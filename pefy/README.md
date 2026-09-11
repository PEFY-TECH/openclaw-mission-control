# PEFY ΩAGENT TEAM ELITE™

PEFY ΩAGENT TEAM ELITE™ is the governed PEFY integration layer for account-wide multi-agent execution. It does **not** replace upstream runtimes blindly. It places them behind PEFY-owned policy, routing, security, observability and benchmark gates.

## Canonical stack

- Control plane: `PEFY-TECH/openclaw-mission-control`
- Team/swarm runtime: `PEFY-TECH/ClawTeam-OpenClaw`
- Agent runtime: `PEFY-TECH/openclaw`
- Work contracts: PEFY ΩWORKGRAPH
- Skills: PEFY ΩEXPERT SKILL FABRIC™ (ΩESF™)
- Model routing: PEFY ΩOmniRoute / Ω9REA
- Security: PEFY ΩCODEX SECURITY FABRIC™ (ΩCSF™)
- Qualification: ΩBENCH

## Production principle

Production status is evidence, not a label. Code can be production-oriented while the runtime remains unactivated. A deployment is only declared `active-production` after infrastructure, secrets, identity, network, observability, backup/restore, rollback and health evidence are verified.

## Team operating model

The executive orchestrator decomposes missions and selects only the roles needed. The baseline capability pool covers strategy, architecture, engineering, data/AI, cybersecurity, DevSecOps/SRE, QA, compliance/audit, finance, legal/risk, project operations and research/documentation. Additional specialists are resolved dynamically from the certified ΩESF registry.

Agent spawning is bounded. The default is three workers, the soft limit is eight, and the hard limit is twelve unless the operating profile is deliberately revised and requalified.

## Approval model

- **L0** — read-only analysis: automatic.
- **L1** — reversible low-risk internal writes: allowed with audit trail.
- **L2** — repository writes, external communications, deployments and data mutations: policy approval required.
- **L3** — privileged, high-impact, financial, legal, security-sensitive or irreversible actions: dual control.
- **L4** — prohibited actions: deny and log.

## Deployment gate

Run:

```bash
AUTH_MODE=local \
LOCAL_AUTH_TOKEN='<50+ char token>' \
POSTGRES_PASSWORD='<non-default secret>' \
bash pefy/scripts/preflight.sh
```

Then run the repository's normal test suite:

```bash
make check
```

The GitHub workflow `PEFY Agent Team Gate` validates this layer on every relevant pull request and on changes merged to `master`.

## Required evidence before production activation

1. Canonical upstream and license/SPDX qualification.
2. SBOM and build provenance.
3. CVE/GHSA/OSV/vendor/CISA-KEV review.
4. External secret store or protected GitHub environment secrets.
5. Tenant and identity isolation tests.
6. Network policy and least-privilege execution.
7. Functional, performance, reliability and security ΩBENCH results.
8. Backup/restore and deterministic rollback test.
9. Mission correlation, logs, metrics, traces and approval ledger.
10. Operator acceptance and release sign-off.

## Status

The GitHub integration layer can be merged after CI passes. Runtime activation still requires binding to a real deployment target and its protected secrets; this repository deliberately does not contain those secrets.
