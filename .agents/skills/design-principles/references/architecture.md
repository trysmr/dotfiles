# アーキテクチャ原則

## 基本原則

- データ結合やスタンプ結合を優先し、制御結合や共通結合を避ける。
- 純粋な計算と副作用を分離する。
- 深い継承よりcompositionを選ぶ。
- 外部連携にはPorts and Adaptersを検討し、複雑なadapterにはFacadeを置く。
- 長い条件分岐が責務の違いを表す場合はStrategyやpolymorphismを検討する。
- 短期の実装速度より、長期の変更容易性を優先する。

重要な設計判断では、その選択が保守性と変更容易性にどう寄与するかを説明する。

## Capability over Plumbing

自然な振る舞いは、その状態を所有するdomain objectへ置く。周辺serviceが状態を取り出し、計算して戻すだけのpull-compute-pushになっている場合は、object自身の能力として表現できないか確認する。

判断時は次を確認する。

- その操作はobject自身が行うものか、複数objectや外部I/Oの調整か。
- callerが状態を取得して加工するより、`object.do_x(...)`と命令する方が自然か。
- 薄いwrapperでも、domain能力へ名前を付け、将来のhook面を提供できるか。

複数aggregateのtransactionや外部I/Oの調整はserviceへ置く。

## コメントと明瞭さ

- コメントは処理内容ではなく、コードが必要な理由を説明する。
- 言語のidiomを理解し、不要な構文を除く。
- 既存コードを変更するときは、依頼に不要な整形やstyle変更を行わない。
- 改行、method chain、変数代入、末尾comma、コメント配置など、既存の選択を尊重する。
