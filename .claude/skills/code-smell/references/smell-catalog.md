# Fowler Code Smell カタログ（言語非依存）

Martin Fowler『Refactoring』(2nd ed.) の24 Code Smellの検出基準と、Fowlerが対応づけた推奨リファクタリング。各smellは「臭い（変更しづらさの兆候）」であって欠陥ではない。確信を持って断定せず、根拠を示して提案する。

## 目次

1. [Mysterious Name / 不可解な名前](#1-mysterious-name)
2. [Duplicated Code / 重複コード](#2-duplicated-code)
3. [Long Function / 長い関数](#3-long-function)
4. [Long Parameter List / 長いパラメータリスト](#4-long-parameter-list)
5. [Global Data / グローバルデータ](#5-global-data)
6. [Mutable Data / 可変データ](#6-mutable-data)
7. [Divergent Change / 発散的変更](#7-divergent-change)
8. [Shotgun Surgery / 散弾銃手術](#8-shotgun-surgery)
9. [Feature Envy / 機能の横恋慕](#9-feature-envy)
10. [Data Clumps / データの群れ](#10-data-clumps)
11. [Primitive Obsession / 基本型への執着](#11-primitive-obsession)
12. [Repeated Switches / 重複したスイッチ文](#12-repeated-switches)
13. [Loops / ループ](#13-loops)
14. [Lazy Element / 怠惰な要素](#14-lazy-element)
15. [Speculative Generality / 憶測による一般化](#15-speculative-generality)
16. [Temporary Field / 一時的属性](#16-temporary-field)
17. [Message Chains / メッセージの連鎖](#17-message-chains)
18. [Middle Man / 仲介人](#18-middle-man)
19. [Insider Trading / インサイダー取引](#19-insider-trading)
20. [Large Class / 巨大クラス](#20-large-class)
21. [Alternative Classes with Different Interfaces / 異なるインタフェースの代替クラス](#21-alternative-classes)
22. [Data Class / データクラス](#22-data-class)
23. [Refused Bequest / 拒否された遺贈](#23-refused-bequest)
24. [Comments / コメント](#24-comments)

---

## 1. Mysterious Name
**症状**: 変数・関数・クラス・モジュールの名前から、それが何をするか・何を表すかが読み取れない。省略しすぎ、汎用的すぎ（`data`, `manager`, `process`）、実態と乖離。
**検出のサイン**: 名前を見ただけでは中身を推測できず、実装を読まないと使えない。命名にコメントで補足が付いている。
**推奨リファクタリング**: Change Function Declaration / Rename Variable / Rename Field
**注意**: ドメイン用語として正しい名前を「不可解」と誤判定しない。チーム/業界の語彙は尊重する。

## 2. Duplicated Code
**症状**: 同じ、またはほぼ同じコード構造が2箇所以上に存在する。片方を直したらもう片方も直す必要がある。
**検出のサイン**: コピペの痕跡、酷似したメソッド、同じ条件式の反復。
**推奨リファクタリング**: Extract Function（同一クラス内）/ Slide Statements（重複を隣接させてから抽出）/ Pull Up Method（兄弟サブクラス間）
**注意**: 「たまたま今は同じ」だが将来異なる方向に変化するコードは、無理にDRY化するとかえって結合を生む。変更理由が同じか確認する。

## 3. Long Function
**症状**: 関数が長く、複数の責務を抱えている。「何をするか」を理解するのに時間がかかる。
**検出のサイン**: 数十行超、コメントでセクション分けされている、ローカル変数が多い、ネストが深い。
**推奨リファクタリング**: Extract Function（最有力）/ Replace Temp with Query / Introduce Parameter Object / Preserve Whole Object / Replace Function with Command / Decompose Conditional / Replace Conditional with Polymorphism / Split Loop
**判断軸**: 行数そのものより「異なる抽象度・責務が混在しているか」。意図が名前で説明できる単位に切り出せるか。

## 4. Long Parameter List
**症状**: 引数が多すぎて呼び出しが読みづらく、間違えやすい。
**検出のサイン**: 引数4つ以上、フラグ引数、いつも一緒に渡される引数の塊。
**推奨リファクタリング**: Replace Parameter with Query（他引数から導出可能な場合）/ Preserve Whole Object / Introduce Parameter Object / Remove Flag Argument / Combine Functions into Class
**注意**: 関連する引数の塊は Data Clumps でもある。まとめてオブジェクト化を検討。

## 5. Global Data
**症状**: どこからでも読み書きできるデータ（グローバル変数、シングルトン、クラス変数）。どこで変更されたか追跡不能。
**検出のサイン**: グローバル/クラス変数への直接代入が複数箇所に散在。
**推奨リファクタリング**: Encapsulate Variable（アクセスを関数経由に限定し、変更点を1箇所に絞る）
**注意**: 定数（不変のグローバル）は問題になりにくい。可変であることが臭いの本質。

## 6. Mutable Data
**症状**: データの変更が予期せぬ箇所に波及し、バグの温床になる。
**検出のサイン**: 1つの変数が複数の目的で再代入される、更新メソッドが計算とセットを兼ねる、派生値が手動で同期されている。
**推奨リファクタリング**: Encapsulate Variable / Split Variable（1変数1責務に分割）/ Separate Query from Modifier / Remove Setting Method / Replace Derived Variable with Query / Change Reference to Value
**注意**: 関数型的な不変データへの寄せは有効だが、パフォーマンス要件とバランスを取る。

## 7. Divergent Change
**症状**: 1つのモジュール/クラスが、**異なる理由で**何度も変更される。「DB接続の変更でも触るし、税計算の変更でも触る」。
**検出のサイン**: 無関係な複数の関心事が1クラスに同居。変更履歴が多方向。
**推奨リファクタリング**: Split Phase / Move Function / Extract Function / Extract Class（関心事ごとにクラスを分ける）
**対の概念**: Shotgun Surgery（1変更が多クラスに波及）と逆方向。Divergentは「1クラスに多責務」。

## 8. Shotgun Surgery
**症状**: 1つの変更をするのに、多数のクラス/ファイルを少しずつ修正して回る必要がある。修正漏れが起きやすい。
**検出のサイン**: 同種のロジックが多数のファイルに分散、1機能の追加で広範囲を触る。
**推奨リファクタリング**: Move Function / Move Field / Combine Functions into Class / Combine Functions into Transform / Split Phase / Inline Function / Inline Class（散らばった責務を1箇所に集約）
**対の概念**: Divergent Change の逆。Shotgunは「1責務が多クラスに散在」。

## 9. Feature Envy
**症状**: ある関数が、自分の所属クラスより他クラスのデータ・メソッドを盛んに使う。データの近くに振る舞いがない。
**検出のサイン**: `other.x, other.y, other.z` を取り出して計算している。Tell, Don't Ask 違反。
**推奨リファクタリング**: Move Function（データのある側へ移動）/ Extract Function（羨望部分だけ切り出して移動）
**注意**: 意図的に振る舞いとデータを分離する設計（Strategy等）は例外。

## 10. Data Clumps
**症状**: 同じデータの組（例: `startDate` と `endDate`、`x`/`y`/`z`）が、あちこちで一緒に現れる。
**検出のサイン**: 複数のメソッド引数やフィールドで同じ組み合わせが反復。1つ消すと他が無意味になる関係。
**推奨リファクタリング**: Extract Class（フィールドの塊）/ Introduce Parameter Object（引数の塊）/ Preserve Whole Object
**効果**: 塊をオブジェクト化すると、その概念に振る舞いを持たせられ、Primitive Obsession の解消にも繋がる。

## 11. Primitive Obsession
**症状**: 電話番号・金額・座標などのドメイン概念を、文字列や数値などのプリミティブ型のまま扱う。バリデーションや書式がコードに散る。
**検出のサイン**: 「文字列だが実は特定フォーマット」「数値だが単位付き」、型コード（`type == 1`）。
**推奨リファクタリング**: Replace Primitive with Object / Replace Type Code with Subclasses / Replace Conditional with Polymorphism / Extract Class / Introduce Parameter Object
**効果**: 値オブジェクト化でバリデーション・振る舞いを凝集できる。

## 12. Repeated Switches
**症状**: 同じ条件分岐（switch/if-else連鎖）が複数箇所に現れる。分岐対象の追加時に全switchを直す必要がある（Shotgun Surgeryの一形態）。
**検出のサイン**: 同じ列挙値・型コードに対するswitchが散在。
**推奨リファクタリング**: Replace Conditional with Polymorphism（分岐をクラス階層/多態に置き換え）
**注意**: 単発のswitchは問題ない。「同じ分岐の繰り返し」が臭いの本質。

## 13. Loops
**症状**: 手続き的なループが、意図（filter/map/reduce）を隠している。
**検出のサイン**: ループ内でフィルタ・変換・集計が混在し、何をしたいか読み取りにくい。
**推奨リファクタリング**: Replace Loop with Pipeline（コレクションパイプライン。Rubyなら `select`/`map`/`sum` 等）
**注意**: パイプライン化で読みやすくなる場合に限る。パフォーマンスクリティカルな箇所は慎重に。

## 14. Lazy Element
**症状**: 実体に見合わない要素。ほとんど何もしない関数、フィールド1つだけのクラス、1回しか呼ばれない薄い抽象。
**検出のサイン**: 委譲や単純な受け渡しだけの構造、将来性を見込んで作ったが育たなかった要素。
**推奨リファクタリング**: Inline Function / Inline Class / Collapse Hierarchy
**注意**: 名前による説明価値がある薄い要素（ドメイン概念を表す）は残す。純粋な冗長のみ対象。

## 15. Speculative Generality
**症状**: 「いつか必要になるかも」で作った、現在使われていない抽象・フック・パラメータ。
**検出のサイン**: 唯一の実装しかない抽象基底、使われない引数、テストしか使わないメソッド、意味のない委譲。
**推奨リファクタリング**: Collapse Hierarchy / Inline Function / Inline Class / Change Function Declaration（未使用引数の除去）/ Remove Dead Code
**注意**: YAGNI。実需のない一般化は保守コストだけ増やす。

## 16. Temporary Field
**症状**: 特定の状況でのみ値が設定され、それ以外は空/nullのフィールド。オブジェクトの状態が読みにくい。
**検出のサイン**: 「このメソッドを呼んだ後だけ有効」なフィールド、条件分岐でしか使わない属性。
**推奨リファクタリング**: Extract Class（一時フィールド群を専用クラスへ）/ Move Function / Introduce Special Case（Null Object等）
**注意**: 空値チェックが散在していたら候補。

## 17. Message Chains
**症状**: `a.getB().getC().getD().doIt()` のように、オブジェクトをたどる連鎖。中間構造の変更に脆い（Law of Demeter違反）。
**検出のサイン**: ドット連鎖でナビゲート、中間オブジェクトを取り出して次を辿る。
**推奨リファクタリング**: Hide Delegate（中間を隠蔽）/ Extract Function + Move Function（連鎖の利用を適切な場所へ）
**注意**: 過度なHide Delegateは Middle Man を生む。バランスを見る。

## 18. Middle Man
**症状**: クラスのメソッドの多くが、単に別オブジェクトへ委譲するだけ。存在価値が薄い。
**検出のサイン**: メソッド本体が `delegate.method()` ばかり。
**推奨リファクタリング**: Remove Middle Man（クライアントに直接呼ばせる）/ Inline Function / Replace Superclass with Delegate / Replace Subclass with Delegate
**対の概念**: Message Chains 対策のやりすぎで生じることがある。

## 19. Insider Trading
**症状**: モジュール/クラス同士が内部事情を過剰に知り合い、密結合している。プライベートな取引が多い。
**検出のサイン**: 相互参照、内部状態への相互アクセス、頻繁な内緒のやり取り。
**推奨リファクタリング**: Move Function / Move Field（依存を減らす配置替え）/ Hide Delegate / Replace Subclass with Delegate / Replace Superclass with Delegate
**注意**: 継承関係は密結合になりがち。委譲への置き換えを検討。

## 20. Large Class
**症状**: 1クラスがフィールド・メソッドを抱えすぎ、複数の責務を持つ。
**検出のサイン**: フィールド数が多い、接頭辞でグルーピングされたフィールド群、行数肥大。
**推奨リファクタリング**: Extract Class（責務の塊を分離）/ Extract Superclass / Replace Type Code with Subclasses
**判断軸**: 「このクラスの責務を一文で言えるか」。言えなければ分割候補。差分だけでなくクラス全体を見て判断する。

## 21. Alternative Classes with Different Interfaces
**症状**: 似た役割のクラスなのに、メソッド名・シグネチャが揃っていない。差し替えられない。
**検出のサイン**: 同種の処理をするクラス群でAPIが不揃い、条件分岐で使い分けている。
**推奨リファクタリング**: Change Function Declaration（シグネチャを揃える）/ Move Function（差異を吸収）/ Extract Superclass（共通インタフェース抽出）
**効果**: インタフェースを揃えると Strategy/多態で扱えるようになる。

## 22. Data Class
**症状**: フィールドとゲッター/セッターしか持たず、振る舞いのないクラス。ロジックが外部（サービス層）に散る（Anemic Domain Model）。
**検出のサイン**: getter/setterのみ、外部コードがこのクラスのデータを取り出して計算し書き戻す（pull-compute-push）。
**推奨リファクタリング**: Encapsulate Record / Remove Setting Method / Move Function（振る舞いをデータの側へ）/ Extract Function / Split Phase
**注意**: 意図的なDTO/値オブジェクト/APIレスポンス構造体は正当。「振る舞いを持つべきなのに持っていない」ドメインオブジェクトが対象。

## 23. Refused Bequest
**症状**: サブクラスが親から継承したメソッド/フィールドを使わない、または不適切に上書きする。継承関係が実態に合っていない。
**検出のサイン**: 継承したメソッドを空実装/例外throwでオーバーライド、親のAPIの一部しか使わない。
**推奨リファクタリング**: Push Down Method / Push Down Field（使うサブクラスにだけ下ろす）/ Replace Subclass with Delegate / Replace Superclass with Delegate（継承を委譲に）
**判断軸**: 「is-a」が本当に成立しているか。していなければ委譲へ。

## 24. Comments
**症状**: コメントが、分かりにくいコードの言い訳・消臭剤として使われている。「コメントが必要 = コードが説明不足」のサイン。
**検出のサイン**: 複雑なブロックの前の解説コメント、コードの動作をそのまま説明するコメント。
**推奨リファクタリング**: Extract Function（コメント範囲を命名付き関数に）/ Change Function Declaration（名前で意図を表現）/ Introduce Assertion（前提条件をコード化）
**重要な注意**: **コメント自体は悪ではない**。「なぜそうするか（why）」を説明する良いコメントは残す・推奨する。臭うのは「whatを説明して消臭している」コメントのみ。良いコメントを機械的にsmell扱いしないこと。
