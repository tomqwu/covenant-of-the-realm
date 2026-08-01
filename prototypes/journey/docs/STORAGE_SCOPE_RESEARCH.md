# Browser-storage scope contract

## Boundary

The build is relocatable to an origin root or arbitrary subpath, and each
service worker/cache namespace includes its registration-scope path. Player
records have a different browser boundary: `localStorage` is partitioned by
**origin only**, not URL path or service-worker scope. Every document under the
same scheme, host, and port can access the same storage area. Source:
[MDN Web Storage API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API).

The four current keys are intentionally stable and unqualified:

- `shan-he-you-qi:journey:v1`
- `shan-he-you-qi:chronicle:v1`
- `shan-he-you-qi:preferences:v1`
- `shan-he-you-qi:audio:v1`

Therefore `/journey/` and `/preview/journey/` on the same origin would share
one current journey, chronicle, and preference set even though their offline
shell caches are isolated. Cross-tab/BFCache guards prevent silent stale writes
between those pages, but they do not turn origin storage into path storage.

## Deployment decision

Ship one player-data environment per origin. Use distinct origins for
production, staging, review apps, forks, or independently branded copies when
their player records must not mix. A different subpath is sufficient for
service-worker scope and route links, but not for independent local data or the
origin-wide storage-persistence request.

This is disclosed rather than silently changing keys because introducing a path
prefix now would make existing records appear lost unless every prior mount
location had an explicit migration. It would also make moving the same
deployment from root to subpath look like a different player profile.

## Evidence gate for path namespaces

Reconsider path-scoped record keys only when one real origin must host two
independent persistent copies. A compliant migration must:

1. define a stable deployment ID that survives ordinary path moves, rather than
   deriving identity from `location.pathname` accidentally;
2. read legacy unscoped keys exactly once and require an explicit ownership
   decision when multiple copies could claim them;
3. preserve versioned JSON backup portability across origins/scopes;
4. keep clear/restore transactional across all records in the selected scope;
5. prevent storage events from unrelated deployment IDs creating a false
   conflict; and
6. add a two-subpath browser journey proving independent saves, clears, caches,
   and upgrades.

Until that concrete hosting requirement exists, separate origins are simpler,
more legible to players, and aligned with the browser's actual privacy model.
