# Agent Selection and Review Workflows

Use specialized agents and skills deliberately so exploration stays fast and reviews stay accurate. Keep the orchestration simple and choose the lightest tool that can answer the question reliably.

---

## Agent Selection

- Use `repo-explorer` for lightweight repository discovery, structure checks, and dependency or pattern surveys
- Use `change-reviewer` for code quality, maintainability, naming, query shape, and test coverage review
- Use `security-reviewer` for security-sensitive changes involving authentication, authorization, input handling, secrets, APIs, or permissions

See `.claude/agents/` for the agent definitions.

---

## Review Workflows

- Run `change-reviewer` for code quality or maintainability review
- Run `security-reviewer` for security-sensitive changes
- Use `deep-review` for thorough review with Opus 4.7
- Use `codex-review` for external Codex-based review with gpt-5.5

---

## Task Routing

Choose tools and workflow based on task type:

| Task | Approach | Agents/Skills |
|------|----------|---------------|
| Single-file fix | Direct implementation, no plan needed | — |
| Multi-file feature | Plan file required, then implement | `plan-feature` |
| Investigation/search | Read-only exploration | `repo-explorer` |
| Pre-PR review | Parallel quality + security review | `change-reviewer` + `security-reviewer` |
| Thorough review | Dedicated review with stronger model | `deep-review` or `codex-review` |
| Security-sensitive change | Security review mandatory before commit | `security-reviewer` |
| PR creation | Tests pass, review done, then create | `pr` |

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