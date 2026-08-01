# Reduced-data offline installation research

Date: 2026-07-31

## Question

The production worker precaches a complete offline shell, including a 180 KB
ambient loop that is optional and never autoplays. Can the initial install honor
an explicit reduced-data preference without weakening core offline play or
making sound permanently unavailable?

## Platform evidence

`Save-Data: on` represents an explicit user preference to reduce transferred
bytes. MDN recommends reducing optional media and other automatic work when that
signal is present, while also noting that it is not available across every
browser.

Source: [MDN `Save-Data` header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Save-Data).

The corresponding `NetworkInformation.saveData` boolean is available to some
browser JavaScript environments. Service-worker precaching is still prefetching:
it consumes bandwidth, storage, and CPU before a resource is requested. Web
performance guidance therefore recommends avoiding optional prefetch when the
player has enabled Save-Data.

Sources: [Delivering fast and light applications with Save-Data](https://web.dev/articles/optimizing-content-efficiency-save-data),
[Prefetching, prerendering, and service-worker precaching](https://web.dev/learn/performance/prefetching-prerendering-precaching).

## Decision

- Keep the full offline bundle as the default and as the fallback in browsers
  that expose no reduced-data signal.
- When `navigator.connection.saveData === true`, include `saveData=1` in the
  worker script URL and install a reduced cache without the optional ambient
  loop.
- Include `full` or `reduced` in cache identity so a changed preference cannot
  silently reuse a differently provisioned shell.
- Keep HTML, JavaScript, CSS, manifest, icons, and the meaningful landscape in
  both modes; the five-region game remains complete offline.
- On an explicit Play action, fetch the complete audio file before media start.
  The worker treats that optional asset cache-first, so a successful opt-in adds
  it to the current cache and makes later offline playback possible.
- Construct the media element without a source, set `preload="none"`, and only
  then assign the local audio URL. This removes any constructor-time race that
  could begin resource selection before the no-preload preference exists.
- If that fetch fails offline, retain the existing visible silent-play fallback.

## Acceptance criteria

- A fresh reduced-data installation cache contains no ambient audio but does
  contain the complete core shell and landscape.
- Before explicit Play, the page has no Resource Timing entry for the audio URL.
- No `Save-Data` support or a false value preserves the existing full offline
  installation.
- A reduced-data player can explicitly fetch/play ambience online; that exact
  asset then exists in Cache Storage and plays after an offline reload.
- Cache/update isolation and subpath deployment remain intact under the new
  cache schema and data-mode identity.
- The media control remains single-flight while preparation and `play()` are
  pending, and preparation failures remain fully silent.

## Rejected alternatives

- **Remove audio from every install:** saves bytes but weakens the already-shipped
  full offline experience for players who expressed no constraint.
- **Branch on connection speed:** inferred bandwidth is not an explicit request
  to omit content and can fluctuate during installation.
- **Remove the landscape:** it is a core authored presentation asset rather than
  an opt-in enhancement, and already fits its compressed production budget.
- **Disable the Play control in reduced mode:** an explicit later action is a
  clear decision to spend the bytes and should remain available.
