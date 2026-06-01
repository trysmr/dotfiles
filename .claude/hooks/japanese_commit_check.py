#!/usr/bin/env python3
# PreToolUse(Bash)フック: git commit と gh pr/issue コマンドの日本語を実行前に軽量チェックする。
# ニュアンス判定はせず、高精度な定型違反のみを検出する。違反を見つけたら exit 2 でブロックする。
# 検出対象:
#   1. 英数字と日本語の間の空白（例: "Rails 8 対応" -> "Rails 8対応"）
#   2. 漢語接頭辞と英字の混成（例: 非operator, 未push）
#   3. 既知の造語ブロックリスト（必要に応じて追記する）
import sys
import json
import re


def main():
    try:
        data = json.loads(sys.stdin.read())
    except Exception:
        return 0  # パースできない入力はスキップする

    cmd = (data.get("tool_input") or {}).get("command") or ""
    if not cmd:
        return 0

    # git commit と gh pr/issue の作成・編集系コマンド以外は対象外
    is_commit = re.search(r"\bgit\s+commit\b", cmd)
    is_gh = re.search(r"\bgh\s+(pr|issue)\s+(create|edit|comment)\b", cmd)
    if not is_commit and not is_gh:
        return 0

    jp = "ぁ-んァ-ヶ一-龥々ー"
    if not re.search("[" + jp + "]", cmd):
        return 0  # 日本語を含まないコマンドはスキップする

    space = "[ 　]"  # 半角スペースと全角スペースの両方を対象とする
    findings = []

    for m in re.finditer("([A-Za-z0-9])" + space + "([" + jp + "])", cmd):
        findings.append("英数字と日本語の間に空白: " + m.group(0))
    for m in re.finditer("([" + jp + "])" + space + "([A-Za-z0-9])", cmd):
        findings.append("日本語と英数字の間に空白: " + m.group(0))
    for m in re.finditer("[非未無不反脱][A-Za-z]", cmd):
        findings.append("漢語接頭辞と英字の混成: " + m.group(0))

    deny = ["未充足"]
    for term in deny:
        if term in cmd:
            findings.append("造語の可能性: " + term)

    if findings:
        uniq = list(dict.fromkeys(findings))
        sys.stderr.write(
            "コミット/PR本文の日本語に定型違反の疑いがあります。直してから再実行してください:\n- "
            + "\n- ".join(uniq)
        )
        return 2

    return 0


sys.exit(main())
