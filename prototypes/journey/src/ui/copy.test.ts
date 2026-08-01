import { describe, expect, it } from "vitest";
import { UI_COPY } from "./copy";

const verifyLocalizedTree = (value: unknown, path: string): number => {
  expect(value, `${path} must be an object`).toBeTypeOf("object");
  expect(value, `${path} must not be null`).not.toBeNull();
  const record = value as Record<string, unknown>;
  if ("zh" in record || "en" in record) {
    expect(Object.keys(record).sort(), `${path} must contain only zh and en`).toEqual([
      "en",
      "zh",
    ]);
    expect(record.zh, `${path}.zh must be text`).toBeTypeOf("string");
    expect(record.en, `${path}.en must be text`).toBeTypeOf("string");
    expect((record.zh as string).trim(), `${path}.zh must not be blank`).not.toBe("");
    expect((record.en as string).trim(), `${path}.en must not be blank`).not.toBe("");
    return 1;
  }

  const entries = Object.entries(record);
  expect(entries.length, `${path} must have localized descendants`).toBeGreaterThan(0);
  return entries.reduce(
    (count, [key, child]) => count + verifyLocalizedTree(child, `${path}.${key}`),
    0,
  );
};

describe("interface copy contract", () => {
  it("keeps every interface and status message complete in both languages", () => {
    expect(verifyLocalizedTree(UI_COPY, "UI_COPY")).toBeGreaterThan(100);
  });
});
