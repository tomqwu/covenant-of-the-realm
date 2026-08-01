#!/usr/bin/env node
import { execFile as execFileCallback } from "node:child_process";
import { readdir, readFile } from "node:fs/promises";
import { promisify } from "node:util";

const execFile = promisify(execFileCallback);

const coverage = JSON.parse(await readFile("coverage/coverage-summary.json", "utf8"));
const metrics = ["lines", "statements", "functions", "branches"];
const minimum = Math.min(...metrics.map((metric) => coverage.total[metric].pct));
if (minimum < 99) {
  throw new Error(`Unit coverage badge cannot claim 99%+: minimum is ${minimum}%.`);
}

const docs = await readFile("docs/E2E_COVERAGE.md", "utf8");
const journeySpecs = [
  await readFile("e2e/journey.spec.ts", "utf8"),
  await readFile("e2e/mobile.spec.ts", "utf8"),
].join("\n");
const documented = new Set([...docs.matchAll(/\| (J\d{2}) \|/g)].map((match) => match[1]));
const automated = new Set([...journeySpecs.matchAll(/test\("(J\d{2})/g)].map((match) => match[1]));
if (documented.size === 0 || documented.size !== automated.size) {
  throw new Error(`Critical E2E evidence mismatch: found ${automated.size}/${documented.size}.`);
}
for (const journey of documented) {
  if (!automated.has(journey)) throw new Error(`Missing automated journey: ${journey}`);
}

const unitBadge = await readFile("badges/unit-coverage.svg", "utf8");
const e2eBadge = await readFile("badges/e2e-journeys.svg", "utf8");
const readme = await readFile("README.md", "utf8");
const loopState = await readFile(".loop/STATE.md", "utf8");
const unitClaim = unitBadge.match(/aria-label="unit coverage: ([\d.]+)%"/)?.[1];
const e2eClaim = e2eBadge.match(/aria-label="critical E2E journeys: (\d+) \/ (\d+)"/);
if (Number(unitClaim) !== minimum) {
  throw new Error(`Unit badge claims ${unitClaim ?? "nothing"}%; generated minimum is ${minimum}%.`);
}
if (
  !unitBadge.includes(`<title>unit coverage: ${minimum}%</title>`) ||
  !unitBadge.includes(`>${minimum}%</text>`)
) {
  throw new Error("Unit badge title or visible value differs from its generated claim.");
}
if (Number(e2eClaim?.[1]) !== automated.size || Number(e2eClaim?.[2]) !== documented.size) {
  throw new Error(
    `E2E badge claims ${e2eClaim ? `${e2eClaim[1]}/${e2eClaim[2]}` : "nothing"}; ` +
    `evidence is ${automated.size}/${documented.size}.`,
  );
}
if (
  !e2eBadge.includes(
    `<title>critical E2E journeys: ${automated.size} / ${documented.size}</title>`,
  ) ||
  !e2eBadge.includes(`>${automated.size} / ${documented.size}</text>`)
) {
  throw new Error("E2E badge title or visible value differs from its generated claim.");
}
const documentedTarget = docs.match(/Automated journey coverage target: \*\*(\d+)\/(\d+)/);
if (
  Number(documentedTarget?.[1]) !== automated.size ||
  Number(documentedTarget?.[2]) !== documented.size
) {
  throw new Error("Documented E2E target does not match the journey matrix.");
}
if (!readme.includes("badges/unit-coverage.svg") || !readme.includes("badges/e2e-journeys.svg")) {
  throw new Error("README must display both verified badges.");
}

const specFiles = (await readdir("e2e")).filter((name) => name.endsWith(".spec.ts"));
const evidenceIds = [];
let sourceTests = 0;
for (const file of specFiles) {
  const source = await readFile(`e2e/${file}`, "utf8");
  const tests = [...source.matchAll(/\btest\("([^"]+)"/g)];
  sourceTests += tests.length;
  for (const test of tests) {
    const evidenceId = test[1]?.match(/^([ADJSX]\d{2}) · /)?.[1];
    if (!evidenceId) throw new Error(`${file} contains a browser test without an evidence ID.`);
    evidenceIds.push(evidenceId);
  }
}
if (new Set(evidenceIds).size !== evidenceIds.length) {
  throw new Error("Browser evidence IDs must be unique across every spec file.");
}
const { stdout: listOutput } = await execFile(
  process.execPath,
  ["node_modules/@playwright/test/cli.js", "test", "--list", "--reporter=json"],
  {
    env: { ...process.env, CI: "1" },
    maxBuffer: 10 * 1024 * 1024,
  },
);
const resolvedMatrix = JSON.parse(listOutput);
if (resolvedMatrix.errors.length > 0) {
  throw new Error("Playwright could not resolve the configured browser matrix.");
}
if (
  resolvedMatrix.config.failOnFlakyTests !== true ||
  resolvedMatrix.config.forbidOnly !== true ||
  resolvedMatrix.config.projects.some((project) => project.retries < 1)
) {
  throw new Error("CI must reject focused/flaky browser tests while retaining diagnostic retries.");
}

const configuredSpecs = new Set();
const resolvedEvidenceIds = new Set();
let browserExecutions = 0;
const visitSuite = (suite) => {
  if (suite.file?.endsWith(".spec.ts")) configuredSpecs.add(suite.file);
  for (const spec of suite.specs ?? []) {
    const evidenceId = spec.title?.match(/^([ADJSX]\d{2}) · /)?.[1];
    if (evidenceId) resolvedEvidenceIds.add(evidenceId);
    browserExecutions += spec.tests?.length ?? 0;
  }
  for (const child of suite.suites ?? []) visitSuite(child);
};
for (const suite of resolvedMatrix.suites) visitSuite(suite);
if (
  specFiles.length !== configuredSpecs.size ||
  specFiles.some((name) => !configuredSpecs.has(name))
) {
  throw new Error("One or more E2E spec files are absent from the resolved Playwright matrix.");
}
if (browserExecutions === 0) {
  throw new Error("The resolved Playwright browser matrix is empty.");
}
if (
  sourceTests !== evidenceIds.length ||
  sourceTests !== resolvedEvidenceIds.size ||
  evidenceIds.some((evidenceId) => !resolvedEvidenceIds.has(evidenceId))
) {
  throw new Error("Source evidence IDs differ from the resolved named browser checks.");
}
if (
  !readme.includes(`full browser matrix currently contains ${browserExecutions} passing executions`) ||
  !loopState.includes(`/ ${browserExecutions} total browser executions`) ||
  !loopState.includes(`All ${evidenceIds.length} named`) ||
  !docs.includes(`Configured browser execution target: **${browserExecutions}/${browserExecutions}**`)
) {
  throw new Error(
    `Published full-browser claims do not match ${browserExecutions} configured executions.`,
  );
}

console.log(
  `Badges verified: unit coverage ${minimum}%, critical E2E ` +
  `${automated.size}/${documented.size}, ${evidenceIds.length} named checks / ` +
  `${browserExecutions} browser executions.`,
);
