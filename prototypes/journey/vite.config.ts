import { createHash } from "node:crypto";
import { readFile, writeFile } from "node:fs/promises";
import { defineConfig } from "vitest/config";
import { publicAssetRevision } from "./scripts/public-asset-revision.mjs";

const developmentConnections =
  "connect-src 'self' ws://127.0.0.1:* ws://localhost:*;";
const developmentStyles = "style-src 'self' 'unsafe-inline';";
const themeMarker = '<meta name="theme-color" content="#eee5d1" />';

export default defineConfig(async ({ command }) => {
  const assetRevision = await publicAssetRevision();
  return {
    base: "./",
    plugins: [{
      name: "document-runtime-contract",
      transformIndexHtml: (html: string) => {
        if (!html.includes(themeMarker)) {
          throw new Error("Theme marker was not found in the source document.");
        }
        let transformed = html.replace(
          themeMarker,
          `${themeMarker}\n    <meta name="public-asset-revision" content="${assetRevision}" />`,
        );
        if (command === "build") {
          if (!transformed.includes(developmentConnections)) {
            throw new Error("Development connection policy was not found in the source document.");
          }
          transformed = transformed.replace(developmentConnections, "connect-src 'self';");
          if (!transformed.includes(developmentStyles)) {
            throw new Error("Development style policy was not found in the source document.");
          }
          transformed = transformed.replace(developmentStyles, "style-src 'self';");
        }
        return transformed;
      },
      writeBundle: command === "build"
        ? async () => {
            const document = await readFile("dist/index.html");
            const shellRevision = createHash("sha256")
              .update(document)
              .digest("hex")
              .slice(0, 16);
            const workerPath = "dist/sw.js";
            const worker = await readFile(workerPath, "utf8");
            const marker = "__SHAN_HE_RELEASE_REVISION__";
            if (worker.split(marker).length !== 2) {
              throw new Error("Service worker release marker must occur exactly once.");
            }
            await writeFile(
              workerPath,
              worker.replace(marker, `shell-${shellRevision}`),
            );
          }
        : undefined,
    }],
    test: {
      include: ["src/**/*.test.ts"],
      environment: "happy-dom",
      setupFiles: ["./src/test/setup.ts"],
      coverage: {
        provider: "v8" as const,
        reporter: ["text", "json-summary", "html"],
        include: ["src/game/**/*.ts", "src/pwa/**/*.ts", "src/ui/**/*.ts"],
        exclude: ["src/**/*.test.ts"],
        thresholds: {
          lines: 99,
          functions: 99,
          branches: 99,
          statements: 99,
        },
      },
    },
  };
});
