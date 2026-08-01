# Early-loss and recovery research

Date: 2026-07-31

## Question

The authored **Lost · A Reed Fire Remains** ending can stop a route before Sky
Gate when provisions reach zero. Is that a meaningful consequence with a clear
replay path, or does it need checkpoint retry, extra warning, or a softer
fail-forward rule?

## Reproducible local evidence

`npm run content:audit` executes the production engine across all 32 route
combinations and every requirement-valid choice path. Its 416 unique-route
terminal paths contain:

| Ending | Paths | Share |
| --- | ---: | ---: |
| Covenant | 160 | 38.5% |
| Homeward | 96 | 23.1% |
| Wanderer | 32 | 7.7% |
| Lost | 128 | 30.8% |

No loss is possible after only one or two encounters. Of the 128 loss paths,
96 stop after the third choice and 32 stop after the fourth. Every reachable
state still has an enabled choice, so these are consequences of selected,
visible costs rather than a locked or stranded flow.

The current loss experience is already complete rather than a generic error:

- the player sees the chosen option's authored aftermath before the ending;
- the ending explains that provisions ran out and explicitly invites another
  attempt using the same seed;
- the full reached journal and exact resource deltas remain visible;
- the loss is recorded as one of four discoveries without revealing encounters
  the player did not reach; and
- **Replay this route** and **New route** remain available.

The percentage above is structural path availability, not an expected player
loss rate. Choice preference is not uniform, and no observed sessions exist
yet.

## Comparable narrative guidance

Choice of Games recommends that even a wrong option remain interesting and that
a character death be a memorable scene rather than a dull punishment. Its
broader choice guidance also requires real consequences and enough information
to choose, rather than hiding the basis of a mistake. Sources:
[5 Rules for Writing Interesting Choices](https://www.choiceofgames.com/2010/03/5-rules-for-writing-interesting-choices-in-multiple-choice-games/),
[4 Common Mistakes in Interactive Novels](https://www.choiceofgames.com/2011/12/4-common-mistakes-in-interactive-novels/).

Failbetter's quality-based narrative guidance treats resource loss or a new
problem as useful when it marks failure, creates risk, and produces a memorable
story; it also cautions that very small worlds may not need another reward or
punishment system. Source:
[Difficulty, Rewards and Punishment](https://www.failbettergames.com/news/narrative-snippets-difficulty-rewards-and-punishment).

Ink distinguishes an intentional ending from an accidental loose end and uses
fallback flow to ensure a story cannot run out of valid options. That supports
the repository's present structural invariant: every path either continues or
reaches an authored ending, and no resource state leaves an empty decision.
Source:
[Writing with ink](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md).

## Decision

Keep the current loss ending and existing whole-route replay as the control.
Do not add a checkpoint retry, rewind, extra life, emergency resource grant, or
stronger warning from path counts alone. Each would reduce commitment or teach
optimization before any player has shown that the current consequence is
unclear or uninteresting.

The loss ending already satisfies the comparable-pattern minimum: it is
authored, causally named, recorded, and recoverable through immediate replay.
The unresolved question is emotional, not mechanical.

## Observation gate

During ordinary five-session playtesting, record a loss only when it occurs
naturally; do not coach a participant into a costly path. For every observed
loss, capture:

1. whether the player can explain why the journey stopped;
2. whether they inspect the journal or resource total;
3. whether they replay the same route, start a new route, or leave; and
4. their first unprompted description of the ending.

Run a separate loss-focused round only if fewer than three natural losses are
observed and recovery remains a priority. Start participants from the same
valid pre-loss saved state, disclose after the task that the setup was fixed,
and do not imply that replay is expected.

Prototype a recovery change only when at least **2 of 5 players who actually
reach loss** cannot explain the visible cause, describe the ending as an error
or wasted run, or try to continue but cannot find either replay action.

Match the intervention to the evidence:

- cause misunderstood: revise the loss heading/body to name the final cost;
- replay action missed: test one loss-specific label for the existing same-route
  replay action;
- mistaken activation: use the separate one-step reconsideration gate; and
- deliberate choice felt unfair despite understood cost: test a bounded
  pre-choice affordability phrase, without changing the stat rule.

A checkpoint is last priority. If tested, it may exist only on the loss screen,
must restore the exact state before the terminal choice, must not rewrite the
chronicle until a new ending is reached, and must preserve full-route replay.

## Kill criteria

Keep the current design when players understand the cause and either value the
loss as an ending or can find replay. Kill any recovery prototype that causes
players to probe outcomes without commitment, obscures the four-ending
chronicle, makes the visible deltas redundant, or turns loss into a temporary
dialog rather than a remembered journey.
