# Install and offline behavior

The production build is an installable progressive web app. Development mode
does not register a service worker, so code changes are never hidden behind a
local runtime cache.

Browsers or policies that block service workers retain the complete online game,
local autosave, and reload-resume path; only install/offline behavior is absent.

## First installation

On first production load, `sw.js` opens a build- and data-mode-isolated shell
cache and stores:

- the rendered entry page;
- the JavaScript and CSS files referenced by that page;
- the web app manifest and 192px, 512px, and scalable icons;
- the project-local landscape asset; and
- by default, the optional project-local ambient loop, so choosing sound later
  does not create a runtime network dependency.

The generated-page discovery accepts either HTML quote style, case-insensitive
`src`/`href` names, and ordinary spacing around `=`. Only resolved same-origin
references join the fixed core list; build-time checks separately reject remote
or root-absolute production references.

When `navigator.connection.saveData` is explicitly true, the worker URL carries
`saveData=1`, its cache identity uses `reduced`, and initial installation omits
the 180 KB optional loop. The core game remains complete and offline. If that
player later presses Play while online, the app fetches the full audio file and
the worker adds it cache-first; later offline playback then works. A failed
first opt-in stays on the existing honest silent path. Browsers without this
limited-availability signal keep the full default rather than guessing from
connection speed.

The manifest provides the app identity, standalone display mode, matching
document/launch theme colors,
scope, start URL, and the raster icon sizes required by Chromium install flows.
Its Chinese identity remains the universal fallback, while supporting browsers
can select localized English name, short-name, and description members from the
same static file. This progressive contract and its browser-language boundary
are recorded in
[`MANIFEST_LOCALIZATION_RESEARCH.md`](MANIFEST_LOCALIZATION_RESEARCH.md).
Ordinary rounded icons and an opaque 512px adaptive icon have separate `any`
and `maskable` purposes; see
[`MASKABLE_ICON_RESEARCH.md`](MASKABLE_ICON_RESEARCH.md).
The same full-bleed local asset is the explicit iOS Home Screen icon, with a
relative URL that remains inside a nested deployment.
Production hosting must use HTTPS; loopback addresses remain valid for local
verification.

## Request and update strategy

- The fetch handler responds only to same-origin `GET` requests whose resolved
  URL remains inside the Worker's registration scope. A controlled page's
  request to a neighboring same-origin application bypasses this game cache.
- Navigations and non-hashed public assets are network-first, then fall back to
  their cached response when the network throws or returns a transient 5xx
  failure. Successful navigations replace one canonical scope-home entry rather
  than storing unbounded seed/route query variants. An uncached route falls back
  to that entry page; the client still reads its live URL. Client errors remain
  visible rather than being hidden behind stale content. See
  [`NAVIGATION_CACHE_RESEARCH.md`](NAVIGATION_CACHE_RESEARCH.md).
- Supporting browsers begin online navigation in parallel with service-worker
  startup through standard navigation preload. The worker consumes that response
  before issuing an ordinary fetch, while rejected/unsupported preloads retain
  the same network-first and offline paths. See
  [`NAVIGATION_PRELOAD_RESEARCH.md`](NAVIGATION_PRELOAD_RESEARCH.md).
- Runtime cache open/read/write is best-effort: a successful online response is
  never discarded merely because Cache Storage rejects its refresh. Required
  installation writes remain strict and atomic. Obsolete-cache enumeration and
  deletion are also best-effort during activation, so cleanup failure cannot
  block navigation preload or client claim. See
  [`RUNTIME_CACHE_FAILURE_RESEARCH.md`](RUNTIME_CACHE_FAILURE_RESEARCH.md).
- Vite's content-hashed JavaScript and CSS files are cache-first because a new
  file name represents new content.
- The optional ambient loop is also cache-first. In reduced-data mode its first
  request is issued only by explicit player action. A miss explicitly
  revalidates the stable audio URL before it becomes offline-ready, preventing a
  prior HTTP-cache entry from crossing release identities.
- Offline media requests commonly include an HTTP byte range. The worker slices
  the cached complete audio response and returns `206 Partial Content` with
  `Content-Range`, so Chromium can decode the opted-in loop without a network.
- The production build injects a deterministic digest of the final generated
  entry document into the `sw.js` body. That document already carries the
  content-hashed JavaScript/stylesheet names and a digest of all `public/`
  paths/bytes. The production registration keeps the Worker path stable (apart from the
  independent reduced-data mode), so changed app code or a same-path public
  asset makes the browser's ordinary byte comparison discover a new worker and
  gives it a separate cache while the previous release remains active.
  Worker-script checks bypass the HTTP cache.
- A newly installed worker does not call `skipWaiting()` automatically. Existing
  tabs remain on the worker and cache they loaded, avoiding a mixed-version shell.
- When a fully installed worker is waiting behind an existing controller, the
  page announces that the new offline build is ready. Only the player's reload
  action sends `SKIP_WAITING`; `controllerchange` then reloads immediately under
  the newly active worker.
- Other already-controlled tabs observe that controller replacement, cancel
  pending activity, and become inert behind a reload dialog. They cannot keep
  running old application code against the new worker cache. An initially
  uncontrolled first-install page remains uninterrupted.
- Activation claims clients before best-effort old-cache enumeration. This
  triggers the old-tab ownership guard before a slow cache backend can prolong
  interactivity; the activation promise still buffers functional events until
  cleanup and navigation-preload setup settle. This ordering follows the
  [Service Worker lifecycle](https://web.dev/articles/service-worker-lifecycle)
  and [`Clients.claim()` contract](https://developer.mozilla.org/en-US/docs/Web/API/Clients/claim).
- If browser storage has degraded to memory-only, the update notice explicitly
  warns that reloading will reset the current session before offering that action.
- Cache names include the encoded registration-scope path, behavior schema, an
  automatically derived signature of required/optional precache paths,
  `full`/`reduced` data mode, and the generated-shell release revision. On activation, the new worker
  claims clients and removes only older
  project caches carrying that exact scope prefix; another copy mounted under
  the same origin cannot lose its offline shell.

Increment `CACHE_SCHEMA` in `public/sw.js` when cache behavior itself becomes
incompatible. Precache-list edits change their compact list signature, while
any public path or byte edit changes the public-tree release revision even if
the Vite bundle does not; the rationale is recorded in
[`PRECACHE_IDENTITY_RESEARCH.md`](PRECACHE_IDENTITY_RESEARCH.md). Ordinary
bundled code changes receive new Vite hashes, which automatically produce a new
injected Worker revision and isolated cache. Non-hashed assets remain network-first, except
for explicitly opted-in cache-first audio, within that release-owned cache.
The separate hosting-layer revalidation requirements are in
[`HOST_CACHE_RESEARCH.md`](HOST_CACHE_RESEARCH.md); internal Cache Storage
versioning cannot force a browser to discover HTML that an outer HTTP cache
still considers fresh.

## Verification

The Worker VM harness feeds installation mixed-case, single-quoted, and spaced
asset attributes, requires both local assets to be fetched, and proves a remote
reference is ignored. It also covers exact-scope request interception and
activation when cache enumeration or deletion is unavailable.

Playwright journey J15 runs against `vite preview`, waits for the production
worker, verifies that its stable script URL has no release query and that the
combined bundle/public-tree revision owns the expected isolated cache,
makes and autosaves a choice, takes Chromium offline, and reloads the same
authored reflection. It then navigates to an uncached exact-route URL, exercises
the cached entry-page fallback, and verifies the same first decision. This proves
the HTML, CSS, JavaScript, art, service worker, local save, and shared-route
contract cooperate without a network response.

J29 installs the same production build with an injected explicit Save-Data
preference. It proves the reduced cache initially omits audio without omitting
the landscape, then opts into sound, observes the exact asset in Cache Storage,
reloads offline, and starts it again.

Deployment audit D01 independently serves the production artifact beneath
`/journey/`, verifies that its manifest and service-worker scope resolve within
that subpath, verifies the default Chinese and localized English install
identity plus separate ordinary/maskable icons, saves a reflection, and reloads
it offline. It then installs a
second byte-distinct revision at the same Worker URL, applies the rendered
update action, verifies the new controller,
and retains the reflection. The same audit injects an HTTP 503 and proves the
valid cached shell still resumes. It also creates a different-scope cache
sentinel and proves the updated `/journey/` worker does not delete it. This guards repository pages and other non-root
static hosting rather than inferring support from relative URLs alone.
It also requires a controlled online reload to use one navigation-preload
request with no duplicate ordinary entry request before exercising the offline
and 503 fallbacks. A second online reload carries `Vary: *`, forcing the
standards-defined runtime `Cache.put()` rejection while proving the fresh
network document still renders.

Deployment audit D02 fails one required icon during a background update. It
requires the candidate worker to become redundant, its partially populated
revision cache to disappear, the update notice to remain hidden, and the old
controlled reflection to reload offline. The rationale is recorded in
[`FAILED_UPDATE_RESEARCH.md`](FAILED_UPDATE_RESEARCH.md).

Deployment audit D03 blocks service workers at the browser boundary. It proves
no project cache/controller appears while a saved reflection survives reload
and the same five-region journey reaches its authored ending online.

Deployment audit D04 opens two controlled production tabs on the same saved
reflection. One activates a byte-distinct update; the other must enter a
focused, Axe-clean, inert interruption before explicitly reloading the same
reflection under the new controller.
