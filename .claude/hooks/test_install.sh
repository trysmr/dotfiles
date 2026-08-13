#!/bin/bash

set -uo pipefail

repo_dir="$(cd "$(dirname "$0")/../.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install-test.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT

fixture_dir="$test_dir/repo"
test_home="$test_dir/home"
mkdir -p \
  "$fixture_dir/.config/herdr" \
  "$fixture_dir/.claude/skills" \
  "$fixture_dir/.claude/skills/different" \
  "$fixture_dir/.agents/skills/example" \
  "$fixture_dir/.agents/skills/codex-example" \
  "$test_home/.config/herdr" \
  "$test_home/.copilot/skills/example" \
  "$test_home/.copilot/skills/different" \
  "$test_home/.codex/skills/codex-example"
cp "$repo_dir/install.sh" "$fixture_dir/install.sh"
printf 'name = "dracula"\n' > "$fixture_dir/.config/herdr/config.toml"
printf 'local state\n' > "$test_home/.config/herdr/session.json"
printf 'example skill\n' > "$fixture_dir/.agents/skills/example/SKILL.md"
ln -s ../../.agents/skills/example "$fixture_dir/.claude/skills/example"
printf 'dotfiles version\n' > "$fixture_dir/.claude/skills/different/SKILL.md"
printf 'codex skill\n' > "$fixture_dir/.agents/skills/codex-example/SKILL.md"
cp \
  "$fixture_dir/.agents/skills/example/SKILL.md" \
  "$test_home/.copilot/skills/example/SKILL.md"
printf 'copilot version\n' > "$test_home/.copilot/skills/different/SKILL.md"
cp \
  "$fixture_dir/.agents/skills/codex-example/SKILL.md" \
  "$test_home/.codex/skills/codex-example/SKILL.md"

HOME="$test_home" bash "$fixture_dir/install.sh" --skip-check >/dev/null

expected_link="$(cd "$fixture_dir/.config" && pwd -P)/herdr"
actual_link="$(readlink "$test_home/.config/herdr")"

if [[ "$actual_link" != "$expected_link" ]]; then
  printf 'Herdr設定ディレクトリのリンク先が不正です: %s\n' "$actual_link" >&2
  exit 1
fi

if [[ ! -f "$test_home/.config/herdr.before-dotfiles/session.json" ]]; then
  printf '既存のHerdrデータが退避されていません\n' >&2
  exit 1
fi

expected_skill_link="$(cd "$fixture_dir/.claude/skills" && pwd -P)/example"
actual_skill_link="$(readlink "$test_home/.copilot/skills/example")"

if [[ "$actual_skill_link" != "$expected_skill_link" ]]; then
  printf 'Copilotスキルのリンク先が不正です: %s\n' "$actual_skill_link" >&2
  exit 1
fi

if [[ ! -f "$test_home/.copilot/skills.before-dotfiles/example/SKILL.md" ]]; then
  printf '既存のCopilotスキルが退避されていません\n' >&2
  exit 1
fi

if [[ -L "$test_home/.copilot/skills/different" ]]; then
  printf '内容が異なるCopilotスキルがリンクに置き換えられました\n' >&2
  exit 1
fi

if [[ "$(cat "$test_home/.copilot/skills/different/SKILL.md")" != "copilot version" ]]; then
  printf '内容が異なるCopilotスキルが変更されました\n' >&2
  exit 1
fi

expected_codex_link="$(cd "$fixture_dir/.agents/skills" && pwd -P)/codex-example"
actual_codex_link="$(readlink "$test_home/.agents/skills/codex-example")"

if [[ "$actual_codex_link" != "$expected_codex_link" ]]; then
  printf 'Codexスキルのリンク先が不正です: %s\n' "$actual_codex_link" >&2
  exit 1
fi

if [[ -e "$test_home/.codex/skills/codex-example" ]]; then
  printf 'Codexの旧Skillが有効な配置に残っています\n' >&2
  exit 1
fi

if [[ ! -f "$test_home/.codex/skills.before-dotfiles/codex-example/SKILL.md" ]]; then
  printf 'Codexの旧Skillが退避されていません\n' >&2
  exit 1
fi

printf '✓ 既存データを退避し、設定ディレクトリをリンクしました\n'
