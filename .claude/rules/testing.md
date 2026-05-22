# Testing Principles

## Expected Values Must Be Literals

Never use the method under test to produce expected values. Always write expectations as literal strings or numbers.

```ruby
# BAD: if the logic is broken, the test still passes
assert_equal record.description, result

# GOOD: expected value is explicit
assert_equal "3 課税(10%)", result
```

---

## Do Not DRY Up Tests

Prefer writing setup and assertions directly in each test case over extracting helper methods. Each case must be independently readable. Stub/mock helpers are acceptable.

---

## Test Comments: Section Headings Only

Do not write comments that repeat the test case name. `test "..."` serves as the heading. Only use comments as section headings to group multiple related tests.

---

## Assert Content, Not Just IDs

In search/query tests, verify the actual text content of matched records, not just IDs. Prefer `assert_equal` over `assert_includes` to compare the full result set — the diff on failure shows exactly what went wrong.

---

## Contract Tests Are Mandatory

When adding a new contract to a public API (method signature, optional argument, branching behavior), always add a unit test that directly verifies that contract.

- Tests through a thin wrapper only prove "this specific usage pattern works", not that the contract holds
- When adding a new optional argument or nil-tolerance, test each branch directly at the source
- "It's covered by the caller's tests" is not sufficient

---

## Test Scope (Blast Radius)

Changes propagate through the dependency graph. Pick scope by how deep your change sits:

**Run the full suite** when you touch upstream code that many things depend on:
- Database schema, migrations
- Domain models, shared types, interfaces, domain entities
- Libraries, shared utilities (`lib/`, `packages/shared/`, etc.)
- Configuration, environment, application bootstrap
- Concerns, mixins, decorators, shared helpers

**Scoped tests are sufficient** for leaf-level changes:
- A single view, template, or component
- A single endpoint handler or route action
- CSS, styling
- A single client-side controller, hook, or store
- Static assets

When unsure, run more rather than less. Don't narrow scope unless you can name what depends on the change and argue why those tests don't matter.

---

## Testing Strategy

### Phase Classification (declare before editing code)

State which phase you are in at task start. This prevents silently skipping tests.

- **Spike (exploratory)**: Shape is unknown. Goal is learning, not shipping. Tests **not required**.
  - Output: working prototype + a written summary of what was learned.
- **Stabilize (productionizing)**: Shape is clear, code will be kept. Tests **required** for non-trivial logic.
- **Maintain (modifying existing code)**: Tests **required** for behavioral changes. Trivial edits (config/typo/rename) are exempt with a stated reason.

### Spike Rules

- Mark spike code clearly (branch name, comment, or scratch directory)
- After spike: either (a) throw away and re-implement under Stabilize, or (b) explicitly transition to Stabilize and add tests before merging
- **Never merge spike code without transitioning to Stabilize**

### Stabilize / Maintain Rules

- Tests are required for behavioral changes. The order (before, during, or after implementation) is your choice
- Define expected behaviors clearly through tests, including failure cases and edge cases that matter for the change
- The end state must satisfy the workflow Definition of Done: tests passing for the blast radius
