# Agent Design Guide

## エージェント一覧

| エージェント | モデル | 役割 |
|-------------|--------|------|
| **repo-explorer** | haiku | リポジトリ構造・パターン・依存関係の軽量調査 |
| **change-reviewer** | sonnet | 変更差分の品質・保守性レビュー（命名、N+1、関数サイズ） |
| **security-reviewer** | sonnet | セキュリティ観点のコードレビュー（機密情報、インジェクション、認証不備） |

個別定義: `.claude/agents/` 配下の各ファイルを参照。

## 使い分けガイドライン

### 調査フェーズ
- **新規プロジェクト理解**: `repo-explorer` で構造を把握
- **特定コード検索**: `code-search` Skill（Explore agent、fork context）

### レビューフェーズ
- **コミット後の定期レビュー**: `recent-changes-review` Skill（時間範囲ベース）
- **PR前の差分レビュー**: `review` Skill（change-reviewer + security-reviewer統合）
- **品質のみ確認**: `change-reviewer` を直接使用
- **セキュリティのみ確認**: `security-reviewer` を直接使用
- **外部レビュー**: `codex-review` Skill（Codex CLI連携）

## 連携パターン

### パターン1: 調査 → レビュー
```
repo-explorer（構造把握）→ change-reviewer（品質評価）
```
未知のプロジェクトで変更レビューが必要な場合。まず構造を理解し、その文脈でレビューを行う。

### パターン2: 並列レビュー（review Skill）
```
change-reviewer（品質・保守性）─┐
                                ├→ 結果統合・重大度順に報告
security-reviewer（セキュリティ）─┘
```
PR前の包括的レビュー。両エージェントの結果を統合して報告する。

### パターン3: 設計 → 実装 → レビュー
```
plan-feature Skill（Plan agent）→ 実装 → review Skill → pr Skill
```
機能開発の全体フロー。設計→実装→レビュー→PRの一貫したワークフロー。

## モデル選択の基準

- **haiku**: 速度優先の探索・調査タスク（repo-explorer, code-search）
- **sonnet**: 精度優先の分析・レビュータスク（change-reviewer, security-reviewer）
- **fork context**: メインコンテキストを消費しないタスク（code-search, plan-feature, review）
