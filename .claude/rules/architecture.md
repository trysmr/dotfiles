# Architecture Principles

## Core Principles

- **Prioritize loose coupling**: Prefer data or stamp coupling; avoid control/common coupling
- **Separate pure functions from side effects**: Clearly distinguish computation logic from side-effecting actions
- **Prefer composition**: Choose composition over inheritance (avoid deep inheritance chains)
- **Hexagonal Architecture**: Apply Ports and Adapters for external integrations; introduce a Facade for complex adapter logic
- **Strategy/Polymorphism**: Replace long if-else/switch-case chains with Strategy pattern or polymorphism
- **Changeability**: Always prioritize long-term ease of modification

For each architectural decision, briefly explain **why this approach contributes to maintainability and changeability**.

---

## Code Documentation and Clarity

### Explain "Why", Not Just "What"

**Principle**: Comments should explain the reasoning behind the code, not just describe what it does.

**Example:**
```ruby
# ❌ Bad: Only describes "what"
# Return false if file is already deleted

# ✅ Good: Explains "why" this situation occurs
# During version deletion, content_type access triggers 404 after the original file is deleted
# Deleted file versions don't need to be created, so return false
```

**Rationale**: Future developers (including yourself) need to understand **why the code exists** to make informed changes without breaking things.

---

### Language Idioms and Simplicity

**Principle**: Understand language features to write simpler, more idiomatic code.

**Ruby Example - Implicit begin in methods:**
```ruby
# ❌ Redundant begin block
def image?(new_file)
  begin
    # ...
  rescue Aws::S3::Errors::NotFound
    false
  end
end

# ✅ Idiomatic Ruby (method definition is already a begin block)
def image?(new_file)
  # ...
rescue Aws::S3::Errors::NotFound
  false
end
```

**Rationale**: Simplicity is a virtue. Remove unnecessary syntax by leveraging language features.
