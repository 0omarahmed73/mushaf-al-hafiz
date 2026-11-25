#!/usr/bin/env python3
"""Gate G3 (feature 012): `--wasm` (skwasm) versus the normal JS build (CanvasKit): same pixels, first paint, 20 page turns.

Usage:
  python3 tool/web_smoke/gate_g3_wasm_vs_js.py <probe folder> --work <build folder under the scratchpad> [--url http://127.0.0.1:8767] [--runs 3]

The probe is the G1 probe (scratchpad `$GATES/g1_fontloader/`, which has a `mode=turns` for this gate). It is copied to --work/app and built
twice into --work/site/{js,wasm}; the caller serves --work/site at --url with `python3 -m http.server` (harness-tracked background command).
PASS: pages 1, 2, 50 are pixel-identical between the two builds AND the wasm build is not slower (median of --runs, within 10 %% on first
paint and on the median page turn). Chromium only (nothing is downloaded); Firefox and WebKit are reported «not run».
"""
from __future__ import annotations

import argparse
import json
import statistics
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import _probe_common as c  # noqa: E402

BUILDS = {"js": [], "wasm": ["--wasm"]}

SHOT = r"""
const { chromium } = require(process.env.PLAYWRIGHT_CORE);
(async () => {
  const [url, out, doneMarker] = process.argv.slice(1);
  const b = await chromium.launch({ headless: true });
  const ctx = await b.newContext({ viewport: { width: 412, height: 700 }, deviceScaleFactor: 1 });
  const p = await ctx.newPage();
  const logs = [];
  p.on('console', m => logs.push(m.text()));
  p.on('pageerror', e => logs.push('pageerror ' + String(e).slice(0, 300)));
  const t0 = Date.now();
  await p.goto(url);
  while (Date.now() - t0 < 60000 && !logs.some(l => l.startsWith(doneMarker) || l.startsWith('G1 error'))) await p.waitForTimeout(20);
  const elapsed = Date.now() - t0;
  if (out !== '-') { await p.waitForTimeout(800); await p.screenshot({ path: out }); }
  await b.close();
  console.log(JSON.stringify({ elapsed, logs: logs.filter(l => /^G[13] |pageerror/.test(l)) }));
})();
"""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("probe", type=Path)
    ap.add_argument("--work", type=Path, required=True)
    ap.add_argument("--url", default="http://127.0.0.1:8767")
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--skip-build", action="store_true")
    a = ap.parse_args()
    work = a.work.resolve()
    site = work / "site"
    if not a.skip_build:
        app = work / "app"
        c.copy_probe(a.probe, app)
        site.mkdir(parents=True, exist_ok=True)
        for folder, flags in BUILDS.items():
            print(f"building {folder} ...", flush=True)
            c.flutter_build(app, site / folder, "--base-href", f"/{folder}/", *flags)
    shots = work / "shots"
    shots.mkdir(exist_ok=True)
    res: dict = {"builds": {}}
    for folder in BUILDS:
        for page in (1, 2, 50):
            c.node_json(SHOT, f"{a.url}/{folder}/?page={page}&fmt=woff2", str(shots / f"{folder}_p{page}.png"), "G1 done")
        first, turns, errs = [], [], []
        for _ in range(a.runs):
            r = c.node_json(SHOT, f"{a.url}/{folder}/?page=1&fmt=woff2", "-", "G1 done")
            first.append(r["elapsed"])
            r = c.node_json(SHOT, f"{a.url}/{folder}/?mode=turns&fmt=woff2", "-", "G3 done")
            t = [int(l.split("ms=")[1]) for l in r["logs"] if l.startswith("G3 turn")]
            errs += [l for l in r["logs"] if "pageerror" in l]
            turns.append(t[1:21])  # page 1 is the first paint; pages 2..21 are the 20 turns
        flat = [x for t in turns for x in t]
        res["builds"][folder] = {
            "first_paint_ms_runs": first,
            "first_paint_ms_median": statistics.median(first),
            "turn_ms_median": statistics.median(flat),
            "turn_ms_p90": sorted(flat)[int(len(flat) * 0.9) - 1],
            "turns_counted_per_run": [len(t) for t in turns],
            "errors": errs,
        }
    diffs = {f"p{p}": c.diff_pixels(shots / f"js_p{p}.png", shots / f"wasm_p{p}.png")[0] for p in (1, 2, 50)}
    res["pixel_diff_js_vs_wasm"] = diffs
    j, w = res["builds"]["js"], res["builds"]["wasm"]
    equal = all(v == 0 for v in diffs.values())
    not_slower = w["first_paint_ms_median"] <= j["first_paint_ms_median"] * 1.10 and w["turn_ms_median"] <= j["turn_ms_median"] * 1.10 + 2
    res["equal_pixels"], res["wasm_not_slower"] = equal, not_slower
    res["firefox_webkit"] = "not run (no engine installed, no download approved)"
    print(json.dumps(res, indent=1))
    ok = equal and not_slower and not j["errors"] and not w["errors"]
    print("G3 " + ("PASS (keep --wasm)" if ok else "FAIL (use the normal JS build)"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
