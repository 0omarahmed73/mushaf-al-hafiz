"""Tests for tool/build_quran_assets.py (T006). Run: uv run --with pytest pytest tool/ -q

The session fixture runs the real build (without fonts) into a temp dir and reads the generated
files back, so these tests check the artifacts the Flutter app will load (contracts/assets.md).
"""
import copy
import json
from pathlib import Path

import pytest

import build_quran_assets as b

RAW = Path(__file__).resolve().parent.parent / "data-raw"


@pytest.fixture(scope="session")
def built(tmp_path_factory):
    out = tmp_path_factory.mktemp("assets")
    b.build(RAW, out, skip_fonts=True)
    pages = [
        json.loads((out / "mushaf" / "pages" / f"p{n:03d}.json").read_text(encoding="utf-8"))
        for n in range(1, 605)
    ]
    meta = json.loads((out / "mushaf" / "meta.json").read_text(encoding="utf-8"))
    return pages, meta


def test_page_count_and_lines(built):
    pages, meta = built
    assert len(pages) == 604 and meta["pages"] == 604
    assert [p["page"] for p in pages] == list(range(1, 605))
    assert len(pages[0]["lines"]) == 8 and len(pages[1]["lines"]) == 8
    assert all(len(p["lines"]) == 15 for p in pages[2:])
    for p in pages:
        assert [l["n"] for l in p["lines"]] == list(range(1, len(p["lines"]) + 1))


def test_every_word_once_and_in_order(built):
    pages, _ = built
    ids = [w["id"] for p in pages for l in p["lines"] for w in l["words"]]
    assert ids == list(range(1, 83669))
    assert all(w["g"] and w["k"].count(":") == 2 for p in pages for l in p["lines"] for w in l["words"])


def test_first_pages_and_juz(built):
    pages, _ = built
    assert pages[0]["lines"][0] == {"n": 1, "type": "surah_name", "centered": True, "surah": 1, "words": []}
    assert pages[0]["lines"][1]["words"][0]["k"] == "1:1:1"
    assert pages[1]["lines"][1]["type"] == "basmallah"
    assert pages[0]["juz"] == 1 and pages[603]["juz"] == 30
    assert pages[0]["hizbQuarter"] == 1


def test_line_types_only_ayah_carries_words(built):
    pages, _ = built
    for p in pages:
        for l in p["lines"]:
            assert l["type"] in ("ayah", "surah_name", "basmallah")
            assert (l["type"] == "ayah") == bool(l["words"])
            assert (l["type"] == "surah_name") == (l["surah"] is not None)


def test_meta_reference_values(built):
    _, meta = built
    assert meta["edition"] == "QCF V2 (1421H)"
    assert len(meta["surahs"]) == 114
    assert meta["surahs"][0] == {"n": 1, "name": "الفاتحة", "ayahs": 7, "startPage": 1}
    assert meta["surahs"][17]["startPage"] == 293          # al-Kahf
    assert meta["ayahPage"]["2:255"] == 42                 # Ayat al-Kursi
    assert len(meta["ayahPage"]) == 6236
    assert meta["pageSurahs"][0] == [1]
    assert len(meta["pageJuz"]) == 604 and meta["pageJuz"][603] == 30
    assert len(meta["pageHizbQuarter"]) == 604 and len(meta["pageSurahs"]) == 604


def test_start_page_is_page_of_first_ayah_even_if_title_is_on_previous_page(built):
    pages, meta = built
    # an-Nisa: its title line is the last line of page 76, its first ayah is on page 77 (printed index: 77)
    assert pages[75]["lines"][14]["type"] == "surah_name" and pages[75]["lines"][14]["surah"] == 4
    assert meta["ayahPage"]["4:1"] == 77
    assert meta["surahs"][3]["startPage"] == 77
    assert 4 in meta["pageSurahs"][75] and 4 in meta["pageSurahs"][76]   # title page and text page both list it


def test_validate_accepts_the_real_build(built):
    pages, meta = built
    b.validate(pages, meta)


def test_validate_rejects_missing_word(built):
    pages, meta = built
    broken = copy.deepcopy(pages)
    broken[5]["lines"][3]["words"].pop()
    with pytest.raises(ValueError):
        b.validate(broken, meta)


def test_validate_rejects_wrong_line_count(built):
    pages, meta = built
    broken = copy.deepcopy(pages)
    broken[10]["lines"].pop()
    with pytest.raises(ValueError):
        b.validate(broken, meta)


def test_validate_rejects_wrong_reference_value(built):
    pages, meta = built
    broken = copy.deepcopy(meta)
    broken["ayahPage"]["2:255"] = 43
    with pytest.raises(ValueError):
        b.validate(pages, broken)


def test_failed_validation_writes_nothing(tmp_path, monkeypatch):
    def always_fail(pages, meta):
        raise ValueError("boom")

    monkeypatch.setattr(b, "validate", always_fail)
    with pytest.raises(ValueError):
        b.build(RAW, tmp_path, skip_fonts=True)
    assert not (tmp_path / "mushaf").exists()
