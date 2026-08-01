import { readFile } from "node:fs/promises";
import { expect, OPERABLE_CHOICE_SELECTOR, test, type Page } from "./fixtures";

const finishJourney = async (page: Page, firstChoiceMade = false): Promise<void> => {
  for (let index = firstChoiceMade ? 1 : 0; index < 5; index += 1) {
    if (index > 0) await page.getByRole("button", { name: /继续前行/ }).click();
    await page.locator(OPERABLE_CHOICE_SELECTOR).first().click();
  }
};

test("X01 · a saved five-region journey completes across browser engines", async ({ page }) => {
  await page.goto("/?seed=4242");
  await page.getByRole("button", { name: "启程" }).click();
  await page.locator(OPERABLE_CHOICE_SELECTOR).first().click();
  const reflection = await page.getByTestId("reflection").locator("h1").textContent();
  await page.reload();
  await expect(page.getByTestId("reflection").locator("h1")).toHaveText(reflection ?? "");

  await finishJourney(page, true);

  await expect(page.locator("[data-ending='covenant']")).toBeVisible();
  await expect(page.locator(".journal li")).toHaveCount(5);
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth)).toBe(true);
});

test("X02 · the complete journey text downloads across browser engines", async ({ page }) => {
  await page.goto("/?seed=4242");
  await page.getByRole("button", { name: "启程" }).click();
  await finishJourney(page);

  const downloadPromise = page.waitForEvent("download");
  await page.getByRole("button", { name: "下载行旅文本" }).click();
  const download = await downloadPromise;
  expect(download.suggestedFilename()).toMatch(
    /^shan-he-you-qi-journey-4242-covenant-\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}-\d{3}Z\.txt$/,
  );
  const path = await download.path();
  expect(path).not.toBeNull();
  const artifact = await readFile(path!, "utf8");
  expect(artifact).toContain("结局：守契 · 山河有应");
  expect(artifact.match(/^\d\. /gm)).toHaveLength(5);
  const replayUrl = new URL(artifact.match(/^同路旅签：(.*)$/m)?.[1] ?? "");
  expect(replayUrl.searchParams.get("seed")).toBe("4242");
  expect(replayUrl.searchParams.get("replay")).toBe("1");
  expect(replayUrl.searchParams.get("route")?.split(",")).toHaveLength(5);
});
