import type { StorageLike } from "./storage";

export const AUDIO_SETTINGS_KEY = "shan-he-you-qi:audio:v1";

export interface AudioSettings {
  readonly version: 1;
  readonly volume: number;
  readonly muted: boolean;
}

export const DEFAULT_AUDIO_SETTINGS: AudioSettings = {
  version: 1,
  volume: 0.35,
  muted: false,
};

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null;

export const isAudioSettings = (value: unknown): value is AudioSettings =>
  isRecord(value) &&
  value.version === 1 &&
  typeof value.volume === "number" &&
  Number.isFinite(value.volume) &&
  value.volume >= 0 &&
  value.volume <= 1 &&
  typeof value.muted === "boolean";

export const normalizeVolume = (volume: number): number =>
  Number.isFinite(volume) ? Math.min(1, Math.max(0, volume)) : DEFAULT_AUDIO_SETTINGS.volume;

export const loadAudioSettings = (storage: StorageLike): AudioSettings => {
  const serialized = storage.getItem(AUDIO_SETTINGS_KEY);
  if (!serialized) return DEFAULT_AUDIO_SETTINGS;
  try {
    const value: unknown = JSON.parse(serialized);
    if (isAudioSettings(value)) return value;
  } catch {
    // Invalid local settings fall back to a quiet, unmuted default.
  }
  storage.removeItem(AUDIO_SETTINGS_KEY);
  return DEFAULT_AUDIO_SETTINGS;
};

export const saveAudioSettings = (storage: StorageLike, settings: AudioSettings): void => {
  storage.setItem(AUDIO_SETTINGS_KEY, JSON.stringify(settings));
};
