#!/usr/bin/env python3
"""Crop a region out of a screenshot and encode it as PNG.

    shotcrop.py SHOT.ppm "X,Y WxH" FILE.png

Writes the PNG to FILE. shot.sh copies it to the clipboard by reading the same file:
the screenshot has to stay on disk anyway, and the exit code then belongs
to the crop rather than to wl-copy, for which empty input would pass as success.

Why we crop ourselves at all. A region screenshot could be taken with a second
grim call against the frozen frame already on screen. But then the image
passes through the compositor a second time, and its quality starts to depend on
what the compositor does with the output: night temperature (hyprsunset), digital
vibrance, dithering to 10 bits. Today capture happens before all of that and the
frame comes back pixel for pixel, which has been verified, but that is a property
of someone else's implementation rather than a promise. Here we crop the very file
captured at the start, with no colour conversions, no rounding, no second frame.

Hence PPM rather than PNG for the source shot: exactly two readers need it,
the layer that shows the freeze frame and this script. Both read it at once,
rather than compressing and decompressing for a temporary file in memory.

Its own PNG handling rather than ImageMagick, because pulling that in for one
crop is not worth it: python3 is already a dependency, and zlib ships in its
standard library.
"""

import json
import struct
import subprocess
import sys
import zlib


def die(msg):
    print("shotcrop: " + msg, file=sys.stderr)
    sys.exit(1)


def read_ppm(path):
    """P6, 8 bits per channel, the only thing grim -t ppm prints."""
    try:
        with open(path, "rb") as f:
            data = f.read()
    except OSError as e:
        die(str(e))
    if data[:2] != b"P6":
        die("shot is not in P6 format")

    nums = []
    i = 2
    while len(nums) < 3:
        if i >= len(data):
            die("truncated header")
        c = data[i:i + 1]
        if c.isspace():
            i += 1
            continue
        if c == b"#":
            while i < len(data) and data[i:i + 1] != b"\n":
                i += 1
            continue
        j = i
        while j < len(data) and not data[j:j + 1].isspace():
            j += 1
        nums.append(int(data[i:j]))
        i = j
    i += 1

    w, h, maxval = nums
    if maxval != 255:
        die("expected 8 bits per channel, got maxval=%d" % maxval)
    return w, h, data[i:i + w * h * 3]


def layout_frame(img_w):
    """Origin of the layout and the "logical point to shot pixel" factor.

    grim captures all monitors in one image, while slurp reports coordinates in
    logical layout points, whose origin need not be zero:
    a monitor left of the main one lives at negative x. We work it out from the
    shot itself: its width is the layout in pixels.
    """
    try:
        out = subprocess.run(["hyprctl", "monitors", "-j"],
                             capture_output=True, text=True, check=True).stdout
        mons = json.loads(out)
        if not mons:
            raise ValueError("empty monitor list")
    except Exception:
        return 0, 0, 1.0

    min_x = min(m["x"] for m in mons)
    min_y = min(m["y"] for m in mons)
    max_x = max(m["x"] + m["width"] / m["scale"] for m in mons)
    span = max_x - min_x
    scale = img_w / span if span > 0 else 1.0
    return min_x, min_y, scale


def parse_geom(text):
    """"X,Y WxH", the form slurp prints."""
    try:
        pos, size = text.strip().split(" ")
        x, y = (int(v) for v in pos.split(","))
        w, h = (int(v) for v in size.split("x"))
    except ValueError:
        die("cannot parse the region: %r" % text)
    return x, y, w, h


def encode_png(w, h, rows):
    def chunk(tag, payload):
        body = tag + payload
        return (struct.pack(">I", len(payload)) + body
                + struct.pack(">I", zlib.crc32(body)))

    raw = b"".join(b"\x00" + r for r in rows)
    header = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", header)
            + chunk(b"IDAT", zlib.compress(raw, 6))
            + chunk(b"IEND", b""))


def main():
    if len(sys.argv) != 4:
        die("usage: shotcrop.py SHOT.ppm \"X,Y WxH\" FILE.png")
    src, geom, dst = sys.argv[1:4]

    img_w, img_h, pixels = read_ppm(src)
    if len(pixels) < img_w * img_h * 3:
        die("shot is shorter than its header")

    off_x, off_y, scale = layout_frame(img_w)
    gx, gy, gw, gh = parse_geom(geom)

    x = int(round((gx - off_x) * scale))
    y = int(round((gy - off_y) * scale))
    w = int(round(gw * scale))
    h = int(round(gh * scale))

    x0, y0 = max(0, x), max(0, y)
    x1, y1 = min(img_w, x + w), min(img_h, y + h)
    if x1 <= x0 or y1 <= y0:
        die("the selection is outside the shot")

    rows = []
    for row in range(y0, y1):
        start = (row * img_w + x0) * 3
        rows.append(pixels[start:start + (x1 - x0) * 3])

    try:
        with open(dst, "wb") as f:
            f.write(encode_png(x1 - x0, y1 - y0, rows))
    except OSError as e:
        die(str(e))


if __name__ == "__main__":
    main()
