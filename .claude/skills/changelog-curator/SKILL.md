---
name: changelog-curator
description: Auto-appends entries to docs/changelog/CHANGELOG.md after architectural / rule / spec changes. Enforces the Decision / Why / Updated / Origin format. Use this skill when the swarm-coordinator's gate step 6 detects a schema or architectural change in a diff, or when a developer is about to merge a PR that adds/removes rules or shifts semantics.
disable-model-invocation: false
---

# changelog-curator skill

Append-only curator for `docs/changelog/CHANGELOG.md`. Detects architectural-change diffs + produces a properly-formatted entry.

## When to invoke

- After any PR merge that touches: `CLAUDE.md` (any folder), `docs/strategy/`, `docs/architecture/`, `docs/process/` rules, `docs/conventions/` rules, schema migrations, cross-service API contracts, pricing config, env var additions with semantic meaning
- When swarm-coordinator's gate step 6 detects architectural content in the diff and requires a CHANGELOG entry before merge
- Manually: `/changelog-curator <summary>` for significant commits

## What does NOT need a CHANGELOG entry

- Individual code commits (git log handles that)
- Trivial edits (typos, formatting)
- WIP plans not yet committed to
- Bug fixes without architectural implications
- Test fixture updates
- Dep version bumps (unless they shift behavior)

## Entry format (strict)

```
## YYYY-MM-DD — short title
- **Decision:** one-line what.
- **Why:** one-line why.
- **Updated:** list of files + sections touched (e.g., `STRATEGY.md §5.3`, `CLAUDE_PROMPT.md Sprint 3`, `multi-tenant-rls.md §RLS policy pattern`).
- **Origin:** conversation turn OR PR # OR user request text.
```

## Workflow when invoked

1. **Detect change type** — read the diff (or summary passed in). Classify as: architectural decision / new rule / removed rule / pricing change / schema change / cross-product impact / other.
2. **Extract the Decision** — what was chosen (not what was considered). One sentence, active voice.
3. **Extract the Why** — reason that will age well. Reference the incident / driver / constraint that motivated it. One sentence.
4. **Enumerate files updated** — grep the diff for file paths + extract section headers they landed in. Format as `file.md §Section` pairs.
5. **Identify Origin** — PR number, user request quoted verbatim if from conversation, or `"session 2026-MM-DD — <topic>"` if neither.
6. **Append to `docs/changelog/CHANGELOG.md`** — at the TOP (reverse chronological), immediately after the title/intro block.
7. **Verify** — re-read the appended entry + confirm format compliance.

## Append-only discipline

- **Never edit historical entries** — corrections go as NEW entries that explicitly supersede old ones (e.g., "Decision: reverts 2026-04-23 entry on X because Y")
- **Never reorder** — entries stay in chronological order they were written
- **Never summarize / compress** — if CHANGELOG gets long, archive OLD entries by date range to `docs/changelog/CHANGELOG-<year>.md` but preserve them

## Quality rules

- **Decision lines must be specific.** "Updated docs" is not a Decision. "Moved all glassmorphism rules from CLAUDE.md §5 to docs/conventions/glassmorphism.md" is.
- **Why lines must age well.** "Because the user asked" is too thin. "Because 575-line CLAUDE.md files cause Claude to ignore instructions per Anthropic's 2026 best-practices doc" is durable.
- **Updated lists must be actionable** — someone reading 6 months from now should be able to grep + find every file touched by the decision.
- **Origin must be retrievable** — conversation turn description that can be pattern-matched in session logs, or PR URL.

## Anti-patterns to reject

- ❌ "Made some improvements" — too vague, rewrite
- ❌ "Per user request" without the actual request quoted — not retrievable
- ❌ Editing a historical entry instead of appending a supersession entry
- ❌ Appending to the BOTTOM (should be top, reverse-chron)
- ❌ Skipping CHANGELOG because "it was small" — if it changed an architectural rule, it's not small

## Example good entry

```markdown
## 2026-04-24 — Per-folder CLAUDE.md restructure + agent swarm system

- **Decision:** Replaced 575-line root CLAUDE.md with ~30-line entry point per 2026 Claude Code best practices. Added 7 per-folder CLAUDE.md files. Reorganized docs/ into 6 topical subfolders (strategy / architecture / process / conventions / reference / changelog). Added 3 new agents (swarm-coordinator, compile-checker, rls-isolation-tester) + 2 skills (doc-finder, changelog-curator). Full swarm worktree + manifest + cleanup scripts shipped.
- **Why:** Anthropic's best-practices doc + dev.to community article both confirm bloated CLAUDE.md causes rule-ignoring. Per-folder structure is auto-loaded on demand. Agent swarm (released early 2026) enables parallel cross-stack work with merge-only-if-tests-pass gate.
- **Updated:** CLAUDE.md (root + web/ + backend/ + scripts/ + .claude/ + assets/ + docs/ + /Users/saichetangrandhe/AIFitnessCoach/mobile/flutter/); docs/INDEX.md; 17 new topical docs across docs/{process,architecture,conventions,reference}; .claude/agents/{swarm-coordinator,compile-checker,rls-isolation-tester}.md; .claude/skills/{doc-finder,changelog-curator}/SKILL.md; scripts/{swarm_spawn,swarm_gate,swarm_merge,swarm_cleanup}.sh; .swarm/manifest.schema.json.
- **Origin:** User request 2026-04-24 — "refer https://code.claude.com/docs/en/best-practices and https://dev.to/byme8/you-dont-need-a-claudemd-jgf ... I need CLAUDE.md in every folder including flutter, vercel apps and more web research on more claude practise 2026 and claude.md practices 2026. Oh and need to agent to always launch agent swarm when executing in claude.md."
```
