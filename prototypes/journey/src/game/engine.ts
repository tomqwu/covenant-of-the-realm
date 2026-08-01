import { ENDINGS, ENCOUNTERS, encounterById } from "./content";
import type {
  Choice,
  Encounter,
  EndingId,
  GameState,
  Locale,
  Requirement,
  Stats,
  LocalizedText,
} from "./types";

export const INITIAL_STATS: Stats = { provisions: 8, trust: 0, insight: 0 };

export const normalizeSeed = (seed: number): number => {
  if (!Number.isFinite(seed)) return 1;
  const normalized = Math.abs(Math.trunc(seed)) >>> 0;
  return normalized || 1;
};

const nextSeed = (seed: number): number => {
  let value = normalizeSeed(seed);
  value ^= value << 13;
  value ^= value >>> 17;
  value ^= value << 5;
  return value >>> 0;
};

export const createRoute = (seed: number): readonly string[] => {
  let cursor = normalizeSeed(seed);
  return Array.from({ length: 5 }, (_, region) => {
    cursor = nextSeed(cursor);
    const candidates = ENCOUNTERS.filter((encounter) => encounter.region === region);
    return candidates[(cursor >>> 8) % candidates.length]!.id;
  });
};

export const createGame = (seed: number, locale: Locale = "zh"): GameState => ({
  version: 1,
  seed: normalizeSeed(seed),
  locale,
  phase: "intro",
  route: createRoute(seed),
  sceneIndex: 0,
  stats: INITIAL_STATS,
  journal: [],
});

export const beginGame = (state: GameState): GameState =>
  state.phase === "intro" ? { ...state, phase: "playing" } : state;

export const currentEncounter = (state: GameState): Encounter | null => {
  if (state.phase !== "playing") return null;
  const id = state.route[state.sceneIndex];
  return id ? encounterById(id) : null;
};

export const currentCallback = (state: GameState): LocalizedText | null => {
  const encounter = currentEncounter(state);
  if (!encounter) return null;
  const callback = encounter.callbacks?.find(({ afterChoices }) =>
    state.journal.some((entry) => entry.choiceId && afterChoices.includes(entry.choiceId)),
  );
  return callback?.text ?? null;
};

export const meetsRequirement = (stats: Stats, requirement?: Requirement): boolean =>
  requirement ? stats[requirement.stat] >= requirement.minimum : true;

const clampStat = (value: number): number => Math.max(0, Math.min(9, value));

export const applyEffect = (stats: Stats, effect: Partial<Stats>): Stats => ({
  provisions: clampStat(stats.provisions + (effect.provisions ?? 0)),
  trust: clampStat(stats.trust + (effect.trust ?? 0)),
  insight: clampStat(stats.insight + (effect.insight ?? 0)),
});

export const determineEnding = (stats: Stats): EndingId => {
  if (stats.trust >= 4 && stats.insight >= 4) return "covenant";
  if (stats.provisions >= 3) return "homeward";
  return "wanderer";
};

const finish = (state: GameState, ending: EndingId, stats: Stats): GameState => ({
  ...state,
  phase: "ended",
  stats,
  ending,
});

export const choose = (state: GameState, choiceId: string): GameState => {
  const encounter = currentEncounter(state);
  if (!encounter) throw new Error("A choice can only be made during an encounter.");

  const choice = encounter.choices.find((candidate) => candidate.id === choiceId);
  if (!choice) throw new Error(`Unknown choice: ${choiceId}`);
  if (!meetsRequirement(state.stats, choice.requirement)) {
    throw new Error(`Choice requirement not met: ${choiceId}`);
  }

  const stats = applyEffect(state.stats, choice.effect);
  const sceneIndex = state.sceneIndex + 1;
  const advanced: GameState = {
    ...state,
    phase: "reflection",
    stats,
    sceneIndex,
    journal: [
      ...state.journal,
      {
        encounterId: encounter.id,
        choiceId: choice.id,
        place: encounter.place,
        choice: choice.label,
        aftermath: choice.aftermath,
        effect: choice.effect,
      },
    ],
  };

  if (stats.provisions === 0 && sceneIndex < state.route.length) {
    return finish(advanced, "lost", stats);
  }
  if (sceneIndex >= state.route.length) {
    return finish(advanced, determineEnding(stats), stats);
  }
  return advanced;
};

export const continueJourney = (state: GameState): GameState =>
  state.phase === "reflection" ? { ...state, phase: "playing" } : state;

export const setLocale = (state: GameState, locale: Locale): GameState =>
  state.locale === locale ? state : { ...state, locale };

export const restartGame = (state: GameState): GameState =>
  beginGame({ ...createGame(state.seed, state.locale), route: state.route });

export const createNextJourney = (state: GameState): GameState => {
  const currentRoute = state.route.join("|");
  let seed = state.seed;
  do {
    seed = nextSeed(seed);
  } while (createRoute(seed).join("|") === currentRoute);
  return createGame(seed, state.locale);
};

export const endingContent = (state: GameState) =>
  state.ending ? ENDINGS[state.ending] : null;

export const visibleChoices = (state: GameState): readonly Choice[] =>
  currentEncounter(state)?.choices ?? [];
