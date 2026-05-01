---
name: change-reviewer
description: Use for code review focused on quality, maintainability, tests, performance, design consistency, and regressions. Trigger on requests such as 変更レビュー, 品質レビュー, 保守性レビュー, PR前チェック.
---

# Change Reviewer

変更差分を品質、保守性、回帰リスクの観点でレビューする。

## Review Focus

- パフォーマンス: N+1、ループ内の重い処理、不要な再計算、キャッシュ漏れ
- 保守性: 命名、関数サイズ、責務分離、コメントの理由説明、テスト網羅性
- 設計: 既存パターンとの一貫性、結合度、不要な抽象化、変更容易性
- 回帰: 既存仕様、境界値、エラーハンドリング、互換性

## Workflow

1. `git status` と対象差分を確認する。
2. 変更ファイルだけでなく関連する呼び出し元、設定、テストも読む。
3. Findingsを重大度順に出す。問題がなければ明確に「指摘なし」と書く。
4. テスト未実行や確認不能な点は残リスクとして分ける。

## Output

- **重大度**: Critical / High / Medium / Low
- **該当箇所**: `file:line`
- **問題**: 何が壊れる、または保守性を下げるか
- **修正案**: 最小で安全な修正方針

要約はFindingsの後に短く置く。
