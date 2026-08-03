"""Create and verify a deterministic manifest for the Godot resource pack."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
from typing import Any

SCHEMA_VERSION = 1
ARTIFACT_NAME = "covenant-of-the-realm.pck"
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
    "res://src/domain/exploration_state.gd",
    "res://src/domain/journey_state.gd",
    "res://src/domain/patrol_state.gd",
    "res://src/domain/save_game.gd",
    "res://src/ui/dialogue_portrait.gd",
    "res://src/ui/main.tscn",
    "res://src/ui/map_detail_layer.gd",
    "res://src/ui/map_occluder.gd",
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


def manifest_for(pack_path: Path, source_revision: str, source_tree_state: str) -> dict[str, Any]:
    if not pack_path.is_file() or pack_path.stat().st_size <= 0:
        raise ValueError("resource pack must be a non-empty file")
    if re.fullmatch(r"[0-9a-f]{40}", source_revision) is None:
        raise ValueError("source revision must be a 40-character lowercase Git object ID")
    if source_tree_state not in {"clean", "dirty"}:
        raise ValueError("source tree state must be clean or dirty")
    return {
        "schema_version": SCHEMA_VERSION,
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


def write_manifest(
    pack_path: Path,
    output_path: Path,
    source_revision: str,
    source_tree_state: str,
) -> dict[str, Any]:
    manifest = manifest_for(pack_path, source_revision, source_tree_state)
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
    try:
        expected = manifest_for(
            pack_path,
            str(data.get("source_revision", "")),
            str(data.get("source_tree_state", "")),
        )
    except ValueError as error:
        return [str(error)]
    return [
        f"manifest field {key!r} does not match the resource pack"
        for key, value in expected.items()
        if data.get(key) != value
    ]


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
        print("RPG package manifest verified: size, SHA-256, resources, and source state match.")
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
        f"{manifest['size_bytes']} bytes, sha256 {manifest['sha256']}."
    )


if __name__ == "__main__":
    main()
