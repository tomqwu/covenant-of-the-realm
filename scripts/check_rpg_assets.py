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
    if not isinstance(atlases, list) or not atlases:
        failures.append("atlases must be a non-empty list")
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
    return failures


def main() -> None:
    try:
        data = json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise SystemExit(f"Unable to read pixel asset contract: {error}") from error
    failures = validate_contract(data)
    if failures:
        raise SystemExit("RPG asset validation failed:\n" + "\n".join(failures))
    print(f"RPG pixel assets passed: {len(data['atlases'])} atlases follow the 32x56 contract.")


if __name__ == "__main__":
    main()
