# Design Principles

## Declarative Design

Express complex branching logic (state transitions, rule sets, etc.) as data structures rather than procedural code.

- **Prefer pure functions**: Isolate side effects; increase functions whose behavior is determined solely by inputs and outputs
- **Express as data**: When if/case branches have rule-like properties, convert them to data structures. Data can be enumerated, searched, and validated — logic cannot
- **Prove with invariants**: Test data structure integrity exhaustively, guaranteeing correctness of the entire structure rather than enumerating individual cases
- **Make composable**: Build complex behavior by combining small pure functions and data transformations

---

## Responsibility-Based Placement

Decide where to place classes, constants, and errors based on **which module owns the responsibility**, not on which location is most convenient to use.

When presenting placement options, lead with the responsibility perspective. Mention convenience only as a supplement.

---

## Method Extraction Criteria

Extraction decisions depend on the **visibility** of the method.
Private/internal methods are evaluated from a **code structure** perspective; public methods are evaluated from a **domain capability** perspective. Use both lenses; do not collapse one into the other.

### Private / internal method: code structure perspective

Only extract a private/internal method when **all three** of the following are true. If any is "No", keep it inline.

1. Does the same logic exist in 2+ places? (eliminating duplication)
2. Would the code be hard to understand without that name? (abstraction payoff)
3. Is the body long enough to disrupt the flow at the call site? (readability improvement)

### Public method: domain capability perspective

When a method represents an **object's capability** (something the object itself does), the structure criteria above are insufficient. Also evaluate:

1. **Tell, Don't Ask**: Is it more natural to tell the object to do something than to extract its state and have the caller compute the result? If yes, keep the method.
2. **Symmetry with existing capabilities**: Does the method sit naturally alongside other public methods on the object? An object's public API should read as a coherent set of behaviors, not a random grab bag.
3. **Future hook surface**: Is there a plausible future need to inject callbacks, observability, or lifecycle hooks around this capability? A named method gives you the seam.
4. **Avoid Anemic Domain Model**: Removing the method should not demote the object to a "data container" with logic scattered into surrounding service / orchestration layers.

Keep capability methods even when there is no duplication, the body is short, and there is only one caller — if the method expresses a domain concept.

### When hitting metric limits

Extracting solely to reduce line count is counterproductive. When hitting metric limits, follow this order:

1. Can the responsibility be delegated to a separate class?
2. Can early returns or guard clauses reduce complexity?
3. Can data structuring reduce branches?
4. If extraction is truly needed, design the extracted method to satisfy the appropriate criteria above

---

## ActiveRecord Scope Restrictions (Rails)

Only allow scopes for **stable domain vocabulary** — universal properties of the model that do not depend on usage context.

**Acceptable:** Logical deletion states (`kept` / `discarded`), classifications by record-intrinsic attributes

**Not scopes:** Screen/use-case-specific filters, current-user-dependent queries, search form conditions, aggregation/report queries

When collection operations are needed, extract them as Query Objects that accept and return Relations.

---

## Naming Conventions

### Boolean Columns and Methods

Prefix boolean columns and predicate-style attributes with `is_` or `has_` (e.g., `is_active`, `has_attachments`). This overrides Rails' convention of unprefixed booleans.

**Rationale**: The column name alone should reveal the type. `published` reads as a past participle and could plausibly be a date or status string; `is_published` is unambiguously boolean.

**Apply at**: New table creation and column additions. Existing unprefixed boolean columns are not retroactively renamed unless the surrounding code is being touched.

---

## Frontend Style Adherence

When matching an existing component's appearance (font size, padding, height, spacing), do **not** guess values and iterate by screenshot. Read the existing component's computed values via DevTools first, then apply them.

- **First choice**: Reuse the existing CSS class directly. Do not reimplement the same look with new selectors.
- **If reimplementation is necessary**: Inspect the reference component in DevTools, copy the computed values, and use those literals.
- **Verify before declaring done**: Place the new and reference components side-by-side in the same view (or screenshot) to confirm alignment.
- **Visual fine-tuning belongs in a separate session** with the browser open. Don't try to converge on pixel-perfect output through guess-adjust-screenshot loops.

**Rationale**: Guess-and-check loops on CSS waste massive time and rarely converge. The reference component's computed values are the ground truth.
