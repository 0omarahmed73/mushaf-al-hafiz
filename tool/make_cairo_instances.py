"""Cuts the static weights the app uses out of the variable Cairo font.

Flutter does not map `fontWeight` onto a variable font's weight axis, so the interface font is bundled
as four static files (400, 500, 600, 700). Only the weight axis is pinned; no glyph is changed.

Usage: uv run --with fonttools python tool/make_cairo_instances.py <Cairo[slnt,wght].ttf> <out dir>
Source: github.com/google/fonts, ofl/cairo (SIL Open Font License 1.1).
"""
import sys
from pathlib import Path

from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

WEIGHTS = {"Regular": 400, "Medium": 500, "SemiBold": 600, "Bold": 700}


def main(source: Path, out: Path) -> None:
    out.mkdir(parents=True, exist_ok=True)
    for name, wght in WEIGHTS.items():
        font = TTFont(source)
        static = instantiateVariableFont(font, {"wght": wght, "slnt": 0})
        target = out / f"Cairo-{name}.ttf"
        static.save(target)
        print(f"{target.name}: {target.stat().st_size} bytes")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(Path(sys.argv[1]), Path(sys.argv[2]))
