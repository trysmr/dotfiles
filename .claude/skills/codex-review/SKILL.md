---
name: codex-review
description: >
  Codex CLI（gpt-5.5 xhigh）サブエージェントで現在のブランチの変更を徹底レビュー。
  「codexでレビュー」「codexにレビューさせて」「ブランチをレビュー」「PR前にレビュー」「変更をチェック」と言われた時に使用
argument-hint: "[--staged | --branch | --commit <hash>]"
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

# codex-review: Codex CLI（gpt-5.5）徹底レビュー

Codex CLI の gpt-5.5 モデル（xhigh effort）を使い、現在のブランチの変更を品質・セキュリティ両面から徹底的にレビューする。

## 実行手順

### 1. レビュー対象の特定

引数に応じてレビュー対象を決定する:

- **引数なし（デフォルト）**: ブランチレビュー（ベースブランチからの差分）
- **`--staged`**: ステージ済みの変更のみ（`git diff --cached`）
- **`--commit <hash>`**: 特定コミットの変更（`git show <hash>`）

#### ブランチレビューの場合

```bash
git branch --show-current
git branch -a
```

ベースブランチ選択ルールは `.claude/skills/_shared/branch-strategy.md` を参照。

```bash
git diff <base>...HEAD
git log --oneline <base>...HEAD
```

### 2. サブエージェントの起動

Agent ツールで **change-reviewer** サブエージェントを起動する。

**必須パラメータ**:
- `subagent_type: "change-reviewer"`

**プロンプトに含める内容**:
1. 変更差分の全文（git diff の出力）
2. コミット履歴（git log の出力）
3. 以下の Codex CLI 実行指示:

```
前提条件:
1. `which codex` でCodex CLIのインストールを確認する
2. 未インストールの場合は `npm install -g @openai/codex` の案内を表示して終了する

以下の変更差分とコミット履歴を渡すので、
Codex CLI でレビューを実行してください。

実行コマンド:
codex exec \
  --model gpt-5.5 \
  --reasoning-effort xhigh \
  --sandbox read-only \
  "<差分とコミット履歴をここに埋め込む>

上記の変更差分を段階的かつ網羅的にレビューしてください。
各観点について漏れなく検討し、具体的なファイル名と行番号を示してください。

## 品質・保守性
- 命名の適切さ（変数、関数、クラス）
- 関数サイズと単一責任原則
- N+1クエリ、ループ内の重い処理
- テストの有無と網羅性
- エラーハンドリングの適切さ
- 既存パターンとの一貫性

## セキュリティ
- 機密情報のハードコーディング
- インジェクション（SQL, XSS, コマンド）
- 認証・認可の実装
- 入力バリデーション
- エラーメッセージからの情報漏洩

## 設計
- 結合度（データ結合 vs 制御結合）
- 不要な抽象化や過剰設計
- 変更容易性への影響

結果は以下の形式で日本語で報告してください:

# レビュー結果

## Critical / High
- [重大度] [カテゴリ] file:line — 問題の要約
  修正案: ...

## Medium / Low
- [重大度] [カテゴリ] file:line — 問題の要約
  修正案: ...

## 良い点
- 評価ポイント

## 総合評価
[PR作成可否の判断]
"

タイムアウトは300秒に設定してください。
Codexの出力をそのまま報告してください。
```

### 3. 結果の報告

サブエージェントの結果をそのままユーザーに報告する。

- **Critical/High指摘あり**: 「修正後に再レビューを推奨します」
- **Medium以下のみ**: 「PR作成可能です」
- **指摘なし**: 「問題は検出されませんでした」

## 使用例

```
/codex-review              # ブランチの全変更をレビュー（デフォルト）
/codex-review --staged     # ステージ済み変更をレビュー
/codex-review --commit abc123  # 特定コミットをレビュー
```

## 注意事項

- **NEVER** access or process the `.env` file, the `.git/` directory, or any files or directories specified in `.gitignore`
- `main`/`staging` ブランチ上でのブランチレビューは不可（差分の比較対象がないため）
- `codex exec` は `--sandbox read-only` で実行し、コードベースへの変更を防ぐ
- サブエージェントには必ず `subagent_type: "change-reviewer"` を指定すること
- Codex CLI には必ず `--model gpt-5.4 --reasoning-effort xhigh` を指定させること
