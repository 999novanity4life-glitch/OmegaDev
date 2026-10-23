"""Textures for the 3D floor drains (same palette and light as the kit).

floor_plates  - plain bevelled plates (the drains are real geometry now)
drain_grate   - steel bars with transparent gaps (RGBA) laid over the trench
slime_flow    - tileable flowing slime (ripples + bubbles) that scrolls along
"""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from textures import N, PAL, canvas, mask, paint, rrect, finish, bolt


def floor_plates():
    h, c = canvas()
    c[:] = PAL["seam"]
    half = N // 2
    for i in range(2):
        for j in range(2):
            x0, y0 = i * half, j * half
            plate = mask(rrect((x0 + 10, y0 + 10, x0 + half - 10, y0 + half - 10), 22), blur=7)
            paint(c, plate, (124, 132, 156))
            h += plate
            for bx, by in ((x0 + 34, y0 + 34), (x0 + half - 34, y0 + 34), (x0 + 34, y0 + half - 34), (x0 + half - 34, y0 + half - 34)):
                bolt(h, c, bx, by, 12)
    return finish("floor_plates", h, c, strength=40)


def drain_grate():
    S = 512
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    bars = 6
    step = S / bars
    for k in range(bars):
        y = k * step + step * 0.18
        hgt = step * 0.42
        d.rounded_rectangle((0, y, S, y + hgt), radius=hgt / 2.2, fill=(150, 158, 182, 255))
        d.rounded_rectangle((0, y + 3, S, y + hgt * 0.38), radius=hgt / 4, fill=(214, 222, 240, 255))
        d.rounded_rectangle((0, y + hgt * 0.72, S, y + hgt), radius=hgt / 4, fill=(96, 102, 126, 255))
    im.save("drain_grate.png")
    return im


def slime_flow():
    S = 512
    yy, xx = np.mgrid[0:S, 0:S] / S
    # Ripple bands running along the channel (V direction), tileable.
    wave = 0.5 + 0.5 * np.sin((yy * 6 + 0.12 * np.sin(xx * 2 * math.pi * 2)) * 2 * math.pi)
    base = np.array([40, 170, 40], dtype=float)
    hi = np.array([150, 255, 90], dtype=float)
    col = base[None, None, :] * (1 - wave[..., None] * 0.6) + hi[None, None, :] * (wave[..., None] * 0.6)
    img = Image.fromarray(np.clip(col, 0, 255).astype(np.uint8)).convert("RGBA")
    d = ImageDraw.Draw(img)
    rnd = np.random.default_rng(7)
    for _ in range(26):
        x, y, r = rnd.uniform(0, S), rnd.uniform(0, S), rnd.uniform(6, 18)
        for ox in (-S, 0, S):
            for oy in (-S, 0, S):
                d.ellipse((x + ox - r, y + oy - r, x + ox + r, y + oy + r), outline=(220, 255, 200, 255), width=3)
                d.ellipse((x + ox - r * 0.4, y + oy - r * 0.6, x + ox, y + oy - r * 0.2), fill=(240, 255, 230, 255))
    img = img.filter(ImageFilter.GaussianBlur(0.8))
    img.save("slime_flow.png")
    return img


if __name__ == "__main__":
    floor_plates()
    g = drain_grate()
    s = slime_flow()
    prev = Image.new("RGBA", (1024, 512), (20, 18, 30, 255))
    prev.paste(s, (0, 0))
    over = s.copy()
    over.alpha_composite(g)
    prev.paste(over, (512, 0))
    prev.convert("RGB").save("drain_preview.png")
    print("done")
