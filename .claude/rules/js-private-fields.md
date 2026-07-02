---
paths:
  - "**/*.{js,jsx,ts,tsx,mjs,cjs}"
---

# JS Private Fields: Class-Level Declaration Required

When assigning `this.#field = ...`, the field must be declared at class level. Without the declaration it is a SyntaxError, which silently breaks the entire module.

```js
// BAD: SyntaxError — the whole controller fails to load
class Foo extends Controller {
  connect() {
    this.#handler = () => { ... }  // undeclared
  }
}

// GOOD: declared at class level
class Foo extends Controller {
  #handler

  connect() {
    this.#handler = () => { ... }
  }
}

// GOOD: `_` prefix convention, no declaration needed
class Foo extends Controller {
  connect() {
    this._handler = () => { ... }
  }
}
```

For dynamically assigned properties (set in `connect()`, read in `disconnect()`, etc.), the `_` prefix convention avoids the risk of a forgotten declaration. `#` methods are not affected — declaration and definition are one.
