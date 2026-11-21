#!/usr/bin/env python3
"""Build the read-only ayah assets (text, tafsir, translation, gharib) for feature 002.

Usage:
    uv run python tool/build_ayah_assets.py [--raw data-raw/ayah] [--out assets]

Inputs (git-ignored, in data-raw/ayah/): see specs/002-ayah-actions-sharing/contracts/assets.md.
Output: assets/ayah/{text,tafsir,translation,gharib}/NNN.json and assets/ayah/sources.json.

The Quran words are copied exactly as they are in the source (Constitution I); this script only
splits them per ayah. Every check runs before anything is written and raises ValueError.
"""
import argparse
import gzip
import hashlib
import json
import re
import shutil
import sys
import unicodedata
import zipfile
from pathlib import Path

TOTAL_AYAHS = 6236
TOTAL_WORDS = 77432  # Quranic words, without the 6,236 end-of-ayah markers
TOTAL_SURAHS = 114

_NUMERAL = re.compile(r"[٠-٩0-9]+")


# ------------------------------------------------------------------ text source (T003)

def _json_from(path):
    """Parse a JSON file, or the single .json inside a .zip, as UTF-8."""
    path = Path(path)
    if path.suffix == ".zip":
        with zipfile.ZipFile(path) as z:
            names = [n for n in z.namelist() if n.endswith(".json")]
            if len(names) != 1:
                raise ValueError(f"{path.name}: expected exactly one .json inside, found {names}")
            return json.loads(z.read(names[0]).decode("utf-8"))
    return json.loads(path.read_text(encoding="utf-8"))


def parse_hafs_words(raw):
    """QUL 312 map -> {"s:a:w": {id, surah, ayah, word, text}} with integer numbers."""
    return {
        location: {
            "id": int(e["id"]), "surah": int(e["surah"]), "ayah": int(e["ayah"]),
            "word": int(e["word"]), "text": e["text"],
        }
        for location, e in raw.items()
    }


def read_hafs_words(path):
    return parse_hafs_words(_json_from(path))


def _by_ayah(words):
    """{(surah, ayah): [(position, location, entry)] sorted by position}."""
    grouped = {}
    for location, e in words.items():
        grouped.setdefault((e["surah"], e["ayah"]), []).append((e["word"], location, e))
    for items in grouped.values():
        items.sort(key=lambda t: t[0])
    return grouped


def check_alignment(words, mushaf_ids):
    """The source must have exactly the Mushaf's words: same locations, same ids, positions 1..n
    without a gap, and every ayah ending with its numeral marker (spec FR-008, research D1)."""
    have, want = set(words), set(mushaf_ids)
    if have != want:
        missing, extra = sorted(want - have), sorted(have - want)
        raise ValueError(
            f"source words differ from the Mushaf: {len(missing)} missing (first {missing[:3]}), "
            f"{len(extra)} extra (first {extra[:3]})")
    for location, e in words.items():
        if e["id"] != mushaf_ids[location]:
            raise ValueError(f"id of {location} is {e['id']} in the source but {mushaf_ids[location]} in the Mushaf")
    for (surah, ayah), items in _by_ayah(words).items():
        if [p for p, _, _ in items] != list(range(1, len(items) + 1)):
            raise ValueError(f"{surah}:{ayah}: word positions are not 1..{len(items)}")
        if not _NUMERAL.fullmatch(items[-1][2]["text"]):
            raise ValueError(f"{surah}:{ayah}: the last word is not the numeral marker: {items[-1][2]['text']!r}")


def split_ayahs(words):
    """{(surah, ayah): [word, ...]} in order, the end marker dropped, every word unchanged."""
    return {key: [e["text"] for _, _, e in items[:-1]] for key, items in _by_ayah(words).items()}


def check_totals(ayahs, ayah_count=TOTAL_AYAHS, word_count=TOTAL_WORDS):
    if len(ayahs) != ayah_count:
        raise ValueError(f"expected {ayah_count} ayahs, got {len(ayahs)}")
    words = sum(len(v) for v in ayahs.values())
    if words != word_count:
        raise ValueError(f"expected {word_count} words, got {words}")


# ------------------------------------------------------- Tanzil cross-check (T005)

_BISMILLAH = "بسماللهالرحمنالرحيم"
_DROPPED = {"Mn", "Mc", "Lm", "Cf", "Sk"}


def letters_only(text):
    """The consonant skeleton used to compare two spellings of the same verse: marks, tatweel,
    spaces and signs dropped, alef forms unified, final ya and ta marbuta unified."""
    kept = "".join(
        c for c in unicodedata.normalize("NFD", text)
        if unicodedata.category(c) not in _DROPPED and c != "ـ")
    kept = re.sub("[ٱأإآ]", "ا", kept).replace("ى", "ي").replace("ة", "ه")
    return re.sub("[^ء-ي]", "", kept)


def read_pipe_lines(path):
    """Lines `sura|aya|text` (Tanzil) -> {(sura, aya): text}; blank lines and `#` comments ignored."""
    result = {}
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        sura, aya, text = line.split("|", 2)
        result[(int(sura), int(aya))] = text
    return result


def read_known_differences(path):
    """tool/ayah_text_known_differences.json -> {"2:72": reason}; every entry needs a reason."""
    raw = json.loads(Path(path).read_text(encoding="utf-8"))
    known = {}
    for item in raw["differences"]:
        if not str(item.get("reason", "")).strip():
            raise ValueError(f"known difference {item.get('ayah')} has no reason")
        known[item["ayah"]] = item["reason"]
    return known


def crosscheck(ayahs, tanzil, known):
    """Compare our letters-only text with Tanzil's Uthmani verse for every ayah. Tanzil's file puts
    the basmalah in front of ayah 1 of surahs 2-8 and 10-114; that prefix is dropped first. Returns
    the sorted list of (surah, ayah) that differ and are listed in [known]; any other difference, and
    any listed ayah that no longer differs, raises ValueError."""
    differing = []
    for key in sorted(ayahs):
        theirs = letters_only(tanzil[key])
        surah, ayah = key
        if ayah == 1 and surah not in (1, 9) and theirs.startswith(_BISMILLAH):
            theirs = theirs[len(_BISMILLAH):]
        if letters_only(" ".join(ayahs[key])) != theirs:
            differing.append(key)
    unlisted = [f"{s}:{a}" for s, a in differing if f"{s}:{a}" not in known]
    if unlisted:
        raise ValueError(f"text differs from Tanzil and is not listed: {unlisted[:10]} ({len(unlisted)} ayahs)")
    stale = sorted(set(known) - {f"{s}:{a}" for s, a in differing})
    if stale:
        raise ValueError(f"listed as different but equal to Tanzil: {stale}")
    return differing


# --------------------------------------------------------------------- tafsir (T007)

_TAG = re.compile(r"<[^>]*>")
_BR = re.compile(r"<br\s*/?>", re.IGNORECASE)


def plain_tafsir(markup):
    """Plain text of a tafsir passage: `<br>` becomes a line break, other tags are removed (their text and
    the `{ }` quote marks stay), entities are decoded and runs of spaces collapse like they do when HTML
    is shown. This formatting is the only change made to a human work (research D2)."""
    import html
    text = _TAG.sub("", _BR.sub("\n", markup))
    text = html.unescape(text).replace(" ", " ")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r" ?\n ?", "\n", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def read_pinned_without(path):
    """tool/tafsir_without_own_entry.json -> {"2:107", ...}."""
    return set(json.loads(Path(path).read_text(encoding="utf-8"))["ayahs"])


def read_tafsir(raw, pinned, ayah_counts):
    """QUL tafsir map {"s:a": {"text": html} | {}} -> {surah: {"entries": [{from, to, text}], "without": [ayah]}}.

    Identical consecutive texts of one surah become one entry covering a range. An ayah with no text
    is listed in `without`; the set of those ayahs must equal [pinned] (the 59 known ones), each needs
    an earlier entry in its surah (the app shows that entry with a note, spec FR-009a). Every ayah
    1..n of every surah must be present in the source and nothing else."""
    expected = {f"{s}:{a}" for s, n in ayah_counts.items() for a in range(1, n + 1)}
    missing = sorted(expected - set(raw), key=_key)
    unknown = sorted(set(raw) - expected, key=_key)
    if missing or unknown:
        raise ValueError(f"tafsir ayahs differ from the Mushaf: missing {missing[:5]}, unknown {unknown[:5]}")

    result = {s: {"entries": [], "without": []} for s in sorted(ayah_counts)}
    without = set()
    for surah in sorted(ayah_counts):
        entries = result[surah]["entries"]
        previous = None  # the entry the previous ayah belongs to, only while it is consecutive
        for ayah in range(1, ayah_counts[surah] + 1):
            text = plain_tafsir(raw[f"{surah}:{ayah}"].get("text", ""))
            if not text:
                if not entries:
                    raise ValueError(f"{surah}:{ayah} has no text and no earlier entry in its surah")
                result[surah]["without"].append(ayah)
                without.add(f"{surah}:{ayah}")
                previous = None
            elif previous is not None and previous["text"] == text:
                previous["to"] = ayah
            else:
                previous = {"from": ayah, "to": ayah, "text": text}
                entries.append(previous)
    if without != set(pinned):
        raise ValueError(
            f"ayahs without a tafsir text differ from the pinned list: "
            f"not pinned {sorted(without - set(pinned), key=_key)[:5]}, "
            f"pinned but present {sorted(set(pinned) - without, key=_key)[:5]}")
    return result


def _key(location):
    return tuple(int(x) for x in location.split(":"))


# --------------------------------------------------- translation and gharib (T009)

GHARIB_BOOKS = (327, 208)  # ابن الهائم (التبيان), ابن الجوزي (تذكرة الأريب): classical works only (research D4)


def read_translation(path, ayah_keys):
    """Tanzil `sura|aya|text` -> {(sura, aya): text}: exactly the Mushaf's ayahs, none empty."""
    result = read_pipe_lines(path)
    missing = sorted(set(ayah_keys) - set(result))
    unknown = sorted(set(result) - set(ayah_keys))
    if missing or unknown:
        raise ValueError(
            f"translation ayahs differ from the Mushaf: missing {_fmt(missing)}, unknown {_fmt(unknown)}")
    empty = sorted(k for k, v in result.items() if not v.strip())
    if empty:
        raise ValueError(f"translation is empty for {_fmt(empty)}")
    return result


def _fmt(keys):
    return [f"{s}:{a}" for s, a in keys[:5]]


def read_gharib(raw, ayah_keys, books=GHARIB_BOOKS):
    """Quranpedia meanings dump -> ({surah: {ayah: [{w, m, b}]}}, number of ayahs with an entry).

    Only the whitelisted classical [books] are kept, in the dump's order. Word and meaning are copied
    unchanged. An empty word or meaning, or an unknown ayah in a kept book, stops the build."""
    result = {}
    for row in raw["data"]:
        surah, ayah = int(row["surah"]), int(row["ayah"])
        kept = [m for m in row["meanings"] if int(m["book_info"]["id"]) in books]
        if not kept:
            continue
        if (surah, ayah) not in ayah_keys:
            raise ValueError(f"gharib entry for an unknown ayah {surah}:{ayah}")
        entries = []
        for m in kept:
            for w in m["words"]:
                if not w["text"].strip() or not w["meaning"].strip():
                    raise ValueError(f"gharib entry with an empty word or meaning at {surah}:{ayah}")
                entries.append({"w": w["text"], "m": w["meaning"], "b": int(m["book_info"]["id"])})
        if entries:
            result.setdefault(surah, {})[ayah] = entries
    covered = sum(len(v) for v in result.values())
    return result, covered


# ------------------------------------------------------- sources, writer, report (T011)

MAX_BYTES = 40 * 1024 * 1024  # spec SC-009
KINDS = ("text", "tafsir", "translation", "gharib")
HERE = Path(__file__).resolve().parent
ROOT = HERE.parent

F_WORDS, F_TAFSIR = "qul-312-hafs-words.json.zip", "qul-24-tafsir-saadi-ar.json.zip"
F_TRANSLATION, F_GHARIB = "tanzil-en.sahih.txt", "quranpedia-meanings.json.gz"

SOURCE_DEFS = [
    {"id": "qul-312", "kind": "text", "title": "KFGQPC Hafs script - Word by word", "provider": "QUL (Tarteel)",
     "link": "https://qul.tarteel.ai/resources/translation/312", "file": F_WORDS},
    {"id": "qul-24", "kind": "tafsir", "title": "تفسير السعدي (تيسير الكريم الرحمن)",
     "author": "عبد الرحمن بن ناصر السعدي", "provider": "QUL (Tarteel)",
     "link": "https://qul.tarteel.ai/resources/tafsir/24", "file": F_TAFSIR},
    {"id": "tanzil-en-sahih", "kind": "translation", "title": "Saheeh International", "author": "Saheeh International",
     "provider": "Tanzil Project", "link": "https://tanzil.net/trans/en.sahih", "file": F_TRANSLATION},
    {"id": 327, "kind": "gharib", "title": "التبيان في تفسير غريب القرآن", "author": "ابن الهائم",
     "provider": "Quranpedia", "link": "https://quranpedia.net/dumps", "file": F_GHARIB},
    {"id": 208, "kind": "gharib", "title": "تذكرة الأريب في تفسير الغريب", "author": "ابن الجوزي",
     "provider": "Quranpedia", "link": "https://quranpedia.net/dumps", "file": F_GHARIB},
]

_MONTHS = {m: i for i, m in enumerate(
    ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October",
     "November", "December"], 1)}


def file_sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def zip_date(path):
    """ISO date of the single member of a zip (QUL's file date)."""
    with zipfile.ZipFile(path) as z:
        y, m, d = z.infolist()[0].date_time[:3]
    return f"{y:04d}-{m:02d}-{d:02d}"


def tanzil_last_update(path):
    """`#  Last Update: April 24, 2011` in the footer of a Tanzil translation -> `2011-04-24`."""
    found = re.search(r"Last Update:\s*([A-Za-z]+)\s+(\d+),\s*(\d{4})", Path(path).read_text(encoding="utf-8"))
    if not found or found.group(1) not in _MONTHS:
        raise ValueError(f"{Path(path).name}: no `Last Update` date in the footer")
    return f"{int(found.group(3)):04d}-{_MONTHS[found.group(1)]:02d}-{int(found.group(2)):02d}"


def build_sources(raw_dir, gharib_version):
    versions = {
        F_WORDS: zip_date(raw_dir / F_WORDS), F_TAFSIR: zip_date(raw_dir / F_TAFSIR),
        F_TRANSLATION: tanzil_last_update(raw_dir / F_TRANSLATION), F_GHARIB: gharib_version,
    }
    sources = []
    for d in SOURCE_DEFS:
        entry = {k: v for k, v in d.items() if k != "file"}
        entry.update({"file": d["file"], "version": versions[d["file"]], "sha256": file_sha256(raw_dir / d["file"])})
        sources.append(entry)
    return sources


def read_mushaf(mushaf_dir):
    """({"s:a:w": id}, {surah: ayah count}) from the generated Mushaf assets of feature 001."""
    mushaf_dir = Path(mushaf_dir)
    ids = {}
    for page in sorted((mushaf_dir / "pages").glob("p*.json")):
        for line in json.loads(page.read_text(encoding="utf-8"))["lines"]:
            for w in line["words"]:
                ids[w["k"]] = w["id"]
    meta = json.loads((mushaf_dir / "meta.json").read_text(encoding="utf-8"))
    return ids, {s["n"]: s["ayahs"] for s in meta["surahs"]}


def _dump(obj):
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":"))


def make_files(counts, ayahs, tafsir, translation, gharib, sources):
    """{relative path: text} for every output file (nothing is written here)."""
    files = {}
    for surah in sorted(counts):
        name = f"{surah:03d}.json"
        n = counts[surah]
        files[f"text/{name}"] = _dump({"surah": surah, "ayahs": [ayahs[(surah, a)] for a in range(1, n + 1)]})
        files[f"tafsir/{name}"] = _dump({"surah": surah, **tafsir[surah]})
        files[f"translation/{name}"] = _dump(
            {"surah": surah, "ayahs": [translation[(surah, a)] for a in range(1, n + 1)]})
        files[f"gharib/{name}"] = _dump(
            {"surah": surah, "ayahs": {str(a): e for a, e in sorted(gharib.get(surah, {}).items())}})
    files["sources.json"] = _dump({"sources": sources})
    return files


def size_report(files):
    """Raw and gzip bytes per kind and in total (sources.json counts in the total)."""
    sizes = {k: {"raw": 0, "gzip": 0} for k in KINDS}
    sizes["total"] = {"raw": 0, "gzip": 0}
    for path, text in files.items():
        data = text.encode("utf-8")
        packed = len(gzip.compress(data, 9))
        kind = path.split("/")[0] if "/" in path else None
        for key in ([kind] if kind else []) + ["total"]:
            sizes[key]["raw"] += len(data)
            sizes[key]["gzip"] += packed
    return sizes


def write_files(files, out_dir):
    """Write into `<out>/ayah.tmp`, then swap it in; an earlier `<out>/ayah` is kept until the swap."""
    out_dir = Path(out_dir)
    tmp, final, old = out_dir / "ayah.tmp", out_dir / "ayah", out_dir / "ayah.old"
    for leftover in (tmp, old):
        shutil.rmtree(leftover, ignore_errors=True)
    try:
        for relative, text in files.items():
            target = tmp / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text, encoding="utf-8")
        if final.exists():
            final.rename(old)
        tmp.rename(final)
    except OSError:
        shutil.rmtree(tmp, ignore_errors=True)
        raise
    shutil.rmtree(old, ignore_errors=True)


def build(raw_dir, mushaf_dir, tanzil_arabic, known_path, pinned_path, out_dir,
          totals=(TOTAL_AYAHS, TOTAL_WORDS), max_bytes=MAX_BYTES):
    """Run every check, then write. Raises ValueError (nothing written) if any check fails."""
    raw_dir = Path(raw_dir)
    mushaf_ids, counts = read_mushaf(mushaf_dir)
    ayah_keys = {(s, a) for s, n in counts.items() for a in range(1, n + 1)}

    words = read_hafs_words(raw_dir / F_WORDS)
    check_alignment(words, mushaf_ids)
    ayahs = split_ayahs(words)
    check_totals(ayahs, *totals)
    if set(ayahs) != ayah_keys:
        raise ValueError("the ayahs of the text source differ from the Mushaf's ayah counts")
    crosscheck(ayahs, read_pipe_lines(tanzil_arabic), read_known_differences(known_path))

    tafsir = read_tafsir(_json_from(raw_dir / F_TAFSIR), read_pinned_without(pinned_path), counts)
    translation = read_translation(raw_dir / F_TRANSLATION, ayah_keys)
    gharib_raw = json.loads(gzip.decompress((raw_dir / F_GHARIB).read_bytes()).decode("utf-8"))
    gharib, covered = read_gharib(gharib_raw, ayah_keys)
    sources = build_sources(raw_dir, gharib_raw["license"]["version"])

    files = make_files(counts, ayahs, tafsir, translation, gharib, sources)
    sizes = size_report(files)
    if sizes["total"]["raw"] > max_bytes:
        raise ValueError(f"total size {sizes['total']['raw']} bytes is above the limit {max_bytes} bytes")
    write_files(files, out_dir)
    return {
        "ayahs": len(ayahs), "words": sum(len(v) for v in ayahs.values()), "gharib_covered": covered,
        "tafsir_entries": sum(len(v["entries"]) for v in tafsir.values()),
        "tafsir_without": sum(len(v["without"]) for v in tafsir.values()), "sizes": sizes,
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--raw", default=str(ROOT / "data-raw" / "ayah"))
    parser.add_argument("--mushaf", default=str(ROOT / "assets" / "mushaf"))
    parser.add_argument("--tanzil", default=str(ROOT / "data-raw" / "quran-uthmani.txt"))
    parser.add_argument("--known", default=str(HERE / "ayah_text_known_differences.json"))
    parser.add_argument("--pinned", default=str(HERE / "tafsir_without_own_entry.json"))
    parser.add_argument("--out", default="assets")
    parser.add_argument("--expect-ayahs", type=int, default=TOTAL_AYAHS)
    parser.add_argument("--expect-words", type=int, default=TOTAL_WORDS)
    args = parser.parse_args(argv)
    try:
        report = build(
            Path(args.raw), Path(args.mushaf), Path(args.tanzil), Path(args.known), Path(args.pinned), Path(args.out),
            totals=(args.expect_ayahs, args.expect_words))
    except (ValueError, OSError, KeyError) as error:
        print(f"build failed: {error}", file=sys.stderr)
        return 1
    print(f"OK text: {report['ayahs']} ayahs, {report['words']} words (aligned with the Mushaf, Tanzil cross-check passed)")
    print(f"OK tafsir: {report['tafsir_entries']} entries, {report['tafsir_without']} ayahs without a text of their own")
    print(f"OK gharib: {report['gharib_covered']} of {report['ayahs']} ayahs have meanings")
    for kind, size in report["sizes"].items():
        print(f"size {kind:12} raw {size['raw'] / 1048576:7.2f} MB   gzip {size['gzip'] / 1048576:7.2f} MB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
