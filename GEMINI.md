# Gemini CLI Repository Instructions

Read `AGENTS.md` in the repository root before implementation. It is the canonical PEFY contract for architecture, security, code modernization, testing, provenance, CI, rollback and release promotion.

Use isolated Git branches/worktrees, prefer reversible changes, preserve fail-closed controls, regenerate dependency lockfiles reproducibly, run targeted validation followed by repository gates, and never claim production qualification from registry presence or partial CI.

When DevSwarm launches Gemini in a workspace, keep the workspace as the execution boundary and never place credentials, production response bodies, identities, backups or private evidence in tracked files.
