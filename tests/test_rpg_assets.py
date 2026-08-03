from __future__ import annotations

import json
import shutil
import struct
from pathlib import Path
from typing import Any

import pytest

from scripts import check_rpg_assets

BASE_TILE_NAMES = [
    "grass",
    "water",
    "bank",
    "path",
    "moonleaf_field",
    "stone",
    "deep_grass",
    "water_glint",
]
DETAIL_TILE_NAMES = [
    "reeds",
    "bank_grass",
    "path_pebbles",
    "wildflowers",
    "stone_cracks",
    "moss",
    "fallen_leaves",
    "water_foam",
]


def _write_png_header(path: Path, width: int, height: int) -> None:
    path.write_bytes(
        check_rpg_assets.PNG_SIGNATURE
        + struct.pack(">I", 13)
        + b"IHDR"
        + struct.pack(">II", width, height)
    )


@pytest.fixture
def valid_contract(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> dict[str, Any]:
    source_asset_dir = check_rpg_assets.ASSET_DIR
    data = json.loads(check_rpg_assets.CONTRACT_PATH.read_text(encoding="utf-8"))
    data["map_atlas"] = {
        "file": "ferry_tiles.png",
        "tile_size_px": [32, 32],
        "columns": 8,
        "rows": 2,
        "map_size_tiles": [36, 20],
        "tiles": [*BASE_TILE_NAMES, *DETAIL_TILE_NAMES],
    }
    actor_files = data["atlases"]
    enemy_file = data["enemy_atlas"]["file"]
    for file_name in [*actor_files, enemy_file]:
        shutil.copyfile(source_asset_dir / file_name, tmp_path / file_name)
    _write_png_header(tmp_path / "ferry_tiles.png", 256, 64)
    monkeypatch.setattr(check_rpg_assets, "ASSET_DIR", tmp_path)
    return data


def test_map_atlas_accepts_exact_two_row_contract(valid_contract: dict[str, Any]) -> None:
    assert check_rpg_assets.validate_contract(valid_contract) == []


def test_map_atlas_rejects_wrong_row_layout(valid_contract: dict[str, Any]) -> None:
    valid_contract["map_atlas"]["columns"] = 16
    valid_contract["map_atlas"]["rows"] = 1

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "map_atlas.columns must be 8" in failures
    assert "map_atlas.rows must be 2" in failures


def test_map_atlas_rejects_nested_tile_rows(valid_contract: dict[str, Any]) -> None:
    valid_contract["map_atlas"]["tiles"] = [
        BASE_TILE_NAMES,
        DETAIL_TILE_NAMES,
    ]

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "map_atlas.tiles must be a flat row-major list of tile names" in failures


@pytest.mark.parametrize(
    ("tile_index", "replacement", "expected_message"),
    [
        (0, "meadow", "map_atlas.tiles row 0 must preserve"),
        (8, "rushes", "map_atlas.tiles row 1 must be"),
    ],
)
def test_map_atlas_rejects_changed_row_names(
    valid_contract: dict[str, Any],
    tile_index: int,
    replacement: str,
    expected_message: str,
) -> None:
    valid_contract["map_atlas"]["tiles"][tile_index] = replacement

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert any(failure.startswith(expected_message) for failure in failures)


@pytest.mark.parametrize(
    ("first_index", "second_index", "expected_message"),
    [
        (0, 1, "map_atlas.tiles row 0 must preserve"),
        (8, 9, "map_atlas.tiles row 1 must be"),
    ],
)
def test_map_atlas_rejects_reordered_names_within_each_row(
    valid_contract: dict[str, Any],
    first_index: int,
    second_index: int,
    expected_message: str,
) -> None:
    tiles = valid_contract["map_atlas"]["tiles"]
    tiles[first_index], tiles[second_index] = tiles[second_index], tiles[first_index]

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert any(failure.startswith(expected_message) for failure in failures)


@pytest.mark.parametrize(("width", "height"), [(256, 32), (255, 64)])
def test_map_atlas_rejects_wrong_png_dimensions(
    valid_contract: dict[str, Any], width: int, height: int
) -> None:
    _write_png_header(check_rpg_assets.ASSET_DIR / "ferry_tiles.png", width, height)

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert f"ferry_tiles.png: expected (256, 64), got {(width, height)}" in failures
