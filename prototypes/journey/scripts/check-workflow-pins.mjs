#!/usr/bin/env node
import { readdir, readFile } from "node:fs/promises";

const workflowDirectory = ".github/workflows";
const workflowFiles = (await readdir(workflowDirectory))
  .filter((name) => name.endsWith(".yml") || name.endsWith(".yaml"));

let externalActions = 0;
for (const file of workflowFiles) {
  const source = await readFile(`${workflowDirectory}/${file}`, "utf8");
  for (const match of source.matchAll(/^\s*(?:-\s*)?uses:\s+(\S+)/gm)) {
    const action = match[1];
    if (!action || action.startsWith("./") || action.startsWith("docker://")) continue;
    externalActions += 1;
    const separator = action.lastIndexOf("@");
    const revision = separator === -1 ? "" : action.slice(separator + 1);
    if (!/^[0-9a-f]{40}$/i.test(revision)) {
      throw new Error(`${file}: external action ${action} must use a full-length commit SHA.`);
    }
  }
}

if (externalActions === 0) throw new Error("No external workflow actions were found to verify.");

const checkWorkflow = await readFile(`${workflowDirectory}/check.yml`, "utf8");
if (
  !/^\s*push:\s*$/m.test(checkWorkflow) ||
  !/^\s*pull_request:\s*$/m.test(checkWorkflow) ||
  /pull_request_target|workflow_run/.test(checkWorkflow)
) {
  throw new Error("Check workflow must use only the ordinary push/pull_request code triggers.");
}
if (
  !/^permissions:\s*\n\s+contents:\s*read\s*$/m.test(checkWorkflow) ||
  /^\s+[A-Za-z_-]+:\s*write\s*$/m.test(checkWorkflow)
) {
  throw new Error("Check workflow permissions must remain explicitly read-only.");
}
for (const contract of [
  /timeout-minutes:\s*15/,
  /run:\s*PLAYWRIGHT_WITH_DEPS=1 make setup/,
  /run:\s*make check/,
  /if:\s*failure\(\)/,
  /path:\s*\|\s*\n\s+coverage\/\s*\n\s+playwright-report\/\s*\n\s+test-results\//,
  /if-no-files-found:\s*warn/,
  /retention-days:\s*7/,
]) {
  if (!contract.test(checkWorkflow)) {
    throw new Error("Check workflow setup, validation, or failure-diagnostic contract changed.");
  }
}

const dependabot = await readFile(".github/dependabot.yml", "utf8");
const ecosystems = [...dependabot.matchAll(/package-ecosystem:\s*([^\s]+)/g)]
  .map((match) => match[1]);
if (
  JSON.stringify(ecosystems) !== JSON.stringify(["npm", "github-actions"]) ||
  (dependabot.match(/interval:\s*weekly/g) ?? []).length !== 2 ||
  !/development-tooling:\s*\n\s+dependency-type:\s*development/.test(dependabot) ||
  !/workflow-actions:\s*\n\s+patterns:\s*\n\s+-\s+"actions\/\*"/.test(dependabot) ||
  !dependabot.includes("open-pull-requests-limit: 3") ||
  !dependabot.includes("open-pull-requests-limit: 2")
) {
  throw new Error("Dependabot must retain bounded weekly npm/workflow update groups.");
}

console.log(
  `Workflow verified: read-only push/PR gate with ${externalActions} immutable actions ` +
  "plus bounded dependency updates and seven-day failure diagnostics.",
);
