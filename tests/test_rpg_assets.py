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
ACTOR_ATLASES = [
    "protagonist.png",
    "yanqing.png",
    "liangshu.png",
    "huishen.png",
    "tao_xiaoman.png",
    "cenwei.png",
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
ENEMY_PROFILES = [
    "rock_armor_young",
    "spring_moss_shell",
    "unbalanced_stone_puppet",
    "rock_armor_warden",
]
ENEMY_ANIMATIONS = {
    "idle": {"columns": [0, 1], "fps": 2.5, "loop": True},
    "attack": {"columns": [2, 3], "fps": 8.0, "loop": False},
    "react": {"columns": [4, 5], "fps": 7.0, "loop": False},
    "defeat": {"columns": [6, 7], "fps": 6.0, "loop": False},
}


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


def _write_rgba_png(path: Path, width: int, height: int, pixels: bytes) -> None:
    stride = width * 4
    assert len(pixels) == stride * height
    rows = b"".join(b"\x00" + pixels[row * stride : (row + 1) * stride] for row in range(height))
    _write_png(path, width, height, compressed_data=zlib.compress(rows))


def _copy_enemy_cell(
    pixels: bytearray,
    atlas_width: int,
    source_column: int,
    target_column: int,
    row: int,
) -> None:
    for local_y in range(64):
        source = ((row * 64 + local_y) * atlas_width + source_column * 64) * 4
        target = ((row * 64 + local_y) * atlas_width + target_column * 64) * 4
        pixels[target : target + 64 * 4] = pixels[source : source + 64 * 4]


@pytest.fixture
def valid_contract(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> dict[str, Any]:
    source_asset_dir = check_rpg_assets.ASSET_DIR
    data = json.loads(check_rpg_assets.CONTRACT_PATH.read_text(encoding="utf-8"))
    data["map_atlas"] = {
        "file": "ferry_tiles.png",
        "tile_size_px": [32, 32],
        "columns": 8,
        "rows": 2,
        "map_size_tiles": [48, 27],
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


def test_schema_seven_accepts_six_actor_atlases_and_cenwei(
    valid_contract: dict[str, Any],
) -> None:
    assert valid_contract["schema_version"] == 7
    assert valid_contract["atlases"] == ACTOR_ATLASES
    assert check_rpg_assets._png_size(check_rpg_assets.ASSET_DIR / "cenwei.png") == (128, 224)
    assert check_rpg_assets.validate_contract(valid_contract) == []


def test_actor_atlas_contract_rejects_old_schema_and_changed_roster(
    valid_contract: dict[str, Any],
) -> None:
    valid_contract["schema_version"] = 6
    valid_contract["atlases"] = ACTOR_ATLASES[:-1]

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "schema_version must be 7" in failures
    assert "atlases must match the six stable actor IDs" in failures


def test_actor_atlas_contract_rejects_wrong_cenwei_dimensions(
    valid_contract: dict[str, Any],
) -> None:
    _write_png(check_rpg_assets.ASSET_DIR / "cenwei.png", 127, 224)

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "cenwei.png: expected (128, 224), got (127, 224)" in failures


def test_enemy_atlas_accepts_semantic_animation_contract(
    valid_contract: dict[str, Any],
) -> None:
    enemy_atlas = valid_contract["enemy_atlas"]

    assert enemy_atlas["profiles"] == ENEMY_PROFILES
    assert enemy_atlas["animations"] == ENEMY_ANIMATIONS
    assert check_rpg_assets._png_size(check_rpg_assets.ASSET_DIR / "enemy_profiles.png") == (
        512,
        256,
    )
    assert enemy_atlas["outgoing_presentation"] == {
        "animation": "defeat",
        "events": ["regular_enemy_won"],
        "rule_authority": False,
        "gameplay_timing_authority": False,
        "save_authority": False,
    }
    assert check_rpg_assets.validate_contract(valid_contract) == []


def test_enemy_atlas_rejects_identical_defeat_frames(
    valid_contract: dict[str, Any],
) -> None:
    path = check_rpg_assets.ASSET_DIR / "enemy_profiles.png"
    width, height, raw_pixels = check_rpg_assets._png_rgba_pixels(path)
    pixels = bytearray(raw_pixels)
    _copy_enemy_cell(pixels, width, 6, 7, 0)
    _write_rgba_png(path, width, height, pixels)

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "enemy defeat frames for rock_armor_young must be visibly distinct" in failures


def test_enemy_atlas_rejects_empty_defeat_frame(
    valid_contract: dict[str, Any],
) -> None:
    path = check_rpg_assets.ASSET_DIR / "enemy_profiles.png"
    width, height, raw_pixels = check_rpg_assets._png_rgba_pixels(path)
    pixels = bytearray(raw_pixels)
    for local_y in range(64):
        start = ((2 * 64 + local_y) * width + 6 * 64) * 4
        pixels[start : start + 64 * 4] = bytes(64 * 4)
    _write_rgba_png(path, width, height, pixels)

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "enemy defeat frame unbalanced_stone_puppet:0 must remain visibly populated" in failures


def test_enemy_atlas_rejects_defeat_cell_spill(
    valid_contract: dict[str, Any],
) -> None:
    path = check_rpg_assets.ASSET_DIR / "enemy_profiles.png"
    width, height, raw_pixels = check_rpg_assets._png_rgba_pixels(path)
    pixels = bytearray(raw_pixels)
    boundary = ((1 * 64 + 32) * width + 6 * 64 + 63) * 4
    pixels[boundary : boundary + 4] = bytes((255, 255, 255, 255))
    _write_rgba_png(path, width, height, pixels)

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert (
        "enemy defeat frame spring_moss_shell:0 must keep a transparent one-pixel cell border"
        in failures
    )


def test_enemy_atlas_requires_an_object(valid_contract: dict[str, Any]) -> None:
    valid_contract["enemy_atlas"] = []

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "enemy_atlas must be an object" in failures


@pytest.mark.parametrize(
    ("field", "value", "expected_message"),
    [
        ("frame_size_px", [32, 64], "enemy_atlas.frame_size_px must be [64, 64]"),
        ("foot_anchor_px", [31, 56], "enemy_atlas.foot_anchor_px must be [32, 56]"),
        ("columns", 6, "enemy_atlas.columns must be 8"),
        ("rows", 3, "enemy_atlas.rows must be 4"),
        (
            "animations",
            {"idle": ENEMY_ANIMATIONS["idle"]},
            "enemy_atlas.animations must match idle, attack, react, and defeat slots",
        ),
        (
            "semantic_events",
            {"react": ["enemy_hit"]},
            "enemy_atlas.semantic_events must match battle event priority groups",
        ),
        (
            "terminal_suppression",
            ["battle_won"],
            "enemy_atlas.terminal_suppression must match battle transitions",
        ),
        (
            "outgoing_presentation",
            {"animation": "react", "events": ["regular_enemy_won"]},
            "enemy_atlas.outgoing_presentation must keep defeat presentation-only",
        ),
        ("texture_filter", "linear", "enemy_atlas.texture_filter must be nearest"),
        ("pixel_snap", False, "enemy_atlas.pixel_snap must be true"),
        ("gameplay_authority", True, "enemy_atlas.gameplay_authority must be false"),
        (
            "profiles",
            list(reversed(ENEMY_PROFILES)),
            "enemy_atlas.profiles must match the four stable enemy IDs",
        ),
    ],
)
def test_enemy_atlas_rejects_changed_metadata(
    valid_contract: dict[str, Any],
    field: str,
    value: Any,
    expected_message: str,
) -> None:
    valid_contract["enemy_atlas"][field] = value

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert expected_message in failures


@pytest.mark.parametrize("file_name", [None, "../enemy_profiles.png"])
def test_enemy_atlas_rejects_nonlocal_file_names(
    valid_contract: dict[str, Any], file_name: Any
) -> None:
    valid_contract["enemy_atlas"]["file"] = file_name

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "enemy_atlas.file must be a local file name" in failures


def test_enemy_atlas_rejects_a_missing_file(valid_contract: dict[str, Any]) -> None:
    valid_contract["enemy_atlas"]["file"] = "missing_enemy.png"

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert "missing enemy atlas: missing_enemy.png" in failures


@pytest.mark.parametrize(("width", "height"), [(511, 256), (512, 255)])
def test_enemy_atlas_rejects_wrong_png_dimensions(
    valid_contract: dict[str, Any], width: int, height: int
) -> None:
    _write_png(
        check_rpg_assets.ASSET_DIR / "enemy_profiles.png",
        width,
        height,
    )

    failures = check_rpg_assets.validate_contract(valid_contract)

    assert f"enemy_profiles.png: expected (512, 256), got {(width, height)}" in failures


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

    assert f"zhaohe_landmarks.png: expected (2112, 128), got {(width, height)}" in failures


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
