# Repository Guidelines

## Project Structure & Module Organization
- `backend/`: FastAPI service. Main app code lives in `backend/app/` with API routes in `backend/app/api/`, data models in `backend/app/models/`, schemas in `backend/app/schemas/`, and service logic in `backend/app/services/`.
- `backend/migrations/`: Alembic migrations (`backend/migrations/versions/` for generated revisions).
- `backend/tests/`: pytest suite (`test_*.py` naming).
- `backend/templates/`: backend-shipped templates used by gateway flows.
- `frontend/`: Next.js app. Routes under `frontend/src/app/`, shared components under `frontend/src/components/`, utilities under `frontend/src/lib/`.
- `frontend/src/api/generated/`: generated API client; regenerate instead of editing by hand.
- `docs/`: contributor and operations docs (start at `docs/README.md`).

## Build, Test, and Development Commands
- `make setup`: install/sync backend and frontend dependencies.
- `make check`: closest CI parity run (lint, typecheck, tests/coverage, frontend build).
- `docker compose -f compose.yml --env-file .env up -d --build`: run full stack.
- Fast local loop:
  - `docker compose -f compose.yml --env-file .env up -d db`
  - `cd backend && uv run uvicorn app.main:app --reload --port 8000`
  - `cd frontend && npm run dev`
- `make api-gen`: regenerate frontend API client (backend must be on `127.0.0.1:8000`).

## Coding Style & Naming Conventions
- Python: Black + isort + flake8 + strict mypy. Max line length is 100. Use `snake_case`.
- TypeScript/React: ESLint + Prettier. Components use `PascalCase`; variables/functions use `camelCase`.
- For intentionally unused destructured TS variables, prefix with `_` to satisfy lint config.

## Testing Guidelines
- Backend: pytest via `make backend-test`; coverage policy via `make backend-coverage` (writes `backend/coverage.xml` and `backend/coverage.json`).
- Frontend: vitest + Testing Library via `make frontend-test` (coverage in `frontend/coverage/`).
- Add or update tests whenever behavior changes.

## Commit & Pull Request Guidelines
- Follow Conventional Commits (seen in history), e.g. `feat: ...`, `fix: ...`, `docs: ...`, `test(core): ...`.
- Keep PRs focused and based on latest `master`.
- Include: what changed, why, test evidence (`make check` or targeted commands), linked issue, and screenshots/logs when UI or operator workflow changes.

## Security & Configuration Tips
- Never commit secrets. Copy from `.env.example` and keep real values in local `.env`.
- Report vulnerabilities privately via GitHub security advisories, not public issues.

## PEFY Multi-AI Governance
- This file is the canonical repository contract for humans and AI assistants. Tool-specific instruction files are adapters and must not contradict it.
- Work on an isolated branch or Git worktree. Never edit or push directly to `master` for implementation work.
- Mission Control remains the governance/control plane. DevSwarm, ClawTeam, OpenClaw, IDE agents, CLI agents and external runtimes are subordinate execution adapters.
- Prefer the smallest reversible change that satisfies the requirement. Preserve public contracts unless a migration is explicitly required and covered by tests/migration evidence.
- Never weaken authentication, authorization, tenant isolation, execution allowlists, readiness, auditability, supply-chain gates or rollback controls to make a task pass.
- Never commit credentials, tokens, private keys, production response bodies, customer data, backup archives or evidence containing identities/secrets.
- Do not bulk-sync, blind-rebase, auto-upgrade or vendor external projects solely for parity. Verify canonical provenance, licence, security, compatibility, tests, benchmark impact and rollback first.

## PEFY Required Agent Workflow
1. Understand the task, repository boundaries and affected contracts.
2. Inventory impacted code, dependencies, APIs, migrations, tests, docs, deployment and security surfaces.
3. Execute in an isolated branch/worktree.
4. Run targeted checks first, then repository-wide gates.
5. For dependency changes, regenerate lockfiles reproducibly and assess runtime vulnerabilities separately from dev-only findings.
6. For security-sensitive changes, prove both an allowed path and a denied/fail-closed path.
7. Keep `/healthz` as liveness and `/readyz` dependency-aware; never report readiness when a required production dependency is unavailable.
8. Record immutable candidate SHA/provenance for release evidence.
9. Do not merge while required CI, review, security, deployment or rollback gates are incomplete.
10. Preserve a deterministic rollback target.

## Code Modernization Discipline
Modernization is evidence-driven rather than version-chasing. Classify each change as one or more of: runtime/framework upgrade, dependency remediation, language/runtime migration, API migration, architecture refactor, performance optimization, security hardening, test modernization, observability modernization or developer-experience modernization. Every claimed improvement requires relevant before/after evidence and no security regression.

## Agent Interoperability
The same contract governs Codex/ChatGPT, Claude Code, Gemini CLI, GitHub Copilot, Cursor CLI, Amazon Q, Atlassian Rovo, Goose, Aider, Amp, Mistral Vibe, Qwen Code, OpenCode, Cline, Plandex, Droid, DevSwarm, OpenClaw/ClawTeam and future assistants. Provider-specific files may add syntax or discovery hints, but they may not create weaker policy paths.
