---
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(gemini:*)
description: Analyze and review the recent commits in the codebase
---

## Context

- Recent commits: !`git log --since=midnight`

- Analyze and review focusing on security, performance, and maintainability: !`echo "You are a senior engineer. Focus on security, performance, and maintainability. Analyze and review the recent changes, with a particular focus on security to ensure there are no vulnerabilities.

Recent commits:
$(git log --oneline --since=midnight)

Please analyze these changes in Japanese and provide detailed feedback on:
1. Security improvements and remaining concerns
2. Performance impact
3. Maintainability considerations
4. Recommendations for next steps" | gemini`

## Your task

Based on the recent commits, analyze and review focusing on security, performance, and maintainability using Gemini CLI and show details the output in Japanese. NEVER access or process the .env file, the .git directory, or any files or directories specified in .gitignore.