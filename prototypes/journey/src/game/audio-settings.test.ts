import { describe, expect, it } from "vitest";
import type { StorageLike } from "./storage";
import {
  AUDIO_SETTINGS_KEY,
  DEFAULT_AUDIO_SETTINGS,
  loadAudioSettings,
  normalizeVolume,
  saveAudioSettings,
} from "./audio-settings";

const memoryStorage = (): StorageLike & { data: Map<string, string> } => {
  const data = new Map<string, string>();
  return {
    data,
    getItem: (key) => data.get(key) ?? null,
    setItem: (key, value) => data.set(key, value),
    removeItem: (key) => data.delete(key),
  };
};

describe("ambient audio settings", () => {
  it("uses a quiet default without enabling playback", () => {
    expect(loadAudioSettings(memoryStorage())).toEqual(DEFAULT_AUDIO_SETTINGS);
  });

  it("saves and restores volume and mute", () => {
    const storage = memoryStorage();
    const settings = { ...DEFAULT_AUDIO_SETTINGS, volume: 0.7, muted: true };
    saveAudioSettings(storage, settings);
    expect(loadAudioSettings(storage)).toEqual(settings);
  });

  it("removes corrupt and out-of-range settings", () => {
    const storage = memoryStorage();
    storage.setItem(AUDIO_SETTINGS_KEY, "{");
    expect(loadAudioSettings(storage)).toBe(DEFAULT_AUDIO_SETTINGS);
    expect(storage.data.has(AUDIO_SETTINGS_KEY)).toBe(false);

    storage.setItem(AUDIO_SETTINGS_KEY, JSON.stringify({ ...DEFAULT_AUDIO_SETTINGS, volume: 2 }));
    expect(loadAudioSettings(storage)).toBe(DEFAULT_AUDIO_SETTINGS);
    expect(storage.data.has(AUDIO_SETTINGS_KEY)).toBe(false);
  });

  it("clamps finite volume and repairs non-finite input", () => {
    expect(normalizeVolume(-1)).toBe(0);
    expect(normalizeVolume(0.6)).toBe(0.6);
    expect(normalizeVolume(2)).toBe(1);
    expect(normalizeVolume(Number.NaN)).toBe(DEFAULT_AUDIO_SETTINGS.volume);
  });
});
