import type { StorageLike } from "./storage";

export const PREFERENCES_KEY = "shan-he-you-qi:preferences:v1";

export type TextScale = "normal" | "large";
export type MotionPreference = "system" | "reduced";
export type ContrastPreference = "system" | "high";
export type PreferenceKey = "textScale" | "motion" | "contrast";

export interface Preferences {
  readonly version: 1;
  readonly textScale: TextScale;
  readonly motion: MotionPreference;
  readonly contrast: ContrastPreference;
}

export const DEFAULT_PREFERENCES: Preferences = {
  version: 1,
  textScale: "normal",
  motion: "system",
  contrast: "system",
};

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null;

export const isPreferences = (value: unknown): value is Preferences =>
  isRecord(value) &&
  value.version === 1 &&
  (value.textScale === "normal" || value.textScale === "large") &&
  (value.motion === "system" || value.motion === "reduced") &&
  (value.contrast === "system" || value.contrast === "high");

export const loadPreferences = (storage: StorageLike): Preferences => {
  const serialized = storage.getItem(PREFERENCES_KEY);
  if (!serialized) return DEFAULT_PREFERENCES;
  try {
    const value: unknown = JSON.parse(serialized);
    if (isPreferences(value)) return value;
  } catch {
    // Corrupt local preferences fall back to accessible system defaults.
  }
  storage.removeItem(PREFERENCES_KEY);
  return DEFAULT_PREFERENCES;
};

export const savePreferences = (storage: StorageLike, preferences: Preferences): void => {
  storage.setItem(PREFERENCES_KEY, JSON.stringify(preferences));
};

export const updatePreference = (
  preferences: Preferences,
  key: string,
  value: string,
): Preferences => {
  if (key === "textScale" && (value === "normal" || value === "large")) {
    return { ...preferences, textScale: value };
  }
  if (key === "motion" && (value === "system" || value === "reduced")) {
    return { ...preferences, motion: value };
  }
  if (key === "contrast" && (value === "system" || value === "high")) {
    return { ...preferences, contrast: value };
  }
  return preferences;
};
