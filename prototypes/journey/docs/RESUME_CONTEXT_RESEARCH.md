# Delayed-resume context research

## Question

The game restores one autosaved scene immediately. Does a returning player need
a separate recap, timestamp, or screenshot to understand that restored state?

## Comparable engine patterns

Ren'Py's default save/load UI is built around slots that show a screenshot and
save time, and its save API exposes modification time, screenshot, runtime, save
name, and custom metadata. These fields help distinguish several long-form
states before choosing one.

Sources: [Ren'Py GUI customization — save slots](https://www.renpy.org/doc/html/gui.html#save-slot-buttons),
[Ren'Py saving/loading metadata](https://www.renpy.org/doc/html/save_load_rollback.html).

SugarCube supports configurable auto/slot saves, descriptions, titles, metadata,
and a Continue action for the latest browser save. Its documentation recommends
small bounded slot counts because browser storage is limited. It separately
maintains a temporary playthrough session to survive refresh/background unload.

Source: [SugarCube 2 documentation — saves and playthrough session](https://www.motoslave.net/sugarcube/2/docs/#save-api).

Ink exposes serialization/loading of the complete story state but does not
prescribe a save-selection interface; the host game owns presentation.

Source: [Ink — running, saving, and loading a story](https://github.com/inkle/ink/blob/master/Documentation/RunningYourInk.md#saving-and-loading).

## Fit to this game

This product has one short unfinished autosave, not a gallery of concurrent
long-form states. Every restored reflection already names the completed region,
choice, aftermath, and next-region action. Every restored encounter exposes the
route position, resources, journal count, and any authored callback. The journal
can reveal all earlier decisions. Recent completed routes are separately
identified by ending, seed, and final stats.

Therefore:

- do not add save thumbnails: the decorative landscape is substantially the
  same across scenes, screenshots add local bytes, and visual appearance is not
  required to identify narrative state;
- do not add completion or save timestamps merely to imitate slot UIs: they add
  personal temporal metadata to backups without distinguishing multiple
  unfinished saves;
- do not interpose a modal “Continue” screen before the current direct resume;
  it would add a click without evidence of disorientation; and
- keep the existing single autosave, visible journal, exact recent routes, and
  portable backup as the control condition.

## Evidence gate

Run an optional delayed-return probe with the five-player protocol:

1. On a separate fixed route, stop immediately after the third decision's
   reflection and close the tab.
2. At least 24 hours later, reopen the same browser profile without reminding
   the participant of the prior scene.
3. Measure time until they can state both what they last chose and what the
   traveler is currently trying to do. Record whether they open the journal.
4. Ask only afterward: “Was anything missing when you came back?”

Prototype a recap only if at least **2/5** participants cannot orient to both
facts within ten seconds or independently request a reminder. A stated desire
for multiple unfinished saves belongs to the separate save-slot gate and does
not satisfy this one.

## Bounded prototype if the gate passes

- Render one non-modal bilingual “Resuming” line only when a valid non-intro
  save was loaded at mount.
- Derive it from the existing last journal entry and current/next region; add no
  timestamp, screenshot, new storage field, or analytics.
- Do not move focus away from the restored story heading or auto-open the
  journal.
- Keep direct play, keyboard shortcuts, 320px reflow, and screen-reader heading
  context intact.
- Add one unit test for loaded-vs-fresh visibility and one production browser
  journey covering reflection and encounter resumes.

Kill the prototype if the reminder merely repeats the already visible
reflection/callback, delays first action, or fewer than two participants need it
in a second delayed-return round.
