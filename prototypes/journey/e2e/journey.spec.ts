import { expect, OPERABLE_CHOICE_SELECTOR, test, type Page } from "./fixtures";
import { readFile } from "node:fs/promises";

const start = async (page: Page, seed = 4242): Promise<void> => {
  await page.goto(`/?seed=${seed}`);
  await page.getByRole("button", { name: "启程" }).click();
};

const chooseFirst = async (page: Page): Promise<void> => {
  await page.locator(OPERABLE_CHOICE_SELECTOR).first().click();
};

const continueOnward = async (page: Page): Promise<void> => {
  await page.getByRole("button", { name: /继续前行/ }).click();
};

const reachCovenant = async (page: Page): Promise<void> => {
  await start(page);
  for (let index = 0; index < 5; index += 1) {
    await chooseFirst(page);
    if (index < 4) await continueOnward(page);
  }
  await expect(page.locator("[data-ending='covenant']")).toBeVisible();
};

const playSequence = async (page: Page, choices: readonly number[]): Promise<void> => {
  await start(page);
  for (let index = 0; index < choices.length; index += 1) {
    await page.locator("[data-choice]").nth(choices[index]!).click();
    if (index < choices.length - 1) await continueOnward(page);
  }
};

test("J01 · a first journey enters the opening encounter", async ({ page }) => {
  await start(page);
  await expect(page.getByTestId("encounter")).toBeVisible();
  await expect(page.locator(".route-stop--current")).toContainText("芦渡");
  await expect(page.locator("[data-choice]")).toHaveCount(2);
});

test("J02 · promise-keeping choices reach the covenant ending", async ({ page }) => {
  await reachCovenant(page);
  await expect(page.getByTestId("ending")).toContainText("山河有应");
  await expect(page.locator(".journal li")).toHaveCount(5);
  await expect(page.locator(".journal li em")).toHaveCount(5);
  await expect(page.locator(".journal li em").first()).toContainText("信义 +2");
  await expect(page.locator(".journal li p")).toHaveCount(5);
  await expect(page.locator(".journal li p").first()).toContainText("新缆绷紧时");
});

test("J03 · costly solitary choices reach the authored lost ending", async ({ page }) => {
  await start(page, 77);
  for (let index = 0; index < 3; index += 1) {
    await page.locator("[data-choice]").nth(1).click();
    if (index < 2) await continueOnward(page);
  }
  await expect(page.locator("[data-ending='lost']")).toBeVisible();
  await expect(page.locator("[data-stat='provisions'] dd")).toHaveText("0");
  await expect(page.locator(".chronicle summary")).toContainText("遭遇 3/10");
  await page.locator(".chronicle summary").click();
  await expect(page.locator(".chronicle__encounter--known")).toHaveCount(3);
});

test("J04 · replay preserves the seed and resets the journal", async ({ page }) => {
  await reachCovenant(page);
  const seed = await page.locator(".seed").textContent();
  const firstDecision = await page.locator(".journal li strong").first().textContent();
  await page.getByRole("button", { name: "循原路再走一次" }).click();
  await expect(page.getByTestId("encounter")).toBeVisible();
  await expect(page.locator(".seed")).toHaveText(seed ?? "");
  await expect(
    page.locator("[data-choice]").filter({ hasText: firstDecision ?? "" }),
  ).toHaveCount(1);
  await expect(page.locator(".journal summary")).toContainText("0/5");
});

test("J05 · a new route changes the seed and returns to the intro", async ({ page }) => {
  await reachCovenant(page);
  const seed = await page.locator(".seed").textContent();
  await page.getByRole("button", { name: "换一张旅签" }).click();
  await expect(page.getByTestId("intro")).toBeVisible();
  await expect(page.locator(".seed")).not.toHaveText(seed ?? "");
  await expect(page.locator(".journal summary")).toContainText("0/5");
  const currentSeed = (await page.locator(".seed").textContent())?.match(/\d+/)?.[0];
  expect(new URL(page.url()).searchParams.get("seed")).toBe(currentSeed);
  expect(new URL(page.url()).searchParams.get("route")?.split(",")).toHaveLength(5);
});

test("J06 · refresh resumes the current scene and stats", async ({ page }) => {
  await start(page);
  await chooseFirst(page);
  await expect(page.locator(".journal summary")).toContainText("1/5");
  const title = await page.getByTestId("reflection").locator("h1").textContent();
  await page.reload();
  await expect(page.getByTestId("reflection").locator("h1")).toHaveText(title ?? "");
  await expect(page.locator(".journal summary")).toContainText("1/5");
  await continueOnward(page);
  await expect(page.getByTestId("encounter")).toBeVisible();
});

test("J07 · language and numeric keyboard controls work", async ({ page }) => {
  await page.goto("/?seed=4242");
  await page.keyboard.press("Tab");
  await expect(page.getByRole("link", { name: "跳到行旅正文" })).toBeFocused();
  await page.keyboard.press("Enter");
  await expect(page.getByTestId("intro").locator("h1")).toBeFocused();
  await page.locator(".preferences summary").click();
  await page.getByRole("radio", { name: "标准" }).focus();
  await page.keyboard.press("l");
  await expect(page.getByRole("button", { name: "启程" })).toBeVisible();
  const englishSwitch = page.getByRole("button", { name: "Switch to English" });
  await expect(englishSwitch).toHaveAttribute("lang", "en");
  await englishSwitch.focus();
  await page.keyboard.press("l");
  await expect(page.getByRole("button", { name: "启程" })).toBeVisible();
  await page.locator(".story h1").focus();
  await page.keyboard.press("l");
  await expect(page.getByRole("button", { name: "Begin journey" })).toBeVisible();
  await expect(page.getByRole("button", { name: "切换到中文" })).toHaveAttribute("lang", "zh-CN");
  const localizedUrl = new URL(page.url());
  expect(localizedUrl.searchParams.get("lang")).toBe("en");
  expect(localizedUrl.searchParams.get("route")?.split(",")).toHaveLength(5);
  await page.getByRole("button", { name: "Begin journey" }).click();
  await expect(page.locator(".story h1")).toBeFocused();
  const firstDecision = await page.locator("[data-choice]").first().textContent();
  await page.keyboard.press("1");
  await expect(page.getByTestId("reflection")).toBeVisible();
  await expect(page.locator(".story h1")).toBeFocused();
  await page.keyboard.press("Enter");
  await expect(page.locator(".story h1")).toBeFocused();
  await expect(page.locator(".journal summary")).toContainText("1/5");
  await expect(page.locator("html")).toHaveAttribute("lang", "en");
  await expect(page).toHaveTitle("Covenant of the Road · Mountains & Rivers");
  await expect(page.locator('meta[name="description"]')).toHaveAttribute(
    "content",
    "A journey through mountains and rivers, written by your choices.",
  );
  await page.reload();
  await expect(page.locator("html")).toHaveAttribute("lang", "en");
  await expect(page).toHaveTitle("Covenant of the Road · Mountains & Rivers");
  await expect(page.locator(".journal summary")).toContainText("1/5");
  await page.evaluate(() => localStorage.clear());
  await page.goto(localizedUrl.href);
  await expect(page.getByRole("button", { name: "Begin journey" })).toBeVisible();
  await page.getByRole("button", { name: "Begin journey" }).click();
  await expect(page.locator("[data-choice]").first()).toContainText(firstDecision ?? "");
});

test("J09 · a choice reveals authored aftermath before the next encounter", async ({ page }) => {
  await start(page, 4242);
  await chooseFirst(page);
  await expect(page.getByTestId("reflection")).toContainText("新缆绷紧时");
  await expect(page.locator("[data-stat='trust'] dd")).toHaveText("2");
  await continueOnward(page);
  await expect(page.locator(".route-stop--current")).toContainText("松岭");
});

test("J10 · a provision-aware route reaches the homeward ending", async ({ page }) => {
  await playSequence(page, [0, 1, 0, 1, 1]);
  await expect(page.locator("[data-ending='homeward']")).toBeVisible();
  await expect(page.getByTestId("ending")).toContainText("灯火可亲");
});

test("J11 · a lean independent route reaches the wanderer ending", async ({ page }) => {
  await playSequence(page, [0, 0, 1, 1, 1]);
  await expect(page.locator("[data-ending='wanderer']")).toBeVisible();
  await expect(page.getByTestId("ending")).toContainText("路仍在前");
});

test("J12 · the chronicle persists a unique discovered ending", async ({ page }) => {
  await reachCovenant(page);
  await expect(page.locator(".chronicle summary")).toContainText("1/4");
  await page.locator(".chronicle summary").click();
  await expect(page.locator(".chronicle__ending--known")).toContainText("山河有应");
  await page.reload();
  await expect(page.locator(".chronicle summary")).toContainText("1/4");
  await expect(page.locator(".chronicle p").first()).toHaveText("所录行路 · 1");
});

test("J13 · a completed journey can be copied as a self-contained summary", async ({ context, page }) => {
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
  await page.addInitScript(() => {
    Object.defineProperty(navigator, "share", {
      configurable: true,
      value: async (data: ShareData) => {
        localStorage.setItem("shan-he-you-qi:test-native-share", JSON.stringify(data));
      },
    });
  });
  await reachCovenant(page);
  const firstDecision = await page.locator(".journal li strong").first().textContent();
  const summary = page.getByLabel("可复制的行旅摘要");
  await expect(summary).toContainText("结局：守契 · 山河有应");
  await expect(summary).toContainText("旅签：4242");
  await expect(summary).toContainText("同路旅签：");
  await expect(summary).toContainText("?seed=4242");
  await expect(summary).toContainText("新缆绷紧时");
  await expect(summary).toContainText("盘缠 -1 · 信义 +2 · 见闻 +1");
  await page.getByRole("button", { name: "抄录行旅" }).click();
  await expect(page.getByRole("status")).toContainText("已抄录");
  await expect.poll(() => page.evaluate(() => navigator.clipboard.readText())).toContain("新缆绷紧时");
  await page.getByRole("button", { name: "用系统分享" }).click();
  await expect(page.getByRole("status")).toContainText("已交给系统分享");
  const nativeShare = await page.evaluate(() =>
    JSON.parse(localStorage.getItem("shan-he-you-qi:test-native-share") ?? "null") as {
      title: string;
      text: string;
    },
  );
  expect(nativeShare.title).toBe("行旅之契 · 山河有契");
  expect(nativeShare.text).toContain("新缆绷紧时");
  const nativeReplayUrl = nativeShare.text.match(/同路旅签：(https?:\/\/\S+)/)?.[1];
  expect(nativeReplayUrl).toBeTruthy();
  expect(new URL(nativeReplayUrl!).searchParams.get("seed")).toBe("4242");
  expect(new URL(nativeReplayUrl!).searchParams.get("replay")).toBe("1");
  expect(new URL(nativeReplayUrl!).searchParams.get("route")?.split(",")).toHaveLength(5);
  const copied = await page.evaluate(() => navigator.clipboard.readText());
  const replayUrl = copied.match(/同路旅签：(https?:\/\/\S+)/)?.[1];
  expect(replayUrl).toBeTruthy();
  expect(new URL(replayUrl!).searchParams.get("route")?.split(",")).toHaveLength(5);
  await page.goto(replayUrl!);
  await expect(page.locator(".seed")).toContainText("4242");
  expect(new URL(page.url()).searchParams.get("replay")).toBeNull();
  expect(new URL(page.url()).searchParams.get("route")?.split(",")).toHaveLength(5);
  await page.getByRole("button", { name: "启程" }).click();
  await expect(page.locator("[data-choice]").first()).toContainText(firstDecision ?? "");
  await chooseFirst(page);
  const reflection = await page.getByTestId("reflection").locator("h1").textContent();
  await page.reload();
  await expect(page.getByTestId("reflection").locator("h1")).toHaveText(reflection ?? "");
});

test("J14 · reading preferences apply immediately and persist across reload", async ({ page }) => {
  await page.goto("/?seed=4242");
  const title = page.getByTestId("intro").locator("h1");
  const defaultSize = await title.evaluate((element) => Number.parseFloat(getComputedStyle(element).fontSize));

  await page.locator(".preferences summary").click();
  await page.getByRole("radio", { name: "放大" }).check();
  await page.getByRole("radio", { name: "减少动态" }).check();
  await page.getByRole("radio", { name: "高对比" }).check();

  const app = page.locator("#app");
  await expect(app).toHaveAttribute("data-text-scale", "large");
  await expect(app).toHaveAttribute("data-motion", "reduced");
  await expect(app).toHaveAttribute("data-contrast", "high");
  await expect.poll(() => title.evaluate((element) => Number.parseFloat(getComputedStyle(element).fontSize))).toBeGreaterThan(defaultSize);
  await expect.poll(() => page.locator(".story").evaluate((element) => Number.parseFloat(getComputedStyle(element).animationDuration))).toBeLessThanOrEqual(0.00001);
  await expect.poll(() => app.evaluate((element) => getComputedStyle(element).getPropertyValue("--ink").trim())).toBe("#090b08");

  await page.reload();
  await expect(app).toHaveAttribute("data-text-scale", "large");
  await expect(app).toHaveAttribute("data-motion", "reduced");
  await expect(app).toHaveAttribute("data-contrast", "high");
  await page.locator(".preferences summary").click();
  await expect(page.getByRole("radio", { name: "放大" })).toBeChecked();
  await expect(page.getByRole("radio", { name: "减少动态" })).toBeChecked();
  await expect(page.getByRole("radio", { name: "高对比" })).toBeChecked();
});

test("J15 · the installed shell resumes a saved journey while offline", async ({ context, page }) => {
  await page.goto("/?seed=4242");
  const manifest = await page.evaluate(async () => {
    const href = document.querySelector<HTMLLinkElement>('link[rel="manifest"]')!.href;
    return (await fetch(href)).json() as Promise<{ name: string; icons: { sizes: string }[] }>;
  });
  expect(manifest.name).toBe("山河有契：行旅之契");
  expect(manifest.icons.map((icon) => icon.sizes)).toEqual(expect.arrayContaining(["192x192", "512x512"]));

  await page.evaluate(() => navigator.serviceWorker.ready.then(() => undefined));
  await page.reload();
  await expect.poll(() => page.evaluate(() => Boolean(navigator.serviceWorker.controller))).toBe(true);
  const worker = await page.evaluate(async () => {
    const registration = await navigator.serviceWorker.ready;
    const activeUrl = new URL(registration.active!.scriptURL);
    const workerSource = await fetch(activeUrl).then((response) => response.text());
    const releaseRevision = workerSource.match(
      /const BUILD_REVISION = "(shell-[a-f0-9]{16})";/,
    )?.[1];
    const publicRevision = document.querySelector<HTMLMetaElement>(
      'meta[name="public-asset-revision"]',
    )!.content;
    return {
      revision: activeUrl.searchParams.get("revision"),
      expectedRevision: releaseRevision,
      publicRevision,
      cacheNames: await caches.keys(),
    };
  });
  expect(worker.publicRevision).toMatch(/^[a-f0-9]{12}$/);
  expect(worker.revision).toBeNull();
  expect(worker.expectedRevision).toMatch(/^shell-[a-f0-9]{16}$/);
  expect(worker.cacheNames.some((name) =>
    name.startsWith(`shan-he-you-qi-shell-${encodeURIComponent("/")}-v9-`) &&
    name.endsWith(`-full-${worker.expectedRevision!.replace(/[^A-Za-z0-9_-]/g, "-")}`)
  )).toBe(true);
  const cachedHomeRequests = await page.evaluate(async (revision) => {
    const suffix = `-full-${revision!.replace(/[^A-Za-z0-9_-]/g, "-")}`;
    const name = (await caches.keys()).find((candidate) =>
      candidate.includes("-v9-") && candidate.endsWith(suffix)
    );
    if (!name) return [];
    return (await (await caches.open(name)).keys())
      .map((request) => request.url)
      .filter((url) => new URL(url).pathname === "/");
  }, worker.expectedRevision!);
  expect(cachedHomeRequests).toEqual([new URL("/", page.url()).href]);
  await page.getByRole("button", { name: "启程" }).click();
  const firstDecision = await page.locator("[data-choice]").first().textContent();
  await chooseFirst(page);
  const reflection = await page.getByTestId("reflection").locator("h1").textContent();
  const route = await page.evaluate(() =>
    JSON.parse(localStorage.getItem("shan-he-you-qi:journey:v1")!).route as string[],
  );

  await context.setOffline(true);
  await page.reload();
  await expect(page.getByTestId("reflection").locator("h1")).toHaveText(reflection ?? "");
  await expect(page.locator(".journal summary")).toContainText("1/5");
  await expect(page.locator(".landscape__image")).toBeVisible();
  await expect(page.locator(".landscape__image")).toHaveAttribute(
    "src",
    "./assets/journey-scroll.jpg",
  );
  await page.goto(
    `/?seed=4242&replay=1&route=${encodeURIComponent(route.join(","))}`,
  );
  await expect(page.getByTestId("intro")).toBeVisible();
  expect(new URL(page.url()).searchParams.get("replay")).toBeNull();
  await page.getByRole("button", { name: "启程" }).click();
  await expect(page.locator("[data-choice]").first()).toContainText(firstDecision ?? "");
  await context.setOffline(false);
});

test("J16 · ambience starts only by choice and keeps mute and volume settings", async ({ page }) => {
  await page.goto("/?seed=4242");
  await page.locator(".preferences summary").click();
  const audioToggle = page.getByRole("button", { name: "开启环境音" });
  await expect(audioToggle).toHaveAttribute("aria-pressed", "false");
  await audioToggle.click();
  await expect(page.getByRole("button", { name: "关闭环境音" })).toHaveAttribute("aria-pressed", "true");

  const mute = page.getByRole("button", { name: "静音", exact: true });
  await mute.click();
  await expect(page.getByRole("button", { name: "取消静音" })).toHaveAttribute("aria-pressed", "true");
  const volume = page.locator("[data-audio-volume]");
  await volume.fill("0.65");
  await expect(page.locator(".ambient output")).toHaveText("65%");

  await page.getByRole("button", { name: "关闭环境音" }).click();
  await expect(page.getByRole("button", { name: "开启环境音" })).toHaveAttribute("aria-pressed", "false");
  await page.reload();
  await page.locator(".preferences summary").click();
  await expect(page.getByRole("button", { name: "开启环境音" })).toHaveAttribute("aria-pressed", "false");
  await expect(page.getByRole("button", { name: "取消静音" })).toHaveAttribute("aria-pressed", "true");
  await expect(volume).toHaveValue("0.65");
});

test("J17 · the same route echoes an earlier choice in later prose", async ({ page }) => {
  await start(page, 4242);
  await page.locator("[data-choice]").first().click();
  await page.reload();
  await continueOnward(page);
  const firstEcho = await page.getByTestId("callback").textContent();
  expect(firstEcho).toBeTruthy();

  await page.evaluate(() => localStorage.clear());
  await page.goto("/?seed=4242");
  await page.getByRole("button", { name: "启程" }).click();
  await page.locator("[data-choice]").nth(1).click();
  await continueOnward(page);
  const secondEcho = await page.getByTestId("callback").textContent();
  expect(secondEcho).toBeTruthy();
  expect(secondEcho).not.toBe(firstEcho);
});

test("J18 · a validated backup restores local progress after storage loss", async ({ page }) => {
  await reachCovenant(page);
  await page.getByRole("button", { name: "循原路再走一次" }).click();
  await chooseFirst(page);
  const reflection = await page.getByTestId("reflection").locator("h1").textContent();

  await page.locator(".preferences summary").click();
  await page.getByRole("radio", { name: "高对比" }).check();
  await page.getByRole("button", { name: "静音", exact: true }).click();
  await page.locator("[data-audio-volume]").fill("0.65");
  const downloadPromise = page.waitForEvent("download");
  await page.getByRole("button", { name: "导出进度" }).click();
  const download = await downloadPromise;
  expect(download.suggestedFilename()).toMatch(
    /^shan-he-you-qi-save-\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}-\d{3}Z\.json$/,
  );
  const backupPath = await download.path();
  expect(backupPath).not.toBeNull();

  await page.evaluate(() => localStorage.clear());
  await page.reload();
  await expect(page.getByTestId("intro")).toBeVisible();
  await expect(page.locator(".chronicle summary")).toContainText("0/4");

  await page.locator(".preferences summary").click();
  await page.locator("[data-backup-file]").setInputFiles(backupPath!);
  await expect(page.locator(".backup__status")).toContainText("备份有效");
  await page.locator('[data-action="language"]').click();
  await expect(page.locator(".backup__status")).toBeEmpty();
  await page.locator(".preferences summary").click();
  await expect(page.locator('[data-action="backup-restore"]')).toBeDisabled();
  await page.locator("[data-backup-file]").setInputFiles(backupPath!);
  await expect(page.locator(".backup__status")).toContainText("Backup validated");
  await page.locator('[data-action="backup-restore"]').click();

  await expect(page.getByTestId("reflection").locator("h1")).toHaveText(reflection ?? "");
  await expect(page.locator(".journal summary")).toContainText("1/5");
  await expect(page.locator(".chronicle summary")).toContainText("1/4");
  await expect(page.locator("#app")).toHaveAttribute("data-contrast", "high");
  await page.locator(".preferences summary").click();
  await expect(page.getByRole("button", { name: "取消静音" })).toHaveAttribute("aria-pressed", "true");
  await expect(page.locator("[data-audio-volume]")).toHaveValue("0.65");
  await expect(page.getByRole("button", { name: "开启环境音" })).toHaveAttribute("aria-pressed", "false");
});

test("J19 · a complete journey remains playable when browser storage is denied", async ({ page }) => {
  await page.addInitScript(() => {
    const deny = (): never => {
      throw new DOMException("Storage denied for test", "SecurityError");
    };
    Storage.prototype.getItem = deny;
    Storage.prototype.setItem = deny;
    Storage.prototype.removeItem = deny;
  });
  await page.goto("/?seed=4242");
  await expect(page.locator(".persistence-notice")).toBeVisible();
  await expect(page.locator(".persistence-notice")).toContainText("刷新后不会保留");
  await page.locator(".preferences summary").click();
  await expect(page.locator("[data-backup-file]")).toBeDisabled();
  await expect(page.locator(".backup__status")).toContainText("无法恢复备份");

  await page.getByRole("button", { name: "启程" }).click();
  for (let index = 0; index < 5; index += 1) {
    await chooseFirst(page);
    if (index < 4) await continueOnward(page);
  }

  await expect(page.locator("[data-ending='covenant']")).toBeVisible();
  await expect(page.locator(".journal li")).toHaveCount(5);
  await expect(page.locator(".persistence-notice")).toBeVisible();
  await page.locator(".preferences summary").click();
  const downloadPromise = page.waitForEvent("download");
  await page.getByRole("button", { name: "导出进度" }).click();
  const download = await downloadPromise;
  const backupPath = await download.path();
  expect(backupPath).not.toBeNull();
  const backup = JSON.parse(await readFile(backupPath!, "utf8")) as {
    journey: { phase: string; journal: unknown[] };
    chronicle: { journeys: unknown[] };
  };
  expect(backup.journey.phase).toBe("ended");
  expect(backup.journey.journal).toHaveLength(5);
  expect(backup.chronicle.journeys).toHaveLength(1);
});

test("J20 · an impossible saved phase is discarded before rendering", async ({ page }) => {
  await page.goto("/?seed=4242");
  await page.getByRole("button", { name: "启程" }).click();
  await page.evaluate(() => {
    const key = "shan-he-you-qi:journey:v1";
    const state = JSON.parse(localStorage.getItem(key)!);
    state.phase = "reflection";
    state.sceneIndex = 0;
    state.journal = [];
    localStorage.setItem(key, JSON.stringify(state));
  });

  await page.reload();

  await expect(page.getByTestId("intro")).toBeVisible();
  expect(await page.evaluate(() => localStorage.getItem("shan-he-you-qi:journey:v1"))).toBeNull();
  await page.getByRole("button", { name: "启程" }).click();
  await expect(page.getByTestId("encounter")).toBeVisible();
});

test("J21 · local data clearing requires confirmation and resets every record", async ({ page }) => {
  await reachCovenant(page);
  await page.locator(".preferences summary").click();
  await page.getByRole("radio", { name: "高对比" }).check();
  await page.getByRole("button", { name: "静音" }).click();
  await page.getByRole("button", { name: "清除本地数据" }).click();

  await expect(page.locator(".backup__status")).toContainText("永久删除");
  await expect(page.getByTestId("ending")).toBeVisible();
  const recordsBefore = await page.evaluate(() => [
    "shan-he-you-qi:journey:v1",
    "shan-he-you-qi:chronicle:v1",
    "shan-he-you-qi:preferences:v1",
    "shan-he-you-qi:audio:v1",
  ].map((key) => localStorage.getItem(key)));
  expect(recordsBefore.every((record) => record !== null)).toBe(true);

  await page.locator(".journal summary").click();
  await expect(page.locator(".backup__status")).toBeEmpty();
  await expect(page.getByRole("button", { name: "清除本地数据" })).toBeVisible();
  await page.getByRole("button", { name: "清除本地数据" }).click();
  await page.getByRole("radio", { name: "减少动态" }).check();
  await expect(page.locator(".backup__status")).toBeEmpty();
  await page.getByRole("button", { name: "清除本地数据" }).click();

  await page.getByRole("button", { name: "确认清除全部数据" }).click();
  await expect(page.getByTestId("intro")).toBeVisible();
  await expect(page.locator(".chronicle summary")).toContainText("0/4");
  await page.locator(".preferences summary").click();
  await expect(page.getByRole("radio", { name: "标准" })).toBeChecked();
  await expect(page.getByRole("radio", { name: "跟随系统" }).first()).toBeChecked();
  const recordsAfter = await page.evaluate(() => [
    "shan-he-you-qi:journey:v1",
    "shan-he-you-qi:chronicle:v1",
    "shan-he-you-qi:preferences:v1",
    "shan-he-you-qi:audio:v1",
  ].map((key) => localStorage.getItem(key)));
  expect(recordsAfter).toEqual([null, null, null, null]);
});

test("J22 · the chronicle reopens an exact recent route", async ({ page }) => {
  await reachCovenant(page);
  const firstDecision = await page.locator(".journal li strong").first().textContent();
  await page.getByRole("button", { name: "换一张旅签" }).click();
  await page.getByRole("button", { name: "启程" }).click();
  for (let index = 0; index < 5; index += 1) {
    await chooseFirst(page);
    if (index < 4) await continueOnward(page);
  }

  await expect(page.locator(".chronicle p").first()).toContainText("2");
  await page.getByRole("button", { name: "循原路再走一次" }).click();
  await chooseFirst(page);
  const interruptedSeed = await page.locator(".seed").textContent();
  await page.locator(".chronicle summary").click();
  await expect(page.locator(".chronicle__journeys button")).toHaveCount(2);
  const recalled = page.locator('[data-action="chronicle-replay"]').filter({ hasText: "旅签 4242" });
  await recalled.click();
  await expect(page.getByTestId("reflection")).toBeVisible();
  await expect(page.locator(".seed")).toHaveText(interruptedSeed ?? "");
  await expect(page.locator(".chronicle__status")).toContainText("未竟旅程");
  await page.locator(".preferences summary").click();
  await expect(page.locator(".chronicle__status")).toBeEmpty();
  await recalled.click();
  await expect(page.locator(".chronicle__status")).toContainText("未竟旅程");
  await recalled.click();

  await expect(page.getByTestId("encounter")).toBeVisible();
  await expect(page.locator(".seed")).toContainText("4242");
  await expect(page.locator("[data-choice]").first()).toContainText(firstDecision ?? "");
  await expect(page.locator(".chronicle p").first()).toContainText("2");
  const recalledUrl = new URL(page.url());
  expect(recalledUrl.searchParams.get("seed")).toBe("4242");
  expect(recalledUrl.searchParams.get("route")?.split(",")).toHaveLength(5);
});

test("J23 · another tab cannot be silently overwritten by stale play", async ({ context, page }) => {
  await page.addInitScript(() => {
    let pauseCalls = 0;
    Object.defineProperties(HTMLMediaElement.prototype, {
      play: { configurable: true, value: () => Promise.resolve() },
      pause: {
        configurable: true,
        value: () => { pauseCalls += 1; },
      },
    });
    Object.assign(window, { __testPauseCalls: () => pauseCalls });
  });
  await start(page);
  await chooseFirst(page);
  await expect(page.getByTestId("reflection")).toBeVisible();
  await page.locator(".preferences summary").click();
  await page.getByRole("button", { name: "开启环境音" }).click();
  await expect(page.locator('[data-action="audio"]')).toHaveAttribute("aria-pressed", "true");

  const newerTab = await context.newPage();
  await newerTab.goto("/");
  await expect(newerTab.getByTestId("reflection")).toBeVisible();
  await continueOnward(newerTab);
  await expect(newerTab.getByTestId("encounter")).toBeVisible();

  const conflict = page.getByRole("alertdialog");
  await expect(conflict).toContainText("另一页已更新这段行旅");
  await expect(page.locator(".game-shell__session")).toHaveAttribute("inert", "");
  await expect(page.locator('[data-action="audio"]')).toHaveAttribute("aria-pressed", "false");
  expect(await page.evaluate(() =>
    (window as unknown as { __testPauseCalls(): number }).__testPauseCalls()
  )).toBeGreaterThanOrEqual(1);
  const reload = page.getByRole("button", { name: "载入最新进度" });
  await expect(reload).toBeFocused();
  await reload.click();

  await expect(page.getByTestId("encounter")).toBeVisible();
  await expect(page.locator(".route-stop--current")).toContainText("松岭");
  await expect(page.locator(".journal summary")).toContainText("1/5");
  await newerTab.close();
});

test("J24 · earlier trust visibly unlocks a gated response", async ({ page }) => {
  const route = "ferry-rope,ridge-bell,marsh-marker,city-well,gate-storm";
  const routeUrl = `/?seed=4242&replay=1&route=${route}`;

  await page.goto(routeUrl);
  await page.getByRole("button", { name: "启程" }).click();
  await page.locator('[data-choice="hire-skiff"]').click();
  await continueOnward(page);
  await page.locator('[data-choice="mark-path"]').click();
  await continueOnward(page);

  const gated = page.locator('[data-choice="raise-marker"]');
  await expect(gated).toBeDisabled();
  await expect(gated).toHaveAttribute("aria-disabled", "true");
  await expect(gated).toContainText("尚需 信义 2");
  const fallback = page.locator('[data-choice="force-causeway"]');
  await expect(fallback).toBeEnabled();
  await expect(page.getByTestId("encounter").locator("h1")).toBeFocused();
  await page.keyboard.press("Tab");
  await expect(gated).toBeFocused();
  await gated.press("Enter");
  await expect(page.getByTestId("encounter")).toContainText("水下界碑");
  await gated.press("Space");
  await expect(page.getByTestId("encounter")).toContainText("水下界碑");
  await page.keyboard.press("Tab");
  await expect(fallback).toBeFocused();

  await page.evaluate(() => localStorage.clear());
  await page.goto(routeUrl);
  await page.getByRole("button", { name: "启程" }).click();
  await page.locator('[data-choice="mend-rope"]').click();
  await continueOnward(page);
  await page.locator('[data-choice="mark-path"]').click();
  await continueOnward(page);

  await expect(gated).toBeEnabled();
  await expect(gated).not.toHaveAttribute("aria-disabled", "true");
  await expect(gated).toContainText("信义 +1 · 见闻 +2");
  await gated.click();
  await expect(page.getByTestId("reflection")).toContainText("共渡");
});

test("J25 · legacy backup compaction is disclosed and explicitly restored", async ({ page }) => {
  const journeys = Array.from({ length: 129 }, (_, index) => ({
    id: `legacy-${index}`,
    seed: index + 1,
    ending: index === 0 ? "lost" : "covenant",
    stats: { provisions: 3, trust: 3, insight: 3 },
  }));
  const backup = JSON.stringify({
    version: 1,
    journey: null,
    chronicle: { version: 1, journeys },
    preferences: {
      version: 1,
      textScale: "normal",
      motion: "system",
      contrast: "system",
    },
    audio: { version: 1, volume: 0.35, muted: false },
  });

  await page.goto("/?seed=4242");
  await page.locator(".preferences summary").click();
  await page.locator("[data-backup-file]").setInputFiles({
    name: "legacy-save.json",
    mimeType: "application/json",
    buffer: Buffer.from(backup),
  });

  await expect(page.locator(".backup__status")).toContainText("最近 128 次行路");
  await expect(page.locator(".backup__status")).toContainText("全部已发现结局");
  expect(await page.evaluate(() => localStorage.getItem("shan-he-you-qi:chronicle:v1")))
    .toBeNull();

  await page.locator('[data-action="backup-restore"]').click();
  await expect(page.getByTestId("intro")).toBeVisible();
  const restored = await page.evaluate(() =>
    JSON.parse(localStorage.getItem("shan-he-you-qi:chronicle:v1") ?? "null") as {
      journeys: { id: string }[];
      endings: string[];
      encounters: string[];
    } | null,
  );
  expect(restored?.journeys).toHaveLength(128);
  expect(restored?.journeys[0]?.id).toBe("legacy-1");
  expect(restored?.endings).toEqual(["lost", "covenant"]);
  expect(restored?.encounters).toHaveLength(10);
});

test("J26 · browser eviction protection is requested only by the player", async ({ page }) => {
  await page.addInitScript(() => {
    Object.defineProperties(StorageManager.prototype, {
      persisted: {
        configurable: true,
        value: () => Promise.resolve(sessionStorage.getItem("test-storage-protected") === "yes"),
      },
      persist: {
        configurable: true,
        value: () => {
          const requests = Number(sessionStorage.getItem("test-storage-requests") ?? "0") + 1;
          sessionStorage.setItem("test-storage-requests", String(requests));
          sessionStorage.setItem("test-storage-protected", "yes");
          return Promise.resolve(true);
        },
      },
    });
  });

  await page.goto("/?seed=4242");
  await page.locator(".preferences summary").click();
  await expect(page.locator(".durability__status")).toContainText("自动清除");
  expect(await page.evaluate(() => sessionStorage.getItem("test-storage-requests"))).toBeNull();

  const protect = page.getByRole("button", { name: "请求保护本地数据" });
  await protect.click();
  await expect(page.locator(".durability__status")).toContainText("已防止浏览器自动清除");
  const granted = page.locator('[data-action="protect-storage"]');
  await expect(granted).toBeDisabled();
  await expect(granted).toHaveText("已获浏览器保护");
  expect(await page.evaluate(() => sessionStorage.getItem("test-storage-requests"))).toBe("1");

  await page.reload();
  await page.locator(".preferences summary").click();
  await expect(page.locator(".durability__status")).toContainText("已防止浏览器自动清除");
  await expect(page.getByRole("button", { name: "已获浏览器保护" })).toBeDisabled();
  expect(await page.evaluate(() => sessionStorage.getItem("test-storage-requests"))).toBe("1");
});

test("J27 · hidden pages pause ambience without automatic resume", async ({ page }) => {
  await page.addInitScript(() => {
    let hidden = false;
    let playCalls = 0;
    let pauseCalls = 0;
    Object.defineProperty(Document.prototype, "hidden", {
      configurable: true,
      get: () => hidden,
    });
    Object.defineProperties(HTMLMediaElement.prototype, {
      play: {
        configurable: true,
        value: () => {
          playCalls += 1;
          return Promise.resolve();
        },
      },
      pause: {
        configurable: true,
        value: () => { pauseCalls += 1; },
      },
    });
    Object.assign(window, {
      __setTestVisibility: (value: boolean) => {
        hidden = value;
        document.dispatchEvent(new Event("visibilitychange"));
      },
      __testMediaCalls: () => ({ playCalls, pauseCalls }),
    });
  });

  await page.goto("/?seed=4242");
  await page.locator(".preferences summary").click();
  await page.getByRole("button", { name: "开启环境音" }).click();
  await expect(page.getByRole("button", { name: "关闭环境音" })).toHaveAttribute(
    "aria-pressed",
    "true",
  );

  await page.evaluate(() =>
    (window as unknown as { __setTestVisibility(value: boolean): void })
      .__setTestVisibility(true),
  );
  const play = page.getByRole("button", { name: "开启环境音" });
  await expect(play).toHaveAttribute("aria-pressed", "false");
  await expect(page.locator(".ambient__status")).toContainText("切换页面时已暂停");

  await page.evaluate(() =>
    (window as unknown as { __setTestVisibility(value: boolean): void })
      .__setTestVisibility(false),
  );
  expect(await page.evaluate(() =>
    (window as unknown as { __testMediaCalls(): { playCalls: number; pauseCalls: number } })
      .__testMediaCalls(),
  )).toEqual({ playCalls: 1, pauseCalls: 1 });

  await play.click();
  await expect(page.getByRole("button", { name: "关闭环境音" })).toHaveAttribute(
    "aria-pressed",
    "true",
  );
  expect(await page.evaluate(() =>
    (window as unknown as { __testMediaCalls(): { playCalls: number; pauseCalls: number } })
      .__testMediaCalls().playCalls,
  )).toBe(2);
});

test("J28 · a completed journey downloads as a replayable text artifact", async ({ page }) => {
  await reachCovenant(page);
  const downloadPromise = page.waitForEvent("download");
  await page.getByRole("button", { name: "下载行旅文本" }).click();
  const download = await downloadPromise;

  expect(download.suggestedFilename()).toMatch(
    /^shan-he-you-qi-journey-4242-covenant-\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}-\d{3}Z\.txt$/,
  );
  const downloadPath = await download.path();
  expect(downloadPath).not.toBeNull();
  const artifact = await readFile(downloadPath!, "utf8");
  expect(artifact).toContain("结局：守契 · 山河有应");
  expect(artifact).toContain("新缆绷紧时");
  expect(artifact.match(/^\d\. /gm)).toHaveLength(5);
  expect(artifact.endsWith("#山河有契\n")).toBe(true);

  const routeUrl = artifact.match(/^同路旅签：(.*)$/m)?.[1];
  expect(routeUrl).toBeTruthy();
  const parsed = new URL(routeUrl!);
  expect(parsed.searchParams.get("seed")).toBe("4242");
  expect(parsed.searchParams.get("replay")).toBe("1");
  expect(parsed.searchParams.get("route")?.split(",")).toHaveLength(5);
  await expect(page.locator(".share__status")).toContainText("交给浏览器下载");
});

test("J29 · reduced-data install defers optional audio until player opt-in", async ({ context, page }) => {
  await page.addInitScript(() => {
    Object.defineProperty(Navigator.prototype, "connection", {
      configurable: true,
      get: () => ({ saveData: true }),
    });
  });

  await page.goto("/?seed=4242");
  await page.evaluate(() => navigator.serviceWorker.ready.then(() => undefined));
  await page.reload();
  await expect.poll(() => page.evaluate(() => Boolean(navigator.serviceWorker.controller))).toBe(true);

  const installation = await page.evaluate(async () => {
    const registration = await navigator.serviceWorker.ready;
    const workerUrl = new URL(registration.active!.scriptURL);
    const names = await caches.keys();
    const cacheName = names.find((name) => /-v9-[a-z0-9]+-reduced-/.test(name));
    const urls = cacheName
      ? (await (await caches.open(cacheName)).keys()).map((request) => request.url)
      : [];
    return { cacheName, saveData: workerUrl.searchParams.get("saveData"), urls };
  });
  expect(installation.saveData).toBe("1");
  expect(installation.cacheName).toMatch(/-v9-[a-z0-9]+-reduced-/);
  expect(installation.urls.some((url) => url.endsWith("/assets/journey-scroll.jpg"))).toBe(true);
  expect(installation.urls.some((url) => url.endsWith("/assets/mountain-wind.ogg"))).toBe(false);
  expect(await page.evaluate(() => performance.getEntriesByName(
    new URL("assets/mountain-wind.ogg", document.baseURI).href,
  ).length)).toBe(0);

  await page.locator(".preferences summary").click();
  await page.getByRole("button", { name: "开启环境音" }).click();
  await expect(page.getByRole("button", { name: "关闭环境音" })).toHaveAttribute(
    "aria-pressed",
    "true",
  );
  await expect.poll(() => page.evaluate(() =>
    caches.match(new URL("assets/mountain-wind.ogg", document.baseURI).href)
      .then((response) => Boolean(response)),
  )).toBe(true);
  await page.getByRole("button", { name: "关闭环境音" }).click();

  await context.setOffline(true);
  await page.reload();
  await page.locator(".preferences summary").click();
  await page.getByRole("button", { name: "开启环境音" }).click();
  await expect(page.getByRole("button", { name: "关闭环境音" })).toHaveAttribute(
    "aria-pressed",
    "true",
  );
  await context.setOffline(false);
});

test("J30 · a canonical intro survives reload and owns a consumed shared route", async ({ page }) => {
  await page.goto("/?seed=4242");
  await expect(page.getByTestId("intro")).toBeVisible();

  const firstUrl = new URL(page.url());
  expect(firstUrl.searchParams.get("seed")).toBe("4242");
  expect(firstUrl.searchParams.get("route")?.split(",")).toHaveLength(5);
  expect(firstUrl.searchParams.get("replay")).toBeNull();
  expect(await page.evaluate(() => localStorage.getItem("shan-he-you-qi:journey:v1")))
    .toBeNull();

  await page.reload();
  await expect(page.getByTestId("intro")).toBeVisible();
  expect(new URL(page.url()).searchParams.get("route")).toBe(firstUrl.searchParams.get("route"));
  expect(await page.evaluate(() => localStorage.getItem("shan-he-you-qi:journey:v1")))
    .toBeNull();

  await page.getByRole("button", { name: "启程" }).click();
  await chooseFirst(page);
  await expect(page.getByTestId("reflection")).toBeVisible();

  const sharedRoute = [
    "ferry-letter",
    "ridge-fire",
    "marsh-cranes",
    "city-ledger",
    "gate-names",
  ].join(",");
  await page.goto(`/?seed=77&replay=1&route=${sharedRoute}`);
  await expect(page.getByTestId("intro")).toBeVisible();
  expect(new URL(page.url()).searchParams.get("replay")).toBeNull();
  expect(new URL(page.url()).searchParams.get("route")).toBe(sharedRoute);

  const owned = await page.evaluate(() =>
    JSON.parse(localStorage.getItem("shan-he-you-qi:journey:v1") ?? "null") as {
      phase: string;
      seed: number;
      route: string[];
    } | null,
  );
  expect(owned).toMatchObject({ phase: "intro", seed: 77, route: sharedRoute.split(",") });

  await page.reload();
  await expect(page.getByTestId("intro")).toBeVisible();
  await expect(page.locator(".seed")).toContainText("77");
  expect(new URL(page.url()).searchParams.get("route")).toBe(sharedRoute);
});

test("J31 · failed local exports keep complete selectable fallbacks", async ({ page }) => {
  await page.addInitScript(() => {
    URL.createObjectURL = () => {
      throw new DOMException("Synthetic downloads disabled", "NotAllowedError");
    };
  });
  await page.goto("/?seed=4242");
  await page.locator(".preferences summary").click();
  await page.getByRole("button", { name: "导出进度" }).click();

  await expect(page.locator(".backup__status")).toContainText("无法开始下载");
  const fallback = page.getByRole("textbox", { name: "可手动复制的备份数据" });
  await expect(fallback).toBeVisible();
  const backup = JSON.parse(await fallback.inputValue()) as {
    version: number;
    journey: { phase: string; seed: number };
  };
  expect(backup).toMatchObject({ version: 1, journey: { phase: "intro", seed: 4242 } });

  await page.getByRole("button", { name: "启程" }).click();
  for (let index = 0; index < 5; index += 1) {
    await chooseFirst(page);
    if (index < 4) await continueOnward(page);
  }
  await expect(page.locator("[data-ending='covenant']")).toBeVisible();
  const summary = page.getByRole("textbox", { name: "可复制的行旅摘要" });
  await expect(summary).toContainText("#山河有契");
  await page.getByRole("button", { name: "下载行旅文本" }).click();
  await expect(page.locator(".share__status")).toContainText("手动复制行旅");
  await expect(summary).toContainText("同路旅签：");
});

test("J32 · a restored cached page rechecks local journey ownership", async ({ page }) => {
  await page.goto("/?seed=4242");
  await page.getByRole("button", { name: "启程" }).click();
  await page.evaluate(() =>
    window.dispatchEvent(new PageTransitionEvent("pageshow", { persisted: true })),
  );
  await expect(page.locator(".storage-conflict-backdrop")).toBeHidden();

  await page.evaluate(() => {
    localStorage.setItem(
      "shan-he-you-qi:preferences:v1",
      JSON.stringify({
        version: 1,
        textScale: "large",
        motion: "system",
        contrast: "system",
      }),
    );
    window.dispatchEvent(new PageTransitionEvent("pageshow", { persisted: true }));
  });

  const dialog = page.getByRole("alertdialog");
  await expect(dialog).toContainText("另一页已更新这段行旅");
  await expect(page.locator(".game-shell__session")).toHaveAttribute("inert", "");
  await expect(page.getByRole("button", { name: "载入最新进度" })).toBeFocused();
});

test("J33 · complementary completed routes reveal every authored encounter", async ({ page }) => {
  await reachCovenant(page);
  await expect(page.locator(".chronicle summary")).toContainText("遭遇 5/10");
  await page.locator(".chronicle summary").click();
  await expect(page.locator(".chronicle")).toContainText("已访山河 · 5/10");
  await expect(page.locator(".chronicle__encounter--known")).toHaveCount(5);

  const complementaryRoute = [
    "ferry-letter",
    "ridge-fire",
    "marsh-cranes",
    "city-ledger",
    "gate-names",
  ].join(",");
  await page.goto(`/?seed=77&replay=1&route=${complementaryRoute}`);
  await page.getByRole("button", { name: "启程" }).click();
  for (let index = 0; index < 5; index += 1) {
    await chooseFirst(page);
    if (index < 4) await continueOnward(page);
  }
  await expect(page.getByTestId("ending")).toBeVisible();
  await expect(page.locator(".chronicle summary")).toContainText("遭遇 10/10");
  await page.locator(".chronicle summary").click();

  await expect(page.locator(".chronicle")).toContainText("已访山河 · 10/10");
  await expect(page.locator(".chronicle__encounter--known")).toHaveCount(10);
  await expect(page.locator(".chronicle__encounters")).toContainText("断缆");
  await expect(page.locator(".chronicle__encounters")).toContainText("无主的信");
});

test("J35 · the full desktop journey remains playable at 1440 by 900", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await start(page);
  await page.evaluate(() => document.getAnimations().forEach((animation) => animation.finish()));

  const ledgerBox = await page.locator(".ledger").boundingBox();
  const storyBox = await page.getByTestId("encounter").boundingBox();
  expect(ledgerBox).not.toBeNull();
  expect(storyBox).not.toBeNull();
  expect(ledgerBox!.x + ledgerBox!.width).toBeLessThan(storyBox!.x);
  expect(Math.abs(ledgerBox!.y - storyBox!.y)).toBeLessThan(2);

  for (let index = 0; index < 5; index += 1) {
    expect(await page.evaluate(() =>
      document.documentElement.scrollWidth <= document.documentElement.clientWidth
    )).toBe(true);
    await expect(page.locator(OPERABLE_CHOICE_SELECTOR).first()).toBeInViewport();
    await chooseFirst(page);
    if (index < 4) {
      await expect(page.getByTestId("reflection")).toBeInViewport();
      await continueOnward(page);
    }
  }

  await expect(page.locator("[data-ending='covenant']")).toBeInViewport();
  await expect(page.locator(".journal summary")).toContainText("5/5");
  await expect(page.locator(".journal")).toHaveAttribute("open", "");
  await expect(page.locator(".journal li")).toHaveCount(5);
  await expect(page.locator(".journal li").first()).toBeVisible();
  expect(await page.evaluate(() =>
    document.documentElement.scrollWidth <= document.documentElement.clientWidth
  )).toBe(true);
});
