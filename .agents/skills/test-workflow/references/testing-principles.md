# テスト原則

## 期待値

- method under testから期待値を生成せず、literal stringやnumberで書く。
- searchやqueryではIDだけでなく、実際の表示内容と完全な結果集合を検証する。
- 結果集合は、失敗diffが明確になる`assert_equal`相当を優先する。

## 可読性

- 各test caseへsetupとassertionを直接書き、過度にDRY化しない。
- stub/mockの共通helperは許容する。
- test名を繰り返すcommentを書かず、複数caseをまとめるsection headingだけに使う。

## SearchとFilter

- fixtureの検索対象fieldへ実dataを入れ、hitとno-hitの両方を検証する。
- prefix除去やtrim後に空になる入力を検証する。
- 正規化後に空ならunfiltered scopeへ落とさず、空結果を返すことを確認する。

## 公開契約

- method signature、optional argument、branch、nil許容などの新しい公開契約は、定義元のunit testで直接検証する。
- thin wrapper経由のtestだけで契約を保証したことにしない。
- optional argumentやnil許容は各branchを直接testする。

## Blast Radius

次の上流変更ではfull suiteを基本とする。

- database schema、migration
- domain model、shared type、interface、entity
- shared library、utility
- configuration、environment、bootstrap
- concern、mixin、decorator、shared helper

単一view、component、endpoint handler、CSS、client-side controllerなどのleaf変更はscoped testでよい。範囲を狭める場合は依存先を説明できることを条件とする。
