---
name: code-smell
description: >
  Martin Fowler『Refactoring』の24 Code Smellを検出し、推奨リファクタリングを提示。
  「コードの臭いを検出」「code smell」「リファクタリング候補を探して」「設計の問題を洗い出して」
  「この関数/クラスは大きすぎない?」「保守しづらい箇所を指摘して」と言われた時に使用。
  差分レビューでも既存ファイル/ディレクトリの棚卸しでも使える。バグ検出ではなく設計・保守性の観点。
argument-hint: "[--branch | --uncommitted | --staged | --commit <hash> | ファイルパス | ディレクトリパス]"
context: fork
agent: general-purpose
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Agent
user-invocable: true
---

# code-smell: Fowler Code Smell 検出

Martin Fowler『Refactoring』(2nd ed.)で定義された24種のCode Smellを検出し、各smellにFowlerが対応づけた推奨リファクタリングを提示する。目的は**バグ検出ではなく設計・保守性の改善**。「動くが変更しづらいコード」を洗い出すためのスキル。

## このスキルの立ち位置

- `deep-review` / `codex-review`: バグ・セキュリティ中心の変更差分レビュー
- **`code-smell`（本スキル）**: 設計臭・保守性の観点に特化。リファクタリング候補の棚卸し

両者は補完関係にある。PR前に両方走らせてもよい。

## 実行手順

### 1. 検出対象の特定

引数に応じて対象を決定する:

- **引数なし / `--branch`（デフォルト）**: ブランチ差分（ベースブランチからの変更）
- **`--uncommitted`**: 未コミットの変更（`git diff`）
- **`--staged`**: ステージ済みの変更（`git diff --cached`）
- **`--commit <hash>`**: 特定コミット（`git show <hash>`）
- **ファイルパス指定**: 指定ファイル全体を直接分析
- **ディレクトリパス指定**: 配下のソースファイル群を分析（`Glob`で対象を列挙）

#### ブランチ差分の場合

```bash
git branch --show-current
git branch -a
```

ベースブランチ選択ルールは `.claude/skills/_shared/branch-strategy.md` を参照。

```bash
git diff <base>...HEAD
git log --oneline <base>...HEAD
```

> **差分 vs ファイル全体の注意**: 差分だけでは「Large Class」「Data Class」「Divergent Change」など**クラス全体を見ないと判断できないsmell**は見逃しやすい。差分レビューで大きなクラスに変更が入っていたら、そのファイル全体を`Read`してから判定すること。

### 2. サブエージェントの起動

`software-engineer` サブエージェントを起動し、Code Smell検出を委譲する。24 smellの網羅チェックはコンテキストを消費するため、メイン会話から隔離する。

**必須パラメータ**:
- `subagent_type: "software-engineer"`

**プロンプトに含める内容**:
1. 検出対象（git diff の全文、または対象ファイルの内容/パス）
2. リポジトリの主要言語（Ruby/Rails なら後述のRails補足を読むよう指示）
3. 以下の検出指示:

```
effort を high に設定してください。
検出結果の本文を、この応答内で必ず返しきってください。バックグラウンド化や
「実行中です／完了次第報告します」といった先送り応答は禁止。あなたの最終メッセージが
そのまま検出結果として使われます。

あなたは Martin Fowler『Refactoring』(2nd ed.) の Code Smell 検出器です。
まず `~/.claude/skills/code-smell/references/smell-catalog.md` を読み、24種のsmellの
検出基準と推奨リファクタリングを把握してください。
対象がRuby/Railsの場合は `~/.claude/skills/code-smell/references/rails-smells.md` も読んでください。
（`~/.claude/skills` は実体へのsymlink。CWDに依存せずこの絶対パスで読めます）

対象コードを24 smellの観点で網羅的に精査し、該当箇所を報告してください。

## 検出の心得
- Code Smellはヒューリスティック。確実な違反ではなく「臭い」を示す。誤検出を避けるため、
  各指摘に confidence（高/中/低）を付ける。意図的なValue Object、ドメイン上必要な
  重複、正当な説明コメントを機械的にsmell扱いしない。
- 1つの箇所が複数のsmellに該当することがある（例: Large Class かつ Data Class）。
  最も本質的なsmell名を主として挙げ、副次的なものは補足で触れる。
- 「臭う」だけで終わらせず、Fowlerが対応づけた具体的リファクタリング名を必ず添える。

## 出力形式（日本語）

# Code Smell 検出結果

## サマリ
- 検出対象: <ブランチ差分 / ファイルパス 等>
- 検出件数: High N件 / Medium N件 / Low N件

## High（変更を頻繁に妨げる・バグ温床になりやすい）
- **[Smell名(EN) / 和名]** `file:line` (confidence: 高/中/低)
  - 症状: 何がどう臭うか（具体的なコード根拠）
  - 推奨リファクタリング: `Extract Function` 等（Fowlerの手法名）
  - 補足: 副次的smellや適用時の注意（あれば）

## Medium
（同形式）

## Low
（同形式）

## 総評
- リファクタリング着手の優先順位と、最初の一手の提案

指摘が全くない場合は「顕著なCode Smellは検出されませんでした」と報告してください。
```

### 3. 結果の統合と報告

サブエージェントの結果を優先度順にユーザーへ報告する。

- **High指摘あり**: 「変更容易性に影響するsmellがあります。着手優先順位は上記の通りです」
- **Medium以下のみ**: 「軽微なsmellのみです。必要に応じて対応してください」
- **指摘なし**: 「顕著なCode Smellは検出されませんでした」

このスキルは**検出と提案まで**を担い、リファクタリングの実行は行わない。ユーザーが着手を指示したら、通常の実装フロー（テスト方針含む）に従う。

## 24 Code Smell 早見表

詳細な検出基準は `~/.claude/skills/code-smell/references/smell-catalog.md`。以下は網羅チェック用の一覧。

| # | Smell (EN) | 和名 | 一言サイン |
|---|---|---|---|
| 1 | Mysterious Name | 不可解な名前 | 名前から役割が読めない |
| 2 | Duplicated Code | 重複コード | 同じ構造が2箇所以上 |
| 3 | Long Function | 長い関数 | 1画面に収まらない/責務過多 |
| 4 | Long Parameter List | 長いパラメータリスト | 引数が4つ以上・関連する塊 |
| 5 | Global Data | グローバルデータ | どこからでも書き換え可能 |
| 6 | Mutable Data | 可変データ | 予期せぬ副作用の温床 |
| 7 | Divergent Change | 発散的変更 | 1クラスが複数理由で変更される |
| 8 | Shotgun Surgery | 散弾銃手術 | 1変更が多数箇所に波及 |
| 9 | Feature Envy | 機能の横恋慕 | 他オブジェクトの状態を過剰参照 |
| 10 | Data Clumps | データの群れ | 同じ引数の組が繰り返し出現 |
| 11 | Primitive Obsession | 基本型への執着 | 概念をプリミティブで表現 |
| 12 | Repeated Switches | 重複したスイッチ文 | 同じ条件分岐が散在 |
| 13 | Loops | ループ | パイプライン化できる手続きループ |
| 14 | Lazy Element | 怠惰な要素 | 実体のない薄いクラス/関数 |
| 15 | Speculative Generality | 憶測による一般化 | 使われない将来対応の抽象 |
| 16 | Temporary Field | 一時的属性 | 特定条件でしか使わないフィールド |
| 17 | Message Chains | メッセージの連鎖 | `a.b().c().d()` の連鎖 |
| 18 | Middle Man | 仲介人 | 委譲するだけのクラス |
| 19 | Insider Trading | インサイダー取引 | モジュール間の過度な依存 |
| 20 | Large Class | 巨大クラス | フィールド/メソッドが多すぎ |
| 21 | Alternative Classes w/ Diff Interfaces | 異なるインタフェースの代替クラス | 似た責務なのにAPIが不揃い |
| 22 | Data Class | データクラス | データ保持のみで振る舞いなし |
| 23 | Refused Bequest | 拒否された遺贈 | 継承したものを使わない |
| 24 | Comments | コメント | 悪いコードの言い訳コメント |

## 使用例

```
/code-smell                  # ブランチ差分のsmell検出（デフォルト）
/code-smell --uncommitted    # 未コミット変更を検出
/code-smell app/models/      # 指定ディレクトリの棚卸し
/code-smell lib/parser.rb    # 単一ファイルを精査
```

## 注意事項

- **NEVER** access or process the `.env` file, the `.git/` directory, or any files or directories specified in `.gitignore`
- `main`/`staging` ブランチ上でのブランチ差分検出は不可（比較対象がないため、ファイル/ディレクトリ指定を使う）
- Code Smellは**臭いであって欠陥ではない**。指摘は「変更容易性を下げている可能性」の提示であり、リファクタリング判断はコンテキスト（変更頻度・チーム状況）を踏まえてユーザーが行う
