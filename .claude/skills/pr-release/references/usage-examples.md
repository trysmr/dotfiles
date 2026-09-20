# リリースPR作成の使用例

1. `git fetch origin`と`git branch -a`で対象ブランチを確認する。
2. `git log origin/main..origin/staging --oneline`と各PRの情報から対象を特定する。PR番号のない変更も漏らさない。
3. ユーザー指定の参考PR、または直近のリリースPRを読み、形式を確認する。
4. `gh pr list --base main --head staging --state open --json number,title,url`で重複を確認する。
5. 確認済みの実績だけを使って本文を作り、日本語セルフチェックとともに提示して許可を得る。

本文はWriteで一時ファイルへ書き、単独コマンドで渡す:

```bash
gh pr create --base main --head staging --title '[Release] staging -> main (YYYY-MM-DD): 主要変更の要約' --body-file <本文ファイルの絶対パス>
```

作成後は`gh pr view <番号> --json number,title,body,url,baseRefName,headRefName`で確認する。レビュー・テスト・staging検証の実績が不明なら、完了扱いでPRを作成しない。本番デプロイ後の項目は実際に検証するまでチェックを付けない。

## マージを別途依頼された場合

必須チェックとレビュー、ユーザーの許可を確認し、プロジェクトの方式に従う。永続ブランチのstagingは削除しない。

```bash
gh pr merge <PR番号> --merge
```
