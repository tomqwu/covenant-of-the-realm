# Initial-route lifecycle

## Failure mode

A shared journey uses a one-time `replay=1` marker to supersede unrelated local
progress. The composition root consumes that marker immediately. Previously the
new intro was not persisted until **Begin journey**, so reloading between those
two moments could load the unrelated older save again. The address also gained
its exact `route` signature only after a later player action.

## Ownership contract

Every mount publishes a canonical address containing the numeric seed, the five
validated encounter IDs in region order, and the selected locale when English.
That makes an untouched intro reproducible and manually copyable.

Persistence deliberately differs by entry path:

- An ordinary fresh intro is not saved until play begins. Its exact URL is
  enough to survive reload, and this preserves the promise that clearing local
  data does not silently recreate a journey record.
- A validated one-time shared route is saved as an intro before its marker is
  consumed. It has explicitly superseded local progress, so it must take save
  ownership immediately.
- A resumed journey synchronizes the address from validated saved state without
  rewriting that state merely because the page mounted.

Malformed seed, route, or locale values remain subject to the existing parsing
and region-order validation before any of these rules apply.

## Evidence

- Unit tests prove forced-new initialization persists the new state and reports
  the exact canonical route, while ordinary mount and later route changes keep
  their callback counts explicit.
- Browser journey J30 proves an untouched intro reloads on the same exact route
  with no journey key, then creates unrelated progress, consumes a different
  shared route, and reloads into the shared intro rather than the older scene.
- J13 still proves completed-artifact replay and subsequent normal resume.
- J21 still proves clearing every local record leaves all four storage keys
  absent after reload.
