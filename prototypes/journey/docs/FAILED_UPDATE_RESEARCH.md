# Failed offline-update resilience research

Date: 2026-07-31

## Question

The game installs a new revision into a separate cache and waits for player
approval before activation. What happens if one required asset returns an error
during that background installation?

## Standards evidence

An install event extends its lifetime with `event.waitUntil()`. If that promise
rejects, the install fails and the installing worker is discarded; this is the
standard mechanism for preventing a worker from becoming installed before all
of its required cache is ready.

Source: [MDN `ExtendableEvent.waitUntil()`](https://developer.mozilla.org/en-US/docs/Web/API/ExtendableEvent/waitUntil).

During an update, the previous worker remains responsible for controlled pages
until a new worker installs successfully and later activates. A failed update is
thrown away while the current worker remains active.

Sources: [MDN service-worker update lifecycle](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API/Using_Service_Workers#updating_your_service_worker),
[The service-worker lifecycle](https://web.dev/articles/service-worker-lifecycle#updates).

The browser discards the failed worker, but application-created Cache Storage
entries are a separate resource. The game therefore owns cleanup of a partially
populated revision cache.

## Decision

- Keep every scope, behavior schema, precache-list signature, revision, and data
  mode in a distinct cache. The path signature prevents a core-list-only worker
  change from aliasing the active cache when the JavaScript bundle is unchanged;
  see [`PRECACHE_IDENTITY_RESEARCH.md`](PRECACHE_IDENTITY_RESEARCH.md).
- During install, allow every independent shell fetch to settle so no late write
  races cleanup.
- If any required response is non-successful or any cache operation rejects,
  reject `waitUntil()` and best-effort delete only the failed revision cache.
- Never delete the active worker's prior cache during install; successful old
  caches remain activation-owned.
- Do not announce an update until a complete worker actually reaches waiting.

## Acceptance criteria

- A real core-asset HTTP 503 makes the new worker become `redundant` rather than
  waiting or active.
- The currently active controller URL does not change and no update UI appears.
- No cache name for the failed revision remains after all install work settles.
- The old controlled page retains its reflection and reloads it offline after
  the failed attempt.
- Existing successful full/reduced installations and explicit update activation
  continue to pass.

## Rejected alternatives

- **Reuse the active cache during install:** a partial new build could corrupt
  the only known-good offline shell.
- **Activate with missing optional/core files:** the worker cannot distinguish a
  temporary server fault from a safe feature omission after installation has
  begun; provisioning mode must decide optionality before fetching.
- **Delete every project cache on failure:** would turn an update problem into
  offline data loss for the stable version and other subpath deployments.
- **Show an update error banner:** the current game remains usable and the
  browser may retry later; a persistent player-facing error adds no recovery
  action beyond staying on the already-active build.
