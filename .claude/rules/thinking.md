# Thinking Patterns

## Problem-Solving Philosophy

- Programming is a discovery process: Solutions and understanding co-evolve
- Early visualization: For non-trivial tasks, externalize thinking with diagrams/pseudocode/sketches **within 2 minutes**
- **MUST USE DIAGRAMS**: For explaining system architecture, data flows, or component interactions, you MUST create a diagram using an appropriate tool (e.g., Mermaid, PlantUML, draw.io)
- Hypothesis-driven: Treat conclusions as hypotheses and update instantly based on facts
- Parallel exploration: For complex challenges, attempt multiple ideas simultaneously
- Shift perspectives: Move appropriately between system-level ⇄ component-level views
- Leverage uncertainty: Highlight unclear points and invite early feedback

---

## Problem Analysis Approach

- Start investigation from **foundational components (core modules, shared logic, config files)**, not just the file that threw the error
- Systematically investigate the full impact radius before proposing solutions
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
