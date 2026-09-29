"""Generates assets/icon/icon.png (1024, opaque) and icon_foreground.png
(adaptive-icon foreground with safe-zone padding). Run: python3 tool/make_icon.py

Design: indigo → teal gradient with two people and a check badge. Deliberately
avoids any third-party brand shapes or colors (no camera glyph, no
pink/orange/purple gradient)."""
from PIL import Image, ImageDraw

S = 1024
SS = 4  # supersampling
BRAND = (67, 56, 202)  # #4338CA


def gradient(size):
    stops = [(0.0, (67, 56, 202)), (0.55, (37, 99, 235)), (1.0, (13, 148, 136))]
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            for (t0, c0), (t1, c1) in zip(stops, stops[1:]):
                if t0 <= t <= t1:
                    k = (t - t0) / (t1 - t0)
                    px[x, y] = tuple(round(a + (b - a) * k) for a, b in zip(c0, c1))
                    break
    return img


def person(d, cx, top, u, fill):
    """Head + rounded shoulders, centered on cx."""
    r = 92 * u
    d.ellipse((cx - r, top, cx + r, top + 2 * r), fill=fill)
    bw, bh = 330 * u, 250 * u
    by = top + 2 * r + 28 * u
    d.rounded_rectangle((cx - bw / 2, by, cx + bw / 2, by + bh), radius=150 * u, fill=fill)


def glyph(scale):
    size = S * SS
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    u = size / 1024 * scale
    c = size / 2

    # Back person (translucent), then front person (solid).
    back = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    person(ImageDraw.Draw(back), c + 120 * u, c - 300 * u, u * 0.85, (255, 255, 255, 140))
    layer.alpha_composite(back)
    d = ImageDraw.Draw(layer)
    person(d, c - 70 * u, c - 250 * u, u, "white")

    # Check badge.
    bx, by, br = c + 190 * u, c + 190 * u, 120 * u
    d.ellipse((bx - br - 18 * u, by - br - 18 * u, bx + br + 18 * u, by + br + 18 * u), fill=BRAND)
    d.ellipse((bx - br, by - br, bx + br, by + br), fill=(16, 185, 129))
    d.line([(bx - 58 * u, by + 2 * u), (bx - 14 * u, by + 46 * u), (bx + 62 * u, by - 44 * u)],
           fill="white", width=int(34 * u), joint="curve")
    return layer.resize((S, S), Image.LANCZOS)


bg = gradient(S).convert("RGBA")
bg.alpha_composite(glyph(1.0))
bg.convert("RGB").save("assets/icon/icon.png")

# Adaptive icons crop to the inner ~66%; shrink the glyph accordingly.
glyph(0.62).save("assets/icon/icon_foreground.png")
print("icons written")
