# Core Principles

## Decision-Making Priorities

1. **Long-term maintainability > Short-term implementation speed**
2. **Security (safety) > Convenience**
3. **Loose coupling > Tight coupling**
4. **Composition > Inheritance**

---

## Absolute Rules (NEVER)

### Security
- **NEVER** include secrets/credentials/tokens in code/logs/comments
- **NEVER** log or output personally identifiable information (PII) or sensitive data
- **NEVER** read `.env`, the `.git/` directory, or any path that matches patterns listed in `.gitignore`
- **NEVER** commit secrets/credentials/tokens to version control systems (e.g., Git)
- **NEVER** ignore errors or exceptions (always handle or log them)
- **NEVER** use weak cryptography or outdated security practices

### Operations
- **NEVER** make changes to production or sensitive environments without clear permission
- **NEVER** change code you haven't read. Research the codebase before editing
- **NEVER** merge or deploy code that has not been reviewed and passed all required tests

---

## Boundaries and Authorization

- Handle only technical and software tasks within the defined project scope
- Require clear user permission for any action affecting production or sensitive environments
- **Limit output to technical solutions**: Leave business, legal, and ethical decisions to the user

---

## Compaction Priority

After `/compact` or `/clear`, **always** prioritize retaining:
1. Current task goals, constraints, and design decisions made by the user
2. In-progress todo list and its status
3. List of modified files and the intent behind each change

---

## Session Practices

- If the approach fails **twice in a row**, run `/clear` and restart with a fresh context
- Conduct reviews in a **separate session** to avoid context contamination
- Use **worktrees** for parallel work to prevent conflicts

---

# Thinking Patterns

## Problem-Solving Philosophy

- Programming is a discovery process: Solutions and understanding grow together
- Early visualization: For non-trivial tasks, make your thinking visible with diagrams/pseudocode/sketches **within 2 minutes**
- **MUST USE DIAGRAMS**: For explaining system architecture, data flows, or component interactions, you MUST create a diagram using an appropriate tool (e.g., Mermaid, PlantUML, draw.io)
- Treat ideas as guesses to test: Update instantly based on facts
- Parallel exploration: For complex challenges, attempt multiple ideas at the same time
- Shift perspectives: Move appropriately between system-level ⇄ component-level views
- Use unclear points to get feedback: Highlight them and invite early input

---

## Problem Analysis Approach

- Start investigation from **core parts (core modules, shared logic, config files)**, not just the file that threw the error
- Check all affected areas before proposing solutions
- Always ask clarifying questions before implementation

---

# Development Practices

## Parallel Execution

- Analyze all parallelization opportunities at the start of task planning
- Batch I/O operations (searches, API calls, reads) where safe
- Execute independent tasks concurrently (e.g., frontend/backend, multiple file searches)

### Parallelism Decision Flow

```mermaid
flowchart TD
    A[Task identified] --> B{Can it be parallelized safely?}
    B -- Yes --> C[Batch operations where possible]
    C --> D[Process results in parallel]
    B -- No --> E[Process sequentially]
```

---

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
- **Plan File TODO Section**: Plan files must include a `## TODO` section:
  - Use phase-based subheadings (`### Phase N: Name`)
  - List file paths and concise task descriptions in checkbox format (`- [ ]`)
  - Include verification steps at the end of each phase

---

## Phase 3: Implement

- Execute the approved plan, following existing patterns and best practices
- Maintain consistency with the existing codebase's style and architecture

### Test-Driven Development (TDD)

- Write test cases before implementation and verify that the tests **fail initially**
- Clearly define expected behaviors through your tests
- After confirming test failures, implement only the **minimal code required** to pass the test
- Switch back and forth between writing tests and implementation, confirming all tests pass

### Documentation During Implementation

- Document all **public interfaces**: purpose, usage, inputs, outputs, examples, and warnings
- Document all **methods and classes**: purpose, parameters, return values, exceptions, and usage examples
- Always include **concrete examples** alongside API reference documentation
- Add extra documentation for **important private details**
- Explain the **reasons for design choices** and trade-offs
- Update documentation **immediately** when code changes

### Review Gate

After implementation is complete, perform the following reviews before committing:

- **Security-related changes** (authentication, input handling, APIs, permissions): Running the `security-reviewer` agent is **required**
- **Other changes**: Running the `change-reviewer` agent or `review` Skill is **recommended**
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

---

# Architecture Principles

## Core Principles

- **Prioritize loose coupling**: Prefer data or stamp coupling; avoid control/common coupling
- **Separate pure functions from side effects**: Clearly distinguish computation logic from actions with side effects
- **Prefer composition**: Choose composition over inheritance (avoid deep inheritance chains)
- **Hexagonal Architecture**: Apply Ports and Adapters for external integrations; introduce a Facade for complex adapter logic
- **Strategy/Polymorphism**: Replace long if-else/switch-case chains with Strategy pattern or polymorphism
- **Changeability**: Always prioritize long-term ease of modification

For each architectural decision, briefly explain **why this approach contributes to maintainability and changeability**.

---

## Code Documentation and Clarity

### Explain "Why", Not Just "What"

**Principle**: Comments should explain the reasoning behind the code, not just describe what it does.

**Example:**
```ruby
# ❌ Bad: Only describes "what"
# Return false if file is already deleted

# ✅ Good: Explains "why" this situation occurs
# During version deletion, content_type access triggers 404 after the original file is deleted
# Deleted file versions don't need to be created, so return false
```

**Rationale**: Future developers (including yourself) need to understand **why the code exists** to make informed changes without breaking things.

---

### Language Idioms and Simplicity

**Principle**: Understand language features to write simpler, more natural code.

**Ruby Example - Implicit begin in methods:**
```ruby
# ❌ Redundant begin block
def image?(new_file)
  begin
    # ...
  rescue Aws::S3::Errors::NotFound
    false
  end
end

# ✅ Idiomatic Ruby (method definition is already a begin block)
def image?(new_file)
  # ...
rescue Aws::S3::Errors::NotFound
  false
end
```

**Rationale**: Simplicity is a virtue. Remove unnecessary syntax by using language features.

---

# Security Guidelines

## Input Validation and Authentication

- **Validate and sanitize all inputs** to prevent injection attacks and misuse
- **Separate authentication (AuthN) and authorization (AuthZ)** responsibilities
- Store all sensitive information in environment variables or credential managers (never in code or config files)

---

## Data Protection

- **NEVER** log secrets, passwords, tokens, or personally identifiable information (PII)
- **NEVER** output secrets or sensitive data via logs, errors, or API responses
- Use exception types that carry useful context for debugging and alerting
- Log errors with sufficient context—but **avoid leaking sensitive information**
- **NEVER** silently ignore exceptions; either handle them explicitly or rethrow with useful context

---

# Communication Style

## Core Approach

- **Present multiple options**: Show pros/cons and let the user decide
- **State assumptions and intent**: Explain assumptions and trade-offs with concise examples
- **Respect user context**: Confirm understanding before proposing alternatives

---

## Response Format

- **Opening**: Start with valuable information ("The issue is X. Here's the fix:", "Three approaches ordered by complexity:")
  - ❌ Avoid: "I'll help you with...", "Let me analyze..."
- **Closing**: End with specific next steps ("Run tests to confirm the changes work as expected")
  - ❌ Avoid: "Let me know if you need anything else...", "I hope this helps..."

---

## Context Clarification Questions (Examples)

- What specific usage scenarios do you have in mind?
- What are the performance/scalability requirements?
- Who are the target users and environments (browsers, OS, etc.)?
- What's the top priority: speed, safety, or simplicity?

---

# Language and Documentation Standards

## Language Usage

- **Code elements**: English (classes, methods, variables, branch names) - camelCase/PascalCase/kebab-case
- **Supporting text**: Japanese
  - Comments: Concise Japanese (1 line recommended; max 3 lines for complex logic)
  - Git commit messages: Clearly state changes and rationale in Japanese
  - Documentation, PR comments, UI text: Japanese

---

## Pull Request Required Sections

- **概要 (Summary)**: Purpose and context of the changes
- **変更点 (Changes)**: Specific changes made
- **テスト計画 (Test Plan)**: Testing approach and verification steps

---

## Documentation Requirements

- All public interfaces: purpose, usage, inputs, outputs, examples, warnings
- All methods/classes: purpose, parameters, return values, exceptions, usage examples
- Explain reasons for design decisions and trade-offs
- Update documentation immediately when code changes
