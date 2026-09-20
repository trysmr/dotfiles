"""コマンドを実行せず、Claude/Copilotの安全チェックの判定を検証する。"""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


HOOKS = Path(__file__).resolve().parent


class SecurityBoundariesTest(unittest.TestCase):
    def check_hook(self, hook, arguments, blocked, *, copilot=False, cwd=None):
        payload = {"tool_input": arguments, "cwd": str(cwd or HOOKS.parent.parent)}
        if copilot:
            payload = {"toolName": "bash", "toolArgs": json.dumps(arguments), "cwd": payload["cwd"]}
        result = subprocess.run(
            ["bash", str(HOOKS / hook)], input=json.dumps(payload),
            capture_output=True, text=True,
            env={**os.environ, "SETTINGS_FILE": str(HOOKS.parent / "settings.json")},
        )
        if copilot and blocked:
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertEqual("deny", json.loads(result.stdout)["permissionDecision"])
        else:
            self.assertEqual(2 if blocked else 0, result.returncode, result.stderr)

    def test_search_cannot_execute_or_write(self):
        for command in (
            "rg --pre=echo needle README.md", "rg --pre echo needle README.md",
            "command rg --p're'=echo needle README.md",
            "find . -delete", "find . -exec echo {} +", "find . -fprint /tmp/result",
            "ls && rg --pre=echo needle README.md",
            "RIPGREP_CONFIG_PATH=./config rg needle README.md",
            "rg --p{re,re-glob}=echo needle README.md",
        ):
            with self.subTest(command=command):
                self.check_hook("bash_safety_check.sh", {"command": command}, True)

    def test_git_cannot_write_or_override_settings(self):
        for command in (
            "git diff --output=/tmp/result", "git log --output /tmp/result",
            "git diff --out=/tmp/result", "git push origin --mir",
            "git -c core.pager=echo log", "git --no-pager diff --output=/tmp/result",
            "git push origin :main", "git push origin +main", "git push origin --mirror",
            "GIT_EXTERNAL_DIFF=/tmp/program git diff --ext-diff",
            "GIT_INDEX_FILE=.env git add README.md", "GIT_EDITOR=/tmp/program git commit",
            "PAGER=/tmp/program git --paginate log", "PATH=/tmp git log",
            "/tmp/rg needle README.md", "PATH=/tmp rg needle README.md",
            "git diff --textconv", "GIT_CONFIG_GLOBAL=./config git log",
            "git config --file=.git/config --get-regexp '.*'",
            "git config --blob=HEAD:.env --list",
            "git grep token HEAD -- .env",
            "git cat-file blob HEAD:.env",
            "git hash-object .env",
            "git grep token HEAD -- ':(literal).env'",
            "git grep token HEAD -- ':(glob).e*'",
            "git archive HEAD ':(literal).env'",
            "git ls-tree HEAD ':(glob).e*'",
        ):
            with self.subTest(command=command):
                self.check_hook("bash_safety_check.sh", {"command": command}, True)

    def test_sensitive_paths(self):
        for command in (
            "cat .e'nv'", "cat config/.env.local", "cat .git/config",
            "cat ~/.git-credentials", "cat ~/.config/git/credentials",
            "git show HEAD:.env", "git show :0:config/credentials.yml",
            "rg needle .env", "cat .en*",
            "rg --hidden --no-ignore -g '.env' needle .",
            "grep -R --include=.env needle .", "rg --ignore-file=.env needle .",
            "cat <.env", "cat<.env", "cat README.md >.git/config",
            "git show HEAD:.e{nv,x}", "git show HEAD:$(printf .env)",
            "git diff -- ':(top).env'", "git log -p -- ':(literal)credentials'",
            "rg -g .env needle .", "rg -g.env needle .",
            "cd /tmp && cat alias", "ln -s target alias && cat alias",
            "pushd /tmp && cat alias", "python3 -c 'pass' && cat alias",
            "git commit -F .env", "git commit --file=.git/config",
            "git add -f .env", "git commit -m msg -- .env",
            "git add --pathspec-from-file=.env", "git commit --pathspec-from-file=.git/config -m msg",
            ".git/hooks/pre-commit",
            "awk 1 .env", "cp .env /tmp/leak", "printf x > .env", "pwd > .git/config",
            'python3 -c \'print(open(".env").read())\'',
        ):
            with self.subTest(command=command):
                self.check_hook("bash_safety_check.sh", {"command": command}, True)

    def test_environment_templates_remain_readable(self):
        for command in (
            "cat .env.sample",
            "cat config/.env.example",
            "rg DATABASE_URL .env.template",
        ):
            with self.subTest(command=command):
                self.check_hook("bash_safety_check.sh", {"command": command}, False)

    def test_normal_search_remains_available(self):
        for command in (
            "rg '.*' README.md", "rg -n -e 'credentials' README.md",
            "rg 'foo$' README.md", "rg '[0-9]{4}' README.md",
            "rg --glob '*.rb' needle app", "find src -name '*.rb' -print",
        ):
            with self.subTest(command=command):
                self.check_hook("bash_safety_check.sh", {"command": command}, False)

    def test_write_paths_and_symlink_targets(self):
        for path in (".git/config", "src/.git/hooks/pre-commit", "config/.env.local"):
            with self.subTest(path=path):
                self.check_hook("write_safety_check.sh", {"file_path": path}, True)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "alias").symlink_to(root / ".env")
            self.check_hook("write_safety_check.sh", {"file_path": "alias"}, True, cwd=root)
            self.check_hook("bash_safety_check.sh", {"command": "cat alias"}, True, cwd=root)
            self.check_hook("write_safety_check.sh", {"file_path": "README.md"}, False, cwd=root)

    def test_copilot_decisions(self):
        self.check_hook("bash_safety_check.sh", {"command": "rg --pre=echo x README.md"}, True, copilot=True)
        self.check_hook("write_safety_check.sh", {"file_path": ".git/config"}, True, copilot=True)

    def test_invalid_json_is_rejected(self):
        for hook in ("bash_safety_check.sh", "write_safety_check.sh"):
            result = subprocess.run(["bash", str(HOOKS / hook)], input="{", text=True, capture_output=True)
            self.assertEqual(2, result.returncode)

    def test_invalid_bash_argument_shapes_are_rejected(self):
        payloads = (
            {"toolArgs": "{"},
            {"toolArgs": {"command": "git reset --hard"}},
            {"tool_input": {}},
            {"tool_input": {"command": ""}},
            {"tool_input": {"command": ["git", "status"]}},
        )
        for payload in payloads:
            with self.subTest(payload=payload):
                result = subprocess.run(
                    ["bash", str(HOOKS / "bash_safety_check.sh")],
                    input=json.dumps(payload), text=True, capture_output=True,
                    env={**os.environ, "SETTINGS_FILE": str(HOOKS.parent / "settings.json")},
                )
                self.assertEqual(2, result.returncode)

    def test_native_file_tools_have_the_same_path_guard(self):
        settings = json.loads((HOOKS.parent / "settings.json").read_text())
        entries = settings["hooks"]["PreToolUse"]
        for tool in ("Read", "Edit", "Write"):
            self.assertTrue(any(tool in entry["matcher"].split("|") and any(
                item.get("command", "").endswith("/write_safety_check.sh") for item in entry["hooks"]
            ) for entry in entries))
        self.check_hook("write_safety_check.sh", {"file_path": "config/master.key"}, True)

    def test_sandbox_configuration_separates_sensitive_and_template_paths(self):
        settings = json.loads((HOOKS.parent / "settings.json").read_text())
        sandbox = settings["sandbox"]
        self.assertTrue(sandbox["enabled"])
        self.assertTrue(sandbox["failIfUnavailable"])
        self.assertFalse(sandbox["autoAllowBashIfSandboxed"])
        self.assertFalse(sandbox["allowUnsandboxedCommands"])
        self.assertEqual("default", settings["permissions"]["defaultMode"])
        self.assertNotIn("allowUnixSockets", sandbox["network"])
        credential_files = {entry["path"]: entry["mode"] for entry in sandbox["credentials"]["files"]}
        credential_env = {entry["name"]: entry["mode"] for entry in sandbox["credentials"]["envVars"]}
        self.assertEqual("deny", credential_files["~/.ssh"])
        self.assertEqual("deny", credential_files["~/.aws"])
        self.assertEqual("deny", credential_files["~/.config/gh/hosts.yml"])
        self.assertEqual("deny", credential_files["~/.git-credentials"])
        self.assertEqual("deny", credential_files["~/.config/git/credentials"])
        self.assertEqual("deny", credential_env["GH_TOKEN"])
        self.assertEqual("deny", credential_env["CLAUDE_CODE_OAUTH_TOKEN"])
        self.assertEqual("deny", credential_env["AWS_SECRET_ACCESS_KEY"])
        self.assertEqual("deny", credential_env["OPENAI_API_KEY"])
        self.assertNotIn("tlsTerminate", sandbox["network"])
        self.assertNotIn("excludedCommands", sandbox)
        filesystem = sandbox["filesystem"]
        self.assertIn("/**/.env", filesystem["denyRead"])
        self.assertIn("/**/.env.*", filesystem["denyRead"])
        self.assertIn("/**/.env.sample", filesystem["allowRead"])
        self.assertNotIn("/**/.git", filesystem["denyRead"])
        self.assertNotIn("/**/.git", filesystem["denyWrite"])

        denied_reads = settings["permissions"]["deny"]
        self.assertNotIn("Bash(git:*)", denied_reads)
        self.assertIn("Bash(git status:*)", settings["permissions"]["allow"])
        self.assertIn("Bash(git commit:*)", settings["permissions"]["ask"])
        self.assertNotIn("Bash(git restore:*)", settings["permissions"]["allow"])
        self.assertNotIn("Bash(git rm:*)", settings["permissions"]["allow"])
        self.assertNotIn("Bash(git pull:*)", settings["permissions"]["allow"])
        self.assertNotIn("Read(**/.git/**)", denied_reads)
        self.assertNotIn("Read(.env.*)", denied_reads)
        self.assertNotIn("Read(**/.env.*)", denied_reads)

    def test_mermaid_render_uses_double_scale_without_opening_a_window(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            renderer = root / "mmdc"
            renderer.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
            renderer.chmod(0o755)
            result = subprocess.run(
                ["bash", str(HOOKS / "render_mermaid.sh")],
                input=json.dumps({"last_assistant_message": "```mermaid\ngraph TD\nA-->B\n```"}),
                text=True, capture_output=True,
                env={**os.environ, "PATH": str(root) + os.pathsep + os.environ["PATH"], "TMPDIR": str(root), "SSH_CONNECTION": "test"},
            )
            self.assertEqual(0, result.returncode)
            self.assertIn("-s\n2\n", result.stdout)
            sources = list((root / "claude-mermaid").glob("*.mmd"))
            self.assertEqual(1, len(sources))
            self.assertEqual("graph TD\nA-->B\n", sources[0].read_text())


if __name__ == "__main__":
    unittest.main()
