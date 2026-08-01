import { ENCOUNTERS, STAT_KEYS } from "./content";
import { applyEffect, determineEnding, meetsRequirement } from "./engine";
import type { Choice, GameState, JournalEntry, Locale, Stats } from "./types";

export const SAVE_KEY = "shan-he-you-qi:journey:v1";

export interface StorageLike {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
  removeItem(key: string): void;
}

export interface ResilientStorage extends StorageLike {
  isPersistent(): boolean;
}

export const createResilientStorage = (primary: StorageLike | null): ResilientStorage => {
  const memory = new Map<string, string>();
  let persistent = primary !== null;

  return {
    getItem: (key) => {
      if (persistent) {
        try {
          const value = primary!.getItem(key);
          if (value === null) memory.delete(key);
          else memory.set(key, value);
          return value;
        } catch {
          persistent = false;
        }
      }
      return memory.get(key) ?? null;
    },
    setItem: (key, value) => {
      memory.set(key, value);
      if (persistent) {
        try {
          primary!.setItem(key, value);
        } catch {
          persistent = false;
        }
      }
    },
    removeItem: (key) => {
      memory.delete(key);
      if (persistent) {
        try {
          primary!.removeItem(key);
        } catch {
          persistent = false;
        }
      }
    },
    isPersistent: () => persistent,
  };
};

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null;

const isLocale = (value: unknown): value is Locale => value === "zh" || value === "en";

const isBoundedInteger = (value: unknown): value is number =>
  typeof value === "number" && Number.isInteger(value) && value >= 0 && value <= 9;

const isStats = (value: unknown): value is Stats =>
  isRecord(value) &&
  isBoundedInteger(value.provisions) &&
  isBoundedInteger(value.trust) &&
  isBoundedInteger(value.insight);

const isLocalizedText = (value: unknown): boolean =>
  isRecord(value) && typeof value.zh === "string" && typeof value.en === "string";

const isEffect = (value: unknown): boolean =>
  isRecord(value) &&
  [value.provisions, value.trust, value.insight].every(
    (amount) =>
      amount === undefined ||
      (typeof amount === "number" && Number.isInteger(amount) && amount >= -9 && amount <= 9),
  );

const isJournalEntry = (value: unknown): boolean =>
  isRecord(value) &&
  typeof value.encounterId === "string" &&
  (value.choiceId === undefined || typeof value.choiceId === "string") &&
  isLocalizedText(value.place) &&
  isLocalizedText(value.choice) &&
  isLocalizedText(value.aftermath) &&
  isEffect(value.effect);

const encounterIds = new Set(ENCOUNTERS.map((encounter) => encounter.id));
const encountersById = new Map(ENCOUNTERS.map((encounter) => [encounter.id, encounter]));
const endingIds = new Set(["covenant", "homeward", "wanderer", "lost"]);

const matchesLegacyChoiceEffect = (
  effect: Partial<Stats>,
  authoredEffect: Partial<Stats>,
): boolean => STAT_KEYS.every((stat) => {
  const actual = effect[stat];
  const expected = authoredEffect[stat];
  if (stat === "provisions" && actual === undefined) return true;
  return (actual ?? 0) === (expected ?? 0);
});

const authoredChoiceForEntry = (entry: JournalEntry): Choice | null => {
  const encounter = encountersById.get(entry.encounterId)!;
  const matches = entry.choiceId === undefined
    ? encounter.choices.filter((choice) => matchesLegacyChoiceEffect(entry.effect, choice.effect))
    : encounter.choices.filter((choice) => choice.id === entry.choiceId);
  return matches.length === 1 ? matches[0]! : null;
};

const hasCoherentRouteAndJournal = (state: GameState): boolean => {
  if (!state.route.every(
    (encounterId, region) => encountersById.get(encounterId)!.region === region,
  )) return false;
  let stats: Stats = { provisions: 8, trust: 0, insight: 0 };
  for (const [index, entry] of state.journal.entries()) {
    if (entry.encounterId !== state.route[index]) return false;
    const choice = authoredChoiceForEntry(entry);
    if (!choice) return false;
    if (!meetsRequirement(stats, choice.requirement)) return false;
    if (
      entry.choiceId !== undefined &&
      !STAT_KEYS.every((stat) => (entry.effect[stat] ?? 0) === (choice.effect[stat] ?? 0))
    ) return false;
    stats = applyEffect(stats, entry.effect);
  }
  return STAT_KEYS.every((stat) => state.stats[stat] === stats[stat]);
};

const hasCoherentPhase = (state: GameState): boolean => {
  if (state.phase === "intro") return state.sceneIndex === 0;
  if (state.phase === "playing") {
    return state.sceneIndex < state.route.length && state.stats.provisions > 0;
  }
  if (state.phase === "reflection") {
    return state.sceneIndex > 0 &&
      state.sceneIndex < state.route.length &&
      state.stats.provisions > 0;
  }
  if (state.ending === "lost") {
    return state.sceneIndex > 0 &&
      state.sceneIndex < state.route.length &&
      state.stats.provisions === 0;
  }
  return state.sceneIndex === state.route.length && state.ending === determineEnding(state.stats);
};

export const isGameState = (value: unknown): value is GameState => {
  if (!isRecord(value)) return false;
  const structurallyValid =
    value.version === 1 &&
    typeof value.seed === "number" &&
    Number.isInteger(value.seed) &&
    value.seed > 0 &&
    value.seed <= 0xffff_ffff &&
    isLocale(value.locale) &&
    (value.phase === "intro" ||
      value.phase === "playing" ||
      value.phase === "reflection" ||
      value.phase === "ended") &&
    Array.isArray(value.route) &&
    value.route.length === 5 &&
    value.route.every((item) => typeof item === "string" && encounterIds.has(item)) &&
    Number.isInteger(value.sceneIndex) &&
    (value.sceneIndex as number) >= 0 &&
    (value.sceneIndex as number) <= value.route.length &&
    isStats(value.stats) &&
    Array.isArray(value.journal) &&
    value.journal.every(isJournalEntry) &&
    value.journal.length === value.sceneIndex &&
    (value.ending === undefined || endingIds.has(value.ending as string)) &&
    (value.phase === "ended" ? typeof value.ending === "string" : value.ending === undefined);
  if (!structurallyValid) return false;
  const state = value as unknown as GameState;
  return hasCoherentRouteAndJournal(state) && hasCoherentPhase(state);
};

export const saveGame = (storage: StorageLike, state: GameState): void => {
  storage.setItem(SAVE_KEY, JSON.stringify(state));
};

const normalizeGameState = (state: GameState): GameState => {
  let changed = false;
  const journal = state.journal.map((entry) => {
    if (entry.choiceId !== undefined) return entry;
    const choice = authoredChoiceForEntry(entry)!;
    changed = true;
    return { ...entry, choiceId: choice.id };
  });
  return changed ? { ...state, journal } : state;
};

export const loadGame = (storage: StorageLike): GameState | null => {
  const serialized = storage.getItem(SAVE_KEY);
  if (!serialized) return null;
  try {
    const value: unknown = JSON.parse(serialized);
    if (isGameState(value)) {
      const normalized = normalizeGameState(value);
      if (normalized !== value) saveGame(storage, normalized);
      return normalized;
    }
  } catch {
    // Invalid local data is treated like no save.
  }
  storage.removeItem(SAVE_KEY);
  return null;
};
