import { describe, expect, it, vi } from "vitest";
import { AUDIO_SETTINGS_KEY, DEFAULT_AUDIO_SETTINGS } from "../game/audio-settings";
import {
  createLocalBackup,
  MAX_BACKUP_BYTES,
  parseLocalBackup,
  serializeLocalBackup,
} from "../game/backup";
import {
  CHRONICLE_KEY,
  EMPTY_CHRONICLE,
  MAX_CHRONICLE_JOURNEYS,
  recordJourney,
  saveChronicle,
} from "../game/chronicle";
import { beginGame, choose, continueJourney, createGame, visibleChoices } from "../game/engine";
import { DEFAULT_PREFERENCES, PREFERENCES_KEY } from "../game/preferences";
import { loadGame, SAVE_KEY, saveGame, type StorageLike } from "../game/storage";
import type { GameState } from "../game/types";
import {
  localeFromSearch,
  mountGame,
  routeFromSearch,
  seedFromSearch,
  type AmbientAudio,
  type PageLifecycleSource,
  type VisibilitySource,
} from "./app";

const memoryStorage = (): StorageLike => {
  const data = new Map<string, string>();
  return {
    getItem: (key) => data.get(key) ?? null,
    setItem: (key, value) => data.set(key, value),
    removeItem: (key) => data.delete(key),
  };
};

const rootElement = (): HTMLElement => {
  const root = document.createElement("div");
  document.body.append(root);
  return root;
};

const click = (root: HTMLElement, selector: string): void => {
  root.querySelector<HTMLButtonElement>(selector)!.click();
};

const OPERABLE_CHOICE_SELECTOR =
  '[data-choice]:not(:disabled):not([aria-disabled="true"])';

const selectPreference = (root: HTMLElement, key: string, value: string): void => {
  const input = root.querySelector<HTMLInputElement>(
    `[data-preference="${key}"][value="${value}"]`,
  )!;
  input.checked = true;
  input.dispatchEvent(new Event("change", { bubbles: true }));
};

const selectBackupFile = (root: HTMLElement, file?: File): void => {
  const input = root.querySelector<HTMLInputElement>("[data-backup-file]")!;
  Object.defineProperty(input, "files", {
    configurable: true,
    value: file ? [file] : [],
  });
  input.dispatchEvent(new Event("change", { bubbles: true }));
};

const fakeAudio = (play: () => Promise<void> = vi.fn().mockResolvedValue(undefined)) => ({
  play: vi.fn(play),
  pause: vi.fn(),
  volume: 0,
  muted: false,
  loop: false,
}) satisfies AmbientAudio;

const fakeVisibility = (): {
  readonly source: VisibilitySource;
  setHidden(value: boolean): void;
} => {
  const target = new EventTarget();
  let hidden = false;
  return {
    source: {
      get hidden() { return hidden; },
      addEventListener: (_type, listener) => target.addEventListener("visibilitychange", listener),
      removeEventListener: (_type, listener) => target.removeEventListener("visibilitychange", listener),
    },
    setHidden: (value) => {
      hidden = value;
      target.dispatchEvent(new Event("visibilitychange"));
    },
  };
};

const fakePageLifecycle = (): {
  readonly source: PageLifecycleSource;
  show(persisted: boolean): void;
} => {
  const target = new EventTarget();
  return {
    source: {
      addEventListener: (_type, listener) => target.addEventListener("pageshow", listener),
      removeEventListener: (_type, listener) => target.removeEventListener("pageshow", listener),
    },
    show: (persisted) => {
      const event = new Event("pageshow");
      Object.defineProperty(event, "persisted", { value: persisted });
      target.dispatchEvent(event);
    },
  };
};

const endedState = (): GameState => {
  let state = beginGame(createGame(4242));
  while (state.phase !== "ended") {
    state =
      state.phase === "playing"
        ? choose(state, visibleChoices(state)[0]!.id)
        : continueJourney(state);
  }
  return state;
};

describe("seed parsing", () => {
  it("uses a query seed or normalized fallback", () => {
    expect(seedFromSearch("?seed=0025", 9)).toBe(25);
    expect(seedFromSearch("", -9)).toBe(9);
    expect(seedFromSearch("?seed=nope", 7)).toBe(1);
  });

  it("accepts only the supported route-link language", () => {
    expect(localeFromSearch("?lang=en")).toBe("en");
    expect(localeFromSearch("")).toBe("zh");
    expect(localeFromSearch("?lang=fr")).toBe("zh");
  });

  it("accepts only a complete region-ordered shared route", () => {
    const route = createGame(4242).route;
    expect(routeFromSearch(`?route=${route.join(",")}`)).toEqual(route);
    expect(routeFromSearch("")).toBeUndefined();
    expect(routeFromSearch("?route=ferry-rope")).toBeUndefined();
    expect(routeFromSearch(`?route=${[...route].reverse().join(",")}`)).toBeUndefined();
    expect(routeFromSearch(`?route=unknown,${route.slice(1).join(",")}`)).toBeUndefined();
  });
});

describe("browser application", () => {
  it("blocks stale-tab writes and ambience until newer local data is reloaded", async () => {
    let resolveCopy!: () => void;
    const storage = memoryStorage();
    saveGame(storage, endedState());
    const root = rootElement();
    const reload = vi.fn();
    const audio = fakeAudio();
    const game = mountGame(root, {
      storage,
      seed: 4242,
      reload,
      ambientAudio: audio,
      clipboard: {
        writeText: vi.fn(() => new Promise<void>((resolve) => {
          resolveCopy = resolve;
        })),
      },
      storageEventTarget: window,
      restoreStorage: storage,
    });

    click(root, '[data-action="audio"]');
    await vi.waitFor(() => expect(game.isAmbientPlaying()).toBe(true));
    click(root, '[data-action="copy"]');

    window.dispatchEvent(new StorageEvent("storage", { key: "unrelated" }));
    expect(root.querySelector<HTMLElement>(".storage-conflict-backdrop")?.hidden).toBe(true);

    const sessionEvent = new StorageEvent("storage", {
      key: SAVE_KEY,
      newValue: "unrelated session value",
    });
    Object.defineProperty(sessionEvent, "storageArea", { value: memoryStorage() });
    window.dispatchEvent(sessionEvent);
    expect(root.querySelector<HTMLElement>(".storage-conflict-backdrop")?.hidden).toBe(true);

    const localEvent = new StorageEvent("storage", {
      key: SAVE_KEY,
      newValue: "newer",
    });
    Object.defineProperty(localEvent, "storageArea", { value: storage });
    window.dispatchEvent(localEvent);
    const reloadButton = root.querySelector<HTMLButtonElement>('[data-action="reload-external"]')!;
    expect(root.querySelector('[role="alertdialog"]')?.textContent).toContain("另一页已更新");
    expect(root.querySelector(".game-shell__session")?.hasAttribute("inert")).toBe(true);
    expect(document.activeElement).toBe(reloadButton);
    expect(game.isAmbientPlaying()).toBe(false);
    expect(audio.pause).toHaveBeenCalledOnce();
    expect(root.querySelector('[data-action="audio"]')?.getAttribute("aria-pressed")).toBe("false");

    for (const event of [
      new KeyboardEvent("keydown", { key: "Tab", bubbles: true, cancelable: true }),
      new KeyboardEvent("keydown", { key: "Tab", shiftKey: true, bubbles: true, cancelable: true }),
    ]) {
      reloadButton.dispatchEvent(event);
      expect(event.defaultPrevented).toBe(true);
      expect(document.activeElement).toBe(reloadButton);
    }
    const modifiedTab = new KeyboardEvent("keydown", {
      key: "Tab",
      ctrlKey: true,
      bubbles: true,
      cancelable: true,
    });
    reloadButton.dispatchEvent(modifiedTab);
    expect(modifiedTab.defaultPrevented).toBe(false);
    reloadButton.dispatchEvent(new KeyboardEvent("keydown", { key: "l", bubbles: true }));
    expect(document.documentElement.lang).toBe("zh-CN");

    resolveCopy();
    await Promise.resolve();
    expect(root.querySelector('[data-action="reload-external"]')).toBe(reloadButton);
    expect(document.activeElement).toBe(reloadButton);
    expect(root.querySelector(".share__status")?.textContent).toBe("");

    window.dispatchEvent(new StorageEvent("storage", { key: CHRONICLE_KEY, newValue: "newer" }));
    expect(root.querySelector('[data-action="reload-external"]')).toBe(reloadButton);
    reloadButton.click();
    expect(reloadButton.disabled).toBe(false);
    expect(reloadButton.getAttribute("aria-disabled")).toBe("true");
    expect(reloadButton.textContent).toContain("正在重新载入");
    expect(reload).toHaveBeenCalledOnce();
    reloadButton.click();
    expect(reload).toHaveBeenCalledOnce();
    const pendingTab = new KeyboardEvent("keydown", {
      key: "Tab",
      bubbles: true,
      cancelable: true,
    });
    reloadButton.dispatchEvent(pendingTab);
    expect(pendingTab.defaultPrevented).toBe(true);
    expect(document.activeElement).toBe(reloadButton);

    game.destroy();
    window.dispatchEvent(new StorageEvent("storage", { key: null }));
    expect(root.childElementCount).toBe(0);

    const clearedRoot = rootElement();
    const clearedGame = mountGame(clearedRoot, {
      storage: memoryStorage(),
      seed: 4242,
      reload: vi.fn(),
      storageEventTarget: window,
    });
    window.dispatchEvent(new StorageEvent("storage", { key: null }));
    expect(clearedRoot.querySelector('[role="alertdialog"]')).not.toBeNull();
    clearedGame.destroy();

    const memoryOnlyRoot = rootElement();
    const memoryOnlyGame = mountGame(memoryOnlyRoot, {
      storage: memoryStorage(),
      isStoragePersistent: () => false,
      seed: 4242,
      reload: vi.fn(),
      storageEventTarget: window,
    });
    window.dispatchEvent(new StorageEvent("storage", { key: SAVE_KEY, newValue: "newer" }));
    expect(memoryOnlyRoot.querySelector<HTMLElement>(".storage-conflict-backdrop")?.hidden)
      .toBe(true);
    memoryOnlyGame.destroy();
  });

  it("rechecks owned local records when a cached page is restored", () => {
    const storage = memoryStorage();
    const lifecycle = fakePageLifecycle();
    const root = rootElement();
    const game = mountGame(root, {
      storage,
      seed: 4242,
      reload: vi.fn(),
      pageLifecycleSource: lifecycle.source,
    });

    lifecycle.show(false);
    expect(root.querySelector<HTMLElement>(".storage-conflict-backdrop")?.hidden).toBe(true);
    click(root, '[data-action="begin"]');
    lifecycle.show(true);
    expect(root.querySelector<HTMLElement>(".storage-conflict-backdrop")?.hidden).toBe(true);

    saveGame(storage, createGame(77));
    lifecycle.show(true);
    const reloadButton = root.querySelector<HTMLButtonElement>('[data-action="reload-external"]')!;
    expect(root.querySelector('[role="alertdialog"]')?.textContent).toContain("另一页已更新");
    expect(document.activeElement).toBe(reloadButton);
    lifecycle.show(true);
    expect(root.querySelector('[data-action="reload-external"]')).toBe(reloadButton);

    game.destroy();
    lifecycle.show(true);
    expect(root.childElementCount).toBe(0);

    const memoryStorageState = memoryStorage();
    const memoryLifecycle = fakePageLifecycle();
    const memoryRoot = rootElement();
    const memoryGame = mountGame(memoryRoot, {
      storage: memoryStorageState,
      isStoragePersistent: () => false,
      seed: 4242,
      pageLifecycleSource: memoryLifecycle.source,
    });
    saveGame(memoryStorageState, createGame(77));
    memoryLifecycle.show(true);
    expect(memoryRoot.querySelector<HTMLElement>(".storage-conflict-backdrop")?.hidden).toBe(true);
    memoryGame.destroy();
  });

  it("announces and applies a ready offline update without stealing focus", () => {
    let announceUpdate!: () => void;
    const apply = vi.fn();
    const unsubscribe = vi.fn();
    const root = rootElement();
    const game = mountGame(root, {
      storage: memoryStorage(),
      seed: 4242,
      updateController: {
        apply,
        attach: vi.fn(),
        subscribeExternalActivation: () => vi.fn(),
        subscribe: (listener) => {
          announceUpdate = listener;
          return unsubscribe;
        },
      },
    });
    const begin = root.querySelector<HTMLButtonElement>('[data-action="begin"]')!;
    begin.focus();
    expect(root.querySelector<HTMLElement>(".update-notice")?.hidden).toBe(true);

    announceUpdate();
    expect(root.querySelector<HTMLElement>(".update-notice")?.hidden).toBe(false);
    expect(root.querySelector(".update-notice")?.textContent).toContain("新版本已离线备妥");
    expect(document.activeElement).toBe(begin);

    click(root, '[data-action="language"]');
    expect(root.querySelector(".update-notice")?.textContent).toContain("newer version is ready");
    const update = root.querySelector<HTMLButtonElement>('[data-action="apply-update"]')!;
    update.click();
    expect(update.disabled).toBe(true);
    expect(update.textContent).toBe("Updating…");
    expect(apply).toHaveBeenCalledOnce();

    game.destroy();
    expect(unsubscribe).toHaveBeenCalledOnce();
  });

  it("freezes an old controlled tab when another tab activates an update", () => {
    const mount = (persistent: boolean) => {
      let announceExternalActivation!: () => void;
      const unsubscribe = vi.fn();
      const reload = vi.fn();
      const root = rootElement();
      const game = mountGame(root, {
        storage: memoryStorage(),
        seed: 4242,
        reload,
        isStoragePersistent: () => persistent,
        updateController: {
          apply: vi.fn(),
          attach: vi.fn(),
          subscribe: () => vi.fn(),
          subscribeExternalActivation: (listener) => {
            announceExternalActivation = listener;
            return unsubscribe;
          },
        },
      });
      return { announceExternalActivation, game, reload, root, unsubscribe };
    };

    const persistent = mount(true);
    persistent.announceExternalActivation();
    const reloadButton = persistent.root.querySelector<HTMLButtonElement>(
      '[data-action="reload-external"]',
    )!;
    expect(persistent.root.querySelector('[role="alertdialog"]')?.textContent)
      .toContain("另一页已启用新版本");
    expect(persistent.root.querySelector('[role="alertdialog"]')?.textContent)
      .not.toContain("重置本次旅程");
    expect(persistent.root.querySelector(".game-shell__session")?.hasAttribute("inert")).toBe(true);
    expect(document.activeElement).toBe(reloadButton);
    persistent.announceExternalActivation();
    expect(persistent.root.querySelector('[data-action="reload-external"]')).toBe(reloadButton);
    click(persistent.root, '[data-action="begin"]');
    expect(persistent.game.getState().phase).toBe("intro");
    reloadButton.click();
    expect(persistent.reload).toHaveBeenCalledOnce();
    persistent.game.destroy();
    expect(persistent.unsubscribe).toHaveBeenCalledOnce();

    const memoryOnly = mount(false);
    memoryOnly.announceExternalActivation();
    expect(memoryOnly.root.querySelector('[role="alertdialog"]')?.textContent)
      .toContain("重新载入会重置本次旅程");
    memoryOnly.game.destroy();
  });

  it("starts a requested shared route instead of an existing save", () => {
    const storage = memoryStorage();
    saveGame(storage, endedState());
    const root = rootElement();
    const exactRoute = createGame(4242).route;
    const onJourneyLinkChange = vi.fn();
    const game = mountGame(root, {
      storage,
      seed: 25,
      forceNew: true,
      initialRoute: exactRoute,
      initialLocale: "en",
      onJourneyLinkChange,
    });
    expect(game.getState().phase).toBe("intro");
    expect(game.getState().seed).toBe(25);
    expect(game.getState().route).toEqual(exactRoute);
    expect(game.getState().locale).toBe("en");
    expect(loadGame(storage)).toEqual(game.getState());
    expect(onJourneyLinkChange).toHaveBeenCalledWith(25, exactRoute, "en");
  });

  it("keeps the journey playable and disables restore without persistent storage", () => {
    const root = rootElement();
    const downloadFile = vi.fn();
    let announceUpdate!: () => void;
    const game = mountGame(root, {
      storage: memoryStorage(),
      seed: 4242,
      downloadFile,
      reload: vi.fn(),
      isStoragePersistent: () => false,
      updateController: {
        apply: vi.fn(),
        attach: vi.fn(),
        subscribeExternalActivation: () => vi.fn(),
        subscribe: (listener) => {
          announceUpdate = listener;
          return vi.fn();
        },
      },
    });
    expect(root.querySelector<HTMLElement>(".persistence-notice")?.hidden).toBe(false);
    expect(root.querySelector(".persistence-notice")?.textContent).toContain("刷新后不会保留");
    expect(root.querySelector<HTMLInputElement>("[data-backup-file]")?.disabled).toBe(true);
    expect(root.querySelector(".backup__status")?.textContent).toContain("无法恢复备份");
    announceUpdate();
    expect(root.querySelector(".update-notice")?.textContent).toContain("重新载入会重置本次旅程");

    click(root, '[data-action="begin"]');
    click(root, OPERABLE_CHOICE_SELECTOR);
    expect(game.getState().phase).toBe("reflection");
    click(root, '[data-action="backup-export"]');
    expect(downloadFile).toHaveBeenCalledOnce();
  });

  it("checks durability silently and requests protection only from a player action", async () => {
    let resolveRequest!: (value: boolean) => void;
    const isPersisted = vi.fn().mockResolvedValue(false);
    const requestPersistence = vi.fn(
      () => new Promise<boolean>((resolve) => { resolveRequest = resolve; }),
    );
    const root = rootElement();
    mountGame(root, {
      storage: memoryStorage(),
      seed: 4242,
      storageDurability: { isPersisted, requestPersistence },
    });

    await vi.waitFor(() =>
      expect(root.querySelector(".durability__status")?.textContent).toContain("自动清除"),
    );
    expect(isPersisted).toHaveBeenCalledOnce();
    expect(requestPersistence).not.toHaveBeenCalled();
    const button = root.querySelector<HTMLButtonElement>('[data-action="protect-storage"]')!;
    button.focus();
    button.click();
    expect(button.disabled).toBe(true);
    expect(button.textContent).toContain("正在请求");

    resolveRequest(true);
    await vi.waitFor(() =>
      expect(root.querySelector(".durability__status")?.textContent).toContain("已防止"),
    );
    expect(button.textContent).toContain("已获浏览器保护");
    expect(button.disabled).toBe(true);
    expect(document.activeElement).toBe(button);
  });

  it("reports protected, denied, unsupported, and failed durability states", async () => {
    const protectedRoot = rootElement();
    const protectedRequest = vi.fn().mockResolvedValue(true);
    mountGame(protectedRoot, {
      storage: memoryStorage(),
      seed: 1,
      storageDurability: {
        isPersisted: vi.fn().mockResolvedValue(true),
        requestPersistence: protectedRequest,
      },
    });
    await vi.waitFor(() =>
      expect(protectedRoot.querySelector(".durability__status")?.textContent).toContain("已防止"),
    );
    expect(protectedRequest).not.toHaveBeenCalled();

    const failedRoot = rootElement();
    const requestPersistence = vi.fn()
      .mockResolvedValueOnce(false)
      .mockRejectedValueOnce(new Error("permission unavailable"));
    mountGame(failedRoot, {
      storage: memoryStorage(),
      seed: 2,
      storageDurability: {
        isPersisted: vi.fn().mockRejectedValue(new Error("status unavailable")),
        requestPersistence,
      },
    });
    await vi.waitFor(() =>
      expect(failedRoot.querySelector(".durability__status")?.textContent).toContain("无法检查"),
    );
    click(failedRoot, '[data-action="protect-storage"]');
    await vi.waitFor(() =>
      expect(failedRoot.querySelector(".durability__status")?.textContent).toContain("未授予"),
    );
    click(failedRoot, '[data-action="protect-storage"]');
    await vi.waitFor(() =>
      expect(failedRoot.querySelector(".durability__status")?.textContent).toContain("无法检查"),
    );

    const unsupportedRoot = rootElement();
    mountGame(unsupportedRoot, { storage: memoryStorage(), seed: 3 });
    expect(unsupportedRoot.querySelector(".durability__status")?.textContent).toContain("不报告");
    expect(unsupportedRoot.querySelector<HTMLButtonElement>('[data-action="protect-storage"]')?.hidden)
      .toBe(true);

    let resolveCheck!: (value: boolean) => void;
    const teardownRoot = rootElement();
    const teardown = mountGame(teardownRoot, {
      storage: memoryStorage(),
      seed: 4,
      storageDurability: {
        isPersisted: () => new Promise<boolean>((resolve) => { resolveCheck = resolve; }),
        requestPersistence: vi.fn(),
      },
    });
    teardown.destroy();
    resolveCheck(true);
    await Promise.resolve();
    expect(teardownRoot.childElementCount).toBe(0);
  });

  it("keeps durability state coherent across language renders and rejected teardown", async () => {
    let resolveRequest!: (value: boolean) => void;
    const rerenderRoot = rootElement();
    mountGame(rerenderRoot, {
      storage: memoryStorage(),
      seed: 5,
      storageDurability: {
        isPersisted: vi.fn().mockResolvedValue(false),
        requestPersistence: () => new Promise<boolean>((resolve) => { resolveRequest = resolve; }),
      },
    });
    await vi.waitFor(() =>
      expect(rerenderRoot.querySelector(".durability__status")?.textContent).toContain("自动清除"),
    );
    click(rerenderRoot, '[data-action="language"]');
    expect(rerenderRoot.querySelector(".durability__status")?.textContent)
      .toContain("storage pressure");
    click(rerenderRoot, '[data-action="protect-storage"]');
    click(rerenderRoot, '[data-action="language"]');
    expect(rerenderRoot.querySelector('[data-action="protect-storage"]')?.textContent)
      .toContain("正在请求");
    resolveRequest(true);
    await vi.waitFor(() =>
      expect(rerenderRoot.querySelector(".durability__status")?.textContent).toContain("已防止"),
    );
    click(rerenderRoot, '[data-action="language"]');
    expect(rerenderRoot.querySelector('[data-action="protect-storage"]')?.textContent)
      .toContain("Browser protection granted");

    let rejectRequest!: (reason: Error) => void;
    const teardownRoot = rootElement();
    const teardown = mountGame(teardownRoot, {
      storage: memoryStorage(),
      seed: 6,
      storageDurability: {
        isPersisted: vi.fn().mockResolvedValue(false),
        requestPersistence: () => new Promise<boolean>((_resolve, reject) => {
          rejectRequest = reject;
        }),
      },
    });
    await vi.waitFor(() =>
      expect(teardownRoot.querySelector(".durability__status")?.textContent).toContain("自动清除"),
    );
    click(teardownRoot, '[data-action="protect-storage"]');
    teardown.destroy();
    rejectRequest(new Error("permission closed"));
    await Promise.resolve();
    expect(teardownRoot.childElementCount).toBe(0);
  });

  it("renders persisted narrative strings as inert text", () => {
    const storage = memoryStorage();
    const raw = `<img data-injection src=x onerror="globalThis.injected=true"> & "quoted" 'text'`;
    const ended = endedState();
    const first = ended.journal[0]!;
    saveGame(storage, {
      ...ended,
      journal: [
        {
          ...first,
          place: { zh: raw, en: raw },
          choice: { zh: raw, en: raw },
          aftermath: { zh: raw, en: raw },
        },
        ...ended.journal.slice(1),
      ],
    });
    const root = rootElement();
    mountGame(root, { storage, seed: 9 });

    expect(root.querySelector("[data-injection]")).toBeNull();
    expect(root.querySelector(".journal")?.textContent).toContain(raw);
    expect(root.querySelector<HTMLTextAreaElement>(".share textarea")?.value).toContain(raw);
  });

  it("starts, changes language, and resolves a choice", () => {
    const description = document.createElement("meta");
    description.name = "description";
    document.head.append(description);
    const root = rootElement();
    const game = mountGame(root, { storage: memoryStorage(), seed: 4242 });
    expect(root.dataset.phase).toBe("intro");
    expect(root.dataset.progress).toBe("0");
    expect(root.hasAttribute("style")).toBe(false);
    expect(root.querySelector(".landscape__image")?.getAttribute("src"))
      .toBe("./assets/journey-scroll.jpg");
    expect(root.textContent).toContain("你带来的");
    expect(root.querySelector(".chronicle summary")?.textContent).toContain("0/4");
    expect(root.querySelector('[data-action="language"]')?.getAttribute("lang")).toBe("en");
    expect(root.querySelector('[data-action="language"]')?.getAttribute("aria-label"))
      .toBe("Switch to English");
    click(root, '[data-action="language"]');
    expect(root.textContent).toContain("Did you carry");
    expect(root.querySelector('[data-action="language"]')?.getAttribute("lang")).toBe("zh-CN");
    expect(root.querySelector('[data-action="language"]')?.getAttribute("aria-label"))
      .toBe("切换到中文");
    expect(document.title).toBe("Covenant of the Road · Mountains & Rivers");
    expect(description.content).toBe(
      "A journey through mountains and rivers, written by your choices.",
    );
    expect(document.activeElement).toBe(root.querySelector('[data-action="language"]'));
    click(root, '[data-action="language"]');
    expect(root.textContent).toContain("你带来的");
    expect(document.title).toBe("行旅之契 · 山河有契");
    click(root, '[data-action="begin"]');
    expect(root.dataset.phase).toBe("playing");
    expect(document.activeElement).toBe(root.querySelector(".story h1"));
    expect(root.querySelector(".story")?.hasAttribute("aria-live")).toBe(false);
    expect(root.querySelector('[data-choice="mend-rope"]')?.getAttribute("aria-keyshortcuts"))
      .toBe("1");
    click(root, OPERABLE_CHOICE_SELECTOR);
    expect(game.getState().sceneIndex).toBe(1);
    expect(game.getState().phase).toBe("reflection");
    expect(root.getAttribute("data-phase")).toBe("reflection");
    expect(root.dataset.progress).toBe("1");
    expect(root.textContent).toContain("1/5");
    expect(root.querySelector(".story")?.hasAttribute("aria-live")).toBe(false);
    click(root, '[data-action="continue"]');
    expect(game.getState().phase).toBe("playing");
    description.remove();
  });

  it("supports numeric shortcuts and ignores modified shortcuts", () => {
    const root = rootElement();
    const game = mountGame(root, { storage: memoryStorage(), seed: 4242 });
    click(root, '[data-action="begin"]');
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "1", altKey: true }));
    expect(game.getState().sceneIndex).toBe(0);
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "1" }));
    expect(game.getState().sceneIndex).toBe(1);
    expect(game.getState().phase).toBe("reflection");
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter" }));
    expect(game.getState().phase).toBe("playing");
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "l" }));
    expect(game.getState().locale).toBe("en");
    root.dispatchEvent(new KeyboardEvent("keydown", { key: "l", bubbles: true }));
    expect(game.getState().locale).toBe("zh");
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "x" }));
    expect(game.getState().sceneIndex).toBe(1);
  });

  it("keeps a locked choice focusable without allowing pointer or numeric activation", () => {
    const storage = memoryStorage();
    let state = beginGame(createGame(2));
    state = choose(state, visibleChoices(state)[1]!.id);
    state = continueJourney(state);
    state = choose(state, visibleChoices(state)[1]!.id);
    state = continueJourney(state);
    saveGame(storage, state);
    const root = rootElement();
    const game = mountGame(root, { storage, seed: 2 });
    const locked = root.querySelector<HTMLButtonElement>('[data-choice="raise-marker"]')!;
    expect(locked.disabled).toBe(false);
    expect(locked.getAttribute("aria-disabled")).toBe("true");
    locked.focus();
    expect(document.activeElement).toBe(locked);
    locked.click();
    expect(game.getState().sceneIndex).toBe(2);
    root.querySelector<HTMLElement>(".story h1")!.focus();
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "1" }));
    expect(game.getState().sceneIndex).toBe(2);
  });

  it("loads an ending, replays, starts a new route, and handles R", () => {
    const storage = memoryStorage();
    saveGame(storage, endedState());
    const root = rootElement();
    const onRouteChange = vi.fn();
    const game = mountGame(root, { storage, seed: 1, onJourneyLinkChange: onRouteChange });
    expect(root.querySelector("[data-ending='covenant']")).not.toBeNull();
    expect(root.querySelector<HTMLTextAreaElement>(".share textarea")?.value).toContain("旅签：4242");
    expect(root.querySelector<HTMLButtonElement>('[data-action="copy"]')?.disabled).toBe(true);
    expect(root.querySelector(".share__status")?.textContent).toContain("手动复制");
    expect(game.getChronicle().journeys).toHaveLength(1);
    expect(root.querySelector(".chronicle")?.textContent).toContain("山河有应");
    click(root, '[data-action="replay"]');
    expect(game.getState().phase).toBe("playing");
    expect(onRouteChange).toHaveBeenCalledTimes(1);

    saveGame(storage, endedState());
    game.destroy();
    const secondRouteChange = vi.fn();
    const second = mountGame(root, {
      storage,
      seed: 1,
      onJourneyLinkChange: secondRouteChange,
    });
    expect(second.getChronicle().journeys).toHaveLength(1);
    const oldSeed = second.getState().seed;
    click(root, '[data-action="new"]');
    expect(second.getState().seed).not.toBe(oldSeed);
    expect(second.getState().phase).toBe("intro");
    expect(secondRouteChange).toHaveBeenCalledWith(
      second.getState().seed,
      second.getState().route,
      second.getState().locale,
    );
    expect(secondRouteChange).toHaveBeenCalledTimes(2);

    second.destroy();
    saveGame(storage, endedState());
    const third = mountGame(root, { storage, seed: 1 });
    root.querySelector("textarea")!.dispatchEvent(
      new KeyboardEvent("keydown", { key: "r", bubbles: true }),
    );
    expect(third.getState().phase).toBe("ended");
    root.querySelector<HTMLButtonElement>('[data-action="language"]')!.focus();
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "r" }));
    expect(third.getState().phase).toBe("ended");
    root.querySelector<HTMLElement>(".story h1")!.focus();
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "r" }));
    expect(third.getState().phase).toBe("playing");
  });

  it("replays exact recent routes and falls back for legacy seed-only records", () => {
    const ended = endedState();
    const storage = memoryStorage();
    saveGame(storage, ended);
    const root = rootElement();
    const game = mountGame(root, { storage, seed: 1 });
    const recent = root.querySelector<HTMLButtonElement>('[data-action="chronicle-replay"]')!;
    expect(recent.textContent).toContain("旅签 4242");
    expect(recent.textContent).toContain("盘缠 1");
    click(root, '[data-action="chronicle-replay"]');
    expect(game.getState()).toMatchObject({ phase: "playing", seed: 4242 });
    expect(game.getState().route).toEqual(ended.route);
    expect(game.getChronicle().journeys).toHaveLength(1);

    game.destroy();
    const legacyStorage = memoryStorage();
    const record = recordJourney(EMPTY_CHRONICLE, ended).journeys[0]!;
    const { route: _route, ...legacyRecord } = record;
    saveChronicle(legacyStorage, { version: 1, journeys: [legacyRecord] });
    const legacyRoot = rootElement();
    const legacy = mountGame(legacyRoot, { storage: legacyStorage, seed: 9 });
    const legacyButton = legacyRoot.querySelector<HTMLButtonElement>(
      '[data-action="chronicle-replay"]',
    )!;
    legacyButton.dataset.journeyIndex = "99";
    legacyButton.click();
    expect(legacy.getState().phase).toBe("intro");
    legacyButton.dataset.journeyIndex = "0";
    legacyButton.click();
    expect(legacy.getState().route).toEqual(createGame(4242).route);
  });

  it("requires confirmation before a recent route replaces unfinished progress", () => {
    const completed = endedState();
    const storage = memoryStorage();
    saveChronicle(storage, recordJourney(EMPTY_CHRONICLE, completed));
    let unfinished = beginGame(createGame(9));
    unfinished = choose(unfinished, visibleChoices(unfinished)[0]!.id);
    saveGame(storage, unfinished);
    const root = rootElement();
    const game = mountGame(root, { storage, seed: 1 });
    const invalidReplay = root.querySelector<HTMLButtonElement>(
      '[data-action="chronicle-replay"]',
    )!.cloneNode(true) as HTMLButtonElement;
    invalidReplay.dataset.journeyIndex = "99";
    root.querySelector(".chronicle__journeys")!.append(invalidReplay);

    click(root, '[data-action="chronicle-replay"]');
    expect(game.getState()).toEqual(unfinished);
    expect(root.querySelector(".chronicle__status")?.textContent).toContain("未竟旅程");
    expect(root.querySelector('[data-action="chronicle-replay"] strong')?.textContent)
      .toContain("确认舍下");

    root.querySelector<HTMLElement>(".journal summary")!.click();
    expect(root.querySelector(".chronicle__status")?.textContent).toBe("");
    click(root, '[data-action="chronicle-replay"]');
    expect(root.querySelector(".chronicle__status")?.textContent).toContain("未竟旅程");

    click(root, '[data-action="language"]');
    expect(game.getState().phase).toBe("reflection");
    expect(root.querySelector(".chronicle__status")?.textContent).toBe("");
    click(root, '[data-action="chronicle-replay"]');
    expect(game.getState().phase).toBe("reflection");
    click(root, '[data-action="chronicle-replay"]');
    expect(game.getState()).toMatchObject({ phase: "playing", seed: 4242, locale: "en" });
    expect(game.getState().journal).toHaveLength(0);
  });

  it("bounds the visible recent-journey ledger to five entries", () => {
    const ended = endedState();
    const baseRecord = recordJourney(EMPTY_CHRONICLE, ended).journeys[0]!;
    const journeys = Array.from({ length: 7 }, (_, index) => ({
      ...baseRecord,
      id: `route-${index}`,
      seed: index + 1,
    }));
    const storage = memoryStorage();
    saveChronicle(storage, { version: 1, journeys });
    const root = rootElement();
    mountGame(root, { storage, seed: 8 });
    const recent = root.querySelectorAll('[data-action="chronicle-replay"]');
    expect(recent).toHaveLength(5);
    expect(recent[0]?.textContent).toContain("旅签 7");
    expect(recent[4]?.textContent).toContain("旅签 3");
  });

  it("copies a completed journey and announces success", async () => {
    const storage = memoryStorage();
    saveGame(storage, endedState());
    const writeText = vi.fn().mockResolvedValue(undefined);
    const root = rootElement();
    mountGame(root, {
      storage,
      seed: 1,
      clipboard: { writeText },
      routeUrl: (seed, route, locale) =>
        `https://example.test/game/?seed=${seed}&replay=1&route=${route.join(",")}&lang=${locale}`,
    });
    root.querySelector<HTMLButtonElement>('[data-action="copy"]')!.focus();
    click(root, '[data-action="copy"]');
    await vi.waitFor(() => expect(root.querySelector(".share__status")?.textContent).toContain("已抄录"));
    expect(writeText).toHaveBeenCalledWith(expect.stringContaining("#山河有契"));
    expect(writeText).toHaveBeenCalledWith(
      expect.stringContaining(
        "同路旅签：https://example.test/game/?seed=4242&replay=1&route=",
      ),
    );
    expect(document.activeElement).toBe(root.querySelector('[data-action="copy"]'));
    expect(root.querySelector('[data-action="download-summary"]')).toBeNull();
  });

  it("downloads the visible completed journey as UTF-8 plain text", () => {
    const storage = memoryStorage();
    saveGame(storage, endedState());
    const downloadFile = vi.fn();
    const root = rootElement();
    mountGame(root, {
      storage,
      seed: 1,
      downloadFile,
      now: () => new Date("2026-07-31T23:58:09.321Z"),
      routeUrl: (seed, route) =>
        `https://example.test/game/?seed=${seed}&replay=1&route=${route.join(",")}`,
    });

    const download = root.querySelector<HTMLButtonElement>('[data-action="download-summary"]')!;
    download.focus();
    download.click();

    expect(downloadFile).toHaveBeenCalledWith(
      "shan-he-you-qi-journey-4242-covenant-2026-07-31T23-58-09-321Z.txt",
      expect.stringMatching(/同路旅签：https:\/\/example\.test\/game\/\?seed=4242.*#山河有契\n$/s),
      "text/plain;charset=utf-8",
    );
    expect(root.querySelector(".share__status")?.textContent).toContain("交给浏览器下载");
    expect(document.activeElement).toBe(root.querySelector('[data-action="download-summary"]'));
  });

  it("keeps selectable journey and backup fallbacks when download setup fails", () => {
    const storage = memoryStorage();
    saveGame(storage, endedState());
    const downloadFile = vi.fn(() => {
      throw new Error("synthetic download unavailable");
    });
    const root = rootElement();
    mountGame(root, {
      storage,
      seed: 1,
      downloadFile,
      routeUrl: (seed, route) =>
        `https://example.test/game/?seed=${seed}&replay=1&route=${route.join(",")}`,
    });

    const exportButton = root.querySelector<HTMLButtonElement>('[data-action="backup-export"]')!;
    exportButton.focus();
    exportButton.click();

    expect(root.querySelector(".backup__status")?.textContent).toContain("无法开始下载");
    const fallback = root.querySelector<HTMLTextAreaElement>(".backup__fallback")!;
    expect(fallback.hidden).toBe(false);
    expect(parseLocalBackup(fallback.value)?.journey?.phase).toBe("ended");
    expect(document.activeElement).toBe(exportButton);

    click(root, '[data-action="download-summary"]');
    expect(root.querySelector(".share__status")?.textContent).toContain("手动复制行旅");
    expect(root.querySelector<HTMLTextAreaElement>(".share textarea")?.value).toContain("#山河有契");
    expect(root.querySelector<HTMLTextAreaElement>(".backup__fallback")?.value).toBe(fallback.value);
    expect(downloadFile).toHaveBeenCalledTimes(2);
  });

  it("shares the exact completed artifact through a supported device share sheet", async () => {
    const storage = memoryStorage();
    saveGame(storage, endedState());
    const share = vi.fn().mockResolvedValue(undefined);
    const canShare = vi.fn().mockReturnValue(true);
    const root = rootElement();
    mountGame(root, {
      storage,
      seed: 1,
      nativeShare: { canShare, share },
      reload: vi.fn(),
      routeUrl: (seed, route, locale) =>
        `https://example.test/game/?seed=${seed}&replay=1&route=${route.join(",")}&lang=${locale}`,
    });
    const staged = serializeLocalBackup(
      createLocalBackup(
        endedState(),
        EMPTY_CHRONICLE,
        DEFAULT_PREFERENCES,
        DEFAULT_AUDIO_SETTINGS,
      ),
    );
    selectBackupFile(root, new File([staged], "backup.json"));
    await vi.waitFor(() => expect(root.querySelector(".backup__status")?.textContent).toContain("备份有效"));

    click(root, '[data-action="native-share"]');
    await vi.waitFor(() => expect(root.querySelector(".share__status")?.textContent).toContain("已交给系统分享"));

    expect(canShare).toHaveBeenCalledWith(expect.objectContaining({
      title: "行旅之契 · 山河有契",
      text: expect.stringMatching(/https:\/\/example\.test\/game\/\?seed=4242&replay=1&route=.*&lang=zh/),
    }));
    expect(share).toHaveBeenCalledWith(canShare.mock.calls[0]![0]);
    expect(root.querySelector<HTMLButtonElement>('[data-action="backup-restore"]')?.disabled)
      .toBe(false);
    expect(document.activeElement).toBe(root.querySelector('[data-action="native-share"]'));
  });

  it("keeps fallback sharing usable after unsupported, failed, or canceled device sharing", async () => {
    const storage = memoryStorage();
    saveGame(storage, endedState());

    const unsupportedRoot = rootElement();
    const unsupportedShare = vi.fn();
    mountGame(unsupportedRoot, {
      storage,
      seed: 1,
      clipboard: { writeText: vi.fn().mockResolvedValue(undefined) },
      nativeShare: { canShare: () => false, share: unsupportedShare },
    });
    click(unsupportedRoot, '[data-action="native-share"]');
    await vi.waitFor(() => expect(unsupportedRoot.querySelector(".share__status")?.textContent).toContain("无法打开"));
    expect(unsupportedShare).not.toHaveBeenCalled();
    expect(unsupportedRoot.querySelector<HTMLButtonElement>('[data-action="copy"]')?.disabled).toBe(false);

    const brokenProbeRoot = rootElement();
    const brokenProbeShare = vi.fn();
    mountGame(brokenProbeRoot, {
      storage,
      seed: 1,
      nativeShare: {
        canShare: () => { throw new Error("broken capability probe"); },
        share: brokenProbeShare,
      },
    });
    click(brokenProbeRoot, '[data-action="native-share"]');
    await vi.waitFor(() => expect(brokenProbeRoot.querySelector(".share__status")?.textContent)
      .toContain("无法打开"));
    expect(brokenProbeShare).not.toHaveBeenCalled();

    const failedRoot = rootElement();
    mountGame(failedRoot, {
      storage,
      seed: 1,
      nativeShare: { share: vi.fn().mockRejectedValue(new Error("denied")) },
    });
    click(failedRoot, '[data-action="native-share"]');
    await vi.waitFor(() => expect(failedRoot.querySelector(".share__status")?.textContent).toContain("无法打开"));

    const canceledRoot = rootElement();
    const canceledShare = vi.fn().mockRejectedValue(new DOMException("Canceled", "AbortError"));
    mountGame(canceledRoot, {
      storage,
      seed: 1,
      nativeShare: { share: canceledShare },
    });
    click(canceledRoot, '[data-action="native-share"]');
    await vi.waitFor(() => expect(canceledShare).toHaveBeenCalledOnce());
    expect(canceledRoot.querySelector(".share__status")?.textContent).toBe("");
    expect(canceledRoot.querySelector<HTMLTextAreaElement>(".share textarea")?.readOnly).toBe(true);
  });

  it("ignores a device share result that completes after teardown", async () => {
    let resolveShare!: () => void;
    const storage = memoryStorage();
    saveGame(storage, endedState());
    const root = rootElement();
    const game = mountGame(root, {
      storage,
      seed: 1,
      nativeShare: {
        share: () => new Promise<void>((resolve) => { resolveShare = resolve; }),
      },
    });

    click(root, '[data-action="native-share"]');
    game.destroy();
    resolveShare();
    await Promise.resolve();

    expect(root.childElementCount).toBe(0);
  });

  it("keeps the selectable fallback when clipboard writing fails", async () => {
    const storage = memoryStorage();
    saveGame(storage, endedState());
    const root = rootElement();
    mountGame(root, {
      storage,
      seed: 1,
      clipboard: { writeText: vi.fn().mockRejectedValue(new Error("denied")) },
    });
    click(root, '[data-action="copy"]');
    await vi.waitFor(() => expect(root.querySelector(".share__status")?.textContent).toContain("手动复制"));
    expect(root.querySelector<HTMLTextAreaElement>(".share textarea")?.readOnly).toBe(true);
  });

  it("ignores a clipboard write that completes after teardown", async () => {
    let resolveWrite!: () => void;
    const storage = memoryStorage();
    saveGame(storage, endedState());
    const root = rootElement();
    const game = mountGame(root, {
      storage,
      seed: 1,
      clipboard: {
        writeText: () => new Promise<void>((resolve) => { resolveWrite = resolve; }),
      },
    });
    click(root, '[data-action="copy"]');
    game.destroy();
    resolveWrite();
    await Promise.resolve();
    expect(root.childElementCount).toBe(0);
  });

  it("ignores stale clipboard results and copies tied to an earlier game state", async () => {
    const writes: Array<{ resolve: () => void; reject: (reason: Error) => void }> = [];
    const storage = memoryStorage();
    saveGame(storage, endedState());
    const root = rootElement();
    const game = mountGame(root, {
      storage,
      seed: 1,
      clipboard: {
        writeText: () =>
          new Promise<void>((resolve, reject) => {
            writes.push({ resolve, reject });
          }),
      },
    });
    click(root, '[data-action="copy"]');
    click(root, '[data-action="copy"]');
    writes[1]!.resolve();
    await vi.waitFor(() => expect(root.querySelector(".share__status")?.textContent).toContain("已抄录"));
    writes[0]!.reject(new Error("stale denial"));
    await Promise.resolve();
    expect(root.querySelector(".share__status")?.textContent).toContain("已抄录");

    click(root, '[data-action="copy"]');
    click(root, '[data-action="replay"]');
    writes[2]!.resolve();
    await Promise.resolve();
    expect(game.getState().phase).toBe("playing");
    expect(root.querySelector('[data-action="copy"]')).toBeNull();
  });

  it("applies and persists accessible reading preferences independently", () => {
    const storage = memoryStorage();
    const root = rootElement();
    const game = mountGame(root, { storage, seed: 8 });
    expect(root.dataset).toMatchObject({
      textScale: "normal",
      motion: "system",
      contrast: "system",
    });

    selectPreference(root, "textScale", "large");
    selectPreference(root, "motion", "reduced");
    selectPreference(root, "contrast", "high");
    expect(game.getPreferences()).toMatchObject({
      textScale: "large",
      motion: "reduced",
      contrast: "high",
    });
    expect(root.dataset).toMatchObject({
      textScale: "large",
      motion: "reduced",
      contrast: "high",
    });

    const unchecked = root.querySelector<HTMLInputElement>('[data-preference="motion"]')!;
    unchecked.checked = false;
    unchecked.dispatchEvent(new Event("change", { bubbles: true }));
    const noPreference = document.createElement("input");
    noPreference.checked = true;
    root.append(noPreference);
    noPreference.dispatchEvent(new Event("change", { bubbles: true }));
    const invalid = document.createElement("input");
    invalid.checked = true;
    invalid.dataset.preference = "motion";
    invalid.value = "lots";
    root.append(invalid);
    invalid.dispatchEvent(new Event("change", { bubbles: true }));
    expect(game.getPreferences().motion).toBe("reduced");

    game.destroy();
    const restored = mountGame(root, { storage, seed: 9 });
    expect(restored.getPreferences()).toMatchObject({
      textScale: "large",
      motion: "reduced",
      contrast: "high",
    });
    expect(root.querySelector<HTMLInputElement>('[value="large"]')?.checked).toBe(true);
    root.querySelector<HTMLInputElement>("[data-audio-volume]")!.dispatchEvent(
      new Event("input", { bubbles: true }),
    );
  });

  it("keeps ambient audio opt-in and persists explicit volume and mute controls", async () => {
    const storage = memoryStorage();
    const root = rootElement();
    const audio = fakeAudio();
    const game = mountGame(root, { storage, seed: 10, ambientAudio: audio });
    expect(audio.play).not.toHaveBeenCalled();
    expect(audio).toMatchObject({ loop: true, volume: 0.35, muted: false });
    expect(game.isAmbientPlaying()).toBe(false);

    click(root, '[data-action="audio"]');
    await vi.waitFor(() => expect(game.isAmbientPlaying()).toBe(true));
    expect(root.querySelector('[data-action="audio"]')?.textContent).toContain("关闭");
    expect(root.querySelector('[data-action="audio"]')?.getAttribute("aria-pressed")).toBe("true");

    click(root, '[data-action="language"]');
    expect(root.querySelector('[data-action="audio"]')?.textContent).toContain("Stop ambience");
    click(root, '[data-action="language"]');
    click(root, '[data-action="mute"]');
    expect(audio.muted).toBe(true);
    expect(game.getAudioSettings().muted).toBe(true);
    expect(root.querySelector('[data-action="mute"]')?.textContent).toContain("取消静音");

    const volume = root.querySelector<HTMLInputElement>("[data-audio-volume]")!;
    volume.value = "0.7";
    volume.dispatchEvent(new Event("input", { bubbles: true }));
    expect(audio.volume).toBe(0.7);
    expect(root.querySelector(".ambient output")?.textContent).toBe("70%");

    root.dispatchEvent(new Event("input", { bubbles: true }));
    click(root, '[data-action="audio"]');
    expect(game.isAmbientPlaying()).toBe(false);
    expect(audio.pause).toHaveBeenCalledTimes(1);
    game.destroy();
    expect(audio.pause).toHaveBeenCalledTimes(2);

    const restoredAudio = fakeAudio();
    const restored = mountGame(root, { storage, seed: 11, ambientAudio: restoredAudio });
    expect(restored.getAudioSettings()).toMatchObject({ volume: 0.7, muted: true });
    expect(restoredAudio).toMatchObject({ volume: 0.7, muted: true, loop: true });
    expect(restoredAudio.play).not.toHaveBeenCalled();
  });

  it("announces denied audio playback and remains fully silent", async () => {
    const root = rootElement();
    const audio = fakeAudio(() => Promise.reject(new Error("denied")));
    const game = mountGame(root, { storage: memoryStorage(), seed: 12, ambientAudio: audio });
    click(root, '[data-action="audio"]');
    await vi.waitFor(() => expect(root.querySelector(".ambient__status")?.textContent).toContain("静默"));
    expect(game.isAmbientPlaying()).toBe(false);
    expect(root.querySelector('[data-action="audio"]')?.getAttribute("aria-pressed")).toBe("false");
  });

  it("prepares optional ambience once before playback and handles preparation failure", async () => {
    let resolvePreparation!: () => void;
    const prepareAmbientAudio = vi.fn(
      () => new Promise<void>((resolve) => { resolvePreparation = resolve; }),
    );
    const audio = fakeAudio();
    const root = rootElement();
    const game = mountGame(root, {
      storage: memoryStorage(),
      seed: 12,
      ambientAudio: audio,
      prepareAmbientAudio,
    });

    click(root, '[data-action="audio"]');
    click(root, '[data-action="audio"]');
    expect(prepareAmbientAudio).toHaveBeenCalledOnce();
    expect(audio.play).not.toHaveBeenCalled();
    expect(root.querySelector<HTMLButtonElement>('[data-action="audio"]')?.disabled).toBe(true);
    resolvePreparation();
    await vi.waitFor(() => expect(game.isAmbientPlaying()).toBe(true));
    expect(audio.play).toHaveBeenCalledOnce();

    const failedRoot = rootElement();
    const failedAudio = fakeAudio();
    mountGame(failedRoot, {
      storage: memoryStorage(),
      seed: 12,
      ambientAudio: failedAudio,
      prepareAmbientAudio: vi.fn().mockRejectedValue(new Error("offline")),
    });
    click(failedRoot, '[data-action="audio"]');
    await vi.waitFor(() =>
      expect(failedRoot.querySelector(".ambient__status")?.textContent).toContain("静默"),
    );
    expect(failedAudio.play).not.toHaveBeenCalled();
  });

  it("pauses active ambience while hidden and never auto-resumes it", async () => {
    const visibility = fakeVisibility();
    const audio = fakeAudio();
    const root = rootElement();
    const game = mountGame(root, {
      storage: memoryStorage(),
      seed: 12,
      ambientAudio: audio,
      visibilitySource: visibility.source,
    });

    visibility.setHidden(true);
    expect(audio.pause).not.toHaveBeenCalled();
    visibility.setHidden(false);
    click(root, '[data-action="audio"]');
    await vi.waitFor(() => expect(game.isAmbientPlaying()).toBe(true));

    visibility.setHidden(true);
    expect(game.isAmbientPlaying()).toBe(false);
    expect(audio.pause).toHaveBeenCalledOnce();
    expect(root.querySelector(".ambient__status")?.textContent).toContain("切换页面时已暂停");
    expect(root.querySelector<HTMLButtonElement>('[data-action="audio"]')?.disabled).toBe(false);

    visibility.setHidden(false);
    expect(audio.play).toHaveBeenCalledOnce();
    expect(game.isAmbientPlaying()).toBe(false);
    click(root, '[data-action="audio"]');
    await vi.waitFor(() => expect(audio.play).toHaveBeenCalledTimes(2));
    expect(game.isAmbientPlaying()).toBe(true);

    game.destroy();
    const pausesAfterDestroy = audio.pause.mock.calls.length;
    visibility.setHidden(true);
    expect(audio.pause).toHaveBeenCalledTimes(pausesAfterDestroy);
  });

  it("cancels a pending ambience start when the page becomes hidden", async () => {
    let resolvePlay!: () => void;
    const visibility = fakeVisibility();
    const audio = fakeAudio(() => new Promise<void>((resolve) => { resolvePlay = resolve; }));
    const root = rootElement();
    const game = mountGame(root, {
      storage: memoryStorage(),
      seed: 13,
      ambientAudio: audio,
      visibilitySource: visibility.source,
    });

    click(root, '[data-action="audio"]');
    expect(root.querySelector<HTMLButtonElement>('[data-action="audio"]')?.disabled).toBe(true);
    visibility.setHidden(true);
    expect(root.querySelector<HTMLButtonElement>('[data-action="audio"]')?.disabled).toBe(false);
    expect(root.querySelector(".ambient__status")?.textContent).toContain("切换页面时已暂停");
    resolvePlay();
    await vi.waitFor(() => expect(audio.pause).toHaveBeenCalledOnce());
    expect(game.isAmbientPlaying()).toBe(false);
    expect(root.querySelector('[data-action="audio"]')?.getAttribute("aria-pressed")).toBe("false");
  });

  it("does not call play when visibility changes during audio preparation", async () => {
    let resolvePreparation!: () => void;
    const visibility = fakeVisibility();
    const audio = fakeAudio();
    const root = rootElement();
    const game = mountGame(root, {
      storage: memoryStorage(),
      seed: 13,
      ambientAudio: audio,
      visibilitySource: visibility.source,
      prepareAmbientAudio: () => new Promise<void>((resolve) => {
        resolvePreparation = resolve;
      }),
    });

    click(root, '[data-action="audio"]');
    visibility.setHidden(true);
    resolvePreparation();
    await Promise.resolve();

    expect(audio.play).not.toHaveBeenCalled();
    expect(audio.pause).toHaveBeenCalledOnce();
    expect(game.isAmbientPlaying()).toBe(false);
    expect(root.querySelector(".ambient__status")?.textContent).toContain("切换页面时已暂停");
  });

  it("ignores a pending ambience rejection after visibility already canceled it", async () => {
    let rejectPlay!: (reason: Error) => void;
    const visibility = fakeVisibility();
    const audio = fakeAudio(() => new Promise<void>((_resolve, reject) => { rejectPlay = reject; }));
    const root = rootElement();
    const game = mountGame(root, {
      storage: memoryStorage(),
      seed: 13,
      ambientAudio: audio,
      visibilitySource: visibility.source,
    });

    click(root, '[data-action="audio"]');
    visibility.setHidden(true);
    rejectPlay(new Error("start interrupted"));
    await Promise.resolve();

    expect(game.isAmbientPlaying()).toBe(false);
    expect(root.querySelector(".ambient__status")?.textContent).toContain("切换页面时已暂停");
  });

  it("stops playback that resolves after the game is destroyed", async () => {
    let resolvePlay!: () => void;
    const audio = fakeAudio(() => new Promise<void>((resolve) => { resolvePlay = resolve; }));
    const root = rootElement();
    const game = mountGame(root, { storage: memoryStorage(), seed: 13, ambientAudio: audio });
    click(root, '[data-action="audio"]');
    expect(root.querySelector<HTMLButtonElement>('[data-action="audio"]')?.disabled).toBe(true);
    expect(root.querySelector('[data-action="audio"]')?.textContent).toContain("正在开启");
    click(root, '[data-action="audio"]');
    expect(audio.play).toHaveBeenCalledOnce();
    game.destroy();
    resolvePlay();
    await vi.waitFor(() => expect(audio.pause).toHaveBeenCalledOnce());
    expect(game.isAmbientPlaying()).toBe(false);
  });

  it("exports, validates, and explicitly restores a complete local backup", async () => {
    const storage = memoryStorage();
    const root = rootElement();
    const downloadFile = vi.fn();
    const reload = vi.fn();
    const audio = fakeAudio();
    const game = mountGame(root, {
      storage,
      seed: 4242,
      ambientAudio: audio,
      downloadFile,
      reload,
      readFile: async (file) => file.text(),
      now: () => new Date("2026-07-31T23:58:09.321Z"),
    });
    click(root, '[data-action="begin"]');
    click(root, OPERABLE_CHOICE_SELECTOR);
    selectPreference(root, "contrast", "high");
    click(root, '[data-action="backup-export"]');

    expect(downloadFile).toHaveBeenCalledTimes(1);
    const [name, serialized] = downloadFile.mock.calls[0] as [string, string];
    expect(name).toBe("shan-he-you-qi-save-2026-07-31T23-58-09-321Z.json");
    const backup = parseLocalBackup(serialized)!;
    expect(backup.journey?.phase).toBe("reflection");
    expect(backup.preferences.contrast).toBe("high");

    selectBackupFile(root, new File([serialized], name, { type: "application/json" }));
    await vi.waitFor(() => expect(root.querySelector(".backup__status")?.textContent).toContain("备份有效"));
    expect(root.querySelector<HTMLButtonElement>('[data-action="backup-restore"]')?.disabled).toBe(false);
    click(root, '[data-action="language"]');
    expect(root.querySelector<HTMLButtonElement>('[data-action="backup-restore"]')?.disabled).toBe(true);
    expect(root.querySelector(".backup__status")?.textContent).toBe("");
    click(root, '[data-action="language"]');
    selectBackupFile(root, new File([serialized], name, { type: "application/json" }));
    await vi.waitFor(() => expect(root.querySelector(".backup__status")?.textContent).toContain("备份有效"));
    click(root, '[data-action="backup-restore"]');
    expect(root.querySelector(".backup__status")?.textContent).toContain("重新载入");
    expect(root.querySelector<HTMLButtonElement>('[data-action="backup-export"]')?.disabled).toBe(true);
    expect(root.querySelector<HTMLInputElement>("[data-backup-file]")?.disabled).toBe(true);
    expect(root.querySelector<HTMLButtonElement>('[data-action="backup-restore"]')?.disabled).toBe(true);
    expect(root.querySelector<HTMLButtonElement>('[data-action="backup-clear"]')?.disabled).toBe(true);
    expect(audio.pause).toHaveBeenCalled();
    expect(reload).toHaveBeenCalledOnce();
    expect(game.getState().phase).toBe("reflection");
  });

  it("invalidates a pending backup read and locks data controls after clearing", async () => {
    let resolveRead!: (value: string) => void;
    let resolvePersisted!: (value: boolean) => void;
    const storage = memoryStorage();
    const root = rootElement();
    const reload = vi.fn();
    const keyboardTarget = document.implementation.createHTMLDocument();
    const game = mountGame(root, {
      storage,
      seed: 16,
      reload,
      ambientAudio: fakeAudio(),
      keyboardTarget,
      storageEventTarget: window,
      storageDurability: {
        isPersisted: () => new Promise<boolean>((resolve) => {
          resolvePersisted = resolve;
        }),
        requestPersistence: vi.fn().mockResolvedValue(false),
      },
      downloadFile: vi.fn(),
      readFile: () => new Promise<string>((resolve) => {
        resolveRead = resolve;
      }),
    });
    const serialized = serializeLocalBackup(createLocalBackup(
      createGame(16),
      EMPTY_CHRONICLE,
      DEFAULT_PREFERENCES,
      DEFAULT_AUDIO_SETTINGS,
    ));

    selectBackupFile(root, new File([serialized], "pending.json"));
    click(root, '[data-action="backup-clear"]');
    click(root, '[data-action="backup-clear"]');
    expect(root.querySelector(".backup__status")?.textContent).toContain("重新载入");
    expect(root.querySelector<HTMLButtonElement>('[data-action="backup-export"]')?.disabled).toBe(true);
    expect(root.querySelector<HTMLInputElement>("[data-backup-file]")?.disabled).toBe(true);
    expect(root.querySelector<HTMLButtonElement>('[data-action="backup-restore"]')?.disabled).toBe(true);
    expect(root.querySelector<HTMLButtonElement>('[data-action="backup-clear"]')?.disabled).toBe(true);
    expect(root.getAttribute("aria-busy")).toBe("true");
    expect([...root.querySelectorAll<HTMLButtonElement | HTMLInputElement | HTMLTextAreaElement>(
      "button, input, textarea",
    )].every((control) => control.disabled)).toBe(true);

    const textScale = root.querySelector<HTMLInputElement>(
      '[data-preference="textScale"][value="large"]',
    )!;
    textScale.checked = true;
    textScale.dispatchEvent(new Event("change", { bubbles: true }));
    const volume = root.querySelector<HTMLInputElement>("[data-audio-volume]")!;
    volume.value = "0.2";
    volume.dispatchEvent(new Event("input", { bubbles: true }));
    root.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    keyboardTarget.dispatchEvent(new KeyboardEvent("keydown", { key: "l" }));
    window.dispatchEvent(new StorageEvent("storage", {
      key: SAVE_KEY,
      newValue: "newer",
    }));
    resolvePersisted(false);
    await Promise.resolve();
    for (const key of [SAVE_KEY, CHRONICLE_KEY, PREFERENCES_KEY, AUDIO_SETTINGS_KEY]) {
      expect(storage.getItem(key)).toBeNull();
    }
    expect(root.querySelector(".storage-conflict-backdrop")?.hasAttribute("hidden")).toBe(true);

    resolveRead(serialized);
    await Promise.resolve();
    expect(root.querySelector(".backup__status")?.textContent).toContain("重新载入");
    expect(reload).toHaveBeenCalledOnce();
    game.destroy();
  });

  it("discloses legacy chronicle compaction before restore", async () => {
    const journeys = Array.from(
      { length: MAX_CHRONICLE_JOURNEYS + 1 },
      (_, index) => ({
        id: `legacy-${index}`,
        seed: index + 1,
        ending: index === 0 ? "lost" : "covenant",
        stats: { provisions: 3, trust: 3, insight: 3 },
      }),
    );
    const serialized = JSON.stringify({
      version: 1,
      journey: null,
      chronicle: { version: 1, journeys },
      preferences: DEFAULT_PREFERENCES,
      audio: DEFAULT_AUDIO_SETTINGS,
    });
    const root = rootElement();
    const reload = vi.fn();
    mountGame(root, { storage: memoryStorage(), seed: 16, reload });

    selectBackupFile(root, new File([serialized], "legacy.json"));

    await vi.waitFor(() =>
      expect(root.querySelector(".backup__status")?.textContent).toContain("最近 128 次"),
    );
    expect(root.querySelector(".backup__status")?.textContent).toContain("全部已发现结局");
    expect(root.querySelector<HTMLButtonElement>('[data-action="backup-restore"]')?.disabled)
      .toBe(false);
    expect(reload).not.toHaveBeenCalled();
  });

  it("rejects invalid, unreadable, oversized, and canceled backup selections", async () => {
    const root = rootElement();
    const reload = vi.fn();
    const game = mountGame(root, { storage: memoryStorage(), seed: 14, reload });
    selectBackupFile(root);
    expect(root.querySelector(".backup__status")?.textContent).toBe("");

    selectBackupFile(root, new File(["{"], "invalid.json", { type: "application/json" }));
    await vi.waitFor(() => expect(root.querySelector(".backup__status")?.textContent).toContain("不是有效"));
    expect(game.getState().phase).toBe("intro");

    selectBackupFile(root, new File([new Uint8Array(MAX_BACKUP_BYTES + 1)], "large.json"));
    expect(root.querySelector(".backup__status")?.textContent).toContain("过大");

    game.destroy();
    const failedRoot = rootElement();
    mountGame(failedRoot, {
      storage: memoryStorage(),
      seed: 15,
      reload,
      readFile: vi.fn().mockRejectedValue(new Error("disk denied")),
    });
    selectBackupFile(failedRoot, new File(["{}"], "denied.json"));
    await vi.waitFor(() => expect(failedRoot.querySelector(".backup__status")?.textContent).toContain("不是有效"));
    expect(reload).not.toHaveBeenCalled();
  });

  it("keeps the validated backup staged when an atomic restore cannot write", async () => {
    const base = memoryStorage();
    let failWrites = false;
    const storage: StorageLike = {
      ...base,
      setItem: (key, value) => {
        if (failWrites) {
          failWrites = false;
          throw new Error("storage denied");
        }
        base.setItem(key, value);
      },
    };
    const serialized = serializeLocalBackup(
      createLocalBackup(
        createGame(18),
        EMPTY_CHRONICLE,
        DEFAULT_PREFERENCES,
        DEFAULT_AUDIO_SETTINGS,
      ),
    );
    const root = rootElement();
    const reload = vi.fn();
    mountGame(root, { storage, seed: 18, reload });
    selectBackupFile(root, new File([serialized], "backup.json"));
    await vi.waitFor(() => expect(root.querySelector(".backup__status")?.textContent).toContain("备份有效"));

    failWrites = true;
    click(root, '[data-action="backup-restore"]');

    expect(root.querySelector(".backup__status")?.textContent).toContain("当前进度保持不变");
    expect(root.querySelector<HTMLButtonElement>('[data-action="backup-restore"]')?.disabled).toBe(false);
    expect(reload).not.toHaveBeenCalled();
  });

  it("warns when a failed restore cannot completely roll storage back", async () => {
    const base = memoryStorage();
    saveGame(base, createGame(17));
    let denyJourneyWrites = false;
    const storage: StorageLike = {
      ...base,
      setItem: (key, value) => {
        if (denyJourneyWrites && key === SAVE_KEY) throw new Error("storage denied");
        base.setItem(key, value);
      },
    };
    const serialized = serializeLocalBackup(
      createLocalBackup(
        createGame(18),
        EMPTY_CHRONICLE,
        DEFAULT_PREFERENCES,
        DEFAULT_AUDIO_SETTINGS,
      ),
    );
    const root = rootElement();
    const reload = vi.fn();
    mountGame(root, { storage, seed: 18, reload });
    selectBackupFile(root, new File([serialized], "backup.json"));
    await vi.waitFor(() => expect(root.querySelector(".backup__status")?.textContent).toContain("备份有效"));

    denyJourneyWrites = true;
    click(root, '[data-action="backup-restore"]');

    expect(root.querySelector(".backup__status")?.textContent).toContain("未能完整恢复原记录");
    expect(reload).not.toHaveBeenCalled();
  });

  it("requires a second action before clearing all local records", () => {
    const storage = memoryStorage();
    const root = rootElement();
    const reload = vi.fn();
    const audio = fakeAudio();
    const keyboardTarget = document.implementation.createHTMLDocument();
    mountGame(root, {
      storage,
      seed: 4242,
      reload,
      ambientAudio: audio,
      keyboardTarget,
    });
    click(root, '[data-action="begin"]');
    selectPreference(root, "contrast", "high");
    click(root, '[data-action="mute"]');
    storage.setItem(CHRONICLE_KEY, "existing chronicle");

    click(root, '[data-action="backup-clear"]');
    expect(root.querySelector(".backup__status")?.textContent).toContain("再次按下确认");
    expect(root.querySelector('[data-action="backup-clear"]')?.textContent).toContain("确认清除");
    expect(storage.getItem(SAVE_KEY)).not.toBeNull();
    expect(reload).not.toHaveBeenCalled();

    click(root, '[data-action="mute"]');
    expect(root.querySelector(".backup__status")?.textContent).toBe("");
    click(root, '[data-action="backup-clear"]');

    root.querySelector<HTMLElement>(".journal summary")!.click();
    expect(root.querySelector(".backup__status")?.textContent).toBe("");
    click(root, '[data-action="backup-clear"]');

    selectPreference(root, "motion", "reduced");
    expect(root.querySelector(".backup__status")?.textContent).toBe("");
    click(root, '[data-action="backup-clear"]');

    const volume = root.querySelector<HTMLInputElement>("[data-audio-volume]")!;
    volume.value = "0.5";
    volume.dispatchEvent(new Event("input", { bubbles: true }));
    expect(root.querySelector(".backup__status")?.textContent).toBe("");
    click(root, '[data-action="backup-clear"]');

    keyboardTarget.dispatchEvent(new KeyboardEvent("keydown", { key: "l" }));
    expect(root.querySelector(".backup__status")?.textContent).toBe("");
    click(root, '[data-action="backup-clear"]');
    click(root, '[data-action="backup-clear"]');

    for (const key of [SAVE_KEY, CHRONICLE_KEY, PREFERENCES_KEY, AUDIO_SETTINGS_KEY]) {
      expect(storage.getItem(key)).toBeNull();
    }
    expect(root.querySelector(".backup__status")?.textContent).toContain("reloading");
    expect(audio.pause).toHaveBeenCalled();
    expect(reload).toHaveBeenCalledOnce();
  });

  it("keeps local records when clearing cannot complete", () => {
    const base = memoryStorage();
    for (const key of [SAVE_KEY, CHRONICLE_KEY, PREFERENCES_KEY, AUDIO_SETTINGS_KEY]) {
      base.setItem(key, `old ${key}`);
    }
    let shouldFail = true;
    const failingStorage: StorageLike = {
      ...base,
      removeItem: (key) => {
        if (key === CHRONICLE_KEY && shouldFail) {
          shouldFail = false;
          throw new Error("denied");
        }
        base.removeItem(key);
      },
    };
    const root = rootElement();
    const reload = vi.fn();
    mountGame(root, {
      storage: memoryStorage(),
      restoreStorage: failingStorage,
      seed: 20,
      reload,
    });
    click(root, '[data-action="backup-clear"]');
    click(root, '[data-action="backup-clear"]');

    expect(root.querySelector(".backup__status")?.textContent).toContain("现有记录保持不变");
    for (const key of [SAVE_KEY, CHRONICLE_KEY, PREFERENCES_KEY, AUDIO_SETTINGS_KEY]) {
      expect(base.getItem(key)).toBe(`old ${key}`);
    }
    expect(reload).not.toHaveBeenCalled();
  });

  it("reports a denied pre-clear snapshot without attempting removal", () => {
    const removeItem = vi.fn();
    const restoreStorage: StorageLike = {
      getItem: () => {
        throw new Error("read denied");
      },
      setItem: vi.fn(),
      removeItem,
    };
    const root = rootElement();
    const reload = vi.fn();
    mountGame(root, {
      storage: memoryStorage(),
      restoreStorage,
      seed: 20,
      reload,
    });

    click(root, '[data-action="backup-clear"]');
    click(root, '[data-action="backup-clear"]');

    expect(root.querySelector(".backup__status")?.textContent).toContain("现有记录保持不变");
    expect(removeItem).not.toHaveBeenCalled();
    expect(reload).not.toHaveBeenCalled();
  });

  it("warns when a failed clear cannot completely roll storage back", () => {
    const base = memoryStorage();
    for (const key of [SAVE_KEY, CHRONICLE_KEY, PREFERENCES_KEY, AUDIO_SETTINGS_KEY]) {
      base.setItem(key, `old ${key}`);
    }
    let rollingBack = false;
    const failingStorage: StorageLike = {
      ...base,
      removeItem: (key) => {
        if (key === CHRONICLE_KEY) {
          rollingBack = true;
          throw new Error("remove denied");
        }
        base.removeItem(key);
      },
      setItem: (key, value) => {
        if (rollingBack && key === SAVE_KEY) throw new Error("rollback denied");
        base.setItem(key, value);
      },
    };
    const root = rootElement();
    const reload = vi.fn();
    mountGame(root, {
      storage: memoryStorage(),
      restoreStorage: failingStorage,
      seed: 20,
      reload,
    });
    click(root, '[data-action="backup-clear"]');
    click(root, '[data-action="backup-clear"]');

    expect(root.querySelector(".backup__status")?.textContent).toContain("未能完整恢复原记录");
    expect(reload).not.toHaveBeenCalled();
  });

  it("ignores backup reads that settle after teardown", async () => {
    let resolveRead!: (value: string) => void;
    const root = rootElement();
    const game = mountGame(root, {
      storage: memoryStorage(),
      seed: 16,
      reload: vi.fn(),
      readFile: () => new Promise<string>((resolve) => { resolveRead = resolve; }),
    });
    selectBackupFile(root, new File(["{}"], "later.json"));
    game.destroy();
    resolveRead("{}");
    await Promise.resolve();
    expect(root.childElementCount).toBe(0);

    let rejectRead!: (reason?: unknown) => void;
    const rejectedRoot = rootElement();
    const rejected = mountGame(rejectedRoot, {
      storage: memoryStorage(),
      seed: 17,
      reload: vi.fn(),
      readFile: () => new Promise<string>((_resolve, reject) => { rejectRead = reject; }),
    });
    selectBackupFile(rejectedRoot, new File(["{}"], "later.json"));
    rejected.destroy();
    rejectRead(new Error("late failure"));
    await Promise.resolve();
    expect(rejectedRoot.childElementCount).toBe(0);
  });

  it("keeps only the latest backup selection and cancels in-flight reads", async () => {
    const reads = new Map<string, { resolve: (value: string) => void; reject: (reason: Error) => void }>();
    const root = rootElement();
    mountGame(root, {
      storage: memoryStorage(),
      seed: 19,
      reload: vi.fn(),
      readFile: (file) =>
        new Promise<string>((resolve, reject) => {
          reads.set(file.name, { resolve, reject });
        }),
    });
    const serialized = serializeLocalBackup(
      createLocalBackup(
        createGame(19),
        EMPTY_CHRONICLE,
        DEFAULT_PREFERENCES,
        DEFAULT_AUDIO_SETTINGS,
      ),
    );

    selectBackupFile(root, new File(["first"], "first.json"));
    expect(root.querySelector(".backup__status")?.textContent).toContain("正在验证");
    expect(root.querySelector<HTMLButtonElement>('[data-action="backup-restore"]')?.disabled).toBe(true);
    selectBackupFile(root, new File(["second"], "second.json"));
    reads.get("second.json")!.resolve(serialized);
    await vi.waitFor(() => expect(root.querySelector(".backup__status")?.textContent).toContain("备份有效"));
    reads.get("first.json")!.reject(new Error("stale read"));
    await Promise.resolve();
    expect(root.querySelector(".backup__status")?.textContent).toContain("备份有效");

    selectBackupFile(root, new File(["third"], "third.json"));
    selectBackupFile(root);
    reads.get("third.json")!.resolve(serialized);
    await Promise.resolve();
    expect(root.querySelector(".backup__status")?.textContent).toBe("");
    expect(root.querySelector<HTMLButtonElement>('[data-action="backup-restore"]')?.disabled).toBe(true);
  });

  it("ignores non-controls and cleans up listeners", () => {
    const root = rootElement();
    const keyboardTarget = document.implementation.createHTMLDocument();
    const removeSpy = vi.spyOn(keyboardTarget, "removeEventListener");
    const game = mountGame(root, { storage: memoryStorage(), seed: 3, keyboardTarget });
    root.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    expect(game.getState().phase).toBe("intro");
    game.destroy();
    expect(root.childElementCount).toBe(0);
    expect(removeSpy).toHaveBeenCalled();
  });
});
