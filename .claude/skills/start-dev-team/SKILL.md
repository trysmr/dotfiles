---
name: start-dev-team
description: >
  Claude Code Agent Teamsで開発チームを起動。フェーズごとに7ロールから3-5人を選んでleadに編成プロンプトを発火する。
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

## ロール一覧(参照先 `.claude/agents/`)

| 名前 | model | 主な責務 |
|---|---|---|
| `team-manager` | sonnet | 要件整理、タスク分配、進行管理 |
| `team-designer` | sonnet | UX/UI、データモデル、API契約設計 |
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

#### requirementsフェーズ(最終判断:人間 / plan mode強制)

```text
Create an agent team for requirements gathering. Spawn 2 teammates and require plan approval for each:
- team-manager (use plan mode): 要件整理とタスク分解
- team-designer (use plan mode): UX/データモデルの初期スケッチ

各teammateはplan modeで動作し、leadから人間に承認を仰ぐまで実装に進まない。
このフェーズの目的は要件確定であり、コード変更は行わない。
```

#### designフェーズ(最終判断:人間 / plan mode強制)

```text
Create an agent team for design. Spawn 3 teammates and require plan approval for the first two:
- architect-lead (use plan mode): 全体構造・技術選定の判断
- team-designer (use plan mode): 詳細設計
- repo-explorer: 既存構造の調査(補助)

architect-leadとteam-designerはplan modeで設計案を出す。
repo-explorerは構造把握のみで判断はしない。
最終承認は人間が行う。
```

#### implementationフェーズ(最終判断:自律)

```text
Create an agent team for implementation. Spawn 3 teammates with explicit file-ownership boundaries:
- software-engineer: 機能実装と単体テスト。担当領域はソースコード(src/, lib/, app/, test/, spec/ 等)とコードコメントのみ
- change-reviewer: 変更差分の品質レビュー。書き込みは行わずレポートのみ
- tech-writer: ドキュメント追従更新。担当領域はdocs/, doc/, README.md, CHANGELOG.md等のドキュメントファイルのみ

ファイル衝突を避けるため、software-engineerとtech-writerは同一ファイルを編集しない。
software-engineerは自律的に進めて構わないが、設計から逸脱する判断はleadへエスカレーション。
詰まった場合は`Agent` tool経由で`codex:codex-rescue`を呼ぶ。
```

#### reviewフェーズ(最終判断:人間)

```text
Create an agent team for code review. Spawn 2 teammates:
- change-reviewer: 品質/保守性/QA観点のレビュー
- security-reviewer: セキュリティ観点のレビュー

両者は並列で観点を分けて検証する。
最終的なPR可否判断は人間が行う。
```

Codex CLI(gpt-5.5 xhigh)による徹底レビューを併走させたい場合は、本チームのcleanup後にleadから `/codex-review` skillを別途呼ぶ(skill側でchange-reviewer/security-reviewer subagentを並列起動するため、Agent Teamsの外で動く)。

#### releaseフェーズ(最終判断:人間)

```text
Create an agent team for release preparation. Spawn 2 teammates:
- team-manager: リリースタスク整理と承認窓口
- tech-writer: README/CHANGELOG/リリースノート更新

実装変更は行わず、ドキュメントとリリース手順の整備のみ。
最終リリース可否は人間が承認する。
```

### 3. フェーズ遷移ガイド

各フェーズ完了後、人間が次フェーズへの遷移を承認したら以下の手順:

1. lead側で「Clean up the team」を指示してチームを終了
2. `~/.claude/teams/` 配下が整理されたことを確認
3. 本skillを次フェーズの引数で呼び直す

## 制限事項(Agent Teams公式仕様)

- **1セッション1チーム**: 先行チームのcleanup必須
- **入れ子不可**: teammate内からこのskillを呼んでも入れ子チームは作れない
- **session resumption**: `/resume`/`/rewind` はin-process teammateを復元しない
- **lead固定**: 途中でleadを変更できない
- **permission継承**: teammateはspawn時のlead permissionを継承

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
- フェーズ運用ルール: `CLAUDE.local.md` の `Typical Team` セクション
