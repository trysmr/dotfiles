---
name: codex-review
description: Codex CLIを使ってコードやドキュメントをレビュー。「codexでレビュー」「codexにレビューさせて」「計画書をチェック」「ブランチをレビュー」「PR前にレビュー」「変更をチェック」と言われた時に使用
argument-hint: "[ファイルパス | --uncommitted | --branch]"
context: fork
agent: general-purpose
allowed-tools:
  - Bash
  - Read
---

# Codex Review

OpenAI Codex CLIを使ってコードやドキュメントをレビューします。

## レビュー対象

$ARGUMENTS

## 実行手順

### 1. レビュー対象の判定

引数に応じて実行方法を決定：
- **ファイルパス指定** → `codex exec`でファイルレビュー
- **`--uncommitted`指定** → `codex review --uncommitted`で未コミット変更をレビュー
- **`--branch`指定 or 引数なし** → ブランチレビュー（デフォルト）

### 2. Codex CLIの実行

#### ファイルレビューの場合

```bash
codex exec "<ファイルパス> をレビューしてください。問題点、改善提案、矛盾がないか確認してください。日本語で回答してください。" --sandbox read-only
```

#### 未コミット変更レビューの場合

```bash
codex review --uncommitted
```

#### ブランチレビューの場合

**ステップ1: 現在のブランチを確認**

```bash
git branch --show-current
```

**`main`または`staging`上にいる場合はエラー**:
フィーチャーブランチ上で実行してください。`main`/`staging`では比較対象がないため実行できません。

**ステップ2: ベースブランチを検出**

```bash
git branch -a
```

**ベースブランチ選択ルール**（`pr`/`create-branch`スキルと共通）：
- `hotfix/*` → `main`をベースにする
- **その他すべて** → `staging`が存在する場合は`staging`、存在しない場合は`main`をベースにする

検出結果をユーザーに表示してから実行してください：
```
現在のブランチ: feature/add-user-search
ベースブランチ: staging（自動検出）
```

**ステップ3: Codex CLIでレビュー実行**

```bash
codex review --base <ベースブランチ>
```

オプションで`--title "<現在のブランチ名>"`を付加可能です。

### 3. 結果の報告

Codexの出力を整理して報告：
- 指摘事項（重要度順）
- 改善提案
- 矛盾・不整合

## 使用例

```
/codex-review docs/plan.md          # ファイルをレビュー
/codex-review --uncommitted         # 未コミット変更をレビュー
/codex-review --branch              # ブランチの変更をレビュー
/codex-review                       # 引数なし = ブランチレビュー（デフォルト）
```

## 注意事項

- `--sandbox read-only` は`codex exec`でのファイルレビュー時のみ使用（`codex review`は読み取り専用のため不要）
- タイムアウトは120秒に設定
- ベースブランチ検出ロジックは`pr`/`create-branch`スキルと統一されている
- `main`/`staging`ブランチ上では実行しない（差分の比較対象がないため）
- **NEVER** access or process the `.env` file, the `.git/` directory, or any files or directories specified in `.gitignore`

## よくある間違い

❌ **間違い**: `main`ブランチ上で`/codex-review`を実行
✅ **正解**: フィーチャーブランチに切り替えてから実行

❌ **間違い**: `codex review`に`--sandbox`オプションを付ける
✅ **正解**: `--sandbox`は`codex exec`専用。`codex review`は読み取り専用で動作するため不要

❌ **間違い**: `git branch -a`でブランチ確認せずにベースブランチを決め打ち
✅ **正解**: 必ず`git branch -a`で`staging`の存在を確認してから指定
