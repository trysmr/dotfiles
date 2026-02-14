#!/bin/bash

input=$(cat)
is_copilot=$(echo "$input" | jq -r 'has("toolName")')
command=$(echo "$input" | jq -r '
  (
    .toolArgs? | fromjson? | .command?
  ) // .toolInput.command? // .tool_input.command? // ""
')

deny() {
  local message="$1"

  if [ "$is_copilot" = "true" ]; then
    jq -nc --arg msg "$message" \
      '{"permissionDecision":"deny","permissionDecisionReason":$msg}'
    exit 0
  fi

  echo "$message" >&2
  exit 2
}

# 対象：rails, bundle, rake など（bin/rails, ./bin/rails なども検知）
if [[ "$command" =~ ^(\.?/?bin/)?(rails|bundle|rake)([[:space:]]|$) ]]; then
  deny "Dockerコンテナ内で実行してください: docker compose exec app $command"
fi

exit 0
