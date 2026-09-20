---
name: create-branch
description: Gitブランチの作成や切り替えを依頼された場合、または許可された作業にプロジェクトがブランチを要求する場合に使用。現在のブランチで作業する明示的な許可を尊重する。
allowed-tools:
  - Read
  - Bash
---

# Create Branch

このスキルはプロジェクトのブランチ命名規則に従って新しいGitブランチを作成します。

## 実行手順

### 1. ブランチ戦略の確認

まず`README.md`を読み込んで、プロジェクトのブランチ命名規則を理解してください。

ブランチ構成・プレフィックス・ベースブランチ選択ルールは `.claude/skills/_shared/branch-strategy.md` を参照。

### 2. 現在のブランチと利用可能なブランチの確認

```bash
git branch --show-current
git branch -a
```

で現在のブランチと利用可能なブランチを確認します。

### 3. ブランチ名の決定

ユーザーの要望に基づいて適切なブランチ名を決定：

**命名規則**：
- プレフィックス + `/` + 説明（kebab-case）
- 例:
  - `feature/add-user-profile`
  - `bugfix/fix-login-error`
  - `refactor/improve-database-queries`
  - `chore/update-dependencies`
  - `test/add-user-controller-tests`

**判断基準**：
- 新機能追加 -> `feature/*`
- バグ修正 -> `bugfix/*`
- 緊急修正 -> `hotfix/*`
- コードの改善（動作は変わらない） -> `refactor/*`
- 設定変更、依存関係更新、ビルド関連 -> `chore/*`
- テスト追加・修正 -> `test/*`
- 試行錯誤、一時的な作業 -> `tmp/*`

### 4. ユーザー確認

ブランチ名、分岐元、根拠を提示する。作成が依頼されている場合は、その範囲で進める。現在のブランチで作業する許可を、スキル開始だけを理由に再確認しない。既存の変更を移動・処分する判断が必要な場合は確認する:

```bash
git checkout -b feature/add-user-search
```

**分岐元ブランチ**: staging (または main)
**判断根拠**: 新機能追加のため `feature/*` プレフィックスを使用

**重要**: ユーザーの許可なしにブランチを作成しないでください。

### 5. ブランチ作成

**必要に応じて分岐元ブランチに移動**：
```bash
# stagingが存在し、hotfix以外の場合
git checkout staging

# stagingが存在しない場合、またはhotfixの場合
git checkout main
```

**新しいブランチを作成**：
```bash
git checkout -b <branch-name>
```

プロジェクトにはGit Hooksが設定されており、ブランチ名が命名規則に従っているかチェックされます。

もし拒否された場合は、エラーメッセージを確認して適切な名前に修正してください：

```bash
git branch -m <new-branch-name>
```

### 6. 確認

```bash
git branch --show-current
```

で新しいブランチに切り替わったことを確認します。

## チェックリスト

- [ ] README.mdを読み込んでブランチ命名規則を確認した
- [ ] `git branch -a`で利用可能なブランチを確認した
- [ ] 分岐元ブランチを正しく選択した（`staging`が存在する場合は`staging`、存在しない場合やhotfixの場合は`main`）
- [ ] 作業内容に適したプレフィックスを選択した
- [ ] kebab-case形式でブランチ名を決定した
- [ ] ブランチ名と分岐元をユーザーに提示した
- [ ] ユーザーの許可を得てからブランチを作成した
- [ ] ブランチが正常に作成されたことを確認した

## Troubleshooting

| エラー | 原因 | 対処 |
|--------|------|------|
| ブランチ作成がhookに拒否される | ブランチ名が命名規則に違反している | `git branch -m <new-name>`で修正する |
| `fatal: A branch named '...' already exists` | 同名ブランチが既に存在する | `git branch -a`で確認し、別名を選択してユーザーに提案する |
| 分岐元に切り替えできない | コミットしていない変更がある | `git status`で確認してユーザーへ相談する。勝手にstash・reset・コミットしない |

## 使用例

詳細な使用例（例1〜4）・注意事項は `references/usage-examples.md` を参照してください。
