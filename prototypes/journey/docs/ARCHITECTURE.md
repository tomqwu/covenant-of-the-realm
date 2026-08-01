# Architecture

## Decision: no dedicated UI or game engine

The game is a compact, choice-driven state machine. A scene graph, physics loop,
or canvas-only UI would make accessibility and browser testing harder without
adding useful capability. The application therefore uses:

- TypeScript for deterministic game rules and persistence validation.
- Semantic HTML and CSS for the playable interface.
- Vite for development and production builds.
- Vitest for unit and DOM integration tests.
- Playwright for the full Chromium desktop/mobile matrix plus bounded Firefox
  and WebKit compatibility smoke.
- A dependency-free manifest and service worker for installable offline play.
- A relative Vite base plus artifact check for root or nested static hosting.

The generated ink landscape is presentation only. Game meaning never depends on
pixels in the image, so all interactions remain available to assistive
technology and deterministic tests.

## Boundaries

- `src/game/` owns content, state transitions, seeding, and serialization.
- `src/ui/` renders state and converts user intent into game actions.
- `src/main.ts` is the browser composition root.
- `src/pwa/` owns the testable waiting-worker/update lifecycle adapter.
- `e2e/` verifies complete player journeys, persistence, input methods, and
  responsive behavior.
- `public/sw.js` owns the versioned production shell cache; its lifecycle and
  deployment contract are documented in `docs/OFFLINE.md`.

The Worker source contains a single release placeholder. During production
output, Vite replaces it with a SHA-256 prefix of the final generated entry
document. That document includes the hashed app/style filenames and public-tree
revision, leaving the registration path stable while making every
shell/app/style/public release byte-distinct. The post-build verifier permits only that one
public-file transformation and proves every other copied public byte unchanged.

Game modules do not access the DOM or global storage. UI code receives those
dependencies explicitly, keeping the rules fast and independently testable.
Persisted-state validation reuses the engine's requirement, effect, and ending
functions, preventing load-time coherence rules from drifting away from live
play while retaining a separate strict structural boundary for imported JSON.
The four-key player-record list is likewise one exported contract shared by
backup snapshot/restore, clearing, BFCache signatures, and storage-event
filtering.
The browser composition root wraps persistent storage with an in-memory mirror;
read or write denial changes the advertised persistence capability without
interrupting state transitions. Backup restoration still targets the underlying
persistent store transactionally and is disabled after capability loss. The UI
owns a raw snapshot of the four player records and refreshes it after each
in-app write. A persisted page restoration compares that snapshot before
re-enabling a cached document, extending the storage-event ownership guard to
changes missed while the page was frozen. Controller replacement follows the
same boundary: only the tab that explicitly applies a waiting Worker reloads
immediately; other controlled tabs freeze behind an explicit reload dialog so
old application code cannot continue beneath a newly claimed cache.

That writable-store capability is intentionally separate from browser eviction
protection. When the Storage Manager API exists, the composition root injects
`persisted()` and `persist()` behind a player-action boundary. The UI checks the
first asynchronously, calls the second only from its explicit settings control,
and keeps local JSON export as the cross-browser ownership path. See
[`STORAGE_DURABILITY_RESEARCH.md`](STORAGE_DURABILITY_RESEARCH.md).

Persisted journal prose is data, not markup. The UI HTML-escapes every persisted
place, choice, aftermath, and generated share summary before assigning the
render tree; S01 verifies this trust boundary in production Chromium.

Authored data follows the invariant set in `docs/CONTENT_AUTHORING.md`; tests
validate ID stability, translation completeness, region shape, effects, and
callback coverage before a content edit can ship. Resource names are shared
game vocabulary used by both the rendered interface and portable journey
artifacts, so their Chinese/English labels cannot diverge.

## Coverage boundary

The generated unit percentage includes every production TypeScript module in
`src/game/`, `src/ui/`, and `src/pwa/`. A post-coverage scope check compares the
report with the filesystem and fails if one of those modules is absent or if a
new production module is placed outside those audited directories. This makes
the 100% claim precise and prevents a configuration edit from silently making
the denominator smaller.

`src/main.ts` remains a thin browser composition root and `public/sw.js` is a
browser Worker program. Their meaningful behavior depends on browser globals,
HTTP scope, Cache Storage, navigation, and controller changes, so the production
Playwright matrix owns those boundaries. The Worker additionally runs in a VM
source harness for activation-cleanup failures. Neither file is represented as
part of the unit-coverage percentage.
