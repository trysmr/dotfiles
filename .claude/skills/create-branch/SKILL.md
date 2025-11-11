---
name: create-branch
description: プロジェクトのブランチ命名規則に従って新しいGitブランチを作成。作業開始前、機能開発前、バグ修正前に使用
allowed-tools: Read, Bash
---

# Create Branch

このスキルはプロジェクトのブランチ命名規則に従って新しいGitブランチを作成します。

## 実行手順

### 1. ブランチ戦略の確認

まず`README.md`を読み込んで、プロジェクトのブランチ命名規則を理解してください：

```bash
Read README.md
```

特に「ブランチ戦略とPull Request運用」セクションの「ブランチ構成」を確認します。

**許可されるブランチプレフィックス**：
- `feature/*`: 新機能開発用
- `bugfix/*`: 通常のバグ修正用
- `hotfix/*`: 緊急修正用
- `refactor/*`: リファクタリング用
- `chore/*`: 設定変更・ビルド関連用
- `test/*`: テストコード追加・修正用
- `tmp/*`: 一時作業用

### 2. 現在のブランチと利用可能なブランチの確認

```bash
git branch --show-current
git branch -a
```

で現在のブランチと利用可能なブランチを確認します。

**分岐元ブランチの選択**：
- `hotfix/*`: `main`から分岐
- **その他すべて**: `staging`が存在する場合は`staging`、存在しない場合は`main`から分岐

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

### 4. ブランチ作成

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

### 5. 確認

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
- [ ] ブランチが正常に作成されたことを確認した

## よくある間違い

❌ **間違い**: `git branch -a`でブランチ確認せずに`staging`から分岐
✅ **正解**: 必ず`git branch -a`で`staging`の存在を確認してから分岐

❌ **間違い**: `fix-login-error`（プレフィックスなし）
✅ **正解**: `bugfix/fix-login-error`

❌ **間違い**: `feature/AddUserProfile`（PascalCase）
✅ **正解**: `feature/add-user-profile`（kebab-case）

❌ **間違い**: `bug/fix-error`（bugではなくbugfix）
✅ **正解**: `bugfix/fix-error`

## 使用例

### 例1: 新機能開発の場合（stagingあり）
```
ユーザー: 「ユーザープロフィール機能を開発するブランチ作って」
アシスタント:
1. README.md読み込み
2. git branch -aで確認（stagingが存在）
3. git checkout staging（stagingに移動）
4. ブランチ名決定: feature/add-user-profile
5. git checkout -b feature/add-user-profile
6. 確認
```

### 例2: バグ修正の場合（stagingなし）
```
ユーザー: 「ログインエラーを修正するブランチ作成」
アシスタント:
1. README.md読み込み
2. git branch -aで確認（stagingが存在しない）
3. git checkout main（mainに移動）
4. ブランチ名決定: bugfix/fix-login-error
5. git checkout -b bugfix/fix-login-error
6. 確認
```

### 例3: リファクタリングの場合（stagingあり）
```
ユーザー: 「データベースクエリを改善するブランチ」
アシスタント:
1. README.md読み込み
2. git branch -aで確認（stagingが存在）
3. git checkout staging（stagingに移動）
4. ブランチ名決定: refactor/improve-database-queries
5. git checkout -b refactor/improve-database-queries
6. 確認
```

### 例4: 緊急修正の場合
```
ユーザー: 「セキュリティ問題の緊急修正ブランチ作って」
アシスタント:
1. README.md読み込み
2. git branch -aで確認
3. git checkout main（hotfixは常にmainから分岐）
4. ブランチ名決定: hotfix/fix-security-issue
5. git checkout -b hotfix/fix-security-issue
6. 確認
```

## 注意事項

- ブランチ作成前に必ず`git branch -a`で利用可能なブランチを確認してください
- ブランチ作成後は、必要な変更を行ってからコミットしてください
- 作業が完了したら`commit-and-pr`スキルを使用してPRを作成できます
- `hotfix/*`ブランチは常に`main`から分岐し、`main`へマージします
- その他のブランチは`staging`が存在する場合は`staging`から分岐し`staging`へマージ、存在しない場合は`main`から分岐し`main`へマージします
