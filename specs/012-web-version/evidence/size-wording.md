# T005a: the size wording (owner decision of 2026-11-21)

Decision: the download button shows the real size from `pack.json`, so no text of the web feature says «about 170 MB» as a fact any more.

State of the files at this commit (checked with `grep -n 170`):

- `spec.md`: FR-031, SC-008, SC-010, User Story 9, the «Differences on the web» table and the Clarifications already say «the real size computed from the manifest (about 110 MB with WOFF2, about 172 MB with TTF, decided by gate G1)» (changed in commit 29ac2b1). No «170» is left in `spec.md`. FR-031's Arabic button label already carries `{N}` («... (نحو {N} ميجابايت)»), as does `packButton` in `contracts/ui.md`.
- `plan.md` and `quickstart.md` mention 170 only to say that it is replaced by the computed number.

Which number G1 picked: **WOFF2**. G1 (`gates/G1.md`, PASS) measured the whole Mushaf at 110,924,164 bytes (110.9 MB) with QUL's original WOFF2; the TTF route would be 172,180,056 bytes. The label therefore reads about 111 MB on the day it is computed from the manifest. The phrase «decided by gate G1» in the spec is now settled by `gates/G1.md` and is not edited again here.

Not edited here (as the task says): the constitution 1.4.0 lines 16, 28 and 208 of `.specify/memory/constitution.md` still say «about 170 MB». They are corrected by the PATCH amendment 1.4.1 of task T145a at the end of the feature.
