# Terraformによる対策と確認

Terraformを品質全体の保証手段ではなく、品質シナリオの一部を支える技術領域別の手段として扱う。

## 目次

- [基本姿勢](#基本姿勢)
- [品質特性との対応](#品質特性との対応)
- [利用時品質との分離](#利用時品質との分離)
- [コマンドと機能の使い分け](#コマンドと機能の使い分け)
- [Policy as Code](#policy-as-code)
- [証拠としての扱い](#証拠としての扱い)
- [安全規則](#安全規則)
- [クラウド固有資料の分離](#クラウド固有資料の分離)
- [参照情報](#参照情報)

## 基本姿勢

- 品質モデルと品質シナリオを先に作り、Terraformで扱える項目だけを対応付ける。
- 利用時品質を別に確認し、Terraformだけでは利用状況での便益、リスク、受容を評価できないと明示する。
- 構成へ宣言した事実、planで予測した変更、適用後の状態、実際のサービス動作を分ける。
- 設定の存在だけで可用性、性能、復旧、セキュリティ、安全性を満たすと判断しない。
- アプリ、データ、監視、運用、利用者評価に残る確認を明示する。

## 品質特性との対応

| 品質特性 | 適合度 | Terraformで確認できる例 | Terraformだけでは確認できない例 |
|---|---:|---|---|
| 機能適合性 | 一部 | moduleの入力、出力、条件分岐、生成する資源 | 業務結果、計算結果、画面やAPIの振る舞い |
| 性能効率性 | 一部 | instance class、容量、接続上限、自動拡張の設定 | 実際の応答時間、処理量、資源競合、依存先の遅延 |
| 互換性 | 一部 | network、port、protocol、DNS、接続先の設定 | 相手システムとの情報交換、形式、再試行、実際の共存 |
| インタラクション能力 | ほぼ対象外 | 運用者向け入力説明やvalidationの一部 | UI、理解、学習、誤操作防止、アクセシビリティ |
| 信頼性 | 強い | 冗長化、複数zone、health check、backup、削除保護 | 障害時の切替、復旧時間、復元後のデータ整合性 |
| セキュリティ | 強い | IAM、暗号化、公開範囲、通信制御、監査設定 | アプリの認可、入力攻撃、運用上の誤用、実際の攻撃耐性 |
| 保守性 | 一部 | module化、version制約、入力説明、静的確認、test | アプリの変更容易性、原因解析、チームの理解 |
| 柔軟性 | 一部 | 環境差の変数化、容量変更、moduleの交換、導入自動化 | データ移行、業務変更、外部サービス置換の全工程 |
| 安全性 | 一部 | 削除保護、変更防止、許容範囲、fail safe設定 | 人、財産、組織活動、環境への危害と実際の警告効果 |

適合度は一般的な目安であり、対象moduleを読まずに確定しない。

## 利用時品質との分離

利用時品質は製品品質とは別の表にし、Terraformだけで判断できなくても3特性を省略しない。

| 利用時品質 | Terraformだけでは確認できない主な内容 | 追加で必要な証拠 |
|---|---|---|
| 有益性 | 利用者や組織が目的を達成し、必要な便益を得られるか | 利用状況、業務結果、タスク完了、所要時間、利用者評価 |
| リスクからの保護 | 経済、人命・健康、社会・倫理、環境への悪影響を抑えられるか | リスク分析、事故・損失記録、実地訓練、監査、利害関係者の評価 |
| 受容性 | 利用者や責任を持つ組織が体験、信頼、規則への適合を受け入れられるか | 利用者調査、苦情、説明の理解、運用観察、規則への適合確認 |

情報がない特性は`判断待ち`とし、判断に必要な利用状況、担当、証拠を示す。

## コマンドと機能の使い分け

### `terraform fmt`

- 書式を標準化する。
- review差分と保守性を改善するが、構文、意味、実環境の品質を確認しない。
- 変更を避けて確認する場合は、対象を限定して`terraform fmt -check`を検討する。

### `terraform validate`

- 構成の構文と内部整合性を、特定の変数値や既存stateに依存せず確認する。
- remote service、provider API、実際の資源状態は確認しない。
- providerやmoduleを用意するための初期化が必要になる場合がある。
- `terraform init -backend=false`を使う場合も、依存物の取得、`.terraform`への書き込み、lock fileの変更有無を先に確認する。

### `terraform plan`

- 特定の変数、workspace、stateを踏まえ、予定する変更を確認する。
- remote state、provider API、資格情報へアクセスする可能性がある。
- 保存したplanには機密値が含まれる可能性がある。明確な必要性と許可なしに作成、保存、表示しない。
- planの成功はapply後の動作、可用性、性能、復旧結果を保証しない。

### `terraform test`

- moduleまたはroot moduleの論理、入力、出力、生成する資源をtest fileのassertionで確認する。
- `command = plan`を選べる場合も、providerやdata sourceによる外部アクセスの有無を確認する。
- applyを行うtestは実資源を作成し、費用が発生し得る。終了時の削除が失敗する可能性もある。
- 実行前にtest file、provider、対象account、region、命名、上限、cleanup、費用を確認し、明確な許可を得る。
- 本番accountや機密性の高い環境で実行しない。

### 変数の`validation`

- 入力値の形式、範囲、許容集合を入口で確認する。
- 失敗時は処理を止め、利用者が修正できる説明を返す。
- 外部資源の実在や動作は確認しない。

### `precondition`

- resource、data source、outputを処理する前に、前提条件を確認する。
- 必ず守る前提を、失敗時に停止させたい場合に使う。
- 値を適用後にしか取得できない場合は、評価時点を確認する。

### `postcondition`

- resourceの計画・作成後またはdata sourceの読み取り後に、得られた状態を確認する。
- 後続処理へ不適切な値を渡さないために使う。
- 失敗しても、すでに行われた変更を自動で戻すわけではない。

### `check`

- resource lifecycleの外側で、構成やインフラ全体の状態を確認する。
- planまたはapplyの終盤で評価し、失敗時は警告を出して処理を続ける。
- 必ず守る条件を止める手段として使わない。停止が必要ならvalidation、precondition、postcondition、policyなどを検討する。
- 継続的な確認に使う場合は、実行頻度、通知、対応手順も対応付ける。

### 選択表

| 目的 | 選択候補 | 失敗時の扱い |
|---|---|---|
| 書式の統一 | `fmt` | 差分または終了status |
| 構文と内部整合性 | `validate` | errorで停止 |
| 入力値の制限 | 変数の`validation` | errorで停止 |
| 処理前の必須前提 | `precondition` | errorで対象処理を停止 |
| 得られた状態の必須条件 | `postcondition` | errorで後続処理を停止 |
| 論理と生成予定内容の回帰確認 | `terraform test` | test failure |
| 処理を止めない継続確認 | `check` | warningで継続 |
| 組織共通ルールの強制 | SentinelまたはOPA | policy設定に従う |

## Policy as Code

SentinelまたはOPAは、Terraform runが組織共通のセキュリティ規則や運用基準へ合うかをplan情報から確認する。

- policy setの適用範囲、除外workspace、強制levelを確認する。
- ルールを品質シナリオと組織方針へ対応付ける。
- policy自体をtestし、例外、version、変更review、所有者を管理する。
- providerやクラウド固有の資源形式へ強く依存するルールは、共通資料から分離する。
- policy通過だけで、実際の動作、復旧、性能、利用時品質を満たすとは判断しない。

## 証拠としての扱い

| 段階 | Terraformで得られるもの | 追加で必要な確認 |
|---|---|---|
| 要件 | 変数説明、conditionのerror message、policyの意図 | 業務上の測定基準、担当、優先度 |
| 対策 | 暗号化、冗長化、backup、IAM、制限値の宣言 | 設計理由、対象障害、アプリ側の対策 |
| 検証 | `validate`、test assertion、policy結果 | 負荷、障害、復旧、連携、認可の試験 |
| 観測 | `check`や監視資源の宣言 | 実際のメトリクス、ログ、通知実績 |
| 対応 | alert routeや運用資源の宣言 | 当番、手順、訓練、復旧結果 |

報告では、`構成で確認`、`test結果で確認`、`実環境で確認`を区別する。実行していないコマンドを成功した証拠にしない。

## 安全規則

1. リポジトリと利用者の安全規則を最優先する。
2. `.env`、credentials、Terraformのstate、保存済みplan、Gitで除外されるファイルを、明確な必要性と許可なしに読まない。
3. `plan`、`apply`、applyを伴う`terraform test`、import、state操作を、読み取り調査の一部として実行しない。
4. 実資源、費用、外部接続、本番または機密性の高い環境へ影響する処理は、対象と戻し方を示して許可を得る。
5. `sensitive = true`はCLIやUIの表示を隠す機能であり、値はstateやplanに保存され得る。保存されないと判断しない。
6. ephemeral valueやwrite-only argumentはTerraformとproviderのversion制約を確認し、対応範囲だけで使う。
7. command出力、CI artifact、ログ、reviewコメントへ機密値を出さない。
8. 静的な設定確認と実環境の動作確認を分け、確認していない範囲を明示する。

## クラウド固有資料の分離

初版ではAWS、Azure、Google Cloudなどの固有ルールをこの資料へ加えない。利用要求が繰り返された場合は、次の形で1階層だけ追加する。

```text
references/
├── terraform-controls.md
└── terraform/
    ├── aws.md
    ├── azure.md
    └── google-cloud.md
```

追加時は`SKILL.md`または`terraform-controls.md`から読む条件を明示し、provider固有の資源名と一般原則を混ぜない。

## 参照情報

- [Terraform: Validate your configuration](https://developer.hashicorp.com/terraform/language/validate)
- [Terraform: `validate` command](https://developer.hashicorp.com/terraform/cli/commands/validate)
- [Terraform: Testing features](https://developer.hashicorp.com/terraform/cli/test)
- [Terraform: `check` block](https://developer.hashicorp.com/terraform/language/block/check)
- [HCP Terraform: Policy enforcement](https://developer.hashicorp.com/terraform/enterprise/workspaces/policy-enforcement)
- [Terraform: Manage sensitive data](https://developer.hashicorp.com/terraform/language/manage-sensitive-data)
