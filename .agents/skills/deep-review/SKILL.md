---
name: deep-review
description: Use when the user asks for a deep review, しっかりレビュー, 深くレビュー, high-effort review, or a second-pass review before a risky PR.
---

# Deep Review

重要または広範囲な変更に対し、通常レビューより深くリスクを洗い出す。

## Workflow

1. レビュー対象を決める。指定がなければブランチ差分を対象にする。
2. ベースブランチ、コミット履歴、差分、関連する呼び出し元とテストを確認する。
3. 可能なら `change-reviewer` と `security-reviewer` の観点を並列に使う。
4. Critical/Highは修正必須、Medium以下はPR可否の判断材料として報告する。

## Focus

- 動作回帰、境界値、例外系
- データ破壊、権限境界、ログ漏洩
- 保守性、結合度、既存設計との整合性
- テスト不足とCIで検出できないリスク

## Output

Findingsを先に、重大度順に書く。該当箇所は `file:line` 形式にする。指摘がない場合は「Critical/Highなし」「残リスク」を明確に分ける。
