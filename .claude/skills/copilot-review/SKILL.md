---
name: copilot-review
description: GitHub Copilot CLIを使ってコードやドキュメントをレビュー。「copilotでレビュー」「copilotにレビューさせて」「計画書をチェック」「ブランチをレビュー」「PR前にレビュー」「変更をチェック」と言われた時に使用
argument-hint: "[ファイルパス | --uncommitted | --branch]"
context: fork
agent: general-purpose
allowed-tools:
  - Bash
  - Read
---

# Copilot Review

GitHub Copilot CLIを使ってコードやドキュメントをレビューします。

## レビュー対象

$ARGUMENTS

## 前提条件

1. `which copilot` でCopilot CLIのインストールを確認する
2. 未インストールの場合は `npm install -g @github/copilot-cli` またはHomebrewでのインストールを案内して終了する

## 実行手順

### 1. レビュー対象の判定

引数に応じて実行方法を決定：
- **ファイルパス指定** → ファイル内容をレビュー
- **`--uncommitted`指定** → 未コミット変更をレビュー
- **`--branch`指定 or 引数なし** → ブランチレビュー（デフォルト）

### 2. Copilot CLIの実行

#### ファイルレビューの場合

```bash
copilot --model gpt-5.4 -p "<ファイルパス> をコードレビューしてください。以下の観点で確認し、日本語で報告してください：バグ・論理エラー、セキュリティリスク、パフォーマンス問題、可読性・保守性の改善点" --allow-all-tools --no-ask-user --deny-tool=write
```

#### 未コミット変更レビューの場合

`git diff`（未ステージ変更）・`git diff --cached`（ステージ済み変更）・`git status --short`（新規ファイル含む）をすべてカバーするよう指示します：

```bash
copilot --model gpt-5.4 -p "現在の未コミット変更をすべてコードレビューしてください。git diff（未ステージ変更）、git diff --cached（ステージ済み変更）、git status --short（新規ファイル含む）を確認し、新規ファイルの内容も読み込んでください。以下の観点で確認し、日本語で報告してください：バグ・論理エラー、セキュリティリスク、パフォーマンス問題、可読性・保守性の改善点" --allow-all-tools --no-ask-user --deny-tool=write
```

#### ブランチレビューの場合

**ステップ1: 現在のブランチを確認**

```bash
git branch --show-current
```

**`main`または`staging`上にいる場合はエラー**:
フィーチャーブランチ上で実行してください。`main`/`staging`では比較対象がないため実行できません。

**ステップ2: ベースブランチを検出**

```bash
git branch -a
```

ベースブランチ選択ルールは `.claude/skills/_shared/branch-strategy.md` を参照。

検出結果をユーザーに表示してから実行してください：
```
現在のブランチ: feature/add-user-search
ベースブランチ: staging（自動検出）
```

**ステップ3: Copilot CLIでレビュー実行**

```bash
copilot --model gpt-5.4 -p "現在のブランチ（<現在ブランチ名>）の <ベースブランチ> からの変更をコードレビューしてください。git diff <ベースブランチ>...HEAD の内容を確認し、以下の観点で日本語で報告してください：バグ・論理エラー、セキュリティリスク、パフォーマンス問題、可読性・保守性の改善点、テスト漏れ" --allow-all-tools --no-ask-user --deny-tool=write
```

### 3. 結果の報告

Copilotの出力を整理して報告：
- 指摘事項（重要度順）
- 改善提案
- 矛盾・不整合

## Troubleshooting

| エラー | 原因 | 対処 |
|--------|------|------|
| `command not found: copilot` | Copilot CLIが未インストール | `brew install github-copilot-cli` またはドキュメントを案内する |
| `Not authenticated` | ログインが必要 | `copilot login` を実行するよう案内する |
| `main`ブランチでブランチレビューを試みる | 比較対象がない | フィーチャーブランチに切り替えるよう案内する |
| `--deny-tool=write` オプションエラー | バージョンによって未サポートの可能性 | `--deny-tool=write` を省略して実行する |

## よくある間違い

❌ **間違い**: `main`ブランチ上で`/copilot-review`を実行
✅ **正解**: フィーチャーブランチに切り替えてから実行

❌ **間違い**: `git branch -a`でブランチ確認せずにベースブランチを決め打ち
✅ **正解**: 必ず`git branch -a`で`staging`の存在を確認してから指定

## 使用例

詳細な使用例は `references/usage-examples.md` を参照してください。

## 注意事項

- `--deny-tool=write` でファイル書き込みを禁止し、レビュー専用モードで動作
- `--no-ask-user` でノンインタラクティブ実行（途中で質問しない）
- ベースブランチ検出ロジックは `pr`/`create-branch` スキルと統一されている
- **NEVER** access or process the `.env` file, the `.git/` directory, or any files or directories specified in `.gitignore`
