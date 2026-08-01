import { describe, expect, it } from "vitest";
import { backupFileName, journeyFileName } from "./artifact-name";

describe("local artifact filenames", () => {
  const createdAt = new Date("2026-07-31T23:58:09.321Z");

  it("creates sortable cross-platform backup and journey names", () => {
    expect(backupFileName(createdAt))
      .toBe("shan-he-you-qi-save-2026-07-31T23-58-09-321Z.json");
    expect(journeyFileName(4242, "covenant", createdAt))
      .toBe("shan-he-you-qi-journey-4242-covenant-2026-07-31T23-58-09-321Z.txt");
  });
});
