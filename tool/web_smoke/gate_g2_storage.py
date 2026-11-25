#!/usr/bin/env python3
"""Gate G2 (feature 012): which store does drift pick on the web (COOP/COEP off), and do two tabs corrupt or block each other?

Usage:
  python3 tool/web_smoke/gate_g2_storage.py <probe folder> --work <build folder under the scratchpad> [--url http://127.0.0.1:8766]

The probe (scratchpad `$GATES/g2_storage/`) is copied to --work/app, built (normal web build) into --work/site/, which the caller serves at
--url with `python3 -m http.server` (a harness-tracked background command; this server sends NO COOP/COEP headers, like the real host).
Chromium only unless another engine is installed (nothing is downloaded): Firefox and WebKit are reported «not run».
Steps in ONE browser context: (1) tab A alone writes 5 rows; (2) A reloads and reads: the rows persisted; (3) tabs A and B run at once
(30 writes each, 60 ms apart); (4) a fresh tab reads the final counts. Prints the chosen implementation and the per-tab outcome as JSON.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import _probe_common as c  # noqa: E402

RUN = r"""
const { chromium } = require(process.env.PLAYWRIGHT_CORE);
(async () => {
  const steps = JSON.parse(process.argv[1]);
  const b = await chromium.launch({ headless: true });
  const ctx = await b.newContext({ viewport: { width: 400, height: 300 } });
  const result = [];
  for (const urls of steps) {
    const pages = await Promise.all(urls.map(async (u) => {
      const p = await ctx.newPage();
      const logs = [];
      p.on('console', m => { if (m.text().startsWith('G2 ')) logs.push(m.text()); });
      p.on('pageerror', e => logs.push('pageerror ' + String(e).slice(0, 200)));
      await p.goto(u);
      return { p, logs, u };
    }));
    const t0 = Date.now();
    while (Date.now() - t0 < 60000 && !pages.every(x => x.logs.some(l => l.startsWith('G2 done')))) await pages[0].p.waitForTimeout(150);
    const env = await pages[0].p.evaluate(() => ({ locks: typeof navigator.locks, isolated: self.crossOriginIsolated, indexedDB: typeof indexedDB, opfs: typeof navigator.storage?.getDirectory }));
    result.push({ urls, env, logs: pages.map(x => x.logs) });
    await Promise.all(pages.map(x => x.p.close()));
  }
  await b.close();
  console.log(JSON.stringify(result));
})();
"""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("probe", type=Path)
    ap.add_argument("--work", type=Path, required=True)
    ap.add_argument("--url", default="http://127.0.0.1:8766")
    ap.add_argument("--skip-build", action="store_true")
    a = ap.parse_args()
    work = a.work.resolve()
    if not a.skip_build:
        app = work / "app"
        c.copy_probe(a.probe, app)
        (work / "site").mkdir(parents=True, exist_ok=True)
        print("building ...", flush=True)
        c.flutter_build(app, work / "site" / "g2", "--base-href", "/g2/")
    base = f"{a.url}/g2/"
    steps = [
        [f"{base}?tab=A&writes=5&gap=50"],
        [f"{base}?tab=A&writes=0"],
        [f"{base}?tab=A&writes=30&gap=60", f"{base}?tab=B&writes=30&gap=60"],
        [f"{base}?tab=Z&writes=0"],
    ]
    res = c.node_json(RUN, json.dumps(steps))
    print(json.dumps(res, indent=1, ensure_ascii=False))
    text = json.dumps(res)
    impls = sorted({w.split("impl=")[1].split()[0] for step in res for logs in step["logs"] for w in logs if "impl=" in w})
    final = [w for w in res[-1]["logs"][0] if w.startswith("G2 done")]
    errors = [w for step in res for logs in step["logs"] for w in logs if "error" in w.lower()]
    print("implementations seen:", impls)
    print("final read:", final)
    print("errors:", len(errors))
    print("firefox_webkit: not run (no engine installed, no download approved)")
    ok = bool(impls) and "inMemory" not in impls and "unknown" not in impls and not errors and "pageerror" not in text
    print("G2 " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
