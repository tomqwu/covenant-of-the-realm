#!/usr/bin/env node
import { createHash } from "node:crypto";
import { readdir, readFile, stat } from "node:fs/promises";
import { publicAssetPaths, publicAssetRevision } from "./public-asset-revision.mjs";

const required = [
  "dist/index.html",
  "dist/manifest.webmanifest",
  "dist/sw.js",
  "dist/assets/journey-scroll.jpg",
  "dist/assets/mountain-wind.ogg",
  "dist/icons/app-icon-192.png",
  "dist/icons/app-icon-512.png",
  "dist/icons/app-icon.svg",
  "dist/icons/app-icon-maskable-512.png",
];
await Promise.all(required.map((path) => stat(path)));

const index = await readFile("dist/index.html", "utf8");
const manifestSource = await readFile("dist/manifest.webmanifest", "utf8");
const manifest = JSON.parse(manifestSource);
const documentThemeColor = index.match(/name="theme-color" content="([^"]+)"/)?.[1];
const documentPublicRevision = index.match(
  /name="public-asset-revision" content="([a-f0-9]{12})"/,
)?.[1];
const sourcePublicPaths = await publicAssetPaths();
if (
  !/^<!doctype html>/i.test(index) ||
  !index.includes('<html lang="zh-CN">') ||
  !index.includes('<meta charset="UTF-8"') ||
  !index.includes('name="viewport" content="width=device-width, initial-scale=1.0"') ||
  !index.includes('<title>行旅之契 · 山河有契</title>') ||
  !index.includes('content="《山河有契：行旅之契》——一段由选择写成的山河旅程。"')
) {
  throw new Error("Production document identity, language, or viewport contract is invalid.");
}
const copiedPublicPaths = sourcePublicPaths.filter((path) => path !== "sw.js");
const [expectedPublicRevision, sourceCopiedRevision, builtCopiedRevision] = await Promise.all([
  publicAssetRevision("public", sourcePublicPaths),
  publicAssetRevision("public", copiedPublicPaths),
  publicAssetRevision("dist", copiedPublicPaths),
]);
if (documentPublicRevision !== expectedPublicRevision) {
  throw new Error("Document public-asset revision does not match the source tree contents.");
}
if (builtCopiedRevision !== sourceCopiedRevision) {
  throw new Error("Built public assets do not match every source path and byte.");
}
if (
  manifest.id !== "./" ||
  manifest.start_url !== "./" ||
  manifest.scope !== "./" ||
  manifest.display !== "standalone" ||
  manifest.orientation !== "any" ||
  manifest.dir !== "ltr" ||
  manifest.lang !== "zh-CN" ||
  manifest.name !== "山河有契：行旅之契" ||
  manifest.short_name !== "山河有契" ||
  manifest.description !== "一段由选择写成的山河旅程。" ||
  manifest.name_localized?.en !== "Mountains & Rivers: Covenant of the Road" ||
  manifest.short_name_localized?.en !== "Covenant Road" ||
  manifest.description_localized?.en !==
    "A journey through mountains and rivers, written by your choices." ||
  JSON.stringify(manifest.categories) !== JSON.stringify(["games", "entertainment"])
) {
  throw new Error("Install manifest identity, localization, scope, or display contract is invalid.");
}
if (
  !documentThemeColor ||
  manifest.theme_color !== documentThemeColor ||
  manifest.background_color !== documentThemeColor
) {
  throw new Error("Document, manifest theme, and launch background colors must agree.");
}
const expectedIcons = new Map([
  ["./icons/app-icon-192.png", { sizes: "192x192", purpose: "any", type: "image/png" }],
  ["./icons/app-icon-512.png", { sizes: "512x512", purpose: "any", type: "image/png" }],
  ["./icons/app-icon.svg", { sizes: "any", purpose: "any", type: "image/svg+xml" }],
  [
    "./icons/app-icon-maskable-512.png",
    { sizes: "512x512", purpose: "maskable", type: "image/png" },
  ],
]);
if (!Array.isArray(manifest.icons) || manifest.icons.length !== expectedIcons.size) {
  throw new Error("Install manifest must declare exactly the required app icons.");
}
for (const icon of manifest.icons) {
  const expected = expectedIcons.get(icon?.src);
  if (
    !expected ||
    expected.sizes !== icon.sizes ||
    expected.purpose !== icon.purpose ||
    expected.type !== icon.type
  ) {
    throw new Error("Install manifest icon paths, sizes, or single-purpose roles are invalid.");
  }
}
const pngDimensions = async (path) => {
  const bytes = await readFile(path);
  if (
    bytes.subarray(0, 8).toString("hex") !== "89504e470d0a1a0a" ||
    bytes.subarray(12, 16).toString("ascii") !== "IHDR"
  ) {
    throw new Error(`${path} is not a valid PNG with an IHDR header.`);
  }
  return [bytes.readUInt32BE(16), bytes.readUInt32BE(20)];
};
const actualPngDimensions = await Promise.all([
  pngDimensions("dist/icons/app-icon-192.png"),
  pngDimensions("dist/icons/app-icon-512.png"),
  pngDimensions("dist/icons/app-icon-maskable-512.png"),
]);
if (JSON.stringify(actualPngDimensions) !== JSON.stringify([
  [192, 192],
  [512, 512],
  [512, 512],
])) {
  throw new Error("Install icon pixel dimensions differ from their manifest contract.");
}
const jpegDimensions = async (path) => {
  const bytes = await readFile(path);
  if (bytes[0] !== 0xff || bytes[1] !== 0xd8) {
    throw new Error(`${path} does not contain a JPEG start marker.`);
  }
  let offset = 2;
  while (offset < bytes.length) {
    while (bytes[offset] === 0xff) offset += 1;
    const marker = bytes[offset];
    offset += 1;
    if (marker === undefined || marker === 0xd9 || marker === 0xda) break;
    if (marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
    if (offset + 2 > bytes.length) break;
    const length = bytes.readUInt16BE(offset);
    if (length < 2 || offset + length > bytes.length) break;
    if (
      (marker >= 0xc0 && marker <= 0xc3) ||
      (marker >= 0xc5 && marker <= 0xc7) ||
      (marker >= 0xc9 && marker <= 0xcb) ||
      (marker >= 0xcd && marker <= 0xcf)
    ) {
      return [bytes.readUInt16BE(offset + 5), bytes.readUInt16BE(offset + 3)];
    }
    offset += length;
  }
  throw new Error(`${path} does not contain a complete JPEG frame header.`);
};
if (JSON.stringify(await jpegDimensions("dist/assets/journey-scroll.jpg")) !==
  JSON.stringify([1774, 887])) {
  throw new Error("Hero landscape dimensions differ from the reviewed production asset.");
}
const audioBytes = await readFile("dist/assets/mountain-wind.ogg");
const opusHeadOffset = audioBytes.indexOf(Buffer.from("OpusHead"));
const opusTagsOffset = audioBytes.indexOf(Buffer.from("OpusTags"));
if (
  audioBytes.subarray(0, 4).toString("ascii") !== "OggS" ||
  opusHeadOffset < 0 ||
  opusHeadOffset + 16 > audioBytes.length ||
  audioBytes[opusHeadOffset + 8] !== 1 ||
  audioBytes[opusHeadOffset + 9] !== 2 ||
  audioBytes.readUInt32LE(opusHeadOffset + 12) !== 48_000 ||
  opusTagsOffset <= opusHeadOffset
) {
  throw new Error("Ambient audio must remain a tagged stereo 48 kHz Ogg/Opus asset.");
}
const manifestStrings = (value) => {
  if (typeof value === "string") return [value];
  if (Array.isArray(value)) return value.flatMap(manifestStrings);
  if (value && typeof value === "object") return Object.values(value).flatMap(manifestStrings);
  return [];
};
for (const value of manifestStrings(manifest)) {
  if (/^(?:https?:|\/\/|\/)/i.test(value)) {
    throw new Error(`Install manifest contains a remote or root-absolute value: ${value}`);
  }
}
const policy = index.match(/http-equiv="Content-Security-Policy"\s+content="([^"]+)"/)?.[1];
if (!policy) throw new Error("Production document must declare a Content Security Policy.");
const policyEntries = policy.split(";").map((entry) => entry.trim()).filter(Boolean);
const directives = new Map(policyEntries.map((entry) => {
  const [name, ...values] = entry.split(/\s+/);
  return [name, values];
}));
if (directives.size !== policyEntries.length) {
  throw new Error("Production Content Security Policy contains a duplicate directive.");
}
const expectedDirectives = new Map([
  ["default-src", ["'self'"]],
  ["base-uri", ["'none'"]],
  ["object-src", ["'none'"]],
  ["script-src", ["'self'"]],
  ["style-src", ["'self'"]],
  ["img-src", ["'self'", "data:"]],
  ["media-src", ["'self'"]],
  ["connect-src", ["'self'"]],
  ["worker-src", ["'self'"]],
  ["manifest-src", ["'self'"]],
  ["form-action", ["'none'"]],
  ["frame-src", ["'none'"]],
]);
if (directives.size !== expectedDirectives.size) {
  throw new Error("Production Content Security Policy directive set is incomplete or unexpected.");
}
for (const [name, expectedValues] of expectedDirectives) {
  const values = directives.get(name);
  if (JSON.stringify(values) !== JSON.stringify(expectedValues)) {
    throw new Error(`Production Content Security Policy has an invalid ${name} directive.`);
  }
}
if (!index.includes('name="referrer" content="no-referrer"')) {
  throw new Error("Production document must suppress referrer disclosure.");
}
if (!index.includes('rel="apple-touch-icon" href="./icons/app-icon-maskable-512.png"')) {
  throw new Error("Production document must expose the full-bleed iOS Home Screen icon.");
}
if (
  !index.includes("<noscript>") ||
  !index.includes("需要启用 JavaScript 才能开始行旅") ||
  !index.includes("JavaScript is required to begin.")
) {
  throw new Error("Production document must contain the bilingual no-script fallback.");
}
if (
  !/<link\s+rel="preload"\s+href="\.\/assets\/journey-scroll\.jpg"\s+as="image"\s+type="image\/jpeg"\s+fetchpriority="high"\s*\/>/.test(index)
) {
  throw new Error("Production document must preload the stable hero landscape path.");
}
const documentUrls = [...index.matchAll(
  /(?:src|href|poster|action|formaction|data)\s*=\s*(["'])(.*?)\1/gi,
)]
  .map((match) => match[2] ?? "");
for (const url of documentUrls) {
  if (/^(?:\/|https?:|\/\/)/i.test(url)) {
    throw new Error(`Production document URL must be relocatable: ${url}`);
  }
}
const documentSrcsets = [...index.matchAll(/srcset\s*=\s*(["'])(.*?)\1/gi)]
  .map((match) => match[2] ?? "");
for (const srcset of documentSrcsets) {
  if (/(?:^|,\s*)(?:\/|https?:|\/\/)/i.test(srcset)) {
    throw new Error(`Production document srcset must be relocatable: ${srcset}`);
  }
}

const assetNames = await readdir("dist/assets");
const javascript = assetNames.filter((name) => name.endsWith(".js"));
const styles = assetNames.filter((name) => name.endsWith(".css"));
if (javascript.length !== 1 || styles.length !== 1) {
  throw new Error("Expected one production JavaScript bundle and one stylesheet.");
}
const builtPaths = await publicAssetPaths("dist");
const expectedBuiltPaths = [
  ...sourcePublicPaths,
  "index.html",
  `assets/${javascript[0]}`,
  `assets/${styles[0]}`,
].sort();
if (JSON.stringify(builtPaths) !== JSON.stringify(expectedBuiltPaths)) {
  const expected = new Set(expectedBuiltPaths);
  const actual = new Set(builtPaths);
  const unexpected = builtPaths.filter((path) => !expected.has(path));
  const missing = expectedBuiltPaths.filter((path) => !actual.has(path));
  throw new Error(
    `Production file set differs from the release contract; unexpected: ${unexpected.join(", ") || "none"}; missing: ${missing.join(", ") || "none"}.`,
  );
}
const workerSource = await readFile("dist/sw.js", "utf8");
const expectedReleaseRevision = `shell-${createHash("sha256")
  .update(index)
  .digest("hex")
  .slice(0, 16)}`;
if (
  workerSource.includes("__SHAN_HE_RELEASE_REVISION__") ||
  !workerSource.includes(`const BUILD_REVISION = "${expectedReleaseRevision}";`)
) {
  throw new Error("Built service worker does not contain the exact release revision.");
}

const [javascriptSize, stylesheetSize, landscapeSize, audioSize] = await Promise.all([
  stat(`dist/assets/${javascript[0]}`).then((entry) => entry.size),
  stat(`dist/assets/${styles[0]}`).then((entry) => entry.size),
  stat("dist/assets/journey-scroll.jpg").then((entry) => entry.size),
  stat("dist/assets/mountain-wind.ogg").then((entry) => entry.size),
]);
const budgets = [
  ["JavaScript", javascriptSize, 100_000],
  ["CSS", stylesheetSize, 50_000],
  ["landscape", landscapeSize, 700_000],
  ["audio", audioSize, 300_000],
];
for (const [label, size, maximum] of budgets) {
  if (size > maximum) throw new Error(`${label} exceeds its ${maximum}-byte production budget.`);
}
const distributionSize = (await Promise.all(
  builtPaths.map((path) => stat(`dist/${path}`).then((entry) => entry.size)),
)).reduce((total, size) => total + size, 0);
if (distributionSize > 1_100_000) {
  throw new Error("Production distribution exceeds its 1100000-byte raw budget.");
}
const remoteLiteral = /(?:https?|wss?):\/\/|["'`]\/\//i;
const stylesheet = await readFile(`dist/assets/${styles[0]}`, "utf8");
if (
  /url\(\s*["']?(?:\/|https?:|\/\/)/i.test(stylesheet) ||
  /@import\s+(?:url\(\s*)?["']?(?:\/|https?:|\/\/)/i.test(stylesheet)
) {
  throw new Error("Production CSS contains a root-absolute or remote URL.");
}
const javascriptSource = await readFile(`dist/assets/${javascript[0]}`, "utf8");
if (remoteLiteral.test(javascriptSource)) {
  throw new Error("Production JavaScript contains a literal remote URL.");
}
if (remoteLiteral.test(workerSource)) {
  throw new Error("Production service worker contains a literal remote URL.");
}
const iconSource = await readFile("dist/icons/app-icon.svg", "utf8");
const iconUrls = [...iconSource.matchAll(/(?:href|src)\s*=\s*(["'])(.*?)\1/gi)]
  .map((match) => match[2] ?? "");
if (
  iconUrls.some((url) => /^(?:https?:|\/\/|\/)/i.test(url)) ||
  /url\(\s*["']?(?:\/|https?:|\/\/)/i.test(iconSource) ||
  /@import\s+(?:url\(\s*)?["']?(?:\/|https?:|\/\/)/i.test(iconSource)
) {
  throw new Error("Production SVG icon contains a remote or root-absolute dependency.");
}

console.log(
  `Build verified: ${builtPaths.length} expected files / ${distributionSize} B; JS ${javascriptSize} B, CSS ${stylesheetSize} B, landscape ${landscapeSize} B, audio ${audioSize} B.`,
);
