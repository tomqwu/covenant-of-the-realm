#!/usr/bin/env node
import { readdir, readFile } from "node:fs/promises";
import { join } from "node:path";

const testFiles = [];
const visit = async (directory) => {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) await visit(path);
    else if (entry.name.endsWith(".test.ts") || entry.name.endsWith(".spec.ts")) {
      testFiles.push(path);
    }
  }
};
await Promise.all([visit("src"), visit("e2e")]);

const forbidden = /\.(?:only|skip|todo|fixme|fail|fails)\s*\(/g;
const violations = [];
for (const file of testFiles.sort()) {
  const source = await readFile(file, "utf8");
  for (const match of source.matchAll(forbidden)) {
    const line = source.slice(0, match.index).split("\n").length;
    violations.push(`${file}:${line}: ${match[0].trim()}`);
  }
}
if (violations.length > 0) {
  throw new Error(
    `Focused, skipped, placeholder, or expected-failure tests are not release evidence:\n` +
    violations.join("\n"),
  );
}

console.log(
  `Test definitions verified: ${testFiles.length} files contain no release-bypassing modifiers.`,
);
