import "./style.css";
import { createResilientStorage, type StorageLike } from "./game/storage";
import { createServiceWorkerUpdateController } from "./pwa/update";
import { mountGame, localeFromSearch, routeFromSearch, seedFromSearch } from "./ui/app";
import type { Locale } from "./game/types";

const root = document.querySelector<HTMLElement>("#app");
if (!root) throw new Error("Missing #app root element.");

const ambientAudioUrl = new URL("assets/mountain-wind.ogg", document.baseURI).href;
const ambientAudio = new Audio();
ambientAudio.preload = "none";
ambientAudio.src = ambientAudioUrl;

const persistentStorage = (() => {
  try {
    return window.localStorage as StorageLike;
  } catch {
    return null;
  }
})();
const storage = createResilientStorage(persistentStorage);

const downloadFile = (
  name: string,
  contents: string,
  mimeType = "application/octet-stream",
): void => {
  let url: string | null = null;
  let anchor: HTMLAnchorElement | null = null;
  try {
    url = URL.createObjectURL(new Blob([contents], { type: mimeType }));
    anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = name;
    anchor.hidden = true;
    document.body.append(anchor);
    anchor.click();
  } finally {
    anchor?.remove();
    if (url !== null) window.setTimeout(() => URL.revokeObjectURL(url!), 0);
  }
};

const setJourneySearch = (
  url: URL,
  seed: number,
  route: readonly string[],
  locale: Locale,
): void => {
  url.searchParams.set("seed", String(seed));
  url.searchParams.set("route", route.join(","));
  if (locale === "en") url.searchParams.set("lang", "en");
  else url.searchParams.delete("lang");
};

const routeUrl = (seed: number, route: readonly string[], locale: Locale): string => {
  const url = new URL(window.location.href);
  url.hash = "";
  url.search = "";
  setJourneySearch(url, seed, route, locale);
  url.searchParams.set("replay", "1");
  return url.href;
};

const replaceRouteUrl = (seed: number, route: readonly string[], locale: Locale): void => {
  const url = new URL(window.location.href);
  url.hash = "";
  url.search = "";
  setJourneySearch(url, seed, route, locale);
  window.history.replaceState(null, "", url);
};

const forceNew = new URLSearchParams(window.location.search).get("replay") === "1";
const updateController = createServiceWorkerUpdateController(() => window.location.reload());

const nativeShare = typeof navigator.share === "function"
  ? {
      share: (data: ShareData) => navigator.share(data),
      ...(typeof navigator.canShare === "function"
        ? { canShare: (data: ShareData) => navigator.canShare(data) }
        : {}),
    }
  : undefined;

const storageDurability =
  typeof navigator.storage?.persisted === "function" &&
  typeof navigator.storage.persist === "function"
    ? {
        isPersisted: () => navigator.storage.persisted(),
        requestPersistence: () => navigator.storage.persist(),
      }
    : undefined;

mountGame(root, {
  storage,
  restoreStorage: persistentStorage ?? undefined,
  isStoragePersistent: storage.isPersistent,
  seed: seedFromSearch(window.location.search, Date.now()),
  forceNew,
  initialRoute: routeFromSearch(window.location.search),
  initialLocale: localeFromSearch(window.location.search),
  clipboard: navigator.clipboard,
  nativeShare,
  updateController,
  routeUrl,
  onJourneyLinkChange: replaceRouteUrl,
  ambientAudio,
  prepareAmbientAudio: async () => {
    const response = await fetch(ambientAudioUrl, { cache: "reload" });
    if (!response.ok) throw new Error(`Unable to prepare ambience: ${response.status}`);
  },
  downloadFile,
  reload: () => window.location.reload(),
  storageEventTarget: persistentStorage ? window : undefined,
  pageLifecycleSource: window,
  storageDurability,
  visibilitySource: document,
});

if (forceNew) {
  const resumedUrl = new URL(window.location.href);
  resumedUrl.searchParams.delete("replay");
  window.history.replaceState(null, "", resumedUrl);
}

if (import.meta.env.PROD && "serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    const workerUrl = new URL("sw.js", document.baseURI);
    const connection = (navigator as Navigator & { connection?: { saveData?: boolean } }).connection;
    if (connection?.saveData === true) workerUrl.searchParams.set("saveData", "1");
    void navigator.serviceWorker
      .register(workerUrl, { scope: "./", updateViaCache: "none" })
      .then((registration) => updateController.attach(registration, navigator.serviceWorker))
      .catch(() => undefined);
  });
}
