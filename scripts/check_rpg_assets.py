"""Validate deterministic RPG pixel-asset dimensions and production metadata."""

from __future__ import annotations

import json
import struct
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "rpg" / "assets" / "pixel"
CONTRACT_PATH = ASSET_DIR / "asset_contract.json"
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def _png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as stream:
        header = stream.read(24)
    if len(header) != 24 or not header.startswith(PNG_SIGNATURE) or header[12:16] != b"IHDR":
        raise ValueError("not a valid PNG header")
    return struct.unpack(">II", header[16:24])


def validate_contract(data: Any) -> list[str]:
    failures: list[str] = []
    if not isinstance(data, dict):
        return ["asset contract must be an object"]
    expected = {
        "schema_version": 1,
        "origin": "original",
        "tile_grid_px": 32,
        "actor_frame_px": [32, 56],
        "actor_visible_height_px": 56,
        "foot_anchor_px": [16, 52],
        "collision_box_px": [16, 20],
        "directions": ["down", "left", "right", "up"],
        "atlas_columns": 4,
        "atlas_rows": 4,
        "texture_filter": "nearest",
        "pixel_snap": True,
    }
    for key, value in expected.items():
        if data.get(key) != value:
            failures.append(f"{key} must be {value!r}")
    animations = data.get("animations")
    if not isinstance(animations, dict):
        failures.append("animations must be an object")
    else:
        if animations.get("idle") != {"columns": [0, 1], "fps": 2.0}:
            failures.append("idle animation must use columns 0-1 at 2 fps")
        if animations.get("walk") != {"columns": [2, 3], "fps": 6.0}:
            failures.append("walk animation must use columns 2-3 at 6 fps")
    palette = data.get("palette")
    if not isinstance(palette, list) or len(palette) < 8:
        failures.append("palette must contain at least eight colors")
    elif any(not isinstance(color, str) or len(color) != 6 for color in palette):
        failures.append("palette entries must be six-character RGB hex values")
    atlases = data.get("atlases")
    expected_actor_atlases = ["protagonist.png", "yanqing.png", "liangshu.png"]
    if not isinstance(atlases, list) or atlases != expected_actor_atlases:
        failures.append("atlases must match the three stable actor IDs")
        return failures
    width = data.get("actor_frame_px", [0, 0])[0] * data.get("atlas_columns", 0)
    height = data.get("actor_frame_px", [0, 0])[1] * data.get("atlas_rows", 0)
    for file_name in atlases:
        if not isinstance(file_name, str) or Path(file_name).name != file_name:
            failures.append(f"invalid atlas file name: {file_name!r}")
            continue
        path = ASSET_DIR / file_name
        if not path.is_file():
            failures.append(f"missing atlas: {file_name}")
            continue
        try:
            actual = _png_size(path)
        except ValueError as error:
            failures.append(f"{file_name}: {error}")
            continue
        if actual != (width, height):
            failures.append(f"{file_name}: expected {(width, height)}, got {actual}")
    enemy_atlas = data.get("enemy_atlas")
    expected_enemy_profiles = [
        "rock_armor_young",
        "spring_moss_shell",
        "unbalanced_stone_puppet",
        "rock_armor_warden",
    ]
    if not isinstance(enemy_atlas, dict):
        failures.append("enemy_atlas must be an object")
    else:
        if enemy_atlas.get("frame_size_px") != [64, 64]:
            failures.append("enemy_atlas.frame_size_px must be [64, 64]")
        if enemy_atlas.get("foot_anchor_px") != [32, 56]:
            failures.append("enemy_atlas.foot_anchor_px must be [32, 56]")
        if enemy_atlas.get("columns") != 2 or enemy_atlas.get("rows") != 4:
            failures.append("enemy_atlas must use two columns and four rows")
        if enemy_atlas.get("animation") != {"columns": [0, 1], "fps": 2.5}:
            failures.append("enemy_atlas.animation must use columns 0-1 at 2.5 fps")
        if enemy_atlas.get("profiles") != expected_enemy_profiles:
            failures.append("enemy_atlas.profiles must match the four stable enemy IDs")
        enemy_file = enemy_atlas.get("file")
        if not isinstance(enemy_file, str) or Path(enemy_file).name != enemy_file:
            failures.append("enemy_atlas.file must be a local file name")
        else:
            path = ASSET_DIR / enemy_file
            if not path.is_file():
                failures.append(f"missing enemy atlas: {enemy_file}")
            else:
                try:
                    actual = _png_size(path)
                    if actual != (128, 256):
                        failures.append(
                            f"{enemy_file}: expected (128, 256), got {actual}"
                        )
                except ValueError as error:
                    failures.append(f"{enemy_file}: {error}")
    map_atlas = data.get("map_atlas")
    if not isinstance(map_atlas, dict):
        failures.append("map_atlas must be an object")
        return failures
    if map_atlas.get("tile_size_px") != [32, 32]:
        failures.append("map_atlas.tile_size_px must be [32, 32]")
    if map_atlas.get("map_size_tiles") != [36, 20]:
        failures.append("map_atlas.map_size_tiles must be [36, 20]")
    tile_names = map_atlas.get("tiles")
    columns = map_atlas.get("columns")
    rows = map_atlas.get("rows")
    if not isinstance(columns, int) or columns <= 0:
        failures.append("map_atlas.columns must be a positive integer")
        columns = 0
    if not isinstance(rows, int) or rows <= 0:
        failures.append("map_atlas.rows must be a positive integer")
        rows = 0
    if not isinstance(tile_names, list) or len(tile_names) != columns * rows:
        failures.append("map_atlas.tiles must name every atlas cell")
    map_file = map_atlas.get("file")
    if not isinstance(map_file, str) or Path(map_file).name != map_file:
        failures.append("map_atlas.file must be a local file name")
    else:
        path = ASSET_DIR / map_file
        if not path.is_file():
            failures.append(f"missing map atlas: {map_file}")
        else:
            try:
                actual = _png_size(path)
                if map_atlas.get("tile_size_px") == [32, 32] and columns and rows:
                    expected_map_size = (
                        map_atlas["tile_size_px"][0] * columns,
                        map_atlas["tile_size_px"][1] * rows,
                    )
                    if actual != expected_map_size:
                        failures.append(
                            f"{map_file}: expected {expected_map_size}, got {actual}"
                        )
            except ValueError as error:
                failures.append(f"{map_file}: {error}")
    return failures


def main() -> None:
    try:
        data = json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise SystemExit(f"Unable to read pixel asset contract: {error}") from error
    failures = validate_contract(data)
    if failures:
        raise SystemExit("RPG asset validation failed:\n" + "\n".join(failures))
    print(
        "RPG pixel assets passed: "
        f"{len(data['atlases'])} actors, four animated enemies, "
        "and one 32 px map atlas validated."
    )


if __name__ == "__main__":
    main()
