# Forced colors and narrow reflow

This research pass began after the unblocked feature queue was complete. It
targets presentation robustness without adding an unvalidated narrative choice.

## Primary-source findings

- [W3C's Reflow explanation](https://www.w3.org/WAI/WCAG21/Understanding/reflow.html)
  defines the relevant narrow state as 320 CSS pixels and requires content and
  functionality without two-dimensional scrolling.
- [MDN's forced-colors reference](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/forced-colors)
  explains that the browser substitutes a user-selected system palette, removes
  box shadows, and recommends only targeted compatibility adjustments.
- [W3C's Focus Appearance explanation](https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html)
  identifies a two-CSS-pixel perimeter as the minimum indicator area. The game
  retains its three-pixel focus outline.

## Repository decision

The game continues to use native buttons, inputs, fieldsets, details, and links
so the browser can assign appropriate system colors. Forced-color CSS removes
only decorative landscape/noise layers, replaces blur-dependent presentation,
gives the primary action an explicit system border, and restores a visible
current-route marker after forced colors remove its inset shadow.

The first tab stop is a bilingual, focus-visible skip link targeting the current
story heading. This avoids forcing keyboard and screen-reader users through the
journal, chronicle, and settings before each story action. The expanded 360 px
audit also keeps undiscovered chronicle labels above minimum contrast and recent
route controls at least 44 CSS pixels high.

Scene transitions use one announcement mechanism: focus moves to the new native
`h1`. The story container is not also a live region. WAI's
[ARIA19 technique](https://www.w3.org/WAI/WCAG21/Techniques/aria/ARIA19)
describes live regions as announcing content without moving focus, while the
[status-message failure test](https://www.w3.org/WAI/WCAG21/Techniques/failures/F103)
explicitly excludes changes that take focus. Combining both mechanisms here
could announce the same scene twice.

Character-only shortcuts are active only while focus is inside the current
story component, and their target controls expose `aria-keyshortcuts`. This
uses the focus exception in WCAG 2.2's
[Character Key Shortcuts criterion](https://www.w3.org/WAI/WCAG22/Understanding/character-key-shortcuts.html):
speech input or an accidental `L`, `R`, `1`, or `2` while focus is in settings,
the masthead, or the sidebar cannot change the game.

Automated audit A03 emulates forced colors and reduced motion at exactly 320 CSS
pixels, opens settings, completes all five regions, checks horizontal reflow,
checks that the operating-system motion preference reduces story animation to
the bounded near-zero duration, checks the authored three-pixel focus indicator
and route marker, and requires zero Axe violations at both settings and ending
states.

## Language-switch control

WCAG 2.2 requires the language of a phrase to be programmatically determinable
so assistive technology can apply the right pronunciation rules. The HTML
Standard defines `lang` for both an element's contents and its text-bearing
attributes. Sources: [W3C Language of Parts](https://www.w3.org/WAI/WCAG22/Understanding/language-of-parts),
[HTML `lang`](https://html.spec.whatwg.org/multipage/dom.html#attr-lang).

The language switch is an intentional language exception: in the Chinese UI it
visibly says “English,” and in the English UI it visibly says “中文.” Its full
accessible name now uses that same target language (“Switch to English” or
“切换到中文”), contains the visible label, and the button declares `lang="en"`
or `lang="zh-CN"` respectively. The document and every other control remain in
the active interface language. Unit rendering assertions and browser journey
J07 verify both target-language states before and after the switch.

## Touch target consistency

WCAG 2.2's [Target Size (Minimum)](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html)
sets a 24 by 24 CSS-pixel AA floor, while
[Target Size (Enhanced)](https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced.html)
uses 44 by 44 CSS pixels. The game applies the enhanced size to every visible
pointer target: language, route, story and ending actions;
journal/chronicle/settings/share disclosures; the skip link when focused;
preference labels; audio controls; the volume range; storage protection;
backup; restore; and clear-data actions all expose at least a 44 by 44
CSS-pixel target.
The native radio remains visually compact inside its 44-pixel activation label.

A01 measures the rendered geometry of every visible target on the intro and in
expanded settings before and after the viewport narrows to 360 CSS pixels. A02
repeats that measurement for the encounter, every aftermath, and the complete
ending/share surface. A03 measures all controls throughout the 320 CSS-pixel
forced-colors journey. This catches later padding, font, or layout changes that
would silently shrink the usable target even if a CSS declaration still looked
correct in source.

A05 combines English, 320 CSS pixels, large text, reduced motion, and high
contrast through a complete ending. Its first run found that pointer hover could
move the primary action by 2px and reflow choice text through changing padding;
at the narrow boundary Playwright's real pointer could not reach a stable click.
Hover feedback now changes only paint (color, background, and inset shadow), so
the hit geometry remains fixed. The audit rejects horizontal overflow,
undersized targets, and Axe violations in that combined state.

A06 starts at the first Tab stop, uses the skip link, then completes all five
regions using only native Tab, Enter, and Space activation. It requires each
new scene heading to receive focus, each next native action to follow it in the
sequential order, and the ending's replay action to be the next control. This
extends the scoped-shortcut evidence with a complete no-pointer path.

## Discoverable gated choices

ink's official [conditional-choice documentation](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md#conditional-choices)
demonstrates the common alternative of omitting an unavailable option entirely.
This game deliberately shows its four resource-gated actions because the action
wording and exact threshold explain how earlier decisions change later agency.

WAI's [keyboard-interface guidance](https://www.w3.org/WAI/ARIA/apg/practices/keyboard-interface/)
notes that screen-reader users are less likely to discover disabled elements
that cannot receive focus, and recommends `aria-disabled="true"` when a disabled
element needs to stay discoverable. Locked story choices therefore remain
native buttons in the sequential focus order with `aria-disabled="true"` rather
than the native `disabled` attribute. The delegated pointer handler and scoped
number shortcuts both reject activation until the live requirement passes.
Their locked label uses the contrast-tested secondary ink token rather than a
low-alpha inactive-control exemption, while the exact requirement retains its
cinnabar treatment. Forced colors maps the complete locked action to system
`GrayText`.

J24 focuses and presses Enter on a locked choice, proves the encounter cannot
advance, then replays the exact route with sufficient trust and proves the same
button becomes operable. A02 also runs Axe with that locked control focused.
That expanded state exposed insufficient contrast in the solitary-route
callback over its translucent panel; callback prose now uses the primary ink
token, and A02 retains the low-trust route so the regression cannot hide behind
the collaborative happy path.
The real assistive-technology pass remains a release gate; automated focus and
semantic evidence do not replace it.

Automated evidence is not labeled as a screen-reader pass. The repeatable
desktop/mobile assistive-technology tasks and blocking criteria for a real
release live in
[`ASSISTIVE_TECH_RELEASE_CHECK.md`](ASSISTIVE_TECH_RELEASE_CHECK.md).

## Cross-tab alert-dialog focus

The cross-tab/BFCache ownership conflict is terminal: the stale page cannot be
resumed safely and exposes one **Reload newer progress** action. Its background
session is visually obscured and marked `inert`, initial focus moves to that
action, and unmodified Tab or Shift+Tab cycles back to the same action. Browser
tab-switch modifiers remain browser-owned. After activation the action stays
focusable with `aria-disabled` while reload is pending, but duplicate activation
is ignored; an intercepted or delayed navigation therefore does not leave an
empty modal tab sequence. This follows WAI's
[Alert and Message Dialog pattern](https://www.w3.org/WAI/ARIA/apg/patterns/alertdialog/),
which requires modal content outside the dialog to be inoperable and its tab
sequence to remain inside. A04 verifies the focus entry, both tab directions,
inert background, and zero Axe violations in the rendered conflict state.
