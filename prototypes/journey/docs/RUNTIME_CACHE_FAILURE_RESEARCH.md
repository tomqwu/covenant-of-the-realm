# Runtime cache-write failure research

## Failure boundary

Production installation must fail atomically when a required shell asset cannot
be cached: claiming offline readiness without a complete shell would be false.
That rule does not apply to a later successful online response. If a runtime
refresh is readable but its best-effort cache update fails, returning an old
cached page—or failing the request—would make caching reduce availability.

## Standards evidence

The Service Workers specification requires `Cache.put()` to reject with a
`TypeError` for a response whose `Vary` header contains `*`; it can also fail
with `QuotaExceededError` when the granted storage limit is exceeded. These are
cache-write failures, not failures of the already received network response.

Source: [Service Workers — Cache `put()`](https://www.w3.org/TR/service-workers/#cache-put).

## Repository decision

- Installation keeps strict cache creation and writes inside its atomic
  try/delete boundary.
- Runtime network-first and cache-first handlers treat cache open, match, and
  put as best-effort. A successful network response is returned even when it
  cannot be recorded.
- A network failure still uses an available exact cached response and then the
  canonical entry-page fallback. If Cache Storage itself is unavailable, the
  online request still runs and an offline request fails honestly.
- Failed runtime writes do not delete the already installed cache.

## Executable evidence

D01 serves a fresh controlled navigation with `Vary: *` and a unique head
marker. That header is a deterministic standards-defined `Cache.put()` failure.
The rendered document must contain the network-only marker, proving the worker
did not substitute its older cached entry or fail the navigation. The audit
then removes the header and continues through saved-reflection offline recovery,
503 fallback, and explicit update activation. D02 separately retains strict
candidate-install rollback.
