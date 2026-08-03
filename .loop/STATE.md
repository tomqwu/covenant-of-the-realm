# Loop State

## Current outcome

- Repository: `/Users/tomwu/Projects/covenant-of-the-realm`
- Branch: `codex/rpg-foundation`
- Draft PR: <https://github.com/tomqwu/covenant-of-the-realm/pull/7>
- Clean-cache implementation head `f5c60e2fcc2ec6806e1434bac01a40f16551c2ec` is pushed. Actions run
  `30862795331` attempt 1 is green across MUD, multiplayer, RPG, and Journey; its independently rerun
  RPG job in attempt 2 is also green. The last confirmed remote `main` remains
  `7256ade54792ff481ffc30517ca2c693f78be198` and must not be merged without authorization.
- Manifest schema v2 records normalized `build_os` / `build_architecture`, keeps exact schema-v1
  verification, and rejects partial, unknown, noncanonical, wrong-type, future-schema, and unexpected
  fields. It records build provenance, not a selected native release target.
- The schema-v2 base passed local `make check`: 152 Python tests at 100% statement/branch coverage (600 statements /
  306 branches), 21 Evennia integration tests plus the real two-client journey, 2,716 Godot rule/scene
  assertions, 330 chapter E2E checks, 169 physical-input checks, 122 browser unit tests at 100%, 53
  Playwright executions, badges, and reproducible browser output.
- Its Godot lifecycle passed in `886.56` ms for 20 complete 13-state cycles, one dialogue reveal probe,
  four settings writes, 114 static / 124 peak nodes, and zero root leaks.
- Three equal-source Linux runs and independent local worktrees proved that the old 697,160-byte PCK
  changed across empty import caches even though sequential exports sharing one cache matched. Entry
  comparison isolated all drift to Godot's generated binary `main.scn`; the other 60 entries matched.
- The fix sets `editor/export/convert_text_resources_to_binary=false` and extends the package gate to
  two normal exports plus two independent empty-cache project copies. For the packaged runtime inputs
  committed in `f5c60e2`, all four local macOS/arm64 PCKs and all four PCKs in each of two independent
  hosted Linux/x86_64 RPG job attempts match at 709,100 bytes and SHA-256
  `e8308c22cda27e45b73fcf35e4fbb37587a266ead18d7be5c277c0864d74d351`; strict manifests, 22/9
  content probing, and headless boot pass. The hosted lifecycle samples were `5,771.41` ms and
  `5,912.40` ms. This controlled same-input cross-OS PCK observation is not a future identity promise;
  manifests remain per-build provenance artifacts.
- Local `make check` is green with the same 152 / 600 / 306 Python coverage and one `929.22` ms
  lifecycle sample. The implementation has been independently audited for code, scope, tests, and
  documentation with no blocking findings.

## Next action

Begin the next unblocked gameplay-density loop after this evidence closeout is pushed and its checks
are monitored. Keep the ignored package and Draft PR body current while leaving `main` unchanged.

## Blockers

No current engineering blocker. Native `.app` / `.exe` packaging remains intentionally blocked on
owner decisions for the first platform, templates, signing, icon, license, and distribution target.

## Exact verification

```sh
uv run python -m pytest -q tests/test_rpg_package_manifest.py tests/test_godot_checked.py
make check-rpg
make check
```
