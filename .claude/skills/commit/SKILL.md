---
name: commit
description: 変更をGitブランチにコミットしてリモートにプッシュ。バグ修正、新機能、リファクタリング時に使用
allowed-tools: Read, Bash
---

# Commit Workflow

このスキルは現在の変更をGitブランチにコミットしてリモートにプッシュします。

## 実行手順

### 1. ブランチ戦略の確認

まず`README.md`を読み込んで、プロジェクトのブランチ戦略を理解してください：

```bash
Read README.md
```

**ブランチ構成の例**：
- `main`: 本番環境（必須）
- `staging`: ステージング環境（プロジェクトによっては存在しない場合がある）
- `feature/*`: 新機能開発
- `bugfix/*`: バグ修正
- `hotfix/*`: 緊急修正
- `refactor/*`: リファクタリング
- `chore/*`: 設定変更・ビルド関連
- `test/*`: テストコード
- `docs/*`: ドキュメント作成・更新

**ベースブランチの確認**：
```bash
git branch -a
```

で利用可能なブランチを確認します。

### 2. 変更内容の確認

```bash
git status
git diff
```

で変更ファイルと差分を確認します。

### 3. ブランチ名の決定

変更内容に基づいて適切なブランチ名を決定：
- プレフィックス: `feature/`, `bugfix/`, `refactor/`, `chore/`, `test/`, `hotfix/`, `docs/`
- kebab-case形式
- 例: `bugfix/fix-login-error`, `feature/add-user-search`, `docs/update-api-spec`

### 4. ブランチ作成（新しいブランチの場合）

すでに適切なブランチにいる場合はスキップしてください。

```bash
git checkout -b <branch-name>
```

### 5. コミット情報の準備

変更内容に基づいて、以下を準備します：

```bash
# ステージング
git add <files>

# ステージング内容の確認
git diff --cached
```

コミットメッセージ案を作成：
- タイトル: 1行で簡潔に変更内容を記述
- 詳細: 変更内容の具体的な説明（箇条書き）

### 6. ユーザー確認

以下の情報をユーザーに提示し、コミットの許可を得てください：

- **ステージング済みファイル**: `git diff --cached --name-only` の出力
- **コミットメッセージ案**: タイトルと詳細

**重要**: ユーザーの許可なしにコミットを実行しないでください。

### 7. コミット実行

ユーザーの許可を得てから、コミットを実行します：

```bash
git commit -m "$(cat <<'EOF'
タイトル（1行、簡潔に変更内容を記述）

- 変更内容の詳細1
- 変更内容の詳細2
- 変更内容の詳細3
EOF
)"
```

コミットメッセージは日本語で記述します。

### 8. リモートへプッシュ

```bash
# 新しいブランチの場合
git push -u origin <branch-name>

# 既存ブランチの場合
git push
```

プロジェクトにはGit Hooksが設定されており、ブランチ名チェックとベースブランチの案内が表示されます。

## チェックリスト

実行前に確認すべき項目：

- [ ] README.mdを読み込んでブランチ戦略を理解した
- [ ] `git branch -a`で利用可能なブランチを確認した
- [ ] `git status`と`git diff`で変更内容を確認した
- [ ] 適切なブランチプレフィックスを選択した
- [ ] セキュリティ情報（`.env`, `credentials`等）を含まない
- [ ] ステージング済みファイルとコミットメッセージ案をユーザーに提示した
- [ ] ユーザーの許可を得てからコミットを実行した
- [ ] コミットメッセージが明確で日本語で記述されている

## 使用例

### 例1: 既存ブランチでの追加コミット

**ステップ1**: 変更を確認
```bash
git branch
git status
git diff
```

**ステップ2**: ステージングと確認
```bash
git add docs/contact_relation_spec.md
git diff --cached
git diff --cached --name-only
```

**ステップ3**: ユーザーに提示
```
以下の内容でコミットしてよろしいですか？

ステージング済みファイル:
- docs/contact_relation_spec.md

コミットメッセージ案:
タイトル: 申込書発行仕様書にビジネスフロー図を追加

詳細:
- sequenceDiagramでビジネスフローを可視化
- セクション番号を調整
```

**ステップ4**: ユーザーの許可を待つ

**ステップ5**: 許可後にコミット・プッシュ
```bash
git commit -m "$(cat <<'EOF'
申込書発行仕様書にビジネスフロー図を追加

- sequenceDiagramでビジネスフローを可視化
- セクション番号を調整
EOF
)"

git push
```

### 例2: 新規ブランチでのコミット

**ステップ1**: ブランチ作成と変更確認
```bash
git checkout -b feature/add-user-search
git status
git diff
```

**ステップ2**: ステージングと確認
```bash
git add app/controllers/users_controller.rb app/views/users/index.html.erb
git diff --cached --name-only
```

**ステップ3**: ユーザーに提示
```
以下の内容でコミットしてよろしいですか？

ステージング済みファイル:
- app/controllers/users_controller.rb
- app/views/users/index.html.erb

コミットメッセージ案:
タイトル: ユーザー検索機能を追加

詳細:
- 名前・メールアドレスでの検索に対応
- ページネーション実装
```

**ステップ4**: ユーザーの許可を待つ

**ステップ5**: 許可後にコミット・プッシュ
```bash
git commit -m "$(cat <<'EOF'
ユーザー検索機能を追加

- 名前・メールアドレスでの検索に対応
- ページネーション実装
EOF
)"

git push -u origin feature/add-user-search
```
