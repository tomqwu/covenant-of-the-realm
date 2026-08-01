# Host HTTP-cache contract

## Why the service worker is not the only cache

The game controls its own Cache Storage, but browsers and intermediary hosts
also have an HTTP cache. The release identity in generated HTML combines the
hashed app bundle with every `public/` path and byte. A same-path image, audio,
manifest, icon, or worker edit therefore produces a new candidate worker cache.

The build injects that release identity into the stable `sw.js` body, so an old
page can still discover a byte-distinct Worker. A long-fresh entry document can
nevertheless return the old bundle after activation and overwrite the new
Worker's canonical runtime page response. The public-tree digest therefore does
not remove the need to revalidate the outer document.

MDN's [HTTP caching guide](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Caching)
recommends `Cache-Control: no-cache` for main HTML so it can be stored but must
be revalidated, while content-hashed subresources can use a long lifetime with
`immutable`. `no-store` is not needed for this non-personalized static document
and would unnecessarily discard useful browser behavior such as the
back/forward cache.

The registration already uses `updateViaCache: "none"`; MDN defines that as
never consulting the HTTP cache for service-worker update checks. That protects
the worker script check but does not make the outer HTML discovery request
fresh. Source:
[MDN `updateViaCache`](https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration/updateViaCache).

## Required production policy

Configure the final static host with these semantics:

| Response | Cache policy | Reason |
| --- | --- | --- |
| entry/start HTML, including query variants | `Cache-Control: no-cache` | present the current bundle/public revision on every online navigation while allowing conditional `304` responses |
| `sw.js` | `Cache-Control: no-cache` | defense in depth around worker update checks; keep the URL response revalidatable |
| content-hashed `assets/index-*.js` and `assets/index-*.css` | `Cache-Control: public, max-age=31536000, immutable` | the URL changes with content |
| `manifest.webmanifest`, icons, landscape, and ambience | `Cache-Control: no-cache` | these public URLs are stable while their bytes may change |

Equivalent immediately-stale/revalidate directives are acceptable only when
the chosen host cannot emit `no-cache`. Do not assign `immutable` to HTML,
`sw.js`, the manifest, icons, landscape, or audio. Preserve `ETag` or
`Last-Modified` when the host supplies them so unchanged revalidation stays
cheap.

The worker's atomic install requests the entry document and every release asset
with `cache: "reload"`. The reduced-data path omits ambience; its later explicit
audio preparation also requests revalidation on an empty release cache. These
are internal safeguards, not substitutes for the outer document header.

## Live verification

After a hosting target exists:

1. inspect response headers for the final start URL, `sw.js`, one fixed-name
   public asset, and both hashed bundles;
2. publish a harmless same-path public-asset byte change;
3. open an already installed online copy without clearing browser data;
4. confirm the update notice appears, activate it, and verify only the new
   release cache remains;
5. go offline and complete/resume the saved journey; and
6. record the host, paths, exact headers, release identifiers, browser, and
   elapsed update-discovery time in the release evidence.

If a selected platform does not permit custom response headers, record its
actual policy and measured update latency. Do not claim immediate update
discovery from local D01 alone; either accept/document the host limitation or
choose a host that can enforce the table above.

D01 runs the production artifact under this exact cache-policy split before its
install/offline/update assertions. That proves compatibility with the intended
headers, but it is not evidence that a future external host actually emits
them; the live verification remains mandatory.
