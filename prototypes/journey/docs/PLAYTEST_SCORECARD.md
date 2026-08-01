# Five-session playtest scorecard

Use this sheet with the protocol and thresholds in
[`DECISION_PATTERN_RESEARCH.md`](DECISION_PATTERN_RESEARCH.md). It is deliberately
observation-first: record what the participant does or says before interpreting
it. GOV.UK's moderated-testing guidance recommends neutral tasks, thinking
aloud, mostly watching and listening, and a consistent discussion guide; its
analysis guidance recommends one observed fact or verbatim quote per note.

Sources: [Using moderated usability testing](https://www.gov.uk/service-manual/user-research/using-moderated-usability-testing),
[Analyse a research session](https://www.gov.uk/service-manual/user-research/analyse-a-research-session).

## Round setup

- Research question: do at least three players experience regions 3–5 as a
  repeated optimization rather than distinct role-play decisions?
- Participants: five people unfamiliar with this project who plausibly enjoy
  short reflective or narrative games.
- Route: open the hosted game with this query string for every participant:
  `?seed=4242&replay=1&route=ferry-rope,ridge-bell,marsh-marker,city-well,gate-storm`.
- Reset: use **Clear local data** twice between participants, or use a fresh
  browser profile. Confirm the intro, `0/5` journal, and `0/4` chronicle.
- Task prompt: “Complete this journey in whatever way feels right to you. Please
  say what you are considering as you choose.” Do not explain stats or endings.
- Privacy: use participant codes P01–P05 only. Do not record names, contact
  details, health data, or audio/video unless separately consented and needed.

## Per-participant observation

Copy this section once for each participant.

### Participant P__

- Device/input:
- Interface language:
- Start/end time:
- Completed without facilitator help: yes / no
- Ending understood in their own words: yes / partly / no

| Region | First observable action | Verbatim reason or thought | Reread/hesitation | Basis stated by player |
| --- | --- | --- | --- | --- |
| 芦渡 / Reed Ferry |  |  | none / once / repeated | role / arithmetic / prose / unclear |
| 松岭 / Pine Ridge |  |  | none / once / repeated | role / arithmetic / prose / unclear |
| 雨泽 / Rain Marsh |  |  | none / once / repeated | role / arithmetic / prose / unclear |
| 故城 / Old City |  |  | none / once / repeated | role / arithmetic / prose / unclear |
| 天门关 / Sky Gate |  |  | none / once / repeated | role / arithmetic / prose / unclear |

Post-ending questions, asked in this order:

1. Which decisions felt meaningfully different from one another?
2. Did any decisions feel like the same choice in new wording?
3. When did you choose who this traveler was, rather than the best outcome?
4. What did you expect the game to remember?
5. What did the three resource figures change during the journey?
6. Is there anything left here that would make you take another journey?
7. If you wanted to return to this journey later, what would you do?

Do not point out the chronicle or its encounter count before question 6. Record
whether the player notices or opens it without prompting.

One-observation notes:

- OBS-P__-01:
- OBS-P__-02:
- OBS-P__-03:

Session classification, completed only after notes are written:

- Primary observed issue: repeated trade / unclear intent / uninteresting trade / none
- Described at least three scenes as the same trade: yes / no
- Shifted primarily to stat arithmetic by region 3: yes / no
- Named one action as strictly/broadly better in at least three dominated scenes: yes / no
- Deliberated differently at Old City's provisions-vs-trust control: yes / no / unclear
- Activated a choice by mistake or independently requested undo: yes / no
- Explained all three resources and the locked-choice requirement: yes / partly / no
- Noticed the encounter-discovery count without prompting: yes / no
- Expressed intent to replay because authored encounters remain: yes / no
- Independently began another route; discovery count before/after and repeated-title reaction:
- Requested preserving more than one unfinished journey: yes / no
- Tried to install/add the game, could not find the browser path, and requested an in-game route: yes / no
- Installed the game during or before this session: yes / no / not observed
- Unprompted launcher task attempted or requested (record exact words):
- Tried to open a game backup from the file manager: yes / no
- Encountered or named confusing duplicate installed-app windows: yes / no
- Tried to send a journey artifact into the app from an OS share sheet: yes / no
- Reached the lost ending naturally: yes / no
- If lost, explained the cause and next action without prompting:
- If lost, first recovery action: replay route / new route / inspect journal / leave / other
- Counts toward delta-driven flattening: yes / no
- Counts toward axis repetition including Old City: yes / no
- Reason tied to observation IDs:

Classification rule: **unclear intent** means the player cannot predict what an
option is trying to do; **uninteresting trade** means the intent is understood
but neither option feels worth considering; **repeated trade** means the player
understands the options but experiences three or more regions as the same
underlying decision. Use Old City's non-dominated control to split repeated
trade into delta-driven flattening or axis repetition; only the latter can
satisfy the vow gate.

## Round decision

| Participant | Primary issue | Delta flattening | Axis repetition | Completion | Ending comprehension | Key observation IDs |
| --- | --- | --- | --- | --- | --- | --- |
| P01 |  | yes / no | yes / no | yes / no | yes / partly / no |  |
| P02 |  | yes / no | yes / no | yes / no | yes / partly / no |  |
| P03 |  | yes / no | yes / no | yes / no | yes / partly / no |  |
| P04 |  | yes / no | yes / no | yes / no | yes / partly / no |  |
| P05 |  | yes / no | yes / no | yes / no | yes / partly / no |  |

- Repetition count: __ / 5
- Delta-driven-flattening count: __ / 5 (effect-rebalance gate: **3/5**).
- Axis-repetition count including Old City: __ / 5 (vow gate: **3/5**).
- Gate result: build vow prototype only at **3/5 or more**; otherwise retain the
  current decisions and record the strongest different issue. Apply the
  response-selection order in
  [`TRADEOFF_RESEARCH.md`](TRADEOFF_RESEARCH.md); do not build the vow first when
  the same evidence specifically passes the effect-rebalance gate.
- Comprehension baseline for the follow-up prototype: __ / 5 fully understood.
- Mistaken-choice/undo-request count: __ / 5 (reconsideration gate: **2/5**).
- Resource/gate misunderstanding count: __ / 5 (qualitative-label gate: **3/5**).
- Encounter-ledger replay motivation: __ / 5; note unprompted discovery separately.
- Repetition-blocked spontaneous replays: __ / 5 (unseen-biased route prototype
  gate: **2/5**, under `ENCOUNTER_DISCOVERY_RESEARCH.md`).
- Multiple-unfinished-save requests: __ / 5 (save-slot request gate: **2/5**, plus
  the measured-duration condition in `COMPARABLE_PATTERN_ROADMAP.md`).
- Failed install-discovery attempts: __ / 5 (custom-install prototype gate:
  **2/5**, with the platform contract in `INSTALL_DISCOVERY_RESEARCH.md`).
- Distinct installed-app shortcut requests: __ / 5; exact tasks:
- File-manager backup-open attempts/requests: __ / 5.
- Confusing duplicate-window sessions: __ / 5.
- Inbound OS-share attempts: __ / 5.
- Natural lost endings observed: __ / 5; cause/recovery failures among those: __ / __.
- Loss-recovery gate: prototype only at **2/5 actual loss sessions**, using the
  intervention matching rules in `LOSS_RECOVERY_RESEARCH.md`.
- Platform candidate decision: none / shortcut / file handler / launch handler / share target.
  Apply the separate **2/5** gates and state-ownership contracts in
  `PLATFORM_INTEGRATION_ROADMAP.md`; an installed participant alone is not
  evidence for any candidate.
- Median completion time: __ minutes.
- Decision owner/date:
- Linked issue or next increment:

Do not average away contradictory observations. Preserve the participant-level
notes so the proposed vow can be checked against the exact behavior that
triggered it.

## Optional delayed-return probe

Use the separate protocol in
[`RESUME_CONTEXT_RESEARCH.md`](RESUME_CONTEXT_RESEARCH.md); do not improvise it
inside the uninterrupted main journey.

| Participant | Delay | Oriented to last choice and current goal within 10s | Opened journal | Independently requested recap | Observation IDs |
| --- | --- | --- | --- | --- | --- |
| P01 |  | yes / no | yes / no | yes / no |  |
| P02 |  | yes / no | yes / no | yes / no |  |
| P03 |  | yes / no | yes / no | yes / no |  |
| P04 |  | yes / no | yes / no | yes / no |  |
| P05 |  | yes / no | yes / no | yes / no |  |

- Delayed-resume failures/requests: __ / 5.
- Gate result: prototype one-line recap only at **2/5 or more**.
- Second-round kill result if prototyped:
