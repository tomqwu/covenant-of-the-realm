#!/usr/bin/env node

const minimum = [22, 12, 0];
const current = process.versions.node.split(".").map(Number);
const comparison = (current[0] ?? 0) - minimum[0] ||
  (current[1] ?? 0) - minimum[1] ||
  (current[2] ?? 0) - minimum[2];

if (comparison < 0) {
  console.error(`Node.js 22.12.0 or newer is required; found ${process.versions.node}.`);
  process.exit(1);
}
