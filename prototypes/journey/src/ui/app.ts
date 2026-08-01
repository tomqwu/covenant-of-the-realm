import { ENDINGS, ENCOUNTERS, REGION_NAMES, STAT_KEYS } from "../game/content";
import {
  loadAudioSettings,
  normalizeVolume,
  saveAudioSettings,
  type AudioSettings,
} from "../game/audio-settings";
import {
  clearLocalData,
  createLocalBackup,
  LOCAL_DATA_KEYS,
  LocalDataMutationError,
  MAX_BACKUP_BYTES,
  parseLocalBackupWithMetadata,
  restoreLocalBackup,
  serializeLocalBackup,
  type LocalBackup,
} from "../game/backup";
import { backupFileName, journeyFileName } from "../game/artifact-name";
import {
  discoveredEncounters,
  discoveredEndings,
  loadChronicle,
  recordJourney,
  saveChronicle,
  type Chronicle,
} from "../game/chronicle";
import {
  beginGame,
  choose,
  continueJourney,
  createGame,
  createNextJourney,
  currentCallback,
  currentEncounter,
  endingContent,
  meetsRequirement,
  normalizeSeed,
  restartGame,
  setLocale,
  visibleChoices,
} from "../game/engine";
import { loadGame, saveGame, type StorageLike } from "../game/storage";
import {
  loadPreferences,
  savePreferences,
  updatePreference,
  type Preferences,
} from "../game/preferences";
import { buildJourneySummary } from "../game/summary";
import type { ServiceWorkerUpdateController } from "../pwa/update";
import type { Choice, GameState, Locale, Requirement, Stats } from "../game/types";
import { localize, statLabel, UI_COPY } from "./copy";

export interface AppOptions {
  readonly storage: StorageLike;
  readonly restoreStorage?: StorageLike;
  readonly isStoragePersistent?: () => boolean;
  readonly seed: number;
  readonly forceNew?: boolean;
  readonly initialRoute?: readonly string[];
  readonly initialLocale?: Locale;
  readonly keyboardTarget?: Document;
  readonly clipboard?: { writeText(text: string): Promise<void> };
  readonly nativeShare?: NativeShare;
  readonly updateController?: ServiceWorkerUpdateController;
  readonly routeUrl?: (seed: number, route: readonly string[], locale: Locale) => string;
  readonly onJourneyLinkChange?: (
    seed: number,
    route: readonly string[],
    locale: Locale,
  ) => void;
  readonly ambientAudio?: AmbientAudio;
  readonly prepareAmbientAudio?: () => Promise<void>;
  readonly downloadFile?: (name: string, contents: string, mimeType?: string) => void;
  readonly now?: () => Date;
  readonly reload?: () => void;
  readonly readFile?: (file: File) => Promise<string>;
  readonly storageEventTarget?: Window;
  readonly pageLifecycleSource?: PageLifecycleSource;
  readonly storageDurability?: StorageDurability;
  readonly visibilitySource?: VisibilitySource;
}

export interface StorageDurability {
  isPersisted(): Promise<boolean>;
  requestPersistence(): Promise<boolean>;
}

export interface VisibilitySource {
  readonly hidden: boolean;
  addEventListener(type: "visibilitychange", listener: EventListener): void;
  removeEventListener(type: "visibilitychange", listener: EventListener): void;
}

export interface PageLifecycleSource {
  addEventListener(type: "pageshow", listener: EventListener): void;
  removeEventListener(type: "pageshow", listener: EventListener): void;
}

export interface NativeShare {
  canShare?(data: NativeShareData): boolean;
  share(data: NativeShareData): Promise<void>;
}

export interface NativeShareData {
  readonly title: string;
  readonly text: string;
}

export interface AmbientAudio {
  play(): Promise<void>;
  pause(): void;
  volume: number;
  muted: boolean;
  loop: boolean;
}

type ShareStatus =
  | "idle"
  | "copy-success"
  | "download-success"
  | "download-failure"
  | "copy-failure"
  | "native-success"
  | "native-failure";
type AudioStatus = "idle" | "failure" | "paused-hidden";
type DurabilityStatus =
  | "unsupported"
  | "checking"
  | "best-effort"
  | "requesting"
  | "protected"
  | "denied"
  | "failure";
type BackupStatus =
  | "idle"
  | "reading"
  | "ready"
  | "ready-compacted"
  | "invalid"
  | "too-large"
  | "restoring"
  | "restore-failed"
  | "restore-rollback-failed"
  | "confirm-clear"
  | "clearing"
  | "clear-failed"
  | "clear-rollback-failed";
type BackupExportStatus = "idle" | "success" | "failure";
type ExternalInterruption = "data" | "update" | null;

interface AmbientView {
  readonly settings: AudioSettings;
  readonly playing: boolean;
  readonly status: AudioStatus;
  readonly available: boolean;
  readonly pending: boolean;
}

interface BackupView {
  readonly status: BackupStatus;
  readonly exportStatus: BackupExportStatus;
  readonly manualExport: string | null;
  readonly ready: boolean;
  readonly canExport: boolean;
  readonly canImport: boolean;
  readonly canClear: boolean;
  readonly persistent: boolean;
  readonly durability: DurabilityStatus;
}

export interface MountedGame {
  getState(): GameState;
  getChronicle(): Chronicle;
  getPreferences(): Preferences;
  getAudioSettings(): AudioSettings;
  isAmbientPlaying(): boolean;
  destroy(): void;
}

export const seedFromSearch = (search: string, fallback: number): number => {
  const raw = new URLSearchParams(search).get("seed");
  return raw === null ? normalizeSeed(fallback) : normalizeSeed(Number(raw));
};

export const localeFromSearch = (search: string): Locale =>
  new URLSearchParams(search).get("lang") === "en" ? "en" : "zh";

export const routeFromSearch = (search: string): readonly string[] | undefined => {
  const encoded = new URLSearchParams(search).get("route");
  if (!encoded) return undefined;
  const route = encoded.split(",");
  if (
    route.length !== 5 ||
    !route.every(
      (encounterId, region) =>
        ENCOUNTERS.find((encounter) => encounter.id === encounterId)?.region === region,
    )
  ) return undefined;
  return route;
};

const effectText = (effect: Partial<Stats>, locale: Locale): string =>
  STAT_KEYS
    .filter((stat) => (effect[stat] ?? 0) !== 0)
    .map((stat) => {
      const amount = effect[stat]!;
      return `${statLabel(stat, locale)} ${amount > 0 ? "+" : ""}${amount}`;
    })
    .join(" · ");

const statsText = (stats: Stats, locale: Locale): string =>
  STAT_KEYS
    .map((stat) => `${statLabel(stat, locale)} ${stats[stat]}`)
    .join(" · ");

const escapeHtml = (value: string): string =>
  value.replace(/[&<>"']/g, (character) => `&#${character.codePointAt(0)};`);

const persistedText = (value: { readonly zh: string; readonly en: string }, locale: Locale): string =>
  escapeHtml(localize(value, locale));

const renderRegionTrack = (state: GameState): string =>
  REGION_NAMES.map((region, index) => {
    const status = index < state.sceneIndex ? "complete" : index === state.sceneIndex ? "current" : "future";
    return `<li class="route-stop route-stop--${status}" aria-current="${status === "current" ? "step" : "false"}">
      <span class="route-stop__mark" aria-hidden="true"></span>
      <span>${localize(region, state.locale)}</span>
    </li>`;
  }).join("");

const renderStats = (state: GameState): string =>
  STAT_KEYS
    .map(
      (stat) => `<div class="stat" data-stat="${stat}">
        <dt>${statLabel(stat, state.locale)}</dt>
        <dd>${state.stats[stat]}</dd>
      </div>`,
    )
    .join("");

const renderJournal = (state: GameState): string => {
  const entries = state.journal.length
    ? state.journal
        .map(
          (entry, index) => `<li>
            <span>${String(index + 1).padStart(2, "0")} · ${persistedText(entry.place, state.locale)}</span>
            <strong>${persistedText(entry.choice, state.locale)}</strong>
            <em>${effectText(entry.effect, state.locale)}</em>
            <p>${persistedText(entry.aftermath, state.locale)}</p>
          </li>`,
        )
        .join("")
    : `<li class="journal__empty">${localize(UI_COPY.journalEmpty, state.locale)}</li>`;
  return `<details class="journal" ${state.phase === "ended" ? "open" : ""}>
    <summary>${localize(UI_COPY.journal, state.locale)} <span>${state.journal.length}/5</span></summary>
    <ol>${entries}</ol>
  </details>`;
};

const renderChronicle = (state: GameState, chronicle: Chronicle): string => {
  const discovered = discoveredEndings(chronicle);
  const encountered = discoveredEncounters(chronicle);
  const endings = (["covenant", "homeward", "wanderer", "lost"] as const)
    .map((ending) => {
      const known = discovered.has(ending);
      const label = known
        ? localize(ENDINGS[ending].title, state.locale)
        : localize(UI_COPY.undiscoveredEnding, state.locale);
      return `<li class="chronicle__ending ${known ? "chronicle__ending--known" : ""}">
        <span aria-hidden="true">${known ? "●" : "○"}</span>${label}
      </li>`;
    })
    .join("");
  const encounterRows = REGION_NAMES.map((region, regionIndex) => {
    const variants = ENCOUNTERS.filter((encounter) => encounter.region === regionIndex)
      .map((encounter) => {
        const known = encountered.has(encounter.id);
        return `<span class="chronicle__encounter${known ? " chronicle__encounter--known" : ""}">${known ? localize(encounter.title, state.locale) : localize(UI_COPY.undiscoveredEncounter, state.locale)}</span>`;
      })
      .join('<span aria-hidden="true"> · </span>');
    return `<li><strong>${localize(region, state.locale)}</strong><span>${variants}</span></li>`;
  }).join("");
  const recentStart = Math.max(0, chronicle.journeys.length - 5);
  const recent = chronicle.journeys
    .slice(recentStart)
    .map((journey, offset) => ({ journey, index: recentStart + offset }))
    .reverse()
    .map(({ journey, index }) => `<li>
      <button type="button" data-action="chronicle-replay" data-journey-index="${index}" aria-label="${localize(UI_COPY.replayRecordedJourney, state.locale)} · ${localize(ENDINGS[journey.ending].title, state.locale)} · ${localize(UI_COPY.routeSeed, state.locale)} ${journey.seed}">
        <strong>${localize(ENDINGS[journey.ending].title, state.locale)}</strong>
        <span>${localize(UI_COPY.routeSeed, state.locale)} ${journey.seed}</span>
        <small>${statsText(journey.stats, state.locale)}</small>
      </button>
    </li>`)
    .join("");
  return `<details class="chronicle">
    <summary>${localize(UI_COPY.chronicle, state.locale)} <span>${localize(UI_COPY.endingsDiscovered, state.locale)} ${discovered.size}/4 · ${localize(UI_COPY.encountersShort, state.locale)} ${encountered.size}/${ENCOUNTERS.length}</span></summary>
    <p>${localize(UI_COPY.journeysRecorded, state.locale)} · ${chronicle.journeys.length}</p>
    <ul>${endings}</ul>
    <p>${localize(UI_COPY.encountersDiscovered, state.locale)} · ${encountered.size}/${ENCOUNTERS.length}</p>
    <ol class="chronicle__encounters">${encounterRows}</ol>
    ${recent ? `<p>${localize(UI_COPY.recentJourneys, state.locale)}</p><ol class="chronicle__journeys">${recent}</ol>` : ""}
    <p class="chronicle__status" role="status"></p>
  </details>`;
};

const preferenceOption = (
  state: GameState,
  preferences: Preferences,
  key: "textScale" | "motion" | "contrast",
  value: string,
  label: { readonly zh: string; readonly en: string },
): string => `<label>
  <input type="radio" name="preference-${key}" value="${value}" data-preference="${key}" ${preferences[key] === value ? "checked" : ""}>
  <span>${localize(label, state.locale)}</span>
</label>`;

const audioToggleLabel = (state: GameState, ambient: AmbientView): string =>
  localize(
    ambient.pending ? UI_COPY.ambientStarting : ambient.playing ? UI_COPY.ambientStop : UI_COPY.ambientPlay,
    state.locale,
  );

const muteLabel = (state: GameState, ambient: AmbientView): string =>
  localize(ambient.settings.muted ? UI_COPY.ambientUnmute : UI_COPY.ambientMute, state.locale);

const audioStatusText = (state: GameState, ambient: AmbientView): string =>
  !ambient.available
    ? localize(UI_COPY.ambientUnavailable, state.locale)
    : ambient.status === "failure"
      ? localize(UI_COPY.ambientFailed, state.locale)
      : ambient.status === "paused-hidden"
        ? localize(UI_COPY.ambientPausedWhenHidden, state.locale)
      : ambient.pending
        ? localize(UI_COPY.ambientStarting, state.locale)
        : "";

const renderAmbient = (state: GameState, ambient: AmbientView): string => `<div class="ambient">
  <p class="ambient__title">${localize(UI_COPY.ambient, state.locale)}</p>
  <div class="ambient__actions">
    <button type="button" data-action="audio" aria-pressed="${ambient.playing}" ${ambient.available && !ambient.pending ? "" : "disabled"}>${audioToggleLabel(state, ambient)}</button>
    <button type="button" data-action="mute" aria-pressed="${ambient.settings.muted}" ${ambient.available ? "" : "disabled"}>${muteLabel(state, ambient)}</button>
  </div>
  <label for="ambient-volume">${localize(UI_COPY.ambientVolume, state.locale)} <output for="ambient-volume">${Math.round(ambient.settings.volume * 100)}%</output></label>
  <input id="ambient-volume" data-audio-volume type="range" min="0" max="1" step="0.05" value="${ambient.settings.volume}" ${ambient.available ? "" : "disabled"}>
  <p class="ambient__status" role="status">${audioStatusText(state, ambient)}</p>
</div>`;

const durabilityStatusText = (state: GameState, backup: BackupView): string => {
  if (backup.durability === "checking") return localize(UI_COPY.storageChecking, state.locale);
  if (backup.durability === "best-effort") return localize(UI_COPY.storageBestEffort, state.locale);
  if (backup.durability === "requesting") return localize(UI_COPY.storageRequesting, state.locale);
  if (backup.durability === "protected") return localize(UI_COPY.storageProtected, state.locale);
  if (backup.durability === "denied") return localize(UI_COPY.storageDenied, state.locale);
  if (backup.durability === "failure") {
    return localize(UI_COPY.storageProtectionFailed, state.locale);
  }
  return localize(UI_COPY.storageProtectionUnavailable, state.locale);
};

const renderDurability = (state: GameState, backup: BackupView): string => {
  const hidden = backup.durability === "unsupported";
  const disabled =
    !backup.persistent ||
    backup.durability === "checking" ||
    backup.durability === "requesting" ||
    backup.durability === "protected";
  const buttonLabel = backup.durability === "requesting"
    ? UI_COPY.storageRequesting
    : backup.durability === "protected"
      ? UI_COPY.storageProtectionGranted
      : UI_COPY.storageProtect;
  return `<div class="durability"${backup.persistent ? "" : " hidden"}>
    <p class="durability__title">${localize(UI_COPY.storageDurability, state.locale)}</p>
    <p class="durability__status" role="status">${durabilityStatusText(state, backup)}</p>
    <button type="button" data-action="protect-storage"${hidden ? " hidden" : ""}${disabled ? " disabled" : ""}>${localize(buttonLabel, state.locale)}</button>
  </div>`;
};

const backupStatusText = (state: GameState, backup: BackupView): string => {
  if (!backup.persistent) return localize(UI_COPY.backupPersistenceUnavailable, state.locale);
  if (backup.status === "restoring") return localize(UI_COPY.backupRestoring, state.locale);
  if (backup.status === "clearing") return localize(UI_COPY.backupClearing, state.locale);
  if (!backup.canExport && !backup.canImport) {
    return localize(UI_COPY.backupUnavailable, state.locale);
  }
  if (backup.status === "reading") return localize(UI_COPY.backupReading, state.locale);
  if (backup.status === "ready") return localize(UI_COPY.backupReady, state.locale);
  if (backup.status === "ready-compacted") {
    return localize(UI_COPY.backupReadyCompacted, state.locale);
  }
  if (backup.status === "invalid") return localize(UI_COPY.backupInvalid, state.locale);
  if (backup.status === "too-large") return localize(UI_COPY.backupTooLarge, state.locale);
  if (backup.status === "restore-failed") return localize(UI_COPY.backupRestoreFailed, state.locale);
  if (backup.status === "restore-rollback-failed") {
    return localize(UI_COPY.backupRestoreRollbackFailed, state.locale);
  }
  if (backup.status === "confirm-clear") return localize(UI_COPY.backupClearPrompt, state.locale);
  if (backup.status === "clear-failed") return localize(UI_COPY.backupClearFailed, state.locale);
  if (backup.status === "clear-rollback-failed") {
    return localize(UI_COPY.backupClearRollbackFailed, state.locale);
  }
  if (backup.exportStatus === "success") return localize(UI_COPY.backupExported, state.locale);
  if (backup.exportStatus === "failure") {
    return localize(UI_COPY.backupExportFailed, state.locale);
  }
  return "";
};

const renderBackup = (state: GameState, backup: BackupView): string => `<div class="backup">
  <p class="backup__title">${localize(UI_COPY.backup, state.locale)}</p>
  <p class="backup__description">${localize(UI_COPY.backupDescription, state.locale)}</p>
  <div class="backup__actions">
    <button type="button" data-action="backup-export" ${backup.canExport ? "" : "disabled"}>${localize(UI_COPY.backupExport, state.locale)}</button>
    <label class="backup__file ${backup.canImport ? "" : "backup__file--disabled"}">
      <span>${localize(UI_COPY.backupChoose, state.locale)}</span>
      <input type="file" data-backup-file accept=".json,application/json" ${backup.canImport ? "" : "disabled"}>
    </label>
    <button type="button" data-action="backup-restore" ${backup.ready ? "" : "disabled"}>${localize(UI_COPY.backupRestore, state.locale)}</button>
    <button class="backup__clear" type="button" data-action="backup-clear" ${backup.canClear ? "" : "disabled"}>${localize(UI_COPY.backupClear, state.locale)}</button>
  </div>
  <textarea class="backup__fallback" readonly aria-label="${localize(UI_COPY.backupFallbackLabel, state.locale)}"${backup.manualExport === null ? " hidden" : ""}>${backup.manualExport === null ? "" : escapeHtml(backup.manualExport)}</textarea>
  <p class="backup__status" role="status">${backupStatusText(state, backup)}</p>
</div>`;

const renderPersistenceNotice = (state: GameState, persistent: boolean): string =>
  `<p class="persistence-notice" role="status"${persistent ? " hidden" : ""}>${localize(UI_COPY.persistenceUnavailable, state.locale)}</p>`;

const renderUpdateNotice = (
  state: GameState,
  available: boolean,
  persistent: boolean,
): string =>
  `<aside class="update-notice"${available ? "" : " hidden"}>
    <span role="status">${localize(UI_COPY.updateReady, state.locale)}${persistent ? "" : ` ${localize(UI_COPY.updateResetsSession, state.locale)}`}</span>
    <button class="text-action" type="button" data-action="apply-update">${localize(UI_COPY.applyUpdate, state.locale)}</button>
  </aside>`;

const renderExternalChangeNotice = (
  state: GameState,
  interruption: ExternalInterruption,
  persistent: boolean,
): string => {
  const update = interruption === "update";
  const kicker = update ? UI_COPY.externalUpdateKicker : UI_COPY.externalChangeKicker;
  const title = update ? UI_COPY.externalUpdateTitle : UI_COPY.externalChangeTitle;
  const description = update
    ? `${localize(UI_COPY.externalUpdateDescription, state.locale)}${persistent ? "" : ` ${localize(UI_COPY.updateResetsSession, state.locale)}`}`
    : localize(UI_COPY.externalChangeDescription, state.locale);
  const reload = update ? UI_COPY.externalUpdateReload : UI_COPY.externalChangeReload;
  return `<div class="storage-conflict-backdrop"${interruption ? "" : " hidden"}>
    <section class="storage-conflict" role="alertdialog" aria-modal="true" aria-labelledby="storage-conflict-title" aria-describedby="storage-conflict-description">
      <p class="eyebrow">${localize(kicker, state.locale)}</p>
      <h2 id="storage-conflict-title">${localize(title, state.locale)}</h2>
      <p id="storage-conflict-description">${description}</p>
      <button class="primary-action" type="button" data-action="reload-external">${localize(reload, state.locale)}</button>
    </section>
  </div>`;
};

const renderPreferences = (
  state: GameState,
  preferences: Preferences,
  ambient: AmbientView,
  backup: BackupView,
): string =>
  `<details class="preferences">
    <summary>${localize(UI_COPY.preferences, state.locale)}</summary>
    <fieldset>
      <legend>${localize(UI_COPY.textScale, state.locale)}</legend>
      ${preferenceOption(state, preferences, "textScale", "normal", UI_COPY.textNormal)}
      ${preferenceOption(state, preferences, "textScale", "large", UI_COPY.textLarge)}
    </fieldset>
    <fieldset>
      <legend>${localize(UI_COPY.motion, state.locale)}</legend>
      ${preferenceOption(state, preferences, "motion", "system", UI_COPY.motionSystem)}
      ${preferenceOption(state, preferences, "motion", "reduced", UI_COPY.motionReduced)}
    </fieldset>
    <fieldset>
      <legend>${localize(UI_COPY.contrast, state.locale)}</legend>
      ${preferenceOption(state, preferences, "contrast", "system", UI_COPY.contrastSystem)}
      ${preferenceOption(state, preferences, "contrast", "high", UI_COPY.contrastHigh)}
    </fieldset>
    ${renderAmbient(state, ambient)}
    ${renderDurability(state, backup)}
    ${renderBackup(state, backup)}
  </details>`;

const renderIntro = (state: GameState): string => `<section class="story story--intro" data-testid="intro">
  <p class="eyebrow">${localize(UI_COPY.introKicker, state.locale)}</p>
  <h1 id="story-title" tabindex="-1">${localize(UI_COPY.introTitle, state.locale)}</h1>
  <p class="lede">${localize(UI_COPY.introBody, state.locale)}</p>
  <button class="primary-action" type="button" data-action="begin">${localize(UI_COPY.begin, state.locale)}</button>
</section>`;

const requirementText = (requirement: Requirement, state: GameState): string => {
  const { stat, minimum } = requirement;
  return `${localize(UI_COPY.requirement, state.locale)} ${statLabel(stat, state.locale)} ${minimum}`;
};

const renderChoice = (choice: Choice, index: number, state: GameState): string => {
  const enabled = meetsRequirement(state.stats, choice.requirement);
  return `<button class="choice" type="button" data-choice="${choice.id}" aria-keyshortcuts="${index + 1}" ${enabled ? "" : 'aria-disabled="true"'}>
    <span class="choice__number" aria-hidden="true">${index + 1}</span>
    <span class="choice__copy">
      <strong>${localize(choice.label, state.locale)}</strong>
      <span>${localize(choice.detail, state.locale)}</span>
    </span>
    <span class="choice__effect">${enabled ? effectText(choice.effect, state.locale) : requirementText(choice.requirement!, state)}</span>
  </button>`;
};

const renderEncounter = (state: GameState): string => {
  const encounter = currentEncounter(state)!;
  const callback = currentCallback(state);
  return `<section class="story story--encounter" data-testid="encounter">
    <p class="eyebrow">${String(state.sceneIndex + 1).padStart(2, "0")} · ${localize(encounter.place, state.locale)}</p>
    <h1 id="story-title" tabindex="-1">${localize(encounter.title, state.locale)}</h1>
    <p class="lede">${localize(encounter.body, state.locale)}</p>
    ${callback ? `<p class="narrative-callback" data-testid="callback">${localize(callback, state.locale)}</p>` : ""}
    <fieldset class="choices">
      <legend>${localize(UI_COPY.choicePrompt, state.locale)}</legend>
      ${encounter.choices.map((choice, index) => renderChoice(choice, index, state)).join("")}
    </fieldset>
    <p class="keyboard-hint">${localize(UI_COPY.keyboardHint, state.locale)}</p>
  </section>`;
};

const renderReflection = (state: GameState): string => {
  const entry = state.journal.at(-1)!;
  const nextRegion = REGION_NAMES[state.sceneIndex]!;
  return `<section class="story story--reflection" data-testid="reflection">
    <p class="eyebrow">${localize(UI_COPY.reflectionKicker, state.locale)} · ${persistedText(entry.place, state.locale)}</p>
    <h1 id="story-title" tabindex="-1">${persistedText(entry.choice, state.locale)}</h1>
    <p class="lede">${persistedText(entry.aftermath, state.locale)}</p>
    <button class="primary-action" type="button" data-action="continue" aria-keyshortcuts="Enter">${localize(UI_COPY.onward, state.locale)} · ${localize(nextRegion, state.locale)}</button>
    <p class="keyboard-hint">${localize(UI_COPY.reflectionHint, state.locale)}</p>
  </section>`;
};

const renderEnding = (
  state: GameState,
  shareStatus: ShareStatus,
  canCopy: boolean,
  canNativeShare: boolean,
  canDownload: boolean,
  routeUrl?: string,
): string => {
  const ending = endingContent(state)!;
  const summary = buildJourneySummary(state, routeUrl)!;
  const status =
    shareStatus === "copy-success"
      ? localize(UI_COPY.copied, state.locale)
      : shareStatus === "download-success"
        ? localize(UI_COPY.downloaded, state.locale)
        : shareStatus === "download-failure"
          ? localize(UI_COPY.downloadFailed, state.locale)
      : shareStatus === "native-success"
        ? localize(UI_COPY.shared, state.locale)
        : shareStatus === "native-failure"
          ? localize(UI_COPY.shareFailed, state.locale)
          : shareStatus === "copy-failure" || (!canCopy && !canNativeShare)
        ? localize(UI_COPY.copyFailed, state.locale)
        : "";
  return `<section class="story story--ending" data-testid="ending" data-ending="${state.ending!}">
    <p class="eyebrow">${localize(UI_COPY.endingKicker, state.locale)}</p>
    <h1 id="story-title" tabindex="-1">${localize(ending.title, state.locale)}</h1>
    <p class="lede">${localize(ending.body, state.locale)}</p>
    <div class="ending-actions">
      <button class="primary-action" type="button" data-action="replay" aria-keyshortcuts="R">${localize(UI_COPY.replay, state.locale)}</button>
      <button class="text-action" type="button" data-action="new">${localize(UI_COPY.newJourney, state.locale)}</button>
    </div>
    <details class="share" open>
      <summary>${localize(UI_COPY.shareJourney, state.locale)}</summary>
      <textarea readonly aria-label="${localize(UI_COPY.summaryLabel, state.locale)}">${escapeHtml(summary)}</textarea>
      <div class="share__actions">
        <button class="text-action" type="button" data-action="copy" ${canCopy ? "" : "disabled"}>${localize(UI_COPY.copyJourney, state.locale)}</button>
        ${canDownload ? `<button class="text-action" type="button" data-action="download-summary">${localize(UI_COPY.downloadJourney, state.locale)}</button>` : ""}
        ${canNativeShare ? `<button class="text-action" type="button" data-action="native-share">${localize(UI_COPY.nativeShareJourney, state.locale)}</button>` : ""}
      </div>
      <p class="share__status" role="status">${status}</p>
    </details>
    <p class="keyboard-hint">${localize(UI_COPY.endingHint, state.locale)}</p>
  </section>`;
};

const renderStory = (
  state: GameState,
  shareStatus: ShareStatus,
  canCopy: boolean,
  canNativeShare: boolean,
  canDownload: boolean,
  routeUrl?: string,
): string => {
  if (state.phase === "intro") return renderIntro(state);
  if (state.phase === "playing") return renderEncounter(state);
  if (state.phase === "reflection") return renderReflection(state);
  return renderEnding(state, shareStatus, canCopy, canNativeShare, canDownload, routeUrl);
};

const renderApp = (
  root: HTMLElement,
  state: GameState,
  chronicle: Chronicle,
  preferences: Preferences,
  ambient: AmbientView,
  backup: BackupView,
  shareStatus: ShareStatus,
  canCopy: boolean,
  canNativeShare: boolean,
  canDownload: boolean,
  updateAvailable: boolean,
  externalInterruption: ExternalInterruption,
  routeUrl?: string,
): void => {
  document.documentElement.lang = state.locale === "zh" ? "zh-CN" : "en";
  document.title = localize(UI_COPY.documentTitle, state.locale);
  document
    .querySelector<HTMLMetaElement>('meta[name="description"]')
    ?.setAttribute("content", localize(UI_COPY.documentDescription, state.locale));
  root.dataset.phase = state.phase;
  root.dataset.textScale = preferences.textScale;
  root.dataset.motion = preferences.motion;
  root.dataset.contrast = preferences.contrast;
  root.dataset.progress = String(state.sceneIndex);
  root.innerHTML = `<div class="game-shell">
    ${renderExternalChangeNotice(state, externalInterruption, backup.persistent)}
    <div class="game-shell__session"${externalInterruption ? " inert" : ""}>
    <a class="skip-link" href="#story-title">${localize(UI_COPY.skipToStory, state.locale)}</a>
    <header class="masthead">
      <a class="wordmark" href="#game" aria-label="${localize(UI_COPY.seriesTitle, state.locale)}">
        <span class="wordmark__seal" aria-hidden="true">契</span>
        <span><b>${localize(UI_COPY.gameTitle, state.locale)}</b><small>${localize(UI_COPY.seriesTitle, state.locale)}</small></span>
      </a>
      <div class="masthead__actions">
        <span class="seed"><span>${localize(UI_COPY.routeSeed, state.locale)}</span> ${state.seed}</span>
        <button class="language" type="button" data-action="language" lang="${state.locale === "zh" ? "en" : "zh-CN"}" aria-keyshortcuts="L" aria-label="${localize(UI_COPY.languageLabel, state.locale)}">${localize(UI_COPY.language, state.locale)}</button>
      </div>
    </header>

    ${renderUpdateNotice(state, updateAvailable, backup.persistent)}

    <figure class="landscape" aria-hidden="true">
      <img class="landscape__image" src="./assets/journey-scroll.jpg" alt="" fetchpriority="high">
      <div class="landscape__veil" aria-hidden="true"></div>
    </figure>

    <nav class="route" aria-label="${localize(UI_COPY.progress, state.locale)}">
      <div class="route__line" aria-hidden="true"><span></span></div>
      <ol>${renderRegionTrack(state)}</ol>
    </nav>

    <main id="game" class="game-content">
      <aside class="ledger" aria-label="${localize(UI_COPY.progress, state.locale)}">
        ${renderPersistenceNotice(state, backup.persistent)}
        <dl>${renderStats(state)}</dl>
        ${renderJournal(state)}
        ${renderChronicle(state, chronicle)}
        ${renderPreferences(state, preferences, ambient, backup)}
      </aside>
      ${renderStory(state, shareStatus, canCopy, canNativeShare, canDownload, routeUrl)}
    </main>
    </div>
  </div>`;
};

export const mountGame = (root: HTMLElement, options: AppOptions): MountedGame => {
  const keyboardTarget = options.keyboardTarget ?? document;
  const freshGame = (): GameState => {
    const fresh = createGame(options.seed, options.initialLocale);
    return options.initialRoute ? { ...fresh, route: options.initialRoute } : fresh;
  };
  let state = options.forceNew ? freshGame() : (loadGame(options.storage) ?? freshGame());
  if (options.forceNew) saveGame(options.storage, state);
  options.onJourneyLinkChange?.(state.seed, state.route, state.locale);
  let chronicle = loadChronicle(options.storage);
  let preferences = loadPreferences(options.storage);
  let audioSettings = loadAudioSettings(options.storage);
  let audioPlaying = false;
  let audioPending = false;
  let audioStatus: AudioStatus = "idle";
  let audioPlayVersion = 0;
  let durabilityStatus: DurabilityStatus = options.storageDurability ? "checking" : "unsupported";
  let pendingBackup: LocalBackup | null = null;
  let backupStatus: BackupStatus = "idle";
  let backupExportStatus: BackupExportStatus = "idle";
  let manualBackupExport: string | null = null;
  let backupReadVersion = 0;
  let shareStatus: ShareStatus = "idle";
  let shareRequestVersion = 0;
  let updateAvailable = false;
  let externalInterruption: ExternalInterruption = null;
  let pendingJourneyReplayIndex: number | null = null;
  let destroyed = false;
  let localDataReloadPending = false;
  let ownedLocalDataSignature = "";

  const invalidatePendingBackup = (): void => {
    backupReadVersion += 1;
    pendingBackup = null;
    backupStatus = "idle";
    backupExportStatus = "idle";
    manualBackupExport = null;
  };

  const isStoragePersistent = (): boolean => options.isStoragePersistent?.() ?? true;

  const localDataSignature = (): string =>
    JSON.stringify(LOCAL_DATA_KEYS.map((key) => options.storage.getItem(key)));

  const rememberLocalData = (): void => {
    ownedLocalDataSignature = localDataSignature();
  };

  if (options.ambientAudio) {
    options.ambientAudio.loop = true;
    options.ambientAudio.volume = audioSettings.volume;
    options.ambientAudio.muted = audioSettings.muted;
  }

  const ambientView = (): AmbientView => ({
    settings: audioSettings,
    playing: audioPlaying,
    status: audioStatus,
    available: Boolean(options.ambientAudio),
    pending: audioPending,
  });

  const cancelAmbientOwnership = (): void => {
    audioPlayVersion += 1;
    audioPlaying = false;
    audioPending = false;
    options.ambientAudio?.pause();
  };

  const backupView = (): BackupView => {
    const persistent = isStoragePersistent();
    const reloading = backupStatus === "restoring" || backupStatus === "clearing";
    return {
      status: backupStatus,
      exportStatus: backupExportStatus,
      manualExport: manualBackupExport,
      ready: pendingBackup !== null && persistent && !reloading,
      canExport: Boolean(options.downloadFile) && !reloading,
      canImport: Boolean(options.reload) && persistent && !reloading,
      canClear: Boolean(options.reload) && persistent && !reloading,
      persistent,
      durability: durabilityStatus,
    };
  };

  const recordCompletion = (): void => {
    const nextChronicle = recordJourney(chronicle, state);
    if (nextChronicle !== chronicle) {
      chronicle = nextChronicle;
      saveChronicle(options.storage, chronicle);
    }
  };

  recordCompletion();
  rememberLocalData();

  const commit = (nextState: GameState, focusSelector = ".story h1"): void => {
    const linkChanged =
      nextState.seed !== state.seed ||
      nextState.locale !== state.locale ||
      nextState.route.some((id, index) => id !== state.route[index]);
    state = nextState;
    invalidatePendingBackup();
    pendingJourneyReplayIndex = null;
    if (linkChanged) options.onJourneyLinkChange?.(state.seed, state.route, state.locale);
    shareStatus = "idle";
    saveGame(options.storage, state);
    recordCompletion();
    rememberLocalData();
    renderApp(
      root,
      state,
      chronicle,
      preferences,
      ambientView(),
      backupView(),
      shareStatus,
      Boolean(options.clipboard),
      Boolean(options.nativeShare),
      Boolean(options.downloadFile),
      updateAvailable,
      externalInterruption,
      options.routeUrl?.(state.seed, state.route, state.locale),
    );
    root.querySelector<HTMLElement>(focusSelector)!.focus();
  };

  const copySummary = async (): Promise<void> => {
    const requestVersion = ++shareRequestVersion;
    const copiedState = state;
    let nextStatus: ShareStatus;
    try {
      await options.clipboard!.writeText(
        buildJourneySummary(state, options.routeUrl?.(state.seed, state.route, state.locale))!,
      );
      nextStatus = "copy-success";
    } catch {
      nextStatus = "copy-failure";
    }
    if (destroyed || requestVersion !== shareRequestVersion || state !== copiedState) return;
    shareStatus = nextStatus;
    renderApp(
      root,
      state,
      chronicle,
      preferences,
      ambientView(),
      backupView(),
      shareStatus,
      Boolean(options.clipboard),
      Boolean(options.nativeShare),
      Boolean(options.downloadFile),
      updateAvailable,
      externalInterruption,
      options.routeUrl?.(state.seed, state.route, state.locale),
    );
    root.querySelector<HTMLButtonElement>('[data-action="copy"]')!.focus();
  };

  const shareSummary = async (): Promise<void> => {
    const requestVersion = ++shareRequestVersion;
    const sharedState = state;
    const data: NativeShareData = {
      title: localize(UI_COPY.documentTitle, state.locale),
      text: buildJourneySummary(state, options.routeUrl?.(state.seed, state.route, state.locale))!,
    };
    let nextStatus: ShareStatus;
    let supported = true;
    try {
      supported = options.nativeShare!.canShare?.(data) ?? true;
    } catch {
      supported = false;
    }
    if (!supported) {
      nextStatus = "native-failure";
    } else {
      try {
        await options.nativeShare!.share(data);
        nextStatus = "native-success";
      } catch (error) {
        nextStatus = error instanceof DOMException && error.name === "AbortError"
          ? "idle"
          : "native-failure";
      }
    }
    if (destroyed || requestVersion !== shareRequestVersion || state !== sharedState) return;
    shareStatus = nextStatus;
    renderApp(
      root,
      state,
      chronicle,
      preferences,
      ambientView(),
      backupView(),
      shareStatus,
      Boolean(options.clipboard),
      Boolean(options.nativeShare),
      Boolean(options.downloadFile),
      updateAvailable,
      externalInterruption,
      options.routeUrl?.(state.seed, state.route, state.locale),
    );
    root.querySelector<HTMLButtonElement>('[data-action="native-share"]')!.focus();
  };

  const downloadSummary = (): void => {
    shareRequestVersion += 1;
    const summary = buildJourneySummary(
      state,
      options.routeUrl?.(state.seed, state.route, state.locale),
    )!;
    try {
      options.downloadFile!(
        journeyFileName(state.seed, state.ending!, options.now?.() ?? new Date()),
        `${summary}\n`,
        "text/plain;charset=utf-8",
      );
      shareStatus = "download-success";
    } catch {
      shareStatus = "download-failure";
    }
    renderApp(
      root,
      state,
      chronicle,
      preferences,
      ambientView(),
      backupView(),
      shareStatus,
      Boolean(options.clipboard),
      Boolean(options.nativeShare),
      Boolean(options.downloadFile),
      updateAvailable,
      externalInterruption,
      options.routeUrl?.(state.seed, state.route, state.locale),
    );
    root.querySelector<HTMLButtonElement>('[data-action="download-summary"]')!.focus();
  };

  const syncAmbientControls = (): void => {
    const toggle = root.querySelector<HTMLButtonElement>('[data-action="audio"]')!;
    const ambient = ambientView();
    const mute = root.querySelector<HTMLButtonElement>('[data-action="mute"]')!;
    const volume = root.querySelector<HTMLInputElement>("[data-audio-volume]")!;
    const output = root.querySelector<HTMLOutputElement>('.ambient output')!;
    const status = root.querySelector<HTMLElement>(".ambient__status")!;
    toggle.textContent = audioToggleLabel(state, ambient);
    toggle.setAttribute("aria-pressed", String(ambient.playing));
    toggle.disabled = !ambient.available || ambient.pending;
    mute.textContent = muteLabel(state, ambient);
    mute.setAttribute("aria-pressed", String(ambient.settings.muted));
    volume.value = String(ambient.settings.volume);
    output.value = `${Math.round(ambient.settings.volume * 100)}%`;
    status.textContent = audioStatusText(state, ambient);
  };

  const toggleAmbient = async (): Promise<void> => {
    if (audioPlaying) {
      cancelAmbientOwnership();
      audioStatus = "idle";
      syncAmbientControls();
      return;
    }
    const playVersion = ++audioPlayVersion;
    try {
      audioPending = true;
      audioStatus = "idle";
      syncAmbientControls();
      if (options.prepareAmbientAudio) await options.prepareAmbientAudio();
      if (destroyed || playVersion !== audioPlayVersion) return;
      const playback = options.ambientAudio!.play();
      // Some browsers leave the media play promise pending while an offline
      // byte-range response is being decoded. Keep the control operable so the
      // player can stop immediately; a later rejection still restores failure.
      audioPlaying = true;
      audioPending = false;
      syncAmbientControls();
      await playback;
      if (destroyed || playVersion !== audioPlayVersion) return;
      audioStatus = "idle";
    } catch {
      if (destroyed || playVersion !== audioPlayVersion) return;
      audioPlaying = false;
      audioStatus = "failure";
    }
    audioPending = false;
    syncAmbientControls();
  };

  const onVisibilityChange = (): void => {
    if (!options.visibilitySource?.hidden || (!audioPlaying && !audioPending)) return;
    cancelAmbientOwnership();
    audioStatus = "paused-hidden";
    syncAmbientControls();
  };

  const toggleMute = (): void => {
    invalidatePendingBackup();
    audioSettings = { ...audioSettings, muted: !audioSettings.muted };
    options.ambientAudio!.muted = audioSettings.muted;
    saveAudioSettings(options.storage, audioSettings);
    rememberLocalData();
    syncAmbientControls();
    syncPersistenceControls();
  };

  const syncBackupControls = (): void => {
    const backup = backupView();
    const exportButton = root.querySelector<HTMLButtonElement>('[data-action="backup-export"]')!;
    const restore = root.querySelector<HTMLButtonElement>('[data-action="backup-restore"]')!;
    const clear = root.querySelector<HTMLButtonElement>('[data-action="backup-clear"]')!;
    const status = root.querySelector<HTMLElement>(".backup__status")!;
    const file = root.querySelector<HTMLInputElement>("[data-backup-file]")!;
    const fileLabel = file.closest<HTMLElement>(".backup__file")!;
    const fallback = root.querySelector<HTMLTextAreaElement>(".backup__fallback")!;
    if (!pendingBackup && backupStatus === "idle") file.value = "";
    exportButton.disabled = !backup.canExport;
    file.disabled = !backup.canImport;
    fileLabel.classList.toggle("backup__file--disabled", !backup.canImport);
    restore.disabled = !backup.ready;
    clear.disabled = !backup.canClear;
    clear.textContent = localize(
      backup.status === "confirm-clear" ? UI_COPY.backupClearConfirm : UI_COPY.backupClear,
      state.locale,
    );
    fallback.hidden = backup.manualExport === null;
    fallback.value = backup.manualExport ?? "";
    status.textContent = backupStatusText(state, backup);
  };

  const syncDurabilityControls = (): void => {
    const backup = backupView();
    const container = root.querySelector<HTMLElement>(".durability")!;
    const status = root.querySelector<HTMLElement>(".durability__status")!;
    const button = root.querySelector<HTMLButtonElement>('[data-action="protect-storage"]')!;
    container.hidden = !backup.persistent;
    status.textContent = durabilityStatusText(state, backup);
    button.hidden = backup.durability === "unsupported";
    button.disabled =
      !backup.persistent ||
      backup.durability === "checking" ||
      backup.durability === "requesting" ||
      backup.durability === "protected";
    button.textContent = localize(
      backup.durability === "requesting"
        ? UI_COPY.storageRequesting
        : backup.durability === "protected"
          ? UI_COPY.storageProtectionGranted
          : UI_COPY.storageProtect,
      state.locale,
    );
  };

  const syncPersistenceControls = (): void => {
    const backup = backupView();
    const notice = root.querySelector<HTMLElement>(".persistence-notice")!;
    const file = root.querySelector<HTMLInputElement>("[data-backup-file]")!;
    const label = file.closest<HTMLElement>(".backup__file")!;
    notice.hidden = backup.persistent;
    file.disabled = !backup.canImport;
    label.classList.toggle("backup__file--disabled", !backup.canImport);
    syncDurabilityControls();
    syncBackupControls();
  };

  const settleStorageDurability = async (request: boolean): Promise<void> => {
    durabilityStatus = request ? "requesting" : "checking";
    syncDurabilityControls();
    try {
      const isProtected = await (request
        ? options.storageDurability!.requestPersistence()
        : options.storageDurability!.isPersisted());
      if (destroyed || localDataReloadPending) return;
      durabilityStatus = isProtected ? "protected" : request ? "denied" : "best-effort";
    } catch {
      if (destroyed || localDataReloadPending) return;
      durabilityStatus = "failure";
    }
    syncDurabilityControls();
  };

  const exportBackup = (): void => {
    const backup = createLocalBackup(state, chronicle, preferences, audioSettings);
    const serialized = serializeLocalBackup(backup);
    try {
      options.downloadFile!(
        backupFileName(options.now?.() ?? new Date()),
        serialized,
        "application/json",
      );
      backupExportStatus = "success";
      manualBackupExport = null;
    } catch {
      backupExportStatus = "failure";
      manualBackupExport = serialized;
    }
    syncBackupControls();
  };

  const stageBackup = async (file: File): Promise<void> => {
    const readVersion = ++backupReadVersion;
    pendingBackup = null;
    backupStatus = "reading";
    backupExportStatus = "idle";
    manualBackupExport = null;
    syncBackupControls();
    if (file.size > MAX_BACKUP_BYTES) {
      backupStatus = "too-large";
      syncBackupControls();
      return;
    }
    try {
      const serialized = await (options.readFile ? options.readFile(file) : file.text());
      if (destroyed || readVersion !== backupReadVersion) return;
      const parsed = parseLocalBackupWithMetadata(serialized);
      pendingBackup = parsed?.backup ?? null;
      backupStatus = parsed
        ? parsed.compactedChronicle ? "ready-compacted" : "ready"
        : "invalid";
    } catch {
      if (destroyed || readVersion !== backupReadVersion) return;
      backupStatus = "invalid";
    }
    syncBackupControls();
  };

  const freezeForLocalDataReload = (): void => {
    localDataReloadPending = true;
    shareRequestVersion += 1;
    root.setAttribute("aria-busy", "true");
    for (const control of root.querySelectorAll<
      HTMLButtonElement | HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement
    >("button, input, select, textarea")) control.disabled = true;
  };

  const applyPendingBackup = (): void => {
    try {
      restoreLocalBackup(options.restoreStorage ?? options.storage, pendingBackup!);
    } catch (error) {
      backupStatus = error instanceof LocalDataMutationError && !error.rollbackComplete
        ? "restore-rollback-failed"
        : "restore-failed";
      syncBackupControls();
      return;
    }
    invalidatePendingBackup();
    cancelAmbientOwnership();
    audioStatus = "idle";
    syncAmbientControls();
    backupStatus = "restoring";
    syncBackupControls();
    freezeForLocalDataReload();
    options.reload!();
  };

  const requestClearLocalData = (): void => {
    if (backupStatus !== "confirm-clear") {
      backupStatus = "confirm-clear";
      syncBackupControls();
      return;
    }
    try {
      clearLocalData(options.restoreStorage ?? options.storage);
    } catch (error) {
      backupStatus = error instanceof LocalDataMutationError && !error.rollbackComplete
        ? "clear-rollback-failed"
        : "clear-failed";
      syncBackupControls();
      return;
    }
    invalidatePendingBackup();
    cancelAmbientOwnership();
    audioStatus = "idle";
    syncAmbientControls();
    backupStatus = "clearing";
    syncBackupControls();
    freezeForLocalDataReload();
    options.reload!();
  };

  const disarmClearLocalData = (): void => {
    if (backupStatus !== "confirm-clear") return;
    backupStatus = "idle";
    syncBackupControls();
  };

  const chooseByIndex = (index: number): void => {
    const choice = visibleChoices(state)[index]!;
    if (meetsRequirement(state.stats, choice.requirement)) {
      commit(choose(state, choice.id));
    }
  };

  const syncChronicleReplayControls = (): void => {
    for (const button of root.querySelectorAll<HTMLButtonElement>(
      '[data-action="chronicle-replay"]',
    )) {
      const index = Number(button.dataset.journeyIndex);
      const record = chronicle.journeys[index];
      if (!record) continue;
      const confirming = index === pendingJourneyReplayIndex;
      button.toggleAttribute("data-confirming", confirming);
      button.setAttribute(
        "aria-label",
        `${localize(confirming ? UI_COPY.confirmReplayRecordedJourney : UI_COPY.replayRecordedJourney, state.locale)} · ${localize(ENDINGS[record.ending].title, state.locale)} · ${localize(UI_COPY.routeSeed, state.locale)} ${record.seed}`,
      );
      button.querySelector("strong")!.textContent = localize(
        confirming ? UI_COPY.confirmLeaveJourney : ENDINGS[record.ending].title,
        state.locale,
      );
    }
    root.querySelector<HTMLElement>(".chronicle__status")!.textContent =
      pendingJourneyReplayIndex === null
        ? ""
        : localize(UI_COPY.replayReplacesJourney, state.locale);
  };

  const disarmChronicleReplay = (): void => {
    if (pendingJourneyReplayIndex === null) return;
    pendingJourneyReplayIndex = null;
    syncChronicleReplayControls();
  };

  const replayRecordedJourney = (index: number): void => {
    const record = chronicle.journeys[index];
    if (!record) return;
    if (state.phase !== "ended" && state.journal.length > 0 && pendingJourneyReplayIndex !== index) {
      pendingJourneyReplayIndex = index;
      syncChronicleReplayControls();
      root.querySelector<HTMLButtonElement>(
        `[data-action="chronicle-replay"][data-journey-index="${index}"]`,
      )!.focus();
      return;
    }
    const fresh = createGame(record.seed, state.locale);
    commit(beginGame(record.route ? { ...fresh, route: record.route } : fresh));
  };

  const onClick = (event: Event): void => {
    if (localDataReloadPending) return;
    const button = (event.target as Element).closest<HTMLButtonElement>("button");
    if (externalInterruption && button?.dataset.action !== "reload-external") return;
    if (button?.dataset.action !== "chronicle-replay") disarmChronicleReplay();
    if (button?.dataset.action !== "backup-clear") disarmClearLocalData();
    if (!button || button.disabled || button.getAttribute("aria-disabled") === "true") return;
    const action = button.dataset.action;
    const choiceId = button.dataset.choice;
    if (choiceId) {
      commit(choose(state, choiceId));
      return;
    }
    switch (action) {
      case "begin":
        commit(beginGame(state));
        break;
      case "language":
        commit(setLocale(state, state.locale === "zh" ? "en" : "zh"), '[data-action="language"]');
        break;
      case "continue":
        commit(continueJourney(state));
        break;
      case "copy":
        void copySummary();
        break;
      case "native-share":
        void shareSummary();
        break;
      case "download-summary":
        downloadSummary();
        break;
      case "apply-update":
        button.disabled = true;
        button.textContent = localize(UI_COPY.applyingUpdate, state.locale);
        options.updateController!.apply();
        break;
      case "reload-external":
        button.setAttribute("aria-disabled", "true");
        button.textContent = localize(UI_COPY.externalChangeReloadPending, state.locale);
        options.reload!();
        break;
      case "audio":
        void toggleAmbient();
        break;
      case "mute":
        toggleMute();
        break;
      case "protect-storage":
        void settleStorageDurability(true);
        break;
      case "backup-export":
        exportBackup();
        break;
      case "backup-restore":
        applyPendingBackup();
        break;
      case "backup-clear":
        requestClearLocalData();
        break;
      case "chronicle-replay":
        replayRecordedJourney(Number(button.dataset.journeyIndex));
        break;
      case "replay":
        commit(restartGame(state));
        break;
      case "new":
        commit(createNextJourney(state));
        break;
    }
  };

  const onKeyDown = (event: KeyboardEvent): void => {
    if (localDataReloadPending) return;
    const modified = event.ctrlKey || event.metaKey || event.altKey;
    if (externalInterruption) {
      if (event.key === "Tab" && !modified) {
        event.preventDefault();
        root.querySelector<HTMLButtonElement>('[data-action="reload-external"]')?.focus();
      }
      return;
    }
    if (modified) return;
    const target = event.target;
    if (
      target instanceof Element &&
      target.closest("input, textarea, select, [contenteditable='true']")
    ) return;
    const activeElement = root.ownerDocument.activeElement;
    if (!(activeElement instanceof Element) || !root.querySelector(".story")?.contains(activeElement)) {
      return;
    }
    const key = event.key.toLowerCase();
    if (state.phase === "playing" && (key === "1" || key === "2")) {
      event.preventDefault();
      chooseByIndex(Number(key) - 1);
    } else if (key === "l") {
      commit(setLocale(state, state.locale === "zh" ? "en" : "zh"));
    } else if (key === "enter" && state.phase === "reflection") {
      commit(continueJourney(state));
    } else if (key === "r" && state.phase === "ended") {
      commit(restartGame(state));
    }
  };

  const onChange = (event: Event): void => {
    if (localDataReloadPending || externalInterruption) return;
    disarmClearLocalData();
    disarmChronicleReplay();
    const input = event.target as HTMLInputElement;
    if (input.matches("[data-backup-file]")) {
      const file = input.files?.[0];
      if (file) {
        void stageBackup(file);
      } else {
        backupReadVersion += 1;
        pendingBackup = null;
        backupStatus = "idle";
        syncBackupControls();
      }
      return;
    }
    if (!input.checked || !input.dataset.preference) return;
    const nextPreferences = updatePreference(preferences, input.dataset.preference, input.value);
    if (nextPreferences === preferences) return;
    invalidatePendingBackup();
    preferences = nextPreferences;
    savePreferences(options.storage, preferences);
    rememberLocalData();
    root.dataset.textScale = preferences.textScale;
    root.dataset.motion = preferences.motion;
    root.dataset.contrast = preferences.contrast;
    syncPersistenceControls();
  };

  const onInput = (event: Event): void => {
    if (localDataReloadPending || externalInterruption) return;
    disarmClearLocalData();
    disarmChronicleReplay();
    const input = (event.target as Element).closest<HTMLInputElement>("[data-audio-volume]");
    if (!input || !options.ambientAudio) return;
    invalidatePendingBackup();
    audioSettings = { ...audioSettings, volume: normalizeVolume(Number(input.value)) };
    options.ambientAudio.volume = audioSettings.volume;
    saveAudioSettings(options.storage, audioSettings);
    rememberLocalData();
    syncAmbientControls();
    syncPersistenceControls();
  };

  root.addEventListener("click", onClick);
  root.addEventListener("change", onChange);
  root.addEventListener("input", onInput);
  keyboardTarget.addEventListener("keydown", onKeyDown);
  options.visibilitySource?.addEventListener("visibilitychange", onVisibilityChange);
  renderApp(
    root,
    state,
    chronicle,
    preferences,
    ambientView(),
    backupView(),
    shareStatus,
    Boolean(options.clipboard),
    Boolean(options.nativeShare),
    Boolean(options.downloadFile),
    updateAvailable,
    externalInterruption,
    options.routeUrl?.(state.seed, state.route, state.locale),
  );
  if (options.storageDurability) void settleStorageDurability(false);

  const localDataKeys = new Set<string>(LOCAL_DATA_KEYS);
  const showExternalInterruption = (interruption: Exclude<ExternalInterruption, null>): void => {
    if (localDataReloadPending || externalInterruption === "data") return;
    if (externalInterruption === "update" && interruption === "update") return;
    externalInterruption = interruption;
    shareRequestVersion += 1;
    invalidatePendingBackup();
    cancelAmbientOwnership();
    audioStatus = "idle";
    renderApp(
      root,
      state,
      chronicle,
      preferences,
      ambientView(),
      backupView(),
      shareStatus,
      Boolean(options.clipboard),
      Boolean(options.nativeShare),
      Boolean(options.downloadFile),
      updateAvailable,
      externalInterruption,
      options.routeUrl?.(state.seed, state.route, state.locale),
    );
    root.querySelector<HTMLButtonElement>('[data-action="reload-external"]')!.focus();
  };
  const showExternalDataChange = (): void => showExternalInterruption("data");
  const onStorage = (event: StorageEvent): void => {
    if (!isStoragePersistent()) return;
    if (
      event.storageArea !== null &&
      options.restoreStorage !== undefined &&
      event.storageArea !== options.restoreStorage
    ) return;
    if (event.key !== null && !localDataKeys.has(event.key)) return;
    showExternalDataChange();
  };
  const onPageShow = (event: Event): void => {
    if (!(event as PageTransitionEvent).persisted || !isStoragePersistent()) return;
    if (localDataSignature() === ownedLocalDataSignature) return;
    showExternalDataChange();
  };
  options.storageEventTarget?.addEventListener("storage", onStorage);
  options.pageLifecycleSource?.addEventListener("pageshow", onPageShow);
  const unsubscribeUpdate = options.updateController?.subscribe(() => {
    updateAvailable = true;
    root.querySelector<HTMLElement>(".update-notice")!.hidden = false;
  });
  const unsubscribeExternalActivation = options.updateController
    ?.subscribeExternalActivation(() => showExternalInterruption("update"));

  return {
    getState: () => state,
    getChronicle: () => chronicle,
    getPreferences: () => preferences,
    getAudioSettings: () => audioSettings,
    isAmbientPlaying: () => audioPlaying,
    destroy: () => {
      destroyed = true;
      cancelAmbientOwnership();
      root.removeEventListener("click", onClick);
      root.removeEventListener("change", onChange);
      root.removeEventListener("input", onInput);
      keyboardTarget.removeEventListener("keydown", onKeyDown);
      options.visibilitySource?.removeEventListener("visibilitychange", onVisibilityChange);
      options.storageEventTarget?.removeEventListener("storage", onStorage);
      options.pageLifecycleSource?.removeEventListener("pageshow", onPageShow);
      unsubscribeUpdate?.();
      unsubscribeExternalActivation?.();
      root.replaceChildren();
    },
  };
};
