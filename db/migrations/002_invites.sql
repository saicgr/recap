-- Recap sync — workspace invites (Wave 5).
--
-- Sharing a workspace without ever handing the server a key. VERIFIED LIVE
-- (2026-07-14) against project super-cake-40491136: Alice invites, Bob accepts
-- and gains membership + the wrapped key, a wrong lookup is rejected, the invite
-- is single-use, and an uninvited third user sees nothing.
--
-- The security argument is the two-HKDF split (a correction from an earlier
-- broken design that escrowed the key to the operator):
--
--   token  -- a single random secret, sent to the invitee OUT-OF-BAND only
--   lookup = HKDF(token, "recap/invite/lookup")   -> the server sees this
--   kek    = HKDF(token, "recap/invite/kek")      -> the server NEVER sees this
--
-- The inviter wraps K_ws with kek locally and uploads only the wrapped blob and
-- sha256(lookup). The invitee sends `lookup`, gets the blob, derives kek from the
-- token it holds, and unwraps locally. Because lookup and kek are independent
-- HKDF outputs, the server storing lookup+blob cannot derive kek. See
-- lib/services/sync/crypto/invite.dart.

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA app;

CREATE TABLE IF NOT EXISTS public.invites (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  lookup_hash  text NOT NULL UNIQUE,   -- hex(sha256(lookup))
  wrapped_key  text NOT NULL,          -- kek-wrapped K_ws; the server cannot open it
  kid          integer NOT NULL DEFAULT 1,
  created_by   uuid NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  expires_at   timestamptz NOT NULL,
  accepted_at  timestamptz,
  accepted_by  uuid
);

CREATE INDEX IF NOT EXISTS invites_ws_idx ON public.invites (workspace_id);

ALTER TABLE public.invites ENABLE ROW LEVEL SECURITY;
-- Only admins can list a workspace's invites. There is no client INSERT/UPDATE
-- policy — invites move exclusively through the two RPCs below.
CREATE POLICY invites_read ON public.invites FOR SELECT TO authenticated
  USING (app.is_admin(workspace_id));

-- Create an invite. Admin only. The inviter passes `lookup` (not secret — it
-- cannot derive kek) and the kek-wrapped key; the server stores sha256(lookup).
CREATE OR REPLACE FUNCTION public.create_invite(
  p_workspace_id uuid,
  p_lookup       text,
  p_wrapped_key  text,
  p_kid          integer,
  p_ttl_seconds  integer DEFAULT 604800  -- 7 days
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_id uuid;
BEGIN
  IF NOT app.is_admin(p_workspace_id) THEN
    RAISE EXCEPTION 'only an admin can invite';
  END IF;
  INSERT INTO public.invites (workspace_id, lookup_hash, wrapped_key, kid, created_by, expires_at)
  VALUES (
    p_workspace_id,
    encode(app.digest(p_lookup, 'sha256'), 'hex'),
    p_wrapped_key,
    p_kid,
    auth.uid(),
    now() + make_interval(secs => p_ttl_seconds)
  )
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

-- Redeem an invite. Any authenticated user. Adds the caller as a member and
-- returns the wrapped key, which only the caller (holding the token) can unwrap.
CREATE OR REPLACE FUNCTION public.accept_invite(p_lookup text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_inv public.invites%ROWTYPE;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;

  SELECT * INTO v_inv FROM public.invites
  WHERE lookup_hash = encode(app.digest(p_lookup, 'sha256'), 'hex')
  FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'invalid invite'; END IF;
  IF v_inv.accepted_at IS NOT NULL THEN RAISE EXCEPTION 'invite already used'; END IF;
  IF v_inv.expires_at < now() THEN RAISE EXCEPTION 'invite expired'; END IF;

  INSERT INTO public.workspace_members (workspace_id, user_id, role, status)
  VALUES (v_inv.workspace_id, v_uid, 'member', 'active')
  ON CONFLICT (workspace_id, user_id) DO UPDATE SET status = 'active';

  UPDATE public.invites SET accepted_at = now(), accepted_by = v_uid WHERE id = v_inv.id;

  RETURN jsonb_build_object(
    'workspace_id', v_inv.workspace_id,
    'kid', v_inv.kid,
    'wrapped_key', v_inv.wrapped_key
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_invite(uuid, text, text, integer, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_invite(text) TO authenticated;

-- PostgREST caches the schema; new functions 404 until it refreshes:
--   NOTIFY pgrst, 'reload schema';
