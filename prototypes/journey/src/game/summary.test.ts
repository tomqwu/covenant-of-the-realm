import { describe, expect, it } from "vitest";
import { beginGame, choose, continueJourney, createGame, setLocale, visibleChoices } from "./engine";
import { buildJourneySummary } from "./summary";

const completedGame = () => {
  let state = beginGame(createGame(4242));
  while (state.phase !== "ended") {
    state = state.phase === "playing" ? choose(state, visibleChoices(state)[0]!.id) : continueJourney(state);
  }
  return state;
};

describe("journey summary", () => {
  it("returns no artifact for an unfinished route", () => {
    expect(buildJourneySummary(createGame(2))).toBeNull();
  });

  it("builds a complete Chinese summary", () => {
    const summary = buildJourneySummary(completedGame(), "https://example.test/game/?seed=4242");
    expect(summary).toContain("《山河有契：行旅之契》");
    expect(summary).toContain("结局：守契 · 山河有应");
    expect(summary).toContain("旅签：4242");
    expect(summary).toContain("同路旅签：https://example.test/game/?seed=4242");
    expect(summary).toContain("1. 芦渡");
    expect(summary).toContain("新缆绷紧时");
    expect(summary).toContain("盘缠 -1 · 信义 +2 · 见闻 +1");
    expect(summary).toContain("盘缠 1 · 信义 7 · 见闻 6");
  });

  it("builds the English variant", () => {
    const summary = buildJourneySummary(setLocale(completedGame(), "en"));
    expect(summary).toContain("Mountains & Rivers · Covenant of the Road");
    expect(summary).toContain("Ending: Covenant · The Land Answers");
    expect(summary).toContain("Path:");
    expect(summary).toContain("When the new rope draws taut");
    expect(summary).toContain("Provisions -1 · Trust +2 · Insight +1");
    expect(summary).toContain("Provisions 1 · Trust 7 · Insight 6");
  });

  it("omits unchanged resources from partial authored effects", () => {
    let state = beginGame(createGame(4242));
    while (state.phase !== "ended") {
      state = state.phase === "playing"
        ? choose(state, visibleChoices(state).at(-1)!.id)
        : continueJourney(state);
    }

    const summary = buildJourneySummary(setLocale(state, "en"))!;
    expect(summary).toContain("Provisions -3 · Insight +1");
    expect(summary).not.toContain("Provisions -3 · Trust");
  });

  it("keeps canonical resource order for valid data with shuffled object keys", () => {
    const completed = completedGame();
    const first = completed.journal[0]!;
    const shuffled = {
      ...completed,
      stats: {
        insight: completed.stats.insight,
        provisions: completed.stats.provisions,
        trust: completed.stats.trust,
      },
      journal: [
        {
          ...first,
          effect: {
            insight: first.effect.insight,
            provisions: first.effect.provisions,
            trust: first.effect.trust,
          },
        },
        ...completed.journal.slice(1),
      ],
    };

    const summary = buildJourneySummary(shuffled)!;
    expect(summary).toContain("盘缠 -1 · 信义 +2 · 见闻 +1");
    expect(summary).toContain("盘缠 1 · 信义 7 · 见闻 6");
  });
});
