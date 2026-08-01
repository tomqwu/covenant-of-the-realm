# Content authoring contract

Narrative content is data in `src/game/content.ts`; engine and UI modules must
not special-case encounter IDs. The automated contract in
`src/game/content.test.ts` protects the assumptions that keep route generation,
persistence, callbacks, and bilingual rendering deterministic.

## Current shape

- Five ordered regions, each with exactly two encounter variants.
- Every encounter has exactly two choices.
- Encounter and choice IDs are globally unique, stable after release, and use
  lowercase ASCII words separated only by hyphens. This keeps persistence,
  HTML data attributes, and comma-separated exact-route URLs unambiguous.
- Chinese and English text is required for place, title, body, label, detail,
  aftermath, callback, and ending fields.
- The exported `STAT_KEYS` sequence is the canonical Provisions/Trust/Insight
  order for the ledger, journal deltas, validation, and portable artifacts;
  never infer presentation order from imported JSON object keys.
- Every effect is an integer between -9 and 9 and changes at least one stat.
- Within each encounter, the choices' trust/insight effect signatures remain
  distinct. This lets a legacy version-1 journal that omitted both a stable
  choice ID and the provision cost infer exactly one authored choice and still
  enforce its requirement.
- Every encounter after the ferry has two callbacks whose target IDs cover all
  four choices in the immediately preceding region exactly once.

## Adding or changing content

1. Add the encounter and both complete choices to `ENCOUNTERS`.
2. Keep IDs short, semantic, hyphen-delimited, and permanent; saved journals and new chronicle
   identities refer to choice IDs. Legacy prose-based chronicle IDs remain
   recognized so copy edits cannot double-count a completed path.
3. Author the immediate aftermath before adjusting numeric effects.
4. Add both callback variants to each encounter in the following region.
5. State locked-choice requirements in both detail strings.
6. Run `make check`; never update a badge by hand unless the generated evidence
   already supports the new value.

Changing the number of regions, encounters per region, or choices per encounter
is a game-structure change, not a content-only edit. Update route generation,
rendering, persistence validation, the critical journey matrix, and this
contract together.
