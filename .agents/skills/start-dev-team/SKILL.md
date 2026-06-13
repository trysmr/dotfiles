---
name: start-dev-team
description: Use when the user asks to start a development team, 開発チーム起動, Agent Team作って, フェーズ別チーム, or wants role-based Codex subagents for requirements, design, implementation, review, or release work.
---

# Start Dev Team

フェーズに応じて、Codex custom subagentsを組み合わせて作業を進めるための運用スキル。

Claude Agent Teamsの自動チーム生成とは違い、Codexでは必要なsubagentを明示的に呼び出し、メインスレッドで判断と統合を行う。

## Phase Map

| Phase | Primary subagents | Purpose |
| --- | --- | --- |
| `requirements` | `team-manager`, `team-designer` | 要件整理、初期UX/データモデル整理 |
| `design` | `architect-lead`, `team-designer`, `repo-explorer` | 全体構造、詳細設計、既存構造調査 |
| `implementation` | `software-engineer`, `change-reviewer`, `tech-writer` | 実装、品質確認、文書追従 |
| `review` | `change-reviewer`, `security-reviewer` | 品質・セキュリティレビュー |
| `release` | `team-manager`, `tech-writer` | リリースタスク整理、リリース文書整備 |

## Workflow

1. ユーザーの依頼からphaseを決める。明示されていない場合は目的から推定し、曖昧なら短く確認する。
2. Phase Mapから必要なsubagentを選ぶ。
3. 依頼内容、制約、対象ファイル、完了条件をsubagentごとに分けて渡す。
4. 並列化できる調査・レビューは並列で実行し、編集を伴う作業は衝突しないよう順序を決める。
5. subagentの結果をメインスレッドで統合し、採用判断、残タスク、検証結果をユーザーに報告する。

## Guardrails

- 最終判断はメインスレッドで行う。subagentの提案をそのまま採用しない。
- 実装やファイル編集は`software-engineer`かメインスレッドに限定し、reviewer系subagentには編集させない。
- `security-reviewer`はセキュリティ関連変更で必須、通常変更では`change-reviewer`を優先する。
- `tech-writer`が文書を更新する場合は、実装と同じファイルを同時に編集しない。
- CodexにClaude Agent Teamsのcleanup、lead、teammate復元はない。必要なら通常のTODO管理で状態を残す。

## Examples

```text
開発チーム起動 --phase design
```

`architect-lead`、`team-designer`、`repo-explorer`を使い、実装前の設計判断と既存構造調査を行う。

```text
Agent Team作って。実装からレビューまで進めたい
```

`software-engineer`で実装し、完了後に`change-reviewer`と必要なら`security-reviewer`で確認する。
