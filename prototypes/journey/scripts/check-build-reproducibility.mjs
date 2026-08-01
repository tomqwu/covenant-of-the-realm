#!/usr/bin/env node
import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { readdir, readFile } from "node:fs/promises";
import { join, relative } from "node:path";
import { promisify } from "node:util";

const execute = promisify(execFile);

const builtFiles = async (directory) => {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = await Promise.all(entries.map((entry) => {
    const path = join(directory, entry.name);
    return entry.isDirectory() ? builtFiles(path) : Promise.resolve([path]);
  }));
  return files.flat();
};

const snapshot = async () => {
  const files = (await builtFiles("dist")).sort();
  return Promise.all(files.map(async (path) => ({
    path: relative("dist", path).split("\\").join("/"),
    digest: createHash("sha256").update(await readFile(path)).digest("hex"),
  })));
};

const first = await snapshot();
await execute(process.execPath, ["node_modules/vite/bin/vite.js", "build"], {
  env: { ...process.env, NO_COLOR: "1" },
});
const second = await snapshot();

if (JSON.stringify(first) !== JSON.stringify(second)) {
  const firstByPath = new Map(first.map((entry) => [entry.path, entry.digest]));
  const secondByPath = new Map(second.map((entry) => [entry.path, entry.digest]));
  const paths = new Set([...firstByPath.keys(), ...secondByPath.keys()]);
  const differences = [...paths]
    .filter((path) => firstByPath.get(path) !== secondByPath.get(path))
    .sort()
    .map((path) => `${path}: ${firstByPath.get(path) ?? "missing"} -> ${secondByPath.get(path) ?? "missing"}`);
  throw new Error(`Production build is not reproducible:\n${differences.join("\n")}`);
}

console.log(`Production build reproducibility verified across ${first.length} files.`);
