---
name: start-dev-team
description: Use when the user asks to start a development team, 開発チーム起動, Agent Team作って, フェーズ別チーム, or wants role-based Codex subagents for requirements, design, implementation, review, or release work.
---

# Start Dev Team

rootだけでは分離しづらい作業に、必要最小限のCodex custom subagentを割り当てる運用スキル。

Claude Agent Teamsの自動チーム生成とは違い、Codexでは必要なsubagentを明示的に呼び出し、メインスレッドで判断と統合を行う。

## Candidate Map

| Phase | Candidate | Use when |
| --- | --- | --- |
| `requirements` | `team-manager` or `team-designer` | 要件整理またはUX・データモデル設計を独立して任せる |
| `design` | `repo-explorer`, `architect-lead`, or `team-designer` | 限定調査、全体構造、詳細設計のいずれかに専門的な判断が必要 |
| `implementation` | `software-engineer` | 所有ファイルを分離できる実装を独立して任せる |
| `review` | `change-reviewer`; `security-reviewer` when needed | 最後のコード変更後の品質確認、またはセキュリティ関連変更の確認 |
| `release` | `tech-writer` | リリース文書を独立して作成する |

## Workflow

1. rootで続ける場合とsubagentへ分離する場合を比較する。独立した作業または役割固有の判断がなければrootで続ける。
2. Candidate Mapから原則1つだけ選ぶ。互いに独立した作業、または通常レビューに加えてセキュリティ確認が必要な場合だけ2つ使う。
3. 確認済みの要件、維持する操作経路、制約、対象ファイル、完了条件だけを渡す。仮説や検討案は現在の判断に必要な場合だけ分離して含める。テストを依頼する場合は期待する挙動と再発条件を渡す。
4. `fork_turns`は`none`または必要な直近turn数を使い、上記の情報を依頼文へ明示する。作業を安全に再構成できない場合だけ全履歴を渡す。
5. subagentの結果をメインスレッドで検証し、採用判断、残タスク、検証結果をユーザーに報告する。

## Guardrails

- 最終判断はメインスレッドで行う。subagentの提案をそのまま採用しない。
- subagentへの依頼と結果には具体的な名前、操作、状態、パスを使う。依頼内容や一般的な背景を結果で繰り返させない。
- ユーザーが人数や役割を指定していない場合、同時に使うsubagentは最大2つとする。subagentに追加のsubagent起動や再委譲をさせず、追加調査が必要かはメインスレッドで判断する。
- 各subagentには完了条件を明示して渡し、結果を受け取ってからフェーズ完了を宣言する。
- 実装やファイル編集は`software-engineer`かメインスレッドに限定し、reviewer系subagentには編集させない。
- `change-reviewer`は最後のコード変更後に1回使う。同じ差分の確認結果があれば、PR作成時に再利用する。
- `security-reviewer`はセキュリティ関連変更で必須、通常変更では`change-reviewer`を優先する。
- `tech-writer`が文書を更新する場合は、実装と同じファイルを同時に編集しない。
- CodexにClaude Agent Teamsのcleanup、lead、teammate復元はない。必要なら通常のTODO管理で状態を残す。

## Examples

```text
開発チーム起動 --phase design
```

設計判断を左右する既存パターンの調査を`repo-explorer`へ任せ、結果を確認してから追加のagentが必要か判断する。

```text
Agent Team作って。実装からレビューまで進めたい
```

`software-engineer`で実装し、完了後に`change-reviewer`と必要なら`security-reviewer`で確認する。
