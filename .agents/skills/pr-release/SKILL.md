---
name: pr-release
description: Use when the user asks for a release PR, 本番リリース, リリースPR, or a PR that merges staging into main.
---

# Release PR Workflow

`staging` を `main` へマージする本番リリース用PRを作成する。通常の作業PRは `pr` skill を使う。

## Preconditions

- `origin/main` と `origin/staging` が存在すること。
- 含まれる各PRがすでにレビュー、テスト、staging検証済みであること。

## Workflow

1. `git fetch origin` の実行許可を必要に応じて得る。
2. `git branch -a` で `main` と `staging` を確認する。
3. `git log origin/main..origin/staging --oneline` でリリース対象を確認する。
4. コミット履歴からPR番号を抽出し、`gh pr view <number> --json number,title,body` で内容を整理する。
5. タイトルと本文を作成し、ユーザーに提示して許可を得る。
6. 許可後に `gh pr create --base main --head staging` を実行する。

## Title

```text
[Release] staging -> main (YYYY-MM-DD): 主要変更の要約
```

## Body

```markdown
## 概要
ステージング環境で検証完了した[主要機能の概要]を本番環境にリリースします。

## 変更点
### PRタイトル（#123）
- 変更内容の要約

## テスト計画
- [x] RuboCop静的解析パス
- [x] 全テストN件パス(0 failures, 0 errors)
- [x] staging環境で動作確認
- [ ] 本番デプロイ後の確認
  - [ ] アプリケーションが正常に起動することを確認
  - [ ] 主要機能が正常に動作することを確認
```

## Guardrails

- `staging` または `main` がない場合は通常PRへ切り替える。
- ユーザー許可なしにPRを作成しない。
