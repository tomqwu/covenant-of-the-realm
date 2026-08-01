import {
  expect,
  test as base,
  type Page,
} from "@playwright/test";

type RuntimeErrorFixtures = {
  runtimeErrors: string[];
};

export const OPERABLE_CHOICE_SELECTOR =
  '[data-choice]:not(:disabled):not([aria-disabled="true"])';

export const observeRuntimeErrors = (page: Page): string[] => {
  const errors: string[] = [];
  page.on("pageerror", (error) => errors.push(error.message));
  return errors;
};

export const test = base.extend<RuntimeErrorFixtures>({
  runtimeErrors: [async ({ context }, use) => {
    const errors: string[] = [];
    const observe = (page: Page): void => {
      page.on("pageerror", (error) => errors.push(error.message));
    };
    context.pages().forEach(observe);
    context.on("page", observe);
    await use(errors);
    context.off("page", observe);
  }, { auto: true }],
});

test.afterEach(async ({ runtimeErrors }) => {
  expect(runtimeErrors, "uncaught browser runtime errors").toEqual([]);
});

export { expect };
export type { Page };
