#!/usr/bin/env python3
# PreToolUse(Bash)フック: git commit と gh pr/issue コマンドの日本語を実行前に軽量チェックする。
# ニュアンス判定はせず、高精度な定型違反のみを検出する。違反を見つけたら exit 2 でブロックする。
# 検出対象:
#   1. 英数字と日本語の間の空白（例: "Rails 8 対応" -> "Rails 8対応"）
#   2. 漢語接頭辞と英字の混成（例: 非operator, 未push）
#   3. 既知の造語ブロックリスト（必要に応じて追記する）
#   4. 日本語での使用を禁止している語
#
# このファイルの内容は .claude/hooks と .codex/hooks で同一に保つ。どちらかを変更したら、もう一方にも同じ変更を反映すること。

import json
import re
import sys


def command_from_hook_input(data):
    tool_args = data.get("toolArgs")
    if isinstance(tool_args, str):
        try:
            parsed = json.loads(tool_args)
        except json.JSONDecodeError:
            parsed = {}
        command = parsed.get("command")
        if isinstance(command, str):
            return command

    for key in ("tool_input", "toolInput"):
        value = data.get(key)
        if isinstance(value, dict):
            command = value.get("command")
            if isinstance(command, str):
                return command

    return ""


def main():
    try:
        data = json.loads(sys.stdin.read())
    except json.JSONDecodeError:
        return 0

    command = command_from_hook_input(data)
    if not command:
        return 0

    is_commit = re.search(r"\bgit\s+commit\b", command)
    is_gh = re.search(r"\bgh\s+(pr|issue)\s+(create|edit|comment)\b", command)
    if not is_commit and not is_gh:
        return 0

    jp = "ぁ-んァ-ヶ一-龥々ー"
    if not re.search("[" + jp + "]", command):
        return 0

    space = "[ 　]"
    findings = []

    for match in re.finditer("([A-Za-z0-9])" + space + "([" + jp + "])", command):
        findings.append("英数字と日本語の間に空白: " + match.group(0))
    for match in re.finditer("([" + jp + "])" + space + "([A-Za-z0-9])", command):
        findings.append("日本語と英数字の間に空白: " + match.group(0))
    for match in re.finditer("[非未無不反脱][A-Za-z]", command):
        findings.append("漢語接頭辞と英字の混成: " + match.group(0))

    for term in ["未充足", "未永続化", "状態未反映", "次ステータス移行条件"]:
        if term in command:
            findings.append("造語の可能性: " + term)

    for term in ["契約", "述語"]:
        if term in command:
            findings.append("日本語での使用を禁止している語: " + term)

    if findings:
        unique_findings = list(dict.fromkeys(findings))
        sys.stderr.write(
            "コミット/PR本文の日本語に定型違反の疑いがあります。直してから再実行してください:\n- "
            + "\n- ".join(unique_findings)
        )
        return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
