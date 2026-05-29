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

### Insight Block Discipline (Explanatory Style)

The `★ Insight ─────` block in Explanatory output style must NOT include **your own debugging mishaps or edge cases you tripped over during verification**.

Trivia, asides, and interesting tangents about the code itself are fine and welcome — those help the user learn. The line is between "fact about the code/domain" (good) and "thing I personally got stuck on while verifying" (bad).

**Rationale**: Sharing your debugging snags forces the user to ask "wait, where? which file? does this matter?" — wasted cognitive load with no payoff. The user did not write the buggy verification code and has no reason to follow your missteps.

**Apply when**: Writing each Insight bullet. Self-check: "Is this a property of the code/domain, or is it about my verification process?" If the latter, drop it.

---

## References for Technical Claims

Include references (official docs, links, test output) for external APIs, tools, commands, or non-obvious technical claims.

---

## Interaction Modes

### Syakyo Mode (Hands-Off)

When the user says "写経モード" / "写経したい" / "写経していきたい" / "I want to type it myself", **do not edit files**. The user is learning by typing the code themselves.

- Present code in code blocks
- State the target file path and line numbers explicitly
- Use Read only; never Edit/Write
- Wait for the user to apply the code before moving on

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
- **Verify Japanese text after edits**: After Edit/Write operations on files containing Japanese, run `grep` for `�` (U+FFFD replacement character). Mojibake is most likely with `replace_all` or long string substitutions, and looks unprofessional to the user opening the file.

---

## Git Commit Message Style

- **Title (first line)**: Noun-form, 50 chars or less. End with a verbal noun (`〜を追加` / `〜を修正` / `〜に対応`). Avoid polite forms (`〜しました`).
- **Body**: One paragraph = one line. Do not wrap mid-paragraph. Bullet lists may span multiple lines.
- **Why-centric**: Explain the rationale, not just what changed. The diff already shows what.
- **No review-process meta**: Do not reference how the change came about (e.g., "Pre-PRレビューで指摘されたため〜", "フィードバックを受けて〜", "レビュー指摘により〜"). Write the underlying motivation directly (e.g., "Xが暗黙依存していたため明示化する", "Yに偽装余地があったため早期検証で塞ぐ"). Reviewer names and review process are ephemeral and lose meaning over time; the underlying motivation is permanent and tells future readers why this code exists. Writing "指摘されたから直した" also reads as if the author couldn't notice it themselves — avoid.

---

## Pull Request Required Sections

- **概要 (Summary)**: Purpose and context of the changes
- **変更点 (Changes)**: Specific changes made
- **テスト計画 (Test Plan)**: Testing approach and verification steps

The **No review-process meta** rule from Git Commit Message Style applies to the PR body as well — write the motivation directly, do not narrate the review process.

The **Test Plan** should list CI-reproducible checks (lint, automated tests). Manual or ad-hoc verification runs (e.g., Rails runner sessions, one-off scripts) are not part of the Test Plan checklist — reviewers cannot replay them from the PR alone. If such checks were valuable to record, mention them in the Summary or as a discussion note, not as a check item.

---

## Documentation Requirements

- All public interfaces: purpose, usage, inputs, outputs, examples, warnings
- All methods/classes: purpose, parameters, return values, exceptions, usage examples
- Explain reasons for design decisions and trade-offs
- Update documentation immediately when code changes
