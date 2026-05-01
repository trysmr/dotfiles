---
name: commit
description: Use when the user asks to commit, save changes, 変更を保存, コミットして, or after completing an implementation, bug fix, refactor, documentation update, or configuration change that should be committed.
---

# Commit Workflow

現在の変更を意図が分かる日本語メッセージでコミットする。

## Workflow

1. `../_shared/branch-strategy.md` を必要に応じて確認する。
2. `git branch --show-current` で保護ブランチ上でないことを確認する。
3. `git status` と `git diff` で変更内容を読む。読んでいないファイルはステージしない。
4. 秘密情報、`.env`、認証情報、不要な生成物が含まれていないか確認する。
5. 必要なテスト、lint、formatを実行する。実行できない場合は理由を記録する。
6. `git add <files>` で意図したファイルだけをステージし、`git diff --cached` を確認する。
7. コミット予定ファイルとメッセージ案をユーザーへ提示し、許可を得る。
8. 許可後に `git commit -m "..."` を実行する。

## Message Rules

- 日本語で「なぜ変更したか」を中心に書く。
- 1行目は50文字前後を目安にする。
- 変更が多い場合だけ本文に箇条書きを追加する。
- 英語の識別子と日本語の間に不要な半角スペースを入れない。

## Guardrails

- ユーザー許可なしにコミットしない。
- `git add .`、`git add -A`、`--no-verify` は使わない。
- pre-commit hookが失敗した場合は修正して再実行する。回避しない。
