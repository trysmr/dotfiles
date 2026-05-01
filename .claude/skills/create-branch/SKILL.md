---
name: create-branch
description: プロジェクトのブランチ命名規則に従ってGitブランチを作成。「ブランチお願い」「ブランチを作って」「ブランチ作って」「ブランチを切って」「新しいブランチで作業」などと言われた時、または新しい作業・機能開発・バグ修正を開始する前に使用
allowed-tools:
  - Read
  - Bash
---

# Create Branch

このスキルはプロジェクトのブランチ命名規則に従って新しいGitブランチを作成します。

## 実行手順

### 1. ブランチ戦略の確認

まず`README.md`を読み込んで、プロジェクトのブランチ命名規則を理解してください：

```bash
Read README.md
```

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
- 新機能追加 → `feature/*`
- バグ修正 → `bugfix/*`
- 緊急修正 → `hotfix/*`
- コードの改善（動作は変わらない） → `refactor/*`
- 設定変更、依存関係更新、ビルド関連 → `chore/*`
- テスト追加・修正 → `test/*`
- 試行錯誤、一時的な作業 → `tmp/*`

### 4. ユーザー確認

以下の git checkout コマンド形式でユーザーに提示し、ブランチ作成の許可を得てください：

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
| ブランチ作成がhookに拒否される | ブランチ名が命名規則に違反している | `git branch -m <new-name>` で修正する |
| `fatal: A branch named '...' already exists` | 同名ブランチが既に存在する | `git branch -a` で確認し、別名を選択してユーザーに提案する |
| 分岐元に切り替えできない | 未コミットの変更がある | `git status` を確認し、stashまたはコミットしてから切り替える |

## 使用例

詳細な使用例（例1〜4）・注意事項は `references/usage-examples.md` を参照してください。
