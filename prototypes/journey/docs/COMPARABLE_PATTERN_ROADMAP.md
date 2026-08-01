# Comparable narrative-pattern roadmap

## Current product boundary

This is a five-decision short journey with one autosaved current state, an
aftermath pause before each continuation, exact-route replay, portable backup,
four ending discoveries, and ten encounter discoveries. Patterns that solve
long-form or many-slot interactive fiction problems are not automatically a fit.

This roadmap records candidates and measurable triggers. It is not permission
to implement them without the stated evidence.

## 1. One-step reconsideration — evidence-gated

Twine's archived Sugarcane format supports bookmark checkpoints and a rewind
menu. That pattern can recover from a mistaken activation, but it also changes
the meaning of committing to a cost.

Source: [Twine Sugarcane story-format reference](https://www.twinery.org/cookbook/twine1/storyformats/sugarcane/index.html).

The current aftermath screen is the only reasonable boundary for a smaller
version: one **Reconsider this choice** action before **Continue**, never a free
history browser after seeing later consequences.

Adopt only if at least two of five observed players either activate the wrong
choice or independently ask to undo before continuing. Kill the idea if players
use it primarily to optimize visible stat deltas, or if it weakens their sense
that a decision has weight. Any prototype must restore the exact pre-choice
state, preserve keyboard focus, and add a full browser journey.

## 2. Qualitative stat interpretation — evidence-gated

ChoiceScript's official introduction uses variables to let earlier choices
affect later outcomes and exposes current values on a stats screen. This game
already does both, including exact choice deltas and a visible trust gate.

Source: [Introduction to ChoiceScript](https://www.choiceofgames.com/make-your-own-games/choicescript-intro/).

A compact qualitative descriptor beside each number—such as low/steady/high—
would be justified only if at least three of five players cannot explain what
one resource changes or why a choice was locked after completing a journey.
Do not hide the numbers or replace exact requirements. Kill the feature if the
existing labels, deltas, and gate copy already support comprehension.

## 3. Explicit save slots — deferred by scope

SugarCube provides player-managed save, load, and delete slots in addition to
story state. That is useful when players maintain several long or divergent
in-progress runs.

Source: [Twine SugarCube saving-games reference](https://www.twinery.org/cookbook/savinggames/sugarcube/sugarcube_savinggames.html).

This game currently has one short current journey, autosave, five exact recent
completed routes, one-time shared routes, and portable JSON backup. Save slots
would duplicate those concepts and add overwrite/delete/conflict UI. Reconsider
only if the authored journey grows beyond 30 measured minutes or at least two
of five players ask to preserve multiple unfinished routes. Prefer versioned
named slots capped at three; never silently overwrite one.

## 4. Achievement banners and points — rejected

ChoiceScript achievements are durable past-deed records that can award points
and display banners; its guide also says hidden achievements are poor at
encouraging discovery. The quiet ending/encounter ledger now supplies visible
replay direction without an extrinsic score or interruption.

Source: [Achievements in ChoiceScript](https://www.choiceofgames.com/make-your-own-games/achievements-in-choicescript/).

Do not add points, platform-style banners, or dozens of named tasks. Revisit
only if the product's tone and player promise deliberately change.

## 5. Delayed-resume recap — evidence-gated

Long-form engines use timestamps, screenshots, descriptions, and metadata to
distinguish several save slots. This game's single short autosave already
restores into a named reflection/encounter with route position and journal.
Do not add a save gallery or modal Continue screen. Run the 24-hour return probe
in [`RESUME_CONTEXT_RESEARCH.md`](RESUME_CONTEXT_RESEARCH.md); only a **2/5**
orientation failure/request threshold authorizes a one-line, data-derived recap.

## Prioritized next evidence

1. Run the five-player scorecard in `PLAYTEST_SCORECARD.md`, recording both
   repetition and completion time.
2. Add two observations: mistaken-choice/undo requests and resource/gate
   comprehension.
3. Ask whether the 5/10 encounter ledger motivates another route, without
   explaining its purpose first.
   If a player independently starts one, record actual discovery gain and
   repeated-title friction; do not substitute stated intent for behavior.
4. Implement at most one candidate whose threshold is met; record the evidence
   and kill result before changing the game.
5. Record attempted install/return-later behavior without teaching the browser
   path; the separate install-discovery gate is in
   [`INSTALL_DISCOVERY_RESEARCH.md`](INSTALL_DISCOVERY_RESEARCH.md).
6. If scheduling permits, run the separate delayed-return probe; do not treat a
   same-session answer about returning later as observed resume disorientation.

Until that evidence exists, the current build is the control condition.
