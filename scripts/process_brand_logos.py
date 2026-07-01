#!/usr/bin/env python3
"""Remove black backgrounds from EmberSoul Labs logo PNGs."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

REPO_ROOT = Path(__file__).resolve().parents[1]
SRC = Path.home() / ".cursor/projects/c-Users-USER-Desktop-EmberSoullabs-EmberCore-ERP/assets"
OUT = REPO_ROOT / "assets/images/brand"

MAPPING = {
    "*logo-horizontal*": "embersoul_labs_logo_horizontal.png",
    "*202318*": "embersoul_labs_logo_horizontal.png",
    "*202353*": "embersoul_labs_logo_horizontal_sm.png",
    "*202457*": "embersoul_labs_logo_stacked.png",
    "*202602*": "embersoul_labs_logo_icon.png",
}

HORIZONTAL_SM_MAX_WIDTH = 280

THRESHOLD = 32
FEATHER = 28


def remove_black(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            brightness = max(r, g, b)
            if brightness <= THRESHOLD:
                px[x, y] = (r, g, b, 0)
            elif brightness <= THRESHOLD + FEATHER:
                fade = int(255 * (brightness - THRESHOLD) / FEATHER)
                px[x, y] = (r, g, b, min(a, fade))
    bbox = im.getbbox()
    return im.crop(bbox) if bbox else im


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    written: set[str] = set()
    for pattern, out_name in MAPPING.items():
        matches = sorted(SRC.glob(pattern))
        if not matches:
            continue
        out = remove_black(Image.open(matches[0]))
        out.save(OUT / out_name, optimize=True)
        written.add(out_name)
        print(f"Wrote {out_name}: {out.size}")

    if "embersoul_labs_logo_horizontal.png" in written:
        horizontal = Image.open(OUT / "embersoul_labs_logo_horizontal.png")
        sm = horizontal.copy()
        if sm.width > HORIZONTAL_SM_MAX_WIDTH:
            ratio = HORIZONTAL_SM_MAX_WIDTH / sm.width
            sm = sm.resize(
                (HORIZONTAL_SM_MAX_WIDTH, max(1, int(sm.height * ratio))),
                Image.Resampling.LANCZOS,
            )
        sm.save(OUT / "embersoul_labs_logo_horizontal_sm.png", optimize=True)
        print(f"Wrote embersoul_labs_logo_horizontal_sm.png: {sm.size}")

    icon_path = OUT / "embersoul_labs_logo_icon.png"
    if icon_path.exists():
        icon = Image.open(icon_path)
        for size in (128, 256):
            resized = icon.copy()
            resized.thumbnail((size, size), Image.Resampling.LANCZOS)
            name = f"embersoul_labs_logo_icon_{size}.png"
            resized.save(OUT / name, optimize=True)
            print(f"Wrote {name}: {resized.size}")

        favicon = OUT / "embersoul_labs_logo_icon_128.png"
        (REPO_ROOT / "web/favicon.png").write_bytes(favicon.read_bytes())
        print("Updated web/favicon.png")


if __name__ == "__main__":
    main()
