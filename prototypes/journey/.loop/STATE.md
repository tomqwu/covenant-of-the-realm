# Current state

Last updated: 2026-07-31

## Outcome

《山河有契：行旅之契》 is a complete, playable bilingual browser game. A
deterministic five-region route presents two authored choices per encounter,
visible resource consequences, a persisted aftermath beat, and one of four
reachable endings. The same production artifact works at an origin root or
nested path, installs as a PWA, and resumes offline.

No dedicated UI/game engine is needed. Semantic HTML, CSS, and TypeScript keep
the narrative, keyboard/touch interaction, focus, reflow, persistence, and
screen-reader structure in one testable DOM surface.

Run the real production game locally with `make play` (or `npm run play`). Do
not open the source `index.html` through `file://`.

## Shipped player surface

- Chinese and English journeys, metadata, exact-route URLs, artifacts, and
  install identity; both languages complete by touch at 360 CSS pixels.
- A bilingual semantic fallback explains the JavaScript requirement when
  browser policy disables the game engine; the shell never fails as a blank page.
- Autosave/reload, same-route replay, deterministic non-colliding new routes,
  and guarded recall of five recent exact routes.
- A local chronicle of unique paths, four endings, and all ten encounter
  variants without revealing unseen encounters after an early loss.
- Copy, native share, and filesystem-safe UTC text download for a complete
  replayable journey; every local-export failure retains a selectable fallback.
- Reading scale, reduced motion, high contrast, forced-colors support, a skip
  link, focus-managed story transitions, scoped keyboard shortcuts, and stable
  44×44 CSS-pixel pointer targets. Resource-gated story actions remain keyboard
  discoverable with ARIA-disabled semantics while pointer, Enter, and numeric
  activation stay inert until their requirement passes.
- Explicit opt-in ambience with persistent volume/mute, Save-Data-aware offline
  installation, no constructor-time preload, visibility/conflict cancellation,
  and no automatic resume.
- Validated versioned backup, latest-selection-wins staging, explicit restore,
  atomic best-effort rollback, browser eviction-protection request, and
  consecutive two-action clearing of all four player records. A denied
  pre-mutation snapshot is classified as safely unchanged and performs no write
  or removal.
- One-time shared-route ownership, cross-tab and BFCache stale-page guards, and
  terminal write/async locks while restore or clear reload is pending. The
  cross-tab listener rejects same-named session-storage events before they can
  create a false local-progress conflict.
- Scope-aware offline caches plus an explicit origin-wide player-storage
  contract: independent production/staging copies require distinct origins.

## Engineering guarantees

- Static, account-free, analytics-free, same-origin runtime with no production
  dependency or third-party request. The privacy contract is in
  [`docs/PRIVACY.md`](../docs/PRIVACY.md).
- The build rejects remote/root-absolute dependencies across HTML URL and
  `srcset` attributes, CSS, manifest values, SVG resources, application
  JavaScript, and Worker code.
- Content IDs, translations, effects, requirements, callbacks, route shape,
  lifecycle state, derived stats, and ending reachability fail fast in tests;
  every interface/status message is recursively required to contain non-blank
  Chinese and English text, and resource labels are shared by UI and portable
  artifacts. A shared canonical resource sequence also prevents imported JSON
  property order from changing ledger or artifact presentation. Save validation
  calls the same requirement, effect, and ending functions as live play rather
  than duplicating game rules. Legacy
  entries without a choice ID must infer exactly one authored effect and satisfy
  its live requirement; arbitrary bounded effects cannot create a valid save.
  A valid legacy journal is rewritten once with stable choice IDs so callbacks
  and future chronicle identity regain their normal deterministic behavior.
- The session-length audit traverses all 416 valid paths across all 32 routes,
  separates 288 full journeys from 128 early losses, and gates the exact
  reachable authored-text envelopes without presenting them as observed time.
  It also locks the 160/96/32/128 ending distribution and proves all early
  losses occur after encounter three (96 paths) or four (32 paths), without
  presenting structural path share as player behavior. It also locks the eight
  authored choice IDs that are mechanically Pareto-dominated on visible
  resource deltas, treating that result as playtest input rather than observed
  player preference. The audit parses the research table and rejects stale
  documented IDs.
- All 32 encounter combinations, 20 choices, 1,664 valid terminal paths, four
  endings, and the bounded seed distribution are exhaustively audited.
- Versioned service-worker caches are isolated by scope, behavior schema,
  precache signature, data mode, bundle revision, and a deterministic digest of
  every public path and byte. Installation is atomic;
  generated-shell discovery accepts both HTML quote styles, attribute case, and
  ordinary spacing without admitting cross-origin references;
  fetch interception is limited to same-origin GETs inside that exact scope;
  runtime refresh writes are best-effort; navigation preload does not duplicate
  the network request; client claim precedes best-effort activation cleanup, so
  cache enumeration failure or delay cannot prolong old-tab interactivity;
  exact-route navigations share one canonical cache key; non-initiating tabs
  freeze before old code can run beneath a newly claimed Worker.
- Production output is byte-reproducible across consecutive builds; the
  generated-shell digest cannot churn from unchanged source. The checker allows
  only the source-derived release file set (currently 11 files) and enforces a
  1.1 MB total raw-byte ceiling; manifest icon roles and actual PNG dimensions
  are checked together.
- The core landscape is preloaded once from a relocatable path. Optional audio
  remains gesture-owned. The build checks the hero JPEG's reviewed dimensions
  plus the ambience Ogg/Opus container, tags, stereo channels, and 48 kHz source
  rate. Production CSP strips Vite-only WebSocket/inline-style
  permissions, rejects inline script/style execution, base mutation, objects,
  forms, and frames, and permits same-origin connections only. The build checks
  the complete directive/value set.
- CI actions are immutable-SHA pinned, read-only, and upload seven-day failure
  diagnostics. Dependabot groups bounded npm and workflow updates; lint rejects
  focused, skipped, placeholder, `fixme`, and expected-failure tests across the
  full suite, while CI retries collect diagnostics but still fail any flaky
  browser result.

## Quality baseline

- Unit suite: **121 tests**, exact **100%** statements, branches, functions, and
  lines (1,173 / 869 / 230 / 1,041 at the latest full run) across every game,
  UI, and PWA adapter production module. A filesystem/report comparison rejects
  omitted or newly out-of-scope production modules; browser composition and
  Worker boundaries are covered by production integration evidence.
- Critical browser journeys: **35/35**. They include all endings, exact 1440×900
  desktop completion, complete Chinese/English 360px touch runs, persistence,
  ownership, backup, offline/update, audio, sharing, and failure recovery.
- Additional browser evidence: **18 checks / 53 total browser executions**:
  five zero-violation Axe suites plus a complete native-keyboard journey (including the
  English large-text/high-contrast/reduced-motion combination at 320px and a
  focused low-trust locked-choice/callback state), D01–D05
  deployment/update audits, S01–S03 security audits, and Firefox/WebKit X01/X02
  complete-journey and native-download smoke. Standard contexts fail after each
  journey if any uncaught browser runtime exception was recorded. S03 also
  requires a clean console/network, no cookies/session/IndexedDB, exactly four
  player records, and ten query-free static cache keys.
- Production artifact: 11 files / 958,607 bytes total, including one
  70,068-byte JS bundle, one 18,732-byte stylesheet, 620,433-byte landscape,
  and 180,156-byte optional audio, all within enforced raw-byte budgets.
- Documentation: 55 Markdown files with repository-local links checked.
- Locked dependency audit: zero known vulnerabilities and no outdated direct
  dependency at the latest audit.
- Badges: local numeric claims are parsed against generated coverage and the
  documented/automated E2E matrix; accessible/visible claims are 100% and 35/35,
  and the published 53-execution total is derived from Playwright's resolved
  project/test matrix rather than a hand-maintained multiplier. All 51 named
  checks require unique A/D/J/S/X evidence IDs. Unit count,
  coverage totals, documentation count, and artifact byte claims are likewise
  checked against generated evidence.

## Current queue and next evidence

Every unblocked item in [`docs/ROADMAP.md`](../docs/ROADMAP.md) is complete. The
remaining game-design change is intentionally external-evidence gated. Run the
five-session protocol in
[`docs/PLAYTEST_SCORECARD.md`](../docs/PLAYTEST_SCORECARD.md) without teaching
the interface, then apply at most one threshold that actually passes:

- resource-effect rebalance: 3/5 show delta-driven flattening and deliberate
  differently at the Old City control;
- new vow/decision pattern: 3/5 report axis repetition that includes Old City;
- one-step reconsideration: 2/5 mistaken activations or independent undo asks;
- qualitative resource labels: 3/5 cannot explain resources/gate;
- unseen-biased route prototype: 2/5 spontaneous replays blocked by repetition;
- multiple save slots: 2/5 ask for multiple unfinished routes, with the separate
  duration/scope condition;
- custom install route or any installed-platform integration: 2/5 observed
  failures/attempts for that exact task; and
- delayed-resume recap: 2/5 cannot orient within ten seconds in the optional
  24-hour return probe.

The comparison and kill rules live in
[`docs/COMPARABLE_PATTERN_ROADMAP.md`](../docs/COMPARABLE_PATTERN_ROADMAP.md),
[`docs/PLATFORM_INTEGRATION_ROADMAP.md`](../docs/PLATFORM_INTEGRATION_ROADMAP.md),
[`docs/RESUME_CONTEXT_RESEARCH.md`](../docs/RESUME_CONTEXT_RESEARCH.md), and
[`docs/LOSS_RECOVERY_RESEARCH.md`](../docs/LOSS_RECOVERY_RESEARCH.md). The
direct-choice decision and its escalation rule are recorded separately in
[`docs/CHOICE_COMMITMENT_RESEARCH.md`](../docs/CHOICE_COMMITMENT_RESEARCH.md).
The fixed-route Old City control and separate delta-rebalance/vow gates are in
[`docs/TRADEOFF_RESEARCH.md`](../docs/TRADEOFF_RESEARCH.md).
Do not add screenshots, timestamps, points, save galleries, install buttons, or
checkpoint recovery without the matching evidence, and do not add a confirmation
dialog to every narrative choice as a substitute for observed usability data.

## Blockers

- No GitHub remote exists, so the dynamic Actions badge cannot be configured.
  The workflow and locally verified badges are ready.
- Public release also needs owner choices for licensing, a private vulnerability
  contact, and a final HTTPS host with verified security and cache headers. The
  exact non-simulatable gates are in
  [`docs/RELEASE_CHECKLIST.md`](../docs/RELEASE_CHECKLIST.md).
- A real desktop/mobile screen-reader pass remains an explicit release gate;
  automated Axe/focus evidence is not misreported as assistive-tech validation.
- The remaining product candidates require external participants or a real
  remote. Neither can be honestly simulated by repository code.
- A memory-only leave warning is deliberately rejected pending observed loss;
  it is unreliable on mobile and can weaken back/forward-cache recovery. See
  [`docs/MEMORY_ONLY_EXIT_RESEARCH.md`](../docs/MEMORY_ONLY_EXIT_RESEARCH.md).

## Verification

```sh
make check
```

This is the sole local/CI release gate: hygiene, docs/workflow/content audit,
typecheck, exact unit coverage, the complete browser matrix, badge verification,
production build, and generated verification of the published handoff metrics.

## Decisions in force

- Semantic DOM, no UI/game engine.
- Seeded encounter selection; deterministic player consequences.
- One short autosave; no speculative long-form save UI.
- Player-owned local data and portable artifacts; no backend or telemetry.
- Decorative art/audio never carries required meaning; silent play is complete.
- Small behavior increments must change tests and documentation together.
