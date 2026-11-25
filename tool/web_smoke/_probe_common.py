"""Shared helpers of the gate runners (feature 012): build a probe app that lives OUTSIDE the repository, drive Chromium
through playwright-core (Node) and compare PNG screenshots pixel for pixel.

Nothing here downloads or installs anything. It uses the playwright-core and the cached Chromium that are already on the
machine (override with PLAYWRIGHT_CORE). The `playwright` Python package is not used because it is not installed.
"""
from __future__ import annotations

import os
import shutil
import struct
import subprocess
import sys
import zlib
from pathlib import Path

DEFAULT_PLAYWRIGHT_CORE = "~/.nvm/versions/node/v24.22.2/lib/node_modules/@playwright/cli/node_modules/playwright-core"


def playwright_core() -> str:
    path = os.environ.get("PLAYWRIGHT_CORE", DEFAULT_PLAYWRIGHT_CORE)
    if not Path(path).is_dir():
        sys.exit(f"playwright-core not found at {path} (set PLAYWRIGHT_CORE); nothing is downloaded by this tool")
    return path


def copy_probe(probe: Path, work: Path) -> Path:
    """Copies the probe app into [work] (a folder under the scratchpad) so the original stays clean."""
    probe = probe.resolve()
    work = work.resolve()
    repo = Path(__file__).resolve().parents[2]
    if repo in work.parents or work == repo:
        sys.exit(f"refusing to build inside the repository tree: {work} (rule 8)")
    if work.exists():
        shutil.rmtree(work)
    shutil.copytree(probe, work, ignore=shutil.ignore_patterns("build", ".dart_tool"))
    return work


def flutter_build(app: Path, out: Path, *flags: str) -> None:
    cmd = ["flutter", "build", "web", "--release", "--no-web-resources-cdn", *flags]
    r = subprocess.run(cmd, cwd=app, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"build failed ({' '.join(cmd)}):\n{r.stdout[-2000:]}\n{r.stderr[-2000:]}")
    if out.exists():
        shutil.rmtree(out)
    shutil.move(str(app / "build" / "web"), str(out))


def node_json(script: str, *args: str) -> object:
    """Runs a Node script (playwright-core is made available as env PLAYWRIGHT_CORE) and parses its last stdout line as JSON."""
    import json

    r = subprocess.run(["node", "-e", script, *args], capture_output=True, text=True, env={**os.environ, "PLAYWRIGHT_CORE": playwright_core()})
    if r.returncode != 0:
        sys.exit(f"node script failed:\n{r.stdout[-2000:]}\n{r.stderr[-2000:]}")
    return json.loads(r.stdout.strip().splitlines()[-1])


def read_png(path: Path) -> tuple[int, int, int, bytes]:
    """Minimal PNG reader (8-bit, non-interlaced, colour type 2 or 6). Returns width, height, channels, raw pixels."""
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
    pos, idat, w = 8, b"", 0
    h = ct = 0
    while pos < len(data):
        (n,) = struct.unpack(">I", data[pos : pos + 4])
        kind = data[pos + 4 : pos + 8]
        body = data[pos + 8 : pos + 8 + n]
        pos += 12 + n
        if kind == b"IHDR":
            w, h, depth, ct, _, _, il = struct.unpack(">IIBBBBB", body)
            assert depth == 8 and il == 0 and ct in (2, 6), "unsupported PNG"
        elif kind == b"IDAT":
            idat += body
    ch = 3 if ct == 2 else 4
    raw = zlib.decompress(idat)
    stride = w * ch
    out = bytearray()
    prev = bytearray(stride)
    p = 0
    for _ in range(h):
        f = raw[p]
        line = bytearray(raw[p + 1 : p + 1 + stride])
        p += 1 + stride
        for i in range(stride):
            a = line[i - ch] if i >= ch else 0
            b = prev[i]
            c = prev[i - ch] if i >= ch else 0
            if f == 1:
                line[i] = (line[i] + a) & 255
            elif f == 2:
                line[i] = (line[i] + b) & 255
            elif f == 3:
                line[i] = (line[i] + ((a + b) >> 1)) & 255
            elif f == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 255
        out += line
        prev = line
    return w, h, ch, bytes(out)


def diff_pixels(a: Path, b: Path) -> tuple[int, int]:
    """(differing pixels, total pixels); a size mismatch counts every pixel as different."""
    if a.read_bytes() == b.read_bytes():
        w, h, _, _ = read_png(a)
        return 0, w * h
    wa, ha, ca, pa = read_png(a)
    wb, hb, cb, pb = read_png(b)
    if (wa, ha, ca) != (wb, hb, cb):
        return max(wa * ha, wb * hb), max(wa * ha, wb * hb)
    n = 0
    for i in range(0, len(pa), ca):
        if pa[i : i + ca] != pb[i : i + ca]:
            n += 1
    return n, wa * ha


def ink_pixels(path: Path) -> int:
    """Number of pixels that are not white: a blank or missing-glyph render has far fewer than a rendered page."""
    w, h, ch, px = read_png(path)
    return sum(1 for i in range(0, len(px), ch) if px[i : i + 3] != b"\xff\xff\xff")
