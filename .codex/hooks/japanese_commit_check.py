#!/usr/bin/env python3
"""PreToolUse hook for lightweight Japanese style checks in commit and PR text."""

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

    for term in ["未充足"]:
        if term in command:
            findings.append("造語の可能性: " + term)

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
