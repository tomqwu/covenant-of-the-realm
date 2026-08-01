# Navigation preload research

## Player-facing problem

The installed game deliberately uses network-first navigation so an online
player receives the current shell while an offline player receives the cached
one. After the browser has stopped an idle service worker, however, an ordinary
network request cannot begin until that worker boots and handles its fetch
event. That startup tax is avoidable without changing the offline contract.

## Standards evidence

The Service Workers specification defines a registration-owned
`NavigationPreloadManager` and a `FetchEvent.preloadResponse` promise. MDN
explains that the preload fetch runs in parallel with worker boot and recommends
feature-detecting and enabling it during activation, then consuming the
preloaded response before starting an ordinary fetch.

Sources: [Service Workers — NavigationPreloadManager](https://www.w3.org/TR/service-workers/#navigation-preload-manager),
[MDN NavigationPreloadManager](https://developer.mozilla.org/en-US/docs/Web/API/NavigationPreloadManager).

## Repository decision

- On activation, enable navigation preload only when the registration exposes
  it. A rejected enable request is non-fatal because this is an optimization.
- For same-origin navigations, await the preloaded response first and issue an
  ordinary fetch only when no usable preload was provided. A rejected preload
  gets that ordinary network attempt.
- Pass the resulting response through the existing 5xx handling, canonical
  cache write, and offline fallback. Preload does not bypass update isolation or
  create query-key cache growth.
- Non-navigation assets retain their existing cache strategy.
- Bump the cache behavior schema to `v7`, keeping a worker-only change from
  sharing an active candidate cache when the Vite bundle revision is unchanged.

## Verification and fallback

D01 reads the browser's registered preload state and instruments the nested
production server. A controlled online reload must produce exactly one request
carrying `Service-Worker-Navigation-Preload` and no duplicate ordinary entry
request. The same journey then proves cached reflection recovery offline and
under HTTP 503. J15, J29, and D02 retain full/reduced cache identities and
failed-update rollback.

Browsers without the manager simply use the previous network-first path. If a
preload request fails while an ordinary fetch could still work, the worker tries
that fetch before consulting the cache. This keeps performance support from
becoming a new availability dependency.
