---
paths:
  - "**/*.{js,jsx,ts,tsx,mjs,cjs}"
---

# Coding Style

## Control Flow: Always Use Block Form (Brace-style Languages)

In JavaScript, TypeScript, and other C-like brace languages, never use inline `if` / `else` statements that omit braces. Always wrap the body in `{ }`, even for a single statement.

```js
// BAD - inline form
if (!url) return
if (frame) frame.src = url
if (row) row.click()

// GOOD - block form
if (!url) {
  return
}
if (frame) {
  frame.src = url
}
if (row) {
  row.click()
}
```

**Why:** Inline forms are bug-prone:

- **ASI (Automatic Semicolon Insertion) traps** can produce surprising parses, especially when the next line starts with `(`, `[`, `+`, `-`, or a template literal.
- **Indentation deception** when extending the body — a line that looks conditional by indentation may actually run unconditionally:
  ```js
  if (!url) return
    cleanup()  // indented like it's inside the if, but always runs
  ```
- **Larger diffs on change** — extending a one-line body forces the reviewer to read both the original and the rewritten `if`, instead of a single line addition inside the existing block.

**Apply when:** Every `if`, `else`, `else if`, `for`, `while` body in brace-style languages — regardless of statement length. Single-statement bodies still get braces.
