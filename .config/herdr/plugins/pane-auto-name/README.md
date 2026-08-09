# Agent Auto Name

Herdrが検出したAgentへ、指示に使う名前を自動設定するPluginです。同じ名前をPaneの境界にも表示します。

Agent名は作業ディレクトリと連番から生成します。

```text
kotorium-1
kotorium-2
dotfiles-1
```

Agentが動いている間は同じ名前を維持します。手動で設定したAgent名は変更しません。

名前を使って、pane IDを調べずに指示できます。

```bash
herdr agent prompt kotorium-2 "テスト失敗の原因を調べて" --wait
herdr agent get kotorium-1
herdr agent read dotfiles-1
```

AgentがいないPaneの表示名には、次の優先順位を使用します。

1. フォアグラウンドプロセスと作業ディレクトリ
2. 作業ディレクトリ

Pluginが設定した名前とは異なるラベルを手動設定した場合、そのPaneは自動更新の対象から外れます。

## 配置と登録

Plugin本体はdotfilesリポジトリ内のこのディレクトリです。

```text
.config/herdr/plugins/pane-auto-name/
├── herdr-plugin.toml
├── auto_name.py
└── tests/
```

`~/.config/herdr/plugins/config/trysmr.pane-auto-name/`はHerdrがPluginごとに用意する設定保存先です。Plugin本体ではありません。現時点では設定ファイルを使用しないため、空のままで問題ありません。

`install.sh`を実行すると、このリポジトリ内のPlugin本体がHerdrへ登録されます。リポジトリのルートで手動登録する場合は、次のコマンドを使います。

```bash
herdr plugin link "$PWD/.config/herdr/plugins/pane-auto-name"
herdr plugin action invoke trysmr.pane-auto-name.refresh
```
