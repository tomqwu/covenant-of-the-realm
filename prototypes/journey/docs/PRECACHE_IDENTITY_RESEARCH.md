# Precache identity research

## Failure boundary

The worker registration URL originally carried only the hashed JavaScript
bundle name. That isolates ordinary application-code releases, but it is not
sufficient when the service-worker script, manifest, audio, artwork, icon, or
required public-asset list changes while the app bundle does not. In that case
a newly installing worker and the active worker could otherwise open the same
named cache. A partial installation that deletes its cache during rollback
could then delete the active offline shell; cache-first audio could also remain
stale indefinitely after a same-path replacement.

Adding the separate maskable icon made this boundary concrete: `CORE_PATHS`
changed independently of the application modules.

## Decision

Cache identity now has five independent components:

1. encoded registration scope;
2. manually reviewed behavior schema (currently `v9`);
3. an automatically derived FNV-1a signature of both required and optional
   precache path lists; and
4. the full/reduced data mode;
5. a sanitized SHA-256 prefix of the final generated entry document, injected
   into the built Worker body. That document already contains the hashed
   JavaScript/stylesheet names and deterministic `public/` tree revision.

Changing a path in either precache list or changing any public file's path or
bytes therefore opens a distinct candidate cache even when the JavaScript
bundle hash stays the same. A worker-algorithm or cache-contract change still
requires a manual schema increment. The build injects the public-tree revision
into generated HTML and the combined release revision into `dist/sw.js`.
Production registers the stable Worker path; a changed release therefore
changes the Worker's bytes and uses the browser's normal update algorithm. The
post-build checker recomputes the source-tree digest and corresponding
non-worker paths inside `dist/`, then verifies the one intentional Worker
transformation exactly, so stale metadata, missing copies, or unexpected byte
differences cannot ship.

The signature is not a security primitive. It is a compact deterministic cache
namespace used only to prevent lifecycle aliasing; same-origin responses and
the local-only content policy remain the security boundary.

## Verification

- J15 requires a `v9-<precache>-full-shell-<digest>` cache, proves the active
  Worker URL has no release query and its cache uses the build-verified shell
  revision, then resumes a saved reflection offline.
- J29 requires the corresponding `v9-<precache>-reduced-<release>` identity and
  proves optional audio is absent until player opt-in.
- D01 serves a second byte-distinct build from the same Worker URL, installs and
  activates it while retaining progress, and deletes only old caches from its
  own scope.
- D02 fails the newly required maskable icon and proves the candidate cache is
  deleted while the active controller and offline reflection survive.

This turns every entry-document, app, style, and public-tree edit—including a
same-path asset replacement—into a transactionally isolated offline-shell
change.
