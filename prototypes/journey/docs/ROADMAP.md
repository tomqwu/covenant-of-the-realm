# Eight-hour feature loop

This queue orders complete player outcomes, not isolated UI additions. Every
increment must preserve a playable build, 99%+ unit coverage, and all critical
browser journeys.

## P0 · Consequence and ending clarity

- [x] Add an authored, persisted aftermath beat after every non-terminal choice.
- [x] Cover all four endings through real UI journeys, not engine tests alone.
- [x] Make the final journal summarize the causal path to the ending.
- [x] Pair every final journal decision with its authored aftermath.

## P1 · Replay value and ownership

- [x] Add a local chronicle of discovered endings and completed journeys.
- [x] Add a copyable route/ending summary with an accessible fallback.
- [x] Add capability-detected device sharing without replacing copy/manual fallback.
- [x] Preserve the selected language in exact-route links and address updates.
- [x] Add player-controlled text scale, motion, and contrast preferences.
- [x] Add installable/offline deployment support with an update-safe cache.
- [x] Localize the installed app identity with a backward-compatible manifest fallback.
- [x] Separate ordinary and full-bleed maskable install icons around the standardized safe zone.
- [x] Reuse the full-bleed icon for an explicit relocatable iOS Home Screen identity.
- [x] Bound route-query navigation caching to one canonical offline entry.
- [x] Announce a fully cached update and activate it only on player request.
- [x] Start online installed navigations in parallel with service-worker boot without weakening offline fallback.
- [x] Keep successful online play available when a runtime Cache Storage operation fails.
- [x] Define the host HTTP-cache contract and revalidate stable audio on a release-cache miss.
- [x] Prevent a worker activated in one tab from leaving older tabs interactive under the new cache.
- [x] Keep a controlled page's same-origin cross-application requests outside the game worker cache.

## P2 · Sensory and content depth

- [x] Add optional ambient audio only with explicit volume and mute controls.
- [ ] Add a new decision pattern only after playtesting identifies repetition.
- [x] Add route-specific callbacks so earlier actions alter later prose.

The remaining decision-pattern item is gated by the evidence and explicit
thresholds in [`DECISION_PATTERN_RESEARCH.md`](DECISION_PATTERN_RESEARCH.md).

## P3 · Local resilience

- [x] Add validated export and explicit two-step restore for all local progress.
- [x] Isolate offline shell caches by bundle and full public-tree content revision.
- [x] Fall back to an honest in-memory session when browser storage is denied.
- [x] Verify forced colors, keyboard focus, and 320 px reflow through an ending.
- [x] Render imported and persisted narrative strings as inert text.
- [x] Make the static build relocatable and enforce production asset budgets.
- [x] Reduce the shipped landscape payload while retaining its source artifact.
- [x] Smoke a saved complete journey in Chromium, Firefox, and WebKit engines.
- [x] Move chronicle identity to stable choice IDs without duplicating legacy paths.
- [x] Make backup file staging latest-selection-wins and cancel-safe.
- [x] Prevent late clipboard completion from reviving a destroyed interface.
- [x] Make pending ambience startup single-flight and visibly non-interactive.
- [x] Make clipboard results latest-request-wins and state-owned.
- [x] Expose all 32 authored route combinations and preserve saved-route replay.
- [x] Skip deterministic seed collisions when the player requests a new route.
- [x] Make copied journey artifacts open the same route once without breaking resume.
- [x] Preserve exact encounter signatures and per-choice deltas in shared artifacts.
- [x] Reject impossible saved phases, route order, journal identity, and derived stats.
- [x] Add guarded two-step clearing for every local player record.
- [x] Invalidate staged restores whenever newer local state is created.
- [x] Preserve and replay up to five recent routes from the local chronicle.
- [x] Bound retained chronicle paths without forgetting discovered endings.
- [x] Compact oversized legacy chronicles in storage and imported backups instead of discarding their history.
- [x] Guard recent-route recall before it replaces unfinished progress.
- [x] Block stale-tab writes when another tab changes local player data.
- [x] Pin CI actions immutably and reject mutable workflow references.
- [x] Distinguish writable best-effort storage from explicit browser eviction protection.
- [x] Pause active and pending ambience when the page becomes hidden without auto-resume.
- [x] Download the completed journey as a local, replayable UTF-8 text artifact.
- [x] Defer optional offline audio when the browser explicitly requests reduced data.
- [x] Remove failed-update partial caches while preserving the active offline build.
- [x] Canonicalize the initial route before play and persist consumed shared-route ownership before reload can resurrect an unrelated save.
- [x] Recover from local download setup failure with honest status and complete selectable journey/backup artifacts.
- [x] Recheck all local-record ownership when a page resumes from the browser back/forward cache.
- [x] Track all ten completed-route encounter discoveries without forgetting evicted history.
- [x] Prevent early lost journeys from revealing encounters the player never reached.
- [x] Enforce the 44 CSS-pixel touch-target contract across every visible interaction state.
- [x] Give each local backup and completed-journey artifact a sortable cross-platform UTC filename.
- [x] Complete and audit both Chinese and English touch journeys at 360 CSS pixels.
- [x] Expose the core hero landscape to the initial HTML preload scanner without duplicating its request.
- [x] Keep pointer hover feedback from moving or reflowing interactive targets.
- [x] Make the local-data/privacy boundary explicit and reject remote URLs from the production JavaScript artifact.
- [x] Disarm destructive local-data clearing after any intervening interaction.
- [x] Require consecutive intent before recent-route recall replaces unfinished progress.
- [x] Prevent late audio preparation from starting after page/data ownership is canceled.
- [x] Lock backup controls and invalidate pending file reads after successful restore/clear.
- [x] Freeze every local write and stale async redraw while restore/clear reload is pending.
- [x] Apply audio no-preload before assigning its source and prove reduced-data silence at the request layer.
- [x] Strip development WebSocket origins from the production connection policy.
- [x] Cancel ambience before a cross-tab or cached-page conflict makes its controls inert.
- [x] Prevent late portable-artifact results from redrawing an ownership conflict.
- [x] Keep Worker activation cleanup best-effort without blocking preload or client claim.
- [x] Make production output byte-reproducible and bind the Worker revision to the final shell.

## Research trigger

Research begins only when the actionable queue above is complete or a feature
is blocked by an unknown design pattern. Research should compare primary
sources or directly playable narrative games, record the observed interaction,
and turn it into a testable hypothesis rather than copying surface style.

The decision-pattern research remains playtest-gated. A second comparison in
[`REPLAY_DISCOVERY_RESEARCH.md`](REPLAY_DISCOVERY_RESEARCH.md) found an unblocked
route-recall gap and defines the bounded recent-journey increment above.
[`PLATFORM_SHARING_RESEARCH.md`](PLATFORM_SHARING_RESEARCH.md) records the
standards evidence, fallback contract, and kill criteria for device sharing.
[`UPDATE_LIFECYCLE_RESEARCH.md`](UPDATE_LIFECYCLE_RESEARCH.md) records the
waiting-worker lifecycle and explicit update contract.
[`MULTI_TAB_RESEARCH.md`](MULTI_TAB_RESEARCH.md) records the shared-storage race
and the reload-before-write guard derived from the browser event contract.
[`SESSION_LENGTH_AUDIT.md`](SESSION_LENGTH_AUDIT.md) separates the measurable
authored-text envelope from the still-unverified 15–20 minute design target.
[`STORAGE_DURABILITY_RESEARCH.md`](STORAGE_DURABILITY_RESEARCH.md) distinguishes
ordinary local writes from a granted origin-wide persistence request and records
the explicit player-gesture contract.
[`AUDIO_VISIBILITY_RESEARCH.md`](AUDIO_VISIBILITY_RESEARCH.md) derives a
pause-without-auto-resume contract from the standardized document visibility
lifecycle.
[`JOURNEY_TEXT_EXPORT_RESEARCH.md`](JOURNEY_TEXT_EXPORT_RESEARCH.md) records the
permission-free Blob/download ownership path and object-URL lifecycle.
[`REDUCED_DATA_RESEARCH.md`](REDUCED_DATA_RESEARCH.md) separates the core offline
shell from optional audio under an explicit Save-Data preference.
[`FAILED_UPDATE_RESEARCH.md`](FAILED_UPDATE_RESEARCH.md) makes failed worker
installation atomic at the revision-cache boundary.
[`INITIAL_ROUTE_LIFECYCLE.md`](INITIAL_ROUTE_LIFECYCLE.md) records why ordinary
fresh intros rely on their exact URL while one-time shared intros must take
immediate save ownership.
[`DOWNLOAD_FAILURE_RESEARCH.md`](DOWNLOAD_FAILURE_RESEARCH.md) separates handing
a Blob URL to the browser from guaranteed file delivery and defines the manual
artifact fallback.
[`BFCACHE_OWNERSHIP_RESEARCH.md`](BFCACHE_OWNERSHIP_RESEARCH.md) extends the
cross-tab guard across frozen/cached document restoration.
[`ENCOUNTER_DISCOVERY_RESEARCH.md`](ENCOUNTER_DISCOVERY_RESEARCH.md) turns the
existing authored route matrix into quiet replay direction without points or
pop-up achievements.
[`MANIFEST_LOCALIZATION_RESEARCH.md`](MANIFEST_LOCALIZATION_RESEARCH.md) keeps a
stable Chinese install fallback while exposing the English identity through the
standard localized-member map on supporting browsers.
[`MASKABLE_ICON_RESEARCH.md`](MASKABLE_ICON_RESEARCH.md) replaces the ambiguous
combined icon purpose with independently audited ordinary and adaptive assets.
[`PRECACHE_IDENTITY_RESEARCH.md`](PRECACHE_IDENTITY_RESEARCH.md) prevents a
public-asset-list-only worker update from sharing the active offline cache.
[`NAVIGATION_CACHE_RESEARCH.md`](NAVIGATION_CACHE_RESEARCH.md) keeps unbounded
route seeds from creating unbounded duplicate entry-document cache keys.
[`NAVIGATION_PRELOAD_RESEARCH.md`](NAVIGATION_PRELOAD_RESEARCH.md) removes the
avoidable worker-start delay from online network-first navigations while
retaining the same cache and failure semantics.
[`RUNTIME_CACHE_FAILURE_RESEARCH.md`](RUNTIME_CACHE_FAILURE_RESEARCH.md)
separates strict atomic installation from best-effort runtime refresh writes.
[`INSTALL_DISCOVERY_RESEARCH.md`](INSTALL_DISCOVERY_RESEARCH.md) rejects a
permanent non-interoperable install button until observed discovery failures
cross a two-of-five prototype threshold.
[`PLATFORM_INTEGRATION_ROADMAP.md`](PLATFORM_INTEGRATION_ROADMAP.md) evaluates
installed-app shortcuts, file handling, launch-window control, and inbound
sharing against the existing save-ownership contract; every candidate remains
evidence-gated.
[`HERO_LOADING_RESEARCH.md`](HERO_LOADING_RESEARCH.md) shortens the only large
core visual's discovery chain while preserving subpath, offline, and
reduced-data contracts.
[`RESUME_CONTEXT_RESEARCH.md`](RESUME_CONTEXT_RESEARCH.md) rejects long-form save
thumbnails/timestamps for the current one-save scope and defines a two-of-five
delayed-orientation gate for a bounded recap.
[`MEMORY_ONLY_EXIT_RESEARCH.md`](MEMORY_ONLY_EXIT_RESEARCH.md) rejects an
unreliable leave-page prompt that can weaken back/forward-cache recovery and
defines an observed-loss threshold for reconsideration.
[`CHOICE_COMMITMENT_RESEARCH.md`](CHOICE_COMMITMENT_RESEARCH.md) rejects a
confirmation dialog on the game's primary verb and routes observed mistaken
activations to the already-bounded aftermath reconsideration experiment first.
[`TRADEOFF_RESEARCH.md`](TRADEOFF_RESEARCH.md) turns the locked dominance audit
and Old City's natural control into separate 3/5 gates for an effect-only
rebalance versus the expressive-vow prototype.
[`LOSS_RECOVERY_RESEARCH.md`](LOSS_RECOVERY_RESEARCH.md) separates the 30.8%
reachable lost-path share from an observed player-loss rate, proves that loss
occurs only after region three or four, and keeps checkpoint retry behind a
two-of-five actual-loss comprehension/recovery gate.
[`COMPARABLE_PATTERN_ROADMAP.md`](COMPARABLE_PATTERN_ROADMAP.md) compares rewind,
qualitative-stat, save-slot, and achievement patterns and gives each an explicit
adoption threshold or rejection rule.
