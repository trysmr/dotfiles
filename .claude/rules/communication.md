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

### Use AskUserQuestion for Choice-Based Decisions

When asking the user to choose between 2-4 alternatives, **MUST** use the `AskUserQuestion` tool instead of presenting a numbered list in plain text. `AskUserQuestion` is a deferred tool — load its schema first via `ToolSearch` with `select:AskUserQuestion`, then call it.

- **Apply when**: presenting concrete alternatives the user picks from (approach A vs B, library choice, scope decision, file location)
- **Skip when**: simple yes/no confirmation, or when the next step is obvious from context
- **Format**: place the recommended option first and append `(Recommended)` to its label; bundle related decisions into a single call (max 4 questions)

**Rationale**: Click-based selection is faster and less error-prone than long text replies, especially for multi-branch agreement. The extra `ToolSearch` step is intentional friction — do not skip it just because plain text feels easier.

---

# Language and Documentation Standards

## Language Usage

- **Code elements**: English (classes, methods, variables, branch names) - camelCase/PascalCase/kebab-case
- **Supporting text**: Japanese
  - Comments: Concise Japanese (1 line recommended; max 3 lines for complex logic)
  - Git commit messages: Clearly state changes and rationale in Japanese
  - Documentation, PR comments, UI text: Japanese

### Formatting Conventions

- Use ASCII arrow `->` instead of Unicode arrow `→`. The Unicode form looks AI-generated.
- Do not insert spaces between Japanese and English/numeric characters. `Sprint 1テスト作成` is correct; `Sprint 1 テスト作成` is wrong.
- For business-facing task descriptions (project tracker tickets, planning docs), avoid implementation-level terms (class names, column names, code). Use domain language instead — engineering details belong in design docs and code comments.

---

## Git Commit Message Style

- **Title (first line)**: Noun-form, 50 chars or less. End with a verbal noun (`〜を追加` / `〜を修正` / `〜に対応`). Avoid polite forms (`〜しました`).
- **Body**: One paragraph = one line. Do not wrap mid-paragraph. Bullet lists may span multiple lines.
- **Why-centric**: Explain the rationale, not just what changed. The diff already shows what.

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
