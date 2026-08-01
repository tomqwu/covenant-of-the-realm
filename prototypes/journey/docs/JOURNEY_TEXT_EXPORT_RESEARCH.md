# Completed-journey text export research

Date: 2026-07-31

## Question

The ending already exposes a selectable summary, clipboard copy, and
capability-detected system sharing. What permission-free ownership path remains
when clipboard access is denied, a share sheet is unavailable, and manual
selection is awkward on a touch device?

## Platform evidence

The HTML `download` attribute expresses that a same-origin, `blob:`, or `data:`
hyperlink is intended for local download and lets the page propose a filename;
the user agent sanitizes that name for the operating system. Browser settings
still decide whether the file is saved, opened, or prompts for a destination.

Sources: [HTML Standard downloading resources](https://html.spec.whatwg.org/multipage/links.html#downloading-resources),
[MDN `<a download>` reference](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/a#download).

The File API defines `URL.createObjectURL()` for a local `Blob` and
`URL.revokeObjectURL()` to release it. Revocation makes later dereferencing fail,
so the implementation keeps the URL alive through the synthetic hyperlink click
and revokes it in a later task instead of racing the download.

Sources: [W3C File API](https://www.w3.org/TR/FileAPI/#creating-revoking),
[`URL.revokeObjectURL()`](https://developer.mozilla.org/en-US/docs/Web/API/URL/revokeObjectURL_static).

## Decision

Add **Download journey text** to the completed-journey share panel when the
browser composition root supplies local download support:

- export the exact same bilingual artifact already visible in the textarea;
- use UTF-8 plain text and a stable ASCII filename containing the route seed,
  ending ID, and sortable filesystem-safe UTC timestamp;
- include ending, five decisions, aftermaths, resource deltas, final stats, and
  the validated exact-route link;
- create no backend request, account, hidden metadata, or new persistence record;
- keep copy, manual selection, and device sharing independent.

## Acceptance criteria

- Download is available only after an ending and only from a player action.
- The visible status announces that the artifact was handed to the browser; it
  does not claim a particular filesystem destination.
- The suggested filename ends in `.txt`, contains only stable ASCII tokens, and
  distinguishes different endings/exports of the same route without relying on
  browser-added numeric suffixes.
- A browser test reads the downloaded bytes and compares the important artifact
  fields, including all five numbered decisions and the exact-route link.
- Firefox and WebKit compatibility journey X02 repeats the native Blob download,
  filename, UTF-8 content, and replay-link checks rather than inferring them from
  Chromium behavior.
- Backup export retains JSON media type and filename; journey export uses
  `text/plain;charset=utf-8`.
- Existing copy/manual/share paths remain usable when download is absent.
- If Blob URL or synthetic-link setup throws, announce failure and keep the
  complete visible textarea as the manual recovery path.

## Rejected alternatives

- **PDF export:** larger implementation and rendering surface with no benefit
  for this compact, already textual artifact.
- **Screenshot export:** inaccessible text and poor localization/reflow.
- **Server-generated permalink:** adds an account/network/data-retention boundary
  to a deliberately local-only game.
- **Replace clipboard with download:** desktop copy remains the quickest path and
  should stay independent.
