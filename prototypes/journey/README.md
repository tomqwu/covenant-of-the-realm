# 山河有契 · 行旅之契

![Unit coverage](badges/unit-coverage.svg)
![Critical E2E journeys](badges/e2e-journeys.svg)

一段由选择写成的山河旅程。携一封未署名的旧契，从芦渡出发，穿过松岭、雨泽与故城，在抵达天门关之前决定：人与山河之间的约定，究竟写在纸上，还是记在人心里。

*Covenant of the Road* is a short bilingual, choice-driven browser game. Each journey supports deterministic replay seeds, autosaves locally, works offline after its first production load, and has one of four authored endings.

## Play

Requires Node.js 22.12 or newer.

```sh
npm ci
npm run play
```

This verifies the production artifact, starts a loopback preview, and opens it
in the default browser. Use `npm run dev` instead while editing. Do not open the
repository's `index.html` through `file://`: the source TypeScript and install
worker intentionally run from an HTTP origin. JavaScript is required to run the
choice engine; the production shell gives a bilingual explanation when it is
disabled. No account, backend, or network
connection is required after dependencies are installed.

Controls:

- Click or tap either response.
- With focus in the current story, press `1` or `2` to choose.
- With focus in the current story, press `L` to change language.
- With focus in the completed story, press `R` to replay the same route.
- Reopen any of the five most recent exact routes from the local chronicle; an unfinished journey requires confirmation first.
- Copy a completed journey to share its decisions, resource deltas, selected language, and a one-time exact-route link.
- Download that same completed-journey artifact as local UTF-8 text.
- On supported devices, send that same local artifact through the system share sheet.
- Open Reading settings to opt into ambience, set its volume, or mute it; hidden pages pause without auto-resuming.
- Honor the browser's reduced-data preference by deferring optional audio until explicit play.
- Export or restore a validated local backup from Reading settings.
- Check best-effort storage and explicitly ask the browser for eviction protection.
- Clear every local record through a guarded two-step action.
- If another tab changes local progress, reload the newer state before this tab can write again.

## Game design

Each route contains one deterministic encounter from each of five regions, with all 32 authored combinations reachable. Choices change three visible resources—provisions, trust, and insight—and can unlock later responses. The same route seed always produces the same encounters; replay explicitly retains a saved route, shared links validate and carry the exact five encounter IDs ahead of an unrelated local save, and choices themselves never contain hidden randomness.

Read [the complete game design](docs/GAME_DESIGN.md), [architecture decision](docs/ARCHITECTURE.md), [deployment contract](docs/DEPLOYMENT.md), [security boundary](docs/SECURITY.md), [player privacy contract](docs/PRIVACY.md), [accessibility research](docs/ACCESSIBILITY_RESEARCH.md), and [critical E2E matrix](docs/E2E_COVERAGE.md).

For publication, use the owner/deployment gates in the
[release readiness checklist](docs/RELEASE_CHECKLIST.md); the repository does
not guess a license, security contact, remote, or hosting target.

## Quality commands

```sh
make setup      # install locked dependencies
make play       # build, serve, and open the production game
make check      # typecheck, coverage, E2E, production build, and evidence claims
make lint       # non-test static checks
make test       # unit and browser suites
```

Unit coverage gates are enforced at 99% for statements, branches, functions, and lines. The current verified result is 100% across all four metrics for every production module in `src/game`, `src/ui`, and `src/pwa`; a scope guard rejects an omitted or newly unmeasured module. The browser composition root and service-worker script are intentionally covered at their real integration boundaries by production E2E and the Worker source harness rather than included in that percentage. Playwright covers all 35 named critical player journeys—including all four endings, visible state-gated choices, persistent ending/encounter discovery and exact route recall, canonical/shared/cached-page ownership, resilient clipboard/device/text-file/backup sharing, saved reading preferences, offline and reduced-data installation, background-safe opt-in ambience, route callbacks, browser eviction protection, current and legacy local-backup recovery, restricted/corrupt storage, guarded local-data clearing, and an exact 1440×900 desktop completion—across desktop Chromium plus complete Chinese and English five-region mobile touch runs at 360 px. Saved complete-journey and native text-download checks also pass in Firefox and WebKit. Five additional Axe suites require zero automated accessibility violations across intro, settings, the combined large-text/reduced-motion/high-contrast mode, forced colors at 320 px, cross-tab conflict, encounter, aftermath, and the full English large/high-contrast 320 px ending. A native Tab/Enter/Space journey completes all five regions without pointer or shortcut keys, five deployment audits cover nested-scope installation, same-URL worker updates, failed-update rollback, multi-tab activation ownership, offline resume, blocked workers, and the no-JavaScript explanation, and three security audits prove the local-only runtime boundary. Standard browser contexts also fail on every uncaught page exception. The full browser matrix currently contains 53 passing executions.

Production builds expose an install manifest and versioned offline shell. A
fully cached update is announced in-app and activates only when the player asks
to reload. The same manifest retains a Chinese fallback identity and exposes an
English install identity on browsers that support localized manifest members.
See [install and offline behavior](docs/OFFLINE.md) for the deployment
and cache-update contract.

Backup files stay on the player's device and are strictly validated before the separate restore action is enabled. Browser data begins best-effort; the game checks and requests automatic-eviction protection without overstating it. See [local backup and restore](docs/BACKUP.md) and [storage durability research](docs/STORAGE_DURABILITY_RESEARCH.md).

The badges are repository-local because no GitHub remote is configured yet. `npm run badges:check` requires each SVG's accessible label, title, and visible numeric claim to match the generated unit report plus the documented/automated E2E matrix exactly. The full execution total comes from Playwright's resolved project/test list, so project filters cannot silently make the published claim stale. Once a remote exists, add its dynamic Actions badge without replacing these evidence badges.

## Engineering loop

1. Read `.loop/REQUIREMENTS.md`, `.loop/PLAN.md`, and `.loop/STATE.md`.
2. Choose one small outcome with observable acceptance criteria.
3. Change game behavior and tests together.
4. Run `make check`.
5. Update the loop state for the next contributor.

Repository-specific agent guidance lives in [AGENTS.md](AGENTS.md); human contribution guidance lives in [CONTRIBUTING.md](CONTRIBUTING.md).
