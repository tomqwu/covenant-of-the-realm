# Choice commitment and confirmation

## Question

Should every narrative choice require a second confirmation before its resource
effect and aftermath are committed?

The current interaction commits one enabled native-button activation, saves the
new state, and moves focus to a separate authored aftermath. The aftermath names
the selected action, shows its exact resource delta, and requires an explicit
**Continue** action before the next encounter.

## Primary-source comparison

- ink's official [choice documentation](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md#2-choices)
  treats selecting an option as immediate story flow into its output. It also
  supports separating the visible option wording from the resulting prose. That
  is the same structural boundary as this game's choice followed by aftermath;
  it does not introduce a generic confirmation step between them.
- Choice of Games' [rules for interesting choices](https://www.choiceofgames.com/2010/03/5-rules-for-writing-interesting-choices-in-multiple-choice-games/)
  argue that players need enough information to compare genuinely appealing
  tradeoffs, and explicitly reject hiding consequences as a way to repair an
  imbalanced option. This game exposes the action detail, exact resource delta,
  and any gate before activation.
- Choice of Games' [end-game design guidance](https://www.choiceofgames.com/2016/11/end-game-and-victory-design/)
  says choices must remain meaningful at the ending. The four ending rules and
  causal journal already preserve that consequence chain.
- W3C's [Error Prevention (Legal, Financial, Data)](https://www.w3.org/WAI/WCAG22/Understanding/error-prevention-legal-financial-data.html)
  covers legal commitments, financial transactions, changes to stored
  user-controlled data, and test submissions. Its
  [confirmation technique](https://www.w3.org/WAI/WCAG22/Techniques/general/G168)
  is designed for an irreversible action such as cancelling a reservation.
  Ordinary narrative choice is not one of those transactions. The game's
  actual destructive stored-data action—clear local data—already requires two
  consecutive activations, while restore is separately staged and confirmed.

## Decision

Do not add a confirmation dialog or second click before every story choice.
That would duplicate already-visible information, add ten avoidable controls to
a complete journey, and place modal error-prevention friction on the game's
primary verb.

The existing aftermath remains a deliberate **reflection boundary**, not a
confirmation screen: the decision is already saved and its authored consequence
is allowed to land before the player continues.

## Evidence and prototype rule

Record accidental activations and independent undo requests in the five-session
scorecard. If at least two of five observed players activate the wrong choice or
ask to undo before continuing, test the bounded one-step **Reconsider this
choice** aftermath prototype from
[`COMPARABLE_PATTERN_ROADMAP.md`](COMPARABLE_PATTERN_ROADMAP.md). Do not test a
pre-choice confirmation first.

Kill the reconsideration prototype if players mainly use it to optimize known
resource deltas or if it weakens the perceived weight of decisions. Reconsider
a pre-choice confirmation only if the same observed mis-activation problem
persists after the bounded prototype and cannot be fixed through target,
wording, or focus behavior. Any such confirmation must name the exact choice,
offer native confirm/cancel actions, contain keyboard focus, and add an
assistive-technology release task plus a complete browser journey.

Until those conditions exist, direct choice → aftermath is the control.
