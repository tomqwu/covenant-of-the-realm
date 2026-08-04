"""Validate deterministic RPG pixel-asset dimensions and production metadata."""

from __future__ import annotations

import json
import struct
import zlib
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "rpg" / "assets" / "pixel"
CONTRACT_PATH = ASSET_DIR / "asset_contract.json"
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
MAP_ATLAS_COLUMNS = 8
MAP_ATLAS_ROWS = 2
MAP_ATLAS_SIZE_PX = (256, 64)
MAP_SIZE_TILES = (48, 27)
LANDMARK_ATLAS_COLUMNS = 11
LANDMARK_ATLAS_ROWS = 1
LANDMARK_FRAME_SIZE_PX = (192, 128)
LANDMARK_ATLAS_SIZE_PX = (2112, 128)
ENEMY_ATLAS_COLUMNS = 6
ENEMY_ATLAS_ROWS = 4
ENEMY_FRAME_SIZE_PX = (64, 64)
ENEMY_ATLAS_SIZE_PX = (384, 256)
MAP_BASE_TILE_NAMES = [
    "grass",
    "water",
    "bank",
    "path",
    "moonleaf_field",
    "stone",
    "deep_grass",
    "water_glint",
]
MAP_DETAIL_TILE_NAMES = [
    "reeds",
    "bank_grass",
    "path_pebbles",
    "wildflowers",
    "stone_cracks",
    "moss",
    "fallen_leaves",
    "water_foam",
]
LANDMARK_PROFILES = [
    "tree_celadon",
    "ferry_house_rust",
    "ferry_house_ochre",
    "ferry_house_teal",
    "ferry_dock",
    "mountain_rock",
    "spring_cave",
    "spring_gate",
    "ferry_boat_repair",
    "ferry_drying_rack",
    "path_rain_shelter",
]
OCCLUDING_LANDMARK_PROFILES = LANDMARK_PROFILES[:4]


def _png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError("not a valid PNG signature")

    offset = len(PNG_SIGNATURE)
    size: tuple[int, int] | None = None
    compressed_rows: list[bytes] = []
    saw_iend = False
    while offset < len(data):
        if len(data) - offset < 12:
            raise ValueError("truncated PNG chunk")
        chunk_length = struct.unpack(">I", data[offset : offset + 4])[0]
        chunk_end = offset + 12 + chunk_length
        if chunk_end > len(data):
            raise ValueError("truncated PNG chunk")
        chunk_type = data[offset + 4 : offset + 8]
        chunk_data = data[offset + 8 : offset + 8 + chunk_length]
        expected_crc = struct.unpack(">I", data[offset + 8 + chunk_length : chunk_end])[0]
        actual_crc = zlib.crc32(chunk_data, zlib.crc32(chunk_type)) & 0xFFFFFFFF
        if actual_crc != expected_crc:
            raise ValueError(f"PNG chunk CRC mismatch: {chunk_type.decode('ascii', 'replace')}")

        if size is None:
            if chunk_type != b"IHDR" or chunk_length != 13:
                raise ValueError("PNG must begin with a 13-byte IHDR chunk")
            (
                width,
                height,
                bit_depth,
                color_type,
                compression_method,
                filter_method,
                interlace_method,
            ) = struct.unpack(">IIBBBBB", chunk_data)
            if width == 0 or height == 0:
                raise ValueError("PNG dimensions must be positive")
            if bit_depth != 8 or color_type != 6:
                raise ValueError("PNG must use 8-bit RGBA pixels")
            if compression_method != 0 or filter_method != 0 or interlace_method != 0:
                raise ValueError("PNG must use standard compression/filtering without interlace")
            size = (width, height)
        elif chunk_type == b"IHDR":
            raise ValueError("PNG must contain exactly one IHDR chunk")

        if chunk_type == b"IDAT":
            compressed_rows.append(chunk_data)
        elif chunk_type == b"IEND":
            if chunk_length != 0:
                raise ValueError("PNG IEND chunk must be empty")
            saw_iend = True
            offset = chunk_end
            if offset != len(data):
                raise ValueError("PNG contains trailing data after IEND")
            break
        offset = chunk_end

    if size is None:
        raise ValueError("PNG is missing IHDR")
    if not compressed_rows:
        raise ValueError("PNG is missing IDAT image data")
    if not saw_iend:
        raise ValueError("PNG is missing IEND")

    decompressor = zlib.decompressobj()
    try:
        rows = decompressor.decompress(b"".join(compressed_rows)) + decompressor.flush()
    except zlib.error as error:
        raise ValueError("invalid PNG image data") from error
    if not decompressor.eof or decompressor.unused_data or decompressor.unconsumed_tail:
        raise ValueError("invalid PNG image data")

    width, height = size
    row_stride = 1 + width * 4
    if len(rows) != row_stride * height:
        raise ValueError("PNG image data length does not match its dimensions")
    if any(rows[row * row_stride] > 4 for row in range(height)):
        raise ValueError("PNG uses an invalid row filter")
    return size


def validate_contract(data: Any) -> list[str]:
    failures: list[str] = []
    if not isinstance(data, dict):
        return ["asset contract must be an object"]
    expected = {
        "schema_version": 6,
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
    expected_actor_atlases = [
        "protagonist.png",
        "yanqing.png",
        "liangshu.png",
        "huishen.png",
        "tao_xiaoman.png",
        "cenwei.png",
    ]
    if not isinstance(atlases, list) or atlases != expected_actor_atlases:
        failures.append("atlases must match the six stable actor IDs")
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
        if enemy_atlas.get("columns") != ENEMY_ATLAS_COLUMNS:
            failures.append("enemy_atlas.columns must be 6")
        if enemy_atlas.get("rows") != ENEMY_ATLAS_ROWS:
            failures.append("enemy_atlas.rows must be 4")
        expected_enemy_animations = {
            "idle": {"columns": [0, 1], "fps": 2.5, "loop": True},
            "attack": {"columns": [2, 3], "fps": 8.0, "loop": False},
            "react": {"columns": [4, 5], "fps": 7.0, "loop": False},
        }
        if enemy_atlas.get("animations") != expected_enemy_animations:
            failures.append("enemy_atlas.animations must match idle, attack, and react slots")
        expected_semantic_events = {
            "react": ["weakness_exposed", "art_hit", "talisman_hit"],
            "attack": ["enemy_hit", "enemy_glanced"],
        }
        if enemy_atlas.get("semantic_events") != expected_semantic_events:
            failures.append("enemy_atlas.semantic_events must match battle event priority groups")
        expected_terminal_events = [
            "regular_enemy_won",
            "boss_arrived",
            "battle_won",
            "retreated",
            "companion_rescue",
        ]
        if enemy_atlas.get("terminal_suppression") != expected_terminal_events:
            failures.append("enemy_atlas.terminal_suppression must match battle transitions")
        if enemy_atlas.get("texture_filter") != "nearest":
            failures.append("enemy_atlas.texture_filter must be nearest")
        if enemy_atlas.get("pixel_snap") is not True:
            failures.append("enemy_atlas.pixel_snap must be true")
        if enemy_atlas.get("gameplay_authority") is not False:
            failures.append("enemy_atlas.gameplay_authority must be false")
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
                    if actual != ENEMY_ATLAS_SIZE_PX:
                        failures.append(
                            f"{enemy_file}: expected {ENEMY_ATLAS_SIZE_PX}, got {actual}"
                        )
                except ValueError as error:
                    failures.append(f"{enemy_file}: {error}")
    map_atlas = data.get("map_atlas")
    if not isinstance(map_atlas, dict):
        failures.append("map_atlas must be an object")
        return failures
    if map_atlas.get("tile_size_px") != [32, 32]:
        failures.append("map_atlas.tile_size_px must be [32, 32]")
    if map_atlas.get("map_size_tiles") != list(MAP_SIZE_TILES):
        failures.append(f"map_atlas.map_size_tiles must be {list(MAP_SIZE_TILES)!r}")
    tile_names = map_atlas.get("tiles")
    columns = map_atlas.get("columns")
    rows = map_atlas.get("rows")
    if columns != MAP_ATLAS_COLUMNS:
        failures.append(f"map_atlas.columns must be {MAP_ATLAS_COLUMNS}")
    if rows != MAP_ATLAS_ROWS:
        failures.append(f"map_atlas.rows must be {MAP_ATLAS_ROWS}")
    if not isinstance(tile_names, list) or any(
        not isinstance(tile_name, str) for tile_name in tile_names
    ):
        failures.append("map_atlas.tiles must be a flat row-major list of tile names")
    else:
        expected_tile_count = MAP_ATLAS_COLUMNS * MAP_ATLAS_ROWS
        if len(tile_names) != expected_tile_count:
            failures.append(f"map_atlas.tiles must name all {expected_tile_count} atlas cells")
        if tile_names[:MAP_ATLAS_COLUMNS] != MAP_BASE_TILE_NAMES:
            failures.append(
                f"map_atlas.tiles row 0 must preserve {MAP_BASE_TILE_NAMES!r}"
            )
        if tile_names[MAP_ATLAS_COLUMNS:] != MAP_DETAIL_TILE_NAMES:
            failures.append(f"map_atlas.tiles row 1 must be {MAP_DETAIL_TILE_NAMES!r}")
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
                if actual != MAP_ATLAS_SIZE_PX:
                    failures.append(
                        f"{map_file}: expected {MAP_ATLAS_SIZE_PX}, got {actual}"
                    )
            except ValueError as error:
                failures.append(f"{map_file}: {error}")
    landmark_atlas = data.get("landmark_atlas")
    if not isinstance(landmark_atlas, dict):
        failures.append("landmark_atlas must be an object")
        return failures
    if landmark_atlas.get("frame_size_px") != list(LANDMARK_FRAME_SIZE_PX):
        failures.append("landmark_atlas.frame_size_px must be [192, 128]")
    if landmark_atlas.get("foot_anchor_px") != [96, 127]:
        failures.append("landmark_atlas.foot_anchor_px must be [96, 127]")
    if landmark_atlas.get("columns") != LANDMARK_ATLAS_COLUMNS:
        failures.append(f"landmark_atlas.columns must be {LANDMARK_ATLAS_COLUMNS}")
    if landmark_atlas.get("rows") != LANDMARK_ATLAS_ROWS:
        failures.append(f"landmark_atlas.rows must be {LANDMARK_ATLAS_ROWS}")
    if landmark_atlas.get("texture_filter") != "nearest":
        failures.append("landmark_atlas.texture_filter must be nearest")
    if landmark_atlas.get("pixel_snap") is not True:
        failures.append("landmark_atlas.pixel_snap must be true")
    if landmark_atlas.get("collision_authority") is not False:
        failures.append("landmark_atlas.collision_authority must be false")
    if landmark_atlas.get("profiles") != LANDMARK_PROFILES:
        failures.append("landmark_atlas.profiles must match the eleven stable landmark IDs")
    if landmark_atlas.get("occluding_profiles") != OCCLUDING_LANDMARK_PROFILES:
        failures.append(
            "landmark_atlas.occluding_profiles must contain only tree and house IDs"
        )
    landmark_file = landmark_atlas.get("file")
    if not isinstance(landmark_file, str) or Path(landmark_file).name != landmark_file:
        failures.append("landmark_atlas.file must be a local file name")
    else:
        path = ASSET_DIR / landmark_file
        if not path.is_file():
            failures.append(f"missing landmark atlas: {landmark_file}")
        else:
            try:
                actual = _png_size(path)
                if actual != LANDMARK_ATLAS_SIZE_PX:
                    failures.append(
                        f"{landmark_file}: expected {LANDMARK_ATLAS_SIZE_PX}, got {actual}"
                    )
            except ValueError as error:
                failures.append(f"{landmark_file}: {error}")
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
        f"one 32 px map atlas for {MAP_SIZE_TILES[0]}x{MAP_SIZE_TILES[1]}-tile maps, "
        "and eleven environment landmarks validated."
    )


if __name__ == "__main__":
    main()
