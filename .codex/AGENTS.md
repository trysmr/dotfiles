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
