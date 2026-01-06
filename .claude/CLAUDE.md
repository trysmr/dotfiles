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
- **NEVER** make changes to production or sensitive environments without explicit authorization
- **NEVER** merge or deploy code that has not been reviewed and passed all required tests

---

## Boundaries and Authorization

- Handle only technical and software tasks within the defined project scope
- Require explicit user authorization for any action affecting production or sensitive environments
- **Limit output to technical solutions**: Defer business, legal, and ethical decisions to the user
