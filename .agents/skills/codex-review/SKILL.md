---
name: codex-review
description: Use when the user asks for a thorough Codex review, codexでレビュー, ブランチをレビュー, PR前にレビュー, 変更をチェック, or review with high reasoning.
---

# Codex Review

現在の変更をCodex CLIで読み取り専用レビューする。

## Targets

- 引数なしまたは `--branch`: ベースブランチからHEADまで
- `--uncommitted`: `git diff`
- `--staged`: `git diff --cached`
- `--commit <hash>`: `git show <hash>`
- ファイルパス: 指定ファイルと関連差分

## Workflow

1. `../_shared/branch-strategy.md` を必要に応じて確認する。
2. 対象差分とコミット履歴を取得する。`.env`、`.git/`、gitignore対象は読まない。
3. `codex review` または `codex exec --sandbox read-only` を使い、読み取り専用でレビューする。
4. 品質、セキュリティ、設計、テスト不足を重大度順に統合して報告する。

## Review Prompt Checklist

- 命名、責務分離、関数サイズ
- N+1や重い処理
- エラーハンドリング
- テストの有無と境界値
- 既存パターンとの一貫性
- 機密情報、インジェクション、AuthN/AuthZ、入力検証、情報漏洩

## Output

```markdown
## Critical / High
- [重大度] [カテゴリ] `file:line` — 問題
  修正案: ...

## Medium / Low
- ...

## 総合評価
PR作成可否と残リスク
```
