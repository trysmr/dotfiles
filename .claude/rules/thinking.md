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
- Ask clarifying questions whenever requirements or constraints are unclear
- **Verify before recommending**: When suggesting tools, features, directory conventions, or configuration options, confirm they are officially supported (via docs, source code, or empirical test). Label unverified claims as "unconfirmed"
- **Never fix by guessing**: Identify the root cause before making changes. Do not apply a fix based on "probably this is the issue." Before every fix, be able to explain *why* this change resolves the problem with concrete evidence

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
