# ブランチ戦略

## ブランチ構成

- `main`: 本番環境
- `staging`: ステージング環境。存在しないプロジェクトもある
- `feature/*`: 新機能開発
- `bugfix/*`: バグ修正
- `hotfix/*`: 緊急修正
- `refactor/*`: 振る舞いを変えない改善
- `chore/*`: 設定、依存関係、ビルド関連
- `test/*`: テスト追加、修正
- `docs/*`: ドキュメント作成、更新
- `tmp/*`: 一時作業

## ベースブランチ

1. `git branch -a` で利用可能なブランチを確認する。
2. `hotfix/*` は常に `main` から分岐し、`main` へPRを出す。
3. その他は `staging` が存在する場合は `staging`、存在しない場合は `main` を使う。

## 保護ブランチ

`main`、`staging`、`develop` は削除やforce pushをしない。
