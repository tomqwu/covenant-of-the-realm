import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { runInNewContext } from "node:vm";
import { describe, expect, it, vi } from "vitest";

type WorkerListener = (event: { waitUntil(promise: Promise<unknown>): void }) => void;

describe("service worker source", () => {
  it("discovers either HTML quote style and attribute case during atomic installation", async () => {
    const source = await readFile(resolve("public/sw.js"), "utf8");
    const listeners = new Map<string, (event: unknown) => void>();
    const scope = "https://example.test/journey/";
    const html = `<script SRC='./assets/custom.js'></script>
      <link href = './assets/custom.css' rel='stylesheet'>
      <img src='https://outside.test/tracker.png'>`;
    const shellResponse = {
      ok: true,
      clone: vi.fn().mockReturnThis(),
      text: vi.fn().mockResolvedValue(html),
    };
    const assetResponse = { ok: true };
    const cache = { put: vi.fn().mockResolvedValue(undefined) };
    const fetch = vi.fn(async (input: URL | string) =>
      String(input) === scope ? shellResponse : assetResponse
    );
    const remove = vi.fn().mockResolvedValue(true);
    const worker = {
      location: { href: `${scope}sw.js` },
      registration: { scope },
      clients: { claim: vi.fn() },
      addEventListener: (type: string, listener: (event: unknown) => void) =>
        listeners.set(type, listener),
    };
    runInNewContext(source.replace(
      /const BUILD_REVISION = "[^"]+";/,
      'const BUILD_REVISION = "current";',
    ), {
      URL,
      caches: {
        delete: remove,
        keys: vi.fn(),
        open: vi.fn().mockResolvedValue(cache),
      },
      fetch,
      Promise,
      Set,
      self: worker,
    });

    let installation: Promise<unknown> | undefined;
    listeners.get("install")!({
      waitUntil: (promise: Promise<unknown>) => { installation = promise; },
    });
    await expect(installation).resolves.toBeUndefined();

    const requested = fetch.mock.calls.map(([input]) => String(input));
    expect(requested).toContain(`${scope}assets/custom.js`);
    expect(requested).toContain(`${scope}assets/custom.css`);
    expect(requested).not.toContain("https://outside.test/tracker.png");
    expect(remove).not.toHaveBeenCalled();
  });

  it("claims clients even when obsolete-cache cleanup is unavailable", async () => {
    const source = await readFile(resolve("public/sw.js"), "utf8");
    const listeners = new Map<string, WorkerListener>();
    const activationOrder: string[] = [];
    const enable = vi.fn().mockResolvedValue(undefined);
    const claim = vi.fn(async () => { activationOrder.push("claim"); });
    const remove = vi.fn().mockRejectedValue(new Error("cache deletion denied"));
    const scope = "https://example.test/journey/";
    const scopedPrefix = `shan-he-you-qi-shell-${encodeURIComponent("/journey/")}-`;

    const worker = {
      location: { href: `${scope}sw.js` },
      registration: {
        scope,
        navigationPreload: { enable },
      },
      clients: { claim },
      addEventListener: (type: string, listener: WorkerListener) => listeners.set(type, listener),
    };
    const cacheStorage = {
      keys: vi.fn(async () => {
        activationOrder.push("keys");
        return [] as string[];
      }),
      delete: remove,
      open: vi.fn(),
    };

    const context = {
      URL,
      caches: cacheStorage,
      fetch: vi.fn(),
      Promise,
      Set,
      self: worker,
    } as Record<string, unknown>;
    runInNewContext(`${source.replace(
      /const BUILD_REVISION = "[^"]+";/,
      'const BUILD_REVISION = "current";',
    )}\nglobalThis.__activeCache = CACHE_NAME;`, context);
    const activeCache = context.__activeCache as string;
    cacheStorage.keys.mockImplementationOnce(async () => {
      activationOrder.push("keys");
      return [
        `${scopedPrefix}v6-obsolete`,
        activeCache,
        "shan-he-you-qi-shell-%2Fanother%2F-v6-foreign",
      ];
    });

    const activate = async (): Promise<void> => {
      let activation: Promise<unknown> | undefined;
      listeners.get("activate")!({ waitUntil: (promise) => { activation = promise; } });
      await expect(activation).resolves.toBeUndefined();
    };

    await activate();
    expect(remove).toHaveBeenCalledTimes(1);
    expect(remove).toHaveBeenCalledWith(`${scopedPrefix}v6-obsolete`);
    expect(enable).toHaveBeenCalledOnce();
    expect(claim).toHaveBeenCalledOnce();
    expect(activationOrder.slice(0, 2)).toEqual(["claim", "keys"]);

    cacheStorage.keys.mockRejectedValueOnce(new Error("cache enumeration denied"));
    activationOrder.length = 0;
    remove.mockClear();
    enable.mockClear();
    claim.mockClear();
    await activate();
    expect(remove).not.toHaveBeenCalled();
    expect(enable).toHaveBeenCalledOnce();
    expect(claim).toHaveBeenCalledOnce();
    expect(activationOrder).toEqual(["claim"]);
  });

  it("intercepts only same-origin GET requests inside its registration scope", async () => {
    const source = await readFile(resolve("public/sw.js"), "utf8");
    const listeners = new Map<string, (event: unknown) => void>();
    const scope = "https://example.test/journey/";
    const response = {
      ok: true,
      status: 200,
      clone: vi.fn().mockReturnThis(),
    };
    const cache = {
      match: vi.fn().mockResolvedValue(undefined),
      put: vi.fn().mockResolvedValue(undefined),
    };
    const fetch = vi.fn().mockResolvedValue(response);
    const worker = {
      location: { href: `${scope}sw.js`, origin: "https://example.test" },
      registration: { scope },
      clients: { claim: vi.fn() },
      addEventListener: (type: string, listener: (event: unknown) => void) =>
        listeners.set(type, listener),
    };
    runInNewContext(source.replace(
      /const BUILD_REVISION = "[^"]+";/,
      'const BUILD_REVISION = "current";',
    ), {
      URL,
      caches: {
        delete: vi.fn(),
        keys: vi.fn(),
        open: vi.fn().mockResolvedValue(cache),
      },
      fetch,
      Promise,
      Set,
      self: worker,
    });

    const fetchListener = listeners.get("fetch")!;
    for (const url of [
      "https://example.test/other/asset.js",
      "https://outside.test/journey/asset.js",
    ]) {
      const respondWith = vi.fn();
      fetchListener({ request: { method: "GET", mode: "cors", url }, respondWith });
      expect(respondWith).not.toHaveBeenCalled();
    }

    const postRespondWith = vi.fn();
    fetchListener({
      request: { method: "POST", mode: "cors", url: `${scope}asset.js` },
      respondWith: postRespondWith,
    });
    expect(postRespondWith).not.toHaveBeenCalled();

    const scopedRespondWith = vi.fn();
    fetchListener({
      request: { method: "GET", mode: "cors", url: `${scope}asset.js` },
      respondWith: scopedRespondWith,
    });
    expect(scopedRespondWith).toHaveBeenCalledOnce();
    await expect(scopedRespondWith.mock.calls[0]![0]).resolves.toBe(response);
    expect(fetch).toHaveBeenCalledOnce();
    expect(cache.put).toHaveBeenCalledOnce();
  });
});
