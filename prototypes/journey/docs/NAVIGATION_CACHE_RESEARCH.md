# Bounded navigation-cache research

## Problem

Exact-route URLs intentionally include a seed, five encounter IDs, and sometimes
a locale. The seed space is effectively unbounded. The network-first worker was
storing each successful navigation response under the full request URL, even
though every one of those URLs returns the same static entry document and the
client reads the route from `location.search`.

That behavior could grow one cache entry per opened/shared route for no offline
benefit. The worker already falls back to the cached scope home when an exact
navigation is absent.

## Platform evidence

The Cache API stores request/response pairs. Query strings participate in cache
matching unless `ignoreSearch` is explicitly requested, whose default is
`false`; `put()` replaces only a matching request key.

Sources: [Service Workers — Cache `put()`](https://www.w3.org/TR/service-workers/#cache-put),
[MDN — Cache keys and `ignoreSearch`](https://developer.mozilla.org/en-US/docs/Web/API/Cache/keys).

Using `ignoreSearch` for all reads would be too broad because future assets may
legitimately vary by query. The safe boundary is narrower: canonicalize only
successful navigation writes to the registration scope's home URL.

## Decision

- A successful network navigation still returns its live response to the page.
- Its response clone is stored only under `new URL("./",
  registration.scope)`, replacing the one canonical entry document.
- Asset requests retain their exact request keys and existing cache-first or
  network-first strategies.
- Offline exact-route navigation misses its unique request key, then uses the
  canonical home fallback. The client still validates and consumes the query
  string from the browser URL, so deterministic route behavior is unchanged.
- Cache behavior schema advances to `v6`, preventing an active v5 worker from
  sharing the changed write contract.

## Verification

J15 reloads a canonical URL containing seed and route parameters under the
production worker, opens the active full cache, and requires exactly one home
navigation key with no query string. It then saves a reflection, reloads
offline, and opens an uncached exact-route URL successfully through the same
home fallback.

J29 retains the reduced-data cache identity and optional-audio behavior. D01
retains nested-scope offline navigation and explicit update activation; D02
retains failed-install rollback.
