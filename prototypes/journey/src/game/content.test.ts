import { describe, expect, it } from "vitest";
import { ENDINGS, ENCOUNTERS, REGION_NAMES, STAT_KEYS, STAT_NAMES } from "./content";
import type { LocalizedText } from "./types";

const expectLocalized = (value: LocalizedText): void => {
  expect(value.zh.trim().length).toBeGreaterThan(0);
  expect(value.en.trim().length).toBeGreaterThan(0);
};

describe("authored content contract", () => {
  it("keeps exactly two encounters in each ordered region", () => {
    expect(REGION_NAMES).toHaveLength(5);
    for (const [region, name] of REGION_NAMES.entries()) {
      expectLocalized(name);
      const encounters = ENCOUNTERS.filter((encounter) => encounter.region === region);
      expect(encounters).toHaveLength(2);
      for (const encounter of encounters) expect(encounter.place).toBe(name);
    }
  });

  it("keeps every resource name complete and bilingual", () => {
    expect(STAT_KEYS).toEqual(["provisions", "trust", "insight"]);
    expect(Object.keys(STAT_NAMES).sort()).toEqual(["insight", "provisions", "trust"]);
    for (const name of Object.values(STAT_NAMES)) expectLocalized(name);
  });

  it("keeps encounter and choice IDs globally unique with complete bilingual prose", () => {
    const encounterIds = ENCOUNTERS.map((encounter) => encounter.id);
    const choices = ENCOUNTERS.flatMap((encounter) => encounter.choices);
    const choiceIds = choices.map((choice) => choice.id);
    expect(new Set(encounterIds).size).toBe(encounterIds.length);
    expect(new Set(choiceIds).size).toBe(choiceIds.length);
    for (const id of [...encounterIds, ...choiceIds]) {
      expect(id).toMatch(/^[a-z0-9]+(?:-[a-z0-9]+)*$/);
    }

    for (const encounter of ENCOUNTERS) {
      expectLocalized(encounter.title);
      expectLocalized(encounter.body);
      expect(encounter.choices).toHaveLength(2);
      const legacyEffectSignatures = encounter.choices.map((choice) =>
        JSON.stringify({
          trust: choice.effect.trust ?? 0,
          insight: choice.effect.insight ?? 0,
        })
      );
      expect(new Set(legacyEffectSignatures).size).toBe(encounter.choices.length);
      for (const choice of encounter.choices) {
        expectLocalized(choice.label);
        expectLocalized(choice.detail);
        expectLocalized(choice.aftermath);
        expect(Object.values(choice.effect).some((amount) => amount !== 0)).toBe(true);
        for (const amount of Object.values(choice.effect)) {
          expect(Number.isInteger(amount)).toBe(true);
          expect(amount).toBeGreaterThanOrEqual(-9);
          expect(amount).toBeLessThanOrEqual(9);
        }
        if (choice.requirement) {
          expect(choice.requirement.minimum).toBeGreaterThan(0);
          expect(["provisions", "trust", "insight"]).toContain(choice.requirement.stat);
        }
      }
    }
  });

  it("covers every prior-region choice with one later callback", () => {
    expect(ENCOUNTERS.filter((encounter) => encounter.region === 0).every((encounter) => !encounter.callbacks)).toBe(true);
    for (let region = 1; region < REGION_NAMES.length; region += 1) {
      const priorChoices = new Set(
        ENCOUNTERS.filter((encounter) => encounter.region === region - 1)
          .flatMap((encounter) => encounter.choices)
          .map((choice) => choice.id),
      );
      for (const encounter of ENCOUNTERS.filter((candidate) => candidate.region === region)) {
        expect(encounter.callbacks).toHaveLength(2);
        const targets = encounter.callbacks!.flatMap((callback) => callback.afterChoices);
        expect(new Set(targets)).toEqual(priorChoices);
        expect(targets).toHaveLength(priorChoices.size);
        for (const callback of encounter.callbacks!) expectLocalized(callback.text);
      }
    }
  });

  it("keeps all four endings complete and bilingual", () => {
    expect(Object.keys(ENDINGS).sort()).toEqual(["covenant", "homeward", "lost", "wanderer"]);
    for (const ending of Object.values(ENDINGS)) {
      expectLocalized(ending.title);
      expectLocalized(ending.body);
    }
  });
});
