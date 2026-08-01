# Art direction

## Visual system

- Narrative role: the landscape is the hero; events and choices sit on a quiet
  editorial layer rather than card-heavy game chrome.
- Viewing distance: laptop-first with a complete 360 px mobile adaptation.
- Temperature: contemplative and humane, with tension expressed through cost
  and copy rather than alarm colors.
- Palette: warm xuan paper, carbon ink, muted moss, and one restrained cinnabar
  accent.
- Typography: Songti-style display text paired with a restrained humanist sans
  interface stack.
- Motion: one composed story entrance and a slow panorama shift as the journey
  advances; reduced-motion preferences disable both.

## Generated landscape asset

`docs/art-source/journey-scroll-source.png` was produced with the built-in ImageGen tool
for this project. It is presentation-only and contains no game state or required
information.

Production ships `public/assets/journey-scroll.jpg`, a visually reviewed
full-resolution quality-86 derivative. The source PNG remains outside `public/`
for future art edits; the derivative reduces the offline/runtime transfer from
2,686,620 bytes to roughly 620 KB.
The build parses its JPEG frame header and requires the reviewed 1774×887
dimensions in addition to the byte budget and source-to-build digest.

Final prompt:

> Original panoramic Chinese ink-wash landscape scroll for a responsive browser
> narrative game. A lone winding road crosses five connected regions: reed
> ferry, pine ridge, rain marsh, quiet old walled town, and distant mountain
> pass. Traditional ink wash and restrained mineral pigment on warm fibrous
> xuan paper; expressive dry-brush mountains; spacious contemporary editorial
> composition; calm central negative space for interface overlays. Overcast dawn
> shifts toward pale late-afternoon light. Warm parchment, carbon ink, muted
> moss, washed blue-gray, and one very restrained cinnabar detail. No text,
> letters, symbols, seals, logo, watermark, frame, UI, neon, glossy effects, or
> photorealism.

## Original ambient asset

`public/assets/mountain-wind.ogg` is an original 32-second project-local loop
synthesized from filtered pink/brown noise and a low tonal layer, then encoded
as Opus. It contains no sampled or third-party recording. Playback is strictly
opt-in and remains subordinate to the complete silent reading experience.
The production build verifies the Ogg container, Opus identification/tags,
stereo channel count, and 48 kHz source rate without relying on a host codec;
the release audit additionally decodes the complete file with FFmpeg.

## Install icon variants

The ordinary rounded icon and the adaptive maskable icon share the same original
project-local vector mark. The latter uses a full-bleed paper background and a
safe-zone-scaled composition from
`docs/art-source/app-icon-maskable.svg`. Their separate manifest purposes and
mask behavior are documented in
[`MASKABLE_ICON_RESEARCH.md`](MASKABLE_ICON_RESEARCH.md).
