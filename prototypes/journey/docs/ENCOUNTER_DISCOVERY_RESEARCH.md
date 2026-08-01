# Authored encounter discovery research

## Player gap

The game exposes 32 deterministic route combinations built from ten authored
encounter variants. Exact replay and five recent routes make old journeys
recoverable, but the chronicle previously tracked only four endings. After one
completion, a player had no visible evidence that five unseen scenes remained.

## Comparable evidence

The official *A Highland Song* page ties replay to route discovery: paths include
hidden alternatives, collected map fragments reveal faster routes, and one trip
cannot uncover the landscape's deepest secrets. Its framing is discovery rather
than an abstract achievement score.

The official *80 Days* page similarly presents hundreds of journeys and
thousands of routes, calls the game massively replayable, and pairs that route
variety with sharing/loading journeys. This project is much smaller, so it
should expose its authored breadth honestly rather than imitate the scale.

Sources: [A Highland Song — official game page](https://www.inklestudios.com/a-highland-song/),
[80 Days — official game page](https://www.inklestudios.com/80days/).

## Decision

- Add one compact chronicle row per region, with two encounter-title slots.
- Name a slot only after a completed journey includes that encounter; use a
  neutral bilingual unknown label beforehand.
- Show a direct `n/10` discovery count without points, badges, toast rewards, or
  completion pressure.
- Store a bounded ten-ID discovery set separately from the newest 128 journey
  records so history eviction cannot erase knowledge.
- Accept legacy chronicles without that field. Seed-only records derive their
  deterministic route; the next new completion writes the canonical authored-
  order set.
- Preserve all derived discoveries when an oversized version-1 backup is
  compacted before explicit restore.
- Persist how many encounters a completed record actually reached. An early
  lost ending reveals only that journal-backed route prefix, never later
  encounters from the same seed.

Only completed routes reveal titles. Merely receiving a shared link does not
claim discovery, and unseen titles remain concealed.

## Acceptance evidence

- Unit tests validate the optional schema field, reject unknown/duplicate IDs,
  derive seed-only routes, preserve discoveries across eviction/compaction, and
  hold exact 100% coverage.
- J33 completes two complementary exact routes through the rendered UI and
  proves the chronicle moves from 5/10 to 10/10 with both ferry titles visible.
- J03 loses after three regions and proves exactly three encounter titles are
  known; the two unvisited regions on that route remain concealed.
- J25 proves all ten discoveries survive oversized legacy-backup migration.
- J08 expands the new ledger at 360 px, requires no horizontal overflow, and
  retains its zero-violation Axe audit.

## Kill criteria

Do not add encounter-specific trophies, pop-up celebrations, or random route
rerolls. Revisit route selection only if external playtesting shows that seeing
unrevealed slots motivates replay but repeated random seeds prevent players from
acting on that motivation.

The static control does not currently justify bias: after the scorecard's fixed
seed 4242, the ordinary deterministic **New route** result changes four of five
regional encounter variants. A theoretically perfect complementary route would
improve only one slot, so implementation without observed friction would tune a
metric rather than solve a player problem.

Do not ask participants to replay. If one independently starts another route,
record the encounter count before and after, which titles repeat, and any
verbatim reason for stopping. Prototype an unseen-biased seed look-ahead only if
at least two of five participants both (a) initiate replay because of the ledger
and (b) describe repeated encounters from the generated next route as blocking
that goal. The prototype must still change the seed/route, remain deterministic,
terminate in a bounded search, retain exact-route links, and fall back to the
ordinary non-colliding route after 10/10 discovery. Kill it if players perceive
the bias as an achievement grind or if the natural generator already supplies
enough novelty.
