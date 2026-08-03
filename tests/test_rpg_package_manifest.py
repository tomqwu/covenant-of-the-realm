from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

import pytest

from scripts import rpg_package_manifest

REVISION = "a" * 40


def test_manifest_round_trip_and_exact_contract(tmp_path: Path) -> None:
    pack = tmp_path / "game.pck"
    pack.write_bytes(b"deterministic-pack")
    output = tmp_path / "nested" / "manifest.json"
    written = rpg_package_manifest.write_manifest(pack, output, REVISION, "clean")
    assert written["schema_version"] == 1
    assert written["artifact"] == "covenant-of-the-realm.pck"
    assert written["artifact_type"] == "godot-resource-pack"
    assert written["godot_version"] == "4.7.1"
    assert written["preset"] == "Playable Pack"
    assert written["requires_compatible_godot_runtime"] is True
    assert written["size_bytes"] == len(b"deterministic-pack")
    assert written["sha256"] == hashlib.sha256(b"deterministic-pack").hexdigest()
    assert written["source_revision"] == REVISION
    assert written["source_tree_state"] == "clean"
    assert written["required_resources"] == [
        "res://assets/pixel/enemy_profiles.png",
        "res://assets/pixel/ferry_tiles.png",
        "res://assets/pixel/zhaohe_landmarks.png",
        "res://assets/pixel/huishen.png",
        "res://assets/pixel/liangshu.png",
        "res://assets/pixel/protagonist.png",
        "res://assets/pixel/yanqing.png",
        "res://assets/pixel/tao_xiaoman.png",
        "res://content/prologue.json",
        "res://src/domain/exploration_state.gd",
        "res://src/domain/journey_state.gd",
        "res://src/domain/patrol_state.gd",
        "res://src/domain/save_game.gd",
        "res://src/ui/dialogue_portrait.gd",
        "res://src/ui/main.tscn",
        "res://src/ui/map_detail_layer.gd",
        "res://src/ui/map_occluder.gd",
        "res://src/ui/world_camera.gd",
    ]
    assert written["excluded_resources"] == [
        "res://tests/e2e_runner.gd",
        "res://tests/input_runner.gd",
        "res://tests/performance_budget.json",
        "res://tests/performance_runner.gd",
        "res://tests/test_runner.gd",
        "res://tools/capture_ui.gd",
        "res://tools/generate_pixel_assets.gd",
        "res://tools/scale_test.tscn",
        "res://tools/scale_test_canvas.gd",
    ]
    assert json.loads(output.read_text(encoding="utf-8")) == written
    assert rpg_package_manifest.verify_manifest(pack, output) == []


@pytest.mark.parametrize(
    ("pack_bytes", "revision", "tree_state", "message"),
    [
        (None, REVISION, "clean", "resource pack must be a non-empty file"),
        (b"", REVISION, "clean", "resource pack must be a non-empty file"),
        (b"pack", "ABC", "clean", "source revision must be a 40-character"),
        (b"pack", REVISION, "unknown", "source tree state must be clean or dirty"),
    ],
)
def test_manifest_rejects_invalid_inputs(
    tmp_path: Path,
    pack_bytes: bytes | None,
    revision: str,
    tree_state: str,
    message: str,
) -> None:
    pack = tmp_path / "game.pck"
    if pack_bytes is not None:
        pack.write_bytes(pack_bytes)
    with pytest.raises(ValueError, match=message):
        rpg_package_manifest.manifest_for(pack, revision, tree_state)


def test_verify_reports_unreadable_invalid_and_tampered_manifests(tmp_path: Path) -> None:
    pack = tmp_path / "game.pck"
    pack.write_bytes(b"pack")
    missing = tmp_path / "missing.json"
    assert rpg_package_manifest.verify_manifest(pack, missing)[0].startswith(
        "unable to read manifest:"
    )
    missing.write_text("[]", encoding="utf-8")
    assert rpg_package_manifest.verify_manifest(pack, missing) == ["manifest must be an object"]
    missing.write_text("{}", encoding="utf-8")
    assert "source revision" in rpg_package_manifest.verify_manifest(pack, missing)[0]

    data = rpg_package_manifest.manifest_for(pack, REVISION, "dirty")
    data["sha256"] = "0" * 64
    data["required_resources"] = []
    data["excluded_resources"] = []
    missing.write_text(json.dumps(data), encoding="utf-8")
    failures = rpg_package_manifest.verify_manifest(pack, missing)
    assert failures == [
        "manifest field 'sha256' does not match the resource pack",
        "manifest field 'required_resources' does not match the resource pack",
        "manifest field 'excluded_resources' does not match the resource pack",
    ]


def test_cli_generates_verifies_and_fails_closed(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    pack = tmp_path / "game.pck"
    pack.write_bytes(b"cli-pack")
    manifest = tmp_path / "manifest.json"
    monkeypatch.setattr(
        sys,
        "argv",
        [
            "manifest",
            "--pack",
            str(pack),
            "--manifest",
            str(manifest),
            "--source-revision",
            REVISION,
            "--source-tree-state",
            "dirty",
        ],
    )
    rpg_package_manifest.main()
    assert "RPG package manifest written" in capsys.readouterr().out

    monkeypatch.setattr(
        sys,
        "argv",
        ["manifest", "--pack", str(pack), "--manifest", str(manifest), "--verify"],
    )
    rpg_package_manifest.main()
    assert "RPG package manifest verified" in capsys.readouterr().out

    manifest.write_text("{}", encoding="utf-8")
    with pytest.raises(SystemExit, match="RPG package manifest failed"):
        rpg_package_manifest.main()

    monkeypatch.setattr(
        sys,
        "argv",
        ["manifest", "--pack", str(pack), "--manifest", str(manifest)],
    )
    with pytest.raises(SystemExit) as error:
        rpg_package_manifest.main()
    assert error.value.code == 2
