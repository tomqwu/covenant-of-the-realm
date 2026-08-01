# Static deployment contract

The production output is a self-contained `dist/` directory with no runtime
backend or third-party request. It can be mounted at an origin root or an
unknown nested path. JavaScript is required for the deterministic game state
machine; when browser policy disables it, the shell renders a bilingual
semantic explanation instead of a blank application root.

Relocatable does not mean path-isolated player data. Browser `localStorage` is
origin-scoped, so independent production/staging copies must use different
origins unless a future explicit key migration is implemented. See
[`STORAGE_SCOPE_RESEARCH.md`](STORAGE_SCOPE_RESEARCH.md).

The host must revalidate entry HTML and stable public URLs while allowing the
content-hashed JS/CSS files to be immutable. The exact header matrix and live
same-path-update acceptance test are defined in
[`HOST_CACHE_RESEARCH.md`](HOST_CACHE_RESEARCH.md).

`make play` (or `npm run play`) builds this exact artifact, serves it from a
loopback HTTP origin, and opens the browser. The repository source
`index.html` is not a double-click artifact: `file://` cannot provide the
TypeScript build, HTTP service-worker scope, or production cache lifecycle.

Vite's [production build guidance](https://main.vite.dev/guide/build#relative-base)
specifies `base: "./"` when the deployment base is not known in advance. The
generated script and stylesheet links are therefore relative. Public manifest
and icon links are authored relative, while runtime landscape, audio, backup,
and worker URLs resolve against `document.baseURI`.

Completed-journey URLs are also constructed from the current document URL, so a
root deployment and a repository subpath produce links within their own scope.
`seed` identifies the route token, `route` carries five comma-separated authored
encounter IDs validated in region order, and the one-time `replay=1` flag
supersedes an unrelated save. An English artifact also carries `lang=en`; other
or missing language values safely default to Chinese. The composition root removes only `replay` after
mounting; the retained seed/route make reload and manual copying transparent.
Every mount canonicalizes the retained seed, exact route, and language before
the player acts. An ordinary fresh intro needs no local write: the address is
its durable description, so clearing local data remains cleared. A one-time
shared intro is different: consuming `replay=1` immediately replaces the saved
journey, preventing a reload-before-Begin from reviving unrelated progress.
Starting a different route or recalling one from the chronicle replaces those
retained values, and changing language updates the language token, without
adding the one-time flag. The address bar therefore remains a durable route and
language description while normal autosave/reload behavior continues.

The stable hero landscape path is declared once in the initial document as a
typed high-priority image preload, then consumed by the rendered decorative
image. Both resolve against the same document base, so early discovery does not
sacrifice nested-path relocatability or issue a second page request. Progress
position is selected by stylesheet rules from a bounded DOM data attribute, not
an inline style.
The evidence and rejected alternatives are recorded in
[`HERO_LOADING_RESEARCH.md`](HERO_LOADING_RESEARCH.md).

Playwright deployment audit D01 serves the built `dist/` directory only beneath
`/journey/`. It verifies the manifest URL and worker scope stay inside that
mount, validates both the Chinese fallback and English localized manifest
identity, begins and saves a real journey, takes the browser offline, and reloads
the authored reflection with its landscape. It also installs a second worker
revision, activates it through the player-facing update action, and confirms the
new controller retains that reflection. A cache sentinel representing another
subpath deployment survives that activation, while the older `/journey/` cache
is removed. Relocatability and update behavior are
therefore tested as deployed behavior in addition to static URL inspection.

`scripts/check-build.mjs` runs after every production build and fails when:

- a required offline/install asset is missing;
- the entry document loses its exact default language, title, description,
  character encoding, or mobile viewport contract;
- ordinary and maskable install icons do not have their exact separate purposes
  or their PNG pixel dimensions differ from the declared 192/512 sizes;
- the full-bleed iOS Home Screen icon link is absent or non-relocatable;
- the exact relative hero-image preload contract is absent;
- generated public-asset revision metadata differs from the deterministic
  source `public/` path-and-content digest, any non-worker public copy differs
  from its source, or the built Worker lacks the exact bundle/public revision
  injection;
- generated HTML or CSS contains a root-absolute or remote URL;
- generated app JavaScript or the injected service worker contains a literal
  remote URL;
- the build does not contain exactly the source public tree, entry document, one
  app bundle, and one stylesheet (unexpected source maps or stray artifacts are
  rejected); or
- JavaScript, CSS, landscape, audio, or the complete distribution exceeds its
  explicit raw-byte budget.

The lint gate also exercises the public-tree digest with identical files made
in different creation orders, a same-path byte edit, and a path-only edit. This
proves the release identity is order-independent and sensitive to both parts of
its contract before the production build consumes it.

Every `npm run build` then runs Vite a second time and compares the relative
path plus SHA-256 digest of every `dist/` file. This guards the injected shell
revision against timestamps, unstable ordering, or other nondeterminism that
would otherwise create a false offline update from unchanged source.

The service worker uses the same document base, so its scope, manifest, icons,
hashed bundles, landscape, and ambience stay inside the chosen mount path.
Manifest localization is a single-file progressive enhancement and therefore
does not create another app ID, scope, request path, or cache boundary; see
[`MANIFEST_LOCALIZATION_RESEARCH.md`](MANIFEST_LOCALIZATION_RESEARCH.md).
