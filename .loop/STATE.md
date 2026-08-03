# Loop State

## Current outcome

- Repository: `/Users/tomwu/Projects/covenant-of-the-realm`
- Branch: `codex/rpg-foundation`
- Draft PR: <https://github.com/tomqwu/covenant-of-the-realm/pull/7>
- Current clean base is pushed head `4fd9d14da391fa76a9dcd5b0c78d936ca7815629`; the package-
  provenance candidate is reviewed and ready to commit. The last confirmed remote `main` remains
  `7256ade54792ff481ffc30517ca2c693f78be198` and must not be merged without authorization.
- Manifest schema v2 records normalized `build_os` / `build_architecture`, keeps exact schema-v1
  verification, and rejects partial, unknown, noncanonical, wrong-type, future-schema, and unexpected
  fields. It records build provenance, not a selected native release target.
- Final local `make check` passes: 152 Python tests at 100% statement/branch coverage (600 statements /
  306 branches), 21 Evennia integration tests plus the real two-client journey, 2,716 Godot rule/scene
  assertions, 330 chapter E2E checks, 169 physical-input checks, 122 browser unit tests at 100%, 53
  Playwright executions, badges, and reproducible browser output.
- Godot lifecycle passes in `886.56` ms for 20 complete 13-state cycles, one dialogue reveal probe,
  four settings writes, 114 static / 124 peak nodes, and zero root leaks.
- The real `macos/arm64` package gate double-exports an identical 697,160-byte PCK at SHA-256
  `2f1c122199227f9c9a02537a4b9311c44f8ed03285c8b87267c995b6e45cf5a5`, verifies both manifests,
  requires 22 runtime resources, excludes nine development resources, and boots headlessly. Existing
  Linux evidence is the same size at SHA-256
  `1b8a4a14b9e72fb5352711bda70794203627b476221abdc789f31da38c605713`; schema-v2 hosted evidence
  awaits the candidate push.

## Next action

Commit and push the reviewed candidate, monitor all Draft PR #7 checks, refresh the ignored package
from the resulting clean head, update the PR body and closeout state, and keep `main` unchanged.

## Blockers

No current engineering blocker. Native `.app` / `.exe` packaging remains intentionally blocked on
owner decisions for the first platform, templates, signing, icon, license, and distribution target.

## Exact verification

```sh
uv run python -m pytest -q tests/test_rpg_package_manifest.py tests/test_godot_checked.py
make check-rpg
make check
```
