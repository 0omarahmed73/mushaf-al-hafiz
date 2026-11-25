"""Tests for tool/web_font_coverage.py (feature 012, gate G7). Run: uv run --with pytest --with fonttools pytest tool/test_web_font_coverage.py -q

The web build ships no system fonts, so every code point the app can show must be in one of the three bundled fonts
(Cairo, Amiri Quran, Reem Kufi). The tests use tiny synthetic fonts built in a temp folder.
"""
import json

import pytest
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

import web_font_coverage as w


def make_font(path, chars):
    """A real (tiny) TrueType font whose cmap holds exactly [chars]."""
    names = [".notdef"] + [f"g{ord(c):04x}" for c in chars]
    fb = FontBuilder(1000, isTTF=True)
    fb.setupGlyphOrder(names)
    fb.setupCharacterMap({ord(c): f"g{ord(c):04x}" for c in chars})
    pen = TTGlyphPen(None)
    pen.moveTo((0, 0)); pen.lineTo((0, 100)); pen.lineTo((100, 100)); pen.closePath()
    glyph = pen.glyph()
    fb.setupGlyf({n: glyph for n in names})
    fb.setupHorizontalMetrics({n: (500, 0) for n in names})
    fb.setupHorizontalHeader(ascent=800, descent=-200)
    fb.setupNameTable({"familyName": "T", "styleName": "R"})
    fb.setupOS2()
    fb.setupPost()
    fb.save(str(path))
    return path


def test_font_codepoints_reads_the_cmap(tmp_path):
    f = make_font(tmp_path / "a.ttf", "اب")
    assert w.font_codepoints(f) == {ord("ا"), ord("ب")}


def test_gaps_empty_when_every_point_is_covered_by_the_union(tmp_path):
    a = make_font(tmp_path / "a.ttf", "اب")
    b = make_font(tmp_path / "b.ttf", "جx")
    assert w.gaps({ord("ا"), ord("ج"), ord("x")}, [a, b]) == set()


def test_gaps_reports_a_point_missing_from_every_font(tmp_path):
    a = make_font(tmp_path / "a.ttf", "اب")
    b = make_font(tmp_path / "b.ttf", "ج")
    assert w.gaps({ord("ا"), ord("ش")}, [a, b]) == {ord("ش")}


def test_controls_and_format_characters_need_no_glyph(tmp_path):
    a = make_font(tmp_path / "a.ttf", "ا")
    assert w.gaps({ord("\n"), 0x200F, 0x200C, ord("ا")}, [a]) == set()


def test_string_literals_of_dart_source():
    src = "const a = 'مرحبا'; final b = \"x$y ش\"; // 'تعليق'\nconst c = '''سطر\nثان''';"
    cps = w.dart_literal_codepoints(src)
    assert ord("م") in cps and ord("ش") in cps and ord("ث") in cps
    assert ord("ت") not in cps  # a comment is not shown to the reader


def test_main_fails_on_a_gap_and_passes_when_covered(tmp_path, capsys):
    lib = tmp_path / "lib"; lib.mkdir()
    (lib / "s.dart").write_text("const t = 'اش';", encoding="utf-8")
    data = tmp_path / "data"; data.mkdir()
    (data / "001.json").write_text(json.dumps({"ayahs": ["ا"]}), encoding="utf-8")
    full = make_font(tmp_path / "full.ttf", "اش")
    part = make_font(tmp_path / "part.ttf", "ا")
    assert w.main(["--lib", str(lib), "--data", str(data), "--fonts", str(full)]) == 0
    assert "PASS" in capsys.readouterr().out
    assert w.main(["--lib", str(lib), "--data", str(data), "--fonts", str(part)]) == 1
    out = capsys.readouterr().out
    assert "FAIL" in out and "U+0634" in out


def test_pdf_and_render_libraries_are_not_scanned(tmp_path):
    lib = tmp_path / "lib"; (lib / "pdf").mkdir(parents=True)
    (lib / "pdf" / "p.dart").write_text("const t = 'ش';", encoding="utf-8")
    assert ord("ش") not in w.collect_lib_codepoints(lib)
