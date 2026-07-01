# Ruby/Rails 固有 Code Smell 補足

`smell-catalog.md` の24 smellに加え、Ruby/Railsで頻出する固有パターン。対象がRuby/Railsの場合に併せて参照する。Fowlerの汎用smellがRails文脈でどう現れるかの写像を含む。

## Rails固有パターン

### Fat Model / God Model
**症状**: ActiveRecordモデルにビジネスロジック・バリデーション・コールバック・スコープが集中し肥大化。
**対応smell**: Large Class + Divergent Change の典型例。
**推奨リファクタリング**: Extract Class（Value Object、Form Object、Service Object、Query Object へ責務分離）。ドメインロジックはPORO（Plain Old Ruby Object）へ切り出す。
**注意**: 振る舞いをむやみにService層へ移すと逆にAnemic Domain Model（Data Class）を招く。「モデル自身の能力」はモデルに残す（Tell, Don't Ask）。

### Anemic Domain Model
**症状**: モデルがカラムのアクセサだけになり、ロジックがサービス/ヘルパーに散る。
**対応smell**: Data Class そのもの。
**推奨リファクタリング**: pull-compute-push（外部でモデルの状態を取り出し計算して書き戻す）パターンを見つけたら、その能力をモデルのメソッドへ移す（Move Function）。

### Callback Hell
**症状**: `before_save` / `after_create` 等のコールバックに副作用（メール送信、外部API、他モデル更新）が積まれ、保存の副作用が追跡不能。
**対応smell**: Mutable Data + Insider Trading（暗黙の密結合）。
**推奨リファクタリング**: 副作用をコールバックから明示的なサービス呼び出しへ移動（Separate Query from Modifier の精神）。純粋な整合性維持のみコールバックに残す。

### Scope Abuse
**症状**: 画面固有・ユーザー依存・検索フォーム条件などをActiveRecordのscopeに詰め込む。
**対応smell**: Divergent Change（モデルが画面都合で変更される）。
**推奨リファクタリング**: Extract Class として Query Object（Relationを受け取りRelationを返す）へ。scopeは「論理削除状態」「レコード固有属性の分類」など安定したドメイン語彙に限定する。

### Fat Controller
**症状**: コントローラのアクションにビジネスロジック・複雑な条件分岐・データ整形が詰まる。
**対応smell**: Long Function + Feature Envy（モデルの状態を取り出して加工）。
**推奨リファクタリング**: Extract Function してモデル/サービスへ Move Function。コントローラは「入力受付・呼び出し・応答」に絞る。

## Ruby表現レベルのsmell写像

### Loops -> Enumerable パイプライン
`each` で手続き的にフィルタ・変換・集計しているコードは、`select` / `map` / `reject` / `sum` / `group_by` 等のパイプラインへ（Replace Loop with Pipeline）。
```ruby
# 臭う: 意図が手続きに埋もれる
result = []
items.each { |i| result << i.price if i.active? }

# 意図が明確
result = items.select(&:active?).map(&:price)
```

### Primitive Obsession -> Value Object
金額・期間・識別子などをString/Integerのまま扱うなら、値オブジェクト化を検討（Replace Primitive with Object）。RailsではActiveModel::AttributesやcomposedのValue Objectパターン。

### Repeated Switches -> ポリモーフィズム / STI
`case type when :a ... when :b` が散在するなら、型ごとのクラス（Strategy、STI、`Comparable`等の多態）へ（Replace Conditional with Polymorphism）。

### Long Parameter List -> Keyword Args / Parameter Object
関連する引数の塊は、キーワード引数の整理だけでなく、意味のある値オブジェクト/Structへまとめる（Introduce Parameter Object）。

## Rails文脈での誤検出に注意

以下は「臭い」に見えても正当なことが多い。機械的にsmell扱いしない:

- **DTO/シリアライザ/APIレスポンス構造体がData Class**: 意図的なデータ運搬役なら正当。
- **マイグレーションファイルの重複的記述**: 生成物であり、DRY化対象外。
- **フィクスチャ/ファクトリのデータ重複**: テストの独立可読性のため、あえてDRYにしない方針もある。
- **RESTfulな7アクションのコントローラ**: Railsの規約に沿った標準構造は Large Class ではない。
- **規約に沿ったコールバック（`dependent: :destroy` 相当の整合性維持）**: 副作用が重くなければ許容。

判定時は「Railsの規約・慣習として妥当か」を一段考慮してから指摘する。
