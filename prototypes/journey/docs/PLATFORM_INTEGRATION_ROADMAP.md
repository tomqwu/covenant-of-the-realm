# Installed-platform integration roadmap

## Decision

Do not add operating-system entry points to the current release. The web app is
already installable, resumes its single autosave on an ordinary launch, accepts
a validated backup through an explicit two-step restore, and shares an exact
route from a direct player action. None of the platform additions below solves
an observed player problem yet.

This is a rejection of speculative surface area, not a permanent ban. Each
candidate has a player-evidence gate and a state-ownership contract that must be
met before implementation.

## 1. Manifest shortcuts — standard, but no distinct safe task

The W3C Web Application Manifest defines `shortcuts` as links to key tasks or
pages, normally exposed through an installed app's operating-system context
menu. Invoking one launches its in-scope URL.

Source: [W3C Web Application Manifest — shortcuts](https://www.w3.org/TR/appmanifest/#shortcuts-member).

- **Resume journey** duplicates the ordinary app launch, which already restores
  the current scene.
- **New journey** would need a replay URL. Sending `?replay=1` directly would
  replace unfinished progress before the app can ask for confirmation, breaking
  the ownership rule already enforced for recent-route recall.
- A shortcut is justified only if at least **2/5** observed players ask for a
  distinct operating-system action after installing the game.
- Any prototype must land on an in-app confirmation state before replacing an
  unfinished save, retain the ordinary launch path, work when offline, and add a
  production browser journey for the shortcut URL.

Until there is both player evidence and a distinct safe task, omit `shortcuts`.

## 2. Backup file handling — useful shape, limited platform reach

The `file_handlers` manifest member associates file types with an installed PWA
at the operating-system level. MDN marks it limited availability, experimental,
and not Baseline; the launched app still has to consume the file in JavaScript.

Source: [MDN — `file_handlers`](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Manifest/Reference/file_handlers).

Opening a `.json` backup from a file manager could shorten the current picker
flow, but a generic JSON association would be noisy and the launch path must not
turn “open” into “restore.” Reconsider only if at least **2/5** players explicitly
try or ask to open a downloaded game backup from their file manager.

A compliant prototype must:

1. associate a game-specific extension and MIME type rather than all JSON;
2. validate the same version, byte limit, schema, and reachable-state invariants;
3. stage the parsed data without writing any local record;
4. require the same separate explicit restore action;
5. keep the existing file input as the interoperable fallback; and
6. prove invalid, duplicate, and out-of-order launch files cannot mutate data.

Automatic restore on launch is a kill condition.

## 3. Launch handling — conflicts with exact-route ownership

The experimental, non-Baseline `launch_handler` member can ask a supporting
browser to open a new client, navigate an existing client, or focus an existing
client and deliver the target through `Window.launchQueue`.

Source: [MDN — `launch_handler`](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Manifest/Reference/launch_handler).

Forcing a single existing window is not currently safe. `focus-existing` could
leave an exact shared-route launch unapplied unless custom queue handling is
added; `navigate-existing` could replace an unfinished scene. The present
multi-tab and back/forward-cache guards prefer an explicit stale-session block
over silently choosing a winner.

Reconsider only if at least **2/5** installed-app sessions encounter confusing
duplicate windows. A prototype must preserve exact-route URLs, surface a
confirmation before replacing unfinished progress, retain normal multi-window
behavior on unsupported browsers, and pass the existing stale-tab/BFCache
ownership journeys. Dropping or silently applying a queued route is a kill
condition.

## 4. Inbound share target — no current content contract

The `share_target` manifest member lets an installed PWA receive operating-system
shares through a declared GET or POST action. MDN marks it experimental,
limited availability, and not Baseline; it also requires all incoming data to be
validated before use.

Source: [MDN — `share_target`](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Manifest/Reference/share_target).

The game already has the opposite, evidenced need: outbound sharing of a
completed journey and exact replay URL. It has no authored meaning for arbitrary
inbound text, URLs, or files. Adding a target now would create a new untrusted
input parser and installed-only route without a player task.

Reconsider only if at least **2/5** players independently try to send a journey
artifact into the installed app from an operating-system share sheet. Prefer
opening the already validated exact URL. Any broader prototype must accept only
an explicit game artifact, stage rather than apply it, bound input size, reject
cross-origin/invalid routes, and retain the ordinary link/file fallback.

## Evidence collection and priority

Do not prompt participants with feature names. After a normal completion and
return-later question, observe whether they install the game and what they try
from the launcher or file manager. Record the attempted task and the artifact
they expect to survive. The participant and round-level fields are integrated
into [`PLAYTEST_SCORECARD.md`](PLAYTEST_SCORECARD.md), so the four gates can be
calculated from observations rather than retrospective feature enthusiasm.

Priority after a gate is met:

1. a safe standard shortcut, if a distinct task exists;
2. staged backup-file launch, because it maps to an existing validated artifact;
3. launch-window control, only for observed duplicate-window harm; and
4. inbound sharing, only after a concrete accepted-artifact contract exists.

No candidate may weaken offline play, ordinary browser fallback, explicit
restore/replay confirmation, or the rule that incoming platform data is inert
until validated.
