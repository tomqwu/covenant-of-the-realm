const CACHE_PREFIX = "shan-he-you-qi-shell-";
const CACHE_SCHEMA = "v9";
const BUILD_REVISION = "__SHAN_HE_RELEASE_REVISION__";
const scriptUrl = new URL(self.location.href);
const revision = BUILD_REVISION.replace(/[^A-Za-z0-9_-]/g, "-");
const reducedData = scriptUrl.searchParams.get("saveData") === "1";
const dataMode = reducedData ? "reduced" : "full";
const scopeKey = encodeURIComponent(new URL(self.registration.scope).pathname);
const SCOPED_CACHE_PREFIX = `${CACHE_PREFIX}${scopeKey}-`;
const CORE_PATHS = [
  "./manifest.webmanifest",
  "./icons/app-icon-192.png",
  "./icons/app-icon-512.png",
  "./icons/app-icon.svg",
  "./icons/app-icon-maskable-512.png",
  "./assets/journey-scroll.jpg",
];
const OPTIONAL_PATHS = ["./assets/mountain-wind.ogg"];
const precacheSource = [...CORE_PATHS, "--optional--", ...OPTIONAL_PATHS].join("\n");
let precacheHash = 0x811c9dc5;
for (let index = 0; index < precacheSource.length; index += 1) {
  precacheHash = Math.imul(precacheHash ^ precacheSource.charCodeAt(index), 0x01000193);
}
const precacheRevision = (precacheHash >>> 0).toString(36);
const CACHE_NAME =
  `${SCOPED_CACHE_PREFIX}${CACHE_SCHEMA}-${precacheRevision}-${dataMode}-${revision}`;

const currentCache = () => caches.open(CACHE_NAME);

const cacheResponse = async (cache, request, response) => {
  if (response.ok) {
    const cacheKey = request.mode === "navigate"
      ? new URL("./", self.registration.scope)
      : request;
    await cache.put(cacheKey, response.clone()).catch(() => undefined);
  }
  return response;
};

const rangedResponse = async (request, response) => {
  const rangeHeader = request.headers.get("range");
  if (!rangeHeader || response.status !== 200) return response;

  const bytes = await response.arrayBuffer();
  const match = /^bytes=(\d*)-(\d*)$/.exec(rangeHeader);
  if (!match) return response;

  const total = bytes.byteLength;
  const suffixLength = match[1] === "" ? Number(match[2]) : null;
  const start = suffixLength === null
    ? Number(match[1])
    : Math.max(0, total - suffixLength);
  const requestedEnd = suffixLength === null && match[2] !== "" ? Number(match[2]) : total - 1;
  const end = Math.min(requestedEnd, total - 1);
  if (
    total === 0 ||
    !Number.isSafeInteger(start) ||
    !Number.isSafeInteger(end) ||
    start < 0 ||
    start > end ||
    start >= total
  ) {
    return new Response(null, {
      status: 416,
      headers: { "Content-Range": `bytes */${total}` },
    });
  }

  const headers = new Headers(response.headers);
  headers.set("Accept-Ranges", "bytes");
  headers.set("Content-Length", String(end - start + 1));
  headers.set("Content-Range", `bytes ${start}-${end}/${total}`);
  return new Response(bytes.slice(start, end + 1), {
    status: 206,
    statusText: "Partial Content",
    headers,
  });
};

self.addEventListener("install", (event) => {
  event.waitUntil(
    (async () => {
      try {
        const cache = await currentCache();
        const home = new URL("./", self.registration.scope);
        const homeResponse = await fetch(home, { cache: "reload" });
        if (!homeResponse.ok) throw new Error("Unable to cache the game shell.");
        const html = await homeResponse.clone().text();
        await cache.put(home, homeResponse);

        const referencedPaths = [...html.matchAll(/(?:src|href)\s*=\s*(["'])(.*?)\1/gi)].map(
          (match) => match[2],
        );
        const shellUrls = new Set(
          [...CORE_PATHS, ...(reducedData ? [] : OPTIONAL_PATHS), ...referencedPaths]
            .map((path) => new URL(path, home))
            .filter((url) => url.origin === home.origin)
            .map((url) => url.href),
        );
        const results = await Promise.allSettled(
          [...shellUrls].map(async (url) => {
            const response = await fetch(url, { cache: "reload" });
            if (!response.ok) throw new Error(`Unable to cache ${url}.`);
            await cache.put(url, response);
          }),
        );
        const failed = results.find((result) => result.status === "rejected");
        if (failed) throw failed.reason;
      } catch (error) {
        await caches.delete(CACHE_NAME).catch(() => false);
        throw error;
      }
    })(),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      await self.clients.claim();
      const names = await caches.keys().catch(() => []);
      await Promise.all(
        names
          .filter((name) => name.startsWith(SCOPED_CACHE_PREFIX) && name !== CACHE_NAME)
          .map((name) => caches.delete(name).catch(() => false)),
      );
      if (self.registration.navigationPreload) {
        await self.registration.navigationPreload.enable().catch(() => undefined);
      }
    })(),
  );
});

self.addEventListener("message", (event) => {
  if (event.data?.type === "SKIP_WAITING") void self.skipWaiting();
});

const networkFirst = async (request, preloadResponse) => {
  const cache = await currentCache().catch(() => null);
  try {
    let response;
    try {
      response = await preloadResponse;
    } catch {
      // A failed optional preload still gets the ordinary network attempt below.
    }
    response ??= await fetch(request);
    if (response.status >= 500) throw new Error(`Transient server failure: ${response.status}`);
    return cache ? await cacheResponse(cache, request, response) : response;
  } catch {
    const cached = await cache?.match(request).catch(() => undefined);
    if (cached) return cached;
    if (cache && request.mode === "navigate") {
      const home = await cache
        .match(new URL("./", self.registration.scope))
        .catch(() => undefined);
      if (home) return home;
    }
    throw new Error(`No offline response for ${request.url}`);
  }
};

const cacheFirst = async (request, reloadOnMiss = false) => {
  const cache = await currentCache().catch(() => null);
  const cached = await cache?.match(request).catch(() => undefined);
  if (cached) return rangedResponse(request, cached);
  const response = await fetch(request, reloadOnMiss ? { cache: "reload" } : undefined);
  const resolved = cache ? await cacheResponse(cache, request, response) : response;
  return rangedResponse(request, resolved);
};

self.addEventListener("fetch", (event) => {
  const { request } = event;
  const url = new URL(request.url);
  if (
    request.method !== "GET" ||
    url.origin !== self.location.origin ||
    !url.href.startsWith(self.registration.scope)
  ) return;
  const isHashedAsset = /\/assets\/[^/]+-[A-Za-z0-9_-]{6,}\.(?:css|js)$/.test(url.pathname);
  const isOptionalAudio = url.pathname.endsWith("/assets/mountain-wind.ogg");
  event.respondWith(
    isHashedAsset || isOptionalAudio
      ? cacheFirst(request, isOptionalAudio)
      : networkFirst(request, request.mode === "navigate" ? event.preloadResponse : undefined),
  );
});
