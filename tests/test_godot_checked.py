from __future__ import annotations

import os
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[1]
GODOT_CHECKED = REPO_ROOT / "scripts" / "godot_checked"


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

    assert package_script.count('"$repo_root/scripts/godot_checked"') == 1
    assert check_script.count('"$repo_root/scripts/godot_checked"') == 2
