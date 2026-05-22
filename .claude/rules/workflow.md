# Development Workflow

## Principle

Match process depth to task complexity. A config fix needs no plan file; a multi-file feature deserves one. Don't apply ceremony uniformly.

Do not confuse speed with certainty. The cheapest wrong fix is still more expensive than a short verification step.

---

## Investigation Discipline

Before committing to a solution for non-trivial work, do the cheap verification step that could prove your first answer wrong. Most "obvious" fixes have a missed caller, a forgotten contract, or a shared dependency that makes them wrong.

Useful lenses (apply when relevant, not as a checklist):
- What have you actually read or run — versus assumed?
- What's the current hypothesis, and what one check would disprove it?
- What depends on the code you're about to touch?

For unfamiliar code or wide impact analysis, use `repo-explorer` to get a digested overview of structure, dependencies, and patterns before grepping into specifics.

For bug fixes, do not patch the first matching symptom. Trace at least one caller or execution path to explain why the change fixes the root cause.

For design choices, compare at least two viable options when the first option affects shared code, public behavior, data shape, security, or long-term maintainability. Prefer the smallest option only when you can explain why it does not narrow future change.

Escalate from quick mode to planning mode when any of these are true:
- The change touches shared logic, contracts, persistence, authentication, permissions, or environment/configuration behavior
- The first fix would require guessing about hidden dependencies
- You cannot name the relevant tests or verification path
- You find contradictory evidence during investigation

---

## Definition of Done

Work has two states: in-progress and done. The transition requires evidence.

A task is **done** only when:
- Lint/format is clean for the changed files
- Tests pass for the blast radius of your change
- Required review gates are cleared (see Review Gate)
- You have shown the user the commands and a 1-line result summary

A task with passing implementation but unverified output is still **in-progress**, not done. Do not mark TodoWrite items completed without evidence. Do not write "実装完了" / "done" / "実装しました" without it.

### Reporting format

動作確認:
- `<lint command>` -> no issues
- `<test command>` -> N tests, 0 failures

(Commands and counts must be real, not summaries of intent.)

### On failure

Fix and re-run. Do not report partial completion. Do not say "テストは別途確認してください" or equivalent.

### When to skip

Docs-only edits, config tweaks with no meaningful validation target, or trivial typo fixes. State the reason briefly. "trivial" means truly trivial — a typo in a comment, not a "small" logic change.

---

## Phase 1: Understand

- Ask clarifying questions only when requirements or constraints are unclear and the answer would materially change the implementation
- Gather the minimum context needed to avoid guessing: user goals, usage scenarios, environments, constraints, and existing patterns
- Check affected areas before proposing a fix, especially callers, shared dependencies, tests, and configuration
- **Todo Creation**: For multi-step or risky tasks, create initial high-level todos that capture the main requirements and objectives

---

## Phase 2: Plan

- Present a clear and structured plan before starting non-trivial implementation
- Diagrams are effective for system architecture, data flows, or component interactions (Mermaid, PlantUML, draw.io). Use them when the design is non-trivial enough to benefit from visualization
- Outline key components, responsibilities, interactions, and data flows
- Explain how your design addresses user goals and constraints
- Identify risks and limitations, and propose ways to reduce them
- **Todo Refinement**: Break down high-level todos into actionable tasks; identify dependencies and opportunities for parallel execution
- **Plan File Structure**: Plan files (`~/.claude/plans/*.md`) must include:
  - `## Context`: Why this change is needed — the problem, what prompted it, and the intended outcome
  - `## Acceptance Criteria`: Checklist of conditions that must be true when done (`- [ ]`)
  - `## TODO`: Phase-based implementation tasks
    - Use phase-based subheadings (`### Phase N: Name`)
    - List file paths and concise task descriptions in checkbox format (`- [ ]`)
    - Include verification steps at the end of each phase
  - `## Verification`: How to test the changes end-to-end (commands, tests, manual checks)

---

## Review Gate

After implementation is complete, perform the following reviews before committing:

- **Security-related changes** (authentication, input handling, APIs, permissions): Running the `security-reviewer` agent is **required**
- **Other changes**: Running the `change-reviewer` agent is **recommended**
- For thorough or higher-stakes review, use `deep-review` (Opus 4.7) or `codex-review` (external Codex / gpt-5.5)
- If any Critical/High findings are reported, fix them before committing

---

## Plan File Maintenance

- When a TODO item in `~/.claude/plans/*.md` is completed, update the corresponding `- [ ]` to `- [x]` immediately. Do this even after exiting Plan mode — partial updates leave the plan file unreliable.
- Update granularity: per task or per phase, not at session end (easy to miss items).
- Items requiring user judgment or manual verification: keep as `- [ ]` and explain why in the summary.
- For verification phases, append evidence after the checkbox where possible (test counts, command output, file counts) so the plan doubles as an audit trail.
