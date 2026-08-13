#!/bin/bash

set -uo pipefail

repo_dir="$(cd "$(dirname "$0")/../.." && pwd)"
shared_skills=(
  agents-sdk
  cloudflare
  cloudflare-email-service
  cloudflare-one
  cloudflare-one-migrations
  durable-objects
  sandbox-migrate-to-next
  sandbox-next
  sandbox-stable
  turnstile-spin
  web-perf
  workers-best-practices
  wrangler
)

for skill_name in "${shared_skills[@]}"; do
  canonical_path="$repo_dir/.agents/skills/$skill_name"
  claude_path="$repo_dir/.claude/skills/$skill_name"

  if [[ ! -f "$canonical_path/SKILL.md" ]]; then
    printf 'Codex側にSkillの正本がありません: %s\n' "$skill_name" >&2
    exit 1
  fi

  if [[ ! -L "$claude_path" ]]; then
    printf 'Claude側のSkillがシンボリックリンクではありません: %s\n' "$skill_name" >&2
    exit 1
  fi

  if [[ "$(cd "$claude_path" && pwd -P)" != "$(cd "$canonical_path" && pwd -P)" ]]; then
    printf 'Claude側のSkillがCodex側の正本を参照していません: %s\n' "$skill_name" >&2
    exit 1
  fi
done

printf '✓ 共有Skillの正本がCodex側へ統一されています\n'
