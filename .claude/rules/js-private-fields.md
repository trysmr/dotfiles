---
paths:
  - "**/*.{js,jsx,ts,tsx,mjs,cjs}"
---

# JS Private Fields: クラスレベル宣言必須

`this.#field = ...`でプライベートフィールドを使う場合、クラスレベルで宣言が必要。宣言なしだとSyntaxErrorでモジュール全体がサイレントに壊れる。

```js
// BAD: SyntaxErrorでコントローラー全体が読み込まれない
class Foo extends Controller {
  connect() {
    this.#handler = () => { ... }  // 未宣言
  }
}

// GOOD: クラスレベルで宣言
class Foo extends Controller {
  #handler

  connect() {
    this.#handler = () => { ... }
  }
}

// GOOD: 宣言不要な_プレフィックス慣習
class Foo extends Controller {
  connect() {
    this._handler = () => { ... }
  }
}
```

動的に代入するプロパティ（`connect()`で設定して`disconnect()`で参照する等）は`_`プレフィックス慣習の方が宣言忘れリスクがない。`#`メソッドは宣言と定義が一体なので問題にならない。
