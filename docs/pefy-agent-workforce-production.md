# PEFY Agent Workforce Production Baseline

Status: governed production baseline

This document defines the PEFY-owned operating boundary for the multi-agent workforce exposed through OpenClaw Mission Control. It is intentionally stricter than simply installing multiple agent frameworks.

## 1. Canonical architecture

| Layer | Canonical component | Role |
| --- | --- | --- |
| Control plane | `PEFY-TECH/openclaw-mission-control` | Organizations, boards, tasks, approvals, gateways, agent lifecycle, activity visibility and API-backed operations |
| Team execution | `PEFY-TECH/ClawTeam-OpenClaw` | Multi-agent team formation, task decomposition, worktree isolation, inter-agent messaging and team execution |
| Runtime | `PEFY-TECH/openclaw` | Default registered OpenClaw runtime used by the governed execution layer |
| Project discovery | Mission Control `/project-gallery` | Governed catalogue of PEFY AI, agent and orchestration projects |
| Optional frameworks | AgentScope, AutoAgent, VoltAgent, Archon, Deer Flow, Paperclip and other registered sources | Evaluation candidates; they are not account-wide defaults and must remain behind PEFY governance and adapter boundaries |

The presence of a repository in the gallery is not a production approval. Production authority remains with the control-plane policy, release gates and explicit approvals.

## 2. Production security invariants

1. OpenClaw execution approvals must use an allowlist policy. Do not switch the account or agents to unrestricted `full` shell execution merely to make automation easier.
2. Agent credentials, API keys, GitHub tokens, deployment credentials and model-provider secrets must never be committed to the repository or embedded in Gallery metadata.
3. Human approval is mandatory for destructive, privileged, financial, legal, security-sensitive, external-publication and irreversible actions unless a separately approved policy explicitly authorizes the action class.
4. Agent work must remain traceable to an organization, board/task or equivalent work item, actor/agent identity, repository/ref, evidence and final result.
5. Parallel coding agents must use isolated workspaces/worktrees or an equivalently strong isolation mechanism before merge.
6. Production branches must be changed through reviewed commits or pull requests with CI evidence. Emergency changes require an auditable exception record.
7. External frameworks and catalogues are inputs, not sovereign control planes. Their provenance and license must be reviewed before code or content is vendored.
8. A missing, incompatible or unclear license blocks code/content incorporation. Reference links may be retained with explicit provenance and without copying the upstream work.
9. Least privilege applies to GitHub, model providers, gateways, tools, connected applications and deployment targets.
10. Runtime health, failed jobs, denied approvals, security events and agent errors must be observable and retained according to the applicable operational and audit policy.

## 3. Activation model

The workforce is considered **registered** when its repositories and metadata are present.

The workforce is considered **GitHub production-baselined** when all of the following are true:

- the canonical repositories are present under the PEFY GitHub boundary;
- Mission Control exposes the agent and project governance surfaces;
- changes pass the repository CI gates;
- the production branch contains the approved baseline;
- no unresolved release blocker is known.

The workforce is considered **runtime active** only when a deployment environment has been configured and independently verified with:

- a non-placeholder authentication token or approved identity provider;
- a reachable Mission Control backend health endpoint;
- a reachable Mission Control frontend;
- at least one healthy registered gateway/runtime;
- an OpenClaw/ClawTeam health check;
- a controlled agent-team smoke mission;
- approval enforcement verified with both an allowed and denied action;
- logs and audit events visible after the smoke mission.

Do not label a repository-only state as a live runtime deployment.

## 4. Required release gates

Before production promotion, record evidence for these gates:

| Gate | Minimum evidence |
| --- | --- |
| Source | Canonical repository and immutable commit/ref identified |
| License/provenance | License and upstream provenance reviewed |
| CI | Lint, typecheck, tests and build pass |
| Security | Secret scan/dependency review plus least-privilege configuration |
| Functional | Control-plane and team-execution smoke tests pass |
| Reliability | Restart/recovery and rollback path demonstrated |
| Governance | Approvals, identity and audit trail demonstrated |
| Deployment | Production environment/URL and health verification recorded |
| Rollback | Last-known-good ref and rollback procedure recorded |

A failed gate keeps the component in candidate or pre-production state.

## 5. AI Project Gallery governance

The Gallery is a PEFY-owned registry surface. It may include:

- PEFY-owned repositories;
- approved internal projects;
- externally hosted references with clear provenance;
- maturity and governance metadata generated by PEFY review.

It must not imply ownership of external projects. External source code or curated content must not be copied into PEFY repositories unless the license and provenance permit it and the security review accepts it.

At the time this baseline was created, `KalyanM45/AI-Project-Gallery` was treated as a reference-only discovery source because no repository license was exposed by GitHub metadata during the review. The Gallery therefore links to it but does not mirror its content.

## 6. Account-wide GitHub boundary

The control plane can govern work that is connected to it, but repository code alone cannot impose GitHub organization settings across every account. Organization-wide branch rules, GitHub Actions environments, deployment credentials, organization secrets, runner policies and other administrative controls must be configured through authorized GitHub administration channels and verified separately.

This distinction is mandatory: **central governance is account-oriented; live execution and GitHub administrative enforcement are environment-specific and evidence-based.**

## 7. Operating principle

Prefer one governed workforce with interchangeable subordinate runtimes over multiple competing account-wide agent systems. New frameworks enter through discovery, provenance/license review, security assessment, functional evaluation, controlled integration, observability and rollback qualification. Only measurable advantage justifies promotion into the canonical execution path.
