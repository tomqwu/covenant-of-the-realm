# Release readiness checklist

## Current status

The repository is locally release-candidate ready: the production artifact is
static and relocatable, all named checks run through `make check`, the lockfile
is present and used by reproducible setup, the CI workflow is read-only and
SHA-pinned, and the browser
matrix covers complete desktop/mobile play plus root and nested-path offline
deployment. It is not yet publicly released because no remote, license,
security-reporting contact, or hosting target has been chosen.

Those are owner and deployment decisions, not missing game code. Do not guess
them or add a workflow that can publish to an unknown destination.

## Before creating a public remote

- [ ] Choose repository visibility and a license. GitHub notes that a public
  repository without a license remains under default copyright and is not an
  open-source grant; the owner must make that choice deliberately. See
  [GitHub's licensing guidance](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository).
- [ ] Choose a private security-reporting route and add a root or `.github/`
  `SECURITY.md` containing supported versions and reporting instructions. The
  existing `docs/SECURITY.md` documents the technical boundary; it intentionally
  does not invent a contact. See
  [GitHub's repository-security guidance](https://docs.github.com/en/code-security/getting-started/quickstart-for-securing-your-repository).
- [ ] Create the first commit intentionally, add the remote, and confirm the
  intended default branch. The current local repository has no commits and no
  remote.
- [ ] Let the existing **Check / check** job pass once, then require that exact
  job through a branch ruleset before merging. Required checks apply only after
  a check with that name exists; GitHub distinguishes strict/up-to-date and
  loose modes. See
  [available ruleset rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets).
- [ ] Add the remote-specific Actions badge without replacing the two local
  evidence badges, then verify its repository and branch URL.

## Choose and verify hosting

- [ ] Select an HTTPS static host and its final root or subpath. Installable
  PWAs require HTTPS outside loopback development; `file://` is not a production
  path. See
  [MDN's installability requirements](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Making_PWAs_installable).
- [ ] Give production, staging, and review copies distinct origins when their
  player records must be independent. Subpaths isolate Worker caches but not
  `localStorage`; follow
  [`STORAGE_SCOPE_RESEARCH.md`](STORAGE_SCOPE_RESEARCH.md).
- [ ] If GitHub Pages is chosen, enable **Pages → GitHub Actions** first and add
  a separate build/deploy workflow only then. The deploy job needs `pages: write`
  and `id-token: write`, must depend on the artifact-producing job, and should
  use the protected `github-pages` environment. See
  [GitHub's custom Pages workflow contract](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages).
- [ ] Configure response headers at the host: at minimum preserve the shipped
  CSP and referrer policy, add `X-Content-Type-Options: nosniff`, and set an
  explicit `frame-ancestors` policy. `frame-ancestors` cannot be enforced from
  the current CSP meta element, so this is necessarily host-owned. See
  [MDN's `frame-ancestors` reference](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Security-Policy/frame-ancestors).
- [ ] Apply and measure the HTTP-cache matrix in
  [`HOST_CACHE_RESEARCH.md`](HOST_CACHE_RESEARCH.md): HTML, `sw.js`, and
  fixed-name public assets must revalidate; only content-hashed JS/CSS may be
  year-long immutable. Prove an already-installed copy discovers a same-path
  public-asset release without clearing browser data.
- [ ] Run `make check`, publish only the resulting `dist/`, then repeat D01's
  real tasks at the final URL: begin, save, install, go offline, relaunch, apply
  one update, and open a copied exact-route link.
- [ ] Keep a second controlled tab open while applying that live update. It must
  enter the D04 reload dialog, reject old-code interaction, and resume the same
  saved scene after explicit reload.
- [ ] Confirm the deployed page makes no third-party or unexpected production
  requests and that the service-worker scope exactly matches the chosen mount.
- [ ] Disable JavaScript at the final URL on a 320 CSS-pixel viewport. Confirm
  the bilingual explanation is readable, the manifest remains in scope, and
  the page has no horizontal overflow; this mirrors deployment audit D05 under
  the host's actual CSP and rewrite rules.

## Real-device release evidence

Automated WebKit/Firefox smoke proves ordinary browser play, not installation
on every operating system. Install UI and behavior vary by browser and platform;
MDN specifically calls for cross-browser/OS testing in
[PWA best practices](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Best_practices).

- [ ] Complete Chinese and English touch journeys on one physical narrow phone.
- [ ] Install and offline-relaunch on one Chromium desktop or Android device.
- [ ] Add to Home Screen and offline-relaunch on one current iOS/iPadOS device.
- [ ] Verify ordinary web play remains complete on a browser that does not offer
  the same manifest-install path.
- [ ] Check installed icon cropping, standalone window title/theme, text zoom,
  reduced motion, high contrast/forced colors where supported, mute, and local
  clearing.
- [ ] Complete the desktop/mobile screen-reader and keyboard protocol in
  [`ASSISTIVE_TECH_RELEASE_CHECK.md`](ASSISTIVE_TECH_RELEASE_CHECK.md), record
  exact versions/results, and close every blocking finding.
- [ ] Run the five-session external playtest before adding any gated gameplay or
  install surface. Record observations in `PLAYTEST_SCORECARD.md`.

## Release decision

Ship only when every applicable item above has an owner and evidence link. A
license, security contact, live URL, branch rule, or physical-device result must
never be marked complete from a local simulation. If hosting changes later,
repeat the header, scope, nested-path, update, and offline checks before moving
players to the new origin.
