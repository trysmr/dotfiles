# Testing Principles

Tests record What: the observable behavior that must hold, not a copy of implementation steps. Each assertion must protect a confirmed requirement or known regression. Assert absence only when absence itself is required behavior, an authorization/security boundary, or a concrete regression condition. Do not invent negative requirements from alternatives mentioned in conversation.

Do not run database-mutating Rails tests concurrently when agents or sessions share a test database.

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

### Search/Filter Test Rigor

- **Fixtures must hold real data in the searched fields**: a test that only asserts "no hit" cannot catch a broken partial-match. Populate the searched field and verify both hit and no-hit cases.
- **Test inputs that normalize to empty**: verify whether requirements call for clearing the search or returning no results. Test that confirmed behavior, and ensure normalization never removes authorization filters.

---

## Contract Tests Are Mandatory

When adding a new contract to a public API (method signature, optional argument, branching behavior), always add a unit test that directly verifies that contract.

- Tests through a thin wrapper only prove "this specific usage pattern works", not that the contract holds
- When adding a new optional argument or nil-tolerance, test each branch directly at the source
- "It's covered by the caller's tests" is not sufficient

---

## Test Scope (Blast Radius)

Changes propagate through the dependency graph. Pick scope by how deep your change sits:

**Verify affected callers as well as units** when you touch upstream code that many things depend on. Run the full suite when required by the project or when the dependency scope cannot be bounded:
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

State the phase when it changes the testing approach. Routine documentation, configuration without behavior changes, and trivial edits may omit classification with a brief reason.

- **Spike (exploratory)**: Shape is unknown. Goal is learning, not shipping. Tests **not required**.
  - Output: working prototype + a written summary of what was learned.
- **Stabilize (productionizing)**: Shape is clear, code will be kept. Tests **required** for non-trivial logic.
- **Maintain (modifying existing code)**: Tests **required** for behavioral changes. Trivial edits (config/typo/rename) are exempt with a stated reason.

### Spike Rules

- Mark spike code clearly (branch name, comment, or scratch directory)
- After spike: either (a) throw away and re-implement under Stabilize, or (b) explicitly transition to Stabilize and add tests before merging
- **Never merge spike code without transitioning to Stabilize**

### Stabilize / Maintain Rules

- For non-trivial Stabilize work and behavior-changing Maintain work, write the expected behavior or regression test, confirm it fails for the intended reason, then implement and run checks for the affected callers. If test-first is impractical, state the reason and alternative verification.
- Define expected behaviors clearly through tests, including failure cases and edge cases that matter for the change
- The end state must satisfy the workflow Definition of Done: tests passing for the blast radius
