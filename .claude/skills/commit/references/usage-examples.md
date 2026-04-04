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
git add docs/contact_relation_spec.md
git diff --cached
git diff --cached --name-only
```

**ステップ3**: ユーザーに提示
```bash
git commit -m "なぜ変更したかを1行で記述"
```

**変更ファイル**:
- [ファイルパス]

**ステップ4**: ユーザーの許可を待つ

**ステップ5**: 許可後にコミット・プッシュ
```bash
git commit -m "検索UIの応答速度を改善するためページネーションを実装"

git push
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

**変更ファイル**:
- [ファイルパス]

**ステップ4**: ユーザーの許可を待つ

**ステップ5**: 許可後にコミット・プッシュ
```bash
git commit -m "名前・メールアドレスでユーザーを絞り込めるよう検索機能を追加"

git push -u origin feature/add-user-search
```
