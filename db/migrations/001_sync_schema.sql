-- Recap sync backend — Neon Postgres schema (Wave 5).
--
-- Architecture: the Flutter app talks DIRECTLY to the Neon Data API
-- (PostgREST over HTTPS) with a per-user JWT from Neon Auth. There is no
-- application server in this path. Row-Level Security enforces tenancy inside
-- the database, so a compromised or malicious client cannot read another
-- workspace — the isolation is not in app code, it is in Postgres.
--
-- Everything user-authored is stored as CIPHERTEXT (the *_enc columns). The
-- app encrypts client-side with a per-workspace key; the operator holds no key
-- and cannot read user content. Ciphertext is base64 TEXT rather than bytea on
-- purpose: PostgREST hex-encodes bytea, which doubles every payload on the wire.
--
-- VERIFIED LIVE (2026-07-14) against project super-cake-40491136 with two real
-- users and real JWTs: member sees own rows (positive control), non-member sees
-- nothing, cross-workspace INSERT -> 403, forged created_by -> 403, anon -> 400.
--
-- Auth flow the client must follow (no Better Auth SDK exists for Dart):
--   1. POST <auth>/sign-in/email  -> opaque session token (NOT a JWT)
--   2. GET  <auth>/token  sending the session as a COOKIE header -> EdDSA JWT
--      (Bearer does NOT work on /token — it must be the cookie)
--   3. Send that JWT as Authorization: Bearer to the Data API. exp = 15 min,
--      so re-mint from the session before expiry.

-- ---------------------------------------------------------------------------
-- Helper schema. NOT exposed through the Data API (which serves `public`), but
-- `authenticated` still needs USAGE because RLS policies call into it.
-- Forgetting this GRANT makes every request fail with "permission denied for
-- schema app" — the policies themselves cannot run.
-- ---------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS app;
GRANT USAGE ON SCHEMA app TO authenticated;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.workspaces (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name_enc   text NOT NULL,              -- ciphertext
  created_by uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz                 -- soft delete; see "no DELETE policy"
);

CREATE TABLE IF NOT EXISTS public.workspace_members (
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id      uuid NOT NULL,
  role         text NOT NULL DEFAULT 'member' CHECK (role IN ('admin','member','viewer')),
  status       text NOT NULL DEFAULT 'active' CHECK (status IN ('active','removed')),
  created_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (workspace_id, user_id)
);

-- Covering index for the membership lookup every single RLS policy performs.
CREATE INDEX IF NOT EXISTS wm_user_active_idx
  ON public.workspace_members (user_id, status);

-- Public keys are, by definition, public: every member must be able to read
-- them to wrap the workspace key for a new member.
CREATE TABLE IF NOT EXISTS public.user_public_keys (
  user_id     uuid PRIMARY KEY,
  x25519_pub  text NOT NULL,   -- key agreement (sealed box)
  ed25519_pub text NOT NULL,   -- signing
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- The workspace key, encrypted TO each member's public key. The server stores
-- only wrapped blobs it cannot open. `kid` supports key rotation: removing a
-- member MUST mint a new kid, or they could still decrypt future rows they
-- fetch with the old key.
CREATE TABLE IF NOT EXISTS public.wrapped_workspace_keys (
  workspace_id   uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  member_user_id uuid NOT NULL,
  kid            integer NOT NULL DEFAULT 1,
  wrapped_key    text NOT NULL,
  wrapped_by     uuid NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (workspace_id, member_user_id, kid)
);

CREATE TABLE IF NOT EXISTS public.meetings (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  title_enc    text NOT NULL,
  body_enc     text,
  duration_ms  bigint NOT NULL DEFAULT 0,
  kid          integer NOT NULL DEFAULT 1,
  hlc          text NOT NULL,   -- hybrid logical clock; also bound into the AEAD AAD
  created_by   uuid NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  deleted_at   timestamptz
);

CREATE INDEX IF NOT EXISTS meetings_ws_updated_idx
  ON public.meetings (workspace_id, updated_at);

-- ---------------------------------------------------------------------------
-- RLS helpers.
--
-- SECURITY DEFINER so they run as the owner and therefore bypass RLS on
-- workspace_members. Without that, a policy on workspace_members that queries
-- workspace_members recurses infinitely.
--
-- SET search_path = '' pins resolution so the function cannot be hijacked by a
-- caller-controlled search_path.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION app.is_member(p_ws uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.workspace_members m
    WHERE m.workspace_id = p_ws AND m.user_id = auth.uid() AND m.status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION app.is_admin(p_ws uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.workspace_members m
    WHERE m.workspace_id = p_ws AND m.user_id = auth.uid()
      AND m.status = 'active' AND m.role = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION app.is_viewer(p_ws uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.workspace_members m
    WHERE m.workspace_id = p_ws AND m.user_id = auth.uid()
      AND m.status = 'active' AND m.role = 'viewer'
  );
$$;

GRANT EXECUTE ON FUNCTION app.is_member(uuid), app.is_admin(uuid), app.is_viewer(uuid)
  TO authenticated;

-- ---------------------------------------------------------------------------
-- Row-Level Security
--
-- NOTE: there is deliberately NO client DELETE policy on any table. Deletes are
-- soft (deleted_at) so a compromised client cannot destroy a workspace's
-- history, and so tombstones can replicate to other devices. Hard purges run
-- server-side on a schedule.
-- ---------------------------------------------------------------------------
ALTER TABLE public.workspaces            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspace_members     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_public_keys      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wrapped_workspace_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meetings              ENABLE ROW LEVEL SECURITY;

CREATE POLICY ws_read   ON public.workspaces FOR SELECT TO authenticated
  USING (app.is_member(id));
CREATE POLICY ws_update ON public.workspaces FOR UPDATE TO authenticated
  USING (app.is_admin(id)) WITH CHECK (app.is_admin(id));
-- No INSERT policy: workspaces are created only through create_workspace().

CREATE POLICY wm_read         ON public.workspace_members FOR SELECT TO authenticated
  USING (app.is_member(workspace_id));
CREATE POLICY wm_admin_write  ON public.workspace_members FOR INSERT TO authenticated
  WITH CHECK (app.is_admin(workspace_id));
CREATE POLICY wm_admin_update ON public.workspace_members FOR UPDATE TO authenticated
  USING (app.is_admin(workspace_id)) WITH CHECK (app.is_admin(workspace_id));

CREATE POLICY upk_read_all    ON public.user_public_keys FOR SELECT TO authenticated
  USING (true);   -- public keys are public by construction
CREATE POLICY upk_self_write  ON public.user_public_keys FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());
CREATE POLICY upk_self_update ON public.user_public_keys FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- A member may read ONLY the key wrapped for them — never another member's.
CREATE POLICY wwk_read_own     ON public.wrapped_workspace_keys FOR SELECT TO authenticated
  USING (member_user_id = auth.uid());
CREATE POLICY wwk_admin_insert ON public.wrapped_workspace_keys FOR INSERT TO authenticated
  WITH CHECK (app.is_admin(workspace_id) AND wrapped_by = auth.uid());
-- A member must also be able to wrap the key for THEMSELVES — otherwise, on a
-- second device, they would see ciphertext and hold no key. Safe: they already
-- possess K_ws to have wrapped it.
CREATE POLICY wwk_self_insert  ON public.wrapped_workspace_keys FOR INSERT TO authenticated
  WITH CHECK (member_user_id = auth.uid() AND wrapped_by = auth.uid()
              AND app.is_member(workspace_id));

CREATE POLICY meetings_read   ON public.meetings FOR SELECT TO authenticated
  USING (app.is_member(workspace_id));
-- created_by = auth.uid() stops a member forging authorship as someone else.
CREATE POLICY meetings_insert ON public.meetings FOR INSERT TO authenticated
  WITH CHECK (app.is_member(workspace_id)
              AND NOT app.is_viewer(workspace_id)
              AND created_by = auth.uid());
CREATE POLICY meetings_update ON public.meetings FOR UPDATE TO authenticated
  USING (app.is_member(workspace_id) AND NOT app.is_viewer(workspace_id))
  WITH CHECK (app.is_member(workspace_id) AND NOT app.is_viewer(workspace_id));

GRANT SELECT, INSERT, UPDATE ON
  public.workspaces, public.workspace_members, public.user_public_keys,
  public.wrapped_workspace_keys, public.meetings
  TO authenticated;

-- ---------------------------------------------------------------------------
-- create_workspace: the ONLY way to create a workspace.
--
-- This cannot be an RLS INSERT policy. The first workspace_members row makes
-- you an admin, but a bootstrap policy guarding that insert would have to ask
-- "is this user an admin of the workspace?" — which is false until the row it
-- is guarding exists. SECURITY DEFINER sidesteps the chicken-and-egg.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_workspace(p_name_enc text)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_ws  uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  INSERT INTO public.workspaces (name_enc, created_by)
  VALUES (p_name_enc, v_uid)
  RETURNING id INTO v_ws;

  INSERT INTO public.workspace_members (workspace_id, user_id, role, status)
  VALUES (v_ws, v_uid, 'admin', 'active');

  RETURN v_ws;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_workspace(text) TO authenticated;

-- After creating functions, PostgREST caches the schema and will 404 them until
-- it refreshes:  NOTIFY pgrst, 'reload schema';
