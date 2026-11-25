# Gate verdicts of feature 012

One file per gate: `G<n>.md`. Every file has these fields.

| Field | Meaning |
|---|---|
| Gate | G1 to G7 and the question it answers |
| Date | the day it was run |
| Command | the exact command(s) run (probe apps live in the scratchpad `$GATES`, never in the repository) |
| Engines | the browser engine(s) and version(s) actually used; engines not run are written «not run» with the reason |
| Measured numbers | the numbers, not adjectives |
| Verdict | `PASS`, `FAIL` or `BLOCKED` (with the exact reason) |
| Consequence for the plan | which decision it fixes (font extension, build flag, storage notice, fallback list) |
