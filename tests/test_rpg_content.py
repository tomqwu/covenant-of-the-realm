from __future__ import annotations

import json
from copy import deepcopy
from pathlib import Path

from scripts.check_rpg_content import ROOT, validate_story


def story() -> dict:
    return json.loads((ROOT / "rpg/content/prologue.json").read_text(encoding="utf-8"))


def test_repository_story_is_valid() -> None:
    assert validate_story(story()) == []


def test_first_breath_story_locks_spatial_ritual_contract() -> None:
    data = story()
    data["nodes"]["spring"]["actions"][0]["id"] = "skip_listening"
    data["nodes"]["spring"]["actions"][1]["label"] = "强行冲脉"
    data["nodes"]["spring"]["actions"][2]["possible_targets"] = ["spring"]
    data["messages"].pop("first_breath_out_of_order")
    failures = validate_story(data)
    assert (
        "story.nodes.spring.actions[0].id must be 'listen_to_spring'" in failures
    )
    assert "story.nodes.spring.actions[1].label must be '月芽温脉'" in failures
    assert (
        "story.nodes.spring.actions[2].possible_targets must be ['complete']"
        in failures
    )
    assert (
        "story.messages is missing first-breath events: first_breath_out_of_order"
        in failures
    )

    data = story()
    data["nodes"]["spring"]["actions"].append(
        {"id": "extra_breath", "label": "多余步骤", "possible_targets": ["spring"]}
    )
    assert (
        "story.nodes.spring.actions must contain exactly three first-breath actions"
        in validate_story(data)
    )


def test_first_breath_contract_does_not_constrain_other_story_ids() -> None:
    data = story()
    data["story_id"] = "another_original_story"
    data["nodes"]["spring"]["actions"][0]["label"] = "另一故事的行动"
    data["messages"].pop("first_breath_out_of_order")
    data["nodes"]["riverbank"]["actions"] = [
        action
        for action in data["nodes"]["riverbank"]["actions"]
        if action["id"] != "talk_to_patrol_runner"
    ]
    data["dialogues"].pop("patrol_runner_briefing")
    for message_id in (
        "invalid_patrol_response",
        "patrol_boat_first",
        "patrol_herbs_first",
        "patrol_unavailable",
    ):
        data["messages"].pop(message_id)
    epilogue_line = data["dialogues"]["chapter_epilogue"]["lines"][-1]
    epilogue_line["text"] = epilogue_line["text"].replace("{patrol_reflection}。", "")
    data["journal_side_entries"]["patrol_boat_first"]["title"] = "另一故事的选择"
    assert validate_story(data) == []


def test_first_breath_contract_rejects_malformed_spring_shapes() -> None:
    data = story()
    data["nodes"]["spring"] = []
    assert (
        "story.nodes.spring must define the first-breath ritual"
        in validate_story(data)
    )

    data = story()
    data["nodes"]["spring"]["actions"] = {}
    assert (
        "story.nodes.spring.actions must contain exactly three first-breath actions"
        in validate_story(data)
    )

    data = story()
    data["nodes"]["spring"]["actions"][1] = []
    assert "story.nodes.spring.actions[1] must be an object" in validate_story(data)


def test_first_breath_story_locks_repeatable_life_landmark_contract() -> None:
    data = story()
    data["nodes"]["riverbank"]["actions"] = [
        action
        for action in data["nodes"]["riverbank"]["actions"]
        if action["id"] != "inspect_boat_repair"
    ]
    drying_rack = next(
        action
        for action in data["nodes"]["riverbank"]["actions"]
        if action["id"] == "inspect_drying_rack"
    )
    drying_rack["label"] = "查看别处"
    rain_shelter = next(
        action
        for action in data["nodes"]["mountain_path"]["actions"]
        if action["id"] == "inspect_rain_shelter"
    )
    rain_shelter["possible_targets"] = ["riverbank"]
    data["messages"].pop("rain_shelter_inspected")
    data["messages"]["boat_repair_inspected"] = "一段被意外改写的文字。"

    failures = validate_story(data)
    assert (
        "story.nodes.riverbank.actions is missing life-landmark action "
        "'inspect_boat_repair'" in failures
    )
    assert (
        "story.nodes.riverbank.actions.inspect_drying_rack.label must be "
        "'查看晾晒竹架'" in failures
    )
    assert (
        "story.nodes.mountain_path.actions.inspect_rain_shelter.possible_targets "
        "must be ['mountain_path']" in failures
    )
    assert (
        "story.messages is missing life-landmark events: rain_shelter_inspected"
        in failures
    )
    assert any(
        failure.startswith("story.messages.boat_repair_inspected must be ")
        for failure in failures
    )

    data = story()
    data["nodes"]["riverbank"] = []
    assert "story.nodes.riverbank must be an object" in validate_story(data)

    data = story()
    data["nodes"]["riverbank"]["actions"] = {}
    assert (
        "story.nodes.riverbank.actions must be a non-empty list"
        in validate_story(data)
    )


def test_first_breath_story_locks_patrol_runner_contract() -> None:
    data = story()
    patrol_action = next(
        action
        for action in data["nodes"]["riverbank"]["actions"]
        if action["id"] == "talk_to_patrol_runner"
    )
    patrol_action["possible_targets"] = ["mountain_path"]
    dialogue = data["dialogues"]["patrol_runner_briefing"]
    dialogue["lines"][0]["text"] = "一段被意外改写的巡路开场。"
    dialogue["choices"][1]["event_id"] = "patrol_boat_first"
    dialogue["choice_prompt"] = "随意选择。"
    data["messages"].pop("patrol_unavailable")
    data["messages"]["patrol_boat_first"] = "一段被意外改写的巡路结果。"
    data["journal_side_entries"]["patrol_boat_first"]["title"] = "被改写的木楔路线"
    data["journal_side_entries"]["patrol_herbs_first"]["summary"] = "被改写的翻药路线。"
    epilogue_line = data["dialogues"]["chapter_epilogue"]["lines"][-1]
    epilogue_line["text"] = epilogue_line["text"].replace("{patrol_reflection}。", "")

    failures = validate_story(data)

    assert any(
        failure.startswith(
            "story.nodes.riverbank.actions.talk_to_patrol_runner must be "
        )
        for failure in failures
    )
    assert (
        "story.dialogues.patrol_runner_briefing.lines must match the exact patrol script"
        in failures
    )
    assert (
        "story.dialogues.patrol_runner_briefing.choices must match the exact patrol script"
        in failures
    )
    assert (
        "story.dialogues.patrol_runner_briefing.choice_prompt must match the exact patrol script"
        in failures
    )
    assert any(
        failure.startswith("story.messages.patrol_boat_first must be ")
        for failure in failures
    )
    assert any(
        failure.startswith("story.messages.patrol_unavailable must be ")
        for failure in failures
    )
    assert any(
        failure.startswith("story.journal_side_entries.patrol_boat_first must be ")
        for failure in failures
    )
    assert any(
        failure.startswith("story.journal_side_entries.patrol_herbs_first must be ")
        for failure in failures
    )
    assert (
        "story.dialogues.chapter_epilogue.lines must contain exactly one "
        "'{patrol_reflection}' token" in failures
    )

    data = story()
    data["nodes"]["riverbank"]["actions"] = [
        action
        for action in data["nodes"]["riverbank"]["actions"]
        if action["id"] != "talk_to_patrol_runner"
    ]
    assert (
        "story.nodes.riverbank.actions is missing patrol action 'talk_to_patrol_runner'"
        in validate_story(data)
    )


def test_first_breath_story_locks_patrol_worksite_reactions() -> None:
    data = story()
    boat_action = next(
        action
        for action in data["nodes"]["riverbank"]["actions"]
        if action["id"] == "talk_at_boat_worksite"
    )
    boat_action["label"] = "领取船架奖励"
    data["nodes"]["riverbank"]["actions"] = [
        action
        for action in data["nodes"]["riverbank"]["actions"]
        if action["id"] != "talk_at_herbs_worksite"
    ]
    data["dialogues"]["patrol_boat_priority"]["lines"][0]["text"] = (
        "一段被意外改写的船架回声。"
    )
    data["dialogues"]["patrol_boat_followup"]["choices"][1]["event_id"] = (
        "patrol_boat_cloth_secured"
    )
    data["dialogues"]["patrol_herbs_priority"]["choice_prompt"] = "领取关系奖励。"
    data["dialogues"].pop("patrol_herbs_followup")
    data["messages"]["patrol_boat_cloth_secured"] = "你获得一件奖励。"
    data["messages"].pop("patrol_herbs_light_checked")
    data["messages"]["patrol_worksite_unavailable"] = "这里可以随时领取奖励。"
    data["messages"].pop("invalid_patrol_work_response")

    failures = validate_story(data)

    assert any(
        failure.startswith(
            "story.nodes.riverbank.actions.talk_at_boat_worksite must be "
        )
        for failure in failures
    )
    assert (
        "story.nodes.riverbank.actions is missing patrol worksite action "
        "'talk_at_herbs_worksite'" in failures
    )
    for dialogue_id in (
        "patrol_boat_priority",
        "patrol_boat_followup",
        "patrol_herbs_priority",
        "patrol_herbs_followup",
    ):
        assert (
            f"story.dialogues.{dialogue_id} must match the exact patrol worksite script"
            in failures
        )
    assert any(
        failure.startswith("story.messages.patrol_boat_cloth_secured must be ")
        for failure in failures
    )
    assert any(
        failure.startswith("story.messages.patrol_herbs_light_checked must be ")
        for failure in failures
    )
    assert any(
        failure.startswith("story.messages.patrol_worksite_unavailable must be ")
        for failure in failures
    )
    assert any(
        failure.startswith("story.messages.invalid_patrol_work_response must be ")
        for failure in failures
    )


def test_patrol_worksite_reactions_do_not_add_journal_results() -> None:
    data = story()
    worksite_events = {
        choice["event_id"]
        for dialogue_id in (
            "patrol_boat_priority",
            "patrol_boat_followup",
            "patrol_herbs_priority",
            "patrol_herbs_followup",
        )
        for choice in data["dialogues"][dialogue_id]["choices"]
    }

    assert worksite_events == {
        "patrol_boat_cloth_secured",
        "patrol_boat_measure_checked",
        "patrol_herbs_tray_steadied",
        "patrol_herbs_light_checked",
    }
    assert worksite_events.isdisjoint(data["journal_entries"])
    assert worksite_events.isdisjoint(data["journal_side_entries"])


def test_first_breath_story_locks_path_keeper_action_and_echoes() -> None:
    data = story()
    path_keeper_action = next(
        action
        for action in data["nodes"]["mountain_path"]["actions"]
        if action["id"] == "talk_to_path_keeper"
    )
    path_keeper_action["label"] = "向岑苇领取奖励"
    data["messages"]["path_keeper_route_checked"] = "一段被意外改写的路签回声。"
    data["messages"].pop("path_keeper_after_setback")

    failures = validate_story(data)

    assert any(
        failure.startswith(
            "story.nodes.mountain_path.actions.talk_to_path_keeper must be "
        )
        for failure in failures
    )
    assert any(
        failure.startswith("story.messages.path_keeper_route_checked must be ")
        for failure in failures
    )
    assert any(
        failure.startswith("story.messages.path_keeper_after_setback must be ")
        for failure in failures
    )

    data = story()
    data["nodes"]["mountain_path"]["actions"] = [
        action
        for action in data["nodes"]["mountain_path"]["actions"]
        if action["id"] != "talk_to_path_keeper"
    ]
    assert (
        "story.nodes.mountain_path.actions is missing path-keeper action "
        "'talk_to_path_keeper'" in validate_story(data)
    )


def test_first_breath_story_locks_sunny_cord_path_mark_contract() -> None:
    data = story()
    path_mark_action = next(
        action
        for action in data["nodes"]["mountain_path"]["actions"]
        if action["id"] == "inspect_path_marker"
    )
    path_mark_action["label"] = "领取路签奖励"
    data["dialogues"]["path_mark_briefing"]["lines"][0]["text"] = "改写的开场。"
    data["dialogues"]["path_mark_briefing"]["choices"][1]["event_id"] = (
        "path_mark_low_knot"
    )
    data["messages"].pop("path_mark_choice_required")
    data["messages"]["path_marker_low_knot_inspected"] = "改写的低结结果。"
    data["journal_side_entries"]["path_mark_low_knot"]["title"] = "私有奖励"
    data["journal_side_entries"]["path_mark_high_streamer"]["summary"] = (
        "改写的高穗后果。"
    )
    epilogue_line = data["dialogues"]["chapter_epilogue"]["lines"][-1]
    epilogue_line["text"] = epilogue_line["text"].replace(
        "{path_mark_reflection}。", ""
    )

    failures = validate_story(data)

    assert any(
        failure.startswith(
            "story.nodes.mountain_path.actions.inspect_path_marker must be "
        )
        for failure in failures
    )
    assert (
        "story.dialogues.path_mark_briefing must match the exact sunny-cord script"
        in failures
    )
    assert any(
        failure.startswith("story.messages.path_mark_choice_required must be ")
        for failure in failures
    )
    assert any(
        failure.startswith("story.messages.path_marker_low_knot_inspected must be ")
        for failure in failures
    )
    assert any(
        failure.startswith(
            "story.journal_side_entries.path_mark_low_knot must be "
        )
        for failure in failures
    )
    assert any(
        failure.startswith(
            "story.journal_side_entries.path_mark_high_streamer must be "
        )
        for failure in failures
    )
    assert (
        "story.dialogues.chapter_epilogue.lines must contain exactly one "
        "'{path_mark_reflection}' token" in failures
    )

    data = story()
    data["nodes"]["mountain_path"]["actions"] = [
        action
        for action in data["nodes"]["mountain_path"]["actions"]
        if action["id"] != "inspect_path_marker"
    ]
    assert (
        "story.nodes.mountain_path.actions is missing path-mark action "
        "'inspect_path_marker'" in validate_story(data)
    )

    data = story()
    data["nodes"]["mountain_path"] = []
    assert (
        "story.nodes.mountain_path.actions is missing path-keeper action "
        "'talk_to_path_keeper'" in validate_story(data)
    )

    data = story()
    data["nodes"]["mountain_path"]["actions"] = {}
    assert (
        "story.nodes.mountain_path.actions is missing path-keeper action "
        "'talk_to_path_keeper'" in validate_story(data)
    )


def test_rejects_non_object_and_missing_contract() -> None:
    assert validate_story([]) == ["story must be an object"]
    failures = validate_story({"schema_version": 2})
    assert "story.schema_version must be 1" in failures
    assert "story.story_id must be non-empty text" in failures
    assert "story.origin must be 'original'" in failures
    assert "story.nodes must be an object" in failures
    assert "story.messages must be an object" in failures
    assert "story.dialogues must be an object" in failures
    assert "story.dialogues must not be empty" in failures
    assert "story.journal_entries must be an object" in failures
    assert any("journal_entries is missing" in failure for failure in failures)
    assert "story.journal_side_entries must be an object" in failures
    assert any("journal_side_entries is missing" in failure for failure in failures)
    assert "story.enemy_notes must be an object" in failures
    assert any("enemy_notes is missing" in failure for failure in failures)
    assert "story.start_node must be non-empty text" in failures


def test_rejects_unlicensed_source_fields() -> None:
    data = story()
    data["nodes"]["riverbank"]["source_text"] = "not allowed"
    assert any("source_text is forbidden" in failure for failure in validate_story(data))


def test_rejects_bad_start_and_unreachable_nodes() -> None:
    data = story()
    data["start_node"] = "missing"
    assert "story.start_node points to missing node 'missing'" in validate_story(data)

    data = story()
    data["nodes"]["orphan"] = deepcopy(data["nodes"]["complete"])
    data["nodes"]["orphan"]["actions"][0]["id"] = "orphan_review"
    data["nodes"]["orphan"]["actions"][0]["possible_targets"] = ["orphan"]
    assert "story has unreachable nodes: orphan" in validate_story(data)


def test_reachability_handles_converging_paths() -> None:
    data = {
        "schema_version": 1,
        "story_id": "diamond",
        "origin": "original",
        "start_node": "start",
        "nodes": {
            "start": {
                "kind": "explore",
                "title": "起点",
                "description": "两条路。",
                "actions": [
                    {"id": "left", "label": "左", "possible_targets": ["left"]},
                    {"id": "right", "label": "右", "possible_targets": ["right"]},
                    {
                        "id": "inspect_rock_spoor",
                        "label": "看爪痕",
                        "possible_targets": ["start"],
                    },
                    {
                        "id": "inspect_moss_spoor",
                        "label": "看孢痕",
                        "possible_targets": ["start"],
                    },
                    {
                        "id": "inspect_puppet_spoor",
                        "label": "看拖痕",
                        "possible_targets": ["start"],
                    },
                    {
                        "id": "use_talisman",
                        "label": "用符",
                        "possible_targets": ["start"],
                    },
                    {
                        "id": "use_art",
                        "label": "引气",
                        "possible_targets": ["start"],
                    },
                    {
                        "id": "guard",
                        "label": "守势",
                        "possible_targets": ["start"],
                    },
                ],
            },
            "left": {
                "kind": "dialogue",
                "title": "左路",
                "description": "归流。",
                "actions": [{"id": "left_end", "label": "继续", "possible_targets": ["end"]}],
            },
            "right": {
                "kind": "dialogue",
                "title": "右路",
                "description": "归流。",
                "actions": [
                    {"id": "right_end", "label": "继续", "possible_targets": ["end"]}
                ],
            },
            "end": {
                "kind": "ending",
                "title": "终点",
                "description": "汇合。",
                "actions": [
                    {"id": "review", "label": "回顾", "possible_targets": ["end"]}
                ],
            },
        },
        "messages": {"done": "完成。", "briefing_continue": "继续。", "briefing_wait": "等待。"},
        "dialogues": {
            "briefing": {
                "lines": [{"speaker": "同行者", "text": "两路终将汇合。"}],
                "choices": [
                    {"id": "continue", "label": "继续", "event_id": "briefing_continue"},
                    {"id": "wait", "label": "等待", "event_id": "briefing_wait"},
                ],
                "choice_prompt": "选择一条路。",
            }
        },
        "journal_entries": {
            "ferry_watermark": {"title": "水痕", "summary": "旧日水位。"},
            "spring_seam": {"title": "泉纹", "summary": "分流泉脉。"},
            "abandoned_basket": {"title": "药篓", "summary": "修补提绳。"},
        },
        "journal_side_entries": {
            "ferryman_repair": {"title": "扶尺", "summary": "水尺立稳。"},
            "ferryman_record": {"title": "记时", "summary": "涨时入簿。"},
            "basket_return": {"title": "归圃", "summary": "药篓回到药圃。"},
            "basket_trail": {"title": "留山", "summary": "药篓留给行旅。"},
            "patrol_boat_first": {"title": "先护船", "summary": "木楔先送船架。"},
            "patrol_herbs_first": {"title": "先翻药", "summary": "药叶先上竹架。"},
            "path_mark_low_knot": {"title": "低结", "summary": "低处晴绳。"},
            "path_mark_high_streamer": {"title": "高穗", "summary": "高处亮穗。"},
        },
        "enemy_notes": {
            "rock_armor_young": {
                "title": "岩甲幼兽",
                "trace": "爪痕两短一深。",
                "cycle": ["先试探。", "再冲撞。"],
                "counter": "冲撞时用符。",
                "trace_action": "inspect_rock_spoor",
                "counter_action": "use_talisman",
                "counter_intent": "rock_rending_charge",
            },
            "spring_moss_shell": {
                "title": "泉苔寄壳",
                "trace": "孢痕一明一暗。",
                "cycle": ["先吸潮。", "再吐雾。"],
                "counter": "吸潮时引气。",
                "trace_action": "inspect_moss_spoor",
                "counter_action": "use_art",
                "counter_intent": "moss_absorb_tide",
            },
            "unbalanced_stone_puppet": {
                "title": "失衡石傀",
                "trace": "拖痕一深一浅。",
                "cycle": ["先摆锤。", "再回正。"],
                "counter": "摆锤时守势。",
                "trace_action": "inspect_puppet_spoor",
                "counter_action": "guard",
                "counter_intent": "puppet_unbalanced_swing",
            },
        },
    }
    assert validate_story(data) == []


def test_rejects_invalid_nodes_actions_and_targets() -> None:
    data = story()
    data["nodes"]["riverbank"]["kind"] = "cutscene"
    data["nodes"]["riverbank"]["title"] = ""
    data["nodes"]["riverbank"]["actions"][0]["possible_targets"] = ["missing", 42]
    data["nodes"]["battle"]["actions"][0]["id"] = "gather_moonleaf"
    failures = validate_story(data)
    assert any("kind must be one of" in failure for failure in failures)
    assert "story.nodes.riverbank.title must be non-empty text" in failures
    assert any("points to missing node 'missing'" in failure for failure in failures)
    assert any("contains an invalid id" in failure for failure in failures)
    assert any("duplicates 'gather_moonleaf'" in failure for failure in failures)


def test_rejects_empty_actions_targets_messages_and_endings() -> None:
    data = story()
    data["nodes"]["riverbank"]["actions"] = []
    data["nodes"]["battle"]["actions"][0]["possible_targets"] = []
    data["nodes"]["complete"]["kind"] = "dialogue"
    data["messages"] = {}
    failures = validate_story(data)
    assert "story.nodes.riverbank.actions must be a non-empty list" in failures
    assert any("possible_targets must be a non-empty list" in failure for failure in failures)
    assert "story must contain at least one ending node" in failures
    assert "story.messages must not be empty" in failures
    assert "story has no ending reachable from 'riverbank'" in failures


def test_rejects_malformed_nested_values() -> None:
    data = story()
    data["nodes"]["battle"] = []
    data["nodes"]["riverbank"]["actions"][0] = []
    data["messages"]["gathered"] = 8
    failures = validate_story(data)
    assert "story.nodes.battle must be an object" in failures
    assert "story.nodes.riverbank.actions[0] must be an object" in failures
    assert "story.messages.gathered must be non-empty text" in failures


def test_validates_optional_transition_prose_and_references() -> None:
    data = story()
    data["transitions"] = []
    assert "story.transitions must be an object" in validate_story(data)

    data = story()
    data["transitions"]["mountain_path"] = ""
    data["transitions"]["missing_transition"] = "无效转场"
    failures = validate_story(data)
    assert "story.transitions.mountain_path must be non-empty text" in failures
    assert (
        "story.transitions.missing_transition must reference a node or message id"
        in failures
    )


def test_validates_finite_journal_entries() -> None:
    data = story()
    data["journal_entries"].pop("spring_seam")
    data["journal_entries"]["licensed_secret"] = {
        "title": "不应出现",
        "summary": "外部设定不得混入。",
    }
    failures = validate_story(data)
    assert "story.journal_entries is missing: spring_seam" in failures
    assert "story.journal_entries has unknown ids: licensed_secret" in failures

    data = story()
    data["journal_entries"]["unused_note"] = {
        "title": "多余条目",
        "summary": "没有规则消费者的内容也应被拒绝。",
    }
    failures = validate_story(data)
    assert not any("journal_entries is missing" in failure for failure in failures)
    assert "story.journal_entries has unknown ids: unused_note" in failures

    data = story()
    data["journal_entries"]["ferry_watermark"] = []
    data["journal_entries"]["spring_seam"]["summary"] = ""
    failures = validate_story(data)
    assert "story.journal_entries.ferry_watermark must be an object" in failures
    assert "story.journal_entries.ferry_watermark.title must be non-empty text" in failures
    assert "story.journal_entries.spring_seam.summary must be non-empty text" in failures


def test_rejects_malformed_dialogue_contract() -> None:
    data = story()
    data["dialogues"] = {"": []}
    failures = validate_story(data)
    assert "story.dialogues.id must be non-empty text" in failures
    assert "story.dialogues. must be an object" in failures
    assert "story.dialogues..lines must be a non-empty list" in failures
    assert "story.dialogues..choices must contain exactly two responses" in failures

    data = story()
    data["dialogues"]["companion_briefing"]["lines"] = []
    data["dialogues"]["companion_briefing"]["choices"] = {}
    failures = validate_story(data)
    assert "story.dialogues.companion_briefing.lines must be a non-empty list" in failures
    assert (
        "story.dialogues.companion_briefing.choices must contain exactly two responses"
        in failures
    )


def test_validates_finite_journal_side_entries() -> None:
    data = story()
    data["journal_side_entries"].pop("ferryman_record")
    data["journal_side_entries"]["licensed_choice"] = {
        "title": "不应出现",
        "summary": "没有规则消费者的支线结果。",
    }
    failures = validate_story(data)
    assert "story.journal_side_entries is missing: ferryman_record" in failures
    assert "story.journal_side_entries has unknown ids: licensed_choice" in failures

    data = story()
    data["journal_side_entries"]["unused_result"] = {
        "title": "多余结果",
        "summary": "没有稳定规则标识的结果也应被拒绝。",
    }
    failures = validate_story(data)
    assert not any("journal_side_entries is missing" in failure for failure in failures)
    assert "story.journal_side_entries has unknown ids: unused_result" in failures

    data = story()
    data["journal_side_entries"]["ferryman_repair"] = []
    data["journal_side_entries"]["ferryman_record"]["summary"] = ""
    failures = validate_story(data)
    assert "story.journal_side_entries.ferryman_repair must be an object" in failures
    assert (
        "story.journal_side_entries.ferryman_repair.title must be non-empty text"
        in failures
    )
    assert (
        "story.journal_side_entries.ferryman_record.summary must be non-empty text"
        in failures
    )


def test_validates_exact_enemy_note_ids() -> None:
    data = story()
    data["enemy_notes"].pop("spring_moss_shell")
    data["enemy_notes"]["rock_armor_warden"] = deepcopy(
        data["enemy_notes"]["rock_armor_young"]
    )
    failures = validate_story(data)
    assert "story.enemy_notes is missing: spring_moss_shell" in failures
    assert "story.enemy_notes has unknown enemy ids: rock_armor_warden" in failures

    data = story()
    data["enemy_notes"]["unlicensed_enemy"] = deepcopy(
        data["enemy_notes"]["rock_armor_young"]
    )
    failures = validate_story(data)
    assert not any("enemy_notes is missing" in failure for failure in failures)
    assert "story.enemy_notes has unknown enemy ids: unlicensed_enemy" in failures


def test_rejects_malformed_enemy_note_fields_and_cycle() -> None:
    data = story()
    data["enemy_notes"]["rock_armor_young"] = []
    data["enemy_notes"]["spring_moss_shell"]["trace"] = ""
    data["enemy_notes"]["spring_moss_shell"]["cycle"] = ["", 7]
    data["enemy_notes"]["unbalanced_stone_puppet"].pop("counter")
    data["enemy_notes"]["unbalanced_stone_puppet"]["spoiler"] = "不应出现"
    failures = validate_story(data)
    assert "story.enemy_notes.rock_armor_young must be an object" in failures
    assert any(
        "story.enemy_notes.rock_armor_young is missing fields" in failure
        for failure in failures
    )
    assert (
        "story.enemy_notes.spring_moss_shell.trace must be non-empty text" in failures
    )
    assert (
        "story.enemy_notes.spring_moss_shell.cycle[0] must be non-empty text"
        in failures
    )
    assert (
        "story.enemy_notes.spring_moss_shell.cycle[1] must be non-empty text"
        in failures
    )
    assert (
        "story.enemy_notes.unbalanced_stone_puppet is missing fields: counter"
        in failures
    )
    assert (
        "story.enemy_notes.unbalanced_stone_puppet has unknown fields: spoiler"
        in failures
    )

    data = story()
    data["enemy_notes"]["rock_armor_young"]["cycle"] = {}
    assert (
        "story.enemy_notes.rock_armor_young.cycle must be a non-empty list"
        in validate_story(data)
    )


def test_validates_enemy_note_action_and_intent_references() -> None:
    data = story()
    data["enemy_notes"]["rock_armor_young"]["trace_action"] = "missing_spoor"
    data["enemy_notes"]["spring_moss_shell"]["counter_action"] = "guard"
    data["enemy_notes"]["unbalanced_stone_puppet"]["counter_intent"] = (
        "moss_absorb_tide"
    )
    failures = validate_story(data)
    assert (
        "story.enemy_notes.rock_armor_young.trace_action must be "
        "'inspect_rock_spoor' for 'rock_armor_young'" in failures
    )
    assert (
        "story.enemy_notes.rock_armor_young.trace_action points to missing action "
        "'missing_spoor'" in failures
    )
    assert (
        "story.enemy_notes.spring_moss_shell.counter_action must be "
        "'use_art' for 'spring_moss_shell'" in failures
    )
    assert (
        "story.enemy_notes.unbalanced_stone_puppet.counter_intent must be "
        "'puppet_unbalanced_swing' for 'unbalanced_stone_puppet'" in failures
    )

    data = story()
    mountain_actions = data["nodes"]["mountain_path"]["actions"]
    data["nodes"]["mountain_path"]["actions"] = [
        action for action in mountain_actions if action["id"] != "inspect_rock_spoor"
    ]
    assert (
        "story.enemy_notes.rock_armor_young.trace_action points to missing action "
        "'inspect_rock_spoor'" in validate_story(data)
    )


def test_rejects_malformed_dialogue_lines_and_choices() -> None:
    data = story()
    dialogue = data["dialogues"]["companion_briefing"]
    dialogue["lines"] = [[]]
    dialogue["choices"] = [
        {"id": "ghost", "label": "", "event_id": "missing_event"},
        {"id": "ghost", "label": "重复", "event_id": "briefing_careful"},
        [],
    ]
    failures = validate_story(data)
    assert "story.dialogues.companion_briefing.lines[0] must be an object" in failures
    assert "story.dialogues.companion_briefing.lines[0].speaker must be non-empty text" in failures
    assert "story.dialogues.companion_briefing.lines[0].text must be non-empty text" in failures
    assert any("choices must contain exactly two" in failure for failure in failures)
    assert any("duplicates 'ghost'" in failure for failure in failures)
    assert any(
        "event_id points to missing message 'missing_event'" in failure
        for failure in failures
    )
    assert any("event_id must be non-empty text" in failure for failure in failures)
    assert "story.dialogues.companion_briefing.choices[0].label must be non-empty text" in failures
    assert "story.dialogues.companion_briefing.choices[2] must be an object" in failures

    data = story()
    data["dialogues"]["chapter_epilogue"]["lines"][0]["text"] = "{unknown_echo}"
    assert any(
        "text has unknown tokens: unknown_echo" in failure
        for failure in validate_story(data)
    )


def test_main_reports_invalid_json_and_empty_directory(tmp_path: Path, monkeypatch, capsys) -> None:
    from scripts import check_rpg_content

    monkeypatch.setattr(check_rpg_content, "CONTENT_DIR", tmp_path)
    try:
        check_rpg_content.main()
    except SystemExit as error:
        assert str(error) == "No RPG story files found."
    else:
        raise AssertionError("empty content directory must fail")

    (tmp_path / "broken.json").write_text("{", encoding="utf-8")
    try:
        check_rpg_content.main()
    except SystemExit as error:
        assert "invalid JSON at line 1" in str(error)
    else:
        raise AssertionError("invalid JSON must fail")
    assert capsys.readouterr().out == ""


def test_main_reports_invalid_story_and_valid_story(tmp_path: Path, monkeypatch, capsys) -> None:
    from scripts import check_rpg_content

    monkeypatch.setattr(check_rpg_content, "CONTENT_DIR", tmp_path)
    path = tmp_path / "story.json"
    path.write_text(json.dumps({"schema_version": 1}), encoding="utf-8")
    try:
        check_rpg_content.main()
    except SystemExit as error:
        assert "RPG content validation failed" in str(error)
        assert ".origin must be 'original'" in str(error)
    else:
        raise AssertionError("invalid story must fail")

    path.write_text(json.dumps(story(), ensure_ascii=False), encoding="utf-8")
    check_rpg_content.main()
    assert capsys.readouterr().out == "RPG content passed across 1 original story graph(s).\n"
