import subprocess
import sys
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "check_japanese.py"


class CheckJapaneseCliTest(unittest.TestCase):
    def run_checker(self, text: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT)],
            input=text,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_accepts_natural_japanese(self) -> None:
        result = self.run_checker("Rails 8対応です。次のステータスを確認します。\n")

        self.assertEqual(0, result.returncode)
        self.assertEqual("定型違反なし\n", result.stdout)
        self.assertEqual("", result.stderr)

    def test_reports_each_mechanical_finding(self) -> None:
        result = self.run_checker(
            "Rails 8 対応です。次ステータスを確認します。A→Bへ進みます。\n"
        )

        self.assertEqual(1, result.returncode)
        self.assertIn("全角矢印", result.stdout)
        self.assertIn("英数字と日本語の間に空白", result.stdout)
        self.assertIn("助詞の省略の可能性", result.stdout)
        self.assertEqual("\n3件の定型違反候補\n", result.stderr)

    def test_reports_intentional_example_for_manual_review(self) -> None:
        result = self.run_checker("規則では「次ステータス」を避けます。\n")

        self.assertEqual(1, result.returncode)
        self.assertIn("助詞の省略の可能性", result.stdout)


if __name__ == "__main__":
    unittest.main()
