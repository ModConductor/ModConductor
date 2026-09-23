#!/usr/bin/env python3
"""Generate the Flutter, Linux, and Windows icons from the approved SVG."""

import argparse
from pathlib import Path
import struct
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
SVG = ROOT / "ui/packages/mc_ui_foundation/assets/brand/modconductor.svg"
FOUNDATION_PNG = ROOT / "ui/packages/mc_ui_foundation/assets/brand/modconductor.png"
LINUX_ICONS = ROOT / "packaging/icons/hicolor"
WINDOWS_ICO = ROOT / "ui/apps/mod_conductor/windows/runner/resources/app_icon.ico"
ICON_ID = "dev.modconductor.mod_conductor"
ICO_SIZES = (16, 24, 32, 48, 64, 128, 256)


def render(size: int, destination: Path) -> bytes:
    subprocess.run([
        "rsvg-convert", "--width", str(size), "--height", str(size),
        "--output", str(destination), str(SVG),
    ], check=True)
    return destination.read_bytes()


def icon_file(frames: list[tuple[int, bytes]]) -> bytes:
    header = struct.pack("<HHH", 0, 1, len(frames))
    offset = len(header) + len(frames) * 16
    entries = bytearray()
    images = bytearray()
    for size, png in frames:
        entries += struct.pack("<BBBBHHII", size % 256, size % 256, 0, 0,
                               1, 32, len(png), offset)
        images += png
        offset += len(png)
    return header + entries + images


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    scratch = ROOT / ".agent-workspace"
    scratch.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="mc061-icons-", dir=scratch) as temporary:
        work = Path(temporary)
        frames = [(size, render(size, work / f"{size}.png")) for size in ICO_SIZES]
        outputs = {
            FOUNDATION_PNG: render(512, work / "512.png"),
            WINDOWS_ICO: icon_file(frames),
        }
        outputs.update({
            LINUX_ICONS / f"{size}x{size}/apps/{ICON_ID}.png": dict(frames)[size]
            for size in (48, 256)
        })
        for path, data in outputs.items():
            if args.check:
                if not path.is_file() or path.read_bytes() != data:
                    parser.error(f"Icon needs regeneration: {path.relative_to(ROOT)}")
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)


if __name__ == "__main__":
    main()
