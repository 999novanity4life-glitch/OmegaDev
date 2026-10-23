"""Puzzle mini-game art in the Slime Rise style (same palette, top-left light).

Pipe tiles (5 shapes x empty/flowing), symbol icons (white, tintable) and a
pad glow. Output 256px PNGs with transparency where useful.
"""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 1024
PAL = {
    "seam": (24, 18, 40), "slate": (62, 78, 110), "slate_hi": (96, 116, 158),
    "steel": (185, 192, 212), "steel_hi": (230, 236, 248), "steel_lo": (110, 118, 142),
    "slime": (107, 255, 61), "slime_dk": (40, 150, 40), "empty": (20, 24, 34),
}
# Connection layouts (N=up, E=right, S=down, W=left) for each canonical shape.
SHAPES = {
    "end": ["N"],
    "straight": ["N", "S"],
    "elbow": ["N", "E"],
    "tee": ["N", "E", "S"],
    "cross": ["N", "E", "S", "W"],
}
EDGE = {"N": (S / 2, 0), "E": (S, S / 2), "S": (S / 2, S), "W": (0, S / 2)}


def layer(draw_fn, blur=0):
    im = Image.new("L", (S, S), 0)
    draw_fn(ImageDraw.Draw(im))
    if blur:
        im = im.filter(ImageFilter.GaussianBlur(blur))
    return np.asarray(im, dtype=np.float64) / 255.0


def paint(col, m, rgb):
    col[:] = col * (1 - m[..., None]) + np.array(rgb, dtype=np.float64) * m[..., None]


def pipe_tile(name, dirs, flowing):
    col = np.zeros((S, S, 3))
    col[:] = PAL["seam"]
    tile = layer(lambda d: d.rounded_rectangle((24, 24, S - 24, S - 24), radius=90, fill=255), blur=8)
    paint(col, tile, PAL["slate"])
    inner = layer(lambda d: d.rounded_rectangle((70, 70, S - 70, S - 70), radius=70, fill=255), blur=10)
    paint(col, inner, PAL["slate_hi"])
    # Soft top-left bevel light on the tile.
    yy, xx = np.mgrid[0:S, 0:S] / S
    col += ((1 - (xx + yy) / 2 - 0.5) * 30 * tile)[..., None]
    cx, cy = S / 2, S / 2

    def arms(width):
        def f(d):
            for k in dirs:
                ex, ey = EDGE[k]
                d.line((cx, cy, ex, ey), fill=255, width=width)
            r = width / 2
            d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=255)
        return f

    shadow = layer(arms(300), blur=26)
    paint(col, shadow * 0.55, PAL["seam"])
    tube = layer(arms(260), blur=1)
    paint(col, tube, PAL["steel"])
    # Tube highlight stripe and rim shade for a rounded look.
    hi = layer(arms(120), blur=18)
    col += (hi * tube * 34)[..., None]
    rim = np.clip(tube - layer(arms(220), blur=4), 0, 1)
    paint(col, rim * 0.7, PAL["steel_lo"])
    channel = layer(arms(120), blur=3)
    paint(col, channel, PAL["slime"] if flowing else PAL["empty"])
    if flowing:
        glow = layer(arms(60), blur=12)
        paint(col, glow * 0.8, (210, 255, 180))
    else:
        paint(col, layer(arms(40), blur=10) * 0.35, PAL["slime_dk"])
    # Bolted collar at the centre joint.
    collar = layer(lambda d: d.ellipse((cx - 150, cy - 150, cx + 150, cy + 150), fill=255), blur=3)
    paint(col, collar, PAL["steel_lo"])
    core = layer(lambda d: d.ellipse((cx - 110, cy - 110, cx + 110, cy + 110), fill=255), blur=3)
    paint(col, core, PAL["slime"] if flowing else PAL["empty"])
    for a in range(0, 360, 60):
        bx, by = cx + math.cos(math.radians(a)) * 130, cy + math.sin(math.radians(a)) * 130
        paint(col, layer(lambda d, bx=bx, by=by: d.ellipse((bx - 14, by - 14, bx + 14, by + 14), fill=255), blur=2), PAL["steel_hi"])
    alpha = (np.maximum(tile, tube) * 255).astype(np.uint8)
    im = Image.fromarray(np.clip(col, 0, 255).astype(np.uint8)).convert("RGBA")
    im.putalpha(Image.fromarray(alpha))
    im.resize((256, 256), Image.LANCZOS).save(f"pipe_{name}_{'on' if flowing else 'off'}.png")
    return im


def symbol(name, draw):
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    draw(d)
    im.resize((256, 256), Image.LANCZOS).save(f"sym_{name}.png")
    return im


def star_points(cx, cy, r1, r2, n=5):
    pts = []
    for i in range(n * 2):
        r = r1 if i % 2 == 0 else r2
        a = math.radians(-90 + i * 180 / n)
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts


W = (255, 255, 255, 255)
syms = {
    "circle": lambda d: d.ellipse((160, 160, S - 160, S - 160), fill=W),
    "square": lambda d: d.rounded_rectangle((180, 180, S - 180, S - 180), radius=70, fill=W),
    "triangle": lambda d: d.polygon([(S / 2, 150), (S - 140, S - 190), (140, S - 190)], fill=W),
    "star": lambda d: d.polygon(star_points(S / 2, S / 2 + 30, 400, 170), fill=W),
    "diamond": lambda d: d.polygon([(S / 2, 120), (S - 170, S / 2), (S / 2, S - 120), (170, S / 2)], fill=W),
    "heart": lambda d: (d.ellipse((150, 200, 530, 580), fill=W), d.ellipse((494, 200, 874, 580), fill=W), d.polygon([(165, 450), (S - 165, 450), (S / 2, 880)], fill=W)),
}

if __name__ == "__main__":
    tiles = []
    for name, dirs in SHAPES.items():
        for flowing in (False, True):
            tiles.append(pipe_tile(name, dirs, flowing))
    icons = [symbol(n, f) for n, f in syms.items()]
    cell = 200
    sheet = Image.new("RGBA", (cell * 6, cell * 3), (30, 24, 46, 255))
    for i, t in enumerate(tiles):
        sheet.alpha_composite(t.resize((cell, cell), Image.LANCZOS), ((i // 2) * cell, (i % 2) * cell))
    colours = [(107, 255, 61), (166, 107, 255), (61, 232, 255), (255, 150, 40), (255, 201, 60), (255, 90, 120)]
    for i, ic in enumerate(icons):
        tinted = Image.new("RGBA", ic.size, colours[i] + (255,))
        tinted.putalpha(ic.getchannel("A"))
        sheet.alpha_composite(tinted.resize((cell, cell), Image.LANCZOS), (i * cell, 2 * cell))
    sheet.convert("RGB").save("puzzle_preview.png")
    print("done")
