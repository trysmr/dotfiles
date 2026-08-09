import sys
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from auto_name import (
    choose_label,
    plan_agent_names,
    should_manage_label,
    slugify_agent_name,
)


class SlugifyAgentNameTest(unittest.TestCase):
    def test_normalizes_a_directory_name_for_herdr(self):
        self.assertEqual("one-channel", slugify_agent_name("One Channel"))

    def test_prefixes_a_name_that_does_not_start_with_a_letter(self):
        self.assertEqual("agent-123-api", slugify_agent_name("123 API"))


class PlanAgentNamesTest(unittest.TestCase):
    def test_allocates_stable_names_for_agents_in_the_same_directory(self):
        agents = [
            {
                "agent": "codex",
                "foreground_cwd": "/Users/example/project",
                "pane_id": "w1:p1",
                "agent_session": {"source": "herdr:codex", "value": "session-a"},
            },
            {
                "agent": "codex",
                "foreground_cwd": "/Users/example/project",
                "pane_id": "w1:p2",
                "agent_session": {"source": "herdr:codex", "value": "session-b"},
            },
        ]

        assignments, state = plan_agent_names(agents, {})

        self.assertEqual(
            {"w1:p1": "project-1", "w1:p2": "project-2"},
            assignments,
        )
        self.assertEqual(
            {
                "herdr:codex:session-a": "project-1",
                "herdr:codex:session-b": "project-2",
            },
            state,
        )

    def test_reuses_the_previous_name_when_pane_id_changes(self):
        agents = [
            {
                "agent": "codex",
                "foreground_cwd": "/Users/example/project",
                "pane_id": "w2:p9",
                "agent_session": {"source": "herdr:codex", "value": "session-a"},
            },
        ]

        assignments, state = plan_agent_names(
            agents,
            {"herdr:codex:session-a": "project-2"},
        )

        self.assertEqual({"w2:p9": "project-2"}, assignments)
        self.assertEqual({"herdr:codex:session-a": "project-2"}, state)

    def test_preserves_a_manually_assigned_name(self):
        agents = [
            {
                "agent": "codex",
                "name": "reviewer",
                "foreground_cwd": "/Users/example/project",
                "pane_id": "w1:p1",
                "agent_session": {"source": "herdr:codex", "value": "session-a"},
            },
            {
                "agent": "codex",
                "foreground_cwd": "/Users/example/project",
                "pane_id": "w1:p2",
                "agent_session": {"source": "herdr:codex", "value": "session-b"},
            },
        ]

        assignments, state = plan_agent_names(agents, {})

        self.assertEqual({"w1:p2": "project-1"}, assignments)
        self.assertEqual(
            {"herdr:codex:session-b": "project-1"},
            state,
        )

    def test_does_not_take_over_a_name_changed_by_the_user(self):
        agents = [
            {
                "agent": "codex",
                "name": "reviewer",
                "foreground_cwd": "/Users/example/project",
                "pane_id": "w1:p1",
                "agent_session": {"source": "herdr:codex", "value": "session-a"},
            },
        ]

        assignments, state = plan_agent_names(
            agents,
            {"herdr:codex:session-a": "project-1"},
        )

        self.assertEqual({}, assignments)
        self.assertEqual({}, state)


class ChooseLabelTest(unittest.TestCase):
    def test_prefers_custom_agent_name(self):
        pane = {
            "name": "reviewer",
            "agent": "codex",
            "foreground_cwd": "/Users/example/project",
        }

        self.assertEqual("reviewer", choose_label(pane, ["codex"]))

    def test_combines_agent_and_directory(self):
        pane = {
            "agent": "codex",
            "foreground_cwd": "/Users/example/project",
        }

        self.assertEqual("codex:project", choose_label(pane, ["codex"]))

    def test_combines_foreground_process_and_directory(self):
        pane = {"foreground_cwd": "/Users/example/project"}

        self.assertEqual("npm:project", choose_label(pane, ["npm", "node"]))

    def test_uses_directory_for_an_idle_shell(self):
        pane = {"cwd": "/Users/example/project"}

        self.assertEqual("project", choose_label(pane, ["zsh"]))

    def test_uses_home_for_a_home_directory(self):
        pane = {"cwd": "/Users/example"}

        self.assertEqual("home", choose_label(pane, ["zsh"], home="/Users/example"))


class ShouldManageLabelTest(unittest.TestCase):
    def test_manages_an_unlabeled_pane(self):
        self.assertTrue(should_manage_label(None, None))

    def test_keeps_managing_its_previous_label(self):
        self.assertTrue(should_manage_label("codex:project", "codex:project"))

    def test_preserves_a_user_label(self):
        self.assertFalse(should_manage_label("api-server", "codex:project"))


if __name__ == "__main__":
    unittest.main()
