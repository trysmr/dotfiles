---
name: pr
description: プロジェクトのブランチ戦略に従ってプルリクエストを作成。「PR」「プルリク」「PRを作って」「プルリク作って」「プルリクお願い」「プルリクエストを作成」「レビュー依頼して」などと言われた時、またはコミット済みの変更をマージする準備ができた時に使用
allowed-tools:
  - Read
  - Bash
---

# Pull Request Creation Workflow

このスキルはコミット済みの変更に対してプルリクエストを作成します。

**前提条件**: 変更が既にコミット・プッシュされていること

## 実行手順

### 1. ブランチ戦略の確認

まず`README.md`を読み込んで、プロジェクトのブランチ戦略を理解してください：

```bash
Read README.md
```

ベースブランチ選択ルールは `.claude/skills/_shared/branch-strategy.md` を参照。

```bash
git branch -a
```

で利用可能なブランチを確認します。

### 2. 変更内容の確認

```bash
git status
git log --oneline -5
git diff origin/main...HEAD  # または origin/staging...HEAD
```

でコミット履歴と変更内容を確認します。

### 3. Test・Linter実行

PR作成前に品質チェックを実行します。

**プロジェクト固有のコマンドを検出**:
- `Gemfile`がある場合は`rake test`や`bundle exec rspec`、`bundle exec rubocop`を確認
- `package.json`の`scripts.test`や`scripts.lint`を確認
- `pytest.ini`や`setup.py`がある場合は`pytest`を確認
- `Cargo.toml`がある場合は`cargo test`を確認
- `go.mod`がある場合は`go test ./...`を確認
- README.mdに記載がある場合はそちらを優先

**実行例**:
```bash
# Railsプロジェクトの場合
bin/rails test
bin/rails rspec
bin/rubocop
bin/brakeman

# Rubyプロジェクトの場合
bundle exec rspec
bundle exec rubocop

# Node.jsプロジェクトの場合
npm test
npm run lint
```

**重要**: test・linterが失敗した場合、PR作成プロセスを中断してください。エラー内容をユーザーに提示し、修正を促してください。

### 3.5 Pre-PR Review（推奨）

品質チェックの一環として、change-reviewerによるコードレビューを実行する。

```
review Skillを使用して変更差分をレビュー（--branch オプション）
```

- **Critical/High指摘がある場合**: PR作成を中断し、修正を促す
- **Medium以下のみ**: 指摘事項をユーザーに共有し、PR作成を継続するか確認する
- **セキュリティ関連ファイル**（認証、入力処理、API等）が含まれる場合: security-reviewerも自動的に実行される

**注意**: ユーザーが明示的にスキップを指示した場合は省略可。

### 4. PR情報の準備

以下の情報をユーザーに提示し、PR作成の許可を得てください：

- **ベースブランチ**: `staging`または`main`
- **PRタイトル**: 変更内容を簡潔に丁寧な言葉で表現
- **PR本文**: 以下のテンプレートに従って作成
- 英語と日本語の間に余計な半角スペースを追加しない

**PR本文テンプレート**：

```markdown
## 概要
[変更の目的と背景を記述を丁寧な言葉で]

## 変更点
- [具体的な変更内容1を簡潔に]
- [具体的な変更内容2を簡潔に]
- [具体的な変更内容3を簡潔に]

## テスト計画
- [x] [実施済みのテスト]
- [ ] [実施予定のテスト（レビュー時に確認）]
```

### 5. ユーザー確認

PR情報をユーザーに提示し、「はい」「OK」「作成して」などの許可を得てください。

**重要**: ユーザーの許可なしにPRを作成しないでください。

### 6. PR作成

ユーザーの許可を得てから、以下のコマンドでPRを作成します：

```bash
# hotfix/* ブランチの場合のみ
gh pr create --base main --title "タイトル" --body "$(cat <<'EOF'
## 概要
...

## 変更点
...

## テスト計画
...
EOF
)"

# その他すべて（feature/*, bugfix/*, refactor/*, chore/*, test/*, docs/*）
# stagingが存在する場合
gh pr create --base staging --title "タイトル" --body "$(cat <<'EOF'
...
EOF
)"

# stagingが存在しない場合
gh pr create --base main --title "タイトル" --body "$(cat <<'EOF'
...
EOF
)"
```

### 7. PR URLの確認

PR作成後、URLをユーザーに提示します。

## チェックリスト

実行前に確認すべき項目：

- [ ] README.mdを読み込んでブランチ戦略を理解した
- [ ] `git branch -a`で利用可能なブランチを確認した
- [ ] 変更が既にコミット・プッシュされている
- [ ] test・linterを実行し、全て成功したことを確認した
- [ ] Pre-PR Reviewを実行し、Critical/High指摘がないことを確認した（推奨）
- [ ] ベースブランチを正しく選択した（`staging`が存在する場合は`staging`、存在しない場合やhotfixの場合は`main`）
- [ ] PR情報をユーザーに提示し、許可を得た
- [ ] PR本文に「概要」「変更点」「テスト計画」を含めた

## よくある間違い

❌ **間違い**: testが失敗しているのにPRを作成
✅ **正解**: test・linterが全て成功してからPR作成

❌ **間違い**: ユーザーの許可なしにPRを作成
✅ **正解**: 必ずPR情報を提示してユーザーの許可を得る

❌ **間違い**: `git branch -a`でブランチを確認せずに決め打ちでベースブランチを指定
✅ **正解**: 必ず`git branch -a`で利用可能なブランチを確認してから指定

❌ **間違い**: PR作成時にベースブランチを指定しない（デフォルトはmainになる）
✅ **正解**: 必ず`--base staging`または`--base main`を明示的に指定

❌ **間違い**: `staging`が存在しないプロジェクトで`--base staging`を指定
✅ **正解**: `git branch -a`で確認し、存在しない場合は`--base main`を指定

## Troubleshooting

| エラー | 原因 | 対処 |
|--------|------|------|
| `gh pr create` がリモートブランチが見つからないと失敗 | ブランチがpushされていない | `git push -u origin <branch>` を先に実行する |
| `a pull request for branch already exists` | 同ブランチで既にPRが存在する | `gh pr view` で既存PRを確認してユーザーに提示する |
| test・linterが失敗する | コードに問題がある | PR作成を中断し、エラー内容をユーザーに提示して修正を促す |
| `--base staging` でエラー | stagingブランチが存在しない | `git branch -a` で確認し `--base main` に変更する |

## 使用例

詳細な使用例・マージ手順は `references/usage-examples.md` を参照してください。
