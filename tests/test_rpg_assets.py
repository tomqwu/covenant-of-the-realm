from __future__ import annotations

import json
import shutil
import struct
import zlib
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


def _png_chunk(chunk_type: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(data, zlib.crc32(chunk_type)) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + chunk_type + data + struct.pack(">I", crc)


def _write_png(
    path: Path,
    width: int,
    height: int,
    *,
    color_type: int = 6,
    compressed_data: bytes | None = None,
) -> None:
    channels = 4 if color_type == 6 else 3
    ihdr = struct.pack(">IIBBBBB", width, height, 8, color_type, 0, 0, 0)
    if compressed_data is None:
        rows = (b"\x00" + bytes(width * channels)) * height
        compressed_data = zlib.compress(rows)
    path.write_bytes(
        check_rpg_assets.PNG_SIGNATURE
        + _png_chunk(b"IHDR", ihdr)
        + _png_chunk(b"IDAT", compressed_data)
        + _png_chunk(b"IEND", b"")
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
    _write_png(tmp_path / "ferry_tiles.png", 256, 64)
    _write_png(tmp_path / "zhaohe_landmarks.png", 2112, 128)
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
    _write_png(check_rpg_assets.ASSET_DIR / "ferry_tiles.png", width, height)

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert f"ferry_tiles.png: expected (256, 64), got {(width, height)}" in failures


def test_landmark_atlas_accepts_exact_profile_contract(
    valid_contract: dict[str, Any],
) -> None:
    assert valid_contract["schema_version"] == 3
    assert valid_contract["landmark_atlas"]["profiles"] == LANDMARK_PROFILES
    assert check_rpg_assets.validate_contract(valid_contract) == []


def test_landmark_atlas_requires_an_object(valid_contract: dict[str, Any]) -> None:
    valid_contract["landmark_atlas"] = []

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "landmark_atlas must be an object" in failures


@pytest.mark.parametrize(
    ("field", "value", "expected_message"),
    [
        ("frame_size_px", [128, 128], "landmark_atlas.frame_size_px must be [192, 128]"),
        ("foot_anchor_px", [95, 127], "landmark_atlas.foot_anchor_px must be [96, 127]"),
        ("columns", 4, "landmark_atlas.columns must be 11"),
        ("rows", 2, "landmark_atlas.rows must be 1"),
        ("texture_filter", "linear", "landmark_atlas.texture_filter must be nearest"),
        ("pixel_snap", False, "landmark_atlas.pixel_snap must be true"),
        ("collision_authority", True, "landmark_atlas.collision_authority must be false"),
        ("profiles", list(reversed(LANDMARK_PROFILES)), "landmark_atlas.profiles must match"),
        (
            "occluding_profiles",
            LANDMARK_PROFILES,
            "landmark_atlas.occluding_profiles must contain only tree and house IDs",
        ),
    ],
)
def test_landmark_atlas_rejects_changed_metadata(
    valid_contract: dict[str, Any],
    field: str,
    value: Any,
    expected_message: str,
) -> None:
    valid_contract["landmark_atlas"][field] = value

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert any(failure.startswith(expected_message) for failure in failures)


@pytest.mark.parametrize("file_name", [None, "../zhaohe_landmarks.png"])
def test_landmark_atlas_rejects_nonlocal_file_names(
    valid_contract: dict[str, Any], file_name: Any
) -> None:
    valid_contract["landmark_atlas"]["file"] = file_name

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "landmark_atlas.file must be a local file name" in failures


def test_landmark_atlas_rejects_a_missing_file(valid_contract: dict[str, Any]) -> None:
    valid_contract["landmark_atlas"]["file"] = "missing_landmarks.png"

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "missing landmark atlas: missing_landmarks.png" in failures


@pytest.mark.parametrize(("width", "height"), [(2112, 127), (2111, 128)])
def test_landmark_atlas_rejects_wrong_png_dimensions(
    valid_contract: dict[str, Any], width: int, height: int
) -> None:
    _write_png(check_rpg_assets.ASSET_DIR / "zhaohe_landmarks.png", width, height)

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert (
        f"zhaohe_landmarks.png: expected (2112, 128), got {(width, height)}"
        in failures
    )


def test_landmark_atlas_rejects_an_invalid_png(valid_contract: dict[str, Any]) -> None:
    (check_rpg_assets.ASSET_DIR / "zhaohe_landmarks.png").write_bytes(b"not-png")

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "zhaohe_landmarks.png: not a valid PNG signature" in failures


def test_landmark_atlas_rejects_a_truncated_png(valid_contract: dict[str, Any]) -> None:
    path = check_rpg_assets.ASSET_DIR / "zhaohe_landmarks.png"
    path.write_bytes(path.read_bytes()[:24])

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "zhaohe_landmarks.png: truncated PNG chunk" in failures


def test_landmark_atlas_rejects_a_bad_chunk_crc(valid_contract: dict[str, Any]) -> None:
    path = check_rpg_assets.ASSET_DIR / "zhaohe_landmarks.png"
    data = bytearray(path.read_bytes())
    data[-1] ^= 1
    path.write_bytes(data)

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "zhaohe_landmarks.png: PNG chunk CRC mismatch: IEND" in failures


def test_landmark_atlas_rejects_non_rgba8_pixels(valid_contract: dict[str, Any]) -> None:
    _write_png(
        check_rpg_assets.ASSET_DIR / "zhaohe_landmarks.png",
        2112,
        128,
        color_type=2,
    )

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "zhaohe_landmarks.png: PNG must use 8-bit RGBA pixels" in failures


def test_landmark_atlas_rejects_invalid_compressed_pixels(
    valid_contract: dict[str, Any],
) -> None:
    _write_png(
        check_rpg_assets.ASSET_DIR / "zhaohe_landmarks.png",
        2112,
        128,
        compressed_data=b"not-zlib",
    )

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "zhaohe_landmarks.png: invalid PNG image data" in failures
