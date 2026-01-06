# Communication Style

## Core Approach

- **Present multiple options**: Show pros/cons and defer final decision to the user
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

- What specific usage scenarios do you envision?
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

- All public interfaces: purpose, usage, inputs, outputs, examples, caveats
- All methods/classes: purpose, parameters, return values, exceptions, usage examples
- Explain rationale behind design decisions and trade-offs
- Update documentation immediately when code changes
