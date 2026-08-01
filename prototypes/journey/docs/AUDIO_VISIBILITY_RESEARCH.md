# Background-audio visibility research

Date: 2026-07-31

## Question

Ambient audio is already opt-in, looped only after a gesture, and fully
muteable. What should happen after the player switches tabs, minimizes the
window, locks the screen, or moves to another mobile app—especially if the
original `play()` promise has not settled yet?

## Standards evidence

The HTML Standard gives every document a `hidden` or `visible` visibility state
and fires `visibilitychange` after that state changes. The Page Visibility API
is supported across current browser engines and treats a background tab,
minimized window, or screen-off state as hidden.

Sources: [HTML Standard visibility state](https://html.spec.whatwg.org/multipage/interaction.html#page-visibility),
[MDN Page Visibility API](https://developer.mozilla.org/en-US/docs/Web/API/Page_Visibility_API).

MDN identifies the transition to hidden as the point to stop work the player
does not want in the background. Its audio guidance also calls out an important
agency failure: resuming whenever a page becomes visible can start sound without
a fresh player action, because visibility changes are not themselves media
intent.

Sources: [`visibilitychange` usage notes](https://developer.mozilla.org/en-US/docs/Web/API/Document/visibilitychange_event),
[Using the Page Visibility API](https://developer.mozilla.org/en-US/blog/using-the-page-visibility-api/).

## Decision

- Listen to the document's `visibilitychange` event.
- When it becomes hidden, cancel the app's ownership of any pending `play()` and
  pause both pending and active ambience.
- Recheck that ownership after optional audio preparation and before calling
  `play()`; hiding, successful restore/clear, or teardown during the fetch must
  never start media afterward.
- Show a bilingual status when the player returns.
- Do nothing on the visible transition: ambience resumes only from the existing
  explicit player control.
- Keep mute and volume preferences unchanged; hiding a page is a session action,
  not a settings edit.
- Remove the listener at app teardown and make late media promises unable to
  revive playback.

## Acceptance criteria

- Active ambience pauses on a hidden transition and remains paused after the
  page becomes visible.
- A `play()` promise that resolves after hiding is paused again and never marks
  the UI as playing.
- Hiding an already silent page causes no playback or misleading status.
- Returning leaves the play control enabled so the player can opt in again.
- Unit tests cover active, pending, idle, visible, and teardown lifecycles at the
  existing coverage threshold.
- A named production-browser journey proves the real document listener and
  player-controlled restart.

## Rejected alternatives

- **Continue in the background:** wastes resources and can leave sound playing
  from a tab or app the player is no longer viewing.
- **Automatically resume on visible:** treats a browser/OS visibility transition
  as permission to make sound.
- **Persist the paused state as mute:** changes a durable player preference for a
  temporary lifecycle event.
- **Use `blur`/`focus`:** those window signals do not represent the standardized
  hidden cases such as screen lock and fully obscured pages.
