"""Tests for tool/build_ayah_assets.py (feature 002). Run: uv run --with pytest pytest tool/ -q

Small inline samples shaped like the real downloads (specs/002-ayah-actions-sharing/contracts/assets.md);
the Mushaf side is a tiny {location: id} map. Every check must stop the build with ValueError.
"""
import json
import zipfile

import pytest

import build_ayah_assets as a


def entry(surah, ayah, word, text, wid):
    """One QUL 312 entry as it is in the real file (strings for surah, ayah and word)."""
    return {
        "id": wid, "surah": str(surah), "ayah": str(ayah), "word": str(word),
        "location": f"{surah}:{ayah}:{word}", "text": text,
    }


def source(*entries):
    return {e["location"]: e for e in entries}


# Two ayahs: 1:1 has two words and its marker, 1:2 has one word and its marker.
GOOD = source(
    entry(1, 1, 1, "بِسۡمِ", 1),
    entry(1, 1, 2, "۞ ٱللَّهِ", 2),
    entry(1, 1, 3, "١", 3),
    entry(1, 2, 1, "ٱلۡحَمۡدُ", 4),
    entry(1, 2, 2, "٢", 5),
)
MUSHAF = {"1:1:1": 1, "1:1:2": 2, "1:1:3": 3, "1:2:1": 4, "1:2:2": 5}


# ------------------------------------------------------------------ text source (T002)

def test_read_hafs_words_reads_a_json_file(tmp_path):
    path = tmp_path / "words.json"
    path.write_text(json.dumps(GOOD, ensure_ascii=False), encoding="utf-8")
    words = a.read_hafs_words(path)
    assert set(words) == set(GOOD)
    first = words["1:1:2"]
    assert (first["id"], first["surah"], first["ayah"], first["word"]) == (2, 1, 1, 2)
    assert first["text"] == "۞ ٱللَّهِ"


def test_read_hafs_words_reads_the_single_json_inside_a_zip(tmp_path):
    path = tmp_path / "words.json.zip"
    with zipfile.ZipFile(path, "w") as z:
        z.writestr("qpc-hafs-word-by-word.json", json.dumps(GOOD, ensure_ascii=False))
    assert set(a.read_hafs_words(path)) == set(GOOD)


def test_split_ayahs_drops_the_marker_and_keeps_every_word_unchanged():
    ayahs = a.split_ayahs(a.parse_hafs_words(GOOD))
    assert ayahs == {(1, 1): ["بِسۡمِ", "۞ ٱللَّهِ"], (1, 2): ["ٱلۡحَمۡدُ"]}


def test_split_ayahs_orders_words_by_position_not_by_file_order():
    shuffled = dict(reversed(list(GOOD.items())))
    ayahs = a.split_ayahs(a.parse_hafs_words(shuffled))
    assert ayahs[(1, 1)] == ["بِسۡمِ", "۞ ٱللَّهِ"]


def test_alignment_passes_when_locations_and_ids_equal_the_mushaf():
    a.check_alignment(a.parse_hafs_words(GOOD), MUSHAF)


def test_alignment_stops_when_the_source_misses_a_mushaf_word():
    missing = dict(GOOD)
    del missing["1:1:2"]
    with pytest.raises(ValueError, match="1:1:2"):
        a.check_alignment(a.parse_hafs_words(missing), MUSHAF)


def test_alignment_stops_when_the_source_has_an_extra_word():
    extra = dict(GOOD)
    extra["1:2:3"] = entry(1, 2, 3, "٣", 6)
    with pytest.raises(ValueError, match="1:2:3"):
        a.check_alignment(a.parse_hafs_words(extra), MUSHAF)


def test_alignment_stops_when_an_id_differs():
    wrong = dict(GOOD)
    wrong["1:2:1"] = entry(1, 2, 1, "ٱلۡحَمۡدُ", 99)
    with pytest.raises(ValueError, match="id"):
        a.check_alignment(a.parse_hafs_words(wrong), MUSHAF)


def test_alignment_stops_when_an_ayah_does_not_end_with_a_numeral_marker():
    wrong = dict(GOOD)
    wrong["1:2:2"] = entry(1, 2, 2, "ٱلرَّحِيمِ", 5)
    with pytest.raises(ValueError, match="marker"):
        a.check_alignment(a.parse_hafs_words(wrong), MUSHAF)


def test_alignment_stops_when_positions_have_a_gap():
    gap = dict(GOOD)
    del gap["1:1:2"]
    gap["1:1:3"] = entry(1, 1, 3, "١", 3)
    with pytest.raises(ValueError):
        a.check_alignment(a.parse_hafs_words(gap), {"1:1:1": 1, "1:1:3": 3, "1:2:1": 4, "1:2:2": 5})


def test_totals_stop_the_build_unless_the_whole_quran_is_there():
    ayahs = a.split_ayahs(a.parse_hafs_words(GOOD))
    with pytest.raises(ValueError, match="6236"):
        a.check_totals(ayahs)
    a.check_totals(ayahs, ayah_count=2, word_count=3)


# ------------------------------------------------------------ Tanzil cross-check (T004)

def test_letters_only_drops_marks_tatweel_and_unifies_alef_forms():
    assert a.letters_only("بِسۡمِ ٱللَّهِ") == "بسماللّه".replace("ّ", "")
    assert a.letters_only("أَنزَلۡنَٰهُ") == a.letters_only("انزلنه")
    assert a.letters_only("مُوسَىٰ") == a.letters_only("موسي")
    assert a.letters_only("رَحۡمَة") == a.letters_only("رحمه")
    assert a.letters_only("ـــب") == "ب"


BISM = "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ"
OURS = {(1, 1): ["بِسۡمِ", "ٱللَّهِ", "ٱلرَّحۡمَٰنِ", "ٱلرَّحِيمِ"], (2, 1): ["الٓمٓ"], (9, 1): ["بَرَآءَةٌ"], (9, 2): ["فَسِيحُواْ"]}
TANZIL = {(1, 1): BISM, (2, 1): BISM + " الم", (9, 1): "بَرَآءَةٌ", (9, 2): "فَسِيحُوا"}


def test_crosscheck_passes_when_only_the_basmalah_prefix_differs():
    assert a.crosscheck(OURS, TANZIL, known={}) == []


def test_crosscheck_does_not_strip_a_basmalah_from_surah_1_or_9():
    tanzil = dict(TANZIL)
    tanzil[(9, 1)] = BISM + " بَرَآءَةٌ"
    with pytest.raises(ValueError, match="9:1"):
        a.crosscheck(OURS, tanzil, known={})


def test_crosscheck_stops_on_an_unlisted_difference():
    tanzil = dict(TANZIL)
    tanzil[(9, 2)] = "فسيحوا في الارض"
    with pytest.raises(ValueError, match="9:2"):
        a.crosscheck(OURS, tanzil, known={})


def test_crosscheck_accepts_a_listed_difference_with_a_reason():
    tanzil = dict(TANZIL)
    tanzil[(9, 2)] = "فسيحوا في الارض"
    differing = a.crosscheck(OURS, tanzil, known={"9:2": "spelling of the hamza"})
    assert differing == [(9, 2)]


def test_known_differences_need_a_non_empty_reason(tmp_path):
    path = tmp_path / "known.json"
    path.write_text(json.dumps({"differences": [{"ayah": "2:72", "reason": "  "}]}), encoding="utf-8")
    with pytest.raises(ValueError, match="reason"):
        a.read_known_differences(path)
    path.write_text(json.dumps({"differences": [{"ayah": "2:72", "reason": "hamza"}]}), encoding="utf-8")
    assert a.read_known_differences(path) == {"2:72": "hamza"}


def test_crosscheck_stops_on_a_listed_difference_that_no_longer_differs():
    with pytest.raises(ValueError, match="2:2"):
        a.crosscheck(OURS, TANZIL, known={"2:2": "stale"})


def test_read_tanzil_arabic_reads_sura_aya_text_lines(tmp_path):
    path = tmp_path / "quran-uthmani.txt"
    path.write_text("1|1|" + BISM + "\n1|2|ٱلۡحَمۡدُ\n\n# footer\n", encoding="utf-8")
    assert a.read_pipe_lines(path) == {(1, 1): BISM, (1, 2): "ٱلۡحَمۡدُ"}


# ------------------------------------------------------------------ tafsir (T006)

def test_plain_tafsir_removes_tags_keeps_quote_marks_and_breaks_lines_at_br():
    html = ('<span class="arabic qpc-hafs brown">{ بِسْمِ اللَّهِ }</span> أي:&nbsp; أبتدئ<br>'
            '<span class="blue">سطر</span>  ثان &lt;ب&gt;')
    assert a.plain_tafsir(html) == "{ بِسْمِ اللَّهِ } أي: أبتدئ\nسطر ثان <ب>"


def test_plain_tafsir_collapses_spaces_and_blank_lines_and_trims():
    assert a.plain_tafsir("  ا   ب <br> <br><br><br>ج  ") == "ا ب\n\nج"
    assert a.plain_tafsir("<span> </span>") == ""


COUNTS = {2: 5, 3: 1}


def raw_tafsir(**texts):
    """{'2:1': {'text': ...}} from keyword args like s2a1='…'; use None for an empty {} entry."""
    out = {}
    for name, text in texts.items():
        s, ay = name[1:].split("a")
        out[f"{s}:{ay}"] = {} if text is None else {"text": text}
    return out


def test_read_tafsir_merges_identical_consecutive_texts_and_lists_ayahs_without_text():
    raw = raw_tafsir(s2a1="<b>x</b>", s2a2="x", s2a3="y", s2a4=None, s2a5="z", s3a1="z")
    raw = {k: v for k, v in raw.items()}  # <b> is stripped like any tag
    result = a.read_tafsir(raw, pinned={"2:4"}, ayah_counts=COUNTS)
    assert result[2]["entries"] == [
        {"from": 1, "to": 2, "text": "x"}, {"from": 3, "to": 3, "text": "y"}, {"from": 5, "to": 5, "text": "z"}]
    assert result[2]["without"] == [4]
    assert result[3] == {"entries": [{"from": 1, "to": 1, "text": "z"}], "without": []}


def test_read_tafsir_never_merges_across_a_surah_boundary():
    raw = raw_tafsir(s2a1="x", s2a2="x", s2a3="x", s2a4="x", s2a5="z", s3a1="z")
    result = a.read_tafsir(raw, pinned=set(), ayah_counts=COUNTS)
    assert result[2]["entries"][-1] == {"from": 5, "to": 5, "text": "z"}
    assert result[3]["entries"] == [{"from": 1, "to": 1, "text": "z"}]


def test_read_tafsir_stops_when_the_ayahs_without_text_are_not_the_pinned_list():
    raw = raw_tafsir(s2a1="x", s2a2="y", s2a3=None, s2a4="z", s2a5=None, s3a1="w")
    with pytest.raises(ValueError, match="2:5"):
        a.read_tafsir(raw, pinned={"2:3"}, ayah_counts=COUNTS)
    with pytest.raises(ValueError, match="2:4"):
        a.read_tafsir(raw, pinned={"2:3", "2:5", "2:4"}, ayah_counts=COUNTS)


def test_read_tafsir_stops_when_an_ayah_without_text_has_no_earlier_entry_in_its_surah():
    raw = raw_tafsir(s2a1=None, s2a2="y", s2a3="y", s2a4="z", s2a5="z", s3a1="w")
    with pytest.raises(ValueError, match="2:1"):
        a.read_tafsir(raw, pinned={"2:1"}, ayah_counts=COUNTS)


def test_read_tafsir_stops_when_an_ayah_is_missing_or_unknown():
    raw = raw_tafsir(s2a1="x", s2a2="y", s2a3="y", s2a4="z", s3a1="w")  # 2:5 missing
    with pytest.raises(ValueError, match="2:5"):
        a.read_tafsir(raw, pinned=set(), ayah_counts=COUNTS)
    raw = raw_tafsir(s2a1="x", s2a2="y", s2a3="y", s2a4="z", s2a5="z", s3a1="w", s3a2="v")
    with pytest.raises(ValueError, match="3:2"):
        a.read_tafsir(raw, pinned=set(), ayah_counts=COUNTS)


def test_a_text_that_is_only_tags_counts_as_without_text():
    raw = raw_tafsir(s2a1="x", s2a2="<span> </span>", s2a3="y", s2a4="y", s2a5="z", s3a1="w")
    result = a.read_tafsir(raw, pinned={"2:2"}, ayah_counts=COUNTS)
    assert result[2]["without"] == [2]


def test_read_pinned_without_reads_the_ayah_list(tmp_path):
    path = tmp_path / "pinned.json"
    path.write_text(json.dumps({"ayahs": ["2:107", "109:4"]}), encoding="utf-8")
    assert a.read_pinned_without(path) == {"2:107", "109:4"}


# ------------------------------------------------ translation and gharib (T008)

AYAH_KEYS = {(1, 1), (1, 2), (2, 1)}


def test_read_translation_ignores_comment_footer_and_blank_lines(tmp_path):
    path = tmp_path / "en.sahih.txt"
    path.write_text(
        "1|1|In the name of Allah, the Entirely Merciful.\n1|2|[All] praise is [due] to Allah -\n"
        "2|1|Alif, Lam, Meem.\n\n\n# ----\n#  Name: Saheeh International\n", encoding="utf-8")
    result = a.read_translation(path, AYAH_KEYS)
    assert result == {
        (1, 1): "In the name of Allah, the Entirely Merciful.",
        (1, 2): "[All] praise is [due] to Allah -", (2, 1): "Alif, Lam, Meem."}


def test_read_translation_stops_on_a_missing_empty_or_unknown_ayah(tmp_path):
    path = tmp_path / "en.txt"
    path.write_text("1|1|x\n1|2|y\n", encoding="utf-8")
    with pytest.raises(ValueError, match="2:1"):
        a.read_translation(path, AYAH_KEYS)
    path.write_text("1|1|x\n1|2|   \n2|1|z\n", encoding="utf-8")
    with pytest.raises(ValueError, match="1:2"):
        a.read_translation(path, AYAH_KEYS)
    path.write_text("1|1|x\n1|2|y\n2|1|z\n9|9|q\n", encoding="utf-8")
    with pytest.raises(ValueError, match="9:9"):
        a.read_translation(path, AYAH_KEYS)


def gharib_raw(*rows):
    """Quranpedia dump shape: rows are (surah, ayah, [(book id, [(word, meaning)])])."""
    return {
        "license": {"version": "2026-11-14"},
        "data": [
            {"surah": s, "ayah": ay, "meanings": [
                {"book_info": {"id": b, "name": f"book {b}", "author": "x"},
                 "words": [{"text": w, "meaning": m} for w, m in words]}
                for b, words in books]}
            for s, ay, books in rows]}


def test_read_gharib_keeps_only_the_whitelisted_books_in_source_order():
    raw = gharib_raw(
        (1, 1, [(491, [("x", "modern")]), (327, [("بسم", "اسم")]), (208, [("الله", "الاله"), ("الرحمن", "ذو الرحمة")])]),
        (1, 2, [(1424, [("y", "modern")])]),
        (2, 1, [(208, [("الم", "حروف")])]))
    result, covered = a.read_gharib(raw, AYAH_KEYS)
    assert result[1][1] == [
        {"w": "بسم", "m": "اسم", "b": 327}, {"w": "الله", "m": "الاله", "b": 208},
        {"w": "الرحمن", "m": "ذو الرحمة", "b": 208}]
    assert 2 not in result[1], "an ayah with only non-whitelisted books has no entry"
    assert result[2][1] == [{"w": "الم", "m": "حروف", "b": 208}]
    assert covered == 2


def test_read_gharib_keeps_text_and_meaning_unchanged():
    raw = gharib_raw((1, 1, [(327, [("  القيوم ", "القائم  الدائم\n")])]))
    result, _ = a.read_gharib(raw, AYAH_KEYS)
    assert result[1][1] == [{"w": "  القيوم ", "m": "القائم  الدائم\n", "b": 327}]


@pytest.mark.parametrize("row, message", [
    ((1, 1, [(327, [("", "x")])]), "empty"),
    ((1, 1, [(327, [("x", "  ")])]), "empty"),
    ((7, 7, [(327, [("x", "y")])]), "7:7"),
])
def test_read_gharib_stops_on_an_empty_entry_or_an_unknown_ayah(row, message):
    with pytest.raises(ValueError, match=message):
        a.read_gharib(gharib_raw(row), AYAH_KEYS)


def test_read_gharib_ignores_an_unknown_ayah_of_a_book_that_is_not_whitelisted():
    result, covered = a.read_gharib(gharib_raw((7, 7, [(491, [("x", "y")])])), AYAH_KEYS)
    assert result == {} and covered == 0


# ---------------------------------------------------- writer, sources and report (T010)

import gzip
import hashlib
from pathlib import Path

REAL_RAW = Path(__file__).resolve().parent.parent / "data-raw" / "ayah"
REAL_MUSHAF = Path(__file__).resolve().parent.parent / "assets" / "mushaf"
TOOL = Path(__file__).resolve().parent


def make_inputs(root):
    """A tiny but complete input set: 2 surahs, 3 ayahs (1:1, 1:2, 2:1), 4 Quranic words."""
    raw, mushaf = root / "raw", root / "mushaf"
    (mushaf / "pages").mkdir(parents=True)
    raw.mkdir()
    words = [("1:1:1", 1, "ٱلۡحَمۡدُ"), ("1:1:2", 2, "لِلَّهِ"), ("1:1:3", 3, "١"),
             ("1:2:1", 4, "ٱلرَّحۡمَٰنِ"), ("1:2:2", 5, "٢"), ("2:1:1", 6, "الٓمٓ"), ("2:1:2", 7, "١")]
    (mushaf / "meta.json").write_text(json.dumps({"surahs": [
        {"n": 1, "name": "الفاتحة", "ayahs": 2, "startPage": 1},
        {"n": 2, "name": "البقرة", "ayahs": 1, "startPage": 1}]}), encoding="utf-8")
    (mushaf / "pages" / "p001.json").write_text(json.dumps({"page": 1, "lines": [
        {"n": 1, "type": "ayah", "words": [{"id": i, "k": k, "g": "x"} for k, i, _ in words]}]}), encoding="utf-8")
    qul = {k: {"id": i, "surah": k.split(":")[0], "ayah": k.split(":")[1], "word": k.split(":")[2],
               "location": k, "text": t} for k, i, t in words}
    info = zipfile.ZipInfo("qpc-hafs-word-by-word.json", date_time=(2025, 5, 28, 12, 52, 0))
    with zipfile.ZipFile(raw / "qul-312-hafs-words.json.zip", "w") as z:
        z.writestr(info, json.dumps(qul, ensure_ascii=False))
    tafsir = {"1:1": {"text": "<span>أ</span>"}, "1:2": {}, "2:1": {"text": "ب"}}
    info = zipfile.ZipInfo("ar-tafseer-al-saddi.json", date_time=(2025, 5, 26, 19, 38, 0))
    with zipfile.ZipFile(raw / "qul-24-tafsir-saadi-ar.json.zip", "w") as z:
        z.writestr(info, json.dumps(tafsir, ensure_ascii=False))
    (raw / "tanzil-en.sahih.txt").write_text(
        "1|1|All praise is due to Allah\n1|2|The Entirely Merciful\n2|1|Alif, Lam, Meem.\n\n"
        "# Name: Saheeh International\n#  Last Update: April 24, 2011\n#  Source: Tanzil.net\n", encoding="utf-8")
    (raw / "quranpedia-meanings.json.gz").write_bytes(gzip.compress(json.dumps(gharib_raw(
        (1, 1, [(327, [("لِلَّهِ", "ملك")])]), (2, 1, [(208, [("الم", "حروف")])])), ensure_ascii=False).encode()))
    tanzil_arabic = root / "quran-uthmani.txt"
    tanzil_arabic.write_text("1|1|ٱلۡحَمۡدُ لِلَّهِ\n1|2|ٱلرَّحۡمَٰنِ\n2|1|" + BISM + " الم\n", encoding="utf-8")
    known, pinned = root / "known.json", root / "pinned.json"
    known.write_text(json.dumps({"differences": []}), encoding="utf-8")
    pinned.write_text(json.dumps({"ayahs": ["1:2"]}), encoding="utf-8")
    return dict(raw_dir=raw, mushaf_dir=mushaf, tanzil_arabic=tanzil_arabic, known_path=known,
                pinned_path=pinned, totals=(3, 4))


def run_build(tmp_path, **override):
    inputs = make_inputs(tmp_path)
    inputs.update(override)
    out = tmp_path / "out"
    return a.build(out_dir=out, **inputs), out


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def test_build_writes_one_file_per_surah_and_kind(tmp_path):
    _, out = run_build(tmp_path)
    base = out / "ayah"
    assert read(base / "text" / "001.json") == {"surah": 1, "ayahs": [["ٱلۡحَمۡدُ", "لِلَّهِ"], ["ٱلرَّحۡمَٰنِ"]]}
    assert read(base / "text" / "002.json") == {"surah": 2, "ayahs": [["الٓمٓ"]]}
    assert read(base / "tafsir" / "001.json") == {
        "surah": 1, "entries": [{"from": 1, "to": 1, "text": "أ"}], "without": [2]}
    assert read(base / "tafsir" / "002.json") == {"surah": 2, "entries": [{"from": 1, "to": 1, "text": "ب"}], "without": []}
    assert read(base / "translation" / "001.json") == {
        "surah": 1, "ayahs": ["All praise is due to Allah", "The Entirely Merciful"]}
    assert read(base / "gharib" / "001.json") == {"surah": 1, "ayahs": {"1": [{"w": "لِلَّهِ", "m": "ملك", "b": 327}]}}
    assert read(base / "gharib" / "002.json") == {"surah": 2, "ayahs": {"1": [{"w": "الم", "m": "حروف", "b": 208}]}}
    assert sorted(p.name for p in (base / "text").iterdir()) == ["001.json", "002.json"]
    assert "\n" not in (base / "text" / "001.json").read_text(encoding="utf-8")


def test_sources_json_records_every_input_with_its_sha256_and_version(tmp_path):
    inputs = make_inputs(tmp_path)
    out = tmp_path / "out"
    a.build(out_dir=out, **inputs)
    sources = {str(s["id"]): s for s in read(out / "ayah" / "sources.json")["sources"]}
    assert set(sources) == {"qul-312", "qul-24", "tanzil-en-sahih", "327", "208"}
    raw = inputs["raw_dir"]
    digest = lambda name: hashlib.sha256((raw / name).read_bytes()).hexdigest()
    assert sources["qul-312"]["sha256"] == digest("qul-312-hafs-words.json.zip")
    assert sources["qul-24"]["sha256"] == digest("qul-24-tafsir-saadi-ar.json.zip")
    assert sources["tanzil-en-sahih"]["sha256"] == digest("tanzil-en.sahih.txt")
    assert sources["327"]["sha256"] == sources["208"]["sha256"] == digest("quranpedia-meanings.json.gz")
    assert sources["qul-312"]["version"] == "2025-05-28" and sources["qul-24"]["version"] == "2025-05-26"
    assert sources["tanzil-en-sahih"]["version"] == "2011-04-24"
    assert sources["327"]["version"] == "2026-11-14"
    assert sources["327"]["kind"] == "gharib" and sources["327"]["author"] == "ابن الهائم"
    assert sources["208"]["author"] == "ابن الجوزي"
    assert sources["qul-24"]["kind"] == "tafsir" and sources["tanzil-en-sahih"]["kind"] == "translation"


def test_build_reports_sizes_and_gharib_coverage(tmp_path):
    report, out = run_build(tmp_path)
    assert set(report["sizes"]) == {"text", "tafsir", "translation", "gharib", "total"}
    assert all(v["raw"] > 0 and 0 < v["gzip"] for v in report["sizes"].values())
    kinds = sum(report["sizes"][k]["raw"] for k in ("text", "tafsir", "translation", "gharib"))
    assert report["sizes"]["total"]["raw"] == kinds + (out / "ayah" / "sources.json").stat().st_size
    assert report["gharib_covered"] == 2 and report["ayahs"] == 3


def test_build_stops_above_the_size_limit_and_writes_nothing(tmp_path):
    inputs = make_inputs(tmp_path)
    out = tmp_path / "out"
    with pytest.raises(ValueError, match="size"):
        a.build(out_dir=out, max_bytes=10, **inputs)
    assert not out.exists()


@pytest.mark.parametrize("tamper", ["alignment", "crosscheck", "tafsir", "translation", "gharib"])
def test_build_writes_nothing_when_any_check_fails(tmp_path, tamper):
    inputs = make_inputs(tmp_path)
    raw = inputs["raw_dir"]
    if tamper == "alignment":
        z = raw / "qul-312-hafs-words.json.zip"
        data = json.loads(zipfile.ZipFile(z).read("qpc-hafs-word-by-word.json"))
        data["1:2:2"]["text"] = "ٱلرَّحِيمِ"  # last word is no longer a numeral marker
        with zipfile.ZipFile(z, "w") as zf:
            zf.writestr("qpc-hafs-word-by-word.json", json.dumps(data, ensure_ascii=False))
    elif tamper == "crosscheck":
        inputs["tanzil_arabic"].write_text("1|1|غير ذلك\n1|2|ٱلرَّحۡمَٰنِ\n2|1|" + BISM + " الم\n", encoding="utf-8")
    elif tamper == "tafsir":
        inputs["pinned_path"].write_text(json.dumps({"ayahs": []}), encoding="utf-8")
    elif tamper == "translation":
        (raw / "tanzil-en.sahih.txt").write_text("1|1|x\n", encoding="utf-8")
    elif tamper == "gharib":
        (raw / "quranpedia-meanings.json.gz").write_bytes(gzip.compress(json.dumps(
            gharib_raw((9, 9, [(327, [("x", "y")])]))).encode()))
    out = tmp_path / "out"
    with pytest.raises(ValueError):
        a.build(out_dir=out, **inputs)
    assert not out.exists()


def test_a_failed_build_leaves_an_earlier_output_untouched(tmp_path):
    inputs = make_inputs(tmp_path)
    out = tmp_path / "out"
    a.build(out_dir=out, **inputs)
    before = (out / "ayah" / "text" / "001.json").read_text(encoding="utf-8")
    inputs["pinned_path"].write_text(json.dumps({"ayahs": []}), encoding="utf-8")
    with pytest.raises(ValueError):
        a.build(out_dir=out, **inputs)
    assert (out / "ayah" / "text" / "001.json").read_text(encoding="utf-8") == before
    assert not (out / "ayah.tmp").exists()


def test_main_returns_1_and_names_the_reason_when_a_check_fails(tmp_path, capsys):
    inputs = make_inputs(tmp_path)
    inputs["pinned_path"].write_text(json.dumps({"ayahs": []}), encoding="utf-8")
    code = a.main([
        "--raw", str(inputs["raw_dir"]), "--mushaf", str(inputs["mushaf_dir"]), "--tanzil", str(inputs["tanzil_arabic"]),
        "--known", str(inputs["known_path"]), "--pinned", str(inputs["pinned_path"]), "--out", str(tmp_path / "out"),
        "--expect-ayahs", "3", "--expect-words", "4"])
    assert code == 1
    assert "build failed" in capsys.readouterr().err
    assert not (tmp_path / "out").exists()


@pytest.mark.skipif(not (REAL_RAW / "quranpedia-meanings.json.gz").exists() or not (REAL_MUSHAF / "meta.json").exists(),
                    reason="real inputs are not downloaded")
def test_real_inputs_build_the_expected_assets(tmp_path):
    report = a.build(
        raw_dir=REAL_RAW, mushaf_dir=REAL_MUSHAF, tanzil_arabic=REAL_RAW.parent / "quran-uthmani.txt",
        known_path=TOOL / "ayah_text_known_differences.json", pinned_path=TOOL / "tafsir_without_own_entry.json",
        out_dir=tmp_path)
    base = tmp_path / "ayah"
    for kind in ("text", "tafsir", "translation", "gharib"):
        assert len(list((base / kind).iterdir())) == 114
    assert report["ayahs"] == 6236 and report["words"] == 77432
    assert report["gharib_covered"] == 3689
    assert report["sizes"]["total"]["raw"] < 40 * 1024 * 1024
    assert read(base / "tafsir" / "002.json")["without"] == [107, 109, 111, 286]
