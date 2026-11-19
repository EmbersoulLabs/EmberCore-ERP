#!/usr/bin/env python3
"""Resize the EmberCore ERP app icon into web, Android, and iOS slots."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[1]
SRC = Path(
    r"C:\Users\USER\.cursor\projects\c-Users-USER-Desktop-EmberSoullabs-EmberCore-ERP"
    r"\assets\c__Users_USER_AppData_Roaming_Cursor_User_workspaceStorage_"
    r"36e9cc42f9800a2afe8021d5f0fdee6a_images_Ember_Core_Icon-dcff12d5-fe16-4aac-94e9-d332b02e46b7.jpg"
)

def square_master(im: Image.Image) -> Image.Image:
    im = im.convert("RGB")
    w, h = im.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    return im.crop((left, top, left + side, top + side))


def resize(im: Image.Image, size: int) -> Image.Image:
    return im.resize((size, size), Image.Resampling.LANCZOS)


def save_png(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, format="PNG", optimize=True)
    print(f"{path.relative_to(REPO)} {im.size} {path.stat().st_size}")


def main() -> None:
    if not SRC.exists():
        raise SystemExit(f"missing source icon: {SRC}")
    master = square_master(Image.open(SRC))
    brand = REPO / "assets" / "images" / "brand"
    save_png(resize(master, 1024), brand / "embercore_app_icon.png")

    web = REPO / "web"
    save_png(resize(master, 128), web / "favicon.png")
    save_png(resize(master, 192), web / "icons" / "Icon-192.png")
    save_png(resize(master, 512), web / "icons" / "Icon-512.png")

    for folder in (
        "images",
        "fonts",
        "audios",
        "jsons",
        "pdfs",
        "rive_animations",
        "videos",
    ):
        save_png(resize(master, 128), REPO / "assets" / folder / "favicon.png")

    android = REPO / "android" / "app" / "src" / "main" / "res"
    for folder, size in {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }.items():
        save_png(resize(master, size), android / folder / "ic_launcher.png")

    ios = REPO / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for name, size in ios_sizes.items():
        save_png(resize(master, size), ios / name)


if __name__ == "__main__":
    main()
