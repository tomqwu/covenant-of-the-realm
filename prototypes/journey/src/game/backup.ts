import {
  AUDIO_SETTINGS_KEY,
  isAudioSettings,
  saveAudioSettings,
  type AudioSettings,
} from "./audio-settings";
import {
  CHRONICLE_KEY,
  isChronicle,
  normalizeChronicle,
  saveChronicle,
  type Chronicle,
} from "./chronicle";
import {
  isPreferences,
  PREFERENCES_KEY,
  savePreferences,
  type Preferences,
} from "./preferences";
import {
  isGameState,
  saveGame,
  SAVE_KEY,
  type StorageLike,
} from "./storage";
import type { GameState } from "./types";

export const MAX_BACKUP_BYTES = 256_000;
export const LOCAL_DATA_KEYS = [
  SAVE_KEY,
  CHRONICLE_KEY,
  PREFERENCES_KEY,
  AUDIO_SETTINGS_KEY,
] as const;

export interface LocalBackup {
  readonly version: 1;
  readonly journey: GameState | null;
  readonly chronicle: Chronicle;
  readonly preferences: Preferences;
  readonly audio: AudioSettings;
}

export interface ParsedLocalBackup {
  readonly backup: LocalBackup;
  readonly compactedChronicle: boolean;
}

export class LocalDataMutationError extends Error {
  constructor(
    message: string,
    readonly rollbackComplete: boolean,
    cause: unknown,
  ) {
    super(message, { cause });
    this.name = "LocalDataMutationError";
  }
}

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null;

type LocalBackupEnvelope = Omit<LocalBackup, "chronicle"> & {
  readonly chronicle: unknown;
};

const hasLocalBackupEnvelope = (value: unknown): value is LocalBackupEnvelope =>
  isRecord(value) &&
  value.version === 1 &&
  (value.journey === null || isGameState(value.journey)) &&
  isPreferences(value.preferences) &&
  isAudioSettings(value.audio);

export const isLocalBackup = (value: unknown): value is LocalBackup =>
  hasLocalBackupEnvelope(value) && isChronicle(value.chronicle);

export const createLocalBackup = (
  journey: GameState | null,
  chronicle: Chronicle,
  preferences: Preferences,
  audio: AudioSettings,
): LocalBackup => ({ version: 1, journey, chronicle, preferences, audio });

export const serializeLocalBackup = (backup: LocalBackup): string =>
  `${JSON.stringify(backup, null, 2)}\n`;

export const parseLocalBackupWithMetadata = (
  serialized: string,
): ParsedLocalBackup | null => {
  try {
    const value: unknown = JSON.parse(serialized);
    if (!hasLocalBackupEnvelope(value)) return null;
    const chronicle = normalizeChronicle(value.chronicle);
    return chronicle
      ? {
          backup: createLocalBackup(value.journey, chronicle, value.preferences, value.audio),
          compactedChronicle: chronicle !== value.chronicle,
        }
      : null;
  } catch {
    return null;
  }
};

export const parseLocalBackup = (serialized: string): LocalBackup | null =>
  parseLocalBackupWithMetadata(serialized)?.backup ?? null;

type StoredRecord = readonly [key: string, value: string | null];

const rollbackRecords = (storage: StorageLike, previous: readonly StoredRecord[]): boolean => {
  let complete = true;
  for (const [key, value] of previous) {
    try {
      if (value === null) storage.removeItem(key);
      else storage.setItem(key, value);
    } catch {
      complete = false;
    }
  }
  return complete;
};

const mutateRecords = (
  storage: StorageLike,
  message: string,
  mutation: () => void,
): void => {
  let previous: readonly StoredRecord[];
  try {
    previous = LOCAL_DATA_KEYS.map((key) => [key, storage.getItem(key)] as const);
  } catch (cause) {
    throw new LocalDataMutationError(message, true, cause);
  }

  try {
    mutation();
  } catch (cause) {
    throw new LocalDataMutationError(message, rollbackRecords(storage, previous), cause);
  }
};

export const restoreLocalBackup = (storage: StorageLike, backup: LocalBackup): void => {
  mutateRecords(storage, "Could not restore local backup", () => {
    if (backup.journey) saveGame(storage, backup.journey);
    else storage.removeItem(SAVE_KEY);
    saveChronicle(storage, backup.chronicle);
    savePreferences(storage, backup.preferences);
    saveAudioSettings(storage, backup.audio);
  });
};

export const clearLocalData = (storage: StorageLike): void => {
  mutateRecords(storage, "Could not clear local data", () => {
    for (const key of LOCAL_DATA_KEYS) storage.removeItem(key);
  });
};
