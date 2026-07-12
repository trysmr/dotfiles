# Rails実装規則

## Migration

- migration fileを手書きせず、`bin/rails generate migration AddXxxToYyy`で生成してから`change`を編集する。
- localで適用済みかつ未出荷のmigrationを変更する場合は、先にrollbackし、編集後に再度migrateする。
- 複数migrationを戻す場合は`db:rollback STEP=N`を使い、対象数を確認する。
- multi-DBでは対象databaseに合うrollback commandを使う。

## ActiveRecord

`includes`は使わず、query shapeを明示する。

- separate queryなら`preload`
- associationを`WHERE`や`ORDER`で参照してLEFT JOINが必要なら`eager_load`

scopeは安定したdomain語彙に限定する。画面固有filter、current user依存、検索form、集計reportはQuery Objectへ置く。

## I18n

- default formatでは`I18n.l(value)`とし、冗長な`format: :default`を付けない。
- 別formatの場合だけ`format:`を指定する。
- nullable valueは、既存規約に合わせて`I18n.l(value) if value`の明示的guardを使う。
