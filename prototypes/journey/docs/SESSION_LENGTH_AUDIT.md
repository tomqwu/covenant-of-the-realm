# Session-length claim audit

## Why this audit exists

The original requirements, intro, and README described a journey as roughly
15–20 minutes. No timed player sessions exist yet, so that wording presented a
design target as an observed fact.

## Reproducible content envelope

Run:

```sh
npm run content:audit
```

The audit bundles and executes the production game engine, discovers all 32
authored route combinations across the audited seed window, and exhaustively
traverses every choice path that satisfies the engine's resource requirements.
For each of the 416 valid
terminal paths, it counts text the player newly encounters: each reached
region/place title, encounter body, the one actually applicable callback, both
visible choice labels and details, the selected aftermath, and the reached
ending. It therefore distinguishes 288 five-region completions from 128 paths
that reach the authored loss ending early. It does not count repeated journal
text, persistent navigation/UI labels, or time spent deliberating.

Current range:

| Journey class | Language measure | Minimum | Maximum |
| --- | --- | ---: | ---: |
| Five-region completion | English words | 471 | 502 |
| Five-region completion | Chinese Han characters | 643 | 683 |
| Early loss | English words | 283 | 396 |
| Early loss | Chinese Han characters | 367 | 535 |

The same audit locks the unique-route ending distribution at 160 covenant, 96
homeward, 32 wanderer, and 128 lost paths. Loss cannot occur in the first two
regions: 96 loss paths end after encounter three and 32 after encounter four.
These are structural path counts, not observed player-choice rates. The design
decision and external observation gate are in
[`LOSS_RECOVERY_RESEARCH.md`](LOSS_RECOVERY_RESEARCH.md).

The same executable traversal collects every authored encounter and locks the
eight choice IDs whose three resource deltas are Pareto-dominated by the other
action in their encounter. This is a content-review signal rather than a
session-length input or a claim about player preference; its interpretation is
recorded in [`BALANCE_AUDIT.md`](BALANCE_AUDIT.md) and
[`DECISION_PATTERN_RESEARCH.md`](DECISION_PATTERN_RESEARCH.md).

These exact reachable-path envelopes are useful for detecting content drift but
cannot determine play time: decision hesitation, rereading, input method,
language fluency, and accessibility needs can dominate a short interactive work.

## Decision

Player-facing copy now calls this a short journey and makes no duration claim.
The 15–20 minute value remains a design target in the requirements, explicitly
pending evidence.

The five-session [`PLAYTEST_SCORECARD.md`](PLAYTEST_SCORECARD.md) already records
start/end time, completion, input, language, and comprehension. After all five
sessions, report the individual durations and median without discarding slower
accessibility-related runs. Publish an “about N minutes” claim only if the
observed spread makes that useful rather than misleading.

Do not pad the game solely to hit a clock. If the observed median is shorter but
players find the decisions and ending complete, revise the target. Add content
only when the decision-pattern gate identifies a missing consequence or choice,
then remeasure the envelope and rerun timed sessions.
