# T002: approval for downloads

Date: 2026-11-21. Task: T002 (OWNER APPROVAL).

Status: **NOT GRANTED, nothing downloaded.** The owner's instruction for this run is to reuse what is already installed and install nothing.

Used instead (all already on this machine):

- `playwright-core` at `~/.nvm/versions/node/v24.22.2/lib/node_modules/@playwright/cli/node_modules/playwright-core` (Node), driven from the Python runners under `tool/web_smoke/` through a `node` subprocess, because the `playwright` Python package is not installed and not downloaded.
- Cached Chromium `chromium-1255` and `chromium_headless_shell-1255` in `~/.cache/ms-playwright`.
- `fonttools` from the local uv cache (`uv run --offline --with fonttools`) and the scratchpad `w2venv`.

Consequence (as the task says): gates run on Chromium only. Firefox and WebKit are recorded «not run» (no engine installed, no download approved).
