---
name: start-dev-team
description: >
  Claude Code Agent Teamsで開発チームを起動。フェーズごとに必要最小限のロールを選んでleadに編成プロンプトを発火する。
  「開発チーム起動」「Agent Team作って」「フェーズ別チーム」と言われた時、または `/start-dev-team --phase requirements|design|implementation|review|release` 形式で呼ばれた時に使用
argument-hint: "--phase requirements|design|implementation|review|release"
allowed-tools:
  - Read
  - Bash
user-invocable: true
---

# start-dev-team: フェーズ別Agent Team起動

Claude Code Agent Teams機能を使い、開発フェーズに応じた専門チームを起動するためのテンプレート発火skill。

## 前提条件

1. `~/.claude/settings.json` の `env` に `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"` が設定済み
2. Claude Code v2.1.32以上(`claude --version` で確認)
3. **先行チームが存在する場合は事前にcleanupを実行**: leadに「Clean up the team」と指示してから本skillを呼ぶ
4. Claude Code v2.1.198以降はsubagentがbackgroundで動くため、必要最小人数で起動し、各teammateに完了条件と追加委譲禁止を明示する

## ロール一覧(参照先 `.claude/agents/`)

| 名前 | model | 主な責務 |
|---|---|---|
| `team-manager` | sonnet | 要件整理、タスク分配、進行管理 |
| `team-designer` | sonnet | UX/UI、データモデル、API仕様設計 |
| `architect-lead` | opus | 全体構造、技術選定、非機能要件 |
| `software-engineer` | sonnet | 機能実装、単体テスト、リファクタ |
| `change-reviewer` | sonnet | 品質/保守性レビュー、QA観点 |
| `security-reviewer` | sonnet | セキュリティレビュー |
| `tech-writer` | haiku | README、ADR、APIドキュメント |
| `repo-explorer` | haiku | リポジトリ構造調査(architect-lead補助) |

## 実行手順

### 1. 引数パース

`--phase` の値で発火するプロンプトを切り替える:

- `requirements`: 要件定義フェーズ
- `design`: 設計フェーズ
- `implementation`: 実装フェーズ
- `review`: レビューフェーズ
- `release`: リリースフェーズ

引数が不正な場合は使用例を表示して終了。

### 2. フェーズ別チーム編成プロンプト

leadに以下の自然言語プロンプトを発火する(または、人間がコピペしてleadに渡す)。

全フェーズ共通で、leadプロンプトには次を含める:

- 以下のロールは候補であり固定人数ではない。依頼された役割と独立した成果物に応じて必要最小限を選ぶ。ユーザー指定がなければ原則1人から始める。判断と結果の統合はleadが行う。
- 対象リポジトリの絶対パス、確認済みの要件、維持する操作経路、制約、対象ファイルまたは差分、完了条件を渡す。仮説や検討案は要件と分ける。
- 必要な文脈が渡された場合、メモリ検索、全体ルールの再読、対象外の一覧取得、依頼していないスキルや検証を繰り返させない。担当ファイルを分け、他担当の編集を巻き戻させない。
- レビュー担当は読み取りだけとし、テスト実行はleadが担当する。共有DBを使うRailsテストは並行実行しない。
- 待機時間の経過だけで失敗と判断せず、同じteammateの状態と結果を確認する。重複起動しない。
- Treat the listed roles as candidates, not a required headcount. Start with the minimum roles needed for independent deliverables, and add a role only when the authorized scope requires its distinct responsibility.
- Teammates must not invoke skills or spawn nested subagents. Escalate blockers to the lead.
- Give each teammate a bounded deliverable and wait for their result before marking the phase complete.
- Keep background work visible; summarize pending teammates before moving to the next step.

#### requirementsフェーズ(最終判断:人間 / plan mode強制)

```text
Create an agent team for requirements gathering. Select the necessary roles and require plan approval:
- team-manager (use plan mode): 要件整理とタスク分解
- team-designer (use plan mode): UX/データモデルの初期スケッチ

各teammateはplan modeで動作し、leadから人間に承認を仰ぐまで実装に進まない。
このフェーズの目的は要件確定であり、コード変更は行わない。
```

#### designフェーズ(最終判断:人間 / plan mode強制)

```text
Create an agent team for design. Select the necessary roles and require plan approval:
- architect-lead (use plan mode): 全体構造・技術選定の判断
- team-designer (use plan mode): 詳細設計

architect-leadとteam-designerはplan modeで設計案を出す。
既存構造の調査が広範で、別担当に切り出す価値が明確な場合は、許可されたdesignフェーズの範囲でleadがrepo-explorerを追加する。調査が依頼範囲を広げる場合だけ人間に確認する。
最終承認は人間が行う。
```

#### implementationフェーズ(最終判断:自律)

```text
Create an agent team for implementation. Spawn 1 teammate initially:
- software-engineer: 機能実装と単体テスト。担当領域はソースコード(src/, lib/, app/, test/, spec/ 等)とコードコメントのみ

software-engineerは自律的に進めて構わないが、設計から逸脱する判断はleadへエスカレーション。
詰まった場合はleadへ状況、試したこと、次の選択肢を返す。追加subagentやskillは呼ばない。
実装完了後、依頼された範囲にレビューや文書更新まで含まれる場合は、leadが必要性を判断してchange-reviewerやtech-writerを追加する。依頼範囲が実装までの場合は追加せず、次の作業として報告する。
```

#### reviewフェーズ(最終判断:人間)

```text
Create an agent team for code review. Spawn 1 teammate initially:
- change-reviewer: 品質/保守性/QA観点のレビュー

認証、認可、入力処理、API、権限、機密情報を含む変更では、reviewフェーズの範囲内でleadがsecurity-reviewerを追加する。
最終的なPR可否判断は人間が行う。
```

Codex CLI(gpt-5.6-sol xhigh)による徹底レビューを併走させたい場合は、本チームのcleanup後にleadから `/codex-review` skillを別途呼ぶ(skill側でchange-reviewer/security-reviewer subagentを並列起動するため、Agent Teamsの外で動く)。

#### releaseフェーズ(最終判断:人間)

```text
Create an agent team for release preparation. Select the necessary roles:
- team-manager: リリースタスク整理と承認窓口
- tech-writer: README/CHANGELOG/リリースノート更新

実装変更は行わず、ドキュメントとリリース手順の整備のみ。
最終リリース可否は人間が承認する。
```

### 3. フェーズ遷移ガイド

各フェーズ完了後、次フェーズまで許可されていればその範囲で進める。計画だけの依頼や明示的な停止点では人間の承認を待つ。次フェーズへ進む場合の手順:

1. lead側で「Clean up the team」を指示してチームを終了
2. `~/.claude/teams/` 配下が整理されたことを確認
3. 本skillを次フェーズの引数で呼び直す

## 制限事項(Agent Teams公式仕様)

- **1セッション1チーム**: 先行チームのcleanup必須
- **入れ子不可**: teammate内からこのskillを呼んでも入れ子チームは作れない
- **session resumption**: `/resume`/`/rewind` はin-process teammateを復元しない
- **lead固定**: 途中でleadを変更できない
- **permission継承**: teammateはspawn時のlead permissionを継承
- **background既定**: v2.1.198以降、subagentは既定でbackground実行される。完了待ちとcleanupを明示しないと未回収の作業が残りやすい

## 使用例

```
/start-dev-team --phase requirements   # 要件定義チームを起動
/start-dev-team --phase design          # 設計チームを起動(先行cleanup後)
/start-dev-team --phase implementation  # 実装チームを起動
/start-dev-team --phase review          # レビューチームを起動
/start-dev-team --phase release         # リリースチームを起動
```

## 参考

- 公式ドキュメント: https://code.claude.com/docs/en/agent-teams
- ロール定義: `.claude/agents/`
- フェーズ運用ルール: プロジェクトに`CLAUDE.local.md`があればその`Typical Team`セクションを参照。存在しないプロジェクトでも、本skillの共通制限とbackground既定の注意を優先する
