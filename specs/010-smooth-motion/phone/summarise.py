#!/usr/bin/env python3
"""Summarise frame times of the owner's phone for feature 010 (specs/010-smooth-motion/quickstart.md).

Two inputs, both plain text read from a file or stdin:

  summarise.py frametrace [--budget-ms N] [--refresh-hz N] FILE
      FILE is `adb logcat -d -s flutter` output. Lines the FRAME_TRACE build prints:
        FRAMETRACE refresh=<hz>
        FRAMETRACE build=<ms> raster=<ms> total=<ms>
      The budget comes from --budget-ms, else --refresh-hz, else the `refresh=` line, else 16.67 ms (60 Hz).

  summarise.py framestats [--budget-ms N] FILE
      FILE is `adb shell dumpsys gfxinfo app.hafiz.mushaf framestats` output (the PROFILEDATA block). Frame time is
      FrameCompleted - IntendedVsync. A Flutter app draws into its own surface, so this block can be empty or short;
      then use `frametrace` (the build's own FrameTiming numbers) and, as a cross-check, `dumpsys SurfaceFlinger
      --latency` (see quickstart.md).

Prints the count, mean, p50, p90, p95, p99, max, the share of frames within the budget and the count over 100 ms, then
PASS or FAIL against the feature's acceptance numbers (spec SC-001: at least 95% of frames within the budget, none over
100 ms; p99 at most twice the budget). Needs only the Python 3 standard library; it never talks to a phone.
"""
import argparse
import re
import sys


def percentile(sorted_values, p):
    """Nearest-rank percentile of an ascending list."""
    if not sorted_values:
        return float("nan")
    # ceil(p/100 * n) with integer arithmetic so floats cannot drift.
    rank = max(1, min(len(sorted_values), (int(p) * len(sorted_values) + 99) // 100))
    return sorted_values[rank - 1]


def read_text(path):
    if path == "-":
        return sys.stdin.read()
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        return handle.read()


def parse_frametrace(text):
    refresh = None
    totals, builds, rasters = [], [], []
    for line in text.splitlines():
        if "FRAMETRACE" not in line:
            continue
        m = re.search(r"refresh=([0-9.]+)", line)
        if m:
            refresh = float(m.group(1))
        m = re.search(r"build=([0-9.]+)\s+raster=([0-9.]+)\s+total=([0-9.]+)", line)
        if m:
            builds.append(float(m.group(1)))
            rasters.append(float(m.group(2)))
            totals.append(float(m.group(3)))
    return {"total": totals, "build": builds, "raster": rasters}, refresh


def parse_framestats(text):
    totals = []
    header = None
    in_block = False
    for line in text.splitlines():
        line = line.strip()
        if line == "---PROFILEDATA---":
            in_block = not in_block
            header = None
            continue
        if not in_block or not line:
            continue
        cells = line.rstrip(",").split(",")
        if header is None:
            header = cells
            continue
        row = dict(zip(header, cells))
        try:
            flags = int(row["Flags"])
            start = int(row["IntendedVsync"])
            end = int(row["FrameCompleted"])
        except (KeyError, ValueError):
            continue
        if flags & 1:  # the first frame after a layout change is not a user-visible frame
            continue
        if end > start > 0:
            totals.append((end - start) / 1e6)
    return {"total": totals}


def describe(name, values, budget):
    values = sorted(values)
    if not values:
        print(f"{name}: no frames")
        return None
    within = sum(1 for v in values if v <= budget)
    over100 = sum(1 for v in values if v > 100)
    stats = {
        "n": len(values),
        "mean": sum(values) / len(values),
        "p50": percentile(values, 50),
        "p90": percentile(values, 90),
        "p95": percentile(values, 95),
        "p99": percentile(values, 99),
        "max": values[-1],
        "within": 100.0 * within / len(values),
        "over100": over100,
    }
    print(
        f"{name}: n={stats['n']} mean={stats['mean']:.2f} p50={stats['p50']:.2f} p90={stats['p90']:.2f} "
        f"p95={stats['p95']:.2f} p99={stats['p99']:.2f} max={stats['max']:.2f} ms | "
        f"within {budget:.2f} ms budget: {stats['within']:.1f}% | over 100 ms: {over100}"
    )
    return stats


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("kind", choices=["frametrace", "framestats"])
    ap.add_argument("file")
    ap.add_argument("--budget-ms", type=float)
    ap.add_argument("--refresh-hz", type=float)
    args = ap.parse_args(argv)

    text = read_text(args.file)
    if args.kind == "frametrace":
        series, refresh = parse_frametrace(text)
    else:
        series, refresh = parse_framestats(text), None
    hz = args.refresh_hz or refresh
    budget = args.budget_ms or (1000.0 / hz if hz else 1000.0 / 60.0)
    print(f"budget {budget:.2f} ms ({'from --budget-ms' if args.budget_ms else f'{1000.0 / budget:.0f} Hz'})")

    total = describe("total", series["total"], budget)
    for extra in ("build", "raster"):
        if series.get(extra):
            describe(extra, series[extra], budget)
    if total is None:
        print("FAIL: no frames were read")
        return 2
    ok = total["within"] >= 95.0 and total["over100"] == 0 and total["p99"] <= 2 * budget
    print("PASS" if ok else "FAIL", "(at least 95% within the budget, none over 100 ms, p99 at most twice the budget)")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
