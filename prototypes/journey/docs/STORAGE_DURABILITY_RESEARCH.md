# Browser storage durability research

Date: 2026-07-31

## Question

The game already detects whether browser storage can be read and written, falls
back to memory when it cannot, and provides portable backups. Does a successful
`localStorage` write justify describing that data as protected from browser
cleanup, and if not, what is the smallest honest player control?

## Standards evidence

The browser Storage Standard distinguishes the default **best-effort** bucket
from a **persistent** bucket. A persistent bucket cannot be cleared by the user
agent's eviction policy without involvement from the origin or player. The
standard exposes a read-only check through `StorageManager.persisted()` and a
permission request through `StorageManager.persist()`; that request may still
resolve `false`.

Source: [WHATWG Storage Standard](https://storage.spec.whatwg.org/).

MDN likewise documents that best-effort data may be evicted under storage
pressure, while a granted persistence request excludes an origin from automatic
eviction. The player can always remove site data manually, so “protected” must
not be presented as an undeletable or cloud-backed guarantee.

Sources: [Storage quotas and eviction criteria](https://developer.mozilla.org/en-US/docs/Web/API/Storage_API/Storage_quotas_and_eviction_criteria),
[`StorageManager.persist()`](https://developer.mozilla.org/en-US/docs/Web/API/StorageManager/persist).

The API is restricted to secure contexts and browser policy may grant or deny a
request. Guidance recommends making a request from a meaningful user gesture
rather than surprising the player during page load.

Source: [Persistent storage guidance](https://web.dev/articles/persistent-storage).

## Decision

Keep the existing writable-storage fallback, but stop using that signal as a
player-facing synonym for eviction protection. Add a small **Local data
protection** section inside Reading settings:

- silently call `persisted()` only to determine current status;
- describe an unprotected origin as locally saved but best-effort;
- call `persist()` only from an explicit button press;
- distinguish granted, denied, unsupported, and failed states;
- retain local JSON export as the portable long-term fallback;
- never imply that this creates an account, cloud backup, or defense against the
  player's own clearing action.

## Acceptance criteria

- No permission request occurs during mount or ordinary autosave.
- A best-effort status names automatic eviction risk and offers one explicit
  request control.
- The control is disabled while a request is pending and reports the returned
  boolean without guessing why it was denied.
- A granted state says only that automatic browser eviction is prevented and
  keeps player-controlled clearing available.
- Unsupported and rejected API calls leave the game and backup export usable.
- Late asynchronous results cannot render after teardown.
- Unit tests, a named browser journey, and the expanded-settings Axe audit cover
  the complete contract.

## Rejected alternatives

- **Request on startup:** risks an unexplained permission prompt and violates the
  user-gesture recommendation.
- **Call every time progress saves:** can nag after denial and confuses a choice
  about origin-wide storage with routine autosave.
- **Call writable `localStorage` “durable”:** ignores the standards distinction
  between best-effort and persistent buckets.
- **Hide the distinction because backups exist:** portable export reduces risk
  but does not tell a player whether the browser may automatically evict the
  copy they are currently relying on.
