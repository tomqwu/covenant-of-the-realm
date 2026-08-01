#!/usr/bin/env node
import { mkdtemp, mkdir, rename, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { publicAssetRevision } from "./public-asset-revision.mjs";

const temporaryRoot = await mkdtemp(join(tmpdir(), "shan-he-public-revision-"));
const first = join(temporaryRoot, "first");
const second = join(temporaryRoot, "second");

try {
  await Promise.all([
    mkdir(join(first, "nested"), { recursive: true }),
    mkdir(join(second, "nested"), { recursive: true }),
  ]);
  await writeFile(join(first, "z.txt"), "last");
  await writeFile(join(first, "nested", "a.bin"), new Uint8Array([0, 1, 2]));
  await writeFile(join(second, "nested", "a.bin"), new Uint8Array([0, 1, 2]));
  await writeFile(join(second, "z.txt"), "last");

  const [firstRevision, secondRevision] = await Promise.all([
    publicAssetRevision(first),
    publicAssetRevision(second),
  ]);
  if (firstRevision !== secondRevision) {
    throw new Error("Public revision must not depend on file creation order.");
  }

  await writeFile(join(second, "nested", "a.bin"), new Uint8Array([0, 1, 3]));
  const changedBytesRevision = await publicAssetRevision(second);
  if (changedBytesRevision === firstRevision) {
    throw new Error("Public revision must change when same-path bytes change.");
  }

  await writeFile(join(second, "nested", "a.bin"), new Uint8Array([0, 1, 2]));
  await rename(join(second, "z.txt"), join(second, "y.txt"));
  const changedPathRevision = await publicAssetRevision(second);
  if (changedPathRevision === firstRevision) {
    throw new Error("Public revision must change when an asset path changes.");
  }

  console.log("Public asset revision verified: order-independent and path/byte-sensitive.");
} finally {
  await rm(temporaryRoot, { recursive: true, force: true });
}
