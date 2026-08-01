# Cross-tab local-progress ownership

## Trigger

The completed resilience queue covered unavailable, corrupt, restored, cleared,
and migrated storage, but not two live pages using the same browser profile.
Both pages could hold different in-memory journeys and save to the same keys.
The last interaction would win silently.

## Platform evidence

The [MDN storage-event contract](https://developer.mozilla.org/en-US/docs/Web/API/Window/storage_event)
states that a `localStorage` change is reported to other same-origin browsing
contexts, not the page that performed the write. The
[Web Storage guide](https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API/Using_the_Web_Storage_API)
also identifies the event as the mechanism for synchronizing other tabs. The
[HTML Standard](https://html.spec.whatwg.org/dev/webstorage.html) explicitly
warns authors to assume there is no locking mechanism between these operations.

That makes the event suitable for detecting loss of local ownership, but not
for automatically merging two nonlinear journeys. A field-by-field merge would
invent a route state that neither player page actually reached.

## Shipped contract

- Listen only while persistent local storage is active.
- Treat a change to the journey, chronicle, reading, or audio key—and an
  origin-wide clear—as loss of ownership.
- When the browser identifies the event's storage area, require the owned
  persistent `localStorage` object; a same-named `sessionStorage` mutation does
  not invalidate any player record and must not freeze the journey.
- Replace interactive access with a bilingual `alertdialog`; the stale session
  remains visible for context but is `inert`.
- Move focus to one unambiguous action: reload the latest persisted data.
- Do not offer a misleading merge or silently pick the stale page.
- Unrelated storage keys do not interrupt play, and listeners are removed at
  teardown.
- Snapshot the four raw owned records after mount and every in-app write. On a
  persisted `pageshow`, compare current storage before allowing cached UI to
  continue; reuse the same blocking dialog if a frozen page missed a change.
- Revoke active or pending ambience before making the stale session inert; the
  player must not be trapped with sound controls they can no longer operate.
- Version-cancel pending clipboard/native-share results so a late completion
  cannot rerender the stale DOM and replace the focused reload dialog.
- Apply the same ownership boundary when another tab activates a waiting
  service worker. `clients.claim()` changes every controlled page's controller;
  non-initiating tabs stop before old code can run against the new cache and
  explicitly reload. This interruption also applies to memory-only tabs, where
  the dialog discloses that reload resets the unsaved session.

## Evidence and kill criteria

Unit coverage exercises relevant, unrelated-key, unrelated-storage-area,
repeated, clear, cached-restore,
unchanged-snapshot, memory-only, ambience, and teardown paths. J23 advances a journey in a second real tab, observes the first page
become inert, reloads it, and proves the newer region and journal are retained.
J32 injects the standardized persisted restore event with both matching and
drifted records. A04 requires zero Axe violations and verifies focus placement.
D04 applies one update across two real controlled tabs and proves the
non-initiating tab becomes inert, remains accessible, and resumes its saved
reflection only after reload.

Revisit this design only if the product introduces accounts or server sync. At
that point, persisted revision IDs and an explicit conflict-resolution model
would be more honest than extending this local last-writer guard.
