# PEFY Agent Workforce — Production Evidence Dossier

> Complete one copy per environment and release. Replace every `PENDING` with objective evidence or keep the gate blocked. Never paste secrets into this file.

## Release identity

| Field | Evidence |
| --- | --- |
| Environment | PENDING |
| Release date/time UTC | PENDING |
| Mission Control repository | `PEFY-TECH/openclaw-mission-control` |
| Mission Control candidate SHA | PENDING |
| Mission Control merge SHA | PENDING |
| ClawTeam repository | `PEFY-TECH/ClawTeam-OpenClaw` |
| ClawTeam candidate/merge SHA | PENDING |
| OpenClaw repository/version | PENDING |
| Deployment identity/image digest | PENDING |
| Production frontend URL | PENDING |
| Production backend URL | PENDING |
| Previous known-good release | PENDING |

## Gate evidence

| Gate | Status | Evidence reference | Owner/approver |
| --- | --- | --- | --- |
| Provenance/license | PENDING | PENDING | PENDING |
| Mission Control CI | PENDING | PENDING | PENDING |
| PEFY Production Gates | PENDING | PENDING | PENDING |
| ClawTeam CI matrix | PENDING | PENDING | PENDING |
| P0/P1 review closure | PENDING | PENDING | PENDING |
| Secrets/IAM | PENDING | PENDING | PENDING |
| Data sovereignty/tenancy | PENDING | PENDING | PENDING |
| Database migration/backup | PENDING | PENDING | PENDING |
| Backend `/readyz` | PENDING | PENDING | PENDING |
| OpenClaw/ClawTeam qualifier | PENDING | PENDING | PENDING |
| Multi-agent smoke mission | PENDING | PENDING | PENDING |
| Allowed action proof | PENDING | PENDING | PENDING |
| Denied/approval-gated action proof | PENDING | PENDING | PENDING |
| Logs/audit/monitoring | PENDING | PENDING | PENDING |
| Backup restore test | PENDING | PENDING | PENDING |
| Rollback target/test | PENDING | PENDING | PENDING |
| Final acceptance | PENDING | PENDING | PENDING |

## Supply-chain evidence

- Upstream/origin review: PENDING
- License review: PENDING
- Dependency lock hashes: PENDING
- Security advisory review: PENDING
- SBOM reference, if generated: PENDING
- Artifact/image signature or provenance reference, if available: PENDING
- Unresolved exceptions: PENDING

## Infrastructure evidence

- Host/platform: PENDING
- Region/data location: PENDING
- CPU/RAM/storage: PENDING
- PostgreSQL version/service: PENDING
- Redis version/service: PENDING
- TLS termination: PENDING
- Exposed ports/firewall policy: PENDING
- Backup destination: PENDING
- Observability destination: PENDING

## Smoke evidence

Attach or reference the output of:

```bash
bash scripts/pefy-production-smoke.sh
```

Expected evidence directory: `artifacts/pefy-production-smoke/`.

- `healthz.json`: PENDING
- `readyz.json`: PENDING
- `project-gallery.status`: PENDING
- `unauthenticated-bootstrap.status`: PENDING
- `authenticated-bootstrap.status` when applicable: PENDING
- `summary.json`: PENDING

## Agent-runtime qualification

Attach or reference:

```bash
PEFY_OPENCLAW_AGENT_IDS="<approved concrete ids>" \
  bash scripts/verify-pefy-production.sh
```

Record:

- concrete agent IDs: PENDING
- ClawTeam binary/version: PENDING
- OpenClaw version: PENDING
- coordination storage health: PENDING
- effective execution policy: PENDING
- ClawTeam skill loaded: PENDING

Do not record credentials or secret values.

## Controlled multi-agent acceptance mission

- Mission ID/name: PENDING
- Organization/board/task: PENDING
- Repository and immutable starting ref: PENDING
- Team lead: PENDING
- Workers: PENDING
- Worktree isolation proof: PENDING
- Task DAG proof: PENDING
- Agent collaboration proof: PENDING
- Allowed low-risk action result: PENDING
- Denied/gated action result: PENDING
- Result artifact: PENDING
- Audit/activity reference: PENDING

## Resilience and rollback

- Pre-release database backup/snapshot: PENDING
- Restore test date/result: PENDING
- Previous Mission Control target: PENDING
- Previous ClawTeam target: PENDING
- Previous OpenClaw target: PENDING
- Configuration rollback target: PENDING
- Rollback test result: PENDING
- Approved RPO: PENDING
- Approved RTO: PENDING

## Residual risks and exceptions

| Risk/exception | Impact | Compensating control | Owner | Expiry/review date |
| --- | --- | --- | --- | --- |
| PENDING | PENDING | PENDING | PENDING | PENDING |

No unresolved critical risk may be converted to PASS by wording alone.

## Acceptance

- Technical acceptance: PENDING
- Security acceptance: PENDING
- Data/privacy acceptance: PENDING
- Operations acceptance: PENDING
- Business/service-owner acceptance: PENDING
- Final decision: **PENDING**

Final decision must be one of `APPROVED` or `REJECTED`; a blocked mandatory gate implies `REJECTED` for production activation until evidence changes.
