"""コマンドを実行せず、公開されたhook入口の拒否判断を検証する。"""

import ast
import json
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
HOOK = ROOT / ".codex/hooks/command_safety_check.sh"
WRITE_HOOK = ROOT / ".codex/hooks/write_safety_check.sh"


def run_hook(command, *, event="PreToolUse", hook=HOOK, shape="tool_input"):
    arguments = {"command": command}
    payload = {"hook_event_name": event, "cwd": str(ROOT)}
    payload[shape] = json.dumps(arguments) if shape == "toolArgs" else arguments
    result = subprocess.run(
        ["bash", str(hook)], input=json.dumps(payload), text=True,
        capture_output=True, cwd=ROOT, timeout=10, check=False,
    )
    if result.returncode == 2:
        return "deny"
    if result.returncode != 0:
        raise AssertionError(f"hook failed: {result.returncode}")
    output = json.loads(result.stdout) if result.stdout else {}
    specific = output.get("hookSpecificOutput", {})
    return specific.get("permissionDecision", specific.get("decision", {}).get("behavior"))


class CommandBoundaryTest(unittest.TestCase):
    def test_search_external_preprocessors_are_denied(self):
        for command in (
            "rg --pre /bin/rm PATTERN target", "rg --pre=/bin/rm PATTERN target",
            "rg --pr''e /bin/rm PATTERN target", "rg --pre-glob '*.txt' PATTERN target",
        ):
            with self.subTest(command=command):
                self.assertEqual("deny", run_hook(command))

    def test_git_historical_sensitive_paths_are_denied(self):
        for command in (
            "git show HEAD:.env", "git show HEAD:.env.local",
            "git show HEAD:nested/.env", "git show :0:.env",
            "git diff HEAD:.env HEAD~1:.env", "git show HEAD:.g''it/config",
        ):
            with self.subTest(command=command):
                self.assertEqual("deny", run_hook(command))

    def test_git_output_files_are_denied(self):
        for command in (
            "git diff --output=.codex/hooks/command_safety_check.sh",
            "git show --output result.txt", "git log --out''put=result.txt",
        ):
            with self.subTest(command=command):
                self.assertEqual("deny", run_hook(command))

    def test_shell_expansions_and_output_writes_are_denied(self):
        for command in ('cat /dev/null > .codex/hooks/command_safety_check.sh',
                        'cat .{e,}nv', 'cat .{g,}it/config',
                        'cat README.md\nfind build -delete',
                        'git checkout HEAD app.rb'):
            with self.subTest(command=command):
                self.assertEqual('deny', run_hook(command))

    def test_write_aliases_and_case_variants_are_denied(self):
        with tempfile.TemporaryDirectory() as directory:
            alias = Path(directory) / 'ordinary.txt'
            alias.symlink_to(Path(directory) / '.env')
            for path in (str(alias), '.GIT/config'):
                patch = f'*** Begin Patch\n*** Add File: {path}\n+dummy\n*** End Patch'
                with self.subTest(path=path):
                    self.assertEqual('deny', run_hook(patch, hook=WRITE_HOOK))

    def test_find_actions_are_denied(self):
        for command in (
            "find build -delete", "find build -de''lete",
            "find build -exec touch marker {} +", "find build -execdir touch marker {} +",
            "find build -ok touch marker {} ;", "find build -okdir touch marker {} ;",
            "find build -fprint result.txt", "/usr/bin/find build -delete",
        ):
            with self.subTest(command=command):
                self.assertEqual("deny", run_hook(command))

    def test_remote_destructive_pushes_are_denied(self):
        for command in (
            "git push origin :refs/heads/topic", "git push origin +HEAD:main",
            "git push origin --mirror", "git push origin --prune",
            "git push origin --delete topic", "git push origin --force-with-lease",
            "git push origin --mi''rror", "/usr/bin/git push origin --mirror",
        ):
            with self.subTest(command=command):
                self.assertEqual("deny", run_hook(command))

    def test_sensitive_paths_cannot_hide_in_quotes_or_redirections(self):
        for command in (
            'cat .e""nv', 'cat .g""it/config', 'cat input > .e""nv',
            'cat input > nested/.g""it/config', 'cat .env.local',
            'cat ./nested/../.env', 'cat nested/credentials.json',
            'cat private.pem', 'cat .en?', 'cat .g*/config',
            'cat "$INPUT_PATH"', 'cat $(printf .env)',
        ):
            with self.subTest(command=command):
                self.assertEqual("deny", run_hook(command))

    def test_supported_input_shapes_and_permission_event(self):
        for shape in ("tool_input", "toolInput", "toolArgs"):
            for event in ("PreToolUse", "PermissionRequest"):
                with self.subTest(shape=shape, event=event):
                    self.assertEqual("deny", run_hook('cat .e""nv', shape=shape, event=event))

    def test_read_only_search_and_normal_push_reach_runtime_policy(self):
        for command in (
            "find app -name '*.rb' -print", "git status --short",
            "git push origin topic", "cat README.md", "rg --files",
            "rg 'find -delete' README.md", "git diff -- .codex/AGENTS.md",
            "git show HEAD:README.md", "git diff HEAD:app.rb HEAD~1:app.rb",
        ):
            with self.subTest(command=command):
                self.assertIsNone(run_hook(command))

    def test_move_destination_is_checked(self):
        patch = "*** Begin Patch\n*** Update File: safe.txt\n*** Move to: .env\n*** End Patch"
        self.assertEqual("deny", run_hook(patch, hook=WRITE_HOOK))


class RuleBoundaryTest(unittest.TestCase):
    def test_broad_mutating_commands_do_not_have_allow_rules(self):
        source = (ROOT / ".codex/rules/default.rules").read_text()
        rules = []
        for statement in ast.parse(source).body:
            call = statement.value
            self.assertIsInstance(call, ast.Call)
            self.assertEqual("prefix_rule", call.func.id)
            rules.append({item.arg: ast.literal_eval(item.value) for item in call.keywords})
        for command in (("find",), ("git", "push"), ("git", "checkout")):
            matching = []
            for rule in rules:
                pattern = rule["pattern"]
                if len(pattern) <= len(command) and all(
                    word in part if isinstance(part, list) else word == part
                    for word, part in zip(command, pattern)
                ):
                    matching.append(rule["decision"])
            with self.subTest(command=command):
                self.assertNotIn("allow", matching)
                self.assertIn("prompt", matching)


if __name__ == "__main__":
    unittest.main()
