#!/usr/bin/env python3
"""Build the read-only Mushaf assets from the QUL QCF V2 downloads and Tanzil metadata (T007).

Usage:
    uv run --with 'fonttools[woff]' python tool/build_quran_assets.py [--out assets] [--skip-fonts]

Inputs (git-ignored, in data-raw/): see specs/001-mushaf-reader-wirds/contracts/assets.md.
Output: assets/mushaf/pages/pNNN.json, assets/mushaf/meta.json, assets/fonts/qpc-v2/p{N}.ttf.

The Quran text and glyphs are copied exactly as they are in the sources (Constitution I); this
script only re-arranges them. validate() runs before anything is written and raises ValueError.
"""
import argparse
import json
import re
import sqlite3
import sys
from pathlib import Path

TOTAL_PAGES = 604
TOTAL_WORDS = 83668
TOTAL_AYAHS = 6236
TOTAL_SURAHS = 114
SHORT_PAGES = (1, 2)          # the two opening pages have 8 lines
LINES_SHORT = 8
LINES_FULL = 15
EDITION = "QCF V2 (1421H)"

LAYOUT_DB = "qul/x-layout-qpc-v2-15-lines.db/qpc-v2-15-lines.db"
SCRIPT_JSON = "qul/x-script-qpc-v2.json/qpc-v2.json"
FONT_DIR = "qul/x-font-qpc-v2-woff2"
TANZIL_JS = "quran-data.js"


# ---------------------------------------------------------------- parsing

def _array_text(raw: str, name: str) -> str:
    start = raw.index(f"QuranData.{name}")
    return raw[start:raw.index("];", start)]


def parse_tanzil(raw: str):
    """Return (suras, juz_starts, quarter_starts) from Tanzil's quran-data.js (regex only, never evaluated).

    suras: [{"n", "name", "ayahs"}] x114; juz_starts: 30 (surah, ayah); quarter_starts: 240 (surah, ayah).
    """
    suras = []
    for m in re.finditer(r"\[(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*'([^']+)'", _array_text(raw, "Sura")):
        suras.append({"n": len(suras) + 1, "name": m.group(5), "ayahs": int(m.group(2))})

    def pairs(name):
        found = [(int(a), int(b)) for a, b in re.findall(r"\[(\d+),\s*(\d+)\]", _array_text(raw, name))]
        return [p for p in found if p[0] <= TOTAL_SURAHS]  # drop the [115, 1] end sentinel

    juz, quarters = pairs("Juz"), pairs("HizbQaurter")
    if len(suras) != TOTAL_SURAHS or len(juz) != 30 or len(quarters) != 240:
        raise ValueError(f"Tanzil data: expected 114 surahs / 30 juz / 240 quarters, got "
                         f"{len(suras)} / {len(juz)} / {len(quarters)}")
    return suras, juz, quarters


def _as_int(value):
    return int(value) if str(value).strip() != "" else None


def read_layout(db_path: Path):
    con = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    try:
        return [
            {
                "page": int(p), "line": int(n), "type": t, "centered": bool(c),
                "first": _as_int(f), "last": _as_int(l), "surah": _as_int(s),
            }
            for p, n, t, c, f, l, s in con.execute(
                "select page_number, line_number, line_type, is_centered, first_word_id, last_word_id, "
                "surah_number from pages order by page_number, line_number"
            )
        ]
    finally:
        con.close()


def read_words(script_path: Path):
    """Return {word id: {"k": "s:a:w", "g": glyph, "surah", "ayah"}}."""
    raw = json.loads(script_path.read_text(encoding="utf-8"))
    return {
        int(v["id"]): {"k": v["location"], "g": v["text"], "surah": int(v["surah"]), "ayah": int(v["ayah"])}
        for v in raw.values()
    }


# ---------------------------------------------------------------- building

def _position_index(starts):
    """Return f(surah, ayah) -> 1-based index of the last start <= (surah, ayah)."""
    def locate(surah, ayah):
        index = 0
        for i, start in enumerate(starts, 1):
            if start <= (surah, ayah):
                index = i
            else:
                break
        return index
    return locate


def build_pages(layout_rows, words_by_id, quarters, juz_starts):
    """Group QUL layout rows into pages with their words, juz and hizb quarter."""
    juz_of = _position_index(juz_starts)
    quarter_of = _position_index(quarters)
    by_page = {}
    for row in layout_rows:
        by_page.setdefault(row["page"], []).append(row)

    pages = []
    for page_no in sorted(by_page):
        lines, first_word = [], None
        for row in by_page[page_no]:
            words = []
            if row["type"] == "ayah":
                for wid in range(row["first"], row["last"] + 1):
                    w = words_by_id[wid]
                    words.append({"id": wid, "k": w["k"], "g": w["g"]})
                if first_word is None:
                    first_word = words_by_id[row["first"]]
            lines.append({
                "n": row["line"], "type": row["type"], "centered": row["centered"],
                "surah": row["surah"] if row["type"] == "surah_name" else None, "words": words,
            })
        pages.append({
            "page": page_no,
            "juz": juz_of(first_word["surah"], first_word["ayah"]),
            "hizbQuarter": quarter_of(first_word["surah"], first_word["ayah"]),
            "lines": lines,
        })
    return pages


def build_meta(pages, suras):
    """Lookup tables used by the app (contracts/assets.md)."""
    ayah_page = {}
    page_surahs = []
    for p in pages:
        on_page = set()
        for line in p["lines"]:
            if line["surah"] is not None:
                on_page.add(line["surah"])
            for w in line["words"]:
                s, a, n = (int(x) for x in w["k"].split(":"))
                on_page.add(s)
                if n == 1:
                    ayah_page[f"{s}:{a}"] = p["page"]
        page_surahs.append(sorted(on_page))
    return {
        "edition": EDITION,
        "pages": len(pages),
        # startPage = page of the surah's first ayah (matches the printed index); a title line can
        # sit at the bottom of the previous page (18 surahs, e.g. an-Nisa: title p76, text p77).
        "surahs": [{"n": s["n"], "name": s["name"], "ayahs": s["ayahs"], "startPage": ayah_page[f"{s['n']}:1"]}
                   for s in suras],
        "pageJuz": [p["juz"] for p in pages],
        "pageHizbQuarter": [p["hizbQuarter"] for p in pages],
        "pageSurahs": page_surahs,
        "ayahPage": ayah_page,
    }


# -------------------------------------------------------------- validation

def validate(pages, meta):
    """Raise ValueError unless the data is exactly the 1421H Mushaf (Constitution I)."""
    def need(condition, message):
        if not condition:
            raise ValueError(message)

    need(len(pages) == TOTAL_PAGES, f"expected {TOTAL_PAGES} pages, got {len(pages)}")
    need([p["page"] for p in pages] == list(range(1, TOTAL_PAGES + 1)), "page numbers are not 1..604")
    for p in pages:
        want = LINES_SHORT if p["page"] in SHORT_PAGES else LINES_FULL
        need(len(p["lines"]) == want, f"page {p['page']}: expected {want} lines, got {len(p['lines'])}")
        need([l["n"] for l in p["lines"]] == list(range(1, want + 1)), f"page {p['page']}: line numbers not 1..{want}")
    ids = [w["id"] for p in pages for l in p["lines"] for w in l["words"]]
    need(ids == list(range(1, TOTAL_WORDS + 1)), "word ids are not 1..83668 exactly once and in order")

    first = pages[0]["lines"][0]
    need(first["type"] == "surah_name" and first["surah"] == 1, "page 1 line 1 is not the al-Fatiha title")
    need(pages[1]["lines"][1]["type"] == "basmallah", "page 2 line 2 is not the basmallah")
    need(pages[0]["juz"] == 1 and pages[-1]["juz"] == 30, "juz of page 1 / page 604 is wrong")

    need(meta.get("pages") == TOTAL_PAGES, "meta.pages != 604")
    need(len(meta["surahs"]) == TOTAL_SURAHS, "meta must list 114 surahs")
    need(meta["surahs"][17]["startPage"] == 293, "al-Kahf must start on page 293")
    need(len(meta["ayahPage"]) == TOTAL_AYAHS, "ayahPage must have 6236 keys")
    need(meta["ayahPage"].get("2:255") == 42, "2:255 must be on page 42")
    for key in ("pageJuz", "pageHizbQuarter", "pageSurahs"):
        need(len(meta[key]) == TOTAL_PAGES, f"meta.{key} must have 604 entries")


# ------------------------------------------------------------------ output

def convert_fonts(src_dir: Path, dst_dir: Path):
    """Decompress each p{N}.woff2 into p{N}.ttf (Flutter cannot load WOFF2)."""
    from fontTools.ttLib.woff2 import decompress

    dst_dir.mkdir(parents=True, exist_ok=True)
    for n in range(1, TOTAL_PAGES + 1):
        src = src_dir / f"p{n}.woff2"
        if not src.exists():
            raise ValueError(f"missing font {src}")
        decompress(str(src), str(dst_dir / f"p{n}.ttf"))
    return TOTAL_PAGES


def build(raw_dir: Path, out_dir: Path, skip_fonts: bool = False):
    """Run the whole pipeline. Returns (pages, meta). Nothing is written if validation fails."""
    raw_dir, out_dir = Path(raw_dir), Path(out_dir)
    suras, juz, quarters = parse_tanzil((raw_dir / TANZIL_JS).read_text(encoding="utf-8"))
    pages = build_pages(read_layout(raw_dir / LAYOUT_DB), read_words(raw_dir / SCRIPT_JSON), quarters, juz)
    meta = build_meta(pages, suras)
    validate(pages, meta)

    pages_dir = out_dir / "mushaf" / "pages"
    pages_dir.mkdir(parents=True, exist_ok=True)
    for p in pages:
        (pages_dir / f"p{p['page']:03d}.json").write_text(
            json.dumps(p, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    (out_dir / "mushaf" / "meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    fonts = 0 if skip_fonts else convert_fonts(raw_dir / FONT_DIR, out_dir / "fonts" / "qpc-v2")
    words = sum(len(l["words"]) for p in pages for l in p["lines"])
    print(f"{len(pages)} pages, {words} words, {fonts} fonts")
    return pages, meta


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--raw", default=str(Path(__file__).resolve().parent.parent / "data-raw"))
    parser.add_argument("--out", default="assets")
    parser.add_argument("--skip-fonts", action="store_true")
    args = parser.parse_args(argv)
    try:
        build(Path(args.raw), Path(args.out), args.skip_fonts)
    except (ValueError, OSError) as error:
        print(f"build failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
