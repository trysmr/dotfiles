# Development Workflow

## Todo Management Rules

- **Definition of Done (DoD)**: A task is "done" only when implementation is complete, code is reviewed and approved, and all required tests (automated, CI, etc.) have passed
- **Pre-completion checks**: Apply linting and formatting, confirm all tests pass, then commit and close the task
- **In-progress limit**: MUST ensure only **one task** is marked as `in_progress` at any given time

---

## Phase 1: Understand

- Ask clarifying questions whenever requirements or constraints are unclear
- Gather all relevant context: user goals, usage scenarios, environments, and constraints
- Check all affected areas of any error or change
- **Todo Creation**: Create initial high-level todos that capture all main requirements and objectives

---

## Phase 2: Plan

- Present a clear and structured plan before starting implementation
- **MUST USE DIAGRAMS** for system architecture, data flows, or component interactions (e.g., Mermaid, PlantUML, draw.io)
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

## Phase 3: Implement

- Execute the approved plan, following existing patterns and best practices
- Maintain consistency with the existing codebase's style and architecture

### Test-Driven Development (TDD)

For non-trivial features and bug fixes, follow TDD:

- Write test cases before implementation and verify that the tests **fail initially**
- Clearly define expected behaviors through your tests
- After confirming test failures, implement only the **minimal code required** to pass the test
- Switch back and forth between writing tests and implementation, confirming all tests pass

**Lightweight exception**: For trivial changes (config edits, typo fixes, comment updates, simple renames), TDD may be skipped. State the reason briefly.

### Documentation During Implementation

For new public APIs and significant changes:

- Document **public interfaces**: purpose, usage, inputs, outputs, examples, and warnings
- Explain the **reasons for design choices** and trade-offs
- Update documentation **immediately** when code changes

**Lightweight exception**: For internal/private code, config changes, or trivial fixes, documentation is optional. Prioritize clear naming over comments.

### Review Gate

After implementation is complete, perform the following reviews before committing:

- **Security-related changes** (authentication, input handling, APIs, permissions): Running the `security-reviewer` agent is **required**
- **Other changes**: Running the `change-reviewer` agent is **recommended**
- If any Critical/High findings are reported, fix them before committing

### Todo Updates

- Mark tasks as `in_progress` when starting work
- Mark tasks as `completed` only after implementation, testing, and documentation are finished

---

## Phase 4: Present

- Provide ready-to-use code that can be copied, executed, and integrated
- Clearly document the purpose, logic, and reasoning behind each major component
- Clearly list all assumptions, limitations, edge cases, and how to handle them
- **Final Todo Review**: Ensure all todos are completed and all objectives are met

---

## Quality Assurance

- All code must be **tested and produce intended output** before being considered final
- Include references (official docs, links, test output) for all answers/code/samples
- Mark answers as "to be confirmed" if any part is unverified
