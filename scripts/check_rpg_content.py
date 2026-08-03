"""Validate the RPG's original, data-driven story graphs."""

from __future__ import annotations

import json
import re
from collections import deque
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CONTENT_DIR = ROOT / "rpg" / "content"
KINDS = {"battle", "cultivation", "dialogue", "ending", "explore"}
FORBIDDEN_KEYS = {"reference_excerpt", "source_chapter", "source_text"}
REQUIRED_JOURNAL_IDS = {
    "abandoned_basket",
    "ferry_watermark",
    "spring_seam",
}
REQUIRED_JOURNAL_SIDE_IDS = {
    "basket_return",
    "basket_trail",
    "ferryman_record",
    "ferryman_repair",
}
ENEMY_NOTE_REFERENCE_CONTRACT = {
    "rock_armor_young": {
        "trace_action": "inspect_rock_spoor",
        "counter_action": "use_talisman",
        "counter_intent": "rock_rending_charge",
    },
    "spring_moss_shell": {
        "trace_action": "inspect_moss_spoor",
        "counter_action": "use_art",
        "counter_intent": "moss_absorb_tide",
    },
    "unbalanced_stone_puppet": {
        "trace_action": "inspect_puppet_spoor",
        "counter_action": "guard",
        "counter_intent": "puppet_unbalanced_swing",
    },
}
REQUIRED_ENEMY_NOTE_IDS = set(ENEMY_NOTE_REFERENCE_CONTRACT)
REQUIRED_ENEMY_NOTE_FIELDS = {
    "title",
    "trace",
    "cycle",
    "counter",
    "trace_action",
    "counter_action",
    "counter_intent",
}
ALLOWED_DIALOGUE_TOKENS = {
    "basket_reflection",
    "companion_reflection",
    "discovery_reflection",
    "ferryman_reflection",
    "harvest_reflection",
    "intel_reflection",
    "setback_reflection",
}
TOKEN_PATTERN = re.compile(r"\{([^{}]+)\}")
FIRST_BREATH_STORY_ID = "zhaohe_first_breath"
FIRST_BREATH_SPRING_ACTIONS = [
    {
        "id": "listen_to_spring",
        "label": "听泉辨脉",
        "possible_targets": ["spring"],
    },
    {
        "id": "warm_meridians",
        "label": "月芽温脉",
        "possible_targets": ["spring"],
    },
    {
        "id": "breakthrough",
        "label": "静坐引息",
        "possible_targets": ["complete"],
    },
]
FIRST_BREATH_MESSAGE_IDS = {
    "breakthrough",
    "first_breath_out_of_order",
    "meridians_warmed",
    "spring_listened",
}


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


def _validate_first_breath_contract(
    story: dict[str, Any],
    nodes: dict[str, Any],
    messages: dict[str, Any],
    source: str,
    failures: list[str],
) -> None:
    """Lock the shipped first-breath ritual without constraining other stories."""
    if story.get("story_id") != FIRST_BREATH_STORY_ID:
        return

    spring = nodes.get("spring")
    if not isinstance(spring, dict):
        failures.append(f"{source}.nodes.spring must define the first-breath ritual")
    else:
        actions = spring.get("actions")
        if not isinstance(actions, list):
            failures.append(
                f"{source}.nodes.spring.actions must contain exactly three first-breath actions"
            )
        else:
            if len(actions) != len(FIRST_BREATH_SPRING_ACTIONS):
                failures.append(
                    f"{source}.nodes.spring.actions must contain exactly three first-breath actions"
                )
            for index, expected in enumerate(FIRST_BREATH_SPRING_ACTIONS):
                if index >= len(actions) or not isinstance(actions[index], dict):
                    continue
                action = actions[index]
                for field, expected_value in expected.items():
                    if action.get(field) != expected_value:
                        failures.append(
                            f"{source}.nodes.spring.actions[{index}].{field} must be "
                            f"{expected_value!r}"
                        )

    missing_messages = sorted(FIRST_BREATH_MESSAGE_IDS - set(messages))
    if missing_messages:
        failures.append(
            f"{source}.messages is missing first-breath events: "
            + ", ".join(missing_messages)
        )


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
    journal_entries = _mapping(
        story.get("journal_entries"), f"{source}.journal_entries", failures
    )
    journal_side_entries = _mapping(
        story.get("journal_side_entries"),
        f"{source}.journal_side_entries",
        failures,
    )
    enemy_notes = _mapping(story.get("enemy_notes"), f"{source}.enemy_notes", failures)
    raw_transitions = story.get("transitions", {})
    transitions = _mapping(raw_transitions, f"{source}.transitions", failures)
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

    _validate_first_breath_contract(story, nodes, messages, source, failures)

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
                line_text = _text(line.get("text"), f"{line_label}.text", failures)
                unknown_tokens = sorted(
                    set(TOKEN_PATTERN.findall(line_text)) - ALLOWED_DIALOGUE_TOKENS
                )
                if unknown_tokens:
                    failures.append(
                        f"{line_label}.text has unknown tokens: {', '.join(unknown_tokens)}"
                    )

            _text(dialogue.get("choice_prompt"), f"{label}.choice_prompt", failures)

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
                event_id = _text(
                    choice.get("event_id"), f"{choice_label}.event_id", failures
                )
                if event_id and event_id not in messages:
                    failures.append(
                        f"{choice_label}.event_id points to missing message '{event_id}'"
                    )

    for transition_id, transition_text in transitions.items():
        _text(transition_id, f"{source}.transitions.id", failures)
        _text(transition_text, f"{source}.transitions.{transition_id}", failures)
        if transition_id not in nodes and transition_id not in messages:
            failures.append(
                f"{source}.transitions.{transition_id} must reference a node or message id"
            )

    journal_ids = set(journal_entries)
    if journal_ids != REQUIRED_JOURNAL_IDS:
        missing = sorted(REQUIRED_JOURNAL_IDS - journal_ids)
        unknown = sorted(journal_ids - REQUIRED_JOURNAL_IDS)
        if missing:
            failures.append(
                f"{source}.journal_entries is missing: {', '.join(missing)}"
            )
        if unknown:
            failures.append(
                f"{source}.journal_entries has unknown ids: {', '.join(unknown)}"
            )
    for entry_id, raw_entry in journal_entries.items():
        label = f"{source}.journal_entries.{entry_id}"
        _text(entry_id, f"{source}.journal_entries.id", failures)
        entry = _mapping(raw_entry, label, failures)
        _text(entry.get("title"), f"{label}.title", failures)
        _text(entry.get("summary"), f"{label}.summary", failures)

    side_entry_ids = set(journal_side_entries)
    if side_entry_ids != REQUIRED_JOURNAL_SIDE_IDS:
        missing = sorted(REQUIRED_JOURNAL_SIDE_IDS - side_entry_ids)
        unknown = sorted(side_entry_ids - REQUIRED_JOURNAL_SIDE_IDS)
        if missing:
            failures.append(
                f"{source}.journal_side_entries is missing: {', '.join(missing)}"
            )
        if unknown:
            failures.append(
                f"{source}.journal_side_entries has unknown ids: {', '.join(unknown)}"
            )
    for entry_id, raw_entry in journal_side_entries.items():
        label = f"{source}.journal_side_entries.{entry_id}"
        _text(entry_id, f"{source}.journal_side_entries.id", failures)
        entry = _mapping(raw_entry, label, failures)
        _text(entry.get("title"), f"{label}.title", failures)
        _text(entry.get("summary"), f"{label}.summary", failures)

    enemy_note_ids = set(enemy_notes)
    if enemy_note_ids != REQUIRED_ENEMY_NOTE_IDS:
        missing = sorted(REQUIRED_ENEMY_NOTE_IDS - enemy_note_ids)
        unknown = sorted(enemy_note_ids - REQUIRED_ENEMY_NOTE_IDS)
        if missing:
            failures.append(f"{source}.enemy_notes is missing: {', '.join(missing)}")
        if unknown:
            failures.append(
                f"{source}.enemy_notes has unknown enemy ids: {', '.join(unknown)}"
            )
    for enemy_id, raw_note in enemy_notes.items():
        label = f"{source}.enemy_notes.{enemy_id}"
        _text(enemy_id, f"{source}.enemy_notes.id", failures)
        note = _mapping(raw_note, label, failures)
        fields = set(note)
        missing_fields = sorted(REQUIRED_ENEMY_NOTE_FIELDS - fields)
        unknown_fields = sorted(fields - REQUIRED_ENEMY_NOTE_FIELDS)
        if missing_fields:
            failures.append(f"{label} is missing fields: {', '.join(missing_fields)}")
        if unknown_fields:
            failures.append(f"{label} has unknown fields: {', '.join(unknown_fields)}")
        _text(note.get("title"), f"{label}.title", failures)
        _text(note.get("trace"), f"{label}.trace", failures)
        _text(note.get("counter"), f"{label}.counter", failures)

        cycle = note.get("cycle")
        if not isinstance(cycle, list) or not cycle:
            failures.append(f"{label}.cycle must be a non-empty list")
            cycle = []
        for index, step in enumerate(cycle):
            _text(step, f"{label}.cycle[{index}]", failures)

        references = ENEMY_NOTE_REFERENCE_CONTRACT.get(enemy_id)
        for field in ("trace_action", "counter_action", "counter_intent"):
            reference = _text(note.get(field), f"{label}.{field}", failures)
            if not references or not reference:
                continue
            expected = references[field]
            if reference != expected:
                failures.append(
                    f"{label}.{field} must be '{expected}' for '{enemy_id}'"
                )
            if field != "counter_intent" and reference not in action_ids:
                failures.append(
                    f"{label}.{field} points to missing action '{reference}'"
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
