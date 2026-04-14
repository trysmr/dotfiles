# Agent Selection and Review Workflows

Use specialized agents and skills deliberately so exploration stays fast and reviews stay accurate. Keep the orchestration simple and choose the lightest tool that can answer the question reliably.

---

## Agent Selection

- Use `repo-explorer` for lightweight repository discovery, structure checks, and dependency or pattern surveys
- Use code-search workflows when you need targeted implementation lookup or symbol hunting
- Use `change-reviewer` for code quality, maintainability, naming, query shape, and test coverage review
- Use `security-reviewer` for security-sensitive changes involving authentication, authorization, input handling, secrets, APIs, or permissions

See `.claude/agents/` for the agent definitions.

---

## Review Workflows

- Use `recent-changes-review` for time-based review of recent commits
- Use `review` for pre-PR diff review when you want quality and security coverage together
- Run `change-reviewer` directly when only code quality or maintainability needs validation
- Run `security-reviewer` directly when only security risk needs validation
- Use `codex-review` when you explicitly want an external Codex-based review pass

---

## Orchestration Patterns

- For unfamiliar repositories, start with `repo-explorer` and follow with `change-reviewer` only after the structure is understood
- For pre-PR review, prefer parallel quality and security review, then merge findings by severity before acting on them
- For feature work, follow a plan-first flow: design, implement, review, then open a PR

This keeps context gathering cheap, reserves deeper analysis for the right stage, and improves maintainability by separating discovery from evaluation.

---

## Model and Cost Discipline

- Prefer faster, lighter agents for exploration and search-oriented tasks
- Prefer higher-accuracy agents for review, risk analysis, and decisions that may block merge
- Prefer forked-context or isolated review flows when you want to avoid polluting the main implementation context