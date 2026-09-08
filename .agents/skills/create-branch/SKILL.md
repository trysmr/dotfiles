---
name: create-branch
description: Use when the user asks to create or switch to a task branch, or when the repository requires a branch for the authorized work. Honor explicit permission to work on the current branch.
---

# Create Branch

プロジェクトのブランチ戦略に従って新しいGitブランチを作成する。

## Workflow

1. `README.md` があれば確認し、ローカルのブランチ規約を優先する。
2. 追加の共通ルールが必要な場合は `../_shared/branch-strategy.md` を読む。
3. `git branch --show-current` と `git branch -a` で現在地と候補ベースを確認する。
4. 作業内容からブランチ名を決める。形式は `<prefix>/<kebab-case-summary>`。
5. 作成前に、ブランチ名、分岐元、判断根拠をユーザーへ提示する。作成が依頼されている場合は、その範囲で進める。既存の変更を移動・処分する判断が必要な場合は確認する。
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
- `main`、`staging`、`develop`上での直接作業はユーザーの明示的な許可に従う。同じリポジトリと作業範囲への許可を、スキルの開始だけを理由に再度求めない。
- `git checkout -b` 以外の破壊的操作は行わない。
