# Device sharing research

This pass began after the actionable feature queue was exhausted. It asks
whether a completed route should enter the operating system's share sheet while
preserving the game's local-first and cross-browser contract.

## Primary-source findings

- The [W3C Web Share Recommendation](https://www.w3.org/TR/web-share/) defines a
  user-agent-mediated destination chosen by the player; the page cannot choose
  a recipient or learn which destination the player selected.
- [MDN's `navigator.share()` reference](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/share)
  requires a secure context and transient user activation. It also distinguishes
  ordinary cancellation (`AbortError`) from policy, validation, and transport
  failures.
- [MDN's Web Share overview](https://developer.mozilla.org/en-US/docs/Web/API/Web_Share_API)
  marks the API as limited availability and recommends capability detection.

## Decision

Add native sharing only as progressive enhancement on the completed-journey
screen. The system button is rendered only when `navigator.share` exists, and
the API is called synchronously from that button's click handler so transient
activation is retained. Where `canShare` exists, the exact payload is checked
before opening the share sheet.

The payload is the same bilingual, selectable artifact used by clipboard copy,
including the validated seed and five-encounter route signature. Clipboard and
manual selection remain independent universal fallbacks. Canceling a share
sheet is a neutral player action and produces no error; a real failure announces
the fallback without hiding or changing the artifact.

No receiver/target registration is added. The game does not accept external
share data, inspect destinations, add tracking parameters, or send content
before the player's explicit action.

## Acceptance evidence

- Unit tests cover supported, `canShare`-rejected, throwing capability probes,
  failed, canceled, and post-teardown results at 100% source coverage.
- Browser journey J13 injects the platform boundary, opens sharing through the
  rendered button, and verifies the title, authored aftermath, and exact-route
  link in the native payload before replaying it.
- The existing selectable textarea and clipboard path continue to operate when
  native sharing is absent or rejected.

## Kill criteria

Remove the enhancement if it requires an analytics/backend dependency, exposes
a target without explicit activation, hides the manual artifact, or causes a
supported browser to lose completion/replay functionality.
