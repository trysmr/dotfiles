# Security Guidelines

## Input Validation and Authentication

- **Validate and sanitize all inputs** to guard against injection and misuse
- **Separate authentication (AuthN) and authorization (AuthZ)** responsibilities
- Store all sensitive information in environment variables or credential managers (never in code or config files)

---

## Data Protection

- **NEVER** log secrets, passwords, tokens, or personally identifiable information (PII)
- **NEVER** output secrets or sensitive data via logs, errors, or API responses
- Use exception types that carry contextual detail for debugging and alerting
- Log errors with sufficient context—but **avoid leaking sensitive information**
- **NEVER** swallow exceptions; either handle them explicitly or rethrow with contextual information
