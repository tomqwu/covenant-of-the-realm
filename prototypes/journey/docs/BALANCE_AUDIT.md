# Deterministic balance audit

The engine test enumerates every valid decision branch for seeds 1–128. This is
a structural audit, not a substitute for human judgment about emotional pacing.

## Verified state space

- 32/32 possible five-region encounter combinations are generated.
- Across seeds 1–128, every full combination appears 3–5 times and every
  individual encounter appears 63–65 times; reachability is not hiding severe
  exposure skew.
- All 20 authored choices are selectable on at least one valid path.
- 1,664 terminal paths are reached without an invalid or stranded state.
- 384 of 3,840 offered choice opportunities (10%) are intentionally locked by a
  visible stat requirement; every state still has an enabled action.
- Ending distribution is 640 covenant (38.5%), 384 homeward (23.1%), 512 lost
  (30.8%), and 128 wanderer (7.7%).
- Eight of the twenty authored choice IDs are mechanically Pareto-dominated
  when both actions are available: another action in the same encounter has an
  equal-or-better delta for all three resources and a better delta for at least
  one. The gated action can still be unavailable on a particular path, and this
  structural result does not measure whether prose, identity, or role-play makes
  the alternative meaningful to a player.

## Decision

The former route selector used xorshift's lowest bit and produced only 8 of 32
encounter combinations. Selecting from bit 8 exposes all combinations across
the same seed window without changing ending balance. Existing saves retain
their stored route, and replay now explicitly reuses that route, so an algorithm
upgrade cannot alter a saved journey.

“New route” also advances past any seed whose generated encounter IDs collide
with the current route. An exhaustive unit window proves seeds 1–1,024 always
produce a genuinely different next route rather than merely a different number.

No ending thresholds are changed from this audit alone. All endings are
reachable and the rarer wanderer path has real automated coverage; emotional
frequency remains a playtest question. The unique-route content audit now also
proves that early loss occurs only after choice three or four; the recovery
decision remains evidence-gated in
[`LOSS_RECOVERY_RESEARCH.md`](LOSS_RECOVERY_RESEARCH.md).

The audit now locks the exact dominated-choice ID set as review evidence, not as
a desired balance target. Any content change that removes, adds, or moves a
dominance relation fails `npm run content:audit` until the author reviews the
ending/text envelopes and updates this decision record. The five-session
scorecard determines whether the observed optimization actually harms the
experience and whether the three-way vow, effect rebalance, or prose-only
revision is the smallest appropriate response.
