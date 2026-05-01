# コミット 使用例

## 例1: 既存ブランチでの追加コミット

**ステップ1**: 変更を確認
```bash
git branch
git status
git diff
```

**ステップ2**: ステージングと確認
```bash
git add docs/design-spec.md
git diff --cached
git diff --cached --name-only
```

**ステップ3**: ユーザーに提示
```bash
git commit -m "なぜ変更したかを1行で記述"
```

#### 変更が多い場合

```bash
git commit -m "$(cat <<'EOF'
なぜ変更したかを1行で記述

- 変更内容の詳細1
- 変更内容の詳細2
EOF
)"
```

**変更ファイル**:
- [ファイルパス]

**ステップ4**: ユーザーの許可を待つ

**ステップ5**: 許可後にコミット
```bash
git commit -m "検索UIの応答速度を改善するためページネーションを実装"
```

#### 変更が多い場合

```bash
git commit -m "$(cat <<'EOF'
ユーザー検索機能を追加

- 名前・メールアドレスでの検索に対応
- ページネーション実装
EOF
)"
```

## 例2: 新規ブランチでのコミット

**ステップ1**: ブランチ作成と変更確認
```bash
git checkout -b feature/add-user-search
git status
git diff
```

**ステップ2**: ステージングと確認
```bash
git add [ファイルパス]
git diff --cached --name-only
```

**ステップ3**: ユーザーに提示
```bash
git commit -m "なぜ変更したかを1行で記述"
```

#### 変更が多い場合

```bash
git commit -m "$(cat <<'EOF'
ユーザー検索機能を追加

- 名前・メールアドレスでの検索に対応
- ページネーション実装
EOF
)"
```

**変更ファイル**:
- [ファイルパス]

**ステップ4**: ユーザーの許可を待つ

**ステップ5**: 許可後にコミット
```bash
git commit -m "名前・メールアドレスでユーザーを絞り込めるよう検索機能を追加"

git push -u origin feature/add-user-search
```
