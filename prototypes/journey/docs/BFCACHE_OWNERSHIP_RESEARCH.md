# Cached-page local ownership research

## Gap

The storage-event guard protects two simultaneously active same-origin tabs.
A document may instead be frozen and later restored with its JavaScript heap and
render tree intact. If local records changed while it was inactive, continuing
from that old in-memory state could overwrite the newer journey.

## Platform evidence

The HTML Standard fires `pageshow` as the first event on reactivation and defines
`PageTransitionEvent.persisted` as true when a document is being reused rather
than newly loaded. This gives the app a precise, back/forward-cache-compatible
boundary at which to validate its ownership before accepting another action.

Sources: [HTML navigation and session history](https://html.spec.whatwg.org/multipage/nav-history-apis.html#event-pageshow),
[`pageshow` event reference](https://developer.mozilla.org/en-US/docs/Web/API/Window/pageshow_event).

## Decision

- Snapshot the raw journey, chronicle, reading-preference, and audio-setting
  values after initial validation and after every in-app write.
- Do nothing for initial/non-persisted `pageshow` events.
- On a persisted restore, compare current raw records with the owned snapshot.
- If they match, preserve the restored UI and focus without a reload.
- If any differ, reuse the existing bilingual `alertdialog`, mark the old game
  session `inert`, focus **Load latest progress**, and require reload.
- Skip the comparison for a memory-only session because no other document can
  share its resilient-storage mirror.
- Remove the lifecycle listener during teardown.

Raw values are intentional: a malformed or externally cleared record is also a
loss of ownership, even if parsing it would happen to fall back to a default
value equal to current in-memory state.

## Evidence

- Unit tests cover initial events, owned self-writes, unchanged persisted
  restores, changed records, repeated events, memory-only sessions, and teardown
  at exact 100% coverage.
- J32 passes through the real composition root, proves an owned restore remains
  interactive, mutates one local record without a storage event, and proves the
  next persisted restore blocks and focuses correctly.
- J23 still proves the active two-tab event path, while A04 audits the shared
  conflict surface for accessibility.
- The shared conflict path cancels ambient preparation/playback before the
  restored session becomes inert, matching the active multi-tab boundary.

## Rejected alternatives

- **Always reload on `pageshow`:** discards a valid cached UI and can reset a
  memory-only journey.
- **Compare only the journey key:** stale preferences or chronicle writes can
  still overwrite a newer record on the next mutation.
- **Merge records automatically:** nonlinear journey state has no honest
  field-wise merge, and preferences/chronicle should remain one owned bundle.
