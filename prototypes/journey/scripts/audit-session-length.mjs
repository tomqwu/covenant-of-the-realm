#!/usr/bin/env node
import { readFile } from "node:fs/promises";
import { build } from "vite";

const buildResult = await build({
  configFile: false,
  logLevel: "silent",
  build: {
    ssr: "src/game/engine.ts",
    write: false,
    rollupOptions: { output: { format: "es" } },
  },
});
const buildOutput = Array.isArray(buildResult)
  ? buildResult.flatMap((result) => result.output)
  : buildResult.output;
const engineChunk = buildOutput.find((output) => output.type === "chunk");
if (!engineChunk) throw new Error("Unable to bundle the game engine for the content audit.");
const code = engineChunk.code;
const moduleUrl = `data:text/javascript;base64,${Buffer.from(code).toString("base64")}`;
const {
  beginGame,
  choose,
  continueJourney,
  createGame,
  currentCallback,
  currentEncounter,
  endingContent,
  meetsRequirement,
  visibleChoices,
} = await import(moduleUrl);

const englishWords = (value) =>
  value.match(/[A-Za-z]+(?:[’'-][A-Za-z]+)*/g)?.length ?? 0;
const chineseHan = (value) => value.match(/\p{Script=Han}/gu)?.length ?? 0;

const routes = new Map();
const encounters = new Map();
for (let seed = 1; seed <= 128; seed += 1) {
  const state = beginGame(createGame(seed));
  routes.set(state.route.join("|"), state);
}

const terminalPaths = [];
const walk = (state, totals) => {
  const encounter = currentEncounter(state);
  if (!encounter) throw new Error("A traversed playing state has no encounter.");
  encounters.set(encounter.id, encounter);
  const callback = currentCallback(state);
  const sceneText = (locale) => [
    encounter.place[locale],
    encounter.title[locale],
    encounter.body[locale],
    callback?.[locale] ?? "",
    ...visibleChoices(state).flatMap((choice) => [
      choice.label[locale],
      choice.detail[locale],
    ]),
  ].join(" ");
  const visibleEnglishWords = englishWords(sceneText("en"));
  const visibleChineseHan = chineseHan(sceneText("zh"));

  for (const choice of visibleChoices(state).filter((candidate) =>
    meetsRequirement(state.stats, candidate.requirement)
  )) {
    const nextState = choose(state, choice.id);
    const nextTotals = {
      englishWords: totals.englishWords + visibleEnglishWords +
        englishWords(choice.aftermath.en),
      chineseHanCharacters: totals.chineseHanCharacters +
        visibleChineseHan + chineseHan(choice.aftermath.zh),
    };
    if (nextState.phase === "ended") {
      const ending = endingContent(nextState);
      if (!ending || !nextState.ending) throw new Error("A terminal state has no ending.");
      const earlyLoss = nextState.ending === "lost" &&
        nextState.journal.length < nextState.route.length;
      terminalPaths.push({
        kind: earlyLoss ? "earlyLoss" : "completed",
        ending: nextState.ending,
        reachedEncounters: nextState.journal.length,
        englishWords: nextTotals.englishWords +
          englishWords(`${ending.title.en} ${ending.body.en}`),
        chineseHanCharacters: nextTotals.chineseHanCharacters +
          chineseHan(`${ending.title.zh} ${ending.body.zh}`),
      });
    } else {
      walk(continueJourney(nextState), nextTotals);
    }
  }
};

for (const state of routes.values()) {
  walk(state, {
    englishWords: 0,
    chineseHanCharacters: 0,
  });
}

const statKeys = ["provisions", "trust", "insight"];
const mechanicallyDominatedChoices = [...encounters.values()]
  .flatMap((encounter) => encounter.choices.filter((candidate) =>
    encounter.choices.some((alternative) =>
      alternative.id !== candidate.id &&
      statKeys.every((stat) =>
        (alternative.effect[stat] ?? 0) >= (candidate.effect[stat] ?? 0)
      ) &&
      statKeys.some((stat) =>
        (alternative.effect[stat] ?? 0) > (candidate.effect[stat] ?? 0)
      )
    )
  ).map((choice) => choice.id))
  .sort();

const range = (kind, metric) => {
  const values = terminalPaths
    .filter((path) => path.kind === kind)
    .map((path) => path[metric]);
  return { minimum: Math.min(...values), maximum: Math.max(...values) };
};

const audit = {
  routeCombinations: routes.size,
  validTerminalPaths: terminalPaths.length,
  terminalPathCounts: {
    completed: terminalPaths.filter((path) => path.kind === "completed").length,
    earlyLoss: terminalPaths.filter((path) => path.kind === "earlyLoss").length,
  },
  endingCounts: Object.fromEntries(
    ["covenant", "homeward", "wanderer", "lost"].map((ending) => [
      ending,
      terminalPaths.filter((path) => path.ending === ending).length,
    ]),
  ),
  earlyLossByReachedEncounters: Object.fromEntries(
    [1, 2, 3, 4].map((reachedEncounters) => [
      reachedEncounters,
      terminalPaths.filter((path) =>
        path.kind === "earlyLoss" && path.reachedEncounters === reachedEncounters
      ).length,
    ]),
  ),
  mechanicallyDominatedChoices,
  completed: {
    englishWords: range("completed", "englishWords"),
    chineseHanCharacters: range("completed", "chineseHanCharacters"),
  },
  earlyLoss: {
    englishWords: range("earlyLoss", "englishWords"),
    chineseHanCharacters: range("earlyLoss", "chineseHanCharacters"),
  },
};
const expectedMechanicallyDominatedChoices = [
  "buy-rafts",
  "force-causeway",
  "hire-skiff",
  "leave-letter",
  "mark-path",
  "show-paper",
  "take-high-road",
  "wait-storm",
];
const expected = {
  routeCombinations: 32,
  validTerminalPaths: 416,
  terminalPathCounts: { completed: 288, earlyLoss: 128 },
  endingCounts: { covenant: 160, homeward: 96, wanderer: 32, lost: 128 },
  earlyLossByReachedEncounters: { 1: 0, 2: 0, 3: 96, 4: 32 },
  mechanicallyDominatedChoices: expectedMechanicallyDominatedChoices,
  completed: {
    englishWords: { minimum: 471, maximum: 502 },
    chineseHanCharacters: { minimum: 643, maximum: 683 },
  },
  earlyLoss: {
    englishWords: { minimum: 283, maximum: 396 },
    chineseHanCharacters: { minimum: 367, maximum: 535 },
  },
};
if (JSON.stringify(audit) !== JSON.stringify(expected)) {
  throw new Error(
    `Authored text envelope changed. Review session-length claims, then update the audited range: ${JSON.stringify(audit)}`,
  );
}
const tradeoffResearch = await readFile("docs/TRADEOFF_RESEARCH.md", "utf8");
const documentedDominatedChoices = [...tradeoffResearch.matchAll(
  /^\|[^|]+\|[^|]+\| `([^`]+)` \|[^|]+\|$/gm,
)].map((match) => match[1]).sort();
if (
  JSON.stringify(documentedDominatedChoices) !==
  JSON.stringify(expectedMechanicallyDominatedChoices)
) {
  throw new Error(
    `TRADEOFF_RESEARCH.md must document the exact audited dominated-choice set: ${JSON.stringify(expectedMechanicallyDominatedChoices)}`,
  );
}
console.log(JSON.stringify(audit, null, 2));
