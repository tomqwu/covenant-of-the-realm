from __future__ import annotations

import json
from copy import deepcopy
from pathlib import Path

from scripts.check_rpg_content import ROOT, validate_story


def story() -> dict:
    return json.loads((ROOT / "rpg/content/prologue.json").read_text(encoding="utf-8"))


def test_repository_story_is_valid() -> None:
    assert validate_story(story()) == []


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
