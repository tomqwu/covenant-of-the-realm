# Replay and discovery research

Date: 2026-07-31

## Question

The chronicle remembers completed paths and discovered endings, but exposes only
an aggregate journey count and four ending marks. What is the smallest postgame
pattern that makes replay purposeful without turning this reflective journey
into an achievement checklist?

## Comparable patterns

### A journey can be an executable artifact

inkle describes *80 Days* as supporting both sharing a journey and loading
another player's journey. That makes the route more than a receipt: it is a
direct re-entry point. The current copied same-route URL now satisfies the
external-sharing half of this pattern, but a player's own older local routes
remain inaccessible after starting another journey.

Source: [80 Days — official game page](https://www.inklestudios.com/80days/).

### Replay should point toward unseen narrative, not repetition alone

The official *A Highland Song* page explicitly says one journey cannot reveal
the Highlands' deepest secrets and describes its story as a weaving whose
discoveries depend on where the player goes. *Overboard!* similarly frames
repeat play around uncovering secrets and finding a better ending. Both make a
case for retaining concrete prior paths so the player can deliberately compare
them with a new one.

Sources: [A Highland Song — official game page](https://www.inklestudios.com/a-highland-song),
[Overboard! — official game page](https://www.inklestudios.com/overboard/).

### Persistent discovery need not become a trophy system

ChoiceScript's official achievement guide defines achievements as durable
records that survive restart, but also advises against opaque hidden
achievements because they do not encourage discovery. This project's ending
marks already provide lightweight persistent discovery. Adding points, banners,
or dozens of named tasks would compete with the game's tone rather than solve
the route-recall gap.

Source: [Achievements in ChoiceScript](https://www.choiceofgames.com/make-your-own-games/achievements-in-choicescript/).

## Decision

Add a bounded recent-journey ledger inside the existing chronicle:

- preserve the exact five encounter IDs on new journey records;
- list at most the five most recent records with ending, seed, and final stats;
- let the player replay one entry directly in the current language;
- retain compatibility with legacy records that have only a seed;
- keep undiscovered ending names concealed and add no points or banners.

This closes a concrete ownership/replay gap, reuses the existing chronicle, and
does not alter the five-region rules or the playtest-gated decision structure.

## Follow-up: authored encounter discovery

The recent-route ledger solved local re-entry, but the ending-only discovery
count still did not tell a player whether unseen authored encounters remained.
The shipped follow-up adds five compact region rows with two concealed title
slots each. Only encounters actually visited in a completed record become
named; their ten-ID set is stored independently of the bounded journey list. Early lost records
contribute only their visited journal prefix. Legacy seed-only
records derive their deterministic routes and persist the explicit set on the
next completion. This retains the no-points/no-banners decision above while
giving replay a concrete, quiet direction. The full decision record is in
[`ENCOUNTER_DISCOVERY_RESEARCH.md`](ENCOUNTER_DISCOVERY_RESEARCH.md).

## Acceptance criteria

- A newly completed chronicle record stores the exact route independently of
  future generator changes.
- Selecting a recent journey resets current progress and opens that route's
  first encounter while retaining the chronicle.
- Replacing unfinished progress requires two consecutive presses on the same
  route; any other click, change, input, or story action disarms it.
- Legacy seed-only records remain valid and replay using deterministic seed
  generation.
- Only five recent entries render even when more records exist.
- The sidebar calls the bounded, de-duplicated count “Routes recorded,” not a
  lifetime completion count.
- Keyboard, touch, narrow-screen, persisted-text, and backup behavior remain
  covered by the existing gates; one named browser journey proves route recall.

## Rejected alternatives

- **Achievement points or pop-up banners:** motivationally louder than the game
  and unnecessary while ending discovery already persists.
- **Reveal every ending title in advance:** more directive, but it spoils the
  quiet discovery the current marks preserve.
- **Unlimited full decision transcripts in the sidebar:** duplicative of the
  final journal and likely to create reflow/performance problems after many
  runs.
