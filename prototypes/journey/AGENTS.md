# Repository operating instructions

These instructions apply to the entire repository. A more deeply nested
`AGENTS.md` may add narrower instructions for its own subtree.

## Start every loop

1. Read `README.md`, `.loop/REQUIREMENTS.md`, `.loop/PLAN.md`, and
   `.loop/STATE.md`.
2. Inspect `git status --short` and preserve changes you did not create.
3. Select one unblocked plan item, or the smallest outcome explicitly requested
   by the user. User instructions take precedence over the plan.
4. State or infer testable acceptance criteria before making a broad change.

If the requirements do not support a product or architecture decision, record
the question in `.loop/STATE.md` and stop at the decision boundary. Do not invent
business requirements merely to keep the loop moving.

## While implementing

- Keep patches small enough to review and revert independently.
- Follow existing patterns before introducing a new dependency or abstraction.
- Add or update tests with behavior changes; prefer testing public behavior.
- Never place credentials, tokens, private data, or local machine state in the
  repository.
- Do not bypass checks by weakening assertions, deleting tests, or suppressing
  diagnostics without documenting the reason.
- Keep generated artifacts out of Git unless they are intentional deliverables.

## Finish every loop

1. Run `make check` from the repository root.
2. Update `.loop/PLAN.md` only for work actually completed.
3. Refresh `.loop/STATE.md` with the current outcome, next action, blockers, and
   exact verification command. Keep it a concise current snapshot, not a diary.
4. Review the diff for accidental files, secrets, and unrelated edits.

A loop is complete only when its acceptance criteria are met, relevant tests
exist, `make check` passes, and the state documents let another contributor
continue without reconstructing context.

## Repository command contract

- `make setup` installs or resolves dependencies.
- `make check` is deterministic and must not rewrite tracked files.
- `make lint` runs formatting/static/type checks without tests.
- `make test` runs the test suite.

Extend the existing scripts when a runtime is chosen. Do not create competing
validation commands in prose or CI.
