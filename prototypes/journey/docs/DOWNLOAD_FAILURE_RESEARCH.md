# Local-download failure research

## Boundary

The HTML download algorithm lets a browser handle a hyperlink as a download,
and the `download` attribute supplies a suggested filename. It does not give the
application a durable file handle or an acknowledgement that bytes reached a
particular filesystem destination. The app first has to construct a Blob URL,
create and dispatch a link, and later release that URL.

Sources: [HTML download processing](https://html.spec.whatwg.org/multipage/links.html#downloading-resources),
[File API object URLs](https://www.w3.org/TR/FileAPI/#creating-revoking).

The existing success wording already says the artifact was handed to the
browser rather than claiming it was saved. The remaining failure was earlier:
Blob URL or synthetic-link setup could throw synchronously, escape the event
handler, and still leave no recoverable backup UI.

## Decision

- Treat local download as a progressive enhancement boundary supplied by the
  composition root.
- Catch synchronous setup failure at each player action and never announce
  success from that path.
- Keep completed-journey recovery in the selectable summary already on screen.
- For a backup, reveal the exact generated version-1 JSON in a labeled read-only
  textarea, because no equivalent artifact was otherwise visible.
- Clear that manual JSON after any state or preference mutation so stale data is
  not presented as the current backup.
- Make anchor cleanup exception-safe and schedule object-URL revocation even if
  append or click throws after URL creation.

## Acceptance evidence

- Unit tests force the download adapter to throw and cover both statuses, the
  parseable backup fallback, retained journey text, and focus ownership at exact
  100% statement/branch/function/line coverage.
- J28 continues to read a successfully downloaded UTF-8 journey file.
- J31 disables `URL.createObjectURL` in production Chromium, parses the exposed
  backup JSON, completes all five regions, then proves journey export falls back
  to the intact exact-route summary.
- A01 scans the expanded failure state and requires zero Axe violations.

## Kill criteria

Do not add a server upload, account, or File System Access permission prompt for
this compact local artifact. The selectable fallback is portable across the
supported engines and preserves the game's local-only boundary.
