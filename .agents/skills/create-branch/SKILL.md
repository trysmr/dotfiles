---
name: create-branch
description: Use when the user asks to create or switch to a new Git branch, including Japanese requests such as ブランチを作って, ブランチを切って, 新しいブランチで作業, or before starting a new feature, bug fix, refactor, chore, test, docs, or temporary task.
---

# Create Branch

プロジェクトのブランチ戦略に従って新しいGitブランチを作成する。

## Workflow

1. `README.md` があれば確認し、ローカルのブランチ規約を優先する。
2. 追加の共通ルールが必要な場合は `../_shared/branch-strategy.md` を読む。
3. `git branch --show-current` と `git branch -a` で現在地と候補ベースを確認する。
4. 作業内容からブランチ名を決める。形式は `<prefix>/<kebab-case-summary>`。
5. 作成前に、ブランチ名、分岐元、判断根拠をユーザーへ提示して許可を得る。
6. 許可後、必要ならベースブランチへ移動して `git checkout -b <branch-name>` を実行する。
7. `git branch --show-current` で切り替えを確認する。

## Prefix Guide

- 新機能: `feature/*`
- バグ修正: `bugfix/*`
- 緊急修正: `hotfix/*`
- 振る舞いを変えない改善: `refactor/*`
- 設定、依存関係、ビルド関連: `chore/*`
- テスト: `test/*`
- ドキュメント: `docs/*`
- 一時作業: `tmp/*`

## Guardrails

- 未コミット変更がある場合は `git status` を確認し、勝手にstashやresetをしない。
- `main`、`staging`、`develop` 上で直接作業を続ける判断はユーザー確認を必須にする。
- `git checkout -b` 以外の破壊的操作は行わない。
