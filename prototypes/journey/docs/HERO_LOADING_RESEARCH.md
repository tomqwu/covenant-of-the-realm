# Hero landscape loading research

## Problem

The 620 KB ink landscape is the only large core visual and fills the first
viewport, but its URL was declared by JavaScript after the module bundle ran.
The browser could not discover that stable background-image request while
scanning the initial HTML.

## Platform evidence

`<link rel="preload" as="image">` lets a document declare an image that will be
needed soon, before the later CSS or JavaScript reference is processed. MDN
documents preload as widely available and notes that a correctly typed response
can be cached and reused by the eventual request.

Source: [MDN — `rel="preload"`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Attributes/rel/preload).

web.dev's LCP guidance calls out CSS background images specifically: when the
critical image is otherwise not discoverable from the initial response, expose
it through an image preload and use `fetchpriority="high"` for the likely hero.
Fetch priority remains a hint; the browser retains scheduling authority.

Sources: [Optimize Largest Contentful Paint](https://web.dev/articles/optimize-lcp),
[Optimize resource loading with Fetch Priority](https://web.dev/articles/fetch-priority).

## Decision

- Add one relative image preload for `./assets/journey-scroll.jpg` to the source
  document, with its JPEG type and high fetch-priority hint.
- Render the decorative landscape as an ordinary relative `<img>` inside its
  presentation-only figure. The preload and element resolve the same URL
  against the document base, so the response is reusable and a nested
  deployment stays relocatable. Stylesheet-owned `data-progress` states move
  `object-position` without a JavaScript-set inline style.
- Do not preload audio: it is optional, gesture-owned, and deliberately omitted
  from reduced-data installation.
- Do not add a remote CDN or alternate image format merely for this hint; both
  would change the already-audited privacy/offline boundary.
- Keep the landscape in reduced-data mode. The existing research classifies it
  as core authored presentation; this increment changes discovery timing, not
  the full/reduced asset contract.

## Evidence contract

- The production artifact checker requires the exact relative preload, image
  destination, MIME type, and priority hint.
- D01 resolves that link under `/journey/`, then requires exactly one page-level
  Resource Timing entry for the landscape after the rendered image uses
  it. This catches an URL/CORS mismatch that would fetch the same bytes twice.
- The independent worker installation may fetch its own strict cache copy. That
  request belongs to offline installation, not duplicate page presentation.
- Offline reload, failed-update rollback, and the reduced-data cache journey
  must remain green.

## Rejected alternatives

- **Inline the image:** would expand every HTML navigation by hundreds of
  kilobytes and remove the worker's independently addressable asset.
- **Set the background directly in hashed CSS:** still hides the request behind
  stylesheet discovery and complicates the document-relative public path.
- **Preload every visual/audio asset:** preload is for near-term critical work;
  doing so would compete with the script and violate explicit audio ownership.
