"""シェルの展開を実行せず、分割済みの引数と書き込み先を検査する。"""

import fnmatch
import json
import os
from pathlib import Path
import re
import shutil
import sys


FIND_ACTIONS = {"-delete", "-exec", "-execdir", "-ok", "-okdir", "-fprint", "-fprint0", "-fprintf", "-fls"}
PUSH_FLAGS = {"--force", "--force-with-lease", "--force-if-includes", "--delete", "--mirror", "--prune"}
SENSITIVE_SAMPLES = (".git", ".git-credentials", ".env", ".env.local", "credentials", "credentials.json", "id_rsa", "id_ed25519", "private.key", "private.pem")
ENV_TEMPLATE_NAMES = {".env.example", ".env.sample", ".env.template"}


def sensitive_name(name):
    name = name.lower()
    if name in ENV_TEMPLATE_NAMES:
        return False
    return (
        name in (".git", ".git-credentials", ".env", "credentials")
        or name.startswith((".env.", "credentials.", "id_rsa", "id_ed25519", "id_ecdsa", "id_dsa"))
        or name.endswith(("credentials.json", ".pem", ".key", ".p12", ".pfx", ".jks"))
    )


def contains_sensitive_reference(value):
    names = re.findall(
        r"(?:^|[\s\"'/ (=:])((?:\.env(?:\.[\w-]+)*)|\.git|credentials(?:\.[\w-]+)*)(?=$|[\s\"'/ )=:])",
        value,
    )
    return any(sensitive_name(name) for name in names)


def matches_long_option(argument, names):
    option = argument.split("=", 1)[0]
    return option.startswith("--") and len(option) > 2 and any(name.startswith(option) for name in names)


def sensitive_path(value, cwd):
    for part in value.split("/"):
        if sensitive_name(part):
            return True
        if any(char in part for char in "*?[") and any(
            fnmatch.fnmatchcase(sample, part.lower()) for sample in SENSITIVE_SAMPLES
        ):
            return True
    if not any(char in value for char in "*?[]"):
        candidate = Path(os.path.expanduser(value))
        if not candidate.is_absolute():
            candidate = Path(cwd) / candidate
        # 内容は読まず、別名による機密パスへのアクセスだけを確認する。
        if any(sensitive_name(part) for part in candidate.resolve().parts):
            return True
    return False


def unwrap(words):
    while words:
        if re.match(r"^[A-Za-z_][A-Za-z_0-9]*=", words[0]):
            if (words[0].startswith("GIT_") and not words[0].startswith("GIT_OPTIONAL_LOCKS=")) or words[0].startswith(("RIPGREP_CONFIG_PATH=", "SSH_ASKPASS=", "PAGER=", "PATH=")):
                raise ValueError("検査対象の設定を環境変数で差し替える操作は許可しません。")
            words = words[1:]
            continue
        program = os.path.basename(words[0])
        if sensitive_path(words[0], os.getcwd()):
            raise ValueError("機密パス内のプログラムは実行しないでください。")
        if "/" in words[0] and program in ("git", "rg", "grep", "find", "cat", "ls"):
            trusted = shutil.which(program)
            if trusted is None or Path(words[0]).resolve() != Path(trusted).resolve():
                raise ValueError("検索やGitには通常のPATHで確認することができる実行ファイルを使ってください。")
        if program == "command":
            words = words[1:]
            while words and words[0].startswith("-"):
                words = words[1:]
        elif program == "env":
            words = words[1:]
            while words and words[0].startswith("-"):
                option = words.pop(0)
                if option in ("-u", "--unset") and words:
                    words.pop(0)
                elif option not in ("-i", "--ignore-environment", "--") and not option.startswith("--unset="):
                    raise ValueError("envの作業場所や実行形式を変更せず、個別に実行してください。")
        else:
            return program, words[1:]
    return "", []


def has_expansion(raw):
    quote = None
    escaped = False
    for index, char in enumerate(raw):
        if escaped:
            escaped = False
            continue
        if char == "\\" and quote != "'":
            escaped = True
        elif char in ("'", '"'):
            if quote is None:
                quote = char
            elif quote == char:
                quote = None
        elif quote != "'" and char in "$`":
            return True
        elif quote is None and char == "{":
            contents = raw[index + 1:].split("}", 1)[0]
            if "," in contents or ".." in contents:
                return True
    return False


def check_words(words, cwd, raw):
    program, args = unwrap(words)
    if program not in ("git", "rg", "grep", "find"):
        for arg in args:
            if sensitive_path(arg, cwd) or contains_sensitive_reference(arg):
                return "機密パスまたはGit内部へのアクセスは許可しません。"
    if program in ("rg", "grep", "find", "git"):
        operation = next((arg for arg in args if not arg.startswith("-")), "") if program == "git" else ""
        # commit本文中の埋め込みコマンドは既存のシェル側の検査で扱う。
        if operation != "commit" and has_expansion(raw):
            return "検索やGit操作には展開を含まない具体的な引数を指定してください。"
    if program == "rg" and any(arg.split("=", 1)[0] in ("--pre", "--pre-glob") for arg in args):
        return "検索の外部前処理は任意のコマンドを起動するため許可しません。"
    if program == "find" and FIND_ACTIONS.intersection(args):
        return "findの削除、コマンド実行、ファイル出力は個別の操作として確認してください。"
    if program == "git":
        if any(matches_long_option(arg, ("--pathspec-from-file",)) for arg in args):
            return "対象パスをファイルから間接指定せず、確認済みのパスを引数に列挙してください。"
        if any(arg.startswith(":(") for arg in args):
            return "Gitのpathspec magicではなく具体的なファイルパスを指定してください。"
        for arg in args:
            if not arg.startswith("-"):
                break
            if arg in ("-c", "-C") or arg.startswith(("-c", "-C", "--config-env", "--git-dir", "--work-tree", "--exec-path")):
                return "Gitの設定や作業場所を引数で差し替える操作は許可しません。"
        operation = next((arg for arg in args if not arg.startswith("-")), "")
        skip_value = False
        for arg in args:
            if skip_value:
                skip_value = False
                continue
            if operation == "commit" and arg in ("-m", "--message"):
                skip_value = True
                continue
            if operation == "commit" and arg.startswith(("--message=", "-m")):
                continue
            candidates = {arg, arg.split("=", 1)[-1], arg.rsplit(":", 1)[-1]}
            if any(sensitive_path(candidate, cwd) or contains_sensitive_reference(candidate) for candidate in candidates):
                return "Gitの引数で機密パスまたはGit内部を明示的に参照しないでください。"
        if operation in ("diff", "log", "show", "add"):
            if any(matches_long_option(arg, ("--ext-diff", "--textconv")) for arg in args):
                return "Gitの外部差分プログラムや変換処理の実行は許可しません。"
            if any(matches_long_option(arg, ("--output",)) for arg in args):
                return "Gitによるファイル出力は上書きを伴うため許可しません。"
        if operation == "push":
            for arg in args:
                if matches_long_option(arg, PUSH_FLAGS) or arg.startswith((":", "+")):
                    return "リモート参照の削除、強制更新、一括同期は許可しません。"
                if arg.startswith("-") and not arg.startswith("--") and any(char in arg[1:] for char in "fd"):
                    return "リモート参照の削除または強制更新は許可しません。"
        if operation == "commit":
            skip = False
            for arg in args[args.index("commit") + 1:]:
                if skip:
                    skip = False
                    continue
                if arg in ("-m", "--message"):
                    skip = True
                    continue
                if arg.startswith(("--message=", "-m")):
                    continue
                path = arg.split("=", 1)[-1] if arg.startswith(("--file=", "--template=")) else arg
                if path.startswith(("-F", "-t")) and len(path) > 2:
                    path = path[2:]
                if path.startswith(":(") or has_expansion(path) or sensitive_path(path, cwd):
                    return "コミット本文、テンプレート、対象に機密パスや動的なパスを指定しないでください。"
    if program in ("cat", "head", "tail", "less", "more", "ls", "rg", "grep", "find"):
        paths = []
        pattern_seen = program not in ("rg", "grep") or "--files" in args
        skip = False
        for index, arg in enumerate(args):
            if skip:
                skip = False
                continue
            # 検索式やglobの文字列をファイルパスと混同しない。
            if program in ("rg", "grep"):
                if arg in ("--hidden", "--no-ignore", "--no-ignore-vcs", "--no-ignore-dot", "-u", "-uu", "-uuu"):
                    return "通常の除外対象を含む検索は、確認済みのファイルを個別に指定してください。"
                option, _, value = arg.partition("=")
                if option in ("-g", "--glob", "--iglob", "--include", "--ignore-file"):
                    target = value or (args[index + 1] if index + 1 < len(args) else "")
                    if target and not target.startswith("!") and sensitive_path(target, cwd):
                        return "検索オプションによる機密パスへの参照は許可しません。"
                    skip = not bool(value)
                    continue
                if arg.startswith("-g") and len(arg) > 2:
                    if not arg[2:].startswith("!") and sensitive_path(arg[2:], cwd):
                        return "検索オプションによる機密パスへの参照は許可しません。"
                    continue
                if arg in ("-e", "--regexp"):
                    pattern_seen, skip = True, True
                    continue
                if arg.startswith(("--regexp=", "-e")):
                    pattern_seen = True
                    continue
                if arg in ("-g", "--glob", "--iglob", "-t", "--type", "-T", "--type-not", "-m", "--max-count", "-A", "-B", "-C"):
                    skip = True
                    continue
                if arg in ("-f", "--file") and index + 1 < len(args):
                    paths.append(args[index + 1])
                    pattern_seen, skip = True, True
                    continue
                if arg.startswith("--file="):
                    paths.append(arg.split("=", 1)[1])
                    pattern_seen = True
                    continue
            if arg.startswith("-"):
                continue
            if not pattern_seen:
                pattern_seen = True
                continue
            paths.append(arg)
        for path in paths:
            if any(char in path for char in "$`{}"):
                return "参照先を静的に確認するため、展開を含まない具体的なパスを指定してください。"
            if sensitive_path(path, cwd):
                return "機密パスまたはGit内部への参照は許可しません。"
    return None


def main():
    try:
        if sys.argv[1] == "--words":
            reason = check_words(sys.argv[4:], sys.argv[2], sys.argv[3])
        else:
            data = json.load(sys.stdin)
            arguments = data.get("tool_input", data.get("toolInput", data.get("toolArgs")))
            if isinstance(arguments, str):
                arguments = json.loads(arguments)
            path = arguments["file_path"]
            if not isinstance(path, str) or not path:
                raise ValueError("書き込み先がありません。")
            reason = "機密パスまたはGit内部へのアクセスは許可しません。" if sensitive_path(path, data.get("cwd") or os.getcwd()) else None
    except (ValueError, TypeError, KeyError, IndexError, AttributeError, OSError, RuntimeError):
        reason = "安全性の検査に失敗したため処理を拒否しました。"
    if reason:
        print(reason)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
