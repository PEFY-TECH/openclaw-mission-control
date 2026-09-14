# Claude Code Repository Instructions

Before changing this repository, read and comply with `AGENTS.md` in the repository root. It is the canonical PEFY engineering, security, modernization and release contract.

Claude-specific execution must remain subordinate to that contract: isolate work in a branch/worktree, preserve fail-closed security controls, run targeted checks then `make check`, keep dependency upgrades reproducible, and do not merge or claim production readiness without the required CI/review/runtime evidence.

When DevSwarm launches Claude Code in a workspace, treat that workspace branch as the change boundary and keep coordination artifacts separate from production secrets or customer data.
