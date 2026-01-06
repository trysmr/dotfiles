# Development Workflow

## Todo Management Rules

- **Definition of Done (DoD)**: A task is "done" only when implementation is complete, code is reviewed and approved, and all required tests (automated, CI, etc.) have passed
- **Pre-completion checks**: Apply linting and formatting, confirm all tests pass, then commit and close the task
- **In-progress limit**: MUST ensure only **one task** is marked as `in_progress` at any given time

---

## Phase 1: Understand

- Ask clarifying questions whenever requirements or constraints are unclear
- Gather all relevant context: user goals, usage scenarios, environments, and constraints
- Systematically investigate the full impact radius of any error or change
- **Todo Creation**: Create initial high-level todos that capture all main requirements and objectives

---

## Phase 2: Plan

- Present a clear and structured plan before starting implementation
- **MUST USE DIAGRAMS** for system architecture, data flows, or component interactions (e.g., Mermaid, PlantUML, draw.io)
- Outline key components, responsibilities, interactions, and data flows
- Explain how your design addresses user goals and constraints
- Identify risks and limitations, and propose mitigation strategies
- **Todo Refinement**: Break down high-level todos into actionable tasks; identify dependencies and opportunities for parallel execution

---

## Phase 3: Implement

- Execute the approved plan, following established patterns and best practices
- Maintain consistency with the existing codebase's style and architecture

### Test-Driven Development (TDD)

- Write test cases before implementation and verify that the tests **fail initially**
- Clearly define expected behaviors through your tests
- After confirming test failures, implement only the **minimal code required** to pass the test
- Alternate iteratively between writing tests and implementation, continuously confirming that all tests pass

### Documentation During Implementation

- Document all **public interfaces**: purpose, usage, inputs, outputs, examples, and caveats
- Document all **methods and classes**: purpose, parameters, return values, exceptions, and usage examples
- Always include **concrete examples** alongside API reference documentation
- Provide supplemental documentation for **important private details**
- Explain the **rationale behind design decisions** and trade-offs
- Update documentation **immediately** when code changes

### Todo Updates

- Mark tasks as `in_progress` when starting work
- Mark tasks as `completed` only after implementation, testing, and documentation are finished

---

## Phase 4: Present

- Provide ready-to-use code that can be copied, executed, and integrated
- Clearly document the purpose, logic, and reasoning behind each major component
- Explicitly outline all assumptions, limitations, edge cases, and how to handle them
- **Final Todo Review**: Ensure all todos are completed and all objectives are met

---

## Quality Assurance

- All code must be **tested and produce intended output** before being considered final
- Attach primary sources (official docs, links, test output) for all answers/code/samples
- Mark answers as "to be confirmed" if any part is unverified
