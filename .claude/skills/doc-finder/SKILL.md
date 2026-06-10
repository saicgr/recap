---
name: doc-finder
description: Topic-indexed lookup over docs/ — replaces manual find commands with task-keyword-to-subfolder routing. Invoke when you need to locate relevant docs for a task without reading INDEX.md + every filename.
---

# doc-finder skill

Maps task keywords to the right `docs/` subfolder + file. Stateless. Faster than `find docs/ -name '*.md'` + filename inspection for common tasks.

## Usage

Invoke when planning a task. Provide the task keywords; get back a ranked list of docs to read.

## Routing table

### Strategy / business / pricing tasks
→ `docs/strategy/`
- Pricing question, take-rate math, plan tiers → `STRATEGY.md` §5 + `TAKE_RATE_LANDSCAPE.md`
- Market positioning, competitors → `STRATEGY.md` §2 + `TAKE_RATE_LANDSCAPE.md`
- Adjacent vertical expansion (Phase 4+) → `ADJACENT_CATEGORIES.md`
- Brand / naming / app store → `STRATEGY.md` §0.1

### Architecture / infra / cross-service tasks
→ `docs/architecture/`
- New endpoint, multi-tenant query, RLS → `multi-tenant-rls.md` + `infrastructure.md`
- Reusing FitWiz functionality (internal API pattern) → `fitwiz-reuse.md` + `reuse-audit.md`
- Gemini / AI / quota middleware → `ai-cost-guardrails.md`
- Logging, Sentry, PostHog, alerts → `observability.md`
- Email templates, Resend, categories → `email.md`
- Next.js web dashboard conventions → `web-stack.md`
- Supabase vs Render vs Vercel separation decision → `infrastructure.md`

### Process / workflow / discipline tasks
→ `docs/process/`
- Planning a non-trivial change → `ultrathink.md` (MANDATORY first stop)
- Code review / duplication check → `code-cleanliness.md`
- Pre-commit verification / syntax / imports → `compile-cleanly.md`
- Doc maintenance / CHANGELOG / IMPROVEMENTS → `doc-discipline.md`
- Testing standards / E2E / RLS isolation → `testing.md`
- Multi-agent parallel work / swarm → `agents-and-swarm.md`
- Historical context from FitWiz → `lessons-from-fitwiz.md`
- Claude Code best practices (2026) → `claude-code-best-practices.md`

### Conventions / naming / style tasks
→ `docs/conventions/`
- UI / design system / glassmorphism → `glassmorphism.md`
- Logging format / prefixes / PII rules → `logging.md`
- Branch naming / PR rules / commit format → `git-workflow.md`
- File size limits / splitting strategy → `modularization.md`
- Test user credentials / production emails → `test-credentials.md`
- Design prompt for coach web dashboard → `design-prompt-coach-web.md`
- Design prompt for client web app → `design-prompt-client-web.md`

### Reference / gotchas / requirements tasks
→ `docs/reference/`
- Flutter build_runner trap / iOS pipeline / widget infra → `flutter-gotchas.md`
- System requirements / install / account setup → `requirements.md`
- Sprint 1-8 implementation specs → `claude-prompt.md`

### Change / improvement tracking
→ `docs/changelog/`
- Prior architectural decisions → `CHANGELOG.md`
- Open observations / deferred work → `IMPROVEMENTS.md`

## Resolution algorithm

1. Parse task keywords (e.g., "implement take-rate webhook" → keywords: `take-rate`, `webhook`, `stripe`, `billing`)
2. Match keywords against routing table above
3. Return ordered list of docs to read (most relevant first)
4. Flag any ambiguity (e.g., keyword matches multiple subfolders) + ask user to clarify

## When to use (vs read INDEX.md directly)

- Use doc-finder when keywords are clear + you want fast routing
- Read INDEX.md directly when exploring unfamiliar area OR when keywords don't match cleanly
- Read the per-folder CLAUDE.md (root or child) when starting ANY new task — they're the actual entry point

## Maintenance

When new docs are added to `docs/`, update:
1. `docs/INDEX.md` (file listing)
2. `docs/CLAUDE.md` (folder map)
3. This skill's routing table above

Keep routing table in sync with actual file tree. Grep for orphaned references when renaming.
