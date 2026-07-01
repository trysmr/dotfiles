---
name: code-smell
description: Use when the user asks to detect code smells, コードの臭いを検出, リファクタリング候補を探して, find refactoring opportunities, 設計の問題を洗い出して, or wants a maintainability/design review (not a bug hunt) of a diff, file, or directory.
---

# Code Smell Detection

Martin Fowler『Refactoring』(2nd ed.) の24 Code Smellを手がかりに、「動くが変更しづらいコード」を洗い出す。バグ検出ではなく設計・保守性の観点。各smellにはFowlerが対応づけたリファクタリング手法を必ず添える。

## Workflow

1. 対象を決める。指定がなければブランチ差分。ファイル/ディレクトリ指定ならその範囲全体を読む。
2. 対象を下表の24 smellの観点で精査する。差分だけでは判断できない構造的smell（Large Class, Data Class, Divergent Change）は、変更のあったクラス全体を読んでから判定する。
3. 各指摘に confidence（高/中/低）を付ける。ヒューリスティックゆえ、意図的なValue Object/DTO、ドメイン上必要な重複、whyを説明する正当なコメントは機械的にsmell扱いしない。
4. 「臭う」で終えず、対応するリファクタリング手法名を提示する。検出と提案までが責務で、リファクタリング実行はしない。

## 24 Code Smell と対応リファクタリング

| Smell | サイン | 推奨リファクタリング |
|---|---|---|
| Mysterious Name | 名前から役割が読めない | Rename / Change Function Declaration |
| Duplicated Code | 同じ構造が2箇所以上 | Extract Function / Pull Up Method |
| Long Function | 責務過多で長い | Extract Function / Decompose Conditional |
| Long Parameter List | 引数4つ以上・関連する塊 | Introduce Parameter Object / Preserve Whole Object |
| Global Data | どこからでも書換可能 | Encapsulate Variable |
| Mutable Data | 予期せぬ副作用の温床 | Encapsulate/Split Variable / Separate Query from Modifier |
| Divergent Change | 1クラスが複数理由で変更 | Split Phase / Extract Class |
| Shotgun Surgery | 1変更が多数箇所に波及 | Move Function/Field / Combine Functions into Class |
| Feature Envy | 他オブジェクトを過剰参照 | Move Function / Extract Function |
| Data Clumps | 同じ引数の組が反復 | Extract Class / Introduce Parameter Object |
| Primitive Obsession | 概念をプリミティブで表現 | Replace Primitive with Object / Replace Type Code with Subclasses |
| Repeated Switches | 同じ条件分岐が散在 | Replace Conditional with Polymorphism |
| Loops | パイプライン化できる手続きループ | Replace Loop with Pipeline |
| Lazy Element | 実体のない薄い要素 | Inline Function / Inline Class |
| Speculative Generality | 使われない将来対応の抽象 | Collapse Hierarchy / Remove Dead Code |
| Temporary Field | 特定条件でしか使わない属性 | Extract Class / Introduce Special Case |
| Message Chains | `a.b().c().d()` の連鎖 | Hide Delegate / Extract Function |
| Middle Man | 委譲するだけのクラス | Remove Middle Man / Inline Function |
| Insider Trading | モジュール間の過度な依存 | Move Function/Field / Hide Delegate |
| Large Class | フィールド/メソッドが多すぎ | Extract Class / Extract Superclass |
| Alternative Classes w/ Diff Interfaces | 似た責務でAPI不揃い | Change Function Declaration / Extract Superclass |
| Data Class | データ保持のみで振る舞いなし | Move Function / Encapsulate Record |
| Refused Bequest | 継承したものを使わない | Push Down Method/Field / Replace Subclass with Delegate |
| Comments | 悪いコードの言い訳コメント | Extract Function / Introduce Assertion |

Ruby/Railsが対象なら、頻出の複合パターンにも注意する: Fat Model / Anemic Domain Model（=Data Class）、Callback Hell（副作用をコールバックに詰める=Mutable Data + Insider Trading）、Scope Abuse（画面固有条件をscopeに詰める=Divergent Change）。`reduce`+条件付き`push`は`filter_map`へ（Replace Loop with Pipeline）。

## Output

Findingsを重大度順（High/Medium/Low、保守性への影響で判断）に書く。各項目は `[Smell名 / 和名] file:line (confidence)` + 症状（コード根拠）+ 推奨リファクタリング。最後に着手優先順位と最初の一手を述べる。指摘がなければ「顕著なCode Smellなし」と明記する。
