# Player privacy contract

## Short version

The game has no account, analytics, advertising, backend, cookies, or runtime
third-party request. Journey data stays in this browser unless the player
explicitly copies, shares, downloads, or backs it up.

## Data kept on the device

Four versioned browser records contain:

- the current autosaved route, decisions, authored aftermath, resources, and
  selected interface language;
- a bounded chronicle of at most 128 unique completed paths, up to five rendered
  recent routes, and discovered ending/encounter IDs;
- text, motion, and contrast preferences; and
- ambience volume and mute state.

The game uses `localStorage` for those records. A service worker separately uses
Cache Storage for the static HTML, JavaScript, CSS, manifest, icons, landscape,
and optional audio. That offline cache contains no player decisions or backup
contents. A browser may evict best-effort storage; the player can request
origin-wide eviction protection, but the game does not claim permanent storage.

`localStorage` and eviction protection belong to the whole origin, not a URL
subpath. Two copies hosted under different paths of the same scheme/host/port
would share these four player records even though their offline shell caches
have separate scope-aware names. Independent production/staging/review data
therefore requires distinct origins; see
[`STORAGE_SCOPE_RESEARCH.md`](STORAGE_SCOPE_RESEARCH.md).

## Data that can leave the page

Only direct player actions create portable data:

- **Copy** writes the visible completed-journey artifact to the clipboard.
- **Share** passes that same text to the browser/operating-system share sheet;
  the game does not select, observe, or contact the destination.
- **Download journey** creates a local UTF-8 text file through a temporary Blob
  URL.
- **Export progress** creates a local JSON file containing all four records.

Completed artifacts include a route seed, five encounter IDs, selected language,
decisions, resource deltas, aftermaths, final resources, ending, and exact-route
URL. Anyone who receives one can read that information. The exact-route URL in
the address bar contains seed, encounters, and language, but not decisions or
the current resource state. `no-referrer` prevents the document from attaching
that URL as an outbound HTTP referrer.

The app makes no first-party upload. Clipboard, file, and operating-system share
destinations remain under browser and player control.

## Import, restore, and deletion

A selected backup is byte-bounded, parsed, and validated without changing local
data. A separate restore action is required before any record is replaced.
Imported narrative strings are rendered as text, never markup.

**Clear local data** requires two presses and removes all four player records.
It intentionally leaves the non-personal offline asset cache and installed app
shell intact so the game remains playable. Browser site settings or uninstalling
the installed app can remove the origin's remaining static cache.

## Permissions and network boundary

- Clipboard and device sharing are capability-detected and used only on their
  matching player action.
- Ambient audio starts only after its player action and never resumes by itself
  after reload or returning from a hidden page.
- Storage persistence is requested only from its labeled player control.
- All runtime images, audio, scripts, styles, icons, and worker code are
  project-local and same-origin.

The production Content Security Policy blocks remote scripts/assets and inline
script/style execution, and limits connections to same-origin. Vite's loopback
development WebSocket and inline-style permissions exist only while serving
source and are stripped/tightened in the production HTML. The
artifact checker also rejects literal remote URLs in generated HTML, CSS,
manifest values, SVG resource references, app JavaScript, and service-worker
JavaScript; the CSP remains the runtime defense if a URL were assembled
dynamically.

## Verification

- `scripts/check-build.mjs` enforces local/relative production URLs and the
  local-only Content Security Policy.
- S01 proves imported HTML-shaped narrative remains inert.
- S02 proves inline script and dynamic evaluation are blocked while play still
  starts.
- S03 records every HTTP(S) request while settings, audio preparation, complete
  play, persistence, and download run; it requires only the current origin, no
  console/network/policy errors, cookies, session storage, or IndexedDB
  databases, and exactly the four documented local records. It separately
  inspects the one release-owned Cache Storage shell and requires exactly ten
  same-origin, query-free static request keys, so route/player URL data is not
  retained there.
- J18, J19, J21, J23, J31, and J32 cover export/restore, restricted storage,
  clearing, and local-record ownership boundaries through the production UI.
