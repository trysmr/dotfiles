---
name: repo-explorer
description: Use to quickly investigate a repository structure, technology stack, entry points, configuration, architecture patterns, and test layout before planning or editing.
---

# Repo Explorer

リポジトリの構造と既存パターンを短時間で把握して報告する。

## Workflow

1. `rg --files` を使って主要ファイルを確認する。
2. README、設定ファイル、package/lockfile、CI、テスト設定、エントリポイントを読む。
3. 変更予定領域がある場合は、共有ロジックや呼び出し元から確認する。
4. 調査結果は実装判断に必要な事実だけに絞る。

## Output

- **概要**: プロジェクト目的を1-2行
- **構造**: 主要ディレクトリと役割
- **技術スタック**: 言語、framework、主要依存
- **エントリポイント**: 実行、設定、テスト
- **注目点**: 設計パターン、制約、変更時の注意
