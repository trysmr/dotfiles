#!/usr/bin/env python3

import fcntl
import json
import os
import re
import subprocess
import tempfile
from collections import namedtuple
from pathlib import Path


SHELL_NAMES = {"bash", "fish", "ksh", "nu", "sh", "tcsh", "zsh"}
AGENT_NAME_MAX_LENGTH = 32

# Plugin側で名前を管理するAgentと、その判定に使った前回の状態
ManagedAgent = namedtuple(
    "ManagedAgent",
    ["session_key", "agent", "current_name", "previous_name"],
)


def directory_name(path, home=None):
    if not path:
        return "shell"

    resolved_home = home or str(Path.home())
    if os.path.normpath(path) == os.path.normpath(resolved_home):
        return "home"

    return Path(path).name or "root"


def slugify_agent_name(value):
    name = re.sub(r"[^a-z0-9_-]+", "-", value.lower()).strip("-_")
    if not name:
        name = "agent"
    if not name[0].isalpha():
        name = f"agent-{name}"
    return name[:AGENT_NAME_MAX_LENGTH].rstrip("-_")


def agent_session_key(agent):
    session = agent.get("agent_session") or {}
    source = session.get("source")
    value = session.get("value")
    if source and value:
        return f"{source}:{value}"
    return agent["pane_id"]


def numbered_agent_name(base, index):
    suffix = f"-{index}"
    available_length = AGENT_NAME_MAX_LENGTH - len(suffix)
    return f"{base[:available_length].rstrip('-_')}{suffix}"


def plan_agent_names(agents, previous_names):
    used_names = set()
    managed_agents = []
    desired_by_session = {}

    for agent in agents:
        session_key = agent_session_key(agent)
        current_name = agent.get("name")
        previous_name = previous_names.get(session_key)
        if current_name and current_name != previous_name:
            used_names.add(current_name)
            continue
        managed_agents.append(
            ManagedAgent(session_key, agent, current_name, previous_name)
        )

    # Agentの列挙順で連番が入れ替わらないよう、session_key順で名前を決める
    ordered_agents = sorted(managed_agents, key=lambda managed: managed.session_key)

    for managed in ordered_agents:
        if managed.previous_name and managed.previous_name not in used_names:
            desired_by_session[managed.session_key] = managed.previous_name
            used_names.add(managed.previous_name)

    for managed in ordered_agents:
        if managed.session_key in desired_by_session:
            continue
        cwd_name = directory_name(
            managed.agent.get("foreground_cwd") or managed.agent.get("cwd"),
        )
        base = slugify_agent_name(cwd_name)
        index = 1
        desired_name = numbered_agent_name(base, index)
        while desired_name in used_names:
            index += 1
            desired_name = numbered_agent_name(base, index)
        desired_by_session[managed.session_key] = desired_name
        used_names.add(desired_name)

    assignments = {}
    next_state = {}
    for managed in managed_agents:
        desired_name = desired_by_session[managed.session_key]
        next_state[managed.session_key] = desired_name
        if managed.current_name != desired_name:
            assignments[managed.agent["pane_id"]] = desired_name

    return assignments, next_state


def choose_label(pane, process_names, home=None):
    cwd_name = directory_name(
        pane.get("foreground_cwd") or pane.get("cwd"),
        home=home,
    )
    if pane.get("name"):
        return pane["name"]
    if pane.get("agent"):
        return f"{pane['agent']}:{cwd_name}"

    process_name = next(
        (name for name in process_names if name and name not in SHELL_NAMES),
        None,
    )
    if process_name:
        return f"{process_name}:{cwd_name}"
    return cwd_name


def should_manage_label(current_label, previous_label):
    return current_label is None or current_label == previous_label


def run_json(herdr, *args):
    result = subprocess.run(
        [herdr, *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


def load_state(path):
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def save_state(path, state):
    path.parent.mkdir(parents=True, exist_ok=True)
    file_descriptor, temporary_path = tempfile.mkstemp(
        dir=path.parent,
        prefix="labels-",
        suffix=".json",
    )
    try:
        with os.fdopen(file_descriptor, "w", encoding="utf-8") as file:
            json.dump(state, file, ensure_ascii=False, sort_keys=True)
            file.write("\n")
        os.replace(temporary_path, path)
    finally:
        if os.path.exists(temporary_path):
            os.unlink(temporary_path)


def process_names(herdr, pane_id):
    response = run_json(herdr, "pane", "process-info", "--pane", pane_id)
    processes = response["result"]["process_info"].get("foreground_processes", [])
    return [process.get("name") for process in processes]


def sync_agent_names(herdr, state_path):
    previous_names = load_state(state_path)
    agents = run_json(herdr, "agent", "list")["result"]["agents"]
    assignments, next_names = plan_agent_names(agents, previous_names)
    for pane_id, name in assignments.items():
        run_json(herdr, "agent", "rename", pane_id, name)
    save_state(state_path, next_names)

    # リネームしたのはPlugin自身なので、agent listを取り直さず手元の情報へ反映する
    for agent in agents:
        if agent["pane_id"] in assignments:
            agent["name"] = assignments[agent["pane_id"]]

    return {agent["pane_id"]: agent for agent in agents}


def sync_pane_labels(herdr, state_path, panes, agents_by_pane):
    state = load_state(state_path)
    live_pane_ids = {pane["pane_id"] for pane in panes}

    for pane_id in set(state) - live_pane_ids:
        del state[pane_id]

    for pane in panes:
        pane_id = pane["pane_id"]
        current_label = pane.get("label")
        previous_label = state.get(pane_id)
        if not should_manage_label(current_label, previous_label):
            state.pop(pane_id, None)
            continue

        pane.update(agents_by_pane.get(pane_id, {}))
        try:
            names = process_names(herdr, pane_id)
        except subprocess.CalledProcessError:
            continue
        desired_label = choose_label(pane, names)
        if current_label != desired_label:
            run_json(herdr, "pane", "rename", pane_id, desired_label)
        state[pane_id] = desired_label

    save_state(state_path, state)


def main():
    herdr = os.environ.get("HERDR_BIN_PATH", "herdr")
    state_directory = Path(os.environ["HERDR_PLUGIN_STATE_DIR"])
    lock_path = state_directory / "labels.lock"
    state_directory.mkdir(parents=True, exist_ok=True)

    with lock_path.open("w", encoding="utf-8") as lock_file:
        fcntl.flock(lock_file, fcntl.LOCK_EX)
        agents_by_pane = sync_agent_names(herdr, state_directory / "agent-names.json")
        panes = run_json(herdr, "pane", "list")["result"]["panes"]
        sync_pane_labels(
            herdr,
            state_directory / "labels.json",
            panes,
            agents_by_pane,
        )


if __name__ == "__main__":
    main()
