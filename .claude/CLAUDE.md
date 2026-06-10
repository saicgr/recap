# `.claude` — Agents + Skills + Commands Extensibility

Recap's Claude Code extension layer. Agents for delegated isolated work, skills for on-demand domain knowledge, commands for slash invocation, hooks for deterministic always-must-happen actions.

## Workflow

1. **New isolated capability** with structured tool needs → create an **agent** in `agents/<name>.md` (frontmatter: name/description/model/color/allowedTools).
2. **Domain knowledge / reusable workflow** invoked on demand → create a **skill** at `skills/<name>/SKILL.md`.
3. **Slash command** users invoke explicitly → create a **command** at `commands/<name>.md`.
4. **Deterministic always-must-happen** (e.g. `flutter analyze` after every edit, block writes to `*.g.dart`) → create a **hook** in `settings.json`, NOT an agent (hooks are guaranteed; agents/CLAUDE.md rules are advisory).

## Agent inventory

Ported from Reppora and adapted for Recap (mobile-only, no Supabase, no multi-tenant backend):

| Agent | Purpose | Swarmable |
|---|---|---|
| `swarm-coordinator` | Orchestrates parallel agent execution with git worktrees + manifest. Canonical home for triggers + decomposition + gate + cleanup. | n/a (orchestrator) |
| `compile-checker` | Verification gate. For Recap this means `flutter analyze` (0 errors / 0 warnings) + `dart format --set-exit-if-changed` + Drift schema sanity. Ignore Python / TS / Supabase steps. | yes |
| `flutter-app-runner` | Launches the Flutter app on simulator/device and verifies the golden path. | yes |
| `code-organizer` | Detects duplication, dead code, misplaced files. | yes |
| `error-debugger` | Triages stack traces / crashes / platform errors. | yes |
| `full-stack-architect` | Architectural planning. For Recap, scope is mobile-only (Flutter + local Drift + optional Worker proxy). Ignore web/backend references inherited from Reppora. | yes |
| `gemini-integration-validator` | Validates Gemini API integration. For Recap, the entry point is the Cloudflare Worker proxy — the app never holds the key. | yes |
| `market-research-expansion` | Competitor / market analysis for feature decisions. | yes |
| `security-auditor` | Reviews for secrets in app code, insecure storage, permission overreach. Especially: mic permission scope, file URIs, no API keys shipped. | yes |
| `ui-ux-reviewer` | Reviews screens for clarity, accessibility, platform conventions (iOS HIG + Material). | yes |

**Removed from Reppora:** `database-operations-specialist` (Supabase-specific; Recap uses local Drift only) and `rls-isolation-tester` (no multi-tenant backend).

## Skill inventory

- `skills/doc-finder/` — topic-indexed lookup over `docs/` (once we add docs).
- `skills/changelog-curator/` — auto-appends a CHANGELOG after architectural changes.

## Command inventory

- `commands/frontend-design.md` — design system reference (slash-invokable). Adapt for Recap's mobile aesthetic when we settle on it.

## Swarm trigger rules

TL;DR: any 2 of {≥2 subsystems, ≥4 files, ≥30min wall-time, task-type match} → delegate to `swarm-coordinator`. Default ceiling 5 parallel agents. Hard budget 1M tokens / 90 min wall per swarm invocation.

## When adding new capabilities

- Audit existing agents/skills first — never duplicate.
- Frontmatter `swarmable: true` for any agent the coordinator may spawn.
- Update the inventory tables above.
