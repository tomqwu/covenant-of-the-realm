"""Create and verify a canonical provenance manifest for the Godot resource pack."""

from __future__ import annotations

import argparse
import hashlib
import json
import platform
import re
from pathlib import Path
from typing import Any

SCHEMA_VERSION = 2
ARTIFACT_NAME = "covenant-of-the-realm.pck"
BUILD_OS_ALIASES = {
    "darwin": "macos",
    "macos": "macos",
    "linux": "linux",
}
BUILD_ARCHITECTURE_ALIASES = {
    "aarch64": "arm64",
    "arm64": "arm64",
    "amd64": "x86_64",
    "x86_64": "x86_64",
}
REQUIRED_RESOURCES = [
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
    "res://src/domain/patrol_state.gd",
    "res://src/domain/save_game.gd",
    "res://src/domain/settings_store.gd",
    "res://src/ui/dialogue_portrait.gd",
    "res://src/ui/enemy_sprite.gd",
    "res://src/ui/main.gd",
    "res://src/ui/main.tscn",
    "res://src/ui/map_detail_layer.gd",
    "res://src/ui/map_occluder.gd",
    "res://src/ui/world_camera.gd",
]
EXCLUDED_RESOURCES = [
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


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalize_build_os(value: str) -> str:
    if not isinstance(value, str):
        raise ValueError("build operating system must be a string")
    normalized = BUILD_OS_ALIASES.get(value.strip().casefold())
    if normalized is None:
        raise ValueError("build operating system must resolve to macos or linux")
    return normalized


def normalize_build_architecture(value: str) -> str:
    if not isinstance(value, str):
        raise ValueError("build architecture must be a string")
    normalized = BUILD_ARCHITECTURE_ALIASES.get(value.strip().casefold())
    if normalized is None:
        raise ValueError("build architecture must resolve to arm64 or x86_64")
    return normalized


def detect_build_platform() -> tuple[str, str]:
    return (
        normalize_build_os(platform.system()),
        normalize_build_architecture(platform.machine()),
    )


def _resolve_build_platform(
    build_os: str | None,
    build_architecture: str | None,
) -> tuple[str, str]:
    if build_os is None and build_architecture is None:
        return detect_build_platform()
    if build_os is None or build_architecture is None:
        raise ValueError("build operating system and architecture must be provided together")
    return normalize_build_os(build_os), normalize_build_architecture(build_architecture)


def _base_manifest(
    pack_path: Path,
    source_revision: str,
    source_tree_state: str,
) -> dict[str, Any]:
    if not pack_path.is_file() or pack_path.stat().st_size <= 0:
        raise ValueError("resource pack must be a non-empty file")
    if re.fullmatch(r"[0-9a-f]{40}", source_revision) is None:
        raise ValueError("source revision must be a 40-character lowercase Git object ID")
    if source_tree_state not in {"clean", "dirty"}:
        raise ValueError("source tree state must be clean or dirty")
    return {
        "artifact": ARTIFACT_NAME,
        "artifact_type": "godot-resource-pack",
        "godot_version": "4.7.1",
        "preset": "Playable Pack",
        "requires_compatible_godot_runtime": True,
        "sha256": _sha256(pack_path),
        "size_bytes": pack_path.stat().st_size,
        "source_revision": source_revision,
        "source_tree_state": source_tree_state,
        "required_resources": list(REQUIRED_RESOURCES),
        "excluded_resources": list(EXCLUDED_RESOURCES),
    }


def manifest_for(
    pack_path: Path,
    source_revision: str,
    source_tree_state: str,
    *,
    build_os: str | None = None,
    build_architecture: str | None = None,
) -> dict[str, Any]:
    normalized_os, normalized_architecture = _resolve_build_platform(
        build_os,
        build_architecture,
    )
    return {
        "schema_version": SCHEMA_VERSION,
        "build_os": normalized_os,
        "build_architecture": normalized_architecture,
        **_base_manifest(pack_path, source_revision, source_tree_state),
    }


def write_manifest(
    pack_path: Path,
    output_path: Path,
    source_revision: str,
    source_tree_state: str,
    *,
    build_os: str | None = None,
    build_architecture: str | None = None,
) -> dict[str, Any]:
    manifest = manifest_for(
        pack_path,
        source_revision,
        source_tree_state,
        build_os=build_os,
        build_architecture=build_architecture,
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return manifest


def verify_manifest(pack_path: Path, manifest_path: Path) -> list[str]:
    try:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"unable to read manifest: {error}"]
    if not isinstance(data, dict):
        return ["manifest must be an object"]
    schema_version = data.get("schema_version")
    if type(schema_version) is not int:
        return [f"unsupported manifest schema version: {schema_version!r}"]
    try:
        if schema_version == 1:
            expected = {
                "schema_version": 1,
                **_base_manifest(
                    pack_path,
                    str(data.get("source_revision", "")),
                    str(data.get("source_tree_state", "")),
                ),
            }
        elif schema_version == 2:
            if "build_os" not in data or "build_architecture" not in data:
                return ["manifest schema v2 requires build_os and build_architecture"]
            expected = manifest_for(
                pack_path,
                str(data.get("source_revision", "")),
                str(data.get("source_tree_state", "")),
                build_os=data["build_os"],
                build_architecture=data["build_architecture"],
            )
        else:
            return [f"unsupported manifest schema version: {schema_version!r}"]
    except ValueError as error:
        return [str(error)]
    failures = [
        f"manifest field {key!r} does not match the resource pack"
        for key, value in expected.items()
        if type(data.get(key)) is not type(value) or data.get(key) != value
    ]
    failures.extend(
        f"manifest field {key!r} is not allowed by schema v{schema_version}"
        for key in sorted(set(data) - set(expected))
    )
    return failures


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pack", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--source-revision")
    parser.add_argument("--source-tree-state", choices=["clean", "dirty"])
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    if args.verify:
        failures = verify_manifest(args.pack, args.manifest)
        if failures:
            raise SystemExit("RPG package manifest failed:\n" + "\n".join(failures))
        print(
            "RPG package manifest verified: artifact bytes, schema fields, resources, "
            "and source state match."
        )
        return
    if args.source_revision is None or args.source_tree_state is None:
        parser.error("generation requires --source-revision and --source-tree-state")
    manifest = write_manifest(
        args.pack,
        args.manifest,
        args.source_revision,
        args.source_tree_state,
    )
    print(
        "RPG package manifest written: "
        f"{manifest['size_bytes']} bytes, sha256 {manifest['sha256']}, "
        f"build tuple {manifest['build_os']}/{manifest['build_architecture']}."
    )


if __name__ == "__main__":
    main()
