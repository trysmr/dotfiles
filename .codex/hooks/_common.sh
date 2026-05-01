#!/bin/bash

extract_field() {
  local field="$1"
  jq -r "
    (.toolArgs? | fromjson? | .${field}?)
    // .toolInput.${field}?
    // .tool_input.${field}?
    // \"\"
  "
}

hook_event_name() {
  jq -r '.hook_event_name // .hookEventName // ""'
}

deny_current_event() {
  local message="$1"
  local event="$2"

  case "$event" in
    PermissionRequest)
      jq -nc --arg msg "$message" '{
        hookSpecificOutput: {
          hookEventName: "PermissionRequest",
          decision: {
            behavior: "deny",
            message: $msg
          }
        }
      }'
      ;;
    *)
      jq -nc --arg msg "$message" '{
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: "deny",
          permissionDecisionReason: $msg
        }
      }'
      ;;
  esac
  exit 0
}

system_message() {
  local message="$1"
  jq -n --arg msg "$message" '{systemMessage: $msg}'
}

extract_patch_paths() {
  awk '
    /^\*\*\* Add File: / { sub(/^\*\*\* Add File: /, ""); print; next }
    /^\*\*\* Update File: / { sub(/^\*\*\* Update File: /, ""); print; next }
    /^\*\*\* Delete File: / { sub(/^\*\*\* Delete File: /, ""); print; next }
  '
}

is_sensitive_path() {
  local path="$1"
  local base

  [ -z "$path" ] && return 1
  base="$(basename "$path" | tr '[:upper:]' '[:lower:]')"

  case "$path" in
    .git|.git/*|*/.git|*/.git/*) return 0 ;;
  esac

  case "$base" in
    .env|.env.*|*.pem|*.key|*.p12|*.pfx|*.jks|id_rsa*|id_ed25519*|id_ecdsa*|id_dsa*|credentials|credentials.*|*credentials.json)
      return 0
      ;;
  esac

  return 1
}
