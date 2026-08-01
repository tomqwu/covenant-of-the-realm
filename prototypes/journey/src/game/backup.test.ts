import { describe, expect, it } from "vitest";
import { AUDIO_SETTINGS_KEY, DEFAULT_AUDIO_SETTINGS } from "./audio-settings";
import {
  CHRONICLE_KEY,
  EMPTY_CHRONICLE,
  MAX_CHRONICLE_JOURNEYS,
  recordJourney,
} from "./chronicle";
import { beginGame, choose, continueJourney, createGame, visibleChoices } from "./engine";
import { DEFAULT_PREFERENCES, PREFERENCES_KEY } from "./preferences";
import { SAVE_KEY, type StorageLike } from "./storage";
import {
  createLocalBackup,
  clearLocalData,
  isLocalBackup,
  LocalDataMutationError,
  MAX_BACKUP_BYTES,
  parseLocalBackup,
  parseLocalBackupWithMetadata,
  restoreLocalBackup,
  serializeLocalBackup,
} from "./backup";

const memoryStorage = (): StorageLike & { data: Map<string, string> } => {
  const data = new Map<string, string>();
  return {
    data,
    getItem: (key) => data.get(key) ?? null,
    setItem: (key, value) => data.set(key, value),
    removeItem: (key) => data.delete(key),
  };
};

const journey = () => {
  const playing = beginGame(createGame(4242));
  return choose(playing, visibleChoices(playing)[0]!.id);
};

describe("local backup", () => {
  it("serializes and validates a complete versioned bundle", () => {
    const backup = createLocalBackup(
      journey(),
      EMPTY_CHRONICLE,
      DEFAULT_PREFERENCES,
      DEFAULT_AUDIO_SETTINGS,
    );
    const serialized = serializeLocalBackup(backup);
    expect(serialized.endsWith("\n")).toBe(true);
    expect(parseLocalBackup(serialized)).toEqual(backup);
    expect(parseLocalBackupWithMetadata(serialized)).toEqual({
      backup,
      compactedChronicle: false,
    });
    expect(isLocalBackup(backup)).toBe(true);
  });

  it("accepts an intentionally empty current journey", () => {
    const backup = createLocalBackup(
      null,
      EMPTY_CHRONICLE,
      DEFAULT_PREFERENCES,
      DEFAULT_AUDIO_SETTINGS,
    );
    expect(isLocalBackup(backup)).toBe(true);
  });

  it("keeps a maximally bounded valid chronicle inside the import limit", () => {
    let completed = beginGame(createGame(4242));
    while (completed.phase !== "ended") {
      completed = completed.phase === "playing"
        ? choose(completed, visibleChoices(completed)[0]!.id)
        : continueJourney(completed);
    }
    const record = recordJourney(EMPTY_CHRONICLE, completed).journeys[0]!;
    const chronicle = {
      version: 1 as const,
      endings: ["covenant" as const],
      journeys: Array.from({ length: MAX_CHRONICLE_JOURNEYS }, (_, index) => ({
        ...record,
        id: `${index}-`.padEnd(1_024, "x"),
        seed: index + 1,
      })),
    };
    const backup = createLocalBackup(
      completed,
      chronicle,
      DEFAULT_PREFERENCES,
      DEFAULT_AUDIO_SETTINGS,
    );

    expect(new TextEncoder().encode(serializeLocalBackup(backup)).byteLength)
      .toBeLessThanOrEqual(MAX_BACKUP_BYTES);
  });

  it("compacts a valid legacy oversized chronicle without losing ending discovery", () => {
    const journeys = Array.from(
      { length: MAX_CHRONICLE_JOURNEYS + 2 },
      (_, index) => ({
        id: `legacy-${index}`,
        seed: index + 1,
        ending: index === 0 ? "lost" : "covenant",
        stats: { provisions: 3, trust: 3, insight: 3 },
      }),
    );
    const oversized = {
      version: 1,
      journey: null,
      chronicle: { version: 1, endings: ["homeward"], journeys },
      preferences: DEFAULT_PREFERENCES,
      audio: DEFAULT_AUDIO_SETTINGS,
    };

    expect(isLocalBackup(oversized)).toBe(false);
    const parsed = parseLocalBackup(JSON.stringify(oversized));

    expect(parsed?.chronicle.journeys).toHaveLength(MAX_CHRONICLE_JOURNEYS);
    expect(parsed?.chronicle.journeys[0]?.id).toBe("legacy-2");
    expect(parsed?.chronicle.endings).toEqual(["homeward", "lost", "covenant"]);
    expect(isLocalBackup(parsed)).toBe(true);
    expect(parseLocalBackupWithMetadata(JSON.stringify(oversized))?.compactedChronicle)
      .toBe(true);
  });

  it("rejects malformed and invalid nested data", () => {
    const valid = createLocalBackup(
      journey(),
      EMPTY_CHRONICLE,
      DEFAULT_PREFERENCES,
      DEFAULT_AUDIO_SETTINGS,
    );
    expect(parseLocalBackup("{")).toBeNull();
    for (const value of [
      null,
      { ...valid, version: 2 },
      { ...valid, journey: { version: 1 } },
      { ...valid, chronicle: null },
      { ...valid, preferences: null },
      { ...valid, audio: null },
    ]) {
      expect(isLocalBackup(value)).toBe(false);
      expect(parseLocalBackup(JSON.stringify(value))).toBeNull();
    }
  });

  it("restores every record and removes an intentionally absent journey", () => {
    const storage = memoryStorage();
    const complete = createLocalBackup(
      journey(),
      EMPTY_CHRONICLE,
      { ...DEFAULT_PREFERENCES, contrast: "high" },
      { ...DEFAULT_AUDIO_SETTINGS, volume: 0.7, muted: true },
    );
    restoreLocalBackup(storage, complete);
    expect(storage.data.size).toBe(4);

    restoreLocalBackup(storage, { ...complete, journey: null });
    expect(storage.data.size).toBe(3);
  });

  it("rolls every record back when a storage write fails", () => {
    const storage = memoryStorage();
    storage.data.set(SAVE_KEY, "old journey");
    storage.data.set(CHRONICLE_KEY, "old chronicle");
    let shouldFail = true;
    const failingStorage: StorageLike = {
      ...storage,
      setItem: (key, value) => {
        if (key === PREFERENCES_KEY && shouldFail) {
          shouldFail = false;
          throw new Error("storage full");
        }
        storage.data.set(key, value);
      },
    };
    const backup = createLocalBackup(
      null,
      EMPTY_CHRONICLE,
      DEFAULT_PREFERENCES,
      DEFAULT_AUDIO_SETTINGS,
    );

    expect(() => restoreLocalBackup(failingStorage, backup)).toThrow(
      expect.objectContaining({
        message: "Could not restore local backup",
        rollbackComplete: true,
        cause: expect.objectContaining({ message: "storage full" }),
      }),
    );
    expect(storage.data.size).toBe(2);
    expect(storage.data.get(SAVE_KEY)).toBe("old journey");
    expect(storage.data.get(CHRONICLE_KEY)).toBe("old chronicle");
  });

  it("clears every local record and rolls back a failed removal", () => {
    const storage = memoryStorage();
    const complete = createLocalBackup(
      journey(),
      EMPTY_CHRONICLE,
      DEFAULT_PREFERENCES,
      DEFAULT_AUDIO_SETTINGS,
    );
    restoreLocalBackup(storage, complete);
    clearLocalData(storage);
    expect(storage.data.size).toBe(0);

    restoreLocalBackup(storage, complete);
    storage.data.delete(AUDIO_SETTINGS_KEY);
    let shouldFail = true;
    const failingStorage: StorageLike = {
      ...storage,
      removeItem: (key) => {
        if (key === CHRONICLE_KEY && shouldFail) {
          shouldFail = false;
          throw new Error("storage denied");
        }
        storage.data.delete(key);
      },
    };
    expect(() => clearLocalData(failingStorage)).toThrow(
      expect.objectContaining({
        message: "Could not clear local data",
        rollbackComplete: true,
      }),
    );
    expect(storage.data.size).toBe(3);
  });

  it("attempts every rollback record and reports when recovery is incomplete", () => {
    const storage = memoryStorage();
    for (const key of [SAVE_KEY, CHRONICLE_KEY, PREFERENCES_KEY, AUDIO_SETTINGS_KEY]) {
      storage.data.set(key, `old ${key}`);
    }
    let rollingBack = false;
    const rollbackAttempts: string[] = [];
    const failingStorage: StorageLike = {
      ...storage,
      setItem: (key, value) => {
        if (!rollingBack && key === PREFERENCES_KEY) {
          rollingBack = true;
          throw new Error("mutation denied");
        }
        if (rollingBack) rollbackAttempts.push(key);
        if (rollingBack && key === SAVE_KEY) throw new Error("rollback denied");
        storage.data.set(key, value);
      },
    };
    const backup = createLocalBackup(
      null,
      EMPTY_CHRONICLE,
      DEFAULT_PREFERENCES,
      DEFAULT_AUDIO_SETTINGS,
    );

    let thrown: unknown;
    try {
      restoreLocalBackup(failingStorage, backup);
    } catch (error) {
      thrown = error;
    }

    expect(thrown).toBeInstanceOf(LocalDataMutationError);
    expect(thrown).toMatchObject({ rollbackComplete: false });
    expect(rollbackAttempts).toEqual([
      SAVE_KEY,
      CHRONICLE_KEY,
      PREFERENCES_KEY,
      AUDIO_SETTINGS_KEY,
    ]);
    expect(storage.data.has(SAVE_KEY)).toBe(false);
    expect(storage.data.get(CHRONICLE_KEY)).toBe(`old ${CHRONICLE_KEY}`);
    expect(storage.data.get(PREFERENCES_KEY)).toBe(`old ${PREFERENCES_KEY}`);
    expect(storage.data.get(AUDIO_SETTINGS_KEY)).toBe(`old ${AUDIO_SETTINGS_KEY}`);
  });

  it("classifies a failed pre-mutation snapshot as safely unchanged", () => {
    const writes: string[] = [];
    const storage: StorageLike = {
      getItem: () => {
        throw new Error("storage read denied");
      },
      setItem: (key) => writes.push(`set:${key}`),
      removeItem: (key) => writes.push(`remove:${key}`),
    };

    expect(() => clearLocalData(storage)).toThrow(
      expect.objectContaining({
        message: "Could not clear local data",
        rollbackComplete: true,
        cause: expect.objectContaining({ message: "storage read denied" }),
      }),
    );
    expect(writes).toEqual([]);
  });
});
