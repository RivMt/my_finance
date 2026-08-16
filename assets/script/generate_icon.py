#!/usr/bin/env python3
"""Render an SVG icon to a PNG, optionally centered on a larger canvas."""

from __future__ import annotations

import argparse
import io
from pathlib import Path

import cairosvg
from PIL import Image


def positive_int(value: str) -> int:
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError("must be greater than zero")
    return number


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="source SVG file")
    parser.add_argument("output", type=Path, help="output PNG file")
    parser.add_argument("width", type=positive_int, help="output width in pixels")
    parser.add_argument("height", type=positive_int, help="output height in pixels")
    parser.add_argument(
        "--icon-size",
        type=positive_int,
        help="render the SVG into this square and center it on the canvas",
    )
    parser.add_argument(
        "--background",
        default=None,
        help="Pillow-compatible canvas color (default: transparent)",
    )
    return parser.parse_args()


def render_svg(source: Path, width: int, height: int) -> Image.Image:
    png = cairosvg.svg2png(
        bytestring=source.read_bytes(),
        output_width=width,
        output_height=height,
    )
    with Image.open(io.BytesIO(png)) as image:
        return image.convert("RGBA")


def main() -> None:
    args = parse_args()
    if not args.source.is_file():
        raise SystemExit(f"SVG source does not exist: {args.source}")

    args.output.parent.mkdir(parents=True, exist_ok=True)

    if args.icon_size is None:
        image = render_svg(args.source, args.width, args.height)
    else:
        if args.icon_size > min(args.width, args.height):
            raise SystemExit("--icon-size must fit within both canvas dimensions")
        icon = render_svg(args.source, args.icon_size, args.icon_size)
        background = (0, 0, 0, 0) if args.background is None else args.background
        image = Image.new("RGBA", (args.width, args.height), background)
        offset = ((args.width - args.icon_size) // 2, (args.height - args.icon_size) // 2)
        image.alpha_composite(icon, offset)

    image.save(args.output, format="PNG", optimize=True)


if __name__ == "__main__":
    main()
