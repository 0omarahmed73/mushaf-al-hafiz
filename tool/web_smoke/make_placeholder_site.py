#!/usr/bin/env python3
"""G4 preparation (feature 012): generate a SYNTHETIC test site of the same size and shape as the real one.

Usage: python3 tool/web_smoke/make_placeholder_site.py <empty scratch folder> [--size-mb 145] [--seed 12]

It contains none of the app's data: `index.html` says it is a test, one `.wasm` file (random bytes with a valid wasm header),
about 600 random `.woff2`-named files under `d/<12 hex>/fonts/`, about 1,000 small random `.json`-named files, and a `vercel.json`
with the headers and the CSP of specs/012-web-version/contracts/site.md (headers only, no rewrites). The bytes are random, so the host
cannot compress them: the transfer figures of a real deployment will be smaller than this site's, its upload size is the same.
Nothing is pushed or deployed by this script.
"""
from __future__ import annotations

import argparse
import json
import random
import sys
from pathlib import Path

CSP = (
    "default-src 'none'; script-src 'self' 'wasm-unsafe-eval'; connect-src 'self'; img-src 'self' data: blob:; "
    "font-src 'self' blob: data:; style-src 'self' 'unsafe-inline'; worker-src 'self' blob:; manifest-src 'self'; "
    "base-uri 'none'; form-action 'none'; frame-ancestors 'none'"
)
PERMISSIONS = "camera=(), microphone=(), geolocation=(), notifications=(), payment=(), usb=()"


def header(key: str, value: str) -> dict:
    return {"key": key, "value": value}


def vercel_json() -> dict:
    everything = [
        header("Referrer-Policy", "no-referrer"),
        header("X-Content-Type-Options", "nosniff"),
        header("Permissions-Policy", PERMISSIONS),
        header("Content-Security-Policy", CSP),
    ]
    no_cache = ["/sw.js", "/index.html", "/", "/flutter_bootstrap.js", "/version.json", "/manifest.json"]
    return {
        "headers": [
            {"source": "/(.*)", "headers": everything},
            *[{"source": s, "headers": [header("Cache-Control", "no-cache")]} for s in no_cache],
            {"source": "/d/(.*)", "headers": [header("Cache-Control", "public, max-age=31536000, immutable")]},
            {"source": "/(sqlite3.wasm|main.dart.wasm)", "headers": [header("Content-Type", "application/wasm")]},
            {"source": "/canvaskit/(.*).wasm", "headers": [header("Content-Type", "application/wasm")]},
        ]
    }


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("out", type=Path)
    ap.add_argument("--size-mb", type=float, default=145.0, help="target total size in MB (10^6 bytes); allowed 135 to 160")
    ap.add_argument("--seed", type=int, default=12)
    a = ap.parse_args(argv)
    if not 135 <= a.size_mb <= 160:
        sys.exit("--size-mb must be between 135 and 160 (the real site is about that size)")
    if a.out.exists() and any(a.out.iterdir()):
        sys.exit(f"{a.out} is not empty")
    rng = random.Random(a.seed)
    out = a.out
    out.mkdir(parents=True, exist_ok=True)
    version = "".join(rng.choice("0123456789abcdef") for _ in range(12))
    d = out / "d" / version
    (d / "fonts").mkdir(parents=True)
    (d / "pages").mkdir()
    (d / "ayah").mkdir()

    wasm = out / "sqlite3.wasm"
    wasm.write_bytes(b"\x00asm\x01\x00\x00\x00" + rng.randbytes(759_000))
    small = 0
    for i in range(1, 605):
        n = rng.randint(1_000, 8_000)
        (d / "pages" / f"{i:03d}.json").write_bytes(rng.randbytes(n))
        small += n
    for kind in ("text", "tafsir", "translation", "gharib"):
        (d / "ayah" / kind).mkdir()
        for i in range(1, 115):
            n = rng.randint(2_000, 12_000)
            (d / "ayah" / kind / f"{i:03d}.json").write_bytes(rng.randbytes(n))
            small += n
    (out / "index.html").write_text(
        '<!doctype html><html lang="en"><meta charset="utf-8"><title>Deployment test</title>'
        "<body><p>This is a synthetic deployment test (random bytes). It is not an app and has no real content.</p></body></html>\n",
        encoding="utf-8",
    )
    (out / "vercel.json").write_text(json.dumps(vercel_json(), indent=2) + "\n", encoding="utf-8")
    fixed = 759_000 + 8 + small + 600
    per_font = max(1, (int(a.size_mb * 1_000_000) - fixed) // 604)
    for i in range(1, 605):
        n = per_font + rng.randint(-20_000, 20_000)
        (d / "fonts" / f"p{i}.woff2").write_bytes(rng.randbytes(max(n, 1000)))
    files = [p for p in out.rglob("*") if p.is_file()]
    total = sum(p.stat().st_size for p in files)
    print(f"files={len(files)} bytes={total} MB={total / 1e6:.1f} dir=d/{version}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
