"""Gate G7 (feature 012): every code point the web build can show is in one of the three bundled fonts.

The web build has no system fonts (the engine fonts are not fetched from another host), so a character missing from
Cairo, Amiri Quran and Reem Kufi would show an empty box. This script collects the code points of the app's own text
(Dart string literals under lib/, without lib/pdf and lib/render which the web build does not contain, plus the text in
assets/ayah/*) and reports which are in no font.

Run: uv run --with fonttools python tool/web_font_coverage.py
(offline: add --offline when fonttools is already in the uv cache.) Exit 0 and the word PASS when there are no gaps.
"""
from __future__ import annotations

import argparse
import json
import sys
import unicodedata
from pathlib import Path

from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parent.parent
FONT_FILES = [
    "assets/fonts/cairo/Cairo-Regular.ttf",
    "assets/fonts/cairo/Cairo-Medium.ttf",
    "assets/fonts/cairo/Cairo-SemiBold.ttf",
    "assets/fonts/cairo/Cairo-Bold.ttf",
    "assets/fonts/amiri/AmiriQuran.ttf",
    "assets/fonts/reemkufi/ReemKufi.ttf",
]
SKIPPED_LIB_DIRS = ("pdf", "render")


def font_codepoints(path: Path) -> set[int]:
    return set(TTFont(str(path), lazy=True).getBestCmap().keys())


def needs_glyph(cp: int) -> bool:
    """Controls and format characters (zero-width joiner, direction marks) are not drawn, so they need no glyph."""
    return unicodedata.category(chr(cp)) not in ("Cc", "Cf")


def gaps(codepoints: set[int], fonts: list[Path]) -> set[int]:
    have: set[int] = set()
    for f in fonts:
        have |= font_codepoints(Path(f))
    return {cp for cp in codepoints if needs_glyph(cp) and cp not in have}


def dart_literal_codepoints(src: str) -> set[int]:
    """Code points inside Dart string literals; comments are skipped."""
    out: set[int] = set()
    i, n = 0, len(src)
    while i < n:
        ch = src[i]
        if src.startswith("//", i):
            j = src.find("\n", i)
            i = n if j < 0 else j
        elif src.startswith("/*", i):
            j = src.find("*/", i + 2)
            i = n if j < 0 else j + 2
        elif ch in "'\"":
            q = src[i : i + 3] if src[i : i + 3] in ("'''", '"""') else ch
            raw = i > 0 and src[i - 1] == "r"
            i += len(q)
            while i < n and not src.startswith(q, i):
                if src[i] == "\\" and not raw and i + 1 < n:
                    out.add(ord(src[i + 1]))
                    i += 2
                    continue
                if len(q) == 1 and src[i] == "\n":
                    break
                out.add(ord(src[i]))
                i += 1
            i += len(q)
        else:
            i += 1
    return out


def collect_lib_codepoints(lib: Path) -> set[int]:
    out: set[int] = set()
    for p in sorted(lib.rglob("*.dart")):
        rel = p.relative_to(lib).parts
        if rel and rel[0] in SKIPPED_LIB_DIRS:
            continue
        out |= dart_literal_codepoints(p.read_text(encoding="utf-8"))
    return out


def _strings(node):
    if isinstance(node, str):
        yield node
    elif isinstance(node, dict):
        for v in node.values():
            yield from _strings(v)
    elif isinstance(node, list):
        for v in node:
            yield from _strings(v)


def collect_data_codepoints(data: Path) -> set[int]:
    out: set[int] = set()
    for p in sorted(data.rglob("*.json")):
        for s in _strings(json.loads(p.read_text(encoding="utf-8"))):
            out |= {ord(c) for c in s}
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--lib", type=Path, default=ROOT / "lib")
    ap.add_argument("--data", type=Path, default=ROOT / "assets" / "ayah")
    ap.add_argument("--fonts", type=Path, nargs="*", default=[ROOT / f for f in FONT_FILES])
    ap.add_argument("--extra-text", type=Path, nargs="*", default=[], help="more UI text files (for example the strings of the web contract)")
    a = ap.parse_args(argv)
    cps = collect_lib_codepoints(a.lib) | collect_data_codepoints(a.data)
    for t in a.extra_text:
        cps |= {ord(c) for c in t.read_text(encoding="utf-8")}
    missing = gaps(cps, a.fonts)
    print(f"code points checked: {len(cps)}; fonts: {len(a.fonts)}; gaps: {len(missing)}")
    for cp in sorted(missing):
        print(f"  U+{cp:04X} {unicodedata.name(chr(cp), '?')}")
    print("G7 " + ("PASS" if not missing else "FAIL"))
    return 0 if not missing else 1


if __name__ == "__main__":
    sys.exit(main())
