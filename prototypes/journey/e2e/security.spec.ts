import { expect, OPERABLE_CHOICE_SELECTOR, test } from "./fixtures";

test("S01 · persisted narrative text remains inert", async ({ page }) => {
  await page.goto("/?seed=4242");
  await page.getByRole("button", { name: "启程" }).click();
  await page.locator(OPERABLE_CHOICE_SELECTOR).first().click();
  const payload = `</p><img data-injection src=x onerror="globalThis.__injected=true"><p>`;
  await page.evaluate((text) => {
    const key = "shan-he-you-qi:journey:v1";
    const state = JSON.parse(localStorage.getItem(key)!);
    state.journal[0].place.zh = text;
    state.journal[0].choice.zh = text;
    state.journal[0].aftermath.zh = text;
    localStorage.setItem(key, JSON.stringify(state));
  }, payload);

  await page.reload();

  await expect(page.getByTestId("reflection").locator(".lede")).toContainText(payload);
  await expect(page.locator("[data-injection]")).toHaveCount(0);
  expect(await page.evaluate(() => (globalThis as { __injected?: boolean }).__injected)).toBeUndefined();
});

test("S02 · the static shell blocks inline code and dynamic evaluation", async ({ page }) => {
  await page.goto("/?seed=4242");
  const policy = await page
    .locator('meta[http-equiv="Content-Security-Policy"]')
    .getAttribute("content");
  expect(policy).toContain("script-src 'self'");
  expect(policy).toContain("connect-src 'self'");
  expect(policy).toContain("base-uri 'none'");
  expect(policy).toContain("object-src 'none'");
  expect(policy).toContain("form-action 'none'");
  expect(policy).toContain("frame-src 'none'");
  expect(policy).not.toMatch(/(?:https?|wss?):/);
  expect(policy).not.toContain("unsafe-eval");
  expect(policy).not.toContain("unsafe-inline");
  await expect(page.locator("[style]")).toHaveCount(0);
  const baseUris = await page.evaluate(() => {
    const before = document.baseURI;
    const base = document.createElement("base");
    base.href = "/outside-the-game/";
    document.head.append(base);
    return { before, after: document.baseURI };
  });
  expect(baseUris.after).toBe(baseUris.before);
  await page.evaluate(() => {
    (globalThis as { __inlineExecuted?: boolean }).__inlineExecuted = false;
    const script = document.createElement("script");
    script.textContent = "globalThis.__inlineExecuted = true";
    document.body.append(script);
  });
  expect(
    await page.evaluate(() => (globalThis as { __inlineExecuted?: boolean }).__inlineExecuted),
  ).toBe(false);
  expect(await page.evaluate(() => {
    const style = document.createElement("style");
    style.textContent = "body { border-top: 99px solid red !important; }";
    document.head.append(style);
    return getComputedStyle(document.body).borderTopWidth;
  })).not.toBe("99px");
  expect(
    await page.evaluate(async () => {
      (globalThis as { __timerExecuted?: boolean }).__timerExecuted = false;
      setTimeout("globalThis.__timerExecuted = true", 0);
      await new Promise((resolve) => setTimeout(resolve, 20));
      return (globalThis as { __timerExecuted?: boolean }).__timerExecuted;
    }),
  ).toBe(false);

  await page.getByRole("button", { name: "启程" }).click();
  await expect(page.getByTestId("encounter")).toBeVisible();
});

test("S03 · a complete feature session stays inside the documented local boundary", async ({
  context,
  page,
}) => {
  const requests: string[] = [];
  const failedRequests: string[] = [];
  const errorResponses: string[] = [];
  const consoleErrors: string[] = [];
  page.on("request", (request) => requests.push(request.url()));
  page.on("requestfailed", (request) => failedRequests.push(request.url()));
  page.on("console", (message) => {
    if (message.type() === "error") consoleErrors.push(message.text());
  });
  page.on("response", (response) => {
    if (response.status() >= 400) errorResponses.push(`${response.status()} ${response.url()}`);
  });
  await page.addInitScript(() => {
    (globalThis as { __policyViolations?: unknown[] }).__policyViolations = [];
    addEventListener("securitypolicyviolation", (event) => {
      (globalThis as { __policyViolations?: unknown[] }).__policyViolations!.push({
        blockedURI: event.blockedURI,
        directive: event.effectiveDirective,
      });
    });
    HTMLMediaElement.prototype.play = () => Promise.resolve();
    HTMLMediaElement.prototype.pause = () => undefined;
  });

  await page.goto("/?seed=4242");
  const origin = new URL(page.url()).origin;
  await page.evaluate(() => navigator.serviceWorker.ready.then(() => undefined));
  await page.locator(".preferences summary").click();
  await page.locator('[data-preference="contrast"][value="high"]').check();
  await page.locator("[data-audio-volume]").fill("0.4");
  await page.getByRole("button", { name: "开启环境音" }).click();
  await expect(page.getByRole("button", { name: "关闭环境音" })).toHaveAttribute(
    "aria-pressed",
    "true",
  );

  await page.getByRole("button", { name: "启程" }).click();
  for (let index = 0; index < 5; index += 1) {
    await page.locator(OPERABLE_CHOICE_SELECTOR).first().click();
    if (index < 4) await page.getByRole("button", { name: /继续前行/ }).click();
  }
  const downloadPromise = page.waitForEvent("download");
  await page.getByRole("button", { name: "下载行旅文本" }).click();
  await downloadPromise;

  const networkOrigins = requests.flatMap((value) => {
    const url = new URL(value);
    return url.protocol === "http:" || url.protocol === "https:" ? [url.origin] : [];
  });
  expect(new Set(networkOrigins)).toEqual(new Set([origin]));
  expect(failedRequests).toEqual([]);
  expect(errorResponses).toEqual([]);
  expect(consoleErrors).toEqual([]);
  expect(await page.evaluate(() =>
    (globalThis as { __policyViolations?: unknown[] }).__policyViolations
  )).toEqual([]);
  expect(await page.evaluate(() => document.cookie)).toBe("");
  expect(await context.cookies(origin)).toEqual([]);
  expect(await page.evaluate(() => sessionStorage.length)).toBe(0);
  expect(await page.evaluate(async () =>
    typeof indexedDB.databases === "function"
      ? (await indexedDB.databases()).map((database) => database.name)
      : []
  )).toEqual([]);
  const cachedShell = await page.evaluate(async () => {
    const names = await caches.keys();
    const urls = (await Promise.all(names.map(async (name) =>
      (await caches.open(name)).keys().then((requests) => requests.map((request) => request.url))
    ))).flat();
    return { names, urls };
  });
  expect(cachedShell.names).toHaveLength(1);
  expect(cachedShell.names[0]).toMatch(/^shan-he-you-qi-shell-.*-v9-[a-z0-9]+-full-/);
  expect(cachedShell.urls).toHaveLength(10);
  for (const value of cachedShell.urls) {
    const url = new URL(value);
    expect(url.origin).toBe(origin);
    expect(url.search).toBe("");
    expect(url.hash).toBe("");
  }
  expect(await page.evaluate(() => Object.keys(localStorage).sort())).toEqual([
    "shan-he-you-qi:audio:v1",
    "shan-he-you-qi:chronicle:v1",
    "shan-he-you-qi:journey:v1",
    "shan-he-you-qi:preferences:v1",
  ]);
});
