import { readFile } from "node:fs/promises";
import { createServer, type Server } from "node:http";
import { extname, resolve, sep } from "node:path";
import AxeBuilder from "@axe-core/playwright";
import { expect, observeRuntimeErrors, OPERABLE_CHOICE_SELECTOR, test } from "./fixtures";

const mountPath = "/journey/";
const distributionRoot = resolve(process.cwd(), "dist");
const contentTypes: Readonly<Record<string, string>> = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".jpg": "image/jpeg",
  ".json": "application/json; charset=utf-8",
  ".ogg": "audio/ogg",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".webmanifest": "application/manifest+json; charset=utf-8",
};

let server: Server;
let mountedOrigin = "";
let failWithServiceUnavailable = false;
let failedAssetPath: string | null = null;
let preloadedNavigationRequests = 0;
let ordinaryNavigationRequests = 0;
let rejectRuntimeCacheWrite = false;
let workerBuildRevisionOverride: string | null = null;

test.beforeAll(async () => {
  server = createServer(async (request, response) => {
    const pathname = new URL(request.url ?? "/", "http://127.0.0.1").pathname;
    if (!pathname.startsWith(mountPath)) {
      response.writeHead(404).end();
      return;
    }
    if (failWithServiceUnavailable) {
      response.writeHead(503, { "content-type": "text/plain; charset=utf-8" });
      response.end("Temporarily unavailable");
      return;
    }
    if (pathname === failedAssetPath) {
      response.writeHead(503, { "content-type": "text/plain; charset=utf-8" });
      response.end("Asset unavailable");
      return;
    }

    const relativePath = decodeURIComponent(pathname.slice(mountPath.length));
    const requestedPath = relativePath && extname(relativePath) ? relativePath : "index.html";
    if (requestedPath === "index.html") {
      if (request.headers["service-worker-navigation-preload"] !== undefined) {
        preloadedNavigationRequests += 1;
      } else {
        ordinaryNavigationRequests += 1;
      }
    }
    const filePath = resolve(distributionRoot, requestedPath);
    if (filePath !== distributionRoot && !filePath.startsWith(`${distributionRoot}${sep}`)) {
      response.writeHead(403).end();
      return;
    }

    try {
      let body = await readFile(filePath);
      const contentHashed = /^assets\/index-[A-Za-z0-9_-]{6,}\.(?:css|js)$/.test(requestedPath);
      const headers: Record<string, string> = {
        "cache-control": contentHashed
          ? "public, max-age=31536000, immutable"
          : "no-cache",
        "content-type": contentTypes[extname(filePath)] ?? "application/octet-stream",
      };
      if (requestedPath === "index.html" && rejectRuntimeCacheWrite) {
        body = Buffer.from(body.toString("utf8").replace(
          "</head>",
          '<meta name="runtime-cache-write" content="network-response" /></head>',
        ));
        headers.vary = "*";
      }
      if (requestedPath === "sw.js" && workerBuildRevisionOverride) {
        body = Buffer.from(body.toString("utf8").replace(
          /const BUILD_REVISION = "[^"]+";/,
          `const BUILD_REVISION = "${workerBuildRevisionOverride}";`,
        ));
      }
      response.writeHead(200, headers);
      response.end(body);
    } catch {
      response.writeHead(404).end();
    }
  });

  await new Promise<void>((resolveListening) => {
    server.listen(0, "127.0.0.1", resolveListening);
  });
  const address = server.address();
  if (!address || typeof address === "string") throw new Error("Subpath server did not bind.");
  mountedOrigin = `http://127.0.0.1:${address.port}`;
});

test.afterAll(async () => {
  await new Promise<void>((resolveClosed, reject) => {
    server.close((error) => error ? reject(error) : resolveClosed());
  });
});

test.afterEach(() => {
  failWithServiceUnavailable = false;
  failedAssetPath = null;
  rejectRuntimeCacheWrite = false;
  workerBuildRevisionOverride = null;
});

test("D01 · the production PWA remains installable and offline under a subpath", async ({
  context,
  page,
}) => {
  const initialResponse = await page.goto(`${mountedOrigin}${mountPath}?seed=4242`);
  expect(initialResponse?.headers()["cache-control"]).toBe("no-cache");
  await expect(page.getByTestId("intro")).toBeVisible();
  await expect(page.locator(".landscape__image")).toHaveAttribute(
    "src",
    "./assets/journey-scroll.jpg",
  );
  const landscapePreload = page.locator('link[rel="preload"][as="image"]');
  await expect(landscapePreload).toHaveAttribute("type", "image/jpeg");
  await expect(landscapePreload).toHaveAttribute("fetchpriority", "high");
  const landscapeUrl = await landscapePreload.evaluate((element) =>
    (element as HTMLLinkElement).href,
  );
  expect(new URL(landscapeUrl).pathname).toBe(`${mountPath}assets/journey-scroll.jpg`);
  expect((await context.request.get(landscapeUrl)).headers()["cache-control"]).toBe("no-cache");
  await expect.poll(() => page.evaluate(
    (url) => performance.getEntriesByName(url).length,
    landscapeUrl,
  )).toBe(1);

  const manifestPath = await page.locator('link[rel="manifest"]').evaluate((element) =>
    new URL((element as HTMLLinkElement).href).pathname,
  );
  expect(manifestPath).toBe(`${mountPath}manifest.webmanifest`);
  expect((await context.request.get(`${mountedOrigin}${manifestPath}`)).headers()["cache-control"])
    .toBe("no-cache");
  const manifest = await page.evaluate(async (path) => {
    const response = await fetch(path);
    return response.json() as Promise<{
      name: string;
      name_localized: Record<string, string>;
      short_name_localized: Record<string, string>;
      description_localized: Record<string, string>;
      lang: string;
      dir: string;
      icons: Array<{ src: string; sizes: string; purpose: string }>;
    }>;
  }, manifestPath);
  expect(manifest).toMatchObject({
    name: "山河有契：行旅之契",
    name_localized: { en: "Mountains & Rivers: Covenant of the Road" },
    short_name_localized: { en: "Covenant Road" },
    description_localized: {
      en: "A journey through mountains and rivers, written by your choices.",
    },
    lang: "zh-CN",
    dir: "ltr",
  });
  expect(manifest.icons).toEqual(expect.arrayContaining([
    expect.objectContaining({ src: "./icons/app-icon-512.png", purpose: "any" }),
    expect.objectContaining({
      src: "./icons/app-icon-maskable-512.png",
      sizes: "512x512",
      purpose: "maskable",
    }),
  ]));
  const touchIconPath = await page.locator('link[rel="apple-touch-icon"]').evaluate((element) =>
    new URL((element as HTMLLinkElement).href).pathname,
  );
  expect(touchIconPath).toBe(`${mountPath}icons/app-icon-maskable-512.png`);
  const touchIcon = await page.evaluate(async (path) => {
    const image = new Image();
    image.src = path;
    await image.decode();
    const canvas = document.createElement("canvas");
    canvas.width = image.naturalWidth;
    canvas.height = image.naturalHeight;
    const context = canvas.getContext("2d", { willReadFrequently: true })!;
    context.clearRect(0, 0, canvas.width, canvas.height);
    context.drawImage(image, 0, 0);
    const pixels = context.getImageData(0, 0, canvas.width, canvas.height).data;
    let minimumAlpha = 255;
    for (let index = 3; index < pixels.length; index += 4) {
      minimumAlpha = Math.min(minimumAlpha, pixels[index]!);
    }
    return { width: canvas.width, height: canvas.height, minimumAlpha };
  }, touchIconPath);
  expect(touchIcon).toEqual({ width: 512, height: 512, minimumAlpha: 255 });

  const hashedAssets = await page.locator('script[type="module"], link[rel="stylesheet"]')
    .evaluateAll((elements) => elements.map((element) =>
      element instanceof HTMLScriptElement ? element.src : (element as HTMLLinkElement).href
    ));
  expect(hashedAssets).toHaveLength(2);
  for (const assetUrl of hashedAssets) {
    expect((await context.request.get(assetUrl)).headers()["cache-control"])
      .toBe("public, max-age=31536000, immutable");
  }
  expect((await context.request.get(`${mountedOrigin}${mountPath}sw.js`))
    .headers()["cache-control"]).toBe("no-cache");

  const workerScope = await page.evaluate(async () => {
    const registration = await navigator.serviceWorker.ready;
    return registration.scope;
  });
  expect(new URL(workerScope).pathname).toBe(mountPath);
  preloadedNavigationRequests = 0;
  ordinaryNavigationRequests = 0;
  await page.reload();
  await expect.poll(() => page.evaluate(() => Boolean(navigator.serviceWorker.controller))).toBe(true);
  expect(await page.evaluate(async () => {
    const registration = await navigator.serviceWorker.ready;
    return registration.navigationPreload.getState();
  })).toMatchObject({ enabled: true });
  expect(preloadedNavigationRequests).toBe(1);
  expect(ordinaryNavigationRequests).toBe(0);
  rejectRuntimeCacheWrite = true;
  try {
    await page.reload();
  } finally {
    rejectRuntimeCacheWrite = false;
  }
  await expect(page.locator('meta[name="runtime-cache-write"]')).toHaveAttribute(
    "content",
    "network-response",
  );
  const scopedCachePrefix = `shan-he-you-qi-shell-${encodeURIComponent(mountPath)}-`;
  const foreignCacheName = `shan-he-you-qi-shell-${encodeURIComponent("/another-game/")}-v4-sentinel`;
  const staleScopedCacheName = `${scopedCachePrefix}v3-full-stale-sentinel`;
  await page.evaluate((name) => caches.open(name).then(() => undefined), foreignCacheName);
  await page.evaluate((name) => caches.open(name).then(() => undefined), staleScopedCacheName);

  await page.getByRole("button", { name: "启程" }).click();
  await page.locator(OPERABLE_CHOICE_SELECTOR).first().click();
  const reflection = await page.getByTestId("reflection").locator("h1").textContent();
  expect(new URL(page.url()).pathname).toBe(mountPath);

  await context.setOffline(true);
  await page.reload();
  await expect(page.getByTestId("reflection").locator("h1")).toHaveText(reflection ?? "");
  await expect(page.locator(".landscape__image")).toBeVisible();
  await context.setOffline(false);

  failWithServiceUnavailable = true;
  await page.reload();
  await expect(page.getByTestId("reflection").locator("h1")).toHaveText(reflection ?? "");
  failWithServiceUnavailable = false;

  workerBuildRevisionOverride = "d01-update";
  await page.evaluate(async () => {
    const registration = await navigator.serviceWorker.ready;
    await registration.update();
  });
  await expect(page.locator(".update-notice")).toBeVisible();
  await expect(page.locator(".update-notice")).toContainText("新版本已离线备妥");
  await page.evaluate(() => document.getAnimations().forEach((animation) => animation.finish()));
  expect((await new AxeBuilder({ page }).analyze()).violations).toEqual([]);
  await Promise.all([
    page.waitForEvent("framenavigated", (frame) => frame === page.mainFrame()),
    page.getByRole("button", { name: "重新载入更新" }).click(),
  ]);
  await page.waitForLoadState();
  await expect(page.getByTestId("reflection").locator("h1")).toHaveText(reflection ?? "");
  await expect.poll(async () => {
    const controller = await page.evaluate(() => navigator.serviceWorker.controller?.scriptURL ?? "");
    return new URL(controller).searchParams.get("revision");
  }).toBeNull();
  const cacheNames = await page.evaluate(() => caches.keys());
  expect(cacheNames).toContain(foreignCacheName);
  expect(cacheNames).not.toContain(staleScopedCacheName);
  expect(cacheNames.some((name) =>
    name.startsWith(`${scopedCachePrefix}v9-`) && name.endsWith("-full-d01-update")
  )).toBe(true);
});

test("D02 · a failed update preserves the active offline build and removes partial cache", async ({
  context,
  page,
}) => {
  await page.goto(`${mountedOrigin}${mountPath}?seed=4242`);
  await page.evaluate(() => navigator.serviceWorker.ready.then(() => undefined));
  await page.reload();
  await expect.poll(() => page.evaluate(() => Boolean(navigator.serviceWorker.controller))).toBe(true);
  await page.getByRole("button", { name: "启程" }).click();
  await page.locator(OPERABLE_CHOICE_SELECTOR).first().click();
  const reflection = await page.getByTestId("reflection").locator("h1").textContent();
  const activeBefore = await page.evaluate(async () => {
    const registration = await navigator.serviceWorker.ready;
    return registration.active!.scriptURL;
  });

  failedAssetPath = `${mountPath}icons/app-icon-maskable-512.png`;
  workerBuildRevisionOverride = "d02-broken";
  const failedState = await page.evaluate(async () => {
    const registration = await navigator.serviceWorker.ready;
    const state = new Promise<ServiceWorkerState>((resolveState) => {
      registration.addEventListener("updatefound", () => {
        const installing = registration.installing!;
        const report = () => {
          if (installing.state === "redundant") resolveState(installing.state);
        };
        installing.addEventListener("statechange", report);
        report();
      }, { once: true });
    });
    await registration.update();
    return state;
  });
  failedAssetPath = null;

  expect(failedState).toBe("redundant");
  await expect(page.locator(".update-notice")).toBeHidden();
  expect(await page.evaluate(() => navigator.serviceWorker.controller?.scriptURL)).toBe(activeBefore);
  const cacheNames = await page.evaluate(() => caches.keys());
  expect(cacheNames.some((name) => name.includes("d02-broken"))).toBe(false);

  await context.setOffline(true);
  await page.reload();
  await expect(page.getByTestId("reflection").locator("h1")).toHaveText(reflection ?? "");
  await context.setOffline(false);
});

test("D03 · online play remains complete when service workers are blocked", async ({ browser }) => {
  const context = await browser.newContext({ serviceWorkers: "block" });
  const page = await context.newPage();
  const pageErrors = observeRuntimeErrors(page);
  try {
    await page.goto(`${mountedOrigin}${mountPath}?seed=4242`);
    expect(await page.evaluate(() => navigator.serviceWorker.controller)).toBeNull();
    expect(await page.evaluate(() => caches.keys())).toEqual([]);

    await page.getByRole("button", { name: "启程" }).click();
    await page.locator(OPERABLE_CHOICE_SELECTOR).first().click();
    const firstReflection = await page.getByTestId("reflection").locator("h1").textContent();
    await page.reload();
    await expect(page.getByTestId("reflection").locator("h1")).toHaveText(firstReflection ?? "");
    expect(await page.evaluate(() => navigator.serviceWorker.controller)).toBeNull();

    for (let index = 1; index < 5; index += 1) {
      await page.getByRole("button", { name: /继续前行/ }).click();
      await page.locator(OPERABLE_CHOICE_SELECTOR).first().click();
    }
    await expect(page.locator("[data-ending='covenant']")).toBeVisible();
    await expect(page.locator(".journal li")).toHaveCount(5);
    expect(await page.evaluate(() => caches.keys())).toEqual([]);
    expect(pageErrors).toEqual([]);
  } finally {
    await context.close();
  }
});

test("D04 · an update activated in one tab safely interrupts every older tab", async ({ browser }) => {
  const context = await browser.newContext();
  const applyingPage = await context.newPage();
  const olderPage = await context.newPage();
  const applyingErrors = observeRuntimeErrors(applyingPage);
  const olderErrors = observeRuntimeErrors(olderPage);
  try {
    await applyingPage.goto(`${mountedOrigin}${mountPath}?seed=4242`);
    await applyingPage.evaluate(() => navigator.serviceWorker.ready.then(() => undefined));
    await applyingPage.reload();
    await expect.poll(() => applyingPage.evaluate(
      () => Boolean(navigator.serviceWorker.controller),
    )).toBe(true);
    await applyingPage.getByRole("button", { name: "启程" }).click();
    await applyingPage.locator(OPERABLE_CHOICE_SELECTOR).first().click();
    const reflection = await applyingPage.getByTestId("reflection").locator("h1").textContent();

    await olderPage.goto(`${mountedOrigin}${mountPath}`);
    await olderPage.evaluate(() => navigator.serviceWorker.ready.then(() => undefined));
    await olderPage.reload();
    await expect(olderPage.getByTestId("reflection").locator("h1")).toHaveText(reflection ?? "");
    await expect.poll(() => olderPage.evaluate(
      () => Boolean(navigator.serviceWorker.controller),
    )).toBe(true);

    workerBuildRevisionOverride = "d04-update";
    await applyingPage.evaluate(async () => {
      const registration = await navigator.serviceWorker.ready;
      await registration.update();
    });
    await expect(applyingPage.locator(".update-notice")).toBeVisible();
    await Promise.all([
      applyingPage.waitForEvent("framenavigated", (frame) => frame === applyingPage.mainFrame()),
      applyingPage.getByRole("button", { name: "重新载入更新" }).click(),
    ]);

    const dialog = olderPage.getByRole("alertdialog");
    await expect(dialog).toContainText("另一页已启用新版本");
    const reload = olderPage.getByRole("button", { name: "重新载入新版本" });
    await expect(reload).toBeFocused();
    await expect(olderPage.locator(".game-shell__session")).toHaveAttribute("inert", "");
    expect((await new AxeBuilder({ page: olderPage }).analyze()).violations).toEqual([]);

    await Promise.all([
      olderPage.waitForEvent("framenavigated", (frame) => frame === olderPage.mainFrame()),
      reload.click(),
    ]);
    await expect(olderPage.getByTestId("reflection").locator("h1")).toHaveText(reflection ?? "");
    expect((await olderPage.evaluate(() => navigator.serviceWorker.controller?.scriptURL ?? "")))
      .not.toContain("revision=");
    expect((await olderPage.evaluate(() => caches.keys())).some((name) =>
      name.endsWith("-full-d04-update")
    )).toBe(true);
    expect(applyingErrors).toEqual([]);
    expect(olderErrors).toEqual([]);
  } finally {
    await context.close();
  }
});

test("D05 · the production shell explains its JavaScript requirement", async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false });
  const page = await context.newPage();
  const pageErrors = observeRuntimeErrors(page);
  try {
    await page.setViewportSize({ width: 320, height: 720 });
    const response = await page.goto(`${mountedOrigin}${mountPath}`);
    expect(response?.status()).toBe(200);
    await expect(page.getByRole("heading", { name: "需要启用 JavaScript 才能开始行旅" }))
      .toBeVisible();
    await expect(page.locator('[lang="en"]')).toContainText("JavaScript is required to begin");
    await expect(page.locator("#app")).toBeEmpty();
    await expect(page.locator('link[rel="manifest"]')).toHaveAttribute(
      "href",
      "./manifest.webmanifest",
    );
    expect(await page.evaluate(() =>
      document.documentElement.scrollWidth <= document.documentElement.clientWidth
    )).toBe(true);
    expect(pageErrors).toEqual([]);
  } finally {
    await context.close();
  }
});
