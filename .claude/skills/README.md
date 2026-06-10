# Reppora Skills

Project-scoped Claude skills. Currently empty — add when patterns emerge that warrant skill-level codification.

## When to create a skill vs. an agent vs. a command

| Use case | Pick |
|---|---|
| Reusable interactive workflow Claude triggers via `/command-name` | `.claude/commands/` |
| Specialized sub-agent for a domain (DB ops, security audit, etc.) | `.claude/agents/` |
| Codified knowledge / capability Claude can invoke during reasoning | `.claude/skills/` |

## Likely skills to add as project matures

- `supabase-mcp-helper` — wrappers for common Supabase MCP operations (apply migration, RLS check, type-gen)
- `stripe-connect-tester` — invoke Stripe test charges + verify take-rate behavior
- `e2e-runner` — orchestrate the dev-services + Playwright + Patrol pipeline
- `multi-tenant-audit` — RLS isolation check across endpoints
- `flavor-builder` — Flutter flavor build/clean/install for client + coach apps

Add these as concrete patterns emerge during Sprint 1+.
