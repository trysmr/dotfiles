---
name: reload-context
description: Use when the user asks to reload Codex context, reload settings, コンテキストを再読み込み, 設定をリロード, AGENTS.mdを読み直して, or after editing Codex rules, hooks, skills, or AGENTS.md.
---

# Reload Context

Codex hookのコンテキストキャッシュをクリアし、次回のSessionStartまたはhook実行で最新情報を反映しやすくする。

## Workflow

1. 現在の作業ディレクトリを確認する。
2. 以下のキャッシュを削除する。

```bash
PROJECT_HASH=$(printf '%s' "$(pwd)" | md5 | cut -c1-8)
rm -f "/tmp/codex_context_timestamp_${PROJECT_HASH}"
```

3. 必要ならユーザーにCodex CLIの再起動または `/clear` を案内する。

## Notes

- `.codex/AGENTS.md` は通常Codexが直接読み込むため、完全な反映には新規セッションが最も確実。
- `.codex/hooks/load_context.sh --force` を直接実行すると、hookが注入する追加コンテキストだけ確認できる。
