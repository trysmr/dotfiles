---
name: pr
description: Use when the user asks to create a pull request, PR, プルリク, レビュー依頼, or when committed changes are ready to publish for review.
---

# Pull Request Workflow

コミット済み変更に対してGitHub pull requestを作成する。

## Preconditions

- 変更がコミット済みであること。
- 必要なテストとlintが通っていること。
- ブランチがpush済み、またはpush許可を得られること。

## Workflow

1. `README.md` と `../_shared/branch-strategy.md` を必要に応じて確認する。
2. `git branch -a`、`git status`、`git log --oneline -5` で状態を確認する。
3. ベースブランチを決める。`hotfix/*` は `main`、その他は `staging` があれば `staging`、なければ `main`。
4. `git diff <base>...HEAD` でPR範囲の差分を確認する。
5. プロジェクトのテスト/lintコマンドを検出して実行する。失敗した場合はPR作成を止める。
6. 可能なら `change-reviewer`、セキュリティ関連変更なら `security-reviewer` でレビューする。
7. PRタイトルと本文を作成し、ユーザーに提示して許可を得る。
8. 許可後、必要なら `git push -u origin <branch>` を実行し、`gh pr create` でPRを作成する。

## PR Body

```markdown
## 概要
[変更の目的と背景を1-3文で記述します。]

## 変更点
- `対象`: 変更内容
- `対象`: 変更内容

## テスト計画
- [x] [実行した検証]
```

## Guardrails

- ユーザー許可なしにPRを作成しない。
- test/lint失敗中はPRを作成しない。
- Critical/Highレビュー指摘がある場合は先に修正する。
