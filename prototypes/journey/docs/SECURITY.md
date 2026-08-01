# Static security boundary

The game has no account, backend, form submission, runtime third-party script,
or remote asset dependency. Its browser boundary is defense in depth around
local/imported data and static hosting.

The player-facing retention, sharing, and deletion boundary is documented in
[`PRIVACY.md`](PRIVACY.md).

## Document policy

`index.html` declares a Content Security Policy that:

- allows scripts, workers, media, and the manifest only from the current origin;
- rejects inline script, inline style, and dynamic evaluation in production;
- allows styles only from the current origin; bounded DOM data attributes drive
  reading and progress variants without CSSOM/element-style execution;
- disables document-base mutation, objects, form submission, and embedded
  frames;
- restricts images to same-origin/data URLs;
- permits only same-origin connections in the production artifact; the source
  policy's loopback WebSockets and inline development styles support Vite HMR
  and are removed/tightened by the build;
  and
- uses `no-referrer` so shared route details are not sent in outbound referrers.

HTTP deployments may add stricter response headers such as `frame-ancestors`
and `X-Content-Type-Options`; those directives cannot be fully expressed by a
portable static meta policy.

## Data boundaries

- Journey, chronicle, preference, audio, and backup data pass structural and
  semantic validation before use.
- Persisted narrative prose is HTML-escaped at every render boundary.
- Exact-route URL values accept only authored, region-ordered encounter IDs.
- Backup file size is bounded and restore requires a separate explicit action.
- Chronicle path records are capped at 128, and the maximum valid bundle is
  tested below the same 256 KB import ceiling.
- Device sharing is capability-detected and invoked only by a direct button
  action. The browser chooses the destination; the game neither learns the
  target nor transmits the artifact through its own network service.
- Completed-journey text export uses a short-lived local Blob URL and the same
  visible artifact; it adds no network request or hidden metadata.
- A failed backup download renders escaped JSON into a read-only textarea; it is
  never interpreted as markup and is invalidated by newer local state.
- Local clearing and restore attempt to roll back all records if a storage
  operation fails.

## Development supply chain

- `npm ci` installs the committed lockfile and the repository currently has no
  production runtime dependency.
- The check workflow grants its token only read access to repository contents.
- Every external workflow action is pinned to a full 40-character commit SHA;
  the reviewed major release remains in a comment for Dependabot maintenance.
- Weekly bounded Dependabot groups cover npm tooling and GitHub Actions.
- The lint gate rejects mutable workflow tags and branches before CI can run
  them.

## Evidence

- S01 proves event-handler-shaped persisted prose stays inert after reload.
- S02 reads the shipped policy, proves document-base mutation, inline script,
  inline style permission, and string-timer evaluation are blocked, then starts
  normal play.
- S03 exercises settings, audio preparation, persistence, complete play, and
  download while rejecting any console error, failed/error response,
  cross-origin request, CSP violation, cookie, or undocumented browser record.
- Every production build checks the complete directive/value set of the
  local-only policy, no
  referrer, relocatable/local asset URLs in the document, stylesheet, manifest,
  SVG icon, generated app JavaScript, and injected service worker, plus size
  budgets. The output file set is exact, so an accidental source map or unrelated
  artifact cannot silently enter the published directory.
- `npm run workflow:check` proves every external action reference is immutable
  and the check workflow retains only ordinary push/PR triggers, explicit
  read-only permissions, the `make check` entry point, and failure-only
  seven-day coverage/Playwright diagnostics rather than a broad workspace
  upload. The same check locks Dependabot to bounded weekly npm-development and
  official-workflow groups.
