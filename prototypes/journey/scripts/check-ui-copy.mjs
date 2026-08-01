#!/usr/bin/env node
import { readdir, readFile } from "node:fs/promises";
import { join } from "node:path";

const sourcePaths = async (directory) => {
  const entries = await readdir(directory, { withFileTypes: true });
  const paths = await Promise.all(entries.map((entry) => {
    const path = join(directory, entry.name);
    return entry.isDirectory()
      ? sourcePaths(path)
      : Promise.resolve(path.endsWith(".ts") ? [path] : []);
  }));
  return paths.flat();
};

const files = await sourcePaths("src");
const sources = await Promise.all(files.map(async (path) => ({
  path,
  source: await readFile(path, "utf8"),
})));

const copySource = sources.find(({ path }) => path.endsWith("src/ui/copy.ts"))?.source;
if (!copySource) throw new Error("Unable to locate src/ui/copy.ts.");

const copyStart = copySource.indexOf("export const UI_COPY = {");
const copyEnd = copySource.indexOf("} as const;", copyStart);
if (copyStart < 0 || copyEnd < 0) {
  throw new Error("UI_COPY must remain a directly exported object literal.");
}
const copyObject = copySource.slice(copyStart, copyEnd);
const keys = new Set(
  [...copyObject.matchAll(/^  ([A-Za-z][A-Za-z0-9]*):/gm)].map((match) => match[1]),
);
if (keys.size === 0) throw new Error("UI_COPY has no statically discoverable keys.");

const referenced = new Set();
for (const { source } of sources) {
  for (const match of source.matchAll(/\bUI_COPY\.([A-Za-z][A-Za-z0-9]*)/g)) {
    referenced.add(match[1]);
  }
  for (const match of source.matchAll(/\bUI_COPY\["([A-Za-z][A-Za-z0-9]*)"\]/g)) {
    referenced.add(match[1]);
  }
}

const unused = [...keys].filter((key) => !referenced.has(key)).sort();
if (unused.length > 0) {
  throw new Error(`Unused UI_COPY keys: ${unused.join(", ")}`);
}

console.log(`UI copy verified: ${keys.size} top-level keys all have consumers.`);
