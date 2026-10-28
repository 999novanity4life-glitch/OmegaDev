"""Tileable PBR maps for the Moon ground (Terrain MaterialVariants and dust meshes).

Usage (from games/moon-mop):  python art/blender/regolith_tex.py
Writes art/textures/<name>_color.png, _normal.png, _roughness.png at 1024x1024
(Roblox's maximum for texture maps, https://create.roblox.com/docs/art/modeling/texture-specifications).
Normals are tangent space, OpenGL (+Y up), which is the only format Roblox reads.

Look target (walkthrough notes, docs section 2b): uncleaned dust is bright pale
lavender-white with lots of small dimples and speckles; cleaned ground is a smoother,
slightly darker grey-lavender. Everything is generated from noise; no image is copied.
"""
import os
import numpy as np
from PIL import Image

N = 1024
OUT = os.path.join(os.path.dirname(__file__), "..", "textures")
os.makedirs(OUT, exist_ok=True)


def periodic_noise(rng, beta=2.2, lo=2, hi=None):
    """Tileable, isotropic fractal noise by spectral synthesis: white noise shaped by
    1/f^beta in the frequency domain. FFT noise wraps on both axes by construction."""
    f = np.fft.fftfreq(N) * N
    fx, fy = np.meshgrid(f, f)
    k = np.sqrt(fx * fx + fy * fy)
    amp = np.where(k > 0, 1.0 / np.maximum(k, 1) ** (beta / 2), 0)
    amp[k < lo] = 0
    if hi:
        amp[k > hi] = 0
    spec = np.fft.fft2(rng.normal(size=(N, N))) * amp
    h = np.real(np.fft.ifft2(spec))
    return h / (np.abs(h).max() + 1e-9)


def craterlets(rng, count, rmin, rmax, depth):
    """Small bowl dimples with soft raised rims, wrapped so the map tiles."""
    h = np.zeros((N, N))
    y, x = np.mgrid[0:N, 0:N]
    for _ in range(count):
        cx, cy = rng.uniform(0, N, 2)
        r = rmin * (rmax / rmin) ** (rng.random() ** 2.2)  # power law: many tiny, few big
        fresh = rng.uniform(0.25, 1.0)  # older craterlets are softer
        dx = (x - cx + N / 2) % N - N / 2
        dy = (y - cy + N / 2) % N - N / 2
        d = np.sqrt(dx * dx + dy * dy) / r
        m = d < 1.6
        bowl = np.where(d < 1, -np.clip(1 - d * d, 0, None) ** 1.5, 0.0)
        rim = 0.25 * np.exp(-((d - 1.0) / 0.3) ** 2)
        h[m] += (depth * (r / rmax) ** 0.7 * fresh * (bowl + rim))[m]
    return h


def normal_map(h, strength):
    gx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5
    gy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5
    nx, ny, nz = -gx * strength, gy * strength, np.ones_like(h)  # OpenGL: green = +Y up the image
    ln = np.sqrt(nx * nx + ny * ny + nz * nz)
    n = np.stack([nx / ln, ny / ln, nz / ln], -1)
    return ((n * 0.5 + 0.5) * 255).astype(np.uint8)


def save(name, color, normal, rough):
    Image.fromarray(color).save(os.path.join(OUT, f"{name}_color.png"))
    Image.fromarray(normal).save(os.path.join(OUT, f"{name}_normal.png"))
    Image.fromarray(rough).save(os.path.join(OUT, f"{name}_roughness.png"))


def tint(base, shade, spec):
    c = np.clip(base[None, None, :] * shade[..., None] + spec[..., None], 0, 255)
    return c.astype(np.uint8)


def build(name, seed, base_rgb, dimples, dimple_depth, grain, normal_strength, rough_lo):
    rng = np.random.default_rng(seed)
    h = periodic_noise(rng, 2.6) * 1.2 + craterlets(rng, dimples, 3, 60, dimple_depth)
    h += periodic_noise(rng, 1.0, lo=120) * grain  # fine grain
    h += periodic_noise(rng, 2.0, lo=6, hi=60) * 0.15
    hn = (h - h.min()) / (h.max() - h.min())
    # Cavity darkening: dimple floors and grain pits read slightly darker.
    cav = h - (np.roll(h, 4, 0) + np.roll(h, -4, 0) + np.roll(h, 4, 1) + np.roll(h, -4, 1)) / 4
    albedo = periodic_noise(rng, 2.4) * 0.05  # soft patchy brightness, independent of height
    shade = 0.9 + 0.06 * hn + albedo + np.clip(cav * 3, -0.06, 0.03)
    speck = (rng.random((N, N)) > 0.985) * rng.uniform(-40, 25, (N, N))  # dark and bright grains
    color = tint(np.array(base_rgb, float), shade, speck)
    rough = np.clip(rough_lo + 0.1 * (1 - hn) + rng.normal(0, 0.02, (N, N)), 0, 1)
    save(name, color, normal_map(h, normal_strength), (rough * 255).astype(np.uint8))
    return color


if __name__ == "__main__":
    dusty = build("Regolith_Dusty", 7, (222, 218, 230), 160, 1.8, 0.06, 6.0, 0.86)
    clean = build("Regolith_Clean", 8, (170, 166, 182), 40, 0.5, 0.015, 3.0, 0.72)
    # Side-by-side preview, tiled 2x2 to show the seams are invisible.
    tile = lambda c: np.vstack([np.hstack([c, c]), np.hstack([c, c])])
    prev = np.hstack([tile(dusty)[::2, ::2], tile(clean)[::2, ::2]])
    Image.fromarray(prev).save(os.path.join(OUT, "preview_regolith.png"))
    print("wrote", sorted(os.listdir(OUT)))
