import { describe, expect, it, vi } from "vitest";
import {
  beginGame,
  choose,
  continueJourney,
  createGame,
  currentCallback,
  visibleChoices,
} from "./engine";
import {
  createResilientStorage,
  isGameState,
  loadGame,
  SAVE_KEY,
  saveGame,
  type StorageLike,
} from "./storage";

const createStorage = (initial?: string): StorageLike & { removeItem: ReturnType<typeof vi.fn> } => {
  let value = initial ?? null;
  return {
    getItem: vi.fn(() => value),
    setItem: vi.fn((_key: string, next: string) => {
      value = next;
    }),
    removeItem: vi.fn(() => {
      value = null;
    }),
  };
};

describe("persistence", () => {
  it("mirrors successful persistent reads, writes, and removals", () => {
    const data = new Map([["existing", "old"]]);
    const primary: StorageLike = {
      getItem: (key) => data.get(key) ?? null,
      setItem: (key, value) => data.set(key, value),
      removeItem: (key) => data.delete(key),
    };
    const storage = createResilientStorage(primary);
    expect(storage.getItem("existing")).toBe("old");
    expect(storage.getItem("missing")).toBeNull();
    storage.setItem("new", "value");
    storage.removeItem("existing");
    expect(storage.isPersistent()).toBe(true);
    expect([...data]).toEqual([["new", "value"]]);
  });

  it("continues in memory when persistent reads or writes are denied", () => {
    const readDenied = createResilientStorage({
      getItem: () => { throw new Error("denied"); },
      setItem: vi.fn(),
      removeItem: vi.fn(),
    });
    expect(readDenied.getItem("save")).toBeNull();
    readDenied.setItem("save", "session");
    expect(readDenied.getItem("save")).toBe("session");
    readDenied.removeItem("save");
    expect(readDenied.getItem("save")).toBeNull();
    expect(readDenied.isPersistent()).toBe(false);

    const writeDenied = createResilientStorage({
      getItem: () => null,
      setItem: () => { throw new Error("full"); },
      removeItem: vi.fn(),
    });
    writeDenied.setItem("save", "latest");
    expect(writeDenied.getItem("save")).toBe("latest");
    expect(writeDenied.isPersistent()).toBe(false);
  });

  it("falls back when persistent removal fails or no store exists", () => {
    const removeDenied = createResilientStorage({
      getItem: () => null,
      setItem: vi.fn(),
      removeItem: () => { throw new Error("denied"); },
    });
    removeDenied.removeItem("save");
    expect(removeDenied.isPersistent()).toBe(false);

    const memoryOnly = createResilientStorage(null);
    memoryOnly.setItem("save", "session");
    expect(memoryOnly.getItem("save")).toBe("session");
    memoryOnly.removeItem("save");
    expect(memoryOnly.getItem("save")).toBeNull();
    expect(memoryOnly.isPersistent()).toBe(false);
  });

  it("saves and loads a game", () => {
    const storage = createStorage();
    const state = createGame(81);
    saveGame(storage, state);
    expect(loadGame(storage)).toEqual(state);
    expect(storage.setItem).toHaveBeenCalledWith(SAVE_KEY, JSON.stringify(state));
  });

  it("returns null for no save", () => {
    expect(loadGame(createStorage())).toBeNull();
  });

  it("removes malformed JSON", () => {
    const storage = createStorage("{");
    expect(loadGame(storage)).toBeNull();
    expect(storage.removeItem).toHaveBeenCalledWith(SAVE_KEY);
  });

  it("removes structurally invalid saves", () => {
    const storage = createStorage(JSON.stringify({ version: 0 }));
    expect(loadGame(storage)).toBeNull();
    expect(storage.removeItem).toHaveBeenCalled();
  });

  it("migrates a valid legacy journal to stable choice IDs on load", () => {
    const reflection = choose(beginGame(createGame(4242)), "mend-rope");
    const legacy = structuredClone(reflection);
    delete (legacy.journal[0] as { choiceId?: string }).choiceId;
    const storage = createStorage(JSON.stringify(legacy));

    const loaded = loadGame(storage);

    expect(loaded?.journal[0]?.choiceId).toBe("mend-rope");
    expect(storage.setItem).toHaveBeenCalledWith(SAVE_KEY, JSON.stringify(loaded));
    expect(currentCallback(continueJourney(loaded!))).not.toBeNull();
  });

  it("validates every persisted field", () => {
    const valid = createGame(4);
    expect(isGameState(valid)).toBe(true);
    const invalid: unknown[] = [
      null,
      { ...valid, version: 2 },
      { ...valid, seed: "4" },
      { ...valid, seed: 0 },
      { ...valid, seed: 1.5 },
      { ...valid, seed: 0x1_0000_0000 },
      { ...valid, locale: "fr" },
      { ...valid, phase: "paused" },
      { ...valid, route: "route" },
      { ...valid, route: [] },
      { ...valid, route: [1] },
      { ...valid, route: ["missing", ...valid.route.slice(1)] },
      { ...valid, sceneIndex: "0" },
      { ...valid, sceneIndex: -1 },
      { ...valid, sceneIndex: 6 },
      { ...valid, stats: null },
      { ...valid, stats: { ...valid.stats, provisions: "8" } },
      { ...valid, stats: { ...valid.stats, trust: "0" } },
      { ...valid, stats: { ...valid.stats, insight: "0" } },
      { ...valid, stats: { ...valid.stats, insight: 20 } },
      { ...valid, journal: null },
      { ...valid, journal: [{}] },
      { ...valid, journal: [{ encounterId: 2 }] },
      { ...valid, journal: [{ encounterId: "x", place: null, choice: null }] },
      { ...valid, journal: [{ encounterId: "x", place: { zh: 1, en: "x" }, choice: { zh: "x", en: "x" } }] },
      { ...valid, journal: [{ encounterId: "x", place: { zh: "x", en: "x" }, choice: null, aftermath: null, effect: null }] },
      { ...valid, journal: [{ encounterId: "x", place: { zh: "x", en: "x" }, choice: { zh: "x", en: "x" }, aftermath: null, effect: null }] },
      { ...valid, journal: [{ encounterId: "x", place: { zh: "x", en: "x" }, choice: { zh: "x", en: "x" }, aftermath: { zh: "x", en: "x" }, effect: null }] },
      { ...valid, journal: [{ encounterId: "x", place: { zh: "x", en: "x" }, choice: { zh: "x", en: "x" }, aftermath: { zh: "x", en: "x" }, effect: { provisions: 10 } }] },
      { ...valid, ending: "elsewhere" },
      { ...valid, ending: "covenant" },
      { ...valid, phase: "ended" },
    ];
    for (const value of invalid) expect(isGameState(value)).toBe(false);
  });

  it("accepts reachable phases and rejects impossible route lifecycle states", () => {
    const intro = createGame(4242);
    const playing = beginGame(intro);
    const reflection = choose(playing, visibleChoices(playing)[0]!.id);
    const nextEncounter = continueJourney(reflection);
    let completed = nextEncounter;
    while (completed.phase !== "ended") {
      completed = completed.phase === "playing"
        ? choose(completed, visibleChoices(completed)[0]!.id)
        : continueJourney(completed);
    }
    const completeWith = (choices: readonly number[]) => {
      let state = beginGame(createGame(4242));
      for (const choiceIndex of choices) {
        state = choose(state, visibleChoices(state)[choiceIndex]!.id);
        if (state.phase === "reflection") state = continueJourney(state);
      }
      return state;
    };
    const homeward = completeWith([0, 1, 0, 1, 1]);
    const wanderer = completeWith([0, 0, 1, 1, 1]);
    const lostStart = beginGame(createGame(77));
    const lost = choose(lostStart, visibleChoices(lostStart)[1]!.id);
    const ridge = continueJourney(lost);
    const lostAtRidge = choose(ridge, visibleChoices(ridge)[1]!.id);
    const marsh = continueJourney(lostAtRidge);
    const lostInMarsh = choose(marsh, visibleChoices(marsh)[1]!.id);
    const unavailableLegacyChoice = visibleChoices(marsh)[0]!;
    const impossibleLegacyRequirement = {
      ...lostInMarsh,
      journal: [
        ...lostInMarsh.journal.slice(0, 2),
        {
          ...lostInMarsh.journal[2]!,
          choiceId: undefined,
          choice: unavailableLegacyChoice.label,
          aftermath: unavailableLegacyChoice.aftermath,
          effect: unavailableLegacyChoice.effect,
        },
      ],
      stats: { provisions: 0, trust: 1, insight: 4 },
    };
    expect(lostInMarsh).toMatchObject({ phase: "ended", ending: "lost" });
    expect(isGameState(impossibleLegacyRequirement)).toBe(false);

    for (const state of [
      intro,
      playing,
      reflection,
      nextEncounter,
      completed,
      homeward,
      wanderer,
      lostInMarsh,
    ]) {
      expect(isGameState(state)).toBe(true);
    }
    const legacyReflection = structuredClone(reflection);
    delete (legacyReflection.journal[0] as { choiceId?: string }).choiceId;
    expect(isGameState(legacyReflection)).toBe(true);
    const legacyWithoutProvisionEffect = {
      ...legacyReflection,
      journal: [
        { ...legacyReflection.journal[0]!, effect: { trust: 2, insight: 1 } },
        ...legacyReflection.journal.slice(1),
      ],
      stats: { provisions: 8, trust: 2, insight: 1 },
    };
    expect(isGameState(legacyWithoutProvisionEffect)).toBe(true);
    const solitaryReflection = choose(playing, visibleChoices(playing)[1]!.id);
    const legacySolitaryWithoutProvisionEffect = {
      ...solitaryReflection,
      journal: [
        {
          ...solitaryReflection.journal[0]!,
          choiceId: undefined,
          effect: { insight: 1 },
        },
      ],
      stats: { provisions: 8, trust: 0, insight: 1 },
    };
    expect(isGameState(legacySolitaryWithoutProvisionEffect)).toBe(true);
    const impossibleLegacyEffect = {
      ...legacyReflection,
      journal: [
        {
          ...legacyReflection.journal[0]!,
          effect: { provisions: -8, trust: 2, insight: 1 },
        },
      ],
      stats: { provisions: 0, trust: 2, insight: 1 },
      phase: "ended",
      ending: "lost",
    };
    expect(isGameState(impossibleLegacyEffect)).toBe(false);

    for (const state of [
      { ...intro, phase: "reflection" },
      { ...intro, phase: "playing", sceneIndex: 5, journal: completed.journal },
      { ...reflection, phase: "intro" },
      { ...reflection, stats: { ...reflection.stats, provisions: 0 } },
      { ...reflection, stats: { ...reflection.stats, trust: reflection.stats.trust + 1 } },
      { ...reflection, route: [...reflection.route].reverse() },
      { ...reflection, journal: [{ ...reflection.journal[0]!, encounterId: reflection.route[1]! }] },
      { ...reflection, journal: [{ ...reflection.journal[0]!, choiceId: "unknown-choice" }] },
      { ...reflection, journal: [{ ...reflection.journal[0]!, effect: { insight: 1 } }] },
      {
        ...lostInMarsh,
        journal: lostInMarsh.journal.map((entry, index) => index === 2
          ? { ...entry, choiceId: visibleChoices(marsh)[0]!.id }
          : entry),
      },
      { ...completed, sceneIndex: 4, journal: completed.journal.slice(0, 4) },
      { ...completed, ending: "homeward" },
      { ...lostInMarsh, sceneIndex: 5, journal: completed.journal },
      { ...lostInMarsh, stats: { ...lostInMarsh.stats, provisions: 1 } },
    ]) {
      expect(isGameState(state)).toBe(false);
    }
  });
});
