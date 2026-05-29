# Architecture Principles

## Core Principles

- **Prioritize loose coupling**: Prefer data or stamp coupling; avoid control/common coupling
- **Separate pure functions from side effects**: Clearly distinguish computation logic from actions with side effects
- **Prefer composition**: Choose composition over inheritance (avoid deep inheritance chains)
- **Hexagonal Architecture**: Apply Ports and Adapters for external integrations; introduce a Facade for complex adapter logic
- **Strategy/Polymorphism**: Replace long if-else/switch-case chains with Strategy pattern or polymorphism
- **Changeability**: Always prioritize long-term ease of modification

For each architectural decision, briefly explain **why this approach contributes to maintainability and changeability**.

---

## Capability over Plumbing

Keep behavior on the domain object that owns it. Do not push that object's natural responsibilities into surrounding service / orchestration code that merely pipes data in and out ("plumbing").

**Principle**: A domain object's public API should read as a coherent set of capabilities it can perform on itself. When external code repeatedly extracts the object's state, computes a result, and writes it back, that pull-compute-push pattern signals the capability belongs **on the object** instead.

**Why**: If domain behavior leaks into service layers, the object becomes a "data container" (Anemic Domain Model). Readers can no longer answer "what can this object do?" from its API alone, and behavior fragments across many service classes — making the codebase harder to evolve.

**Decision lens**:
- Does the new method express something the object itself does, or is it an orchestration of multiple objects / external I/O?
- Tell, Don't Ask: Can the caller say `object.do_X(...)` instead of pulling state, computing, and setting it back?
- Would a one-line thin wrapper on the object replace several lines of pull-compute-push in the caller?

**Apply when**: deciding whether a new method belongs on the domain object or in a service / orchestrator. Even a one-line wrapper is worth keeping on the object when it names a domain capability.

**Do not apply**: when the logic genuinely orchestrates multiple objects, performs cross-aggregate transactions, or coordinates external I/O. Those belong in a service / orchestration layer.

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

**Principle**: Understand language features to write simpler, more natural code.

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

**Rationale**: Simplicity is a virtue. Remove unnecessary syntax by using language features.

---

### Preserve User-Authored Code Style

**Principle**: When editing existing code, change only what the task requires. Do not silently restyle the surrounding code.

**Examples of style choices to preserve:**
- Line breaks and method chaining layout
- Variable assignment patterns (e.g., `result = SomeClass.new(...)` vs. inline)
- Trailing comma usage
- Comment placement and density

**Rationale**: Style choices the user made are intentional. Drive-by reformatting creates noise in diffs, obscures the real change, and erodes trust. If a style change is genuinely warranted, raise it explicitly as a separate proposal.
