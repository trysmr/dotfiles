# PR作成 使用例

## 例1: 新機能追加の場合（stagingあり）

**ステップ1**: ブランチ確認
```bash
git branch -a
# staging が存在することを確認
```

**ステップ2**: Test・Linter実行
```bash
# プロジェクトに合わせたコマンドを実行
# 全てのテストが成功したことを確認
```

**ステップ3**: PR情報をユーザーに提示し、許可を待つ

**ステップ4**: 許可後にPR作成
```bash
gh pr create --base staging --title "タイトル" --body "$(cat <<'EOF'
## 概要
[変更の目的と背景を丁寧語で1-3文]

## 変更点
- `XxxController`: 一覧画面を追加
- `xxx_table`: `yyy`カラムにDBインデックスを追加

## テスト計画
- [x] RuboCop静的解析パス
- [x] 全テストN件パス(0 failures, 0 errors)
EOF
)"
```

## 例2: hotfixの場合（mainへ直接）

```bash
gh pr create --base main --title "タイトル" --body "$(cat <<'EOF'
## 概要
[原因]のため、[問題]が発生していました。[修正内容]で対処します。

## 変更点
- `XxxModel`の[修正内容]

## テスト計画
- [x] RuboCop静的解析パス
- [x] [対象]テストN件パス(0 failures, 0 errors)
- [x] staging環境で[具体的な確認内容]を確認
EOF
)"
```

## PRのマージ（ユーザーから指示があった場合）

```bash
# 通常のPR（feature/*, bugfix/*, chore/* など）
gh pr merge <PR番号> --merge --delete-branch

# リリースPR（staging → main）など永続ブランチからのPR
gh pr merge <PR番号> --merge
```

**注意**:
- プロジェクトでは**Merge commit**を使用します（Squash mergeは使用しない）
- `staging`や`main`などの永続ブランチがソースの場合は`--delete-branch`を**つけない**こと
