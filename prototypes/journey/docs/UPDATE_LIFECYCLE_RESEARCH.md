# Offline update lifecycle research

This pass began after the actionable feature queue was exhausted. It addresses
the gap between safely caching a new production build and telling a player that
the build is ready to use.

## Primary-source findings

- [MDN's service worker overview](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)
  describes a changed worker installing in the background and then waiting while
  an existing page remains controlled by the prior worker.
- [`ServiceWorkerRegistration.updatefound`](https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration/updatefound_event)
  fires when a registration receives an installing worker; its `statechange`
  event identifies completion of installation.
- The [Service Workers specification](https://www.w3.org/TR/service-workers/)
  defines `skipWaiting()` as the explicit way to allow a waiting worker to
  activate while a client still uses the registration. Activation changes the
  page's controller and fires `controllerchange`.

## Decision

Keep automatic updates conservative. A new worker fully installs and precaches
its isolated shell, but does not call `skipWaiting()` by itself. When an existing
controller is present, the game displays a bilingual status notice without
moving keyboard focus. First installation remains silent.

Cache identity also includes the encoded registration-scope path. Cache Storage
is shared at the origin boundary, so an activating worker deletes older
revisions only for its own mounted path rather than every copy of this project.

Only the player's **Reload to update** action sends `SKIP_WAITING` to the known
waiting worker. The initiating page reloads on the resulting
`controllerchange`. Every other already-controlled tab receives that same
lifecycle event, becomes inert behind a focused alert dialog, and must reload
before it can write or request assets under the new controller. This closes the
mixed-version window created by `clients.claim()` without misreporting a remote
tab's action as local consent. A memory-only tab also warns that reload resets
its session. First installation does not interrupt an initially uncontrolled
page. The initiating action is disabled immediately to prevent duplicate
requests. Normal autosave and backup rules remain unchanged.

The worker calls `clients.claim()` at the start of activation, before
best-effort obsolete-cache enumeration. Existing tabs therefore receive their
controller change before slow cleanup can extend their interactive old-code
window, while `activate.waitUntil()` continues to buffer functional events
until all activation maintenance settles. MDN documents that `claim()` triggers
`controllerchange`; the
[Service Worker lifecycle](https://web.dev/articles/service-worker-lifecycle)
documents the functional-event buffering boundary.

The watcher handles all lifecycle entry points: a worker already waiting when
registration resolves, an installation already in progress, and a later
`updatefound` event. Duplicate observations of one worker do not produce
duplicate listeners.

## Acceptance evidence

- Unit tests cover first install, waiting/in-progress/later updates, duplicate
  observation, local and external activation, controlled/uncontrolled pages,
  inert UI ownership, and teardown at 100% source coverage.
- Deployment audit D01 installs the built PWA beneath `/journey/`, registers a
  distinct second revision, observes the notice, applies it through the rendered
  button, verifies the new controller revision, and retains the saved reflection.
- Deployment audit D04 uses two controlled tabs: one applies an update, while
  the other enters an Axe-clean blocking dialog, reloads explicitly, and retains
  the same saved reflection under the new worker.

## Kill criteria

Remove or revise the prompt if it activates without a player action, steals
focus, reloads before the waiting worker becomes the controller, loses a saved
journey, or mixes assets from two cache revisions.
