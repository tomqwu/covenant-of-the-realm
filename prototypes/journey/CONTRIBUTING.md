# Contributing

## Before coding

- Use Node.js 22.12.0 or newer; `.node-version` gives compatible version
  managers a repository-local baseline, and setup/check fail fast below it.
- Confirm the intended behavior and acceptance criteria in
  `.loop/REQUIREMENTS.md` or the task description.
- Keep one change focused on one outcome.
- Run `make setup` after cloning and whenever dependency locks change.
  It installs the version-matched Chromium, Firefox, and WebKit test runtimes in
  addition to locked packages; the browser cache requires several hundred MB.
  Linux CI sets `PLAYWRIGHT_WITH_DEPS=1` so the same step installs required OS
  libraries without downloading the browser runtimes a second time.

## Validation

Run the same command used by continuous integration:

```sh
make check
```

`make check` must remain non-mutating. If formatting is later automated, expose
it as a separate `make format` target and keep a check-only formatter command in
the validation path. The current lint gate also resolves every repository-local
Markdown link, so move or rename documentation and its references together.

GitHub CI retains coverage output, the Playwright HTML report, traces, and
failure screenshots for seven days only when validation fails. Use that
diagnostic artifact before attempting to reproduce a browser-only failure.

Dependabot groups locked npm development tooling and official workflow actions
into separate bounded weekly updates. Treat each update like any other change:
review release notes and require `make check` before merge. Workflow actions are
pinned to immutable full commit SHAs, with the reviewed release line retained in
a comment; the lint gate rejects a mutable tag or branch.

Do not commit focused, skipped, placeholder, `fixme`, or expected-failure tests.
The lint gate rejects those markers in every unit and browser spec, so a
temporarily narrowed local run cannot be mistaken for release evidence.

CI keeps two Playwright retries to collect a trace and distinguish transient
behavior, but `failOnFlakyTests` makes any retry-only pass fail the job. A green
release therefore requires every browser journey to pass on its first attempt.

## Change description

Explain the user-visible outcome, the verification performed, and any risk or
follow-up. Update `.loop/PLAN.md` and `.loop/STATE.md` when the repository's
current objective or handoff state changes.

Narrative changes must also follow `docs/CONTENT_AUTHORING.md`; its executable
contract is part of the unit suite.

Keep bilingual interface text in `UI_COPY` only when it has a rendered or
behavioral consumer. The lint gate parses the TypeScript source and rejects
orphaned top-level copy keys, preventing removed UI from leaving untranslated
dead strings behind.
