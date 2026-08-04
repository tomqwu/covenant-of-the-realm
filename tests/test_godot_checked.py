from __future__ import annotations

import hashlib
import os
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[1]
GODOT_CHECKED = REPO_ROOT / "scripts" / "godot_checked"
REFERENCE_CAPTURE_DIRECTORY = REPO_ROOT / "docs" / "concepts" / "gameplay-ui-v1"
REFERENCE_CAPTURE_FILENAMES = (
    "00-actor-scale-test.png",
    "01-accessible-dialogue.png",
    "01-basket-returned.png",
    "01-companion-dialogue.png",
    "01-companion-following.png",
    "01-dialogue-journal.png",
    "01-dialogue-speed-setting.png",
    "01-ferry-watermark.png",
    "01-ferryman-choice.png",
    "01-ferryman-dialogue.png",
    "01-ferryman-repaired.png",
    "01-herbkeeper-choice.png",
    "01-herbkeeper-dialogue.png",
    "01-journey-journal.png",
    "01-moonleaf-choice.png",
    "01-moonleaf-regrowth.png",
    "01-new-game-confirmation.png",
    "01-patrol-boat-reaction.png",
    "01-patrol-choice.png",
    "01-patrol-herbs-reaction.png",
    "01-patrol-runner.png",
    "01-portrait-gallery.png",
    "01-protagonist-dialogue.png",
    "01-scene-transition.png",
    "01-title-screen.png",
    "01-y-depth-occlusion.png",
    "01-zhaohe-ferry.png",
    "02-cangquan-battle-react.png",
    "02-cangquan-battle.png",
    "02-cangquan-boss.png",
    "02-cangquan-enemy-defeat.png",
    "02-cangquan-moss-battle.png",
    "02-cangquan-path.png",
    "02-cangquan-puppet-battle.png",
    "02-enemy-intel-journal.png",
    "02-enemy-spoors.png",
    "02-path-discoveries.png",
    "02-path-keeper-route.png",
    "03-moonleaf-warmed.png",
    "03-spring-chamber.png",
    "03-spring-listened.png",
    "04-chapter-epilogue.png",
    "04-first-breath.png",
)
REFERENCE_CAPTURE_AGGREGATE_SHA256 = (
    "153ee23c5cbf0a6208fd9853b2722e7fb032ef2539468a210b47ffa8278568b4"
)


def _run_checked(tmp_path: Path, body: str, *arguments: str) -> subprocess.CompletedProcess[str]:
    fake_godot = tmp_path / "fake-godot"
    fake_godot.write_text(
        "#!/usr/bin/env bash\nset -uo pipefail\n" + body,
        encoding="utf-8",
    )
    fake_godot.chmod(0o755)
    environment = os.environ.copy()
    environment["COVENANT_GODOT_RUNNER"] = str(fake_godot)
    return subprocess.run(
        [str(GODOT_CHECKED), *arguments],
        check=False,
        capture_output=True,
        env=environment,
        text=True,
    )


def test_checked_runner_streams_output_and_forwards_arguments(tmp_path: Path) -> None:
    completed = _run_checked(
        tmp_path,
        'printf "stdout:%s\\n" "$1"\nprintf "stderr:%s\\n" "$2" >&2\n',
        "alpha",
        "beta",
    )

    assert completed.returncode == 0
    assert "stdout:alpha" in completed.stdout
    assert "stderr:beta" in completed.stdout
    assert completed.stderr == ""


def test_checked_runner_preserves_real_nonzero_exit_code(tmp_path: Path) -> None:
    completed = _run_checked(
        tmp_path,
        'printf "SCRIPT ERROR: real failure\\n" >&2\nexit 23\n',
    )

    assert completed.returncode == 23
    assert "SCRIPT ERROR: real failure" in completed.stdout
    assert "fatal script diagnostics" not in completed.stderr


@pytest.mark.parametrize(
    "diagnostic",
    [
        "SCRIPT ERROR: Parse Error: Expected statement.",
        "ERROR: Failed to load script res://tests/test_runner.gd with error Parse error.",
        "Parse Error: Could not resolve class PatrolState.",
    ],
)
def test_checked_runner_fails_on_fatal_script_diagnostic_with_zero_exit(
    tmp_path: Path,
    diagnostic: str,
) -> None:
    completed = _run_checked(tmp_path, f"printf '%s\\n' '{diagnostic}'\n")

    assert completed.returncode == 1
    assert diagnostic in completed.stdout
    assert (
        "fatal script diagnostics were emitted despite a zero process exit code"
        in completed.stderr
    )


def test_checked_runner_does_not_fail_on_unrelated_engine_error_text(tmp_path: Path) -> None:
    completed = _run_checked(tmp_path, 'printf "ERROR: optional audio device unavailable\\n"\n')

    assert completed.returncode == 0


def _make_target_body(makefile: str, target: str) -> str:
    marker = f"{target}:"
    return makefile.split(marker, 1)[1].split("\n\n", 1)[0]


def _shasum_listing_aggregate(paths: tuple[Path, ...]) -> str:
    aggregate = hashlib.sha256()
    for path in paths:
        relative_path = path.relative_to(REPO_ROOT).as_posix()
        file_hash = hashlib.sha256(path.read_bytes()).hexdigest()
        # Match `shasum -a 256 files | shasum -a 256`: two spaces and LF.
        aggregate.update(f"{file_hash}  {relative_path}\n".encode())
    return aggregate.hexdigest()


@pytest.mark.parametrize(
    "target",
    [
        "rpg-import-assets",
        "capture-rpg-ui",
        "test-rpg",
        "test-rpg-e2e",
        "test-rpg-input",
        "test-rpg-performance",
    ],
)
def test_make_target_uses_checked_godot_gate(target: str) -> None:
    makefile = (REPO_ROOT / "Makefile").read_text(encoding="utf-8")

    assert "./scripts/godot_checked" in _make_target_body(makefile, target)


def test_package_scripts_use_checked_godot_gate() -> None:
    package_script = (REPO_ROOT / "scripts" / "package_rpg").read_text(encoding="utf-8")
    check_script = (REPO_ROOT / "scripts" / "check_rpg_package").read_text(encoding="utf-8")
    project_settings = (REPO_ROOT / "rpg" / "project.godot").read_text(encoding="utf-8")

    assert package_script.count('"$repo_root/scripts/godot_checked"') == 1
    assert check_script.count('"$repo_root/scripts/godot_checked"') == 4
    assert package_script.count("scripts/rpg_package_manifest.py") == 1
    assert "--source-revision" in package_script
    assert "--source-tree-state" in package_script
    assert check_script.count('"$repo_root/scripts/package_rpg"') == 2
    assert "command -v rsync" in check_script
    assert check_script.count("rsync -a --exclude '.godot/'") == 2
    assert check_script.count('--export-pack "Playable Pack"') == 2
    assert (
        '--path "$fresh_first_project" \\\n  --export-pack "Playable Pack" "$fresh_first_pack"'
        in check_script
    )
    assert (
        '--path "$fresh_second_project" \\\n  --export-pack "Playable Pack" "$fresh_second_pack"'
        in check_script
    )
    assert 'cmp "$first_pack" "$second_pack"' in check_script
    assert 'cmp "$first_pack" "$fresh_first_pack"' in check_script
    assert 'cmp "$fresh_first_pack" "$fresh_second_pack"' in check_script
    assert 'cmp "$first_manifest" "$second_manifest"' in check_script
    assert "scripts/rpg_package_manifest.py" in check_script
    assert "--verify" in check_script
    assert 'data["build_os"] + "/" + data["build_architecture"]' in check_script
    assert "export/convert_text_resources_to_binary=false" in project_settings


def test_asset_reproducibility_and_capture_contract_include_transient_battle_roles() -> None:
    reproducibility_script = (
        REPO_ROOT / "scripts" / "check_rpg_asset_reproducibility"
    ).read_text(encoding="utf-8")
    capture_script = (REPO_ROOT / "rpg" / "tools" / "capture_ui.gd").read_text(
        encoding="utf-8"
    )

    assert "  cenwei.png\n" in reproducibility_script
    assert capture_script.count("await _save_frame(") == 43
    assert (
        'await _save_frame("02-path-keeper-route.png", false, true)'
        in capture_script
    )
    assert 'await _save_frame("02-cangquan-enemy-defeat.png")' in capture_script
    assert "outgoing_enemy_defeat_contract()" in capture_script
    assert "attack_accent_contract()" in capture_script
    assert 'float(attack_accent["duration"]) * 0.5' in capture_script
    assert "defeat_attack_accent" in capture_script


def test_reference_capture_set_and_aggregate_are_locked() -> None:
    captures = tuple(
        sorted(REFERENCE_CAPTURE_DIRECTORY.glob("*.png"), key=lambda path: path.name)
    )

    assert tuple(path.name for path in captures) == REFERENCE_CAPTURE_FILENAMES
    assert _shasum_listing_aggregate(captures) == REFERENCE_CAPTURE_AGGREGATE_SHA256
