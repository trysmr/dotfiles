---
allowed-tools: Bash(docker compose exec app rubocop -a), Bash(docker compose exec app rails test), Bash(docker compose exec app rails spec), Bash(grep*), Bash(test*)
description: Run Rubocop auto-correct and Rails tests in Docker if applicable
---

## Context

This command inspects `Gemfile.lock` to determine which tools to run:

- If `rubocop` is present, run `docker compose exec app rubocop -a`
- If `rspec-core` is present, run `docker compose exec app rails spec`
- If `minitest` is present, run `docker compose exec app rails test`

Rubocop runs if present. For testing, Minitest is preferred when both are detected.

### Rubocop auto-correct:

!`[ -f "Gemfile.lock" ] && grep -q "rubocop" Gemfile.lock && docker compose exec app rubocop -a || echo 'Skipping rubocop: not found in Gemfile.lock or lockfile missing.'`

### Test execution:

!`[ -f "Gemfile.lock" ] && grep -q "rspec-core" Gemfile.lock && docker compose exec app rails spec \
|| ([ -f "Gemfile.lock" ] && grep -q "minitest" Gemfile.lock && docker compose exec app rails test) \
|| echo 'Skipping tests: no supported test framework found in Gemfile.lock or lockfile missing.'`

## Your task

Check `Gemfile.lock` to determine tool availability.

1. If `rubocop` is present, run `docker compose exec app rubocop -a`
2. If `rspec-core` is present, run `docker compose exec app rails spec`
3. If `minitest` is present, run `docker compose exec app rails test`

Clearly explain:
- Which commands were run or skipped
- Any failures or errors encountered

Output the results in **English**, and include a **Japanese summary** of formatting and test outcomes.

NEVER access or process the `.env` file, the `.git` directory, or any files or directories specified in `.gitignore`.
