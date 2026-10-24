"""Stylized slime particle textures (white/greyscale + alpha so ParticleEmitter.Color tints them).
bubble_flip: 2x2 OneShot  - bubble, wobble, wobble, pop burst
goo_flip:    2x2 Loop     - lumpy goo blob wobbling
drip:        single       - teardrop (round end = leading edge, top of texture)
streak:      single       - soft air streak for updrafts
Drawn at 4x and downsampled for clean anti-aliased edges."""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SS = 4
CELL = 256

def cell():
    return Image.new("RGBA", (CELL * SS, CELL * SS), (255, 255, 255, 0))

def down(im):
    return im.resize((CELL, CELL), Image.LANCZOS)

def ellipse(d, cx, cy, rx, ry, fill):
    d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=fill)

def bubble(squash=0.0):
    im = cell(); d = ImageDraw.Draw(im)
    S = CELL * SS; c = S / 2
    r = S * 0.38
    rx, ry = r * (1 + squash), r * (1 - squash)
    # body: faint fill that thickens toward the rim (reads as a sphere)
    for i in range(40, 0, -1):
        f = i / 40
        a = int(70 + 100 * (f ** 3))
        ellipse(d, c, c, rx * f, ry * f, (225, 245, 230, a))
    # crisp rim with a darker toon outline outside it, so the bubble reads on
    # bright slime as well as on dark walls
    w = r * 0.075
    o = r * 0.05
    d.ellipse((c - rx - o, c - ry - o, c + rx + o, c + ry + o), outline=(95, 110, 100, 235), width=int(o * 1.4))
    d.ellipse((c - rx, c - ry, c + rx, c + ry), outline=(255, 255, 255, 250), width=int(w))
    # inner shade line on the lower right for depth
    d.arc((c - rx + w * 1.6, c - ry + w * 1.6, c + rx - w * 1.6, c + ry - w * 1.6), 10, 100, fill=(200, 220, 205, 150), width=int(w * 0.55))
    # cel highlight: crescent + dot, upper left
    hl = Image.new("L", im.size, 0); hd = ImageDraw.Draw(hl)
    ellipse(hd, c - rx * 0.30, c - ry * 0.36, rx * 0.36, ry * 0.20, 255)
    ellipse(hd, c - rx * 0.20, c - ry * 0.24, rx * 0.36, ry * 0.20, 0)
    ellipse(hd, c + rx * 0.08, c - ry * 0.55, rx * 0.075, ry * 0.075, 255)
    white = Image.new("RGBA", im.size, (255, 255, 255, 255))
    im = Image.composite(white, im, hl)
    return down(im)

def pop():
    im = cell(); d = ImageDraw.Draw(im)
    S = CELL * SS; c = S / 2
    r = S * 0.36
    w = int(r * 0.09)
    # broken ring
    for k in range(6):
        a0 = k * 60 + 8
        d.arc((c - r - w * 0.6, c - r - w * 0.6, c + r + w * 0.6, c + r + w * 0.6), a0, a0 + 34, fill=(95, 110, 100, 220), width=int(w * 1.9))
        d.arc((c - r, c - r, c + r, c + r), a0, a0 + 34, fill=(255, 255, 255, 240), width=w)
    # droplets flying out
    for k in range(6):
        a = math.radians(k * 60 + 30)
        x, y = c + math.cos(a) * r * 1.18, c + math.sin(a) * r * 1.18
        ellipse(d, x, y, r * 0.09, r * 0.09, (255, 255, 255, 240))
    return down(im)

def goo(phase):
    S = CELL * SS; c = S / 2
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    dx, dy = xx - c, yy - c
    ang = np.arctan2(dy, dx)
    rad = np.hypot(dx, dy)
    base = S * 0.36
    edge = base * (1 + 0.07 * np.sin(3 * ang + phase) + 0.045 * np.sin(5 * ang - phase * 1.7) + 0.03 * np.sin(2 * ang + phase * 0.6))
    inside = rad < edge
    # shading: light from upper left, darker toward lower right and the rim
    lx, ly = -0.6, -0.8
    n = (dx * lx + dy * ly) / (edge + 1e-6)
    shade = 0.78 + 0.22 * np.clip(n, -1, 1)
    rim = np.clip((rad / edge - 0.82) / 0.18, 0, 1)
    shade = shade - 0.12 * rim
    val = np.clip(shade * 255, 0, 255)
    alpha = np.where(inside, 255, 0).astype(np.float32)
    # rim light on the shadow side (classic toon goo)
    rimlight = inside & (rad > edge * 0.93) & (n < -0.45)
    val = np.where(rimlight, 232, val)
    rgba = np.zeros((S, S, 4), np.uint8)
    rgba[..., 0] = val; rgba[..., 1] = val; rgba[..., 2] = val; rgba[..., 3] = alpha
    im = Image.fromarray(rgba, "RGBA")
    d = ImageDraw.Draw(im)
    hx = c - base * 0.32 + math.sin(phase) * base * 0.03
    hy = c - base * 0.36
    ellipse(d, hx, hy, base * 0.24, base * 0.13, (255, 255, 255, 255))
    ellipse(d, c + base * 0.05, c - base * 0.58, base * 0.06, base * 0.06, (255, 255, 255, 255))
    return down(im)

def drip():
    # Classic teardrop: x = sin t * sin(t/2), y = cos t; point trails at the bottom
    # (with VelocityParallel the texture top leads, so the round end falls first).
    S = CELL * SS; c = S / 2
    a = S * 0.26
    pts = []
    for k in range(361):
        t = math.radians(k)
        x = math.sin(t) * math.sin(t / 2) ** 1.0
        y = math.cos(t)
        pts.append((c + x * a, c - y * a * 1.55 * -1))
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    n = ((xx - c) * -0.6 + (yy - c) * -0.8) / a
    val = np.clip((0.8 + 0.2 * np.clip(n, -1, 1)) * 255, 0, 255).astype(np.uint8)
    rgba = np.zeros((S, S, 4), np.uint8)
    rgba[..., 0] = val; rgba[..., 1] = val; rgba[..., 2] = val; rgba[..., 3] = np.array(mask)
    im = Image.fromarray(rgba, "RGBA")
    d = ImageDraw.Draw(im)
    # the round part is at the top; highlight on its upper left
    ellipse(d, c - a * 0.33, c - a * 0.85, a * 0.2, a * 0.32, (255, 255, 255, 255))
    return down(im)

def streak():
    S = CELL * SS; c = S / 2
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    w = S * 0.06
    across = np.exp(-((xx - c) / w) ** 2)
    along = np.clip(1 - np.abs((yy - c) / (S * 0.46)), 0, 1) ** 1.2
    a = (across * along * 255).astype(np.uint8)
    rgba = np.zeros((S, S, 4), np.uint8); rgba[..., :3] = 255; rgba[..., 3] = a
    return down(Image.fromarray(rgba, "RGBA"))

def mote():
    # Soft glowing dust mote: bright core, smooth falloff (for light shafts).
    S = CELL * SS; c = S / 2
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    r = np.hypot(xx - c, yy - c) / (S * 0.5)
    a = np.clip(1 - r, 0, 1) ** 2.2
    core = np.clip(1 - r / 0.18, 0, 1)
    alpha = np.clip(a * 0.85 + core * 0.6, 0, 1)
    rgba = np.zeros((S, S, 4), np.uint8); rgba[..., :3] = 255; rgba[..., 3] = (alpha * 255).astype(np.uint8)
    return down(Image.fromarray(rgba, "RGBA"))

def sheet(frames):
    out = Image.new("RGBA", (CELL * 2, CELL * 2), (255, 255, 255, 0))
    for i, f in enumerate(frames):
        out.paste(f, ((i % 2) * CELL, (i // 2) * CELL))
    return out

def upscale(im, n):
    return im.resize((im.width * n // im.width * im.width // im.width if False else n, n), Image.LANCZOS)

if __name__ == "__main__":
    sheet([bubble(0), bubble(0.06), bubble(-0.05), pop()]).save("bubble_flip.png")
    sheet([goo(p) for p in (0, 1.6, 3.2, 4.8)]).save("goo_flip.png")
    drip().save("drip.png")
    streak().save("streak.png")
    mote().save("mote.png")
    # preview on dark lab background, tinted slime green
    names = ["bubble_flip.png", "goo_flip.png", "drip.png", "streak.png"]
    prev = Image.new("RGB", (4 * 300 + 50, 330), (24, 20, 38))
    prev.paste((200, 235, 190), (620, 0, 1250, 330))
    for i, n in enumerate(names):
        im = Image.open(n).convert("RGBA").resize((280, 280), Image.LANCZOS)
        arr = np.array(im).astype(np.float32)
        tint = np.array([120, 255, 90], np.float32) / 255
        arr[..., :3] *= tint
        prev.paste(Image.fromarray(arr.astype(np.uint8), "RGBA"), (20 + i * 300, 20), Image.fromarray(arr.astype(np.uint8), "RGBA"))
    prev.save("preview.png")
    print("ok")
