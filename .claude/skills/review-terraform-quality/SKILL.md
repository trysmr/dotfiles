---
name: review-terraform-quality
description: >
  Terraform構成が品質特性をどこまで支えるかを静的にレビューし、確認できる対策・確認できない実動作・検証方法・安全上の制約・証拠の不足を整理。
  「Terraform構成の品質特性を確認」「terraform validate/test/condition/check/Policy as Codeの使い分け」
  「stateやplanを読まずにTerraformをレビュー」と言われた時に使用。
  applyやplanを実行せず、読み取りだけで判断できる範囲と残る確認を切り分ける。
argument-hint: "[moduleパス | --scope | --tooling | --evidence]"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - WebFetch
user-invocable: true
---

# review-terraform-quality: Terraformの品質範囲レビュー

Terraformを品質全体の保証手段にせず、構成で支えられる範囲と、試験・観測・運用で追加確認する範囲を分ける。

## 依頼の種類を決める

### 品質範囲レビュー

Terraform構成が製品品質の9特性をどこまで支えるかを確認する。9特性をすべて`適用する`、`対象外`、`判断待ち`へ分類する。利用時品質の有益性、リスクからの保護、受容性も省略せず、製品品質とは別の表でそれぞれ分類する。Terraformだけでは判定できない場合は`判断待ち`とし、必要な利用状況、利用者情報、実測、観察結果を示す。

### 確認手段の選択

`fmt`、`validate`、`plan`、`test`、各condition、`check`、Policy as Codeから目的に合う手段を選ぶ。狭い質問へ9特性の表を強制せず、選んだ手段では品質全体を確認できないことを明示する。

### 実装証拠レビュー

許可されたTerraform、test file、CI、policy、監視設定を読み、要件、対策、検証、観測、対応の証拠と不足を整理する。

## 共通ワークフロー

1. 対象module、root module、環境、provider、評価範囲、依頼が読み取りだけかを確認する。
2. リポジトリの指示を確認し、`~/.claude/skills/review-terraform-quality/references/terraform-controls.md`を読む（`~/.claude/skills`は実体へのsymlink。CWDに依存せずこの絶対パスで読める）。
3. 構成へ宣言した事実、planで予測する変更、適用後の状態、実際のサービス動作を分ける。
4. Terraformで確認できる対策と、アプリ、データ、負荷試験、障害試験、監視、運用、利用者評価に残る確認を分ける。
5. 品質上の主張へ、要件、対策、検証、観測、対応のどの証拠があるかを対応付ける。
6. 確認した事実、事実から導く推測、判断待ち、実行していない検証を分ける。
7. 根拠を確認できない可用性、復旧時間、性能、保持期間などの目標値を生成しない。
8. 不足をリスク順に並べ、安全に実行できる次の確認と判断担当を示す。

## 安全に確認する

- `.env`、credentials、Terraformのstate、保存済みplan、Gitで除外されるファイルを、明確な必要性と許可なしに読まない。
- 読み取りだけの依頼では、`plan`、`apply`、applyを伴う`terraform test`、import、state操作を実行しない。
- `terraform test`は実資源と費用を発生させ、削除に失敗する可能性があると扱う。
- `sensitive = true`だけでstateやplanから値が除かれると判断しない。
- 実資源、外部接続、本番または機密性の高い環境へ影響する処理は、対象、費用、戻し方を示して明確な許可を得る。
- 実行していないコマンドや試験を成功した証拠にしない。

## 品質全体へ統合する

`engineer-quality-attributes`スキルから利用された場合は、次を返して品質シナリオへ統合できるようにする。

- Terraformで確認できた対策と該当する品質特性
- Terraformだけでは確認できない実動作と利用時品質
- 検証、観測、対応で不足する証拠
- 安全に実行できる次の確認
- 判断が必要な値、担当、トレードオフ

## 出力する

品質範囲レビューでは、9特性の判定表に加え、有益性、リスクからの保護、受容性の判定表を独立して必ず出力する。Terraformだけでは評価できなくても省略せず、各特性を`判断待ち`とする理由と必要な証拠を示す。そのうえで、証拠の対応、判断待ち、次の作業を出力する。確認手段の選択では、目的、選択候補、停止するか警告か、副作用、確認できない範囲を簡潔に出力する。
