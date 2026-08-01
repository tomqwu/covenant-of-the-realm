import { describe, expect, it, vi } from "vitest";
import { beginGame, choose, continueJourney, createGame, visibleChoices } from "./engine";
import {
  CHRONICLE_KEY,
  discoveredEncounters,
  discoveredEndings,
  EMPTY_CHRONICLE,
  isChronicle,
  journeyRecordId,
  loadChronicle,
  recordJourney,
  saveChronicle,
  MAX_CHRONICLE_JOURNEYS,
} from "./chronicle";
import type { StorageLike } from "./storage";

const completedGame = (seed = 4242) => {
  let state = beginGame(createGame(seed));
  while (state.phase !== "ended") {
    state = state.phase === "playing" ? choose(state, visibleChoices(state)[0]!.id) : continueJourney(state);
  }
  return state;
};

const lostGame = (seed = 77) => {
  let state = beginGame(createGame(seed));
  while (state.phase !== "ended") {
    state = state.phase === "playing" ? choose(state, visibleChoices(state)[1]!.id) : continueJourney(state);
  }
  return state;
};

const storageWith = (initial?: string): StorageLike & { removeItem: ReturnType<typeof vi.fn> } => {
  let value = initial ?? null;
  return {
    getItem: vi.fn(() => value),
    setItem: vi.fn((_key, next) => {
      value = next;
    }),
    removeItem: vi.fn(() => {
      value = null;
    }),
  };
};

describe("journey chronicle", () => {
  it("records a completed route once and reveals its ending", () => {
    const ended = completedGame();
    const recorded = recordJourney(EMPTY_CHRONICLE, ended);
    expect(recorded.journeys).toHaveLength(1);
    expect(recorded.journeys[0]?.id).toBe(journeyRecordId(ended));
    expect(recorded.journeys[0]?.id).toContain("mend-rope");
    expect(recorded.journeys[0]?.route).toEqual(ended.route);
    expect(recorded.journeys[0]?.route).not.toBe(ended.route);
    expect(recorded.journeys[0]?.encountersSeen).toBe(5);
    expect(discoveredEndings(recorded)).toEqual(new Set(["covenant"]));
    expect(discoveredEncounters(recorded)).toEqual(new Set(ended.route));
    expect(recordJourney(recorded, ended)).toBe(recorded);
  });

  it("reveals only encounters actually reached before an early lost ending", () => {
    const ended = lostGame();
    expect(ended.journal).toHaveLength(3);
    const recorded = recordJourney(EMPTY_CHRONICLE, ended);
    expect(recorded.journeys[0]?.encountersSeen).toBe(3);
    expect(discoveredEncounters(recorded)).toEqual(new Set(ended.route.slice(0, 3)));
    expect(recorded.encounters).toEqual(ended.route.slice(0, 3));

    const legacyRecord = { ...recorded.journeys[0]!, encountersSeen: undefined };
    expect(discoveredEncounters({ version: 1, journeys: [legacyRecord] }))
      .toEqual(new Set(ended.route.slice(0, 3)));
    expect(discoveredEncounters({
      version: 1,
      journeys: [{ ...legacyRecord, id: "unrecognized-lost-record" }],
    })).toEqual(new Set());
  });

  it("keeps identity stable across prose edits and recognizes legacy records", () => {
    const ended = completedGame();
    const renamed = {
      ...ended,
      journal: ended.journal.map((entry) => ({
        ...entry,
        choice: { zh: `${entry.choice.zh}（修订）`, en: `${entry.choice.en} (revised)` },
      })),
    };
    expect(journeyRecordId(renamed)).toBe(journeyRecordId(ended));

    const legacyId = `${ended.seed}:${ended.journal
      .map((entry) => `${entry.encounterId}/${entry.choice.zh}`)
      .join("|")}`;
    const legacyState = structuredClone(ended);
    for (const entry of legacyState.journal) {
      delete (entry as { choiceId?: string }).choiceId;
    }
    expect(journeyRecordId(legacyState)).toBe(legacyId);
    const record = recordJourney(EMPTY_CHRONICLE, ended).journeys[0]!;
    const legacy = { version: 1 as const, journeys: [{ ...record, id: legacyId }] };
    expect(recordJourney(legacy, ended)).toBe(legacy);
  });

  it("bounds retained paths while preserving every discovered ending", () => {
    const ended = completedGame();
    const record = recordJourney(EMPTY_CHRONICLE, ended).journeys[0]!;
    const journeys = Array.from({ length: MAX_CHRONICLE_JOURNEYS }, (_, index) => ({
      ...record,
      id: `old-${index}`,
      seed: index + 1,
    }));
    const chronicle = {
      version: 1 as const,
      journeys,
      endings: ["lost" as const, "homeward" as const],
    };

    const next = recordJourney(chronicle, ended);
    expect(next.journeys).toHaveLength(MAX_CHRONICLE_JOURNEYS);
    expect(next.journeys[0]?.id).toBe("old-1");
    expect(next.journeys.at(-1)?.id).toBe(journeyRecordId(ended));
    expect(discoveredEndings(next)).toEqual(new Set(["lost", "homeward", "covenant"]));
    expect(discoveredEncounters(next)).toEqual(new Set(ended.route));
    expect(isChronicle(next)).toBe(true);
  });

  it("does not record an unfinished journey", () => {
    const playing = beginGame(createGame(4));
    expect(recordJourney(EMPTY_CHRONICLE, playing)).toBe(EMPTY_CHRONICLE);
  });

  it("derives legacy seed-only discoveries and persists them with the next route", () => {
    const first = completedGame();
    const record = recordJourney(EMPTY_CHRONICLE, first).journeys[0]!;
    const legacy = {
      version: 1 as const,
      journeys: [{ ...record, route: undefined }],
    };

    expect(discoveredEncounters(legacy)).toEqual(new Set(createGame(record.seed).route));
    const next = recordJourney(legacy, completedGame(77));
    expect(next.encounters).toEqual([...discoveredEncounters(next)]);
    expect(next.encounters).toEqual(
      expect.arrayContaining([...createGame(record.seed).route, ...createGame(77).route]),
    );
  });

  it("saves and loads validated progress", () => {
    const storage = storageWith();
    const chronicle = recordJourney(EMPTY_CHRONICLE, completedGame());
    saveChronicle(storage, chronicle);
    expect(storage.setItem).toHaveBeenCalledWith(CHRONICLE_KEY, JSON.stringify(chronicle));
    expect(loadChronicle(storage)).toEqual(chronicle);
  });

  it("compacts an oversized legacy chronicle without forgetting evicted endings", () => {
    const record = recordJourney(EMPTY_CHRONICLE, completedGame()).journeys[0]!;
    const complementaryRoute = [
      "ferry-letter",
      "ridge-fire",
      "marsh-cranes",
      "city-ledger",
      "gate-names",
    ];
    const journeys = Array.from({ length: MAX_CHRONICLE_JOURNEYS + 3 }, (_, index) => ({
      ...record,
      id: `legacy-${index}`,
      seed: index + 1,
      ending: index === 0 ? "lost" as const : "covenant" as const,
      route: index === 0 ? complementaryRoute : record.route,
    }));
    const storage = storageWith(JSON.stringify({ version: 1, journeys }));

    const compacted = loadChronicle(storage);

    expect(compacted.journeys).toHaveLength(MAX_CHRONICLE_JOURNEYS);
    expect(compacted.journeys[0]?.id).toBe("legacy-3");
    expect(discoveredEndings(compacted)).toEqual(new Set(["lost", "covenant"]));
    expect(discoveredEncounters(compacted).size).toBe(10);
    expect(compacted.encounters).toHaveLength(10);
    expect(storage.setItem).toHaveBeenCalledWith(CHRONICLE_KEY, JSON.stringify(compacted));
    expect(storage.removeItem).not.toHaveBeenCalled();
  });

  it("falls back safely for missing, malformed, or invalid data", () => {
    expect(loadChronicle(storageWith())).toBe(EMPTY_CHRONICLE);
    const malformed = storageWith("{");
    expect(loadChronicle(malformed)).toBe(EMPTY_CHRONICLE);
    expect(malformed.removeItem).toHaveBeenCalledWith(CHRONICLE_KEY);
    const invalid = storageWith(JSON.stringify({ version: 2 }));
    expect(loadChronicle(invalid)).toBe(EMPTY_CHRONICLE);
  });

  it("validates the complete chronicle schema", () => {
    const record = recordJourney(EMPTY_CHRONICLE, completedGame()).journeys[0]!;
    const valid = { version: 1, journeys: [record] };
    expect(isChronicle(valid)).toBe(true);
    expect(isChronicle({ version: 1, journeys: [{ ...record, route: undefined }] })).toBe(true);
    expect(isChronicle({ version: 1, journeys: [record], endings: ["lost", "covenant"] })).toBe(true);
    expect(isChronicle({ version: 1, journeys: [record], encounters: [...record.route!] })).toBe(true);
    expect(discoveredEndings({ version: 1, journeys: [record], endings: ["lost"] }))
      .toEqual(new Set(["lost", "covenant"]));
    for (const value of [
      null,
      { ...valid, version: 2 },
      { ...valid, journeys: null },
      { ...valid, journeys: [null] },
      { ...valid, journeys: [{ ...record, id: 1 }] },
      { ...valid, journeys: [{ ...record, id: "" }] },
      { ...valid, journeys: [{ ...record, id: "x".repeat(1_025) }] },
      { ...valid, journeys: [{ ...record, seed: "1" }] },
      { ...valid, journeys: [{ ...record, seed: 0 }] },
      { ...valid, journeys: [{ ...record, seed: 1.5 }] },
      { ...valid, journeys: [{ ...record, seed: 0x1_0000_0000 }] },
      { ...valid, journeys: [{ ...record, ending: "other" }] },
      { ...valid, journeys: [{ ...record, stats: null }] },
      { ...valid, journeys: [{ ...record, stats: { ...record.stats, trust: 10 } }] },
      { ...valid, journeys: [{ ...record, stats: { ...record.stats, trust: 1.5 } }] },
      { ...valid, journeys: [{ ...record, route: "route" }] },
      { ...valid, journeys: [{ ...record, route: [] }] },
      { ...valid, journeys: [{ ...record, route: [...record.route!].reverse() }] },
      { ...valid, journeys: [{ ...record, route: [1, ...record.route!.slice(1)] }] },
      { ...valid, journeys: [{ ...record, encountersSeen: "5" }] },
      { ...valid, journeys: [{ ...record, encountersSeen: 0 }] },
      { ...valid, journeys: [{ ...record, encountersSeen: 6 }] },
      { ...valid, journeys: [{ ...record, encountersSeen: 1.5 }] },
      { ...valid, journeys: [{ ...record, encountersSeen: 4 }] },
      { ...valid, journeys: [record, { ...record }] },
      {
        ...valid,
        journeys: Array.from({ length: MAX_CHRONICLE_JOURNEYS + 1 }, (_, index) => ({
          ...record,
          id: `route-${index}`,
          seed: index + 1,
        })),
      },
      { ...valid, endings: "lost" },
      { ...valid, endings: ["other"] },
      { ...valid, endings: ["lost", "lost"] },
      { ...valid, encounters: "ferry-rope" },
      { ...valid, encounters: ["other"] },
      { ...valid, encounters: ["ferry-rope", "ferry-rope"] },
    ]) {
      expect(isChronicle(value)).toBe(false);
    }
  });
});
