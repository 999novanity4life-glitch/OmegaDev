"""Slime Rise hand-designed material textures.

Every texture shares one palette and one light (top-left), is drawn as
height + colour layers, then gets baked stylized shading and a normal map.
Each tile is designed to repeat seamlessly. Output: <name>_color.png,
<name>_normal.png (512px) and preview.png (2x2 tiling of each).
"""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

N = 1024  # work size; saved at 512 for clean anti-aliasing

PAL = {
    "plum": (58, 45, 92), "plum_hi": (91, 74, 138), "plum_lo": (38, 28, 62), "seam": (24, 18, 40),
    "steel": (185, 192, 212), "steel_hi": (222, 228, 242), "steel_lo": (120, 128, 152), "steel_dk": (74, 80, 104),
    "slate": (62, 78, 110), "slate_hi": (96, 116, 158), "grout": (150, 168, 204),
    "slime": (107, 255, 61), "slime_dk": (46, 170, 40), "teal": (61, 232, 255), "hazard": (255, 201, 60),
}


def canvas():
    return np.zeros((N, N)), np.zeros((N, N, 3))


def mask(draw_fn, blur=0):
    im = Image.new("L", (N, N), 0)
    draw_fn(ImageDraw.Draw(im))
    if blur:
        im = im.filter(ImageFilter.GaussianBlur(blur))
    return np.asarray(im, dtype=np.float64) / 255.0


def paint(color_arr, m, rgb):
    c = np.array(rgb, dtype=np.float64)
    color_arr[:] = color_arr * (1 - m[..., None]) + c * m[..., None]


def rrect(box, r):
    return lambda d: d.rounded_rectangle(box, radius=r, fill=255)


def circle(cx, cy, r):
    return lambda d: d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=255)


def normals(height, strength):
    gy, gx = np.gradient(height)
    nx, ny, nz = -gx * strength, -gy * strength, np.ones_like(height)
    length = np.sqrt(nx ** 2 + ny ** 2 + nz ** 2)
    return nx / length, ny / length, nz / length


def finish(name, height, color, strength=60.0, shade=0.55):
    nx, ny, nz = normals(height, strength)
    # Stylized light from the top-left, baked softly into the colour.
    light = np.array([-0.5, -0.6, 0.62])
    light /= np.linalg.norm(light)
    lambert = np.clip(nx * light[0] + ny * light[1] + nz * light[2], 0, 1)
    flat = light[2]
    shaded = color * (1 + (lambert - flat) * shade)[..., None]
    out = Image.fromarray(np.clip(shaded, 0, 255).astype(np.uint8)).resize((512, 512), Image.LANCZOS)
    out.save(f"{name}_color.png")
    # Roblox normal maps: OpenGL style, +Y up (flip the image-space y).
    nmap = np.stack([(nx + 1) * 127.5, (-ny + 1) * 127.5, (nz + 1) * 127.5], axis=-1)
    Image.fromarray(np.clip(nmap, 0, 255).astype(np.uint8)).resize((512, 512), Image.LANCZOS).save(f"{name}_normal.png")
    return out


def bolt(height, color, cx, cy, r=18):
    m = mask(circle(cx, cy, r), blur=3)
    paint(color, m, PAL["steel"])
    height += m * 0.8
    inner = mask(lambda d: d.line((cx - r * 0.55, cy, cx + r * 0.55, cy), fill=255, width=max(3, r // 5)), blur=1)
    paint(color, inner * m, PAL["steel_dk"])
    height -= inner * m * 0.3


# 1. Wall panel: one tall panel module. Framed, recessed centre plate, a slime
#    status strip, a vent grille low down and four corner bolts.
def wall():
    h, c = canvas()
    c[:] = PAL["seam"]
    frame = mask(rrect((10, 10, N - 10, N - 10), 26), blur=6)
    paint(c, frame, PAL["plum_hi"])
    h += frame * 1.0
    inset = mask(rrect((70, 70, N - 70, N - 70), 18), blur=8)
    paint(c, inset, PAL["plum"])
    h -= inset * 0.45
    # Upper plate split line.
    split = mask(lambda d: d.line((70, 430, N - 70, 430), fill=255, width=8), blur=2)
    paint(c, split, PAL["plum_lo"])
    h -= split * 0.3
    # Slime status strip, a glowing slot.
    slot = mask(rrect((150, 360, N - 150, 396), 16), blur=2)
    paint(c, slot, PAL["seam"])
    h -= slot * 0.4
    glow = mask(rrect((166, 368, N - 166, 388), 10), blur=1)
    paint(c, glow, PAL["slime"])
    # Vent grille: six rounded slots.
    for i in range(6):
        y = 640 + i * 46
        v = mask(rrect((220, y, N - 220, y + 24), 12), blur=2)
        paint(c, v, PAL["seam"])
        h -= v * 0.5
    # Small label plate top-left of the inset.
    plate = mask(rrect((120, 130, 330, 200), 10), blur=2)
    paint(c, plate, PAL["steel_lo"])
    h += plate * 0.25
    for x in (150, 300):
        bolt(h, c, x, 165, 10)
    for x, y in ((40, 40), (N - 40, 40), (40, N - 40), (N - 40, N - 40)):
        bolt(h, c, x, y, 16)
    return finish("wall", h, c)


# 2. Floor grate: framed steel tile with a 4x4 grid of rounded holes that
#    glow faintly slime-green at the bottom.
def grate():
    h, c = canvas()
    c[:] = PAL["steel_dk"]
    frame = mask(rrect((8, 8, N - 8, N - 8), 20), blur=5)
    paint(c, frame, PAL["steel_lo"])
    h += frame
    cells, margin, gap = 4, 70, 26
    size = (N - 2 * margin - (cells - 1) * gap) / cells
    for i in range(cells):
        for j in range(cells):
            x0 = margin + i * (size + gap)
            y0 = margin + j * (size + gap)
            hole = mask(rrect((x0, y0, x0 + size, y0 + size), 22), blur=4)
            paint(c, hole, (18, 22, 30))
            h -= hole * 1.2
            glow = mask(rrect((x0 + 18, y0 + size * 0.55, x0 + size - 18, y0 + size - 14), 16), blur=14)
            paint(c, glow * 0.55, PAL["slime_dk"])
    for x, y in ((36, 36), (N - 36, 36), (36, N - 36), (N - 36, N - 36)):
        bolt(h, c, x, y, 14)
    return finish("grate", h, c, strength=50)


# 3. Steel plate: clean light plate, bevelled edge, rivet rows top and bottom,
#    one centre seam.
def steel():
    h, c = canvas()
    c[:] = PAL["steel_lo"]
    plate = mask(rrect((10, 10, N - 10, N - 10), 22), blur=7)
    paint(c, plate, PAL["steel"])
    h += plate
    # Gentle vertical sheen (smooth, not noisy).
    yy = np.linspace(0, 1, N)[:, None]
    sheen = (0.06 * np.cos(yy * np.pi * 2))[..., None] * 255
    c += sheen * plate[..., None]
    seam = mask(lambda d: d.line((10, N / 2, N - 10, N / 2), fill=255, width=10), blur=2)
    paint(c, seam, PAL["steel_lo"])
    h -= seam * 0.4
    for row in (70, N / 2 - 50, N / 2 + 50, N - 70):
        for k in range(7):
            bolt(h, c, 110 + k * (N - 220) / 6, row, 13)
    return finish("steel", h, c, strength=45)


# 4. Lab floor tile: 2x2 large slate tiles with lighter inset borders, light
#    grout and a soft gloss streak.
def tile():
    h, c = canvas()
    c[:] = PAL["grout"]
    half = N // 2
    for i in range(2):
        for j in range(2):
            x0, y0 = i * half, j * half
            t = mask(rrect((x0 + 10, y0 + 10, x0 + half - 10, y0 + half - 10), 20), blur=4)
            paint(c, t, PAL["slate_hi"])
            h += t
            inner = mask(rrect((x0 + 44, y0 + 44, x0 + half - 44, y0 + half - 44), 14), blur=5)
            paint(c, inner, PAL["slate"])
            h -= inner * 0.15
            gloss = mask(lambda d, x0=x0, y0=y0: d.polygon(
                [(x0 + 70, y0 + half - 120), (x0 + half - 120, y0 + 70), (x0 + half - 90, y0 + 70), (x0 + 70, y0 + half - 90)], fill=255), blur=10)
            c += (gloss * 22)[..., None]
    return finish("tile", h, c, strength=35)


# 5. Pad tread: light plate with staggered raised lozenges (diamond-plate,
#    stylized), lit tops.
def pad():
    h, c = canvas()
    c[:] = PAL["steel"]
    step = N / 6
    for row in range(7):
        for col in range(7):
            cx = col * step + (step / 2 if row % 2 else 0)
            cy = row * step
            for dx in (-N, 0, N):  # wrap so the tile repeats
                for dy in (-N, 0, N):
                    x, y = cx + dx, cy + dy
                    if -step < x < N + step and -step < y < N + step:
                        angle = 45 if (row + col) % 2 == 0 else -45
                        lz = Image.new("L", (N, N), 0)
                        d = ImageDraw.Draw(lz)
                        w, l = step * 0.16, step * 0.42
                        import math
                        a = math.radians(angle)
                        ca, sa = math.cos(a), math.sin(a)
                        pts = [(x + ca * l, y + sa * l), (x - sa * w, y + ca * w), (x - ca * l, y - sa * l), (x + sa * w, y - ca * w)]
                        d.polygon(pts, fill=255)
                        m = np.asarray(lz.filter(ImageFilter.GaussianBlur(6)), dtype=np.float64) / 255.0
                        paint(c, m, PAL["steel_hi"])
                        h += m * 0.7
    return finish("pad", h, c, strength=55)


if __name__ == "__main__":
    outs = [("Wall panel", wall()), ("Floor grate", grate()), ("Steel plate", steel()), ("Lab tile", tile()), ("Pad tread", pad())]
    cell = 300
    sheet = Image.new("RGB", (cell * len(outs) + 20 * (len(outs) + 1), cell + 40), (20, 18, 30))
    for i, (_, im) in enumerate(outs):
        tiled = Image.new("RGB", (1024, 1024))
        for x in (0, 512):
            for y in (0, 512):
                tiled.paste(im, (x, y))
        sheet.paste(tiled.resize((cell, cell), Image.LANCZOS), (20 + i * (cell + 20), 20))
    sheet.save("preview.png")
    print("done")
