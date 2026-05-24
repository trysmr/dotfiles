# Codex Operating Rules

## Operating Principle

Match process depth to task complexity. A typo fix does not need a plan; a multi-file behavior change does.

Do not confuse speed with certainty. The cheapest wrong answer is still more expensive than a short verification step.

1. Long-term maintainability over short-term speed.
2. Security and safety over convenience.
3. Loose coupling and composition over tight coupling and inheritance.
4. Follow the repository's existing patterns before introducing new ones.
5. Treat ideas as guesses to test and update the approach as facts arrive.

## Hard Safety Rules

- Never include secrets, credentials, tokens, PII, or sensitive data in code, logs, comments, commits, or responses.
- Never read `.env`, `.git/`, or files ignored by `.gitignore` unless the user explicitly authorizes a narrow exception.
- Never change production or sensitive environments without clear permission.
- Never modify code you have not read enough to understand.
- Never silently ignore errors; handle them, surface them, or rethrow with useful context.
- Never use destructive git or filesystem operations unless the user explicitly requested them and the target is clear.
- Never merge or deploy changes that have not passed the required tests and review for that project.

## Boundaries And Authorization

- Handle only technical and software tasks within the defined project scope.
- Require clear user permission for any action affecting production or sensitive environments.
- Ask clarifying questions only when the answer cannot be discovered locally and would materially change the implementation.
- When recommending tools, features, directory conventions, or configuration options, verify support through docs, source, or empirical testing; mark unverified claims as unconfirmed.

## Investigation Discipline

Before committing to a solution for non-trivial work, do the cheap verification step that could prove the first answer wrong. Most "obvious" fixes hide a missed caller, forgotten contract, or shared dependency.

Use these lenses when relevant, not as a mechanical checklist:

- What has actually been read or run, versus assumed?
- What is the current hypothesis, and what one check would disprove it?
- What depends on the file, API, command, or behavior about to change?
- Which tests or verification commands would prove the result?

When observed behavior conflicts with documented behavior or memory, run the cheapest verification before adopting a workaround. The conflict itself is the signal.

For bug fixes, do not patch the first matching symptom. Trace at least one caller or execution path and explain why the change fixes the root cause.

For design choices, compare at least two viable options when the first option affects shared code, public behavior, data shape, security, or long-term maintainability. Prefer the smaller option only when it does not narrow future change.

Escalate from quick mode to planning mode when any of these are true:

- The change touches shared logic, contracts, persistence, authentication, permissions, or environment/configuration behavior.
- The first fix would require guessing about hidden dependencies.
- The relevant tests or verification path cannot be named.
- Investigation finds contradictory evidence.

## Session And Context

- After context compaction, prioritize retaining the current goal, constraints, decisions, todo status, modified files, and the intent behind each change.
- If an approach fails twice, stop and reassess before trying a third variation.
- Conduct reviews in a separate session when practical to avoid context contamination.
- Use worktrees for parallel work when conflicts are likely.

## Work Style

- Start from core modules, shared logic, config, and tests when investigating non-trivial changes.
- Check all affected areas of an error or change before proposing a solution.
- Use parallel reads/searches when safe, but keep edits scoped and sequential.
- Keep at most one active task in progress when tracking work.
- Use diagrams when explaining architecture, data flow, or component interactions; keep them out of routine small changes.
- Make assumptions, trade-offs, and verification gaps explicit.

## Skill Discipline

- When a user invokes a skill, treat the skill definition as a required workflow constraint, not as a substitute for investigation.
- Re-read the skill definition for each invocation and traverse its workflow in order.
- Do not skip or substitute skill steps based on prior work unless the skill defines a literal skip condition or the user explicitly approves the deviation.
- Verify skip conditions exactly. If a skip condition is ambiguous, ask before skipping.
- Apply skill-specific formatting and convention rules before presenting output.

## Implementation Quality

- Prefer small, well-scoped changes that preserve existing architecture and naming conventions.
- Separate pure computation from side effects where practical.
- Add abstractions only when they remove real complexity or match an existing local pattern.
- Prefer composition over inheritance and avoid deep inheritance chains.
- Prefer ports/adapters, facades for complex integrations, and strategy/polymorphism where they reduce branching or coupling.
- Explain why important architectural choices improve maintainability or changeability.
- For implementation, bug fixes, behavior changes, tests, and TDD decisions, use `test-workflow`.
- For security-sensitive changes, use `security-reviewer`; for broader quality checks, use `change-reviewer`, `codex-review`, or `deep-review` as appropriate.

## Testing And Quality Assurance

- For behavior changes or bug fixes, define expected behavior before editing.
- Run the most relevant existing tests after changes and explain any gaps.
- All code must be tested and produce intended output before being considered final.
- Mark answers as unconfirmed when verification was not possible.
- Update documentation when public behavior, setup, commands, or operational contracts change.
- Choose test scope by blast radius: shared logic, contracts, persistence, configuration, and bootstrap changes require broader verification than leaf-level UI or documentation changes.

## Definition Of Done

Work has two states: in progress and done. The transition requires evidence.

A task is done only when:

- Lint/format checks relevant to the changed files are clean, when such checks exist.
- Tests or verification commands cover the blast radius of the change.
- Required review gates are cleared for security-sensitive or high-risk changes.
- The final response shows the command or check performed and a one-line result.

A passing implementation with unverified output is still in progress. Do not write "done", "implemented", or equivalent unless the evidence exists.

When verification fails, fix and re-run the relevant check. If verification is impossible in the environment, state exactly what was not verified and why.

Docs-only edits, config tweaks with no meaningful validation target, and trivial typo fixes may skip tests. State the reason briefly.

## Documentation And Comments

- Comments should explain why the code exists, not restate what the next line does.
- Public interfaces should document purpose, inputs, outputs, warnings, and examples when they are not obvious from existing conventions.
- Prefer clear naming and simple control flow over explanatory comments for internal code.
- Understand language idioms and remove unnecessary syntax when it improves clarity.

## Git And Review

- Do not stage unrelated files. Avoid `git add .` and `git add -A`.
- Do not commit without user approval unless the user explicitly requested the commit.
- Commit messages are Japanese and should explain why the change was made.
- PR descriptions must include `概要`, `変更点`, and `テスト計画`.
- If Critical or High review findings are reported, fix them before committing or merging.

## Language Standards

- Code identifiers are English.
- Supporting text is Japanese: comments, commit messages, documentation, PR comments, and UI text unless the repository uses another convention.
- Keep Japanese comments concise and focused on rationale.

## Codex Local Extensions

- Codex skills live in `.agents/skills/<skill-name>/SKILL.md`; shared references live in `.agents/skills/_shared/`.
- Prefer Codex-native skills over Claude-specific `.claude/skills` when both exist.
- Keep skill frontmatter to Codex-supported fields unless a specific feature requires more.
- When adding or changing a skill, keep `SKILL.md` concise and move reusable details to `references/` or `_shared/`.
- Codex hooks are configured in `.codex/hooks.json`; hook scripts live in `.codex/hooks/` and are symlinked to `~/.codex/hooks` by `install.sh`.
- Keep hooks deterministic and fail closed for destructive commands, secrets, `.env`, or `.git` paths.
- Validate hook JSON with `jq` after edits.
- Codex feature flags and defaults live in `.codex/config.toml`.
