# リリースPR作成 使用例

## 例1: 複数PR集約のリリース（典型的）

**ステップ1**: ブランチ確認
```bash
git fetch origin
git branch -a
# mainとstagingの両方が存在することを確認
```

**ステップ2**: 含まれるPR番号を抽出
```bash
git log origin/main..origin/staging --oneline | grep -oE '#[0-9]+' | sort -u
# 例: #NNN, #NNN+1, #NNN+2
```

**ステップ3**: 各PRの内容を確認
```bash
gh pr view NNN --json number,title,body
gh pr view NNN+1 --json number,title,body
```

**ステップ4**: PR情報をユーザーに提示し、許可を待つ

**ステップ5**: 許可後にPR作成
```bash
gh pr create --base main --head staging --title "[Release] staging -> main (YYYY-MM-DD): インフラ移行、ライブラリアップデート" --body "$(cat <<'EOF'
## 概要
ステージング環境で検証完了した[主要機能の概要]を本番環境にリリースします。

## 変更点
### [PR1のタイトル]（#NNN）
- [変更内容の要約1]
- [変更内容の要約2]

### [PR2のタイトル]（#NNN+1）
- [変更内容の要約1]

### [PR3のタイトル]（#NNN+2）
- [変更内容の要約1]
- [変更内容の要約2]

## テスト計画
- [x] RuboCop静的解析パス
- [x] 全テストN件パス(0 failures, 0 errors)
- [x] staging環境で動作確認
- [ ] 本番デプロイ後の確認
  - [ ] アプリケーションが正常に起動することを確認
  - [ ] ヘルスチェックエンドポイントが正常に応答することを確認
  - [ ] 主要機能が正常に動作することを確認
EOF
)"
```

## 例2: 単一PRのみのリリース（小規模）

```bash
gh pr create --base main --head staging --title "[Release] staging -> main (YYYY-MM-DD): 設定値の更新" --body "$(cat <<'EOF'
## 概要
ステージング環境で検証完了した[変更内容の概要]を本番環境にリリースします。

## 変更点
### [PRのタイトル]（#NNN）
- [変更内容の要約1]
- [変更内容の要約2]

## テスト計画
- [x] RuboCop静的解析パス
- [x] 全テストN件パス(0 failures, 0 errors)
- [x] staging環境で動作確認
- [ ] 本番デプロイ後の確認
  - [ ] [変更箇所]が期待通り動作することを確認
EOF
)"
```

## リリースPRのマージ（ユーザーから指示があった場合）

```bash
# stagingがソースの永続ブランチPRなので--delete-branchをつけない
gh pr merge <PR番号> --merge
```

**注意**:
- プロジェクトでは**Merge commit**を使用します（Squash mergeは使用しない）
- `staging`がソースのリリースPRは`--delete-branch`を**つけない**こと
- マージ後、本番デプロイの完了を待ってから「本番デプロイ後の確認」項目を`[x]`に更新する
