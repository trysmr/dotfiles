#!/usr/bin/env python3
"""日本語の定型違反候補をファイルまたは標準入力から検出する。"""
# このファイルは.claude/skills/japanese-check/scripts/と.agents/skills/japanese-check/scripts/で同一に保つ。どちらかを変更したらもう一方にも同じ変更を反映すること。
# 検出語彙は.claude/hooks/japanese_commit_check.pyと.codex/hooks/japanese_write_check.pyを照合先とする。

import re
import sys
from pathlib import Path


JAPANESE = "ぁ-んァ-ヶ一-龥々ー"
SPACE = "[ 　]"
PREFIX_REWRITES = {
    "未充足": "満たしていない",
    "非終端": "終端でない",
    "未永続化": "永続化していない",
    "状態未反映": "状態が反映されない",
}
PARTICLE_REWRITES = {
    "次エッジ": "次のエッジ",
    "次要素": "次の要素",
    "次ステータス": "次のステータス",
}
REWORD_SUGGESTIONS = {
    "高々": "「N以下」「最大N」",
    "真実の源泉": "「定義元」「〜で一元管理している」",
}
PROHIBITED_JAPANESE_TERMS = ("契約", "述語")


def findings_for_line(line: str) -> list[str]:
    """1行に含まれる定型違反候補を返す。"""
    findings: list[str] = []

    if "�" in line:
        findings.append("文字化け(U+FFFD)が混入")
    if "→" in line:
        findings.append("全角矢印「→」(ASCIIの->を使う)")
    if not re.search(f"[{JAPANESE}]", line):
        return findings

    for match in re.finditer(f"[A-Za-z0-9]{SPACE}[{JAPANESE}]", line):
        findings.append(f"英数字と日本語の間に空白: {match.group(0)}")
    for match in re.finditer(f"[{JAPANESE}]{SPACE}[A-Za-z0-9]", line):
        findings.append(f"日本語と英数字の間に空白: {match.group(0)}")
    for match in re.finditer("[非未無不反脱][A-Za-z]", line):
        findings.append(f"漢語接頭辞と英字の混成: {match.group(0)}")

    for original, suggestion in PREFIX_REWRITES.items():
        if original in line:
            findings.append(f"漢語接頭辞の造語の可能性: {original} -> {suggestion}")
    for original, suggestion in PARTICLE_REWRITES.items():
        if original in line:
            findings.append(f"助詞の省略の可能性: {original} -> {suggestion}")
    for original, suggestion in REWORD_SUGGESTIONS.items():
        if original in line:
            findings.append(f"言い換え推奨: {original} -> {suggestion}")
    for term in PROHIBITED_JAPANESE_TERMS:
        if term in line:
            findings.append(f"日本語での使用を禁止している語: {term}")

    return findings


def check_text(text: str, label: str) -> int:
    """テキストを行単位で確認し、候補数を返す。"""
    count = 0
    for line_number, line in enumerate(text.splitlines(), start=1):
        for finding in findings_for_line(line):
            print(f"{label}:{line_number}: {finding}")
            count += 1
    return count


def check_file(path_text: str) -> int:
    """UTF-8ファイルを読み、読み込み失敗も候補として数える。"""
    path = Path(path_text)
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError as error:
        print(f"{path_text}: 読み込み失敗({error})", file=sys.stderr)
        return 1
    return check_text(text, path_text)


def main() -> int:
    """候補があれば1、なければ0を返す。"""
    if len(sys.argv) > 1:
        total = sum(check_file(path) for path in sys.argv[1:])
    else:
        total = check_text(sys.stdin.read(), "stdin")

    if total == 0:
        print("定型違反なし")
        return 0
    print(f"\n{total}件の定型違反候補", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
