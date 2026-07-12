---
name: rails-practices
description: Use when implementing or reviewing Ruby on Rails changes involving migrations, ActiveRecord queries or scopes, models, or I18n date/time formatting. Apply project conventions first when they conflict with these cross-project defaults.
---

# Rails Practices

Rails固有の変更では、編集前に[references/rails.md](references/rails.md)を読み、対象リポジトリの規則と合わせて適用する。

## Workflow

1. 対象リポジトリのRails version、database構成、既存patternを確認する。
2. migration、query、scope、I18nの該当規則を確認する。
3. generatorやrollbackなど状態を変える操作は、現在の状態と対象を確認してから実行する。
4. modelやmigrationを変更した場合は、blast radiusに合うtestを実行する。

## Priority

リポジトリ固有の明示的規則がある場合はそちらを優先し、差異をユーザーへ示す。
