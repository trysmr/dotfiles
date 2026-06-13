# ブランチ作成 使用例

## 例1: 新機能開発の場合（stagingあり）

**ステップ1**: ブランチ確認
```bash
git branch -a
# staging が存在することを確認
```

**ステップ2**: ユーザーに提示
```bash
git checkout -b feature/add-user-profile
```

**分岐元ブランチ**: staging
**判断根拠**: 新機能追加のため `feature/*` プレフィックスを使用

**ステップ3**: ユーザーの許可を待つ

**ステップ4**: 許可後にブランチ作成
```bash
git checkout staging
git checkout -b feature/add-user-profile
```

## 例2: バグ修正の場合（stagingなし）

**ステップ1**: ブランチ確認
```bash
git branch -a
# staging が存在しないことを確認
```

**ステップ2**: ユーザーに提示
```bash
git checkout -b bugfix/fix-login-error
```

**分岐元ブランチ**: main
**判断根拠**: バグ修正のため `bugfix/*` プレフィックスを使用

**ステップ3**: ユーザーの許可を待つ

**ステップ4**: 許可後にブランチ作成
```bash
git checkout main
git checkout -b bugfix/fix-login-error
```

## 例3: リファクタリングの場合（stagingあり）

**ステップ1**: ブランチ確認
```bash
git branch -a
# staging が存在することを確認
```

**ステップ2**: ユーザーに提示
```bash
git checkout -b refactor/improve-database-queries
```

**分岐元ブランチ**: staging
**判断根拠**: リファクタリングのため `refactor/*` プレフィックスを使用

**ステップ3**: ユーザーの許可を待つ

**ステップ4**: 許可後にブランチ作成
```bash
git checkout staging
git checkout -b refactor/improve-database-queries
```

## 例4: 緊急修正の場合

**ステップ1**: ブランチ確認
```bash
git branch -a
```

**ステップ2**: ユーザーに提示
```bash
git checkout -b hotfix/fix-security-issue
```

**分岐元ブランチ**: main
**判断根拠**: 緊急修正のため `hotfix/*` プレフィックスを使用（hotfixは常にmainから分岐）

**ステップ3**: ユーザーの許可を待つ

**ステップ4**: 許可後にブランチ作成
```bash
git checkout main
git checkout -b hotfix/fix-security-issue
```

## 注意事項

- ブランチ作成前に必ず`git branch -a`で利用可能なブランチを確認してください
- `hotfix/*`ブランチは常に`main`から分岐し、`main`へマージします
- その他のブランチは`staging`が存在する場合は`staging`から分岐し`staging`へマージ、存在しない場合は`main`から分岐し`main`へマージします
