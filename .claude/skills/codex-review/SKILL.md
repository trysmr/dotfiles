---
name: codex-review
description: Codex CLIを使ってコードやドキュメントをレビュー。「codexでレビュー」「codexにレビューさせて」「計画書をチェック」と言われた時に使用
argument-hint: "[ファイルパス or --uncommitted]"
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
- **引数なし** → ユーザーにどちらか確認

### 2. Codex CLIの実行

**ファイルレビューの場合:**
```bash
codex exec "<ファイルパス> をレビューしてください。問題点、改善提案、矛盾がないか確認してください。日本語で回答してください。" --sandbox read-only
```

**未コミット変更レビューの場合:**
```bash
codex review --uncommitted
```

### 3. 結果の報告

Codexの出力を整理して報告：
- 指摘事項（重要度順）
- 改善提案
- 矛盾・不整合

## 使用例

```
/codex-review docs/plan.md          # ファイルをレビュー
/codex-review --uncommitted         # 未コミット変更をレビュー
```

## 注意事項

- `--sandbox read-only` を使用してファイル変更を防ぐ
- タイムアウトは120秒に設定
- **NEVER** access or process the `.env` file, the `.git/` directory, or any files or directories specified in `.gitignore`
