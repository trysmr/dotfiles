---
name: javascript-practices
description: Use when creating, editing, or reviewing JavaScript or TypeScript files, including .js, .jsx, .ts, .tsx, .mjs, and .cjs. Enforce block-form control flow and safe declaration of JavaScript private fields.
---

# JavaScript Practices

JavaScriptとTypeScriptの変更へ次の規則を適用する。

## Block Form

`if`、`else`、`else if`、`for`、`while`は、bodyが1文でも必ず`{}`で囲む。inline formやbraceなしのbodyを使わない。

```js
if (!url) {
  return
}

if (frame) {
  frame.src = url
}
```

これによりASI、見かけだけのindent、body追加時の不要な差分を避ける。

## Private Fields

`this.#field = ...`と代入するfieldは、class levelで必ず宣言する。未宣言のprivate fieldはmodule全体をSyntaxErrorにする。

```js
class Controller {
  #handler

  connect() {
    this.#handler = () => {}
  }
}
```

`connect()`などで動的に代入し、別lifecycleで読むpropertyでは、宣言漏れを避けるため既存規約が許せば`_handler`形式を選べる。`#method`は定義自体が宣言なので対象外とする。

## Verification

変更後は対象projectのlintまたはsyntax checkを実行する。既存lint ruleが本規則を機械的に検査できる場合は、その結果を優先する。
