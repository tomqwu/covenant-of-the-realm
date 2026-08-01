# Maskable install-icon research

## Problem

The install manifest originally marked the same rounded, transparent-corner
icons as both `any` and `maskable`. That is syntactically accepted, but it gives
adaptive-icon platforms an asset whose transparent corners can be composited
onto a user-agent-selected fill and whose normal-icon composition was not
designed around an arbitrary system mask.

## Platform evidence

The Web App Manifest specification defines the guaranteed maskable safe zone as
a circle centered on the image with a radius of 40% of its size. Important
content must remain inside that circle; the user agent may make pixels outside
it transparent. The specification also recommends avoiding transparent pixels
in maskable icons.

Source: [W3C Web App Manifest — icon masks and safe zone](https://www.w3.org/TR/appmanifest/#icon-masks).

The Chrome/web.dev guidance recommends a separate opaque maskable asset and
warns that combining `any maskable` adds maskable padding when the icon is used
in ordinary contexts.

Source: [web.dev — adaptive icon support with maskable icons](https://web.dev/articles/maskable-icon).

WebKit has used manifest-declared `any` icons on iOS/iPadOS since 15.4, but an
explicit `apple-touch-icon` takes precedence. Apple's Web Clip guidance says the
system supplies its own crop/effects, which makes the same full-bleed adaptive
asset a better iOS source than the already-rounded ordinary icon.

Sources: [WebKit — Safari 15.4 manifest icons](https://webkit.org/blog/12445/new-webkit-features-in-safari-15-4/),
[Apple — configuring Web Clip icons](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/ConfiguringWebApplications/ConfiguringWebApplications.html#//apple_ref/doc/uid/TP40006513-SW8).

## Decision and asset contract

- The existing 192px, 512px, and scalable rounded icons now have the single
  `any` purpose.
- `app-icon-maskable-512.png` is a separate opaque, square derivative with the
  paper color extending to every edge and the artwork scaled to 84% around the
  center. The complete mountain/road/seal mark fits within the guaranteed safe
  circle.
- Its editable vector source is
  `docs/art-source/app-icon-maskable.svg`; the production PNG is local and has
  been visually inspected at its native 512px size.
- The maskable asset is part of the service worker's required core shell, so an
  incomplete first install or update cannot publish an install identity that
  disappears offline.
- The document also references this full-bleed file as its relative
  `apple-touch-icon`. iOS can apply its own Home Screen crop without nesting the
  transparent rounded ordinary icon inside another system shape.

No new branding or generated art was introduced: the derivative uses the
existing project-local vector paths, palette, and seal.

## Verification

- The production checker requires all four files and enforces exact MIME,
  declared-size, real PNG dimension, and separate `any`/`maskable` purpose
  values.
- D01 fetches the nested-path manifest and checks that ordinary and maskable
  512px entries are both present with distinct purposes, then resolves the iOS
  touch-icon link inside the same nested mount. It decodes that real PNG into a
  browser canvas and requires 512×512 dimensions plus alpha 255 for every pixel.
- D02 deliberately fails the maskable asset during an update and proves the
  partial cache is discarded while the active offline build survives.
