#!/usr/bin/env python3
"""Gate G1 (feature 012): does Flutter web's FontLoader accept QUL's WOFF2 and draw the same glyphs as the TTF?

Usage:
  python3 tool/web_smoke/gate_g1_woff2.py <probe folder> --work <build folder under the scratchpad> [--url http://127.0.0.1:8765]

The probe folder (scratchpad `$GATES/g1_fontloader/`) is copied to the work folder, built for CanvasKit (normal build) and for
skwasm (`--wasm`), and the work folder's `site/` is expected to be served at --url by `python3 -m http.server` started by the caller
(a harness-tracked background command). Pages 1, 2 and 50 are screenshotted per format and engine on Chromium; Firefox and WebKit
are not run unless an engine is installed (nothing is downloaded). Prints PASS only if, per engine, the WOFF2 pixels equal the TTF pixels.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import _probe_common as c  # noqa: E402

PAGES = (1, 2, 50)
FORMATS = ("ttf", "woff2")
ENGINES = {"canvaskit": ("js", []), "skwasm": ("wasm", ["--wasm"])}

SHOT = r"""
const { chromium } = require(process.env.PLAYWRIGHT_CORE);
(async () => {
  const [url, out] = process.argv.slice(1);
  const b = await chromium.launch({ headless: true });
  const ctx = await b.newContext({ viewport: { width: 412, height: 700 }, deviceScaleFactor: 1 });
  const p = await ctx.newPage();
  const logs = [], reqs = [];
  p.on('console', m => logs.push(m.text()));
  p.on('pageerror', e => logs.push('pageerror ' + String(e).slice(0, 300)));
  p.on('request', r => reqs.push(r.url()));
  await p.goto(url);
  const t0 = Date.now();
  while (Date.now() - t0 < 40000 && !logs.some(l => l.startsWith('G1 done') || l.startsWith('G1 error'))) await p.waitForTimeout(100);
  await p.waitForTimeout(800);
  await p.screenshot({ path: out });
  const renderer = reqs.some(u => /skwasm/.test(u)) ? 'skwasm' : (reqs.some(u => /canvaskit/.test(u)) ? 'canvaskit' : 'unknown');
  await b.close();
  console.log(JSON.stringify({ logs: logs.filter(l => !/^Falling back|^%c/.test(l)).slice(0, 20), renderer }));
})();
"""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("probe", type=Path)
    ap.add_argument("--work", type=Path, required=True)
    ap.add_argument("--url", default="http://127.0.0.1:8765", help="where --work/site is served")
    ap.add_argument("--skip-build", action="store_true")
    a = ap.parse_args()
    work = a.work.resolve()
    app = work / "app"
    site = work / "site"
    if not a.skip_build:
        c.copy_probe(a.probe, app)
        site.mkdir(parents=True, exist_ok=True)
        for engine, (folder, flags) in ENGINES.items():
            print(f"building {engine} ...", flush=True)
            c.flutter_build(app, site / folder, "--base-href", f"/{folder}/", *flags)
    shots = work / "shots"
    shots.mkdir(exist_ok=True)
    result: dict = {"engines": {}, "pass": True}
    for engine, (folder, _) in ENGINES.items():
        per: dict = {}
        for fmt in FORMATS:
            for page in PAGES:
                out = shots / f"{engine}_{fmt}_p{page}.png"
                info = c.node_json(SHOT, f"{a.url}/{folder}/?page={page}&fmt={fmt}", str(out))
                loaded = any(l.startswith("G1 done") for l in info["logs"])
                errs = [l for l in info["logs"] if "error" in l.lower()]
                per[f"{fmt}_p{page}"] = {"loaded": loaded, "renderer": info["renderer"], "ink": c.ink_pixels(out), "errors": errs}
        for page in PAGES:
            d, total = c.diff_pixels(shots / f"{engine}_ttf_p{page}.png", shots / f"{engine}_woff2_p{page}.png")
            per[f"diff_ttf_vs_woff2_p{page}"] = d
            ok = d == 0 and per[f"woff2_p{page}"]["loaded"] and per[f"ttf_p{page}"]["loaded"] and per[f"woff2_p{page}"]["ink"] > 2000 and not per[f"woff2_p{page}"]["errors"]
            result["pass"] = result["pass"] and ok
        result["engines"][engine] = per
    # Cross-engine comparison, informational (CanvasKit vs skwasm may differ in anti-aliasing and still be fine for the gate).
    cross = {}
    for fmt in FORMATS:
        for page in PAGES:
            d, total = c.diff_pixels(shots / f"canvaskit_{fmt}_p{page}.png", shots / f"skwasm_{fmt}_p{page}.png")
            cross[f"{fmt}_p{page}"] = {"diff": d, "total": total}
    result["canvaskit_vs_skwasm"] = cross
    result["firefox_webkit"] = "not run (no engine installed, no download approved)"
    print(json.dumps(result, indent=1))
    print("G1 " + ("PASS" if result["pass"] else "FAIL"))
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
