# PEFY Mission Control — Frontend Supply-Chain Gate

## Purpose

This control keeps the production frontend dependency graph auditable and fail-closed. A repository build or successful UI test does not by itself qualify a dependency set for production.

## Mandatory controls

For every change to `frontend/package.json` or `frontend/package-lock.json`:

1. regenerate the lock graph with the repository Node/npm toolchain using `npm install --package-lock-only --ignore-scripts`;
2. require the regenerated file to be byte-identical to the committed lockfile;
3. run `npm audit --omit=dev --json` against the production dependency graph;
4. retain the audit JSON, `package.json`, `package-lock.json` and SHA/provenance evidence;
5. fail the production gate on any **critical** or **high** production dependency vulnerability;
6. do not use `npm audit fix --force` as an automatic production repair mechanism;
7. review moderate/low findings and keep them visible rather than silently suppressing them.

## September 2026 remediation

The initial production-only audit of the Gallery production-readiness candidate detected:

- 3 critical;
- 6 high;
- 1 moderate.

The critical/high findings were concentrated in an outdated Clerk/Next.js graph. The remediation candidate updates:

- `@clerk/nextjs` from the vulnerable 6.37.x line to 6.39.6;
- `next` from 16.1.7 to 16.3.5;
- `eslint-config-next` to 16.3.5;
- the associated transitive Clerk, `js-cookie`, `sharp`, Next.js and related dependency graph through a regenerated lockfile.

The independently generated candidate lock produced a production audit result of:

- 0 critical;
- 0 high;
- 1 moderate;
- 0 low.

This result is **candidate evidence**, not a final release claim. The committed lock must still pass the permanent `PEFY Frontend Supply-Chain Gate`, the main CI workflow and the PEFY Production Gates on the exact current PR head before promotion.

## Release interpretation

- **PASS:** committed lock is reproducible and production audit has zero high/critical findings on the exact candidate SHA.
- **BLOCKED:** lock drift exists, audit metadata is unavailable, or one or more high/critical production findings remain.
- **REVIEW:** only moderate/low findings remain; each stays visible for triage and future remediation.

A green supply-chain gate does not replace application tests, code review, runtime qualification, data-protection controls or rollback evidence.
