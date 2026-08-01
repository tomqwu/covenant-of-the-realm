import type { EndingId, GameState, Stats } from "./types";
import type { StorageLike } from "./storage";
import { ENCOUNTERS } from "./content";
import { createRoute } from "./engine";

export const CHRONICLE_KEY = "shan-he-you-qi:chronicle:v1";
export const MAX_CHRONICLE_JOURNEYS = 128;

export interface JourneyRecord {
  readonly id: string;
  readonly seed: number;
  readonly ending: EndingId;
  readonly stats: Stats;
  readonly route?: readonly string[];
  readonly encountersSeen?: number;
}

export interface Chronicle {
  readonly version: 1;
  readonly journeys: readonly JourneyRecord[];
  readonly endings?: readonly EndingId[];
  readonly encounters?: readonly string[];
}

export const EMPTY_CHRONICLE: Chronicle = {
  version: 1,
  journeys: [],
  endings: [],
  encounters: [],
};

const ENDING_IDS: readonly EndingId[] = ["covenant", "homeward", "wanderer", "lost"];

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null;

const isStats = (value: unknown): value is Stats =>
  isRecord(value) &&
  [value.provisions, value.trust, value.insight].every(
    (stat) => typeof stat === "number" && Number.isInteger(stat) && stat >= 0 && stat <= 9,
  );

const encounterRegions = new Map(ENCOUNTERS.map((encounter) => [encounter.id, encounter.region]));
const encounterIds = new Set(encounterRegions.keys());

const isRoute = (value: unknown): value is readonly string[] =>
  Array.isArray(value) &&
  value.length === 5 &&
  value.every(
    (encounterId, region) =>
      typeof encounterId === "string" && encounterRegions.get(encounterId) === region,
  );

const isJourneyRecord = (value: unknown): value is JourneyRecord =>
  isRecord(value) &&
  typeof value.id === "string" &&
  value.id.length > 0 &&
  value.id.length <= 1_024 &&
  typeof value.seed === "number" &&
  Number.isInteger(value.seed) &&
  value.seed > 0 &&
  value.seed <= 0xffff_ffff &&
  ENDING_IDS.includes(value.ending as EndingId) &&
  isStats(value.stats) &&
  (value.route === undefined || isRoute(value.route)) &&
  (value.encountersSeen === undefined ||
    (typeof value.encountersSeen === "number" &&
      Number.isInteger(value.encountersSeen) &&
      value.encountersSeen >= 1 &&
      value.encountersSeen <= 5 &&
      (value.ending === "lost" || value.encountersSeen === 5)));

const hasChronicleShape = (value: unknown): value is Chronicle =>
  isRecord(value) &&
  value.version === 1 &&
  Array.isArray(value.journeys) &&
  value.journeys.every(isJourneyRecord) &&
  new Set(value.journeys.map((journey) => (journey as JourneyRecord).id)).size ===
    value.journeys.length &&
  (value.endings === undefined ||
    (Array.isArray(value.endings) &&
      value.endings.every((ending) => ENDING_IDS.includes(ending as EndingId)) &&
      new Set(value.endings).size === value.endings.length)) &&
  (value.encounters === undefined ||
    (Array.isArray(value.encounters) &&
      value.encounters.every((encounter) => encounterIds.has(encounter as string)) &&
      new Set(value.encounters).size === value.encounters.length));

export const isChronicle = (value: unknown): value is Chronicle =>
  hasChronicleShape(value) && value.journeys.length <= MAX_CHRONICLE_JOURNEYS;

const encountersSeenOnJourney = (journey: JourneyRecord): readonly string[] => {
  const route = journey.route ?? createRoute(journey.seed);
  if (journey.encountersSeen !== undefined) return route.slice(0, journey.encountersSeen);

  const prefix = `${journey.seed}:`;
  const serializedPath = journey.id.startsWith(prefix) ? journey.id.slice(prefix.length) : "";
  const entries = serializedPath ? serializedPath.split("|") : [];
  const inferredCount =
    entries.length >= 1 &&
    entries.length <= route.length &&
    entries.every((entry, index) => entry.startsWith(`${route[index]}/`))
      ? entries.length
      : null;
  return route.slice(0, inferredCount ?? (journey.ending === "lost" ? 0 : route.length));
};

export const discoveredEncounters = (chronicle: Chronicle): ReadonlySet<string> => {
  const discovered = new Set([
    ...(chronicle.encounters ?? []),
    ...chronicle.journeys.flatMap(encountersSeenOnJourney),
  ]);
  return new Set(
    ENCOUNTERS.map((encounter) => encounter.id).filter((encounterId) => discovered.has(encounterId)),
  );
};

export const normalizeChronicle = (value: unknown): Chronicle | null => {
  if (!hasChronicleShape(value)) return null;
  if (value.journeys.length <= MAX_CHRONICLE_JOURNEYS) return value;
  return {
    version: 1,
    journeys: value.journeys.slice(-MAX_CHRONICLE_JOURNEYS),
    endings: [...discoveredEndings(value)],
    encounters: [...discoveredEncounters(value)],
  };
};

const pathRecordId = (state: GameState, legacy: boolean): string =>
  `${state.seed}:${state.journal
    .map((entry) => `${entry.encounterId}/${legacy ? entry.choice.zh : (entry.choiceId ?? entry.choice.zh)}`)
    .join("|")}`;

export const journeyRecordId = (state: GameState): string => pathRecordId(state, false);

export const recordJourney = (chronicle: Chronicle, state: GameState): Chronicle => {
  if (state.phase !== "ended" || !state.ending) return chronicle;
  const id = journeyRecordId(state);
  const legacyId = pathRecordId(state, true);
  if (chronicle.journeys.some((journey) => journey.id === id || journey.id === legacyId)) {
    return chronicle;
  }
  const previouslyEncountered = discoveredEncounters(chronicle);
  const encounteredRoute = state.route.slice(0, state.journal.length);
  return {
    version: 1,
    endings: [...new Set([...discoveredEndings(chronicle), state.ending])],
    encounters: ENCOUNTERS.map((encounter) => encounter.id).filter(
      (encounterId) => previouslyEncountered.has(encounterId) || encounteredRoute.includes(encounterId),
    ),
    journeys: [
      ...chronicle.journeys.slice(-(MAX_CHRONICLE_JOURNEYS - 1)),
      {
        id,
        seed: state.seed,
        ending: state.ending,
        stats: state.stats,
        route: [...state.route],
        encountersSeen: state.journal.length,
      },
    ],
  };
};

export const discoveredEndings = (chronicle: Chronicle): ReadonlySet<EndingId> =>
  new Set([
    ...(chronicle.endings ?? []),
    ...chronicle.journeys.map((journey) => journey.ending),
  ]);

export const saveChronicle = (storage: StorageLike, chronicle: Chronicle): void => {
  storage.setItem(CHRONICLE_KEY, JSON.stringify(chronicle));
};

export const loadChronicle = (storage: StorageLike): Chronicle => {
  const serialized = storage.getItem(CHRONICLE_KEY);
  if (!serialized) return EMPTY_CHRONICLE;
  try {
    const value: unknown = JSON.parse(serialized);
    const normalized = normalizeChronicle(value);
    if (!normalized) throw new Error("Invalid chronicle");
    if (normalized !== value) saveChronicle(storage, normalized);
    return normalized;
  } catch {
    // Invalid local data is discarded below.
  }
  storage.removeItem(CHRONICLE_KEY);
  return EMPTY_CHRONICLE;
};
