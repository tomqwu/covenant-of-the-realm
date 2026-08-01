import AxeBuilder from "@axe-core/playwright";
import { expect, OPERABLE_CHOICE_SELECTOR, test } from "./fixtures";

test("J08 · a complete journey remains playable by touch at a narrow viewport", async ({ page }) => {
  await page.setViewportSize({ width: 360, height: 740 });
  await page.goto("/?seed=4242");
  await page.getByRole("button", { name: "启程" }).tap();
  for (let index = 0; index < 5; index += 1) {
    await page.locator(OPERABLE_CHOICE_SELECTOR).first().tap();
    if (index < 4) {
      await expect(page.getByTestId("reflection")).toBeInViewport();
      await page.getByRole("button", { name: /继续前行/ }).tap();
      await expect(page.getByTestId("encounter")).toBeInViewport();
    }
  }

  await expect(page.locator("[data-ending='covenant']")).toBeInViewport();
  await expect(page.locator(".journal summary")).toBeVisible();
  await expect(page.locator(".journal summary")).toContainText("5/5");
  await expect(page.locator(".journal li")).toHaveCount(5);
  await expect(page.locator(".journal li p")).toHaveCount(5);
  await page.locator(".chronicle summary").tap();
  const recentJourney = page.locator(".chronicle__journeys button");
  await expect(recentJourney).toHaveCount(1);
  await expect.poll(async () => (await recentJourney.boundingBox())?.height ?? 0).toBeGreaterThanOrEqual(44);
  await expect(page.locator("body")).toHaveCSS("overflow-x", "hidden");
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth)).toBe(true);
  await page.evaluate(() => document.getAnimations().forEach((animation) => animation.finish()));
  const accessibility = await new AxeBuilder({ page }).analyze();
  expect(accessibility.violations).toEqual([]);
});

test("J34 · the English journey remains playable and accessible by touch at 360 px", async ({ page }) => {
  await page.setViewportSize({ width: 360, height: 740 });
  await page.goto("/?seed=4242");
  await page.locator('[data-action="language"]').tap();
  await expect(page.locator("html")).toHaveAttribute("lang", "en");
  await page.getByRole("button", { name: "Begin journey" }).tap();

  for (let index = 0; index < 5; index += 1) {
    expect(await page.evaluate(() =>
      document.documentElement.scrollWidth <= document.documentElement.clientWidth
    )).toBe(true);
    await page.locator(OPERABLE_CHOICE_SELECTOR).first().tap();
    if (index < 4) {
      await page.getByRole("button", { name: /Continue onward/ }).tap();
    }
  }

  await expect(page.locator("[data-ending='covenant']")).toBeInViewport();
  await expect(page.locator(".journal summary")).toContainText("5/5");
  await expect(page.locator(".share textarea")).toContainText("Replay route:");
  expect(await page.evaluate(() =>
    document.documentElement.scrollWidth <= document.documentElement.clientWidth
  )).toBe(true);
  await page.evaluate(() => document.getAnimations().forEach((animation) => animation.finish()));
  expect((await new AxeBuilder({ page }).analyze()).violations).toEqual([]);
});
