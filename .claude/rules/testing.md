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
