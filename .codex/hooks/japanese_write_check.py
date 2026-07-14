#!/usr/bin/env python3
"""変更ファイルの日本語を決定的な規則で確認するPostToolUse hook。"""

import hashlib
import json
import re
import sys
import tempfile
import time
from pathlib import Path


JAPANESE_RE = re.compile(r"[\u3040-\u30ff\u3400-\u9fff々ー]")
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
PROHIBITED_JAPANESE_TERMS = ("契約", "述語")
DEDUPLICATION_PREFIX = "codex_japanese_write_check_"


def first_execution_for_tool(data: dict) -> bool:
    """複数の設定層から同じhookが起動しても、一度だけ処理する。"""
    keys = ("session_id", "turn_id", "tool_use_id")
    values = [data.get(key) for key in keys]
    if not all(isinstance(value, str) and value for value in values):
        return True

    temp_dir = Path(tempfile.gettempdir())
    now = time.time()
    for marker in temp_dir.glob(f"{DEDUPLICATION_PREFIX}*"):
        try:
            if now - marker.stat().st_mtime > 3600:
                marker.unlink()
        except OSError:
            continue

    digest = hashlib.sha256("\0".join(values).encode()).hexdigest()
    marker = temp_dir / f"{DEDUPLICATION_PREFIX}{digest}"
    try:
        marker.touch(exist_ok=False)
    except FileExistsError:
        return False
    except OSError:
        return True
    return True


def changed_paths(data: dict) -> list[str]:
    """apply_patchの入力から追加・更新対象だけを取り出す。"""
    tool_input = data.get("tool_input")
    command = tool_input.get("command") if isinstance(tool_input, dict) else ""
    if not isinstance(command, str):
        return []

    return re.findall(r"^\*\*\* (?:Add|Update) File: (.+)$", command, re.MULTILINE)


def safe_file(path_text: str, root: Path) -> Path | None:
    """機密パスと作業ディレクトリ外のパスを除外する。"""
    path = Path(path_text)
    if ".." in path.parts or ".git" in path.parts:
        return None

    candidate = path.resolve() if path.is_absolute() else (root / path).resolve()
    try:
        candidate.relative_to(root)
    except ValueError:
        return None

    name = candidate.name.lower()
    if name == ".env" or name.startswith(".env."):
        return None
    if name.endswith((".pem", ".key", ".p12", ".pfx", ".jks")):
        return None
    if name.startswith(("id_rsa", "id_ed25519", "id_ecdsa", "id_dsa")):
        return None
    if name == "credentials" or name.startswith("credentials.") or name.endswith("credentials.json"):
        return None

    if not candidate.is_file() or candidate.stat().st_size > 1_000_000:
        return None
    return candidate


def domain_terms(root: Path) -> set[str]:
    """プロジェクトが明示したドメイン用語を読み込む。"""
    terms_file = root / ".codex" / "japanese_domain_terms.txt"
    try:
        return {
            line.strip()
            for line in terms_file.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        }
    except (FileNotFoundError, UnicodeDecodeError):
        return set()


def findings_for(path: Path, display_path: str, allowed_terms: set[str]) -> list[str]:
    """既知の不自然な表現だけを、行番号付きで報告する。"""
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except UnicodeDecodeError:
        return []

    findings: list[str] = []
    for line_number, line in enumerate(lines, start=1):
        if not JAPANESE_RE.search(line):
            continue

        for original, suggestion in PREFIX_REWRITES.items():
            if original in allowed_terms:
                continue
            if original in line:
                findings.append(
                    f"{display_path}:{line_number}: 「{original}」 -> 「{suggestion}」 "
                    "（漢語接頭辞の造語の可能性）"
                )
        for original, suggestion in PARTICLE_REWRITES.items():
            if original in allowed_terms:
                continue
            if original in line:
                findings.append(
                    f"{display_path}:{line_number}: 「{original}」 -> 「{suggestion}」 "
                    "（助詞の省略の可能性）"
                )
        for term in PROHIBITED_JAPANESE_TERMS:
            if term in line:
                findings.append(
                    f"{display_path}:{line_number}: 「{term}」"
                    "（日本語での使用を禁止している語）"
                )
    return findings


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0
    if not isinstance(data, dict):
        return 0
    if not first_execution_for_tool(data):
        return 0

    root = Path.cwd().resolve()
    allowed_terms = domain_terms(root)
    findings: list[str] = []
    for path_text in changed_paths(data):
        candidate = safe_file(path_text, root)
        if candidate is not None:
            findings.extend(
                findings_for(candidate, str(candidate.relative_to(root)), allowed_terms)
            )

    if not findings:
        return 0

    message = "[japanese_write_check] 不自然な日本語の候補:\n- " + "\n- ".join(findings)
    json.dump(
        {
            "systemMessage": message,
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": message,
            },
        },
        sys.stdout,
        ensure_ascii=False,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
