"""Slime Rise texture library v2: surface-specific variants in the same style.

Same palette, same top-left light, same bevel language as textures.py.
Each surface gets its own designed variants so no two neighbouring
surfaces read as the same texture. Also draws transparent overlay decals.
"""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from textures import N, PAL, canvas, mask, paint, rrect, circle, finish, bolt

FONT_PATHS = ["C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/segoeuib.ttf"]


def font(size):
    for p in FONT_PATHS:
        try:
            return ImageFont.truetype(p, size)
        except OSError:
            pass
    return ImageFont.load_default()


def panel_base(h, c, inset_box=(70, 70, N - 70, N - 70), bolts=True):
    """The shared wall frame every wall variant starts from (keeps them a family)."""
    c[:] = PAL["seam"]
    frame = mask(rrect((10, 10, N - 10, N - 10), 26), blur=6)
    paint(c, frame, PAL["plum_hi"])
    h += frame
    inset = mask(rrect(inset_box, 18), blur=8)
    paint(c, inset, PAL["plum"])
    h -= inset * 0.45
    if bolts:
        for x, y in ((40, 40), (N - 40, 40), (40, N - 40), (N - 40, N - 40)):
            bolt(h, c, x, y, 16)


def stencil(h, c, text, x, y, size, rgb, depth=0.05):
    m = mask(lambda d: d.text((x, y), text, font=font(size), fill=255, anchor="mm"), blur=1)
    paint(c, m, rgb)
    h -= m * depth


# --- Walls -----------------------------------------------------------------

def wall_plain():
    """Calm panel: the 'rest' surface (most of the wall)."""
    h, c = canvas()
    panel_base(h, c)
    for y in (330, 690):
        s = mask(lambda d, y=y: d.line((70, y, N - 70, y), fill=255, width=8), blur=2)
        paint(c, s, PAL["plum_lo"])
        h -= s * 0.3
    return finish("wall_plain", h, c)


def wall_vent():
    """Big intake grille with a fan hub showing through."""
    h, c = canvas()
    panel_base(h, c)
    box = (170, 170, N - 170, N - 170)
    housing = mask(rrect(box, 30), blur=5)
    paint(c, housing, PAL["steel_lo"])
    h += housing * 0.4
    hole = mask(rrect((200, 200, N - 200, N - 200), 22), blur=4)
    paint(c, hole, (16, 14, 26))
    h -= hole
    hub = mask(circle(N / 2, N / 2, 150), blur=3)
    paint(c, hub * 0.6, (40, 36, 60))
    for i in range(10):
        y = 230 + i * 58
        slat = mask(rrect((210, y, N - 210, y + 22), 10), blur=3)
        paint(c, slat, PAL["steel"])
        h += slat * 0.9
    stencil(h, c, "AIR", N / 2, 120, 64, PAL["steel_hi"])
    return finish("wall_vent", h, c)


def wall_hatch():
    """Access hatch: inset door, handle, hazard chevrons, bay number."""
    h, c = canvas()
    panel_base(h, c)
    door = mask(rrect((180, 150, N - 180, N - 110), 28), blur=6)
    paint(c, door, PAL["plum_hi"])
    h += door * 0.6
    seam = mask(rrect((196, 166, N - 196, N - 126), 22), blur=1)
    inner = mask(rrect((206, 176, N - 206, N - 136), 18), blur=1)
    paint(c, np.clip(seam - inner, 0, 1), PAL["seam"])
    handle = mask(rrect((N - 300, 520, N - 240, 680), 20), blur=3)
    paint(c, handle, PAL["steel"])
    h += handle
    # Hazard chevrons along the bottom.
    for i in range(6):
        x = 220 + i * 100
        chev = mask(lambda d, x=x: d.polygon([(x, N - 230), (x + 50, N - 230), (x + 90, N - 180), (x + 40, N - 180)], fill=255), blur=1)
        paint(c, chev, PAL["hazard"])
    stencil(h, c, "B-07", N / 2, 300, 120, PAL["steel_hi"])
    return finish("wall_hatch", h, c)


def wall_pipeport():
    """Round pipe pass-through with flange bolts and a flow arrow."""
    h, c = canvas()
    panel_base(h, c)
    cx, cy = N / 2, N / 2 - 40
    flange = mask(circle(cx, cy, 230), blur=5)
    paint(c, flange, PAL["steel_lo"])
    h += flange * 0.6
    pipe = mask(circle(cx, cy, 160), blur=8)
    paint(c, pipe, PAL["slime_dk"])
    h += pipe * 1.2
    core = mask(circle(cx - 30, cy - 30, 80), blur=30)
    paint(c, core * 0.8, PAL["slime"])
    for k in range(8):
        a = k * math.pi / 4
        bolt(h, c, cx + math.cos(a) * 198, cy + math.sin(a) * 198, 14)
    arrow = mask(lambda d: d.polygon([(300, 860), (620, 860), (620, 820), (720, 890), (620, 960), (620, 920), (300, 920)], fill=255), blur=1)
    paint(c, arrow, PAL["slime"])
    return finish("wall_pipeport", h, c)


def wall_window():
    """Observation window: thick frame, dark glass, slime glowing behind."""
    h, c = canvas()
    panel_base(h, c)
    frame = mask(rrect((140, 160, N - 140, N - 260), 40), blur=6)
    paint(c, frame, PAL["steel_lo"])
    h += frame * 0.8
    glass = mask(rrect((180, 200, N - 180, N - 300), 30), blur=3)
    paint(c, glass, (22, 40, 40))
    h -= glass * 0.6
    yy = np.linspace(0, 1, N)[:, None] * np.ones((1, N))
    glow = np.clip((yy - 0.45) * 2.2, 0, 1) * glass
    paint(c, glow, PAL["slime_dk"])
    bubbles = [(330, 560, 26), (620, 600, 18), (470, 520, 14), (700, 520, 22), (260, 640, 12)]
    for x, y, r in bubbles:
        paint(c, mask(circle(x, y, r), blur=2) * glass, (170, 255, 140))
    shine = mask(lambda d: d.polygon([(230, 230), (380, 230), (240, 440), (200, 440)], fill=255), blur=6)
    c += (shine * glass * 40)[..., None]
    stencil(h, c, "SPECIMEN 7", N / 2, N - 170, 64, PAL["steel_hi"])
    return finish("wall_window", h, c)


def wall_control():
    """Control panel: screen, two gauges, button row."""
    h, c = canvas()
    panel_base(h, c)
    box = mask(rrect((150, 180, N - 150, N - 180), 30), blur=5)
    paint(c, box, PAL["steel_dk"])
    h += box * 0.5
    screen = mask(rrect((210, 240, N - 210, 470), 18), blur=2)
    paint(c, screen, (14, 40, 30))
    for i in range(5):
        y = 280 + i * 36
        line = mask(rrect((240, y, 240 + (420 - i * 50), y + 14), 7), blur=1)
        paint(c, line, PAL["slime"])
    for gx in (340, N - 340):
        g = mask(circle(gx, 600, 90), blur=3)
        paint(c, g, PAL["steel"])
        h += g * 0.6
        face = mask(circle(gx, 600, 70), blur=1)
        paint(c, face, (240, 244, 255))
        needle = mask(lambda d, gx=gx: d.line((gx, 600, gx + 40, 550), fill=255, width=8), blur=1)
        paint(c, needle, (230, 60, 70))
    colours = [PAL["slime"], PAL["hazard"], PAL["teal"], (230, 60, 70)]
    for i, col in enumerate(colours):
        b = mask(circle(270 + i * 160, 770, 34), blur=3)
        paint(c, b, col)
        h += b * 0.7
    return finish("wall_control", h, c)


def wall_base():
    """Lower wall band: darker kick plate with a hazard stripe (three-band wall)."""
    h, c = canvas()
    c[:] = PAL["seam"]
    plate = mask(rrect((8, 8, N - 8, N - 8), 16), blur=5)
    paint(c, plate, PAL["plum_lo"])
    h += plate
    band = mask(lambda d: d.rectangle((8, 120, N - 8, 260), fill=255), blur=2)
    stripes = np.zeros((N, N))
    xx, yy = np.meshgrid(np.arange(N), np.arange(N))
    stripes = (((xx + yy) % 160) < 80).astype(float)
    paint(c, band * stripes, PAL["hazard"])
    paint(c, band * (1 - stripes), PAL["seam"])
    h += band * 0.3
    for k in range(6):
        bolt(h, c, 90 + k * (N - 180) / 5, 60, 12)
        bolt(h, c, 90 + k * (N - 180) / 5, N - 60, 12)
    return finish("wall_base", h, c)


# --- Floors ----------------------------------------------------------------

def floor_drain():
    """Steel floor plate with a round slotted drain and slime residue."""
    h, c = canvas()
    c[:] = PAL["steel_lo"]
    plate = mask(rrect((8, 8, N - 8, N - 8), 20), blur=6)
    paint(c, plate, PAL["steel"])
    h += plate
    ring = mask(circle(N / 2, N / 2, 250), blur=4)
    paint(c, ring, PAL["steel_lo"])
    h -= ring * 0.3
    hole = mask(circle(N / 2, N / 2, 200), blur=3)
    paint(c, hole, (20, 24, 32))
    h -= hole
    for i in range(7):
        y = N / 2 - 150 + i * 50
        s = mask(rrect((N / 2 - 170, y - 10, N / 2 + 170, y + 10), 10), blur=2)
        paint(c, s * hole, PAL["steel"])
        h += s * hole * 0.9
    goo = mask(lambda d: d.ellipse((N / 2 - 120, N / 2 + 60, N / 2 + 160, N / 2 + 200), fill=255), blur=20)
    paint(c, goo * 0.6, PAL["slime_dk"])
    for x, y in ((50, 50), (N - 50, 50), (50, N - 50), (N - 50, N - 50)):
        bolt(h, c, x, y, 14)
    return finish("floor_drain", h, c, strength=50)


def floor_walkway():
    """Safe-path walkway plate: tread texture with a white dashed centre line."""
    h, c = canvas()
    c[:] = PAL["slate"]
    plate = mask(rrect((8, 8, N - 8, N - 8), 18), blur=6)
    paint(c, plate, PAL["slate_hi"])
    h += plate
    for i in range(4):
        y = 80 + i * 256
        dash = mask(rrect((N / 2 - 30, y, N / 2 + 30, y + 150), 20), blur=2)
        paint(c, dash, (236, 240, 250))
        h += dash * 0.2
    for side in (90, N - 90):
        edge = mask(lambda d, s=side: d.line((s, 8, s, N - 8), fill=255, width=14), blur=2)
        paint(c, edge, PAL["slate"])
        h -= edge * 0.3
    return finish("floor_walkway", h, c, strength=40)


def floor_edge():
    """Edge plate: grate field with a hazard border along one side (for drops)."""
    h, c = canvas()
    c[:] = PAL["steel_dk"]
    plate = mask(rrect((8, 8, N - 8, N - 8), 18), blur=5)
    paint(c, plate, PAL["steel_lo"])
    h += plate
    xx, yy = np.meshgrid(np.arange(N), np.arange(N))
    stripes = (((xx + yy) % 160) < 80).astype(float)
    band = mask(lambda d: d.rectangle((8, 8, N - 8, 200), fill=255), blur=2)
    paint(c, band * stripes, PAL["hazard"])
    paint(c, band * (1 - stripes), PAL["seam"])
    h += band * 0.25
    for i in range(3):
        for j in range(4):
            x0, y0 = 90 + j * 220, 280 + i * 230
            hole = mask(rrect((x0, y0, x0 + 180, y0 + 180), 20), blur=4)
            paint(c, hole, (18, 22, 30))
            h -= hole
    return finish("floor_edge", h, c, strength=50)


def tile_emblem():
    """Lobby centre tile: the slime-drop lab emblem inlaid in the floor."""
    h, c = canvas()
    c[:] = PAL["grout"]
    t = mask(rrect((10, 10, N - 10, N - 10), 24), blur=4)
    paint(c, t, PAL["slate_hi"])
    h += t
    ring = mask(circle(N / 2, N / 2, 380), blur=3)
    inner = mask(circle(N / 2, N / 2, 340), blur=3)
    paint(c, np.clip(ring - inner, 0, 1), PAL["hazard"])
    paint(c, inner, PAL["slate"])
    # The blob mascot silhouette: domed body with a curl and a dripping base.
    def blob(d):
        d.ellipse((N / 2 - 210, 380, N / 2 + 210, 720), fill=255)
        d.rectangle((N / 2 - 210, 550, N / 2 + 210, 690), fill=255)
        d.ellipse((N / 2 - 40, 300, N / 2 + 50, 420), fill=255)
        for x in (-150, -40, 80, 170):
            d.ellipse((N / 2 + x - 45, 640, N / 2 + x + 45, 750), fill=255)
    drop = mask(blob, blur=3)
    paint(c, drop, PAL["slime"])
    h += drop * 0.5
    hi = mask(lambda d: d.ellipse((N / 2 - 150, 420, N / 2 - 60, 520), fill=255), blur=8)
    paint(c, hi * 0.7, (220, 255, 200))
    for x, y in ((N / 2 - 55, 560), (N / 2 + 55, 560)):
        paint(c, mask(circle(x, y, 26), blur=2), PAL["seam"])
    return finish("tile_emblem", h, c, strength=35)


# --- Ceiling and trim ------------------------------------------------------

def ceiling_light():
    """Ceiling panel with a recessed light box."""
    h, c = canvas()
    c[:] = PAL["seam"]
    plate = mask(rrect((10, 10, N - 10, N - 10), 20), blur=6)
    paint(c, plate, (60, 58, 84))
    h += plate
    box = mask(rrect((200, 360, N - 200, N - 360), 30), blur=5)
    paint(c, box, PAL["steel_lo"])
    h -= box * 0.3
    lamp = mask(rrect((230, 390, N - 230, N - 390), 24), blur=6)
    paint(c, lamp, (236, 246, 255))
    for x, y in ((40, 40), (N - 40, 40), (40, N - 40), (N - 40, N - 40)):
        bolt(h, c, x, y, 14)
    return finish("ceiling_light", h, c, strength=40)


def trim_strip():
    """Horizontal trim: bevelled strip, bolt row and a slime light line."""
    h, c = canvas()
    c[:] = PAL["steel_dk"]
    for y0, y1, col in ((20, 330, PAL["steel"]), (360, 560, PAL["steel_lo"]), (600, N - 20, PAL["steel"])):
        s = mask(rrect((10, y0, N - 10, y1), 14), blur=5)
        paint(c, s, col)
        h += s
    light = mask(rrect((10, 440, N - 10, 480), 18), blur=2)
    paint(c, light, PAL["slime"])
    for k in range(8):
        bolt(h, c, 64 + k * (N - 128) / 7, 175, 14)
        bolt(h, c, 64 + k * (N - 128) / 7, 790, 14)
    return finish("trim_strip", h, c, strength=45)


# --- Decals (RGBA overlays) ------------------------------------------------

def decal(name, draw, blur=0, size=512):
    im = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    draw(ImageDraw.Draw(im))
    if blur:
        im = im.filter(ImageFilter.GaussianBlur(blur))
    im.resize((size, size), Image.LANCZOS).save(f"decal_{name}.png")
    return im


def decals():
    out = []
    # Level stencils (white, so Color3 can tint them).
    for n in range(1, 5):
        out.append(decal(f"level{n}", lambda d, n=n: d.text((N / 2, N / 2), f"LV{n}", font=font(420), fill=(255, 255, 255, 235), anchor="mm")))
    out.append(decal("arrow", lambda d: d.polygon([(N / 2, 120), (880, 520), (650, 520), (650, 900), (374, 900), (374, 520), (144, 520)], fill=(255, 255, 255, 235))))
    def drip(d):
        d.rounded_rectangle((60, 40, N - 60, 220), radius=90, fill=(107, 255, 61, 230))
        for x, length, w in ((170, 520, 70), (330, 760, 90), (520, 420, 60), (700, 660, 80), (860, 360, 55)):
            d.rounded_rectangle((x - w / 2, 120, x + w / 2, 120 + length), radius=w / 2, fill=(107, 255, 61, 230))
            d.ellipse((x - w * 0.75, 120 + length - w, x + w * 0.75, 120 + length + w * 0.5), fill=(107, 255, 61, 230))
    out.append(decal("drip", drip))
    def puddle(d):
        d.ellipse((120, 300, 900, 760), fill=(70, 210, 50, 220))
        d.ellipse((60, 520, 360, 760), fill=(70, 210, 50, 220))
        d.ellipse((640, 220, 940, 470), fill=(70, 210, 50, 220))
        d.ellipse((260, 360, 520, 470), fill=(190, 255, 160, 200))
        for x, y, r in ((180, 220, 40), (900, 760, 34), (520, 860, 28)):
            d.ellipse((x - r, y - r, x + r, y + r), fill=(70, 210, 50, 220))
    out.append(decal("puddle", puddle))
    def warning(d):
        d.rounded_rectangle((120, 140, 904, 880), radius=60, fill=(30, 22, 44, 255))
        d.polygon([(N / 2, 210), (840, 810), (184, 810)], fill=(255, 201, 60, 255))
        d.rounded_rectangle((N / 2 - 30, 430, N / 2 + 30, 620), radius=30, fill=(30, 22, 44, 255))
        d.ellipse((N / 2 - 34, 650, N / 2 + 34, 718), fill=(30, 22, 44, 255))
    out.append(decal("warning", warning))
    # Soft contact shadow for wall bases (fake AO), black to transparent upward.
    ao = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    a = np.zeros((N, N, 4), dtype=np.uint8)
    yy = np.linspace(0, 1, N)
    a[..., 3] = (np.clip(yy * 1.2 - 0.2, 0, 1) ** 2.2 * 170).astype(np.uint8)[:, None]
    ao = Image.fromarray(a, "RGBA")
    ao.resize((256, 256), Image.LANCZOS).save("decal_ao.png")
    out.append(ao)
    return out


if __name__ == "__main__":
    surfaces = [
        ("Wall: plain", wall_plain()), ("Wall: vent", wall_vent()), ("Wall: hatch", wall_hatch()),
        ("Wall: pipe port", wall_pipeport()), ("Wall: window", wall_window()), ("Wall: control", wall_control()),
        ("Wall: base band", wall_base()), ("Floor: drain", floor_drain()), ("Floor: walkway", floor_walkway()),
        ("Floor: edge", floor_edge()), ("Tile: emblem", tile_emblem()), ("Ceiling light", ceiling_light()),
        ("Trim strip", trim_strip()),
    ]
    ds = decals()
    cell, pad = 240, 16
    cols = 5
    rows = math.ceil(len(surfaces) / cols) + 2
    sheet = Image.new("RGB", (cols * (cell + pad) + pad, rows * (cell + pad) + pad), (20, 18, 30))
    for i, (_, im) in enumerate(surfaces):
        sheet.paste(im.resize((cell, cell), Image.LANCZOS), (pad + (i % cols) * (cell + pad), pad + (i // cols) * (cell + pad)))
    base_row = math.ceil(len(surfaces) / cols)
    for i, im in enumerate(ds):
        bg = Image.new("RGBA", (N, N), (90, 74, 138, 255))
        bg.alpha_composite(im)
        sheet.paste(bg.convert("RGB").resize((cell, cell), Image.LANCZOS), (pad + (i % cols) * (cell + pad), pad + (base_row + i // cols) * (cell + pad)))
    sheet.save("preview2.png")
    print("done", len(surfaces), "surfaces,", len(ds), "decals")
