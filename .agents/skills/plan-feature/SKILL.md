---
name: plan-feature
description: Use when the user asks for an implementation plan, architecture plan, 設計, 実装方針, どう実装する, or wants planning before code changes.
---

# Plan Feature

実装前に調査、設計、リスク、TODOを整理する。コード変更はしない。

## Workflow

1. 要件、制約、優先順位を確認する。不明点が実装判断を左右する場合は質問する。
2. 既存コードの中心部、共有ロジック、設定、テスト構成を先に読む。
3. 影響範囲を確認し、必要なら公式ドキュメントや一次情報で技術仕様を確認する。
4. 複数案がある場合は保守性、セキュリティ、変更容易性の観点で比較する。
5. システム構成、データフロー、コンポーネント連携を説明する場合はMermaidなどで図を入れる。
6. 実装ステップをフェーズ別TODOに分解する。

## Output

```markdown
## 実装計画: [機能名]

### 概要

### 設計方針

### 影響範囲

### リスクと軽減策

### TODO
#### Phase 1: [名前]
- [ ] `path/to/file` — 作業内容
- [ ] 検証: 確認内容
```

## Guardrails

- 計画のみを返し、実装はユーザーの明示的な続行指示後に行う。
- 未確認の前提は「未確認」と明記する。
