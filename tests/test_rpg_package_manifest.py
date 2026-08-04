from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

import pytest

from scripts import rpg_package_manifest

REVISION = "a" * 40
BUILD_OS = "macos"
BUILD_ARCHITECTURE = "arm64"


def test_manifest_round_trip_and_exact_contract(tmp_path: Path) -> None:
    pack = tmp_path / "game.pck"
    pack.write_bytes(b"deterministic-pack")
    output = tmp_path / "nested" / "manifest.json"
    written = rpg_package_manifest.write_manifest(
        pack,
        output,
        REVISION,
        "clean",
        build_os=BUILD_OS,
        build_architecture=BUILD_ARCHITECTURE,
    )
    assert written["schema_version"] == 2
    assert written["build_os"] == BUILD_OS
    assert written["build_architecture"] == BUILD_ARCHITECTURE
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
        "res://assets/pixel/cenwei.png",
        "res://assets/pixel/enemy_profiles.png",
        "res://assets/pixel/ferry_tiles.png",
        "res://assets/pixel/zhaohe_landmarks.png",
        "res://assets/pixel/huishen.png",
        "res://assets/pixel/liangshu.png",
        "res://assets/pixel/protagonist.png",
        "res://assets/pixel/yanqing.png",
        "res://assets/pixel/tao_xiaoman.png",
        "res://content/prologue.json",
        "res://src/domain/enemy_catalog.gd",
        "res://src/domain/exploration_state.gd",
        "res://src/domain/journey_state.gd",
        "res://src/domain/path_keeper_state.gd",
        "res://src/domain/patrol_state.gd",
        "res://src/domain/save_game.gd",
        "res://src/domain/settings_store.gd",
        "res://src/ui/dialogue_portrait.gd",
        "res://src/ui/enemy_sprite.gd",
        "res://src/ui/intent_telegraph.gd",
        "res://src/ui/main.gd",
        "res://src/ui/main.tscn",
        "res://src/ui/map_detail_layer.gd",
        "res://src/ui/map_occluder.gd",
        "res://src/ui/world_camera.gd",
    ]
    assert len(written["required_resources"]) == 25
    assert "res://src/ui/intent_telegraph.gd" in written["required_resources"]
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
    ("raw_value", "expected"),
    [
        ("Darwin", "macos"),
        (" macOS ", "macos"),
        ("Linux", "linux"),
    ],
)
def test_build_operating_system_aliases_are_normalized(
    raw_value: str,
    expected: str,
) -> None:
    assert rpg_package_manifest.normalize_build_os(raw_value) == expected


@pytest.mark.parametrize(
    ("raw_value", "expected"),
    [
        ("arm64", "arm64"),
        (" AArch64 ", "arm64"),
        ("x86_64", "x86_64"),
        ("AMD64", "x86_64"),
    ],
)
def test_build_architecture_aliases_are_normalized(
    raw_value: str,
    expected: str,
) -> None:
    assert rpg_package_manifest.normalize_build_architecture(raw_value) == expected


def test_build_platform_detection_uses_normalized_stdlib_values(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(rpg_package_manifest.platform, "system", lambda: "Linux")
    monkeypatch.setattr(rpg_package_manifest.platform, "machine", lambda: "x86_64")

    assert rpg_package_manifest.detect_build_platform() == ("linux", "x86_64")


@pytest.mark.parametrize(
    ("pack_bytes", "revision", "tree_state", "build_os", "build_architecture", "message"),
    [
        (
            None,
            REVISION,
            "clean",
            BUILD_OS,
            BUILD_ARCHITECTURE,
            "resource pack must be a non-empty file",
        ),
        (
            b"",
            REVISION,
            "clean",
            BUILD_OS,
            BUILD_ARCHITECTURE,
            "resource pack must be a non-empty file",
        ),
        (
            b"pack",
            "ABC",
            "clean",
            BUILD_OS,
            BUILD_ARCHITECTURE,
            "source revision must be a 40-character",
        ),
        (
            b"pack",
            REVISION,
            "unknown",
            BUILD_OS,
            BUILD_ARCHITECTURE,
            "source tree state must be clean or dirty",
        ),
        (b"pack", REVISION, "clean", "FreeBSD", BUILD_ARCHITECTURE, "build operating system"),
        (b"pack", REVISION, "clean", BUILD_OS, "i686", "build architecture"),
        (b"pack", REVISION, "clean", None, BUILD_ARCHITECTURE, "must be provided together"),
    ],
)
def test_manifest_rejects_invalid_inputs(
    tmp_path: Path,
    pack_bytes: bytes | None,
    revision: str,
    tree_state: str,
    build_os: str | None,
    build_architecture: str | None,
    message: str,
) -> None:
    pack = tmp_path / "game.pck"
    if pack_bytes is not None:
        pack.write_bytes(pack_bytes)
    with pytest.raises(ValueError, match=message):
        rpg_package_manifest.manifest_for(
            pack,
            revision,
            tree_state,
            build_os=build_os,
            build_architecture=build_architecture,
        )


@pytest.mark.parametrize(
    ("normalizer", "value", "message"),
    [
        (rpg_package_manifest.normalize_build_os, 7, "must be a string"),
        (rpg_package_manifest.normalize_build_os, "", "must resolve"),
        (rpg_package_manifest.normalize_build_architecture, [], "must be a string"),
        (rpg_package_manifest.normalize_build_architecture, "", "must resolve"),
    ],
)
def test_build_platform_normalizers_reject_malformed_values(
    normalizer,
    value,
    message: str,
) -> None:
    with pytest.raises(ValueError, match=message):
        normalizer(value)


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
    assert rpg_package_manifest.verify_manifest(pack, missing) == [
        "unsupported manifest schema version: None"
    ]
    missing.write_text(
        json.dumps(
            {
                "schema_version": 2,
                "build_os": BUILD_OS,
                "build_architecture": BUILD_ARCHITECTURE,
            }
        ),
        encoding="utf-8",
    )
    assert "source revision" in rpg_package_manifest.verify_manifest(pack, missing)[0]

    data = rpg_package_manifest.manifest_for(
        pack,
        REVISION,
        "dirty",
        build_os=BUILD_OS,
        build_architecture=BUILD_ARCHITECTURE,
    )
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


def test_verify_supports_exact_v1_and_rejects_invalid_v2_provenance(tmp_path: Path) -> None:
    pack = tmp_path / "game.pck"
    pack.write_bytes(b"pack")
    manifest = tmp_path / "manifest.json"
    current = rpg_package_manifest.manifest_for(
        pack,
        REVISION,
        "clean",
        build_os=BUILD_OS,
        build_architecture=BUILD_ARCHITECTURE,
    )

    legacy = {
        key: value
        for key, value in current.items()
        if key not in {"build_os", "build_architecture"}
    }
    legacy["schema_version"] = 1
    legacy["required_resources"] = list(
        rpg_package_manifest.SCHEMA_V1_REQUIRED_RESOURCES
    )
    legacy["excluded_resources"] = list(
        rpg_package_manifest.SCHEMA_V1_EXCLUDED_RESOURCES
    )
    assert len(legacy["required_resources"]) == 22
    assert "res://assets/pixel/cenwei.png" not in legacy["required_resources"]
    assert "res://src/domain/path_keeper_state.gd" not in legacy["required_resources"]
    assert "res://src/ui/intent_telegraph.gd" not in legacy["required_resources"]
    manifest.write_text(json.dumps(legacy), encoding="utf-8")
    assert rpg_package_manifest.verify_manifest(pack, manifest) == []

    reinterpreted_v1 = legacy.copy()
    reinterpreted_v1["required_resources"] = list(
        rpg_package_manifest.REQUIRED_RESOURCES
    )
    manifest.write_text(json.dumps(reinterpreted_v1), encoding="utf-8")
    assert rpg_package_manifest.verify_manifest(pack, manifest) == [
        "manifest field 'required_resources' does not match the resource pack"
    ]

    invalid_v1_scalar_type = legacy.copy()
    invalid_v1_scalar_type["size_bytes"] = float(legacy["size_bytes"])
    manifest.write_text(json.dumps(invalid_v1_scalar_type), encoding="utf-8")
    assert rpg_package_manifest.verify_manifest(pack, manifest) == [
        "manifest field 'size_bytes' does not match the resource pack"
    ]

    invalid_v2_scalar_type = current.copy()
    invalid_v2_scalar_type["requires_compatible_godot_runtime"] = 1
    manifest.write_text(json.dumps(invalid_v2_scalar_type), encoding="utf-8")
    assert rpg_package_manifest.verify_manifest(pack, manifest) == [
        "manifest field 'requires_compatible_godot_runtime' does not match the resource pack"
    ]

    missing_platform = current.copy()
    missing_platform.pop("build_architecture")
    manifest.write_text(json.dumps(missing_platform), encoding="utf-8")
    assert rpg_package_manifest.verify_manifest(pack, manifest) == [
        "manifest schema v2 requires build_os and build_architecture"
    ]

    noncanonical_platform = current.copy()
    noncanonical_platform["build_os"] = "Darwin"
    manifest.write_text(json.dumps(noncanonical_platform), encoding="utf-8")
    assert rpg_package_manifest.verify_manifest(pack, manifest) == [
        "manifest field 'build_os' does not match the resource pack"
    ]

    unexpected_field = current.copy()
    unexpected_field["runner_name"] = "local-machine"
    manifest.write_text(json.dumps(unexpected_field), encoding="utf-8")
    assert rpg_package_manifest.verify_manifest(pack, manifest) == [
        "manifest field 'runner_name' is not allowed by schema v2"
    ]

    current["schema_version"] = 3
    manifest.write_text(json.dumps(current), encoding="utf-8")
    assert rpg_package_manifest.verify_manifest(pack, manifest) == [
        "unsupported manifest schema version: 3"
    ]

    current["schema_version"] = True
    manifest.write_text(json.dumps(current), encoding="utf-8")
    assert rpg_package_manifest.verify_manifest(pack, manifest) == [
        "unsupported manifest schema version: True"
    ]


def test_cli_generates_verifies_and_fails_closed(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    pack = tmp_path / "game.pck"
    pack.write_bytes(b"cli-pack")
    manifest = tmp_path / "manifest.json"
    monkeypatch.setattr(rpg_package_manifest.platform, "system", lambda: "Darwin")
    monkeypatch.setattr(rpg_package_manifest.platform, "machine", lambda: "arm64")
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
    generated = json.loads(manifest.read_text(encoding="utf-8"))
    assert generated["build_os"] == BUILD_OS
    assert generated["build_architecture"] == BUILD_ARCHITECTURE

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
