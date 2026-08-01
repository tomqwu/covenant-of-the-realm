import { createHash } from "node:crypto";
import { readdir, readFile } from "node:fs/promises";
import { join, relative, resolve, sep } from "node:path";

const assetFiles = async (directory) => {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = await Promise.all(entries.map(async (entry) => {
    const path = join(directory, entry.name);
    return entry.isDirectory() ? assetFiles(path) : [path];
  }));
  return files.flat();
};

export const publicAssetPaths = async (root = "public") => {
  const absoluteRoot = resolve(root);
  return (await assetFiles(absoluteRoot))
    .map((file) => relative(absoluteRoot, file).split(sep).join("/"))
    .sort((left, right) => left < right ? -1 : left > right ? 1 : 0);
};

export const publicAssetRevision = async (root = "public", paths) => {
  const absoluteRoot = resolve(root);
  const assetPaths = paths ?? await publicAssetPaths(absoluteRoot);
  const hash = createHash("sha256");
  for (const path of assetPaths) {
    hash.update(path);
    hash.update("\0");
    hash.update(await readFile(join(absoluteRoot, ...path.split("/"))));
    hash.update("\0");
  }
  return hash.digest("hex").slice(0, 12);
};
