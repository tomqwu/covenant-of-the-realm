# Memory-only exit-warning research

## Question

When browser storage is unavailable, the game keeps a complete in-memory
journey and visibly warns that reload will reset it. Should an unfinished route
also register `beforeunload` and ask the browser to confirm every reload, close,
or navigation?

## Platform evidence

MDN identifies unsaved data as the legitimate use case for `beforeunload`, but
also records three material limits: the dialog requires prior user activation,
uses browser-owned generic wording, and is not reliably fired—especially when a
mobile browser is later closed from the operating-system app manager. It also
notes that Firefox excludes pages with `beforeunload` listeners from its
back/forward cache.

Source: [MDN `beforeunload`](https://developer.mozilla.org/en-US/docs/Web/API/Window/beforeunload_event).

The web.dev back/forward-cache guidance recommends conditional listeners only
when absolutely necessary. A cached document can preserve its complete
JavaScript state across an accidental navigation and Back action; a listener
that excludes the page can therefore remove a useful recovery path for the same
memory-only session it is meant to protect.

Source: [web.dev back/forward cache](https://web.dev/articles/bfcache#only_add_beforeunload_listeners_conditionally).

`visibilitychange` and `pagehide` are better lifecycle signals for saving, but
they do not create a writable destination when local storage itself is denied.
They cannot turn the current memory mirror into durable data.

## Decision

Do not add a leave-page prompt to the current release.

- It would make a best-effort desktop warning look like reliable protection on
  mobile when it is not.
- Its generic browser text cannot explain the game's actual recovery options.
- In Firefox it can trade away back/forward-cache restoration.
- It would add a navigation interruption only for an already degraded browser
  mode, while the game currently keeps play, local text/JSON export, and the
  in-page persistence warning available.

The existing contract remains explicit: persistent failure is announced in the
ledger, backup restore is disabled rather than falsely succeeding, journey and
backup export still work, and an update reload repeats the reset warning. A
back/forward-cache restoration rechecks ownership where persistent storage is
available and leaves a memory-only document's own state intact.

## Revisit gate

Reconsider only after at least two independently observed storage-restricted
sessions lose an unfinished route through an accidental desktop navigation or
reload, or two affected players explicitly request a leave warning. Do not count
hypothetical concern or deliberate tab closure.

Any prototype must:

1. attach only after the first unsaved choice in a memory-only unfinished route;
2. remove the listener after persistence becomes available or the route ends;
3. keep the visible warning and export paths because the event remains
   unreliable;
4. verify Chrome and Firefox navigation/Back behavior, including whether the
   page remains eligible for the back/forward cache; and
5. retain the no-warning path for ordinary persistent journeys.

Kill the prototype if it produces prompts on first visit or completed routes,
implies mobile protection, or causes more recoverable Back navigations to reset
than it prevents.
