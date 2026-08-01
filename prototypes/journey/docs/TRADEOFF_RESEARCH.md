# Resource-tradeoff research

## Structural finding

`npm run content:audit` now treats higher provisions, trust, and insight as
mechanically preferable and finds every choice whose other encounter action is
equal or better on all three deltas and better on at least one. Eight of twenty
choice IDs meet that definition. The audit also parses this table, so the
evidence and the executable expected set must change together:

| Region | Encounter | Dominated action | Gate interaction |
| --- | --- | --- | --- |
| Reed Ferry | Broken Rope | `hire-skiff` | both actions normally available |
| Reed Ferry | Unclaimed Letter | `leave-letter` | both actions normally available |
| Pine Ridge | Embers | `take-high-road` | both actions normally available |
| Pine Ridge | Bell in Fog | `mark-path` | both actions normally available |
| Rain Marsh | Submerged Marker | `force-causeway` | the dominating action requires Trust 2 |
| Rain Marsh | Grounded Cranes | `buy-rafts` | the dominating action requires Trust 2 |
| Sky Gate | Names in Stone | `show-paper` | the dominating action requires Insight 3 |
| Sky Gate | Storm at the Pass | `wait-storm` | the dominating action requires Insight 3 |

Old City's `sell-ledger` / `trade-stone` actions instead gain provisions while
losing trust, so neither dominates the collaborative alternative. Those two
encounters are the existing within-game tradeoff control.

Dominance applies only when both actions are available. A gated collaborative
action can still be unavailable, making the pragmatic action necessary rather
than dominated in that state. The audit does not assign value to prose,
character identity, route speed described in fiction, or the player's desired
ending.

## Why this changes the research plan

Choice of Games' [interesting-choice guidance](https://www.choiceofgames.com/2010/03/5-rules-for-writing-interesting-choices-in-multiple-choice-games/)
warns against one option being clearly better and recommends preserving enough
information for intentional choice. Its
[stats guidance](https://www.choiceofgames.com/2011/07/7-rules-for-designing-great-stats/)
also distinguishes expressive decisions from repeated skill optimization.
Failbetter's [choice and consequence essay](https://www.failbettergames.com/news/choice-complicity-and-consequence)
emphasizes that the felt moment of choosing and later consequence are separate
design costs. These sources support measuring which layer is failing before
adding another decision.

The fixed scorecard route contains four dominated scenes and the non-dominated
Old City control:

`ferry-rope → ridge-bell → marsh-marker → city-well → gate-storm`

That makes the current five-session protocol more diagnostic than a simple
repetition count. Compare what the same participant does and says at Old City
with the other regions; do not compare different participants on different
routes.

## Observation classification

After recording behavior without prompting, classify each session:

1. **Delta-driven flattening** — the participant identifies a generally better
   resource option in at least three dominated scenes, shifts to arithmetic, and
   shows meaningfully different deliberation at Old City's genuine tradeoff.
2. **Axis repetition** — the participant describes at least three scenes,
   including Old City, as the same help-others-versus-self decision even though
   Old City's deltas trade off.
3. **Expressive differentiation** — the participant treats pragmatic actions as
   distinct role-play despite their deltas, or explains a desired ending/identity
   that makes the numeric comparison non-decisive.
4. **Unclear intent** — the participant cannot predict what an action is trying
   to do; revise wording before testing mechanics.

## Response selection

- At **3/5 delta-driven flattening**, prototype a content-only effect rebalance
  before adding the vow. Keep all choice IDs, labels, aftermaths, callbacks,
  route shape, and save schema stable. The prototype must remove at least six of
  eight dominance relations, retain four reachable endings and every gated
  action, avoid a first-two-region loss, and rerun the exhaustive ending/text
  audit. Test it with five new participants; kill it if comprehension worsens or
  the pragmatic fiction no longer matches its cost.
- At **3/5 axis repetition**, including the Old City control, prototype the
  three-way expressive vow in
  [`DECISION_PATTERN_RESEARCH.md`](DECISION_PATTERN_RESEARCH.md). Resource
  rebalance alone would not address that observed problem.
- If both reach 3/5, start with the effect-only prototype because it preserves
  persistence and flow. Test the vow only if repetition remains after rebalance.
- Below both thresholds, keep the current control. Do not combine two unproven
  interventions or infer preference from the structural path distribution.

No exact replacement deltas are prescribed here. They must be skeletoned
against ending reachability and tested as a coherent set; changing one scene in
isolation can merely move the dominant route or early-loss boundary.

## Engineering acceptance if rebalance passes

- The dominated-choice audit contains no more than two reviewed IDs.
- All 20 choices remain reachable in the exhaustive state-space test.
- Covenant, homeward, wanderer, and lost remain reachable in unit and browser
  journeys; early loss remains impossible before encounter three.
- Existing valid saves remain coherent. If an authored effect changes, define
  and test a versioned migration rather than silently discarding progress.
- Bilingual effect copy, callbacks, artifacts, and exact-route replay remain
  unchanged except where the tested delta requires a truthful text revision.
- Unit coverage stays at least 99%, all critical browser journeys pass, and the
  second five-session decision/ending comprehension baseline does not decline.
