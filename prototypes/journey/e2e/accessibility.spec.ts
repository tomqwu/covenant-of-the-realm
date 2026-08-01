import AxeBuilder from "@axe-core/playwright";
import { expect, OPERABLE_CHOICE_SELECTOR, test, type Page } from "./fixtures";

const expectNoViolations = async (page: Page): Promise<void> => {
  await page.evaluate(() => document.getAnimations().forEach((animation) => animation.finish()));
  const results = await new AxeBuilder({ page }).analyze();
  expect(
    results.violations.map((violation) => ({
      id: violation.id,
      impact: violation.impact,
      targets: violation.nodes.map((node) => node.target.join(" ")),
    })),
  ).toEqual([]);
};

const expectEnhancedTargets = async (page: Page): Promise<void> => {
  const undersized = await page.locator([
    "button",
    "a[href]",
    "summary",
    ".preferences fieldset label",
    '.ambient input[type="range"]',
    ".backup__file",
  ].join(", ")).evaluateAll((elements) => elements.flatMap((element) => {
    const bounds = element.getBoundingClientRect();
    const hiddenAncestor = element.closest("[hidden]");
    const styles = getComputedStyle(element);
    if (
      hiddenAncestor ||
      styles.display === "none" ||
      styles.visibility === "hidden" ||
      bounds.width === 0 ||
      bounds.height === 0
    ) return [];
    if (bounds.width >= 44 && bounds.height >= 44) return [];
    return [{
      target: element.outerHTML.slice(0, 100),
      width: bounds.width,
      height: bounds.height,
    }];
  }));
  expect(undersized).toEqual([]);
};

test("A01 · intro and expanded settings pass automated accessibility rules", async ({ page }) => {
  await page.addInitScript(() => {
    URL.createObjectURL = () => {
      throw new DOMException("Synthetic downloads disabled", "NotAllowedError");
    };
  });
  await page.goto("/?seed=4242");
  await expectEnhancedTargets(page);
  await expectNoViolations(page);
  await page.locator(".preferences summary").click();
  await expectEnhancedTargets(page);
  await expectNoViolations(page);

  await page.getByRole("button", { name: "导出进度" }).click();
  await expect(page.getByRole("textbox", { name: "可手动复制的备份数据" })).toBeVisible();
  await expectNoViolations(page);

  await page.locator('[data-preference="textScale"][value="large"]').check();
  await page.locator('[data-preference="motion"][value="reduced"]').check();
  await page.locator('[data-preference="contrast"][value="high"]').check();
  await expect(page.locator("#app")).toHaveAttribute("data-text-scale", "large");
  await expect(page.locator("#app")).toHaveAttribute("data-motion", "reduced");
  await expect(page.locator("#app")).toHaveAttribute("data-contrast", "high");
  await page.setViewportSize({ width: 360, height: 740 });
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth)).toBe(true);
  await expectEnhancedTargets(page);
  await expectNoViolations(page);
});

test("A02 · encounter, aftermath, and ending pass automated accessibility rules", async ({ page }) => {
  await page.goto("/?seed=4242");
  await page.getByRole("button", { name: "启程" }).click();
  await expectEnhancedTargets(page);
  await expectNoViolations(page);

  for (let index = 0; index < 5; index += 1) {
    await page.locator(OPERABLE_CHOICE_SELECTOR).first().click();
    await expectEnhancedTargets(page);
    await expectNoViolations(page);
    if (index < 4) await page.getByRole("button", { name: /继续前行/ }).click();
  }
  await expect(page.getByTestId("ending")).toBeVisible();

  await page.evaluate(() => localStorage.clear());
  await page.goto("/?seed=4242&replay=1&route=ferry-rope,ridge-bell,marsh-marker,city-well,gate-storm");
  await page.getByRole("button", { name: "启程" }).click();
  await page.locator('[data-choice="hire-skiff"]').click();
  await page.getByRole("button", { name: /继续前行/ }).click();
  await page.locator('[data-choice="mark-path"]').click();
  await page.getByRole("button", { name: /继续前行/ }).click();
  const locked = page.locator('[data-choice="raise-marker"]');
  await expect(locked).toHaveAttribute("aria-disabled", "true");
  await locked.focus();
  await expect(locked).toBeFocused();
  expect(await locked.evaluate((element) => getComputedStyle(element).color)).toBe(
    await page.locator(".choices legend").evaluate((element) => getComputedStyle(element).color),
  );
  await expectNoViolations(page);
});

test("A03 · forced colors reflow through a complete 320 px journey", async ({ page }) => {
  await page.emulateMedia({ forcedColors: "active", reducedMotion: "reduce" });
  await page.setViewportSize({ width: 320, height: 720 });
  await page.goto("/?seed=4242");
  await page.locator(".preferences summary").click();
  await expectEnhancedTargets(page);
  await expectNoViolations(page);
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth)).toBe(true);

  await page.getByRole("button", { name: "启程" }).click();
  await expect.poll(() => page.locator(".story").evaluate((element) =>
    Number.parseFloat(getComputedStyle(element).animationDuration)
  )).toBeLessThanOrEqual(0.00001);
  const firstChoice = page.locator(OPERABLE_CHOICE_SELECTOR).first();
  await firstChoice.focus();
  expect(await firstChoice.evaluate((element) => Number.parseFloat(getComputedStyle(element).outlineWidth))).toBeGreaterThanOrEqual(3);
  expect(await page.locator(".route-stop--current .route-stop__mark").evaluate((element) => getComputedStyle(element).outlineStyle)).toBe("solid");

  for (let index = 0; index < 5; index += 1) {
    await expectEnhancedTargets(page);
    await page.locator(OPERABLE_CHOICE_SELECTOR).first().click();
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth)).toBe(true);
    if (index < 4) await page.getByRole("button", { name: /继续前行/ }).click();
  }
  await expect(page.getByTestId("ending")).toBeVisible();
  await expectNoViolations(page);
});

test("A04 · a cross-tab progress conflict is focused and accessible", async ({ page }) => {
  await page.goto("/?seed=4242");
  await page.evaluate(() => {
    window.dispatchEvent(new StorageEvent("storage", {
      key: "shan-he-you-qi:journey:v1",
      newValue: "newer",
    }));
  });

  const dialog = page.getByRole("alertdialog");
  await expect(dialog).toBeVisible();
  const reload = page.getByRole("button", { name: "载入最新进度" });
  await expect(reload).toBeFocused();
  await expect(page.locator(".game-shell__session")).toHaveAttribute("inert", "");
  await page.keyboard.press("Tab");
  await expect(reload).toBeFocused();
  await page.keyboard.press("Shift+Tab");
  await expect(reload).toBeFocused();
  await expectNoViolations(page);
});

test("A05 · English large high-contrast text completes at 320 px", async ({ page }) => {
  await page.setViewportSize({ width: 320, height: 720 });
  await page.goto("/?seed=4242");
  await page.getByRole("button", { name: "Switch to English" }).click();
  await page.locator(".preferences summary").click();
  await page.locator('[data-preference="textScale"][value="large"]').check();
  await page.locator('[data-preference="motion"][value="reduced"]').check();
  await page.locator('[data-preference="contrast"][value="high"]').check();

  await expect(page.locator("#app")).toHaveAttribute("data-text-scale", "large");
  await expect(page.locator("#app")).toHaveAttribute("data-motion", "reduced");
  await expect(page.locator("#app")).toHaveAttribute("data-contrast", "high");
  await expectEnhancedTargets(page);
  await expectNoViolations(page);

  await page.getByRole("button", { name: "Begin journey" }).click();
  for (let index = 0; index < 5; index += 1) {
    expect(await page.evaluate(() =>
      document.documentElement.scrollWidth <= document.documentElement.clientWidth
    )).toBe(true);
    await expectEnhancedTargets(page);
    await page.locator(OPERABLE_CHOICE_SELECTOR).first().click();
    if (index < 4) {
      await page.getByRole("button", { name: /Continue onward/ }).click();
    }
  }

  await expect(page.locator("[data-ending='covenant']")).toBeVisible();
  await expect(page.locator(".journal summary")).toContainText("5/5");
  await expect(page.locator(".share textarea")).toContainText("Replay route:");
  expect(await page.evaluate(() =>
    document.documentElement.scrollWidth <= document.documentElement.clientWidth
  )).toBe(true);
  await expectEnhancedTargets(page);
  await expectNoViolations(page);
});

test("A06 · native keyboard navigation completes the full journey", async ({ page }) => {
  await page.goto("/?seed=4242");
  await page.keyboard.press("Tab");
  await expect(page.getByRole("link", { name: "跳到行旅正文" })).toBeFocused();
  await page.keyboard.press("Enter");
  await expect(page.getByTestId("intro").locator("h1")).toBeFocused();
  await page.keyboard.press("Tab");
  await expect(page.getByRole("button", { name: "启程" })).toBeFocused();
  await page.keyboard.press("Enter");

  for (let index = 0; index < 5; index += 1) {
    await expect(page.getByTestId("encounter").locator("h1")).toBeFocused();
    await page.keyboard.press("Tab");
    const choice = page.locator(OPERABLE_CHOICE_SELECTOR).first();
    await expect(choice).toBeFocused();
    await page.keyboard.press("Enter");
    if (index < 4) {
      await expect(page.getByTestId("reflection").locator("h1")).toBeFocused();
      await page.keyboard.press("Tab");
      await expect(page.getByRole("button", { name: /继续前行/ })).toBeFocused();
      await page.keyboard.press("Space");
    }
  }

  await expect(page.locator("[data-ending='covenant'] h1")).toBeFocused();
  await expect(page.locator(".journal li")).toHaveCount(5);
  await page.keyboard.press("Tab");
  await expect(page.getByRole("button", { name: "循原路再走一次" })).toBeFocused();
});
