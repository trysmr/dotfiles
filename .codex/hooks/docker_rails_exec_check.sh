#!/bin/bash

set -u

source "$(dirname "$0")/_common.sh"

input=$(cat)
event=$(printf '%s' "$input" | hook_event_name)
command=$(printf '%s' "$input" | extract_field "command")

[ -z "$command" ] && exit 0

deny() {
  deny_current_event "$1" "$event"
}

# rails, bundle, rake はプロジェクト依存の実行環境差が出やすいため、コンテナ経由に寄せる。
if [[ "$command" =~ ^(\.?/?bin/)?(rails|bundle|rake)([[:space:]]|$) ]]; then
  deny "Dockerコンテナ内で実行してください: docker compose exec app $command"
fi

exit 0
