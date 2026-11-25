# G4-prep: the synthetic test site and what the owner will be asked to do

| Field | Value |
|---|---|
| Gate | G4 preparation (research D1): can Vercel (Hobby) serve a Git-connected static site of the real size with the right headers? |
| Date | 2026-11-21 |
| Command | `python3 tool/web_smoke/make_placeholder_site.py $GATES/g4_site_repo` then `git init`, `git add -A`, one commit in that folder (no remote) |
| Engines | none (no browser involved in the preparation) |
| Measured numbers | 1,667 files; 144,733,796 bytes (144.7 MB; 142 MiB on disk); one local commit; `git remote -v` is empty; the pack of random bytes is about the same size as the files (they do not compress, a real site's fonts do) |
| Verdict | **PREPARED** (not a gate verdict). Nothing was pushed, uploaded or deployed. G4 itself waits for the owner (T014 to T016) |
| Where | scratchpad folder `$GATES/g4_site_repo/` (outside the repository). It is synthetic: random bytes, no Quran data, no app code. `index.html` says it is a deployment test |
| Consequence for the plan | The publish path (T155a to T159) stays blocked until G4 is PASS (`tool/check_publish_ready.py`, T153) |

## What the owner will be asked to do (only after saying «ارفع» for this test)

1. Create a **private** GitHub repository for the built site (any name; the owner chooses).
2. Push the placeholder to it from the scratch repository (the owner runs `git remote add` and `git push` themselves; no token is given to anyone else).
3. Sign in to Vercel themselves (own account, Hobby plan) and import that repository: Framework preset «Other», **no build command**, output directory = the repository root.
4. Deploy once and open the preview address; confirm that Web Analytics, Speed Insights and any toolbar are **off**.
5. Give the assistant the test address, so T016 can run `curl -sI` on the sample files (`.wasm` Content-Type, compression, Cache-Control, the CSP, no COOP/COEP) and confirm that a Git deployment of this size was accepted.
6. After T016, delete the trial deployment or keep it private and unlisted, and say which in `gates/G4.md`.

No password, token or key is typed or stored by anyone else (FR-037). The trial is not the public address of FR-036 and SC-013.
