---
name: test-workflow
description: Use when the user asks for TDD, test design, test quality review, or a non-trivial behavior change where Spike/Stabilize/Maintain classification would materially affect the work. Do not trigger for routine edits with an obvious verification path.
---

# Test Workflow

テスト方針が実装判断を変える場合だけ使う。通常の小さな修正では、リポジトリのDefinition of Doneに従って必要な検証を実行すればよい。

## Phase

作業前に必要なら1つだけ分類する。

- `Spike`: 形が未知。学習目的なのでTDD不要。残すなら後でStabilizeへ移す。
- `Stabilize`: 残す実装を作る。非自明なロジックはテストを先に置く。
- `Maintain`: 既存動作を変える。振る舞い変更は回帰テストで固定する。

設定、文書、タイポ、単純リネーム、検証経路が明らかな小変更は分類を省略してよい。その場合は省略理由を短く述べる。

## TDD

`Stabilize`または振る舞い変更を伴う`Maintain`では、原則として次の順で進める。

1. 期待する契約や失敗ケースをテストで表す。
2. そのテストが意図した理由で失敗することを確認する。
3. 最小の実装で通す。
4. 影響範囲に合う既存テストを実行する。

テストを先に置けない場合は、理由と代替検証を明示する。

## Test Quality

- 期待値はリテラルで書く。テスト対象の出力を期待値生成に使わない。
- テストケースは単体で読めるようにし、過度なhelper化で意図を隠さない。
- 検索や一覧のテストではIDだけでなく、意味のある表示内容や結果集合を検証する。
- 公開API契約を増やす場合は、その契約を直接テストする。

## Report

最終報告には実行した検証コマンドと結果を含める。未検証の範囲がある場合は、理由と残リスクを明示する。
