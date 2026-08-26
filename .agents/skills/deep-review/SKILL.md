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
4. `reviewer`はコードを修正しない。Critical/Highの指摘は停止条件とし、根拠・影響・対応案とともにユーザーへ報告し、ユーザーの判断を待つ。Medium以下はPR可否の判断材料として報告する。

## Focus

- 動作回帰、境界値、例外系
- データ破壊、権限境界、ログ漏洩
- 保守性、結合度、既存設計との整合性
- テスト不足、各アサーションが守る確認済みの挙動、否定アサーションで不在そのものを検証する根拠
- CIで検出できないリスク

## Output

Findingsを先に、重大度順に書く。該当箇所は `file:line` 形式にする。各指摘は、会話を読んでいない新規参加者が対象の操作経路、成立条件、現象、影響を理解できる形にする。「前述の問題」「このケース」など、参照先が会話内にしかない表現は具体的な対象へ直す。指摘がない場合は「Critical/Highなし」「残リスク」を明確に分ける。
