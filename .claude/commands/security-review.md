---
allowed-tools: Bash(git status:*), Bash(git log:*)
description: Analyze and review the recent commits in the codebase
argument-hint: [since-time]
---

## Context

- Recent commits: !`git log --since="${ARGUMENTS:-midnight}"`

- Analyze and review focusing on security, performance, and maintainability. You are a senior engineer. Focus on security, performance, and maintainability. Analyze and review the recent changes, with a particular focus on security to ensure there are no vulnerabilities.

Analyze these changes in Japanese and provide detailed feedback on:
1. Security improvements and remaining concerns
2. Performance impact
3. Maintainability considerations
4. Recommendations for next steps

NEVER access or process the .env file, the .git directory, or any files or directories specified in .gitignore.

## Your task

Based on the recent commits, analyze and review focusing on security, performance, and maintainability and show details the output in Japanese.
