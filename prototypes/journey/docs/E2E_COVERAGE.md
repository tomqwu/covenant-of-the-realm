# Critical E2E journey coverage

Coverage here means automated coverage of every named player journey, separate
from source-code coverage. A journey is covered only when Playwright performs it
through the rendered interface and asserts the observable outcome.

Every Playwright page records `pageerror` events and fails its test if any
uncaught browser exception occurred. This prevents a visually successful
assertion from masking a runtime failure during navigation, interaction, or
asynchronous cleanup. Custom deployment contexts explicitly attach the same
observer when they exercise altered worker or JavaScript policy.

Every named check has one unique evidence ID: J for critical player journeys, A
for accessibility, D for deployment/update, S for security, and X for
cross-engine compatibility. The badge gate rejects anonymous or duplicate IDs
before resolving their configured browser-project executions.

| ID | Journey | Expected evidence |
| --- | --- | --- |
| J01 | First journey | Start screen enters the first encounter |
| J02 | Covenant ending | A valid sequence reaches the covenant ending |
| J03 | Lost ending | Resource-depleting choices reach the authored failure and reveal only the three encounters actually visited |
| J04 | Restart | Replay returns to the same seed and first encounter |
| J05 | New route | New journey changes to a non-colliding route seed, clears the journal, and synchronizes the exact-route address |
| J06 | Persistence | Reload resumes the current encounter and stats |
| J07 | Language and keyboard | A bilingual skip link bypasses sidebar controls; language/numeric keys ignore form controls, focus follows story transitions, localized metadata survives reload, and an English exact-route address reopens the same encounter without local data |
| J08 | Mobile touch | Touch completes all five regions at 360 px; the full journal and expanded encounter/recent-route chronicle remain accessible without horizontal overflow |
| J09 | Authored aftermath | A choice reveals its persisted consequence before the next scene |
| J10 | Homeward ending | A provision-aware route reaches the homeward ending |
| J11 | Wanderer ending | A lean independent route reaches the wanderer ending |
| J12 | Local chronicle | A unique discovered ending persists without reload inflation |
| J13 | Journey sharing | A completed route copies and device-shares decisions, deltas, aftermaths, and a validated exact-route link; opening it supersedes an unrelated save once and subsequent reload resumes normally |
| J14 | Reading preferences | Text, motion, and contrast choices apply and survive reload |
| J15 | Offline resume | The installed production shell proves its bundle/public-tree release identity, restores a saved reflection, and opens a validated exact-route navigation without a network |
| J16 | Optional ambience | Audio requires a player gesture and persisted mute/volume never imply autoplay |
| J17 | Narrative callback | Opposite choices on one seed produce different persisted prose in the next region |
| J18 | Local recovery | A UTC-named downloaded backup validates without writes, a later local mutation invalidates that staged file, and explicit reselection restores journey, chronicle, and preferences after storage loss |
| J19 | Restricted storage | A five-region journey still completes when every persistent-storage operation is denied and exports the complete in-memory journey and chronicle |
| J20 | Corrupt-save recovery | An impossible persisted phase is discarded before rendering and a fresh journey starts normally |
| J21 | Local data clearing | A completed journey, chronicle, reading preferences, and audio settings are erased only after two consecutive explicit actions; any intervening disclosure or setting change disarms confirmation |
| J22 | Recent route recall | During another unfinished journey, a chronicle entry preserves progress on first press, disarms after another disclosure, reopens the exact earlier route only after two consecutive presses, retains discovery history, and leaves a copyable exact-route address |
| J23 | Cross-tab ownership | A stale tab cancels ambience and becomes inert when another tab advances the shared journey, then explicitly reloads into the newer scene before it can write again |
| J24 | Stateful choice gate | The same exact route keeps a trust-gated response and its requirement keyboard-discoverable but activation-inert after solitary choices, then enables it with visible effects after earlier trust-building play |
| J25 | Legacy backup migration | An oversized valid version-1 chronicle is staged without writes, visibly discloses its bounded migration, and restores the newest 128 journeys without forgetting an evicted ending |
| J26 | Storage durability | The composition root checks browser eviction protection without requesting it, requests it exactly once from a player action, and recognizes the granted state after reload |
| J27 | Background ambience | A hidden document pauses opted-in ambience, remains silent when visible again, and restarts only from another player action |
| J28 | Journey text export | A completed journey downloads under a seed/ending/UTC name as UTF-8 text containing all five decisions, authored aftermath, and a validated exact-route link |
| J29 | Reduced-data install | A Save-Data installation omits optional audio while retaining the core shell; explicit online playback caches the loop, cached range requests return `206 Partial Content`, and playback remains operable after an offline reload |
| J30 | Canonical intro ownership | A fresh intro reloads from its exact canonical URL without recreating cleared local data; a consumed shared-route flag immediately replaces an unrelated save so another reload cannot resurrect it |
| J31 | Export failure recovery | With local Blob URL creation denied, backup export reveals valid selectable JSON and a complete journey retains its selectable exact-route summary instead of falsely claiming a download |
| J32 | Cached-page ownership | A persisted page restore with unchanged owned records stays playable; drift in any local player record opens the same focused, inert stale-session guard before another write |
| J33 | Encounter discovery | Two complementary completed exact routes reveal all ten authored encounter variants in the persistent bilingual chronicle ledger |
| J34 | English mobile touch | English touch play completes all five regions at 360 px with no horizontal overflow and a zero-violation ending/share audit |
| J35 | Desktop layout | Mouse play completes all five regions at 1440×900 with the ledger/story columns intact, no horizontal overflow, and the complete ending journal |

Automated journey coverage target: **35/35 (100%)**.

Configured browser execution target: **53/53**. This includes the named journeys
plus accessibility, deployment, security, and twice-run Firefox/WebKit
compatibility specs; the badge gate derives this total from the configured test
files and rejects stale README/state claims.

## Accessibility state audits

The journey count above measures player workflows. Five Axe scans and one full
native-keyboard journey run in the same production Chromium suite:

| ID | Rendered states |
| --- | --- |
| A01 | Intro, expanded settings, selectable backup-export failure fallback, combined large/reduced/high-contrast mode at 360 px, and rendered 44px target geometry |
| A02 | Encounter, all five aftermath states, ending/share controls, a focused low-trust ARIA-disabled gate with callback prose, and rendered 44px target geometry |
| A03 | Forced colors and reduced motion through a complete five-region journey at 320 px, including rendered 44px target geometry |
| A04 | Focused cross-tab conflict dialog with the stale session inert and both Tab directions contained |
| A05 | English large text, reduced motion, and high contrast through a complete journey at 320 px, including target geometry and ending/share reflow |
| A06 | Full native-keyboard journey from skip link through five regions to the ending, with every scene/action focus handoff verified |

A01–A05 require zero automated accessibility violations after entrance motion
settles; A06 is the separate native-keyboard focus/operation journey. J08 also
runs the same Axe audit on the completed mobile ending with
the chronicle expanded, where undiscovered labels and 44 px route controls are visible.
J34 independently audits the longer English copy and share artifact at the same
360 px width.
A05 combines that longer copy with the narrowest supported reflow width and all
three in-app visual preferences instead of inferring the combination from
separate Chinese and 360 px runs.
These checks complement rather than replace keyboard, touch, language, mobile,
and visual-preference journeys.

## Security state audit

S01 mutates structurally valid persisted narrative text with HTML-shaped event
handler content, reloads the reflection, and proves that the payload is visible
only as text: no element is created and no handler executes.

S02 verifies the static Content Security Policy rejects document-base mutation,
inline script/style execution, and string-timer evaluation while the same
protected shell still begins a journey.

S03 completes a production feature session through reading preferences,
same-origin audio preparation, all five regions, local persistence, and native
text download. It requires zero cross-origin HTTP(S) requests, zero CSP
violations, zero console errors or failed/error responses, zero cookies, and
zero session/IndexedDB records, with exactly the four documented localStorage
player records. Its one v9 Cache Storage shell must contain exactly ten
same-origin, query-free static request keys.

## Browser-engine compatibility

X01 runs a bounded smoke in Playwright's Firefox and WebKit projects. Each engine
persists and reloads the first reflection, completes all five regions, reaches
the covenant ending, renders the full journal, and avoids horizontal overflow.
X02 independently completes a route in both engines and verifies the native
Blob download's UTC-safe filename, UTF-8 ending/five-decision content, and valid
exact-route replay URL.
The larger behavioral, mobile, offline, accessibility, and security matrices
remain on Chromium to keep the feedback loop proportionate.

## Deployment audits

- D01 proves the recommended host cache-header split, installability, subpath scope, single-request navigation preload,
  successful online rendering through a forced runtime cache-write rejection,
  isolated cache activation, 503 shell fallback, player-approved update, and
  foreign-scope cache preservation.
- D02 forces a required asset to return 503 during a new worker install. The
  candidate becomes redundant, its partial cache is removed, no update is
  announced, and the previous saved build still reloads offline.
- D03 blocks service workers at the browser boundary, then saves, reloads, and
  completes all five regions online without creating a shell cache. Install and
  offline support remain progressive enhancement rather than a play dependency.
- D04 activates a byte-distinct update from one of two controlled tabs. The
  other tab becomes inert in a focused, Axe-clean reload dialog before old code
  can operate under the new worker, then resumes the saved reflection.
- D05 disables JavaScript at the browser boundary and requires the production
  shell to render its bilingual semantic requirement notice instead of an empty
  unexplained page.
