# PEFY Agent Workforce — Production Release & Acceptance Runbook

## 1. Purpose

This runbook defines the minimum evidence required to move the PEFY Agent Workforce from a repository baseline to a live production service. It applies to the canonical stack:

1. **OpenClaw Mission Control** — governance and operations control plane.
2. **ClawTeam OpenClaw** — multi-agent coordination and execution plane.
3. **OpenClaw** — default governed runtime.
4. **PEFY AI Project Gallery** — governed registry and assurance view.

A component is never considered production-active merely because it exists in GitHub, appears in the Gallery, builds successfully, or is deployed somewhere.

## 2. Assurance states

| State | Meaning | Minimum evidence |
| --- | --- | --- |
| Registered | Known to the PEFY capability registry | Repository identity and role |
| Evaluation only | Available for controlled assessment | Registration; no production claim |
| Code qualified | Repository candidate passed required code/CI gates | Green CI, tests, review closure, immutable commit |
| Runtime qualified | Real target host passed dependency, security and execution checks | Host qualifier, readiness, auth, gateway and audit evidence |
| Live production active | Runtime-qualified release is serving the approved environment | Production URL/endpoint, deployment identity, smoke evidence, monitoring and rollback target |

## 3. Release decision rule

Promotion is **deny by default**. A release may advance only when every mandatory gate for that state has objective evidence. “Mergeable”, “looks healthy”, “installed”, “registered”, or “works on my machine” are not release evidence.

## 4. Pre-release gate — source, provenance and legal

Record and verify:

- repository and organization;
- immutable candidate commit SHA;
- base branch and merge commit after promotion;
- upstream origin where code is derived from an external project;
- declared license and compatibility with PEFY use;
- local proprietary changes separated from upstream-derived code;
- dependency lockfile hashes;
- unresolved provenance or license exceptions;
- external projects with unclear licensing remain reference-only and are not copied, vendored or rebranded.

**Pass criterion:** no unresolved license/provenance blocker for the promoted code.

## 5. CI and code-quality gate

### Mission Control

Required evidence:

- backend lint and coverage jobs pass;
- frontend lint, typecheck, tests and production build pass;
- documentation quality gate passes;
- Cypress E2E passes;
- Linux Docker installer smoke passes;
- Linux local installer smoke passes;
- macOS installer/external-database smoke passes;
- PEFY Production Gates workflow passes;
- dependency-aware readiness regression tests pass.

### ClawTeam

Required evidence:

- Ruff passes;
- qualification shell scripts pass syntax checks;
- Ubuntu Python 3.10, 3.11 and 3.12 tests pass;
- macOS Python 3.10, 3.11 and 3.12 tests pass;
- all P1/P0 review findings are resolved;
- `scripts/verify-pefy-production.sh` remains fail-closed for production qualification.

**Pass criterion:** all required jobs are green for the exact candidate SHA. If GitHub Actions did not run, this gate is not passed.

## 6. Secrets and identity gate

Before deployment:

- no production secret is committed to Git;
- secrets are injected through the approved environment or secret store;
- local-auth tokens meet strength requirements where local auth is used;
- Clerk or another identity provider is configured only with real production credentials where selected;
- credentials are scoped to the least privilege required;
- agent execution approvals use concrete agent IDs;
- unrestricted `full` execution is prohibited for the PEFY production baseline;
- each required OpenClaw agent has effective `allowlist` security;
- each required agent explicitly allows the resolved ClawTeam executable;
- interactive `ask=always` policies are not accepted for unattended production coordination;
- destructive, privileged, financial, legal, security-sensitive, publication and irreversible actions retain the approved human-control policy.

**Evidence must never contain secret values.**

## 7. Data sovereignty and tenancy gate

Confirm:

- production data location and operator are approved;
- database, object storage, logs and backups remain within the approved sovereignty boundary;
- no external model/provider receives data outside the approved routing policy;
- tenant identity is propagated and enforced across control-plane operations;
- tenant data is not mixed in shared logs, caches, agent memory or exports;
- retention and deletion rules are defined;
- backup exports and diagnostics are treated as confidential data;
- telemetry destinations are explicitly approved.

## 8. Infrastructure readiness gate

Mission Control backend:

- `/healthz` returns HTTP 200 and `{ "ok": true }` as a liveness signal;
- `/readyz` returns HTTP 200 and `{ "ok": true }` only while critical dependencies are ready;
- a failed critical dependency causes `/readyz` to return HTTP 503;
- PostgreSQL readiness probe succeeds;
- Redis readiness is verified when Redis-backed rate limiting is configured;
- Docker service health uses `/readyz`;
- frontend waits for a healthy backend before starting in Compose;
- production process restart policy is defined;
- only intended ports are exposed;
- database/Redis administrative ports are not publicly exposed;
- TLS termination and trusted-proxy configuration match the deployed topology.

## 9. Database and migration gate

Before the release:

1. record current schema/migration revision;
2. take an approved backup or snapshot;
3. verify restore procedure and destination;
4. run migration integrity gate;
5. apply migrations only through the approved release path;
6. confirm `/readyz` after migration;
7. record resulting revision.

For a destructive or non-backward-compatible migration, rollback must be designed before deployment. A code rollback is not sufficient when the schema cannot roll back safely.

## 10. Runtime gate — OpenClaw and ClawTeam

On the real execution host:

```bash
cd ClawTeam-OpenClaw
PEFY_OPENCLAW_AGENT_IDS="main" bash scripts/verify-pefy-production.sh
```

Adjust the concrete agent ID list to the approved runtime population.

Required proof:

- Python version supported;
- tmux available for canonical spawning backend;
- ClawTeam binary resolves correctly;
- ClawTeam coordination directory exists, is writable and passes the read/write probe;
- OpenClaw is present;
- effective approvals can be read through the OpenClaw CLI;
- every required concrete agent is in effective allowlist mode;
- resolved ClawTeam executable is actually allowlisted for each required agent;
- ClawTeam OpenClaw skill is loaded.

## 11. Controlled multi-agent smoke mission

Use a non-production-impacting repository/task designed specifically for acceptance.

The mission must demonstrate:

1. Mission Control creates or exposes the controlled task;
2. a team lead is assigned;
3. at least one worker is spawned;
4. parallel coding work uses isolated Git worktrees;
5. task dependency/DAG state is visible;
6. agent-to-agent coordination is observable;
7. one approved, low-risk action succeeds;
8. one non-authorized action is denied or routed to approval;
9. the mission produces an inspectable result/evidence artifact;
10. logs/activity identify organization, board/task, agent, repository/ref and outcome without leaking secrets.

Do not use destructive production assets for the acceptance mission.

## 12. Mission Control production smoke pack

Set real production URLs. The token is optional; without it, the script still proves liveness, readiness, Gallery reachability and unauthenticated denial.

```bash
export PEFY_MC_BACKEND_URL="https://api.example.invalid"
export PEFY_MC_FRONTEND_URL="https://mission-control.example.invalid"
# Optional, never written to evidence:
# export PEFY_MC_LOCAL_AUTH_TOKEN="..."

bash scripts/pefy-production-smoke.sh
```

The script records only non-secret evidence under `artifacts/pefy-production-smoke` by default.

Mandatory checks:

- `/healthz` passes;
- `/readyz` passes;
- `/project-gallery` is reachable after redirects;
- unauthenticated bootstrap is denied with HTTP 401;
- when an approved auth token is supplied, authenticated bootstrap succeeds.

## 13. Security gate

Verify at minimum:

- dependency locks are committed and reviewed;
- high-impact dependency/security advisories are assessed before promotion;
- no hard-coded secret or debug credential is present;
- CORS is explicit for production;
- security headers remain enabled as designed;
- least-privilege GitHub and deployment credentials are used;
- runtime execution approvals are allowlist-based;
- agent tool exposure follows capability/risk policy;
- public endpoints and administrative surfaces are inventoried;
- denial paths are tested;
- audit logs are protected from tampering and inappropriate disclosure;
- production update and rollback mechanisms are deterministic.

Where SBOM/signing infrastructure is available, attach the SBOM, build provenance and artifact/image signature to the evidence package.

## 14. Observability and audit gate

Before declaring live production:

- application logs are being received;
- error logs can be queried;
- request correlation/trace identifiers are usable where implemented;
- agent activity is visible in Mission Control;
- approval decisions are auditable;
- gateway/runtime failures can be distinguished from business-task failures;
- health/readiness failures create an operational signal;
- dashboards/alerts have an owner;
- log retention and access controls are documented;
- sensitive values are redacted.

## 15. Performance and capacity gate

For the target environment, record:

- expected number of organizations/tenants;
- concurrent agents and teams;
- task throughput target;
- API request-rate envelope;
- PostgreSQL and Redis capacity assumptions;
- CPU/RAM/storage limits;
- concurrency limits for external models/tools;
- acceptable latency and error-rate objectives;
- saturation behavior and back-pressure strategy.

No performance claim is accepted without measured evidence from an environment representative of the target workload.

## 16. Resilience, backup and disaster recovery gate

Define and test:

- PostgreSQL backup schedule;
- backup encryption and access control;
- restore procedure;
- Redis recovery expectations according to its role;
- application redeployment procedure from immutable source/artifacts;
- OpenClaw/ClawTeam state backup where state must survive host loss;
- RPO and RTO targets approved by the service owner;
- single-host failure response;
- dependency outage behavior;
- incident escalation and ownership.

A backup that has never been restored is not accepted as restore evidence.

## 17. Rollback gate

Before promotion, record:

- previous known-good Mission Control commit/image;
- previous known-good ClawTeam commit/package;
- previous known-good OpenClaw version;
- database pre-release backup/snapshot identifier;
- configuration version;
- rollback operator and authority;
- maximum rollback decision time.

Rollback exercise must verify that the previous version can start, pass `/readyz`, authenticate correctly and regain operational visibility.

## 18. Change and release traceability

Every production release should be traceable as:

`input/requirement -> branch -> commits -> PR -> reviews -> CI -> immutable merge SHA -> deployment -> smoke evidence -> acceptance -> monitoring -> rollback target`

The release record must not depend solely on chat history.

## 19. Operational ownership

Assign named roles or functional ownership for:

- service owner;
- release manager;
- infrastructure/runtime owner;
- security owner;
- data/privacy owner;
- agent-governance owner;
- incident commander/on-call path;
- backup/restore owner;
- approval-policy owner.

## 20. Go-live acceptance table

| Gate | Required | Status values |
| --- | --- | --- |
| Provenance/license | Yes | PASS / BLOCKED |
| Mission Control CI | Yes | PASS / BLOCKED |
| PEFY Production Gates | Yes | PASS / BLOCKED |
| ClawTeam CI matrix | Yes | PASS / BLOCKED |
| P1/P0 review findings | Yes | PASS / BLOCKED |
| Secrets/IAM | Yes | PASS / BLOCKED |
| Data sovereignty/tenancy | Yes | PASS / BLOCKED |
| DB migration/backup | Yes | PASS / BLOCKED |
| `/readyz` dependency readiness | Yes | PASS / BLOCKED |
| OpenClaw/ClawTeam host qualifier | Yes | PASS / BLOCKED |
| Controlled multi-agent smoke | Yes | PASS / BLOCKED |
| Allowed + denied action proof | Yes | PASS / BLOCKED |
| Logs/audit/monitoring | Yes | PASS / BLOCKED |
| Restore/rollback target | Yes | PASS / BLOCKED |
| Production URL and deployment identity | Yes | PASS / BLOCKED |
| Final acceptance | Yes | APPROVED / REJECTED |

## 21. Current known external blockers

The release process must explicitly keep a gate **BLOCKED**, rather than silently waive it, when the required system is not accessible to the executing operator. Examples include:

- GitHub Actions administratively disabled or not launching on a repository;
- no target host or cloud deployment project provisioned;
- unavailable production credentials/gateway;
- inability to verify backup/restore or logs in the real environment.

These are operational blockers, not reasons to weaken the acceptance standard.
