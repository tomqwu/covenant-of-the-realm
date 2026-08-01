#!/usr/bin/env node
import { execFile as execFileCallback } from "node:child_process";
import { readdir, readFile, stat } from "node:fs/promises";
import { extname, resolve } from "node:path";
import { promisify } from "node:util";
import { publicAssetPaths } from "./public-asset-revision.mjs";

const execFile = promisify(execFileCallback);
const state = await readFile(".loop/STATE.md", "utf8");
const coverage = JSON.parse(await readFile("coverage/coverage-summary.json", "utf8"));
const metrics = ["statements", "branches", "functions", "lines"];
const minimum = Math.min(...metrics.map((metric) => coverage.total[metric].pct));
const coverageTotals = metrics.map((metric) =>
  coverage.total[metric].total.toLocaleString("en-US")
);

const { stdout: testListOutput } = await execFile(
  process.execPath,
  ["node_modules/vitest/vitest.mjs", "list", "--json"],
  { maxBuffer: 10 * 1024 * 1024 },
);
const unitTests = JSON.parse(testListOutput).length;
const unitClaim = new RegExp(
  `Unit suite: \\*\\*${unitTests} tests\\*\\*, exact \\*\\*${minimum}%\\*\\*` +
  `[\\s\\S]{0,160}lines \\(${coverageTotals.join(" / ")} at the latest full run\\)`,
);
if (!unitClaim.test(state)) {
  throw new Error("Published unit test/coverage totals differ from generated evidence.");
}

const ignoredDirectories = new Set([
  ".git",
  "coverage",
  "dist",
  "node_modules",
  "playwright-report",
  "test-results",
]);
let markdownFiles = 0;
const countMarkdown = async (directory) => {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    if (entry.isDirectory() && ignoredDirectories.has(entry.name)) continue;
    const path = resolve(directory, entry.name);
    if (entry.isDirectory()) await countMarkdown(path);
    else if (extname(entry.name).toLowerCase() === ".md") markdownFiles += 1;
  }
};
await countMarkdown(process.cwd());
if (!state.includes(`Documentation: ${markdownFiles} Markdown files`)) {
  throw new Error("Published documentation count differs from the repository tree.");
}

const builtPaths = await publicAssetPaths("dist");
const assetNames = await readdir("dist/assets");
const javascript = assetNames.find((name) => name.endsWith(".js"));
const stylesheet = assetNames.find((name) => name.endsWith(".css"));
if (!javascript || !stylesheet) throw new Error("Built application assets are unavailable.");
const [distributionSize, javascriptSize, stylesheetSize, landscapeSize, audioSize] =
  await Promise.all([
    Promise.all(builtPaths.map((path) => stat(`dist/${path}`)))
      .then((entries) => entries.reduce((total, entry) => total + entry.size, 0)),
    stat(`dist/assets/${javascript}`).then((entry) => entry.size),
    stat(`dist/assets/${stylesheet}`).then((entry) => entry.size),
    stat("dist/assets/journey-scroll.jpg").then((entry) => entry.size),
    stat("dist/assets/mountain-wind.ogg").then((entry) => entry.size),
  ]);
const number = (value) => value.toLocaleString("en-US");
if (
  !state.includes(
    `Production artifact: ${builtPaths.length} files / ${number(distributionSize)} bytes total`,
  ) ||
  !state.includes(
    `${number(javascriptSize)}-byte JS bundle, one ${number(stylesheetSize)}-byte stylesheet, ` +
    `${number(landscapeSize)}-byte landscape`,
  ) ||
  !state.includes(`${number(audioSize)}-byte optional audio`)
) {
  throw new Error("Published production artifact metrics differ from the verified build.");
}

console.log(
  `Loop metrics verified: ${unitTests} unit tests, ${markdownFiles} Markdown files, ` +
  `${builtPaths.length} production files / ${distributionSize} B.`,
);
