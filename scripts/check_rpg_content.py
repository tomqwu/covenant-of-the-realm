"""Validate the RPG's original, data-driven story graphs."""

from __future__ import annotations

import json
from collections import deque
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CONTENT_DIR = ROOT / "rpg" / "content"
KINDS = {"battle", "cultivation", "dialogue", "ending", "explore"}
FORBIDDEN_KEYS = {"reference_excerpt", "source_chapter", "source_text"}


def _mapping(value: Any, label: str, failures: list[str]) -> dict[str, Any]:
    if isinstance(value, dict):
        return value
    failures.append(f"{label} must be an object")
    return {}


def _text(value: Any, label: str, failures: list[str]) -> str:
    if isinstance(value, str) and value.strip():
        return value
    failures.append(f"{label} must be non-empty text")
    return ""


def _find_forbidden(value: Any, path: str, failures: list[str]) -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            if key in FORBIDDEN_KEYS:
                failures.append(f"{path}.{key} is forbidden in production content")
            _find_forbidden(child, f"{path}.{key}", failures)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            _find_forbidden(child, f"{path}[{index}]", failures)


def validate_story(data: Any, source: str = "story") -> list[str]:
    failures: list[str] = []
    story = _mapping(data, source, failures)
    if not story:
        return failures

    _find_forbidden(story, source, failures)
    if story.get("schema_version") != 1:
        failures.append(f"{source}.schema_version must be 1")
    _text(story.get("story_id"), f"{source}.story_id", failures)
    if story.get("origin") != "original":
        failures.append(f"{source}.origin must be 'original'")

    nodes = _mapping(story.get("nodes"), f"{source}.nodes", failures)
    messages = _mapping(story.get("messages"), f"{source}.messages", failures)
    dialogues = _mapping(story.get("dialogues"), f"{source}.dialogues", failures)
    start_node = _text(story.get("start_node"), f"{source}.start_node", failures)
    if start_node and start_node not in nodes:
        failures.append(f"{source}.start_node points to missing node '{start_node}'")

    action_ids: set[str] = set()
    endings: set[str] = set()
    edges: dict[str, set[str]] = {}
    for node_id, raw_node in nodes.items():
        label = f"{source}.nodes.{node_id}"
        _text(node_id, f"{label}.id", failures)
        node = _mapping(raw_node, label, failures)
        kind = node.get("kind")
        if kind not in KINDS:
            failures.append(f"{label}.kind must be one of {sorted(KINDS)}")
        if kind == "ending":
            endings.add(node_id)
        _text(node.get("title"), f"{label}.title", failures)
        _text(node.get("description"), f"{label}.description", failures)

        actions = node.get("actions")
        if not isinstance(actions, list) or not actions:
            failures.append(f"{label}.actions must be a non-empty list")
            actions = []
        edges[node_id] = set()
        for index, raw_action in enumerate(actions):
            action_label = f"{label}.actions[{index}]"
            action = _mapping(raw_action, action_label, failures)
            action_id = _text(action.get("id"), f"{action_label}.id", failures)
            if action_id in action_ids:
                failures.append(f"{action_label}.id duplicates '{action_id}'")
            elif action_id:
                action_ids.add(action_id)
            _text(action.get("label"), f"{action_label}.label", failures)
            targets = action.get("possible_targets")
            if not isinstance(targets, list) or not targets:
                failures.append(f"{action_label}.possible_targets must be a non-empty list")
                continue
            for target in targets:
                if not isinstance(target, str) or not target:
                    failures.append(f"{action_label}.possible_targets contains an invalid id")
                elif target not in nodes:
                    failures.append(f"{action_label} points to missing node '{target}'")
                else:
                    edges[node_id].add(target)

    if not endings:
        failures.append(f"{source} must contain at least one ending node")
    if not messages:
        failures.append(f"{source}.messages must not be empty")
    else:
        for message_id, message in messages.items():
            _text(message_id, f"{source}.messages.id", failures)
            _text(message, f"{source}.messages.{message_id}", failures)

    if not dialogues:
        failures.append(f"{source}.dialogues must not be empty")
    else:
        for dialogue_id, raw_dialogue in dialogues.items():
            label = f"{source}.dialogues.{dialogue_id}"
            _text(dialogue_id, f"{source}.dialogues.id", failures)
            dialogue = _mapping(raw_dialogue, label, failures)
            lines = dialogue.get("lines")
            if not isinstance(lines, list):
                failures.append(f"{label}.lines must be a non-empty list")
                lines = []
            elif not lines:
                failures.append(f"{label}.lines must be a non-empty list")
            for index, raw_line in enumerate(lines):
                line_label = f"{label}.lines[{index}]"
                line = _mapping(raw_line, line_label, failures)
                _text(line.get("speaker"), f"{line_label}.speaker", failures)
                _text(line.get("text"), f"{line_label}.text", failures)

            choices = dialogue.get("choices")
            if not isinstance(choices, list):
                failures.append(f"{label}.choices must contain exactly two responses")
                choices = []
            elif len(choices) != 2:
                failures.append(f"{label}.choices must contain exactly two responses")
            choice_ids: set[str] = set()
            for index, raw_choice in enumerate(choices):
                choice_label = f"{label}.choices[{index}]"
                choice = _mapping(raw_choice, choice_label, failures)
                choice_id = _text(choice.get("id"), f"{choice_label}.id", failures)
                if choice_id in choice_ids:
                    failures.append(f"{choice_label}.id duplicates '{choice_id}'")
                elif choice_id:
                    choice_ids.add(choice_id)
                _text(choice.get("label"), f"{choice_label}.label", failures)
                if choice_id and f"briefing_{choice_id}" not in messages:
                    failures.append(
                        f"{choice_label}.id has no matching message 'briefing_{choice_id}'"
                    )

    if start_node in nodes:
        reachable: set[str] = set()
        pending = deque([start_node])
        while pending:
            node_id = pending.popleft()
            if node_id in reachable:
                continue
            reachable.add(node_id)
            pending.extend(edges.get(node_id, set()) - reachable)
        unreachable = sorted(set(nodes) - reachable)
        if unreachable:
            failures.append(f"{source} has unreachable nodes: {', '.join(unreachable)}")
        if not endings.intersection(reachable):
            failures.append(f"{source} has no ending reachable from '{start_node}'")

    return failures


def main() -> None:
    files = sorted(CONTENT_DIR.glob("*.json"))
    if not files:
        raise SystemExit("No RPG story files found.")
    failures: list[str] = []
    for path in files:
        try:
            relative = str(path.relative_to(ROOT))
        except ValueError:
            relative = str(path)
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            failures.append(f"{relative}: invalid JSON at line {error.lineno}: {error.msg}")
            continue
        failures.extend(validate_story(data, relative))
    if failures:
        raise SystemExit("RPG content validation failed:\n" + "\n".join(failures))
    print(f"RPG content passed across {len(files)} original story graph(s).")


if __name__ == "__main__":
    main()
