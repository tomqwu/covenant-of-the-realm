# Local backup and restore

The game stores progress only in the current browser. Reading settings includes
a local backup flow so players can preserve or move that data without an
account, backend, or upload.

## Exported data

Each export uses a sortable UTC filename such as
`shan-he-you-qi-save-2026-07-31T23-58-09-321Z.json`. Colons and the decimal
point are replaced so the name remains valid on Windows as well as macOS/Linux; separate exports are
distinguishable without relying on browser-added `(1)` suffixes. The file is a
versioned JSON document containing:

- the current journey, including route, journal, stats, phase, and ending;
- the local chronicle of unique completed paths, exact recent routes, discovered endings, and discovered encounter variants;
- text-size, motion, and contrast preferences;
- ambient volume and mute preferences.

Active audio playback is deliberately not exported. Restored sessions always
remain silent until the player starts ambience again.

## Restore safety

Selecting a file never writes storage. The client first enforces a 256 KB limit,
parses JSON as inert data, and validates every nested record with the same schema
guards used by normal persistence. Journey validation also proves the route is
region-ordered, journal entries match the route and authored choice effects,
stats reproduce from those effects, and phase/ending positions are reachable.
Legacy journal entries without stable choice IDs are accepted only when their
non-provision effects identify exactly one authored choice; the historical
omitted provision cost remains compatible, but the live requirement for that
inferred choice must still have been reachable. Arbitrary bounded legacy
effects cannot manufacture a valid journey.
After a valid legacy journey reaches normal loading, it is rewritten once with
the inferred stable choice IDs. Later callback prose and chronicle identity then
use the current deterministic path rather than remaining in compatibility mode.
The separate **Restore this backup** button
is enabled only after validation succeeds.

Chronicle records likewise require bounded non-empty IDs, normalized 32-bit
seeds, unique path identities, valid endings/stats, and (when present) an exact
region-ordered route plus a valid reached-encounter count. At most 128 path records are retained; a separate compact
ending/encounter ledger preserves every discovery when an old path is evicted.
Legacy records without a route or explicit discovery ledger remain accepted;
their deterministic seeds and canonical path IDs supply only the encounters
actually reached until the next completion persists the explicit set. An
unrecognizable legacy lost-record ID conservatively reveals no new titles rather
than exposing an unseen route suffix. An older
version-1 export containing more than 128 otherwise valid paths is migrated
during validation: the newest 128 paths are staged and every ending and
encounter discovered by either the old paths or ledger is retained. This in-memory migration does not
write local storage until the player confirms restore. The validation status
names that compaction and its preservation rule before enabling confirmation;
it is never presented as an unchanged current-format backup.

Each asynchronous read belongs to the latest picker selection. Choosing another
file or canceling the picker invalidates earlier reads, so out-of-order disk
completion cannot stage the wrong backup. Validation immediately disables the
restore action and exposes a live status. Once a valid file is staged, any
journey, language, reading, mute, or volume mutation invalidates it (and any
in-flight read), so a stale file cannot later overwrite newer local work without
being explicitly selected again.

Invalid, oversized, canceled, or unreadable files leave all current data
unchanged and produce an accessible status message. Restore snapshots all four
existing records before writing; if any write fails, rollback attempts every
record even when an earlier rollback operation also fails, and the validated
file remains staged for a retry. If browser access fails while those records are
being snapshotted, no mutation is attempted and the failure is classified as a
complete/no-change rollback. Browser storage does not offer transactions, so
the interface distinguishes a complete rollback (current data is unchanged)
from an incomplete rollback (current data may be mixed and must be checked after
reload). A successful restore reloads the app so no old in-memory state can mix
with the restored bundle.

If the browser denies writable local storage, the current in-memory journey can
still be exported, but file selection and restore are disabled with an explicit
status. The interface never reports a restore that would disappear on reload.

If the browser cannot construct or dispatch the local Blob download, export
does not claim success. The exact versioned JSON is exposed in a labeled,
read-only textarea so the player can copy it into a `.json` file. Any later
journey or preference mutation removes that fallback because it no longer
represents current state. Journey-text export keeps its already-visible summary
as the corresponding manual fallback.

The file input's `.json`/MIME `accept` value is only a picker hint; it is never
treated as validation.

## Browser eviction protection

A successful local write means the journey can survive reload, but browser
storage is best-effort by default and can still be evicted under storage
pressure. Reading settings checks that status without requesting permission. If
the Storage Manager API is available and protection has not been granted, the
player can explicitly ask the browser to protect this origin from automatic
eviction. A denial or API failure changes no data and leaves export available.
Even a grant is not a cloud copy and never prevents the player from clearing
site data or using the in-game clear control. The evidence and wording contract
are recorded in
[`STORAGE_DURABILITY_RESEARCH.md`](STORAGE_DURABILITY_RESEARCH.md).

## Local clearing

Players can remove the journey, chronicle, reading preferences, and audio
preferences without using browser developer tools. The first action only arms
the control and states exactly what will be deleted; any other button disarms
it. Keyboard transitions and settings changes disarm it as well. A second
explicit action removes all four records and reloads. If a removal
fails, rollback attempts all prior values. The interface reports either that
data was kept or, if browser storage also rejects rollback, that the prior state
could not be guaranteed. This action is disabled when writable local storage is
unavailable.

## Versioning

The top-level bundle currently has `version: 1`. Future incompatible schemas
must add an explicit migration or use a new version; never loosen nested
validation merely to accept unknown data.

Unit tests cover serialization, every nested validator, empty-journey backup,
transaction-like restore/clear, pre-mutation read denial, complete and
incomplete rollback, malformed
files, size rejection, read and write failures, selection races, cancellation,
staged-file invalidation, asynchronous teardown, and the maximum valid chronicle staying below the import
limit. Legacy oversized-chronicle migration, portable UTC filenames, and synchronous export failure are also covered. Playwright journey J18 proves an actual browser
download and recovery after complete local-storage loss; J21 proves guarded
clearing of all four browser records; J31 disables Blob URLs and validates the
manual JSON and journey-summary fallbacks.

Clear confirmation represents a consecutive destructive intent, not a sticky
mode. Any other click (including a disclosure), preference/file change, volume
input, or story mutation returns the action to **Clear local data**. The player
must press the clear action twice without an intervening interaction before the
four records are removed.

A successful restore or clear also cancels ownership of active **and pending**
ambience before reload. If an optional-audio preparation promise settles late,
it cannot call `play()` under the discarded local state.

The same success boundary invalidates any pending file read and disables export,
file selection, restore, and clear until reload. A delayed picker result cannot
restage old data after local records have already been replaced or removed, and
the player cannot issue a second mutation against the discarded page state.

That reload-pending state is terminal for the whole mounted session, not only
the backup row. All form controls become disabled, keyboard/click/change/input
handlers stop writing, pending clipboard/share results are version-canceled,
storage-conflict rendering is suppressed, and an outstanding persistence check
cannot re-enable controls. A delayed or intercepted reload therefore cannot
recreate data immediately after a successful clear.
