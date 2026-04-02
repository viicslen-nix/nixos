<!--
Sync Impact Report
- Version change: template-placeholder → 1.0.0
- Modified principles:
	- placeholder principle 1 → I. Code Quality Is Non-Negotiable
	- placeholder principle 2 → II. Tests Protect Every Change
	- placeholder principle 3 → III. Consistent User Experience Across Hosts
	- placeholder principle 4 → IV. Performance Budgets Are Required
	- placeholder principle 5 → V. Minimal, Reusable Nix Design
- Added sections:
	- Engineering Standards
	- Workflow & Quality Gates
- Removed sections:
	- None
- Templates requiring updates:
	- ✅ .specify/templates/plan-template.md
	- ✅ .specify/templates/spec-template.md
	- ✅ .specify/templates/tasks-template.md
	- ⚠ pending .specify/templates/commands/*.md (directory not present in this repository)
- Follow-up TODOs:
	- None
-->

# NixOS Configuration Constitution

## Core Principles

### I. Code Quality Is Non-Negotiable

All changes MUST preserve readability, determinism, and maintainability. Nix modules MUST
be composable, avoid duplicated logic, and use existing shared abstractions before adding
new ones. Every change MUST include clear naming, minimal surface area, and updated
documentation when behavior changes. Rationale: this repository spans multiple hosts and
flakes, so low-quality changes compound quickly and increase operational risk.

### II. Tests Protect Every Change

Behavioral changes MUST be verified by automated tests or reproducible validation commands
that fail before the change and pass after it. Existing tests MUST NOT be bypassed to merge
changes. New modules, host logic changes, and package updates MUST add or extend test
coverage in the closest existing test location. Rationale: configuration regressions can
break boot, networking, and developer workflows; validation is mandatory.

### III. Consistent User Experience Across Hosts

User-facing behavior MUST remain consistent across supported hosts unless a hardware or
environment constraint is explicitly documented. Shared UX settings (keybinds, shell
behavior, editor defaults, desktop interaction patterns) MUST be centralized in shared
modules when possible. Any intentional deviation MUST include a documented reason and
scope. Rationale: predictable workflows across machines reduce cognitive load and support
cost.

### IV. Performance Budgets Are Required

Changes MUST define and respect performance expectations proportional to scope, such as
evaluation time, build time, memory usage, startup time, or interactive responsiveness.
Any change expected to increase runtime or build cost MUST include measurement notes and
justification in the plan or PR description. Regressions beyond stated budgets MUST be
treated as defects. Rationale: this repository is used daily across multiple environments,
and performance regressions directly reduce reliability and developer throughput.

### V. Minimal, Reusable Nix Design

Implementations MUST prefer existing NixOS/Home Manager/nixvim built-ins and plugin-native
options over custom wrappers or ad hoc scripts. New abstractions MUST demonstrate reuse
across at least one additional host, module, or flake, or remain local until reuse is
proven. Rationale: minimal, standard patterns lower maintenance cost and simplify
upgrades.

## Engineering Standards

- Formatting and linting tools configured in this repository MUST pass before merge.
- Changes to host-critical paths (boot, storage, networking, secrets, persistence) MUST
 include explicit rollback guidance in the implementation plan or PR notes.
- Security-sensitive changes MUST preserve least privilege and MUST NOT introduce plaintext
 secrets in tracked files.
- UX-impacting changes MUST document affected hosts and expected behavior deltas.
- Performance-impacting changes MUST define a measurable target and validation method.

## Workflow & Quality Gates

1. Every implementation plan MUST include a Constitution Check covering code quality,
 testing, UX consistency, and performance.
2. Every specification MUST include testable acceptance criteria, UX consistency
 expectations, and measurable success criteria including performance where relevant.
3. Every task breakdown MUST include mandatory validation tasks and explicit UX/performance
 verification tasks when user-facing or runtime-sensitive behavior changes.
4. Reviews MUST block merge when constitutional gates are unmet without an approved,
 documented exception.

## Governance
<!-- Example: Constitution supersedes all other practices; Amendments require documentation, approval, migration plan -->

This constitution supersedes conflicting local process notes for planning, specification,
and task generation in this repository.

Amendment process:

- Propose changes via PR updating this file and any impacted templates.
- Include rationale, impact assessment, and migration guidance when behavior expectations
 change.
- Obtain approval from repository maintainers before merge.

Versioning policy (semantic versioning for governance):

- MAJOR: Breaking governance changes, principle removal, or principle redefinition.
- MINOR: New principle or materially expanded mandatory guidance.
- PATCH: Clarifications, wording improvements, and non-semantic refinements.

Compliance review expectations:

- Plans, specs, tasks, and reviews MUST explicitly confirm constitutional compliance.
- Exceptions MUST be documented with owner, scope, and expiration/revisit date.
- Periodic compliance checks SHOULD occur during major repository restructuring.

**Version**: 1.0.0 | **Ratified**: 2026-04-02 | **Last Amended**: 2026-04-02
