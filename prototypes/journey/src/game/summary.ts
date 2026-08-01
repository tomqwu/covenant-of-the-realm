import { ENDINGS, STAT_KEYS, STAT_NAMES } from "./content";
import type { GameState, Locale, Stats } from "./types";

const effectText = (effect: Partial<Stats>, locale: Locale): string =>
  STAT_KEYS
    .filter((stat) => (effect[stat] ?? 0) !== 0)
    .map((stat) => {
      const amount = effect[stat]!;
      return `${STAT_NAMES[stat][locale]} ${amount > 0 ? "+" : ""}${amount}`;
    })
    .join(" · ");

export const buildJourneySummary = (state: GameState, routeUrl?: string): string | null => {
  if (state.phase !== "ended" || !state.ending) return null;
  const locale = state.locale;
  const title = locale === "zh" ? "《山河有契：行旅之契》" : "Mountains & Rivers · Covenant of the Road";
  const endingLabel = locale === "zh" ? "结局" : "Ending";
  const seedLabel = locale === "zh" ? "旅签" : "Route seed";
  const pathLabel = locale === "zh" ? "行路" : "Path";
  const linkLabel = locale === "zh" ? "同路旅签" : "Replay route";
  const separator = locale === "zh" ? "：" : ": ";
  const path = state.journal
    .map(
      (entry, index) =>
        `${index + 1}. ${entry.place[locale]} — ${entry.choice[locale]}\n   ${entry.aftermath[locale]}\n   ${effectText(entry.effect, locale)}`,
    )
    .join("\n");
  const stats = STAT_KEYS
    .map((stat) => `${STAT_NAMES[stat][locale]} ${state.stats[stat]}`)
    .join(" · ");
  return [
    title,
    `${endingLabel}${separator}${ENDINGS[state.ending].title[locale]}`,
    `${seedLabel}${separator}${state.seed}`,
    ...(routeUrl ? [`${linkLabel}${separator}${routeUrl}`] : []),
    `${pathLabel}${locale === "zh" ? "：" : ":"}`,
    path,
    stats,
    "#山河有契",
  ].join("\n");
};
