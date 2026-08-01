# Decision-pattern research and playtest gate

Date: 2026-07-31

## Question

Does the five-region journey become mechanically repetitive because each scene
offers the same broad trade—help others at a visible cost or preserve the self—
and, if players feel that repetition, what is the smallest different decision
pattern that strengthens the game's reflective promise?

## Local content audit

The current authored set contains ten encounters and twenty choices:

- all 10 encounters present exactly two options;
- all 10 first options are collaborative and raise trust, insight, or both;
- all 10 second options are solitary/pragmatic and never raise trust;
- 4 of 20 options are state-gated, but every gate still sits on that same axis;
- 8 of 20 choice IDs are mechanically Pareto-dominated on the three visible
  resource deltas when both encounter actions are available; and
- later prose now remembers the prior choice, so consequence clarity is no
  longer the main unknown.

The exhaustive audit in [`BALANCE_AUDIT.md`](BALANCE_AUDIT.md) locks the exact
dominated-choice set so content drift cannot hide this signal. It is objective
optimization evidence, but not proof that players experience the narrative
choices as repetitive or uninteresting. The roadmap therefore keeps the
response behind an external playtest; the scorecard records whether players
actually switch to arithmetic by region three.
The fixed playtest route's Old City scene is a non-dominated within-session
control. [`TRADEOFF_RESEARCH.md`](TRADEOFF_RESEARCH.md) defines how that contrast
selects an effect-rebalance prototype or the vow, avoiding two simultaneous
interventions.

## Evidence from established narrative systems

### Expressive choices before more systems

Choice of Games warns that repeatedly asking which skill or approach works best
becomes boring, and recommends asking what the player *wants* to do at least as
often as asking what will work. Its companion guidance recommends personality
decisions with no obvious correct answer, provided they affect later story.
This supports testing one expressive decision rather than adding a fourth
resource. Sources: [5 Rules for Writing Interesting Choices](https://www.choiceofgames.com/2010/03/5-rules-for-writing-interesting-choices-in-multiple-choice-games/),
[7 Rules for Designing Great Stats](https://www.choiceofgames.com/2011/07/7-rules-for-designing-great-stats/).

### Rejoin paths, remember labels

ink's documented “weave” structure lets nested options gather back into one
forward flow, while labelled choices can still change later text. That matches
this game's small, finishable river-shaped architecture and argues against a
large permanent branch. Source: [Writing with ink](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md).

### Consequence is valuable but expensive

Failbetter distinguishes the felt moment of choice, the complicity of acting,
and the later consequence. It cautions that consequence cost grows rapidly and
that many endings cannot rescue weak choices. The current aftermath and callback
systems already fund consequence; the experiment should change the *kind* of
choice. Source: [Choice, Complicity and Consequence](https://www.failbettergames.com/news/choice-complicity-and-consequence).

### Accumulation patterns are a later alternative

Failbetter's “Midnight Buffet” lets players build several progress qualities and
decide how many preparations to make before cashing them in. It is a credible
investigation pattern, but it adds micro-state, actions, and balancing work that
do not fit a first experiment in a short five-region game. Source:
[New Narrative Structures](https://www.failbettergames.com/news/new-narrative-structures).

### Intent before option count

Choice of Games' intentional-choice guidance says players need to understand
why they are choosing and have clues about likely story and stat effects. Its
end-game guidance recommends several independent, sometimes competing goals so
earlier choices can produce meaningfully different conclusions. The current
game already exposes exact stat deltas, pauses on authored aftermath, tracks
three competing resources, and resolves four distinct endings. This evidence
supports measuring felt repetition before adding an option; three buttons do not
repair two unclear intentions. Sources: [How to Write Intentional Choices](https://www.choiceofgames.com/2016/12/how-to-write-intentional-choices/),
[End Game and Victory Design](https://www.choiceofgames.com/2016/11/end-game-and-victory-design/).

### Delayed branching before content trees

Choice of Games recommends delayed branching so early decisions can alter later
chapters without exponential content growth. That matches the shipped callback
system and strengthens the case for a small vow echoed at Sky Gate/endings, not
a sixth route region or permanent branch. Source: [By the Numbers](https://www.choiceofgames.com/2011/07/by-the-numbers-how-to-write-a-long-interactive-novel-that-doesnt-suck/).

### Keep the river small and test it

Failbetter recommends few reusable qualities, a river rather than a content
tree, and playtesting structural skeletons before prose. It explicitly calls for
at least two sets of eyes. Sources: [Narrative Snippets: Parsimony](https://www.failbettergames.com/news/narrative-snippets-parsimony-2),
[Narrative Snippets: Organising Creative Efforts](https://www.failbettergames.com/news/narrative-snippets-organising-creative-efforts-2).

## Recommended hypothesis: the three-way vow

If players report that the middle of the journey repeats one optimization, add
one three-way expressive vow after Old City and before Sky Gate:

1. “The covenant belongs to every hand that carried it.”
2. “The covenant is a promise I chose to finish.”
3. “The covenant is a question the road should leave open.”

The vow has no immediate stat effect and no locked answer. It records a stable
ID, appears in the final journal/summary, and changes two or three sentences at
Sky Gate and in every ending. The route, resources, and ending thresholds stay
unchanged. This tests self-expression without adding a quality or content tree.

## Playtest protocol

Use the fillable [`PLAYTEST_SCORECARD.md`](PLAYTEST_SCORECARD.md) to keep the
five sessions, verbatim observations, threshold calculation, and privacy rules
consistent.

Recruit five players unfamiliar with the project. Use the same seed for the
first run and do not explain the resource model beyond the rendered interface.

Observe:

- hesitation and rereading at each decision;
- whether the player predicts prose, stats, or both as the consequence;
- whether choices after region two are made by role-play or by arithmetic;
- total completion time and any confusion about the ending.

Ask only after the ending:

1. “Which decisions felt meaningfully different from one another?”
2. “Did any decisions feel like the same choice in new wording?”
3. “When did you choose who this traveler was, rather than the best outcome?”
4. “What did you expect the game to remember?”

Repetition is confirmed when at least 3 of 5 players independently describe
three or more scenes as the same trade, or say they switched to stat arithmetic
by the third region. Do not build the vow if fewer than three do.

Also classify each observed hesitation as **unclear intent**, **uninteresting
trade**, or **repeated trade**. Revise labels/details for unclear intent; do not
mistake it for evidence that another option is needed.

## Prototype success and kill criteria

Skeleton the vow with placeholder prose and test it with five more runs before
authoring final bilingual copy.

Success requires:

- at least 4 of 5 players describe the three vows as meaningfully distinct;
- no more than 1 of 5 asks which vow grants the best stats;
- at least 4 of 5 notice a later textual response to their vow;
- median completion time rises by no more than two minutes;
- ending comprehension does not fall below the current baseline.

Kill or revise the pattern if players read the vow as a disguised ending menu,
cannot distinguish two answers, or feel that a no-stat choice is inconsequential.
Only if the expressive-vow test fails because players want more investigation
should the larger bounded-gather pattern be prototyped.

## Engineering acceptance criteria if the gate passes

- Backward-compatible persistence for a stable vow ID.
- Three keyboard/touch-operable choices with no fake locked state.
- Authored bilingual immediate response and ending callback for every vow.
- Journal and share summary include the vow without treating it as a region.
- Same-seed replay permits a different vow without changing the route.
- Unit coverage remains 99%+ and one named E2E journey proves two vows yield
  different later prose while identical pre-vow choices preserve stats.
