import type { EndingId } from "./types";

const portableUtcTimestamp = (createdAt: Date): string =>
  createdAt.toISOString()
    .replaceAll(":", "-")
    .replace(".", "-");

export const backupFileName = (createdAt: Date): string =>
  `shan-he-you-qi-save-${portableUtcTimestamp(createdAt)}.json`;

export const journeyFileName = (
  seed: number,
  ending: EndingId,
  createdAt: Date,
): string =>
  `shan-he-you-qi-journey-${seed}-${ending}-${portableUtcTimestamp(createdAt)}.txt`;
