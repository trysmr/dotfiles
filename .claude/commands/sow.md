---
allowed-tools: Read, Write, Bash(git*), Bash(pwd), Bash(ls*), Bash(cat*), Bash(echo*)
description: Create a new Statement of Work (SOW) document for AI agents from template
---

## Context

This command creates an AI-optimized Statement of Work (SOW) document based on a predefined template.

**Usage**:
```
/sow [project_name] [file_name]
```

**Arguments**:
- `project_name` (optional): Name of the project (default: current directory name)
- `file_name` (optional): Output file name (default: SOW.md)

**Examples**:
```
/sow                              # Creates SOW.md
/sow "User Management Feature"    # Creates SOW.md with specified project name
/sow "API Improvement" "API_SOW.md" # Creates API_SOW.md
```

**Features**:
1. **Template copying**: Creates SOW file based on `~/.claude/templates/SOW_TEMPLATE.md`
2. **Auto project info**: Automatically retrieves Git info, directory name, etc.
3. **File existence check**: Prevents overwriting existing files
4. **Date auto-insertion**: Sets creation and update dates automatically

### Process arguments and set default values:

!`PROJECT_NAME="${1:-$(basename $(pwd))}"
FILE_NAME="${2:-SOW.md}"
echo "プロジェクト名: $PROJECT_NAME"
echo "ファイル名: $FILE_NAME"`

### Check for existing files:

!`if [ -f "$FILE_NAME" ]; then
    echo "⚠️  ファイル '$FILE_NAME' が既に存在します。"
    echo "上書きする場合は手動で削除してから再実行してください。"
    exit 1
fi`

### Verify template file exists:

!`TEMPLATE_PATH="$HOME/.claude/templates/SOW_TEMPLATE.md"
if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "❌ テンプレートファイルが見つかりません: $TEMPLATE_PATH"
    echo "SOWテンプレートが正しく配置されていることを確認してください。"
    exit 1
fi
echo "✅ テンプレートファイルを確認しました: $TEMPLATE_PATH"`

### Gather project information:

!`# 現在のディレクトリ
CURRENT_DIR=$(pwd)
echo "作業ディレクトリ: $CURRENT_DIR"

# Git情報の取得（エラーを無視）
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "不明")
GIT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "不明")
echo "Gitブランチ: $GIT_BRANCH"
echo "Gitリモート: $GIT_REMOTE"

# 日付情報
CURRENT_DATE=$(date +"%Y年%m月%d日")
echo "作成日: $CURRENT_DATE"`

## Your task

Create a SOW file in the current working directory based on the template.

1. Read the template file (`~/.claude/templates/SOW_TEMPLATE.md`)
2. Apply the following replacements:
   - `**テンプレート作成日**: 2025年7月12日` → `**作成日**: [CURRENT_DATE]`
   - `**最終更新**: 2025年7月12日` → `**最終更新**: [CURRENT_DATE]`
3. Add the following project information section at the top of the template:

```markdown
---

## プロジェクト情報

- **プロジェクト名**: [PROJECT_NAME]
- **作業ディレクトリ**: [CURRENT_DIR]
- **Gitブランチ**: [GIT_BRANCH]
- **Gitリモート**: [GIT_REMOTE]
- **作成日**: [CURRENT_DATE]

---
```

4. Create the SOW file with the specified filename in the current directory
5. Display a completion message with the created file path

**Important**: After creating the file, guide the user on next steps (how to fill in each section of the SOW specifically).