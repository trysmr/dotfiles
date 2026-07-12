# 詳細な設計原則

## 宣言的設計

- 状態遷移や規則集合の分岐は、可能なら手続きではなくdata structureで表す。
- 副作用を分離し、入力と出力で決まるpure functionを増やす。
- 規則dataを列挙、検索、検証できる形にする。
- 個別例だけでなく、data structure全体のinvariantをテストする。
- 小さなpure functionとdata transformationを組み合わせる。

## 責務に基づく配置

class、constant、errorの配置は、利用側の都合ではなく責務を所有するmoduleで決める。配置案を示すときは責務の観点を先に説明し、利便性は補足に留める。

## Method抽出

private/internal methodは、次の3条件をすべて満たす場合だけ抽出する。

1. 同じlogicが2箇所以上にある。
2. 名前がないと理解しづらい。
3. bodyがcall siteの流れを妨げる長さである。

public methodがobjectのdomain能力を表す場合は、重複や長さだけで判断しない。次も確認する。

- Tell, Don't Askに沿うか。
- 既存のpublic能力と対称性があるか。
- callback、observability、lifecycle hookの将来の接点になるか。
- 削除するとAnemic Domain Modelにならないか。

metric上限へ達した場合は、責務の別classへの委譲、guard clause、data化の順に検討し、行数削減だけの抽出を避ける。

## ActiveRecord scope

scopeは、論理削除状態やrecord固有の分類など、安定したdomain語彙だけに使う。画面固有filter、current user依存、検索form条件、集計reportはQuery Objectへ置き、Relationを受け取ってRelationを返す。

## Boolean命名

新しいboolean columnやpredicate属性は`is_`または`has_`で始める。既存columnは、周辺変更の対象でない限り遡及的にrenameしない。

## Frontendの見た目合わせ

1. 既存CSS classを再利用できるか確認する。
2. 再実装が必要なら、DevToolsでreference componentのcomputed valueを確認する。
3. 対象pageが実際に読むstylesheetを先に確認する。
4. 新旧componentを同じviewで比較して検証する。

値を推測してscreenshot調整を繰り返さない。pixel-levelの調整はbrowserを開いた専用sessionで行う。
