---
name: design-principles
description: Use when implementing or reviewing non-trivial design decisions involving responsibility placement, domain behavior, shared abstractions, branching/state rules, coupling, inheritance, public methods, or long-term changeability. Do not trigger for routine edits with no meaningful design choice.
---

# Design Principles

設計判断を、責務、結合度、変更容易性、ドメイン能力の観点から行う。

## Workflow

1. 変更対象だけでなく、呼び出し元、共有仕様、周辺責務を確認する。
2. 判断対象に応じて次の参照を読む。
   - アーキテクチャ、ドメイン能力、コメント、既存スタイル: [references/architecture.md](references/architecture.md)
   - 宣言的設計、責務配置、メソッド抽出、scope、命名、Frontend: [references/design-principles.md](references/design-principles.md)
3. 共有コード、公開仕様、データ形状へ影響する場合は、少なくとも2案を比較する。
4. 採用案が保守性と変更容易性へどう寄与するかを簡潔に説明する。
5. 実装後は、責務の漏出、不要な抽象化、既存スタイルの破壊がないか確認する。

## Guardrails

- パターンを目的化せず、実際の複雑さを減らす場合だけ導入する。
- 外部I/Oや複数オブジェクトの調整を、無理にドメインオブジェクトへ押し込まない。
- メトリクス回避だけを目的にprivate methodを抽出しない。
