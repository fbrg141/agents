# Review standards

Copy this file to the root of a project as `REVIEW.md` and edit it. The `go`
skill passes it to the reviewing models, which check diffs against it under
"Standards". Keep it short: list what reviewers should flag, not general advice.

## Must hold
- <e.g. Every public function has a test that exercises its error path.>
- <e.g. No new dependency without a note in the PR description.>

## Flag
- <e.g. SQL built by string concatenation.>
- <e.g. Errors caught and ignored.>

## Ignore
- <e.g. Formatting; the formatter handles it.>
