---
name: pr-release
description: Use when the user asks for a release PR, 本番リリース, リリースPR, or a PR that merges staging into main.
---

# Release PR Workflow

`staging` を `main` へマージする本番リリース用PRを作成する。通常の作業PRは `pr` skill を使う。

## Preconditions

- `origin/main` と `origin/staging` が存在すること。
- 含まれる各PRがすでにレビュー、テスト、staging検証済みであること。

## Workflow

1. `git fetch origin` の実行許可を必要に応じて得る。
2. `git branch -a` で `main` と `staging` を確認する。
3. `git log origin/main..origin/staging --oneline` でリリース対象を確認する。
4. コミット履歴からPR番号を抽出し、`gh pr view <number> --json number,title,body` で内容を整理する。
5. ユーザーが参考PRを指定した場合は、下書き前に`gh pr view <number> --json number,title,body`で取得する。指定がない場合は、`gh pr list --base main --head staging --state merged --limit 1 --json number,title,body`で直近のリリースPRを確認する。
6. `gh pr list --base main --head staging --state open --json number,title,url`で作成中のリリースPRがないことを確認する。存在する場合は新規作成せず、既存PRを報告する。
7. 参考PRの見出し構成、概要の長さ、変更点の粒度、テスト計画の範囲に合わせてタイトルと本文を作成する。対象PRの本文またはユーザー確認から判断できる事実だけを書く。
8. 下記の日本語セルフチェックを出力し、テスト計画と確認済みの事実を照合する。タイトルと本文をユーザーに提示して許可を得る。修正指示で別の参考PRが指定された場合は、推測せず手順5へ戻る。
9. 許可後、下記の形式で`gh pr create`を単独実行する。
10. 作成後に`gh pr view <number> --json number,title,body,url,baseRefName,headRefName`を実行し、ベース、ヘッド、タイトル、本文を確認する。

## Title

```text
[Release] staging -> main (YYYY-MM-DD): 主要変更の要約
```

## Body

```markdown
## 概要

ステージング環境で検証完了した[主要機能の概要]を本番環境にリリースします。

## 変更点

### PRタイトル（#123）

- 変更内容の要約

## テスト計画

- [x] staging環境での動作確認済み
- [ ] 本番デプロイ後の確認
  - [ ] アプリケーションが正常に起動することを確認
  - [ ] 主要機能が正常に動作することを確認
```

- `概要`は参考PRと同程度の長さにする。指定がなければ原則1文にする。
- `変更点`は対象PRごとにまとめ、変更の目的と利用者または運用への影響が分かる粒度で書く。
- `テスト計画`は確認できた実績と本番デプロイ後に必要な確認へ絞る。

## Japanese Self-Check

タイトルと本文を1行ずつ読み、漢語接頭辞の造語、助詞の省略、既存の語彙にない業務用語、禁止語がないか照合する。指摘がなくても次の表を出力し、`gh pr create`の前にユーザーの許可を得る。

| 対象行 | 元の表現 | 判定 | 修正後 |
| --- | --- | --- | --- |
| タイトル | （原文） | OK / 造語 / 助詞省略 / 禁止語 | （OKなら空欄） |
| 概要 | （原文） | OK / 造語 / 助詞省略 / 禁止語 | （OKなら空欄） |

## PR作成コマンド

PR本文はヒアドキュメントで`--body`へ渡す。`gh pr create`を`&&`、`;`、パイプ、引用外の改行で他のコマンドと連結しない。

```bash
gh pr create --base main --head staging --title "タイトル" --body "$(cat <<'EOF'
## 概要
...
EOF
)"
```

## Guardrails

- `origin/staging`または`origin/main`がない場合はPRを作成せず、確認結果を報告する。
- ユーザー許可なしにPRを作成しない。
- 作成中の`staging`から`main`へのPRがある場合は重複作成しない。
- 実行していないテストや確認できない検証を完了扱いにしない。
- 参考PRを確認する前に、その形式を推測して下書きを修正しない。
- `main`と`staging`は永続ブランチとして扱い、削除やforce pushをしない。
- `gh pr create`がTLS/証明書エラーで失敗した場合は`dangerouslyDisableSandbox: true`を指定して再実行する。
