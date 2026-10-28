"""Moon Mop sky: navy space with a soft blue Milky-Way band and sparse stars (our own art, after the
look noted in docs section 2b: "pure black with a soft blue Milky-Way nebula band and sparse white
stars"), plus a small stylised Earth for Sky.MoonTextureId.

Usage:  python art/sky/make_sky.py [--test]
--test writes labelled faces (FT, BK, ...) with an UP arrow, to find Roblox's cube-face orientation.
Writes art/sky/out/sky_<face>.png (1024 px) and earth.png (512 px, transparent).
"""
import os
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
N = 1024
FACES = ["Ft", "Bk", "Lf", "Rt", "Up", "Dn"]


def test_faces():
    font = ImageFont.load_default(size=200)
    small = ImageFont.load_default(size=60)
    cols = {"Ft": (200, 60, 60), "Bk": (60, 200, 60), "Lf": (60, 60, 200), "Rt": (200, 200, 60), "Up": (200, 60, 200), "Dn": (60, 200, 200)}
    for f in FACES:
        im = Image.new("RGB", (N, N), cols[f])
        d = ImageDraw.Draw(im)
        d.text((N / 2, N / 2), f.upper(), font=font, fill="white", anchor="mm")
        d.polygon([(N / 2, 40), (N / 2 - 60, 140), (N / 2 + 60, 140)], fill="white")
        d.text((N / 2, 180), "UP", font=small, fill="white", anchor="mm")
        d.text((60, N / 2), "L", font=small, fill="white", anchor="mm")
        d.text((N - 60, N / 2), "R", font=small, fill="white", anchor="mm")
        im.save(os.path.join(OUT, f"test_{f}.png"))


def fbm3(p, octaves=5, seed=0):
    """Cheap value-noise fBm on 3D points (n,3) using hashed lattice + trilinear blend."""
    rng = np.random.default_rng(seed)
    perm = rng.permutation(256)
    vals = rng.random(256)

    def hash3(i, j, k):
        return vals[perm[(perm[(perm[i & 255] + j) & 255] + k) & 255]]

    total = np.zeros(len(p))
    amp, freq, norm = 1.0, 1.0, 0.0
    for _ in range(octaves):
        q = p * freq
        i0 = np.floor(q).astype(int)
        f = q - i0
        u = f * f * (3 - 2 * f)
        acc = 0
        for dx in (0, 1):
            for dy in (0, 1):
                for dz in (0, 1):
                    w = (u[:, 0] if dx else 1 - u[:, 0]) * (u[:, 1] if dy else 1 - u[:, 1]) * (u[:, 2] if dz else 1 - u[:, 2])
                    acc = acc + w * hash3(i0[:, 0] + dx, i0[:, 1] + dy, i0[:, 2] + dz)
        total += amp * acc
        norm += amp
        amp *= 0.5
        freq *= 2.0
    return total / norm


def face_dirs(face, basis):
    """basis[face] = (forward, right, up) world vectors for that face's centre, image-right, image-up."""
    fwd, right, up = (np.array(v, float) for v in basis[face])
    s = (np.arange(N) + 0.5) / N * 2 - 1
    xx, yy = np.meshgrid(s, -s)  # image x to the right, image y up
    d = fwd[None, None] + xx[..., None] * right[None, None] + yy[..., None] * up[None, None]
    return d / np.linalg.norm(d, axis=-1, keepdims=True)


def sky(basis):
    band_axis = np.array([0.35, 0.8, 0.48])
    band_axis /= np.linalg.norm(band_axis)
    for f in FACES:
        d = face_dirs(f, basis).reshape(-1, 3)
        lat = d @ band_axis  # 0 on the band's great circle
        band = np.exp(-(lat / 0.22) ** 2)
        n1 = fbm3(d * 3.0, 5, 1)
        n2 = fbm3(d * 9.0, 4, 2)
        neb = np.clip(band * (0.35 + 1.1 * (n1 - 0.35)) + 0.25 * band * (n2 - 0.5), 0, 1) ** 1.4
        base = np.array([6, 9, 24]) / 255.0
        navy = np.array([16, 26, 66]) / 255.0
        blue = np.array([70, 110, 200]) / 255.0
        lilac = np.array([120, 110, 190]) / 255.0
        glow = 0.5 + 0.5 * (n2 - 0.5)
        col = base + (navy - base) * np.clip(band * 1.2, 0, 1)[:, None]
        col = col + neb[:, None] * (blue * glow[:, None] + lilac * (1 - glow[:, None])) * 0.75
        img = np.clip(col, 0, 1).reshape(N, N, 3)
        # stars: sparse, a few bright with a soft halo, denser inside the band
        rng = np.random.default_rng(hash(f) % 2**32)
        dens = band.reshape(N, N)
        k = rng.random((N, N))
        thresh = 0.9987 - 0.0012 * dens
        ys, xs = np.nonzero(k > thresh)
        for y, x in zip(ys, xs):
            b = rng.uniform(0.45, 1.0)
            img[y, x] = np.maximum(img[y, x], b)
            if b > 0.93:
                for dy, dx in ((0, 1), (1, 0), (0, -1), (-1, 0)):
                    yy, xx2 = y + dy, x + dx
                    if 0 <= yy < N and 0 <= xx2 < N:
                        img[yy, xx2] = np.maximum(img[yy, xx2], b * 0.55)
        img = bake_earth(img, d.reshape(N, N, 3))
        Image.fromarray((img * 255).astype(np.uint8)).save(os.path.join(OUT, f"sky_{f}.png"))


# Earth is painted into the skybox, because Roblox's own moon always sits opposite the sun and
# would be below the horizon all day. EARTH_DIR is in front of the North Station spawn (-Z).
EARTH_DIR = np.array([0.3, 0.42, -0.86])
EARTH_RADIUS_DEG = 4.5


def bake_earth(img, d):
    e = EARTH_DIR / np.linalg.norm(EARTH_DIR)
    right = np.cross(e, [0, 1, 0])
    right /= np.linalg.norm(right)
    up = np.cross(right, e)
    t = np.tan(np.radians(EARTH_RADIUS_DEG))
    de = d @ e
    with np.errstate(divide="ignore", invalid="ignore"):
        u = (d @ right) / de / t
        v = (d @ up) / de / t
    hit = (de > 0) & (u * u + v * v < 1.05)
    if not hit.any():
        return img
    earth_rgba = np.asarray(Image.open(os.path.join(OUT, "earth.png")), float) / 255
    S = earth_rgba.shape[0]
    px = np.clip(((u + 1) / 2 * S).astype(int), 0, S - 1)
    py = np.clip(((1 - v) / 2 * S).astype(int), 0, S - 1)
    src = earth_rgba[py, px]
    a = np.where(hit, src[..., 3], 0)[..., None]
    return img * (1 - a) + src[..., :3] * a


def earth():
    S = 512
    s = (np.arange(S) + 0.5) / S * 2 - 1
    xx, yy = np.meshgrid(s, -s)
    r2 = xx ** 2 + yy ** 2
    inside = r2 < 1
    z = np.sqrt(np.clip(1 - r2, 0, 1))
    p = np.stack([xx, yy, z], -1).reshape(-1, 3)
    land = fbm3(p * 2.2 + 5, 5, 7).reshape(S, S)
    cloud = fbm3(p * 4.0 + 11, 5, 9).reshape(S, S)
    ocean = np.array([30, 80, 170]) / 255
    deep = np.array([14, 44, 120]) / 255
    green = np.array([70, 120, 60]) / 255
    brown = np.array([150, 120, 80]) / 255
    col = deep + (ocean - deep) * z[..., None]
    isl = land > 0.53
    lc = green + (brown - green) * np.clip((land - 0.53) * 6, 0, 1)[..., None]
    col = np.where(isl[..., None], lc, col)
    cl = np.clip((cloud - 0.55) * 3, 0, 0.85)[..., None]
    col = col * (1 - cl) + cl
    light = np.clip(0.25 + 0.85 * (p.reshape(S, S, 3) @ np.array([-0.5, 0.35, 0.79])), 0.08, 1)
    col = col * light[..., None]
    rim = np.clip((r2 - 0.85) / 0.15, 0, 1)[..., None] * np.array([0.35, 0.55, 1.0]) * 0.6
    col = np.clip(col + rim, 0, 1)
    alpha = np.clip((1 - np.sqrt(r2)) * S / 3, 0, 1)
    rgba = np.dstack([col, alpha])
    Image.fromarray((rgba * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "earth.png"))


# Roblox cube-face basis (forward, right, up), measured in Studio with the --test faces:
# SkyboxFt faces -Z, Bk +Z, Lf +X, Rt -X (all upright); Up and Dn are turned a quarter.
BASIS = {
    "Ft": ((0, 0, -1), (1, 0, 0), (0, 1, 0)),
    "Bk": ((0, 0, 1), (-1, 0, 0), (0, 1, 0)),
    "Lf": ((1, 0, 0), (0, 0, 1), (0, 1, 0)),
    "Rt": ((-1, 0, 0), (0, 0, -1), (0, 1, 0)),
    "Up": ((0, 1, 0), (0, 0, -1), (1, 0, 0)),
    "Dn": ((0, -1, 0), (0, 0, -1), (-1, 0, 0)),
}

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    if "--test" in sys.argv:
        test_faces()
    else:
        earth()
        sky(BASIS)
    print(sorted(os.listdir(OUT)))
