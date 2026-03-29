#!/bin/bash

source "$(dirname "$0")/_common.sh"

input=$(cat)
is_copilot=$(printf '%s' "$input" | detect_copilot)
command=$(printf '%s' "$input" | extract_field "command")

deny() { deny_action "$1" "$is_copilot"; }

# 対象：rails, bundle, rake など（bin/rails, ./bin/rails なども検知）
if [[ "$command" =~ ^(\.?/?bin/)?(rails|bundle|rake)([[:space:]]|$) ]]; then
  deny "Dockerコンテナ内で実行してください: docker compose exec app $command"
fi

exit 0
