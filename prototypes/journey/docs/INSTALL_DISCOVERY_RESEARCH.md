# Install-discovery research

## Question

The production game already satisfies the installable PWA contract and works
offline after installation. Should the game add its own **Install** button, or
leave installation to browser UI until real players show a discovery problem?

## Platform evidence

Browsers can build their ordinary install prompt from the manifest name and
icons. A custom prompt depends on `beforeinstallprompt`: the page must retain
the event, expose its own UI, and later call `prompt()` from a player action.
That retained event can be used only once.

The event is limited-availability and lives in a manifest-incubation proposal,
not the interoperable Web App Manifest standard. Capturing it with
`preventDefault()` can suppress the browser's own install UI. It does not cover
iOS installation: Chrome and Edge on iOS cannot install PWAs, while Safari uses
its Share → Add to Home Screen path. When no event fires, script has no other
way to trigger a browser prompt.

Sources: [web.dev installation prompt](https://web.dev/learn/pwa/installation-prompt/),
[MDN `beforeinstallprompt`](https://developer.mozilla.org/en-US/docs/Web/API/Window/beforeinstallprompt_event),
[MDN installing web apps](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Installing).

## Promotional screenshots are a narrower fallback experiment

Chrome can enrich its existing install sheet when a manifest supplies a
description and at least one form-factor screenshot; manifests without one keep
the ordinary prompt. This is less intrusive than intercepting
`beforeinstallprompt`, but it is not currently a core interoperable member. The
July 2026 Web Application Manifest draft says `screenshots`, `description`, and
`categories` moved to the non-normative Application Information work, while the
Chrome documentation still describes richer install UI as experimental.

Sources: [Web Application Manifest — Application Information](https://www.w3.org/TR/appmanifest/#application-information),
[Chrome richer PWA installation UI](https://developer.chrome.com/blog/richer-pwa-installation).

Do not ship high-resolution promotional assets merely to decorate one vendor's
sheet. If the install-discovery gate passes, test this lower-risk option before
capturing the prompt: generate one narrow and one wide screenshot from the
verified production artifact, keep both deployment-relative and outside the
core offline precache, cap their combined bytes, validate real dimensions and
form-factor metadata in D01, and confirm ordinary installability when a browser
ignores them. Kill them if sessions show no increase in understanding that the
game becomes an offline local app.

## Current decision: retain native discovery

Do not add a permanent or Chromium-only install control yet. The current
manifest, ordinary/maskable/iOS icons, nested-path deployment, full/reduced
offline caches, and browser installation UI already provide the capability.
Adding an unavailable button would be false on unsupported/already-installed
states; intercepting the event could make native discovery worse.

## Evidence gate

Extend the five-session scorecard without explaining installation beforehand.
After the ending ask, “If you wanted to return to this journey later, what would
you do?” Record observable attempts separately from hypothetical preference.

Prototype a custom install affordance only if at least two of five participants
explicitly try to install/add the game, cannot discover the browser path, and
ask for an in-game route. Merely saying “I would bookmark it,” or not mentioning
installation, does not satisfy the gate.

If the gate passes:

- test manifest screenshots first because ignored members preserve the native
  prompt and require no new in-game control;
- render the action only after an actual retained `beforeinstallprompt` event;
- place it after a completed journey or in Reading settings, never before play;
- consume it once, then remove it after acceptance or dismissal;
- keep browser-native installation and the game fully usable when the event is
  absent;
- test accepted, dismissed, already-installed, unsupported, language, focus,
  and 360px states with injected platform adapters rather than user-agent
  sniffing;
- write separate Safari instructions only if the same sessions show an iOS
  discovery failure, and never show them in standalone display mode.

Kill the prototype if players mistake install for account/cloud backup, if the
control appears without an actionable platform event, or if suppressing native
UI reduces successful discovery in the same five-session comparison.
