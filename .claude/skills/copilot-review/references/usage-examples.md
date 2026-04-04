# Copilot Review 使用例

## 例1: ファイルレビュー

```
/copilot-review docs/plan.md
```

実行コマンド:
```bash
copilot --model gpt-5.4 -p "docs/plan.md をコードレビューしてください。以下の観点で確認し、日本語で報告してください：バグ・論理エラー、セキュリティリスク、パフォーマンス問題、可読性・保守性の改善点" --allow-all-tools --no-ask-user --deny-tool=write
```

## 例2: 未コミット変更レビュー

```
/copilot-review --uncommitted
```

実行コマンド:
```bash
copilot --model gpt-5.4 -p "現在の未コミット変更をすべてコードレビューしてください。git diff（未ステージ変更）、git diff --cached（ステージ済み変更）、git status --short（新規ファイル含む）を確認し、新規ファイルの内容も読み込んでください。以下の観点で確認し、日本語で報告してください：バグ・論理エラー、セキュリティリスク、パフォーマンス問題、可読性・保守性の改善点" --allow-all-tools --no-ask-user --deny-tool=write
```

## 例3: ブランチレビュー（stagingあり）

```
/copilot-review --branch
# または引数なし
/copilot-review
```

**ステップ1**: ブランチ確認
```bash
git branch --show-current
# feature/add-user-search
git branch -a
# staging が存在することを確認
```

**ステップ2**: ユーザーに表示
```
現在のブランチ: feature/add-user-search
ベースブランチ: staging（自動検出）
```

**ステップ3**: レビュー実行
```bash
copilot --model gpt-5.4 -p "現在のブランチ（feature/add-user-search）の staging からの変更をコードレビューしてください。git diff staging...HEAD の内容を確認し、以下の観点で日本語で報告してください：バグ・論理エラー、セキュリティリスク、パフォーマンス問題、可読性・保守性の改善点、テスト漏れ" --allow-all-tools --no-ask-user --deny-tool=write
```

## 例4: ブランチレビュー（stagingなし）

```
/copilot-review
```

```bash
copilot --model gpt-5.4 -p "現在のブランチ（feature/add-user-search）の main からの変更をコードレビューしてください。git diff main...HEAD の内容を確認し、以下の観点で日本語で報告してください：バグ・論理エラー、セキュリティリスク、パフォーマンス問題、可読性・保守性の改善点、テスト漏れ" --allow-all-tools --no-ask-user --deny-tool=write
```

## codex-reviewとの対応表

| 操作 | codex-review | copilot-review |
|------|-------------|----------------|
| ファイルレビュー | `/codex-review docs/plan.md` | `/copilot-review docs/plan.md` |
| 未コミット変更 | `/codex-review --uncommitted` | `/copilot-review --uncommitted` |
| ブランチレビュー | `/codex-review --branch` | `/copilot-review --branch` |
| 引数なし（デフォルト） | `/codex-review` | `/copilot-review` |
