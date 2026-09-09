"""シェルを実行せず、引用符で分割された引数と危険な操作を検査する。"""

import fnmatch
import json
import os
from pathlib import Path
import re
import shlex
import sys


FIND_ACTIONS = {"-delete", "-exec", "-execdir", "-ok", "-okdir", "-fprint", "-fprint0", "-fprintf", "-fls"}
PUSH_FLAGS = {"--force", "--force-with-lease", "--force-if-includes", "--delete", "--mirror", "--prune"}
SENSITIVE_NAMES = (".env", ".env.local", ".git", "credentials", "credentials.json", "id_rsa", "id_ed25519", "private.key", "private.pem")


def has_dynamic_expansion(command):
    quote = None
    escaped = False
    for char in command:
        if escaped:
            escaped = False
            continue
        if char == "\\" and quote != "'":
            escaped = True
            continue
        if char in ("'", '"'):
            if quote is None:
                quote = char
            elif quote == char:
                quote = None
        elif quote != "'" and char in ("$", "`"):
            return True
        elif quote is None and char in "{}<>\n":
            return True
    return False


def sensitive_path(value, cwd):
    # オプションへ埋め込まれたパスも、解決後の名前で確認する。
    if value.startswith("-") and "=" in value:
        value = value.split("=", 1)[1]
    if not value or value.startswith("!"):
        return False
    parts = value.replace("\\", "/").split("/")
    for part in parts:
        name = part.lower()
        if name == ".git" or name == ".env" or name.startswith(".env."):
            return True
        if name == "credentials" or name.startswith("credentials.") or name.endswith("credentials.json"):
            return True
        if name.startswith(("id_rsa", "id_ed25519", "id_ecdsa", "id_dsa")):
            return True
        if name.endswith((".pem", ".key", ".p12", ".pfx", ".jks")):
            return True
        if any(char in name for char in "*?[") and any(fnmatch.fnmatchcase(item, name) for item in SENSITIVE_NAMES):
            return True
    # リンク先の内容は読まず、機密パスへの別名参照だけを確認する。
    if not any(char in value for char in "*?[]\n"):
        candidate = Path(os.path.expanduser(value))
        if not candidate.is_absolute():
            candidate = Path(cwd) / candidate
        try:
            resolved = candidate.resolve()
        except (OSError, RuntimeError, ValueError):
            return True
        if str(resolved) != str(candidate) and sensitive_parts(resolved.parts):
            return True
    return False


def sensitive_parts(parts):
    return any(
        part.lower() in (".git", ".env", "credentials")
        or part.lower().startswith((".env.", "credentials.", "id_rsa", "id_ed25519", "id_ecdsa", "id_dsa"))
        or part.lower().endswith(("credentials.json", ".pem", ".key", ".p12", ".pfx", ".jks"))
        for part in parts
    )


def inspect_segment(words, cwd):
    while words and re.match(r"^[A-Za-z_][A-Za-z_0-9]*=", words[0]):
        words = words[1:]
    if not words:
        return None
    program = os.path.basename(words[0])
    if program in ("env", "command"):
        tail = words[1:]
        while tail and (tail[0].startswith("-") or "=" in tail[0]):
            tail = tail[1:]
        return inspect_segment(tail, cwd)
    if program == "rg" and any(arg.split("=", 1)[0] in ("--pre", "--pre-glob") for arg in words[1:]):
        return "検索の外部前処理は任意のコマンドを起動するため許可しません。"
    if program == "find" and FIND_ACTIONS.intersection(words[1:]):
        return "findの削除、コマンド実行、ファイル出力は許可しません。対象を限定した個別の操作として確認してください。"
    if program == "git" and len(words) > 1:
        for arg in words[1:]:
            if arg.split("=", 1)[0] == "--output":
                return "Gitによるファイル出力は上書きを伴うため許可しません。"
            # 履歴やインデックスのパスは、作業ツリーのパスとは異なる接頭辞を持つ。
            if ":" in arg and sensitive_path(arg.rsplit(":", 1)[1], cwd):
                return "Gitの履歴またはインデックス内の機密パスへの参照は許可しません。"
        operation = words[1]
        if operation in ("-c", "--config-env", "-C", "--git-dir", "--work-tree") or operation.startswith(("--config-env=", "--git-dir=", "--work-tree=")):
            return "Gitの設定や作業場所を引数で差し替えず、確認済みの作業ディレクトリで実行してください。"
        if operation == "push":
            for arg in words[2:]:
                if arg.split("=", 1)[0] in PUSH_FLAGS or arg.startswith((":", "+")):
                    return "リモート参照の削除、強制更新、一括同期は許可しません。"
                if arg.startswith("-") and not arg.startswith("--") and any(char in arg[1:] for char in "fd"):
                    return "リモート参照の削除または強制更新は許可しません。"
        if operation == "checkout":
            return "checkoutは作業ファイルを上書きする場合があります。ブランチの切り替えにはswitchを使用してください。"
    return None


def check(command, cwd):
    # 展開を実行して検査すると、それ自体が副作用を起こすため静的な引数を要求する。
    if has_dynamic_expansion(command):
        return "展開、リダイレクト、引用外の改行を含むコマンドは拒否しました。具体的な引数を使い、書き込みには編集ツールを使用してください。"
    try:
        lexer = shlex.shlex(command.replace("\\\n", ""), posix=True, punctuation_chars=";&|()<>")
        lexer.whitespace_split = True
        words = list(lexer)
    except ValueError:
        return "引用符を解釈できないため、コマンドを拒否しました。"
    segment = []
    for word in words + [";"]:
        if word in (";", "&&", "||", "|", "&", "(", ")"):
            reason = inspect_segment(segment, cwd)
            if reason:
                return reason
            segment = []
        else:
            if sensitive_path(word, cwd):
                return "機密パスまたはGit内部への参照は許可しません。"
            segment.append(word)
    return None


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "--path":
        return 2 if sensitive_path(sys.argv[2], os.getcwd()) else 0
    try:
        data = json.load(sys.stdin)
        if not isinstance(data, dict):
            raise ValueError("object required")
        arguments = data.get("tool_input", data.get("toolInput", data.get("toolArgs")))
        if isinstance(arguments, str):
            arguments = json.loads(arguments)
        if not isinstance(arguments, dict):
            raise ValueError("arguments required")
        command = arguments.get("command")
        if not isinstance(command, str) or not command.strip():
            raise ValueError("command required")
        reason = check(command, data.get("cwd") or os.getcwd())
    except (ValueError, TypeError, OSError):
        reason = "hookの入力を確認できないため、コマンドを拒否しました。"
    if reason:
        print(reason)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
