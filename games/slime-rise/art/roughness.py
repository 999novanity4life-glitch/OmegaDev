"""Roughness maps for the Slime Rise MaterialVariants.

Without a RoughnessMap every variant renders as one uniform glossy plastic,
which under LightingStyle Realistic turns the floor into a mirror of the
ceiling lamps. Each map here is derived from the material's own normal and
colour maps so it lines up with the painted detail:
  - a per-surface base value (tile semi-gloss, painted wall satin, ceiling matte),
  - bevels and seams rougher (where the normal tilts away from flat),
  - dark grout/gaps rougher still, bright lit glass smoother,
  - a faint tileable smudge so big floors don't reflect as one flat sheet.
Black = smooth, white = rough (Roblox convention). Output 512x512, tileable.

Run: python roughness.py <mats_dir>   (reads <name>_normal.png / _color.png)
"""
import math
import sys

import numpy as np
from PIL import Image

N = 512

# variant -> (source file stem, base roughness, smudge amount)
MATERIALS = {
    "SR_Tile": ("tile", 0.42, 0.07),
    "SR_Emblem": ("tile_emblem", 0.40, 0.05),
    "SR_Walkway": ("floor_walkway", 0.58, 0.07),
    "SR_FloorEdge": ("floor_edge", 0.55, 0.06),
    "SR_FloorDrain": ("floor_drain", 0.55, 0.06),
    "SR_Grate": ("floor_plates", 0.50, 0.07),
    "SR_Pad": ("pad", 0.48, 0.05),
    "SR_Steel": ("steel", 0.38, 0.06),
    "SR_Trim": ("trim_strip", 0.40, 0.04),
    "SR_Panel": ("wall", 0.55, 0.05),
    "SR_WallPlain": ("wall_plain", 0.55, 0.05),
    "SR_WallVent": ("wall_vent", 0.58, 0.05),
    "SR_WallHatch": ("wall_hatch", 0.55, 0.05),
    "SR_WallPipe": ("wall_pipeport", 0.55, 0.05),
    "SR_WallWindow": ("wall_window", 0.50, 0.04),
    "SR_WallControl": ("wall_control", 0.50, 0.04),
    "SR_WallBase": ("wall_base", 0.60, 0.05),
    "SR_Ceiling": ("ceiling_light", 0.72, 0.04),
}


def load(path, mode):
    im = Image.open(path).convert(mode)
    if im.size != (N, N):
        im = im.resize((N, N), Image.LANCZOS)
    return np.asarray(im).astype(np.float32) / 255.0


def smudge(seed):
    """Low-frequency noise built from integer-frequency waves: tiles seamlessly."""
    rng = np.random.default_rng(seed)
    y, x = np.mgrid[0:N, 0:N] / N * 2 * math.pi
    out = np.zeros((N, N), np.float32)
    for _ in range(10):
        fx, fy = rng.integers(1, 5, size=2)
        phase = rng.uniform(0, 2 * math.pi)
        out += np.sin(fx * x + fy * y + phase) * rng.uniform(0.5, 1.0)
    out -= out.min()
    return out / max(out.max(), 1e-6) * 2 - 1  # -1..1


def roughness(stem, base, smear, mats, seed):
    normal = load(f"{mats}/{stem}_normal.png", "RGB")
    color = load(f"{mats}/{stem}_color.png", "RGB")
    nz = normal[..., 2] * 2 - 1  # 1 = facing straight out
    edge = np.clip((1 - nz) / 0.35, 0, 1)  # bevels and seams
    lum = color @ np.array([0.299, 0.587, 0.114], np.float32)
    dark = np.clip((0.22 - lum) / 0.22, 0, 1)  # grout, gaps, shadows
    bright = np.clip((lum - 0.85) / 0.15, 0, 1)  # lamps, glass highlights
    r = base + 0.22 * edge + 0.18 * dark - 0.20 * bright + smear * smudge(seed)
    return np.clip(r, 0.12, 0.95)


def main():
    mats = sys.argv[1] if len(sys.argv) > 1 else "."
    for i, (name, (stem, base, smear)) in enumerate(MATERIALS.items()):
        r = roughness(stem, base, smear, mats, 100 + i)
        Image.fromarray((r * 255).astype(np.uint8), "L").save(f"{mats}/{stem}_rough.png")
        print(f"{name}: {stem}_rough.png mean={r.mean():.2f}")


if __name__ == "__main__":
    main()
