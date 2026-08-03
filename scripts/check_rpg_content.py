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
    "patrol_boat_first",
    "patrol_herbs_first",
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
    "patrol_reflection",
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
LIFE_LANDMARK_ACTIONS = {
    "riverbank": [
        {
            "id": "inspect_boat_repair",
            "label": "查看补船木架",
            "possible_targets": ["riverbank"],
        },
        {
            "id": "inspect_drying_rack",
            "label": "查看晾晒竹架",
            "possible_targets": ["riverbank"],
        },
    ],
    "mountain_path": [
        {
            "id": "inspect_rain_shelter",
            "label": "查看避雨石棚",
            "possible_targets": ["mountain_path"],
        },
    ],
}
LIFE_LANDMARK_MESSAGES = {
    "boat_repair_inspected": (
        "补船木架上压着一块新桐木。旧船板被削成楔子，湿麻绳和桐油在晨风里慢慢收干；"
        "渡舟午后就能再下水。"
    ),
    "drying_rack_inspected": (
        "竹架把月芽叶、芦根和刚洗过的布分层晾开。木牌记着翻晒时辰，"
        "药香与河风各有自己的位置。"
    ),
    "rain_shelter_inspected": (
        "避雨石棚下留着干柴、引火绒和一只空水瓢。石壁刻着旧规："
        "取一束，后来补一束。"
    ),
}
PATROL_ACTION = {
    "id": "talk_to_patrol_runner",
    "label": "问问陶小满",
    "possible_targets": ["riverbank"],
}
PATROL_WORKSITE_ACTIONS = {
    "talk_at_boat_worksite": {
        "id": "talk_at_boat_worksite",
        "label": "问问船架这头",
        "possible_targets": ["riverbank"],
    },
    "talk_at_herbs_worksite": {
        "id": "talk_at_herbs_worksite",
        "label": "问问竹架这头",
        "possible_targets": ["riverbank"],
    },
}
PATROL_DIALOGUE = {
    "lines": [
        {
            "speaker": "陶小满",
            "text": (
                "借过。西头补船缺两枚木楔，东边药架又催着翻晒；"
                "这趟河风比人还会派活。"
            ),
        },
        {
            "speaker": "你",
            "text": "你每天都这样绕着渡口跑？",
        },
        {
            "speaker": "陶小满",
            "text": (
                "河涨之前送绳，日头偏西前翻药。路走熟了，"
                "哪块石头打滑，脚先替我记着。"
            ),
        },
        {
            "speaker": "陶小满",
            "text": "今天两头都不能落下，只是得定个先后。你替我看一眼风和日头。",
        },
    ],
    "choices": [
        {
            "id": "boat_first",
            "label": "木楔怕潮，先送船架。",
            "event_id": "patrol_boat_first",
        },
        {
            "id": "herbs_first",
            "label": "药叶怕闷，先翻竹架。",
            "event_id": "patrol_herbs_first",
        },
    ],
    "choice_prompt": "先后会改变陶小满下一段巡路与章节回声，但不改变战斗强度。",
}
PATROL_MESSAGES = {
    "patrol_boat_first": (
        "陶小满把木楔往怀里一拢，笑着沿中央石路折向补船架；"
        "送完还会回来照看药叶。"
    ),
    "patrol_herbs_first": (
        "陶小满抬头看了看日影，先往晾晒竹架快走两步；回来再把木楔送去补船。"
    ),
    "patrol_unavailable": "陶小满还没有开始巡路，或今天的先后已经定下。",
    "invalid_patrol_response": "这不是此刻可以作出的巡路安排。",
}
PATROL_WORKSITE_DIALOGUES = {
    "patrol_boat_priority": {
        "lines": [
            {
                "speaker": "陶小满",
                "text": "先送来的木楔已经压在篷布底下，河雾只在布角结了细珠。",
            },
            {
                "speaker": "陶小满",
                "text": "我每回折到西头都再按一遍，免得梁叔量好缺口却找不着料。",
            },
        ],
        "choices": [
            {
                "id": "secure_boat_cloth",
                "label": "替她压稳篷布边角。",
                "event_id": "patrol_boat_cloth_secured",
            },
            {
                "id": "check_boat_measure",
                "label": "陪她核对木楔尺痕。",
                "event_id": "patrol_boat_measure_checked",
            },
        ],
        "choice_prompt": "船架这头已经接上手。你愿意再帮她确认哪一处？",
    },
    "patrol_boat_followup": {
        "lines": [
            {
                "speaker": "陶小满",
                "text": "东边药叶先翻妥了，木楔也没让河雾咬着；油布一路都扎得紧。",
            },
            {
                "speaker": "陶小满",
                "text": "梁叔量好缺口，我把两枚楔子平码在尺边，谁接手都看得明白。",
            },
        ],
        "choices": [
            {
                "id": "secure_boat_cloth",
                "label": "替她压稳篷布边角。",
                "event_id": "patrol_boat_cloth_secured",
            },
            {
                "id": "check_boat_measure",
                "label": "陪她核对木楔尺痕。",
                "event_id": "patrol_boat_measure_checked",
            },
        ],
        "choice_prompt": "船架这头已经接上手。你愿意再帮她确认哪一处？",
    },
    "patrol_herbs_priority": {
        "lines": [
            {
                "speaker": "陶小满",
                "text": "先翻过的药叶已经散了背潮，竹架上的木牌也挪到下一格。",
            },
            {
                "speaker": "陶小满",
                "text": "我每回折到东头都摸一下叶边；不粘手，就能放心去看船架。",
            },
        ],
        "choices": [
            {
                "id": "steady_herb_tray",
                "label": "替她扶稳晾叶竹匾。",
                "event_id": "patrol_herbs_tray_steadied",
            },
            {
                "id": "check_herb_light",
                "label": "陪她看清叶背日影。",
                "event_id": "patrol_herbs_light_checked",
            },
        ],
        "choice_prompt": "竹架这头已经照看妥当。你愿意再帮她确认哪一处？",
    },
    "patrol_herbs_followup": {
        "lines": [
            {
                "speaker": "陶小满",
                "text": "西头先收好了木楔。日影偏了半格，药叶仍赶上了该翻的时辰。",
            },
            {
                "speaker": "陶小满",
                "text": "两头都接上才算完；渡口的活不是争第一，是别让下一双手空等。",
            },
        ],
        "choices": [
            {
                "id": "steady_herb_tray",
                "label": "替她扶稳晾叶竹匾。",
                "event_id": "patrol_herbs_tray_steadied",
            },
            {
                "id": "check_herb_light",
                "label": "陪她看清叶背日影。",
                "event_id": "patrol_herbs_light_checked",
            },
        ],
        "choice_prompt": "竹架这头已经照看妥当。你愿意再帮她确认哪一处？",
    },
}
PATROL_WORKSITE_MESSAGES = {
    "patrol_boat_cloth_secured": (
        "你按住篷布边角，陶小满重新收紧系绳；河风掠过木架，没有再钻进布缝。"
    ),
    "patrol_boat_measure_checked": (
        "你与陶小满顺着梁叔留下的尺痕核对木楔；两枚楔子仍平码在缺口旁。"
    ),
    "patrol_herbs_tray_steadied": (
        "你扶住被河风顶起的竹匾，陶小满将叶片理开，让潮气继续从缝间散去。"
    ),
    "patrol_herbs_light_checked": (
        "你与陶小满沿竹架看过一遍叶背日影；她把木牌挪正，下一次翻晒仍有时辰可循。"
    ),
    "patrol_worksite_unavailable": "此刻陶小满不在可一起搭手的工作点。",
    "invalid_patrol_work_response": "这不是此刻可作出的搭手方式。",
}
PATROL_JOURNAL_SIDE_ENTRIES = {
    "patrol_boat_first": {
        "title": "先往补船架的脚步",
        "summary": (
            "你请陶小满先护住怕潮的木楔。她沿中央石路折向西头，"
            "送完仍会回来照看药架。"
        ),
    },
    "patrol_herbs_first": {
        "title": "先往晾晒架的脚步",
        "summary": (
            "你请陶小满先赶在日头偏西前翻药。她转向东头竹架，"
            "回来再把木楔送去补船。"
        ),
    },
}
PATROL_REFLECTION_TOKEN = "{patrol_reflection}"


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


def _validate_life_landmark_contract(
    story: dict[str, Any],
    nodes: dict[str, Any],
    messages: dict[str, Any],
    source: str,
    failures: list[str],
) -> None:
    """Lock the three shipped repeatable observations to their authored maps."""
    if story.get("story_id") != FIRST_BREATH_STORY_ID:
        return

    for node_id, expected_actions in LIFE_LANDMARK_ACTIONS.items():
        node = nodes.get(node_id)
        if not isinstance(node, dict):
            continue
        actions = node.get("actions")
        if not isinstance(actions, list):
            continue
        actions_by_id = {
            action.get("id"): action
            for action in actions
            if isinstance(action, dict) and isinstance(action.get("id"), str)
        }
        for expected in expected_actions:
            action_id = expected["id"]
            action = actions_by_id.get(action_id)
            if action is None:
                failures.append(
                    f"{source}.nodes.{node_id}.actions is missing life-landmark "
                    f"action '{action_id}'"
                )
                continue
            for field in ("label", "possible_targets"):
                expected_value = expected[field]
                if action.get(field) != expected_value:
                    failures.append(
                        f"{source}.nodes.{node_id}.actions.{action_id}.{field} must be "
                        f"{expected_value!r}"
                    )

    missing_messages = sorted(set(LIFE_LANDMARK_MESSAGES) - set(messages))
    if missing_messages:
        failures.append(
            f"{source}.messages is missing life-landmark events: "
            + ", ".join(missing_messages)
        )
    for message_id, expected_text in LIFE_LANDMARK_MESSAGES.items():
        if message_id in messages and messages[message_id] != expected_text:
            failures.append(
                f"{source}.messages.{message_id} must be {expected_text!r}"
            )


def _validate_patrol_contract(
    story: dict[str, Any],
    nodes: dict[str, Any],
    dialogues: dict[str, Any],
    messages: dict[str, Any],
    journal_side_entries: dict[str, Any],
    source: str,
    failures: list[str],
) -> None:
    """Lock Tao Xiaoman's shipped route choice and its chapter reflection."""
    if story.get("story_id") != FIRST_BREATH_STORY_ID:
        return

    riverbank = nodes.get("riverbank")
    raw_actions = riverbank.get("actions") if isinstance(riverbank, dict) else []
    actions = raw_actions if isinstance(raw_actions, list) else []
    patrol_actions = [
        action
        for action in actions
        if isinstance(action, dict) and action.get("id") == PATROL_ACTION["id"]
    ]
    if not patrol_actions:
        failures.append(
            f"{source}.nodes.riverbank.actions is missing patrol action "
            f"'{PATROL_ACTION['id']}'"
        )
    elif patrol_actions != [PATROL_ACTION]:
        failures.append(
            f"{source}.nodes.riverbank.actions.{PATROL_ACTION['id']} must be "
            f"{PATROL_ACTION!r}"
        )

    actions_by_id = {
        action.get("id"): action
        for action in actions
        if isinstance(action, dict) and isinstance(action.get("id"), str)
    }
    for action_id, expected_action in PATROL_WORKSITE_ACTIONS.items():
        action = actions_by_id.get(action_id)
        if action is None:
            failures.append(
                f"{source}.nodes.riverbank.actions is missing patrol worksite "
                f"action '{action_id}'"
            )
        elif action != expected_action:
            failures.append(
                f"{source}.nodes.riverbank.actions.{action_id} must be "
                f"{expected_action!r}"
            )

    dialogue = dialogues.get("patrol_runner_briefing")
    dialogue = dialogue if isinstance(dialogue, dict) else {}
    for field, expected_value in PATROL_DIALOGUE.items():
        if dialogue.get(field) != expected_value:
            failures.append(
                f"{source}.dialogues.patrol_runner_briefing.{field} must match "
                "the exact patrol script"
            )

    for message_id, expected_text in PATROL_MESSAGES.items():
        if messages.get(message_id) != expected_text:
            failures.append(f"{source}.messages.{message_id} must be {expected_text!r}")

    for dialogue_id, expected_dialogue in PATROL_WORKSITE_DIALOGUES.items():
        if dialogues.get(dialogue_id) != expected_dialogue:
            failures.append(
                f"{source}.dialogues.{dialogue_id} must match the exact patrol "
                "worksite script"
            )

    for message_id, expected_text in PATROL_WORKSITE_MESSAGES.items():
        if messages.get(message_id) != expected_text:
            failures.append(f"{source}.messages.{message_id} must be {expected_text!r}")

    for entry_id, expected_entry in PATROL_JOURNAL_SIDE_ENTRIES.items():
        if journal_side_entries.get(entry_id) != expected_entry:
            failures.append(
                f"{source}.journal_side_entries.{entry_id} must be {expected_entry!r}"
            )

    epilogue = dialogues.get("chapter_epilogue")
    raw_lines = epilogue.get("lines") if isinstance(epilogue, dict) else []
    lines = raw_lines if isinstance(raw_lines, list) else []
    token_count = sum(
        line.get("text", "").count(PATROL_REFLECTION_TOKEN)
        for line in lines
        if isinstance(line, dict) and isinstance(line.get("text", ""), str)
    )
    if token_count != 1:
        failures.append(
            f"{source}.dialogues.chapter_epilogue.lines must contain exactly one "
            f"{PATROL_REFLECTION_TOKEN!r} token"
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
    _validate_life_landmark_contract(story, nodes, messages, source, failures)
    _validate_patrol_contract(
        story,
        nodes,
        dialogues,
        messages,
        journal_side_entries,
        source,
        failures,
    )

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
