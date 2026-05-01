---
name: reload-context
description: CLAUDE.md/CLAUDE.local.md/rules/README.md編集後にコンテキストキャッシュを即座にクリアして再読み込み。「コンテキストを再読み込み」「設定をリロード」「CLAUDE.mdを読み直して」と言われた時に使用
allowed-tools:
  - Bash
---

# Reload Context

`load_context.sh`と`load_memory.sh`のTTLキャッシュをクリアし、次のツール実行時に強制再読み込みさせます。

## 仕組み

通常、コンテキストとメモリは1時間TTLでキャッシュされます。`SessionStart`の`resume|clear|compact`では`--force`で即時再読み込みされますが、セッション中にCLAUDE.md系ファイルを編集した場合は反映されません。このスキルはキャッシュタイムスタンプを削除することで、次のツール実行時にhookが再実行されます。

## 実行手順

### キャッシュクリア

```bash
PROJECT_HASH=$(echo -n "$(pwd)" | md5 | cut -c1-8)
rm -f "/tmp/claude_context_timestamp_${PROJECT_HASH}"

CACHE_KEY_MEMORY="$(pwd):"
MEMORY_HASH=$(echo -n "$CACHE_KEY_MEMORY" | md5 | cut -c1-8)
rm -f "/tmp/claude_memory_timestamp_${MEMORY_HASH}"
```

これで次のツール実行時に`load_context.sh`と`load_memory.sh`が再実行され、最新のコンテキストが注入されます。

## 使用タイミング

- `~/.claude/CLAUDE.md`を編集した後
- プロジェクトの`CLAUDE.md`または`CLAUDE.local.md`を編集した後
- `~/.claude/rules/*.md`を編集した後
- `~/.claude/projects/*/memory/*.md`を編集した後
- `README.md`を編集した後

## 読み込まれる内容

`load_context.sh`が読み込むファイル:
- `~/.claude/CLAUDE.md`（User Memory Global）
- `CLAUDE.md`または`.claude/CLAUDE.md`（Project Memory）
- `CLAUDE.local.md`（Project Memory Local、gitignore対象）
- `~/.claude/rules/*.md`（pathsフロントマターなしのrule）
- `README.md`

`load_memory.sh`が読み込むファイル:
- `~/.claude/projects/{プロジェクトキー}/memory/*.md`（MEMORY.mdを除く全件）

## 注意事項

- キャッシュクリアのみで、このスキル自体はファイル内容を表示しません
- 次のツール実行時にhookが自動的に再実行されます
- 即座に内容を確認したい場合は`! ~/.claude/hooks/load_context.sh --force`を直接実行してください
