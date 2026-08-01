# Install-manifest localization research

## Question

The running game changes its document language, title, and description when the
player changes language. Should the installed app name remain Chinese for every
player, or can the static, offline manifest expose the same English identity
without adding a server or a second application identity?

## Platform evidence

The Web App Manifest Working Draft defines `*_localized` language maps for
localizable members. A user agent should choose the value that best matches the
user's localization settings and use the ordinary member as its fallback.
`name` and `short_name` remain the security-sensitive installed identity.

Source: [W3C Web Application Manifest — localized members](https://www.w3.org/TR/appmanifest/#x_localized-members).

Chrome and Edge shipped the mechanism in version 148 for `name`, `short_name`,
`description`, icons, and shortcut metadata. Browsers that do not implement the
new fields still parse the JSON manifest and ignore members they do not know.

Sources: [Chrome for Developers — manifest localization](https://developer.chrome.com/blog/manifest-localization),
[MDN — `*_localized`](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Manifest/Reference/%2A_localized).

## Decision

Keep the Chinese strings and `lang: zh-CN` as the stable default identity, then
add English `name_localized`, `short_name_localized`, and
`description_localized` values. Both languages are left-to-right, so the
manifest now declares `dir: ltr`.

This is progressive enhancement:

- Chrome/Edge 148+ can show an English install identity when English is the
  user's preferred browser language;
- other browsers retain the complete existing Chinese identity;
- the app ID, start URL, scope, icons, theme, offline cache, and in-game locale
  remain unchanged; and
- no locale is sent to a server or placed in a second manifest URL.

The manifest follows browser/OS language, not the in-game toggle. That is an
intentional platform boundary: dynamically replacing the manifest link after a
toggle would have uneven install-surface behavior and would couple one app
identity to page state. Revisit only if interoperable user-agent support makes
the installed identity reliably follow an explicit app locale.

## Verification

- The production artifact checker requires the exact default identity, English
  language-map values, categories, direction, orientation, scope, display, icon
  MIME declarations, purposes, and real PNG dimensions.
- Deployment audit D01 fetches the real manifest from a nested `/journey/`
  mount and checks both the default and English representations before testing
  installation, update, and offline behavior.
- Unknown-field fallback does not require JavaScript and cannot prevent older
  browsers from reading the ordinary manifest members.
