import { describe, expect, it } from "vitest";
import type { StorageLike } from "./storage";
import {
  DEFAULT_PREFERENCES,
  loadPreferences,
  PREFERENCES_KEY,
  savePreferences,
  updatePreference,
} from "./preferences";

const memoryStorage = (): StorageLike & { data: Map<string, string> } => {
  const data = new Map<string, string>();
  return {
    data,
    getItem: (key) => data.get(key) ?? null,
    setItem: (key, value) => data.set(key, value),
    removeItem: (key) => data.delete(key),
  };
};

describe("player preferences", () => {
  it("uses system-aware defaults when no preferences exist", () => {
    expect(loadPreferences(memoryStorage())).toEqual(DEFAULT_PREFERENCES);
  });

  it("saves and restores every supported preference", () => {
    const storage = memoryStorage();
    const preferences = {
      ...DEFAULT_PREFERENCES,
      textScale: "large" as const,
      motion: "reduced" as const,
      contrast: "high" as const,
    };
    savePreferences(storage, preferences);
    expect(loadPreferences(storage)).toEqual(preferences);
  });

  it("removes malformed or invalid local data", () => {
    const storage = memoryStorage();
    storage.setItem(PREFERENCES_KEY, "{");
    expect(loadPreferences(storage)).toBe(DEFAULT_PREFERENCES);
    expect(storage.data.has(PREFERENCES_KEY)).toBe(false);

    storage.setItem(PREFERENCES_KEY, JSON.stringify({ ...DEFAULT_PREFERENCES, motion: "lots" }));
    expect(loadPreferences(storage)).toBe(DEFAULT_PREFERENCES);
    expect(storage.data.has(PREFERENCES_KEY)).toBe(false);
  });

  it("updates valid controls and ignores unknown values", () => {
    const large = updatePreference(DEFAULT_PREFERENCES, "textScale", "large");
    const reduced = updatePreference(large, "motion", "reduced");
    const high = updatePreference(reduced, "contrast", "high");
    expect(high).toMatchObject({ textScale: "large", motion: "reduced", contrast: "high" });
    expect(updatePreference(high, "motion", "lots")).toBe(high);
    expect(updatePreference(high, "unknown", "high")).toBe(high);
  });
});
