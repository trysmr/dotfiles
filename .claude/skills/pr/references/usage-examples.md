# PR作成の使用例

ブランチ戦略、差分、必要な検証とレビューを確認し、タイトル・本文・日本語セルフチェックを提示して許可を得る。本文はWriteで一時ファイルへ書く。

```markdown
## 概要

[確認できた動機と変更後の挙動を丁寧語で記述する。理由を推測で補わない]

## 変更点

- `app/controllers/example_controller.rb`: 一覧の表示項目を追加
- `test/controllers/example_controller_test.rb`: 一覧の表示内容を検証

## テスト計画

- [x] RuboCop静的解析パス
- [x] 対象テストN件パス(0 failures, 0 errors)
```

チェック済みとするのは実行して成功した項目だけ。Nは実測値に置き換える。ユーザーが項目・順序・文言を指定した場合はそれに従う。

```bash
gh pr create --base staging --head feature/example --title 'タイトル' --body-file <本文ファイルの絶対パス>
```

hotfix、またはstagingがない場合は確認済みのmainをbaseにする。

## マージを別途依頼された場合

プロジェクトのマージ方式と必須チェック・レビューを確認してから実行する。mainやstagingなどの永続ブランチは削除しない。

```bash
gh pr merge <PR番号> --merge
```
