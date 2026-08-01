#!/usr/bin/env node
import { readdir, readFile } from "node:fs/promises";
import { resolve } from "node:path";

const productionModule = /^src\/(?:game|pwa|ui)\/.*\.ts$/;
const deliberatelyUnmeasured = new Set([
  "src/main.ts",
  "src/vite-env.d.ts",
]);

const sourceEntries = await readdir("src", { recursive: true, withFileTypes: true });
const sourceFiles = sourceEntries
  .filter((entry) => entry.isFile())
  .map((entry) => {
    const parent = entry.parentPath ?? entry.path;
    return `${parent}/${entry.name}`.replaceAll("\\", "/");
  })
  .filter((path) => path.endsWith(".ts"))
  .filter((path) => !path.endsWith(".test.ts") && !path.startsWith("src/test/"))
  .sort();

const unexpectedUnmeasured = sourceFiles.filter(
  (path) => !productionModule.test(path) && !deliberatelyUnmeasured.has(path),
);
if (unexpectedUnmeasured.length > 0) {
  throw new Error(
    `Production TypeScript exists outside the audited coverage scope: ${unexpectedUnmeasured.join(", ")}`,
  );
}

const expected = sourceFiles.filter((path) => productionModule.test(path));
const report = JSON.parse(await readFile("coverage/coverage-summary.json", "utf8"));
const measured = Object.keys(report)
  .filter((path) => path !== "total")
  .map((path) => resolve(path))
  .sort();
const expectedAbsolute = expected.map((path) => resolve(path)).sort();

const missing = expectedAbsolute.filter((path) => !measured.includes(path));
const extra = measured.filter((path) => !expectedAbsolute.includes(path));
if (missing.length > 0 || extra.length > 0) {
  throw new Error([
    "Generated unit coverage does not match every game/UI/PWA production module.",
    missing.length > 0 ? `Missing: ${missing.join(", ")}` : "",
    extra.length > 0 ? `Unexpected: ${extra.join(", ")}` : "",
  ].filter(Boolean).join("\n"));
}

console.log(
  `Coverage scope verified: ${expected.length} game/UI/PWA production modules; ` +
  "browser composition root and service worker remain integration-tested boundaries.",
);
