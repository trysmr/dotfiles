---
name: commit-and-pr
description: 変更をGitブランチにコミットし、プロジェクトのブランチ戦略（staging/mainへのPR）に従ってプルリクエストを作成。バグ修正、新機能、リファクタリング時に使用
allowed-tools: Read, Bash
---

# Commit and PR Workflow

このスキルは現在の変更をGitブランチにコミットし、プロジェクトのブランチ戦略に従ってプルリクエストを作成します。

## 実行手順

### 1. ブランチ戦略の確認

まず`README.md`を読み込んで、プロジェクトのブランチ戦略を理解してください：

```bash
Read README.md
```

特に「ブランチ戦略とPull Request運用」セクションを確認し、以下を理解します：

**ブランチ構成の例**：
- `main`: 本番環境（必須）
- `staging`: ステージング環境（プロジェクトによっては存在しない場合がある）
- `feature/*`: 新機能開発
- `bugfix/*`: バグ修正
- `hotfix/*`: 緊急修正
- `refactor/*`: リファクタリング
- `chore/*`: 設定変更・ビルド関連
- `test/*`: テストコード

**ベースブランチの確認**：
```bash
git branch -a
```

で利用可能なブランチを確認し、以下のルールに従います：

**ベースブランチ選択ルール**：
- `hotfix/*` → `main`をベースにする
- **その他すべて** → `staging`が存在する場合は`staging`、存在しない場合は`main`をベースにする

### 2. 変更内容の確認

```bash
git status
git diff
```

で変更ファイルと差分を確認します。

### 3. ブランチ名の決定

変更内容に基づいて適切なブランチ名を決定：
- プレフィックス: `feature/`, `bugfix/`, `refactor/`, `chore/`, `test/`, `hotfix/`
- kebab-case形式
- 例: `bugfix/fix-login-error`, `feature/add-user-search`

### 4. ブランチ作成とコミット

```bash
# ブランチ作成
git checkout -b <branch-name>

# ステージング
git add <files>

# コミット（HEREDOCを使用）
git commit -m "$(cat <<'EOF'
タイトル（1行、簡潔に変更内容を記述）

- 変更内容の詳細1
- 変更内容の詳細2
- 変更内容の詳細3
EOF
)"
```

コミットメッセージは日本語で記述します。

### 5. リモートへプッシュ

```bash
git push -u origin <branch-name>
```

プロジェクトにはGit Hooksが設定されており、ブランチ名チェックとベースブランチの案内が表示されます。

### 6. PR作成

**ベースブランチの指定が最重要**：

```bash
# hotfix/* ブランチの場合のみ
gh pr create --base main --title "タイトル" --body "..."

# その他すべて（feature/*, bugfix/*, refactor/*, chore/*, test/*）
# stagingが存在する場合
gh pr create --base staging --title "タイトル" --body "..."

# stagingが存在しない場合
gh pr create --base main --title "タイトル" --body "..."
```

**PR本文テンプレート**：

```markdown
## 概要
[変更の目的と背景を記述]

## 変更点
- [具体的な変更内容1]
- [具体的な変更内容2]
- [具体的な変更内容3]

## テスト計画
- [x] [実施済みのテスト]
- [ ] [実施予定のテスト（レビュー時に確認）]
```

### 7. PRのマージ（ユーザーから指示があった場合）

```bash
gh pr merge <PR番号> --merge --delete-branch
```

**注意**: プロジェクトでは**Merge commit**を使用します（Squash mergeは使用しない）。

## チェックリスト

実行前に確認すべき項目：

- [ ] README.mdを読み込んでブランチ戦略を理解した
- [ ] `git branch -a`で利用可能なブランチを確認した
- [ ] `git status`と`git diff`で変更内容を確認した
- [ ] 適切なブランチプレフィックスを選択した
- [ ] ベースブランチを正しく指定した（`staging`が存在する場合は`staging`、存在しない場合やhotfixの場合は`main`）
- [ ] セキュリティ情報（`.env`, `credentials`等）を含まない
- [ ] コミットメッセージが明確で日本語で記述されている
- [ ] PR本文に「概要」「変更点」「テスト計画」を含めた

## よくある間違い

❌ **間違い**: `git branch -a`でブランチを確認せずに決め打ちでベースブランチを指定
✅ **正解**: 必ず`git branch -a`で利用可能なブランチを確認してから指定

❌ **間違い**: PR作成時にベースブランチを指定しない（デフォルトはmainになる）
✅ **正解**: 必ず`--base staging`または`--base main`を明示的に指定

❌ **間違い**: `staging`が存在しないプロジェクトで`--base staging`を指定
✅ **正解**: `git branch -a`で確認し、存在しない場合は`--base main`を指定

## 使用例

### 例1: バグ修正の場合（stagingあり）
1. README.md読み込み
2. `git branch -a`でブランチ確認（`staging`が存在）
3. `git status`, `git diff`で確認
4. ブランチ名: `bugfix/fix-validation-error`
5. コミット実行
6. `gh pr create --base staging` でPR作成

### 例2: 新機能追加の場合（stagingなし）
1. README.md読み込み
2. `git branch -a`でブランチ確認（`staging`が存在しない）
3. `git status`, `git diff`で確認
4. ブランチ名: `feature/add-export-function`
5. コミット実行
6. `gh pr create --base main` でPR作成

### 例3: 緊急修正の場合
1. README.md読み込み
2. `git branch -a`でブランチ確認
3. `git status`, `git diff`で確認
4. ブランチ名: `hotfix/fix-critical-security-issue`
5. コミット実行
6. `gh pr create --base main` でPR作成（hotfixは常にmainへ）
