# RPG implementation instructions

These instructions apply under `rpg/`.

1. Read `docs/design/RPG_FOUNDATION_v0.1.md` before changing rules or content.
2. Keep all production story content original. Never paste reference prose, characters,
   locations, proprietary items, or distinctive plot combinations into this tree.
3. Keep deterministic rules in `src/domain/`; do not make UI nodes authoritative.
4. Put display prose and action labels in validated files under `content/`.
5. Add headless tests for every rule branch and a scene smoke test for behavior changes.
6. Run `make check-rpg` from the repository root before finishing an RPG change.
7. Record every external asset or plugin in `docs/ASSET_PROVENANCE.md` before use.
