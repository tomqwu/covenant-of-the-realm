import { describe, expect, it } from "vitest";
import { encounterById } from "./content";
import {
  INITIAL_STATS,
  applyEffect,
  beginGame,
  choose,
  continueJourney,
  createGame,
  createNextJourney,
  createRoute,
  currentCallback,
  currentEncounter,
  determineEnding,
  endingContent,
  meetsRequirement,
  normalizeSeed,
  restartGame,
  setLocale,
  visibleChoices,
} from "./engine";
import type { GameState } from "./types";

const playFirstChoices = (seed = 4242): GameState => {
  let state = beginGame(createGame(seed));
  while (state.phase !== "ended") {
    state =
      state.phase === "playing"
        ? choose(state, visibleChoices(state)[0]!.id)
        : continueJourney(state);
  }
  return state;
};

describe("route seeding", () => {
  it("normalizes unusual inputs", () => {
    expect(normalizeSeed(Number.NaN)).toBe(1);
    expect(normalizeSeed(0)).toBe(1);
    expect(normalizeSeed(-19.9)).toBe(19);
    expect(normalizeSeed(2 ** 32 + 7)).toBe(7);
  });

  it("creates a stable five-region route", () => {
    const first = createRoute(4242);
    expect(first).toEqual(createRoute(4242));
    expect(first).toHaveLength(5);
    expect(first.map((id) => encounterById(id).region)).toEqual([0, 1, 2, 3, 4]);
    expect(createRoute(4243)).not.toEqual(first);
  });

  it("rejects an unknown encounter", () => {
    expect(() => encounterById("missing")).toThrow("Unknown encounter");
  });
});

describe("game transitions", () => {
  it("starts only an intro and exposes encounters only while playing", () => {
    const intro = createGame(42, "en");
    expect(intro.locale).toBe("en");
    expect(currentEncounter(intro)).toBeNull();
    const playing = beginGame(intro);
    expect(playing.phase).toBe("playing");
    expect(beginGame(playing)).toBe(playing);
    expect(currentEncounter(playing)?.region).toBe(0);
    expect(visibleChoices(intro)).toEqual([]);
    expect(continueJourney(playing)).toBe(playing);
    expect(currentCallback(intro)).toBeNull();
    expect(currentCallback(playing)).toBeNull();
  });

  it("selects authored callbacks from stable prior choice IDs", () => {
    let state = beginGame(createGame(4242));
    state = choose(state, visibleChoices(state)[0]!.id);
    expect(state.journal[0]?.choiceId).toBe("mend-rope");
    state = continueJourney(state);
    expect(currentCallback(state)?.en).toContain("ferry");

    const legacy: GameState = {
      ...state,
      journal: state.journal.map(({ choiceId: _choiceId, ...entry }) => entry),
    };
    expect(currentCallback(legacy)).toBeNull();
  });

  it("checks requirements and applies bounded effects", () => {
    expect(meetsRequirement(INITIAL_STATS)).toBe(true);
    expect(meetsRequirement({ ...INITIAL_STATS, trust: 2 }, { stat: "trust", minimum: 2 })).toBe(true);
    expect(meetsRequirement(INITIAL_STATS, { stat: "trust", minimum: 2 })).toBe(false);
    expect(applyEffect({ provisions: 1, trust: 8, insight: 4 }, { provisions: -5, trust: 8 })).toEqual({
      provisions: 0,
      trust: 9,
      insight: 4,
    });
    expect(applyEffect(INITIAL_STATS, {})).toEqual(INITIAL_STATS);
  });

  it("guards invalid choices", () => {
    const intro = createGame(2);
    expect(() => choose(intro, "anything")).toThrow("only be made");
    const playing = beginGame(intro);
    expect(() => choose(playing, "anything")).toThrow("Unknown choice");
    expect(currentEncounter({ ...playing, route: [] })).toBeNull();
    const locked: GameState = {
      ...playing,
      route: ["marsh-marker", ...playing.route.slice(1)],
    };
    expect(() => choose(locked, "raise-marker")).toThrow("requirement not met");
  });

  it("records choices and reaches the covenant ending", () => {
    const ended = playFirstChoices();
    expect(ended.phase).toBe("ended");
    expect(ended.ending).toBe("covenant");
    expect(ended.journal).toHaveLength(5);
    expect(endingContent(ended)?.title.en).toContain("Covenant");
  });

  it("can become lost before the pass", () => {
    let state = beginGame(createGame(77));
    state = choose(state, visibleChoices(state)[1]!.id);
    expect(state.phase).toBe("reflection");
    expect(state.journal[0]?.aftermath.en).toBeTruthy();
    expect(state.journal[0]?.effect.provisions).toBe(-3);
    state = continueJourney(state);
    state = choose(state, visibleChoices(state)[1]!.id);
    state = continueJourney(state);
    state = choose(state, visibleChoices(state)[1]!.id);
    expect(state.phase).toBe("ended");
    expect(state.ending).toBe("lost");
    expect(state.stats.provisions).toBe(0);
  });

  it("classifies non-covenant endings", () => {
    expect(determineEnding({ provisions: 4, trust: 0, insight: 0 })).toBe("homeward");
    expect(determineEnding({ provisions: 2, trust: 3, insight: 3 })).toBe("wanderer");
    expect(determineEnding({ provisions: 1, trust: 4, insight: 4 })).toBe("covenant");
  });

  it("changes locale, restarts, and creates another route", () => {
    const original = beginGame(createGame(93));
    expect(setLocale(original, "zh")).toBe(original);
    const english = setLocale(original, "en");
    expect(english.locale).toBe("en");
    const restarted = restartGame(english);
    expect(restarted.phase).toBe("playing");
    expect(restarted.seed).toBe(93);
    expect(restarted.locale).toBe("en");
    expect(restarted.route).toEqual(original.route);
    const next = createNextJourney(english);
    expect(next.phase).toBe("intro");
    expect(next.seed).not.toBe(93);
    expect(next.route).not.toEqual(english.route);
    expect(endingContent(original)).toBeNull();
  });

  it("advances through seed collisions until a genuinely new route appears", () => {
    for (let seed = 1; seed <= 1_024; seed += 1) {
      const current = createGame(seed);
      const next = createNextJourney(current);
      expect(next.seed).not.toBe(current.seed);
      expect(next.route).not.toEqual(current.route);
    }
  });

  it("exhaustively terminates every valid branch across seeded route variants", () => {
    const endings = new Set<string>();
    const endingCounts = new Map<string, number>();
    const chosenIds = new Set<string>();
    const routeIds = new Set<string>();
    const routeCounts = new Map<string, number>();
    const encounterCounts = new Map<string, number>();
    let lockedChoices = 0;
    let offeredChoices = 0;
    let terminalPaths = 0;

    const visit = (state: GameState): void => {
      for (const value of Object.values(state.stats)) {
        expect(value).toBeGreaterThanOrEqual(0);
        expect(value).toBeLessThanOrEqual(9);
      }
      expect(state.journal.length).toBeLessThanOrEqual(5);
      if (state.phase === "ended") {
        terminalPaths += 1;
        endings.add(state.ending!);
        endingCounts.set(state.ending!, (endingCounts.get(state.ending!) ?? 0) + 1);
        return;
      }
      if (state.phase === "reflection") {
        visit(continueJourney(state));
        return;
      }
      const enabled = visibleChoices(state).filter((choice) =>
        meetsRequirement(state.stats, choice.requirement),
      );
      offeredChoices += visibleChoices(state).length;
      lockedChoices += visibleChoices(state).length - enabled.length;
      expect(enabled.length).toBeGreaterThan(0);
      for (const choice of enabled) {
        chosenIds.add(choice.id);
        visit(choose(state, choice.id));
      }
    };

    for (let seed = 1; seed <= 128; seed += 1) {
      const game = createGame(seed);
      const routeId = game.route.join("|");
      routeIds.add(routeId);
      routeCounts.set(routeId, (routeCounts.get(routeId) ?? 0) + 1);
      for (const encounterId of game.route) {
        encounterCounts.set(encounterId, (encounterCounts.get(encounterId) ?? 0) + 1);
      }
      visit(beginGame(game));
    }
    expect(terminalPaths).toBe(1_664);
    expect(Object.fromEntries(endingCounts)).toEqual({
      covenant: 640,
      homeward: 384,
      lost: 512,
      wanderer: 128,
    });
    expect(chosenIds.size).toBe(20);
    expect(routeIds.size).toBe(32);
    expect(Math.min(...routeCounts.values())).toBe(3);
    expect(Math.max(...routeCounts.values())).toBe(5);
    expect(Math.min(...encounterCounts.values())).toBe(63);
    expect(Math.max(...encounterCounts.values())).toBe(65);
    expect({ lockedChoices, offeredChoices }).toEqual({
      lockedChoices: 384,
      offeredChoices: 3_840,
    });
    expect(endings).toEqual(new Set(["covenant", "homeward", "wanderer", "lost"]));
  });
});
