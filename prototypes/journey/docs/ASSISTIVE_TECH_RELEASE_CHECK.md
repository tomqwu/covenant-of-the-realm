# Assistive-technology release check

## Purpose

Axe, semantic-DOM assertions, forced-colors emulation, focus tests, and a full
keyboard journey catch repeatable implementation defects. They do not prove
what a real screen reader announces or how a mobile reader's gestures expose
the game. Run this checklist against the final production URL before the first
public release and after any semantic/focus/dialog change.

W3C's [Easy Checks](https://www.w3.org/WAI/test-evaluate/preliminary/)
requires logical focus order, visible focus, full keyboard operation, and no
keyboard trap. Its
[Focus Order explanation](https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html)
also distinguishes visual order from the programmatic reading sequence. The
cross-tab interruption follows WAI's
[Alert Dialog pattern](https://www.w3.org/WAI/ARIA/apg/patterns/alertdialog/).

## Minimum matrix

Use current stable versions and record exact versions; do not claim combinations
that were not run.

- one desktop screen reader/browser pair: NVDA with Firefox/Chrome on Windows,
  or VoiceOver with Safari on macOS;
- one mobile pair: VoiceOver with Safari on iOS/iPadOS, or TalkBack with Chrome
  on Android; and
- keyboard-only desktop with the reader off, at 200% zoom and again at the
  narrow 320 CSS-pixel reflow boundary.

At least one pair must complete the Chinese interface and one the English
interface. A bilingual reader is useful but not required; the language-switch
control itself must be pronounced in its target language.

## Task script and acceptance

Start from a fresh browser profile at `?seed=4242`. Do not teach landmarks or
shortcuts before the tester attempts each task.

1. **Orient and begin.** The document title and active language are correct.
   Landmark/headings navigation reveals header, journey navigation, progress
   complementary region, and one main story. The first Tab exposes **Skip to
   journey**, which reaches the intro `h1`; the next action begins play.
2. **Understand one choice.** Each choice announces its action label, detail,
   exact resource effect, and button state as one operable control. A locked
   response remains reachable in sequential navigation, announces disabled
   state and its visible numeric requirement, and cannot be activated by Enter,
   Space, pointer, or its number shortcut.
3. **Follow all scene changes.** After each selection, focus moves to the new
   aftermath/ending heading exactly once. It is not duplicated by a live region.
   A persistent storage, update, audio, backup, or share status is not
   re-announced merely because the story rerendered. Continue through all five
   regions and confirm the journal count reaches 5/5.
4. **Use language and reading settings.** The switch says “Switch to English”
   or “切换到中文” in the target language. Text, motion, and contrast groups have
   legends and selected radio states. Changing them does not lose the current
   scene or focus context.
5. **Use optional audio silently and audibly.** Play/mute controls announce
   pressed state, the range has a volume label/value, and a playback failure or
   hidden-page pause is announced without blocking silent completion.
6. **Inspect journal and chronicle.** Both disclosures announce expanded state.
   Regions, decisions, resource deltas, aftermaths, discoveries, and a recent
   route are read in coherent order. An unfinished-route replacement requires
   the same second confirmation described visually.
7. **Exercise local-data safety.** Backup selection announces validation status
   but never restores automatically. Clear-data first announces the destructive
   consequence; any intervening control disarms it. Do not use a participant's
   real backup or browser profile.
8. **Trigger a cross-tab conflict.** The alert dialog is announced immediately,
   its title/description are associated, focus starts on **Load latest progress**,
   and Tab/Shift+Tab stay there. Background controls are unavailable. The action
   remains reachable while reload is pending.
9. **Finish and export.** The ending title/body and 5-entry journal are complete.
   The selectable summary has a label, the copy/download/device actions have
   distinct names, and status feedback is announced without moving focus.

## Evidence record

| Field | Result |
| --- | --- |
| Release revision / live URL |  |
| Device, OS, browser |  |
| Screen reader and version |  |
| Interface language |  |
| Completed without pointer or facilitator | yes / no |
| Duplicate/missing scene announcement | none / details |
| Repeated unrelated status announcement | none / details |
| Focus loss or trap | none / details |
| Unnamed/misnamed control or state | none / details |
| Reflow/zoom obstruction | none / details |
| Linked issue IDs and retest result |  |
| Tester and date |  |

Release with zero blockers: any unavailable task, lost focus that prevents
progress, unannounced destructive/restore state, unreadable locked requirement,
wrong document/part language, repeated unrelated status speech that obscures a
scene, or unreachable conflict reload is a blocker.
Record non-blocking verbosity or pronunciation friction separately rather than
discarding it; it can inform the next evidence-gated iteration.
