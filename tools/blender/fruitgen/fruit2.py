"""fruitgen v2: surface detail carved into a dense mesh as a height field.

v1 put thin swirl tubes on a smooth ball. The show's fruits are *made of* the
detail: packed cinnamon-roll swirl buns (Rubber), branching cracks (Quake),
overlapping scallop scales (Azure Dragon). v2 builds a ~300k-vertex sphere,
displaces it with numpy height fields, colours each vertex from the same
fields (groove = dark, ridge = light, plus a vertical gradient and a glow
mask), then bakes colour x AO, normal, roughness and glow onto a low-poly
copy that keeps the lumpy silhouette.

Run: python fruit2.py <key> <outdir> [--fast]
"""
import math, os, sys
import numpy as np
import bpy, bmesh
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fruitlib as F  # reuse: reset, hexcol, material, curve helpers, studio, aim, render, export


# ------------------------------------------------------------------ colour helpers
def rgb(h):
    return np.array(F.hexcol(h)[:3])


def lerp(a, b, t):
    t = np.clip(t, 0, 1)[..., None]
    return a * (1 - t) + b * t


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


# ------------------------------------------------------------------ point sets
def fib_dirs(n):
    k = np.arange(n) + 0.5
    z = 1 - 2 * k / n
    r = np.sqrt(1 - z * z)
    th = math.pi * (3 - math.sqrt(5)) * k
    return np.stack([r * np.cos(th), r * np.sin(th), z], 1)


def jitter(dirs, amount, seed):
    rng = np.random.default_rng(seed)
    d = dirs + rng.normal(0, amount, dirs.shape)
    return d / np.linalg.norm(d, axis=1, keepdims=True)


def frames(c):
    up = np.where(np.abs(c[:, 2:3]) < 0.95, np.array([[0, 0, 1.0]]), np.array([[1.0, 0, 0]]))
    u = np.cross(c, up)
    u /= np.linalg.norm(u, axis=1, keepdims=True)
    v = np.cross(c, u)
    return u, v


def nearest2(d, centres):
    """Angular distance to nearest and second-nearest centre, and nearest index."""
    if len(centres) == 1:  # one bun: pretend its far side is the neighbour
        centres = np.vstack([centres, -centres])
    dots = d @ centres.T  # (N, C)
    idx = np.argpartition(-dots, 1, axis=1)[:, :2]
    rows = np.arange(len(d))[:, None]
    top = dots[rows, idx]
    order = np.argsort(-top, axis=1)
    idx = np.take_along_axis(idx, order, 1)
    top = np.take_along_axis(top, order, 1)
    a = np.arccos(np.clip(top, -1, 1))
    return a[:, 0], a[:, 1], idx[:, 0]


# ------------------------------------------------------------------ height fields
def swirl_buns(d, centres, turns=2.2, seed=0, groove=0.55, sharp=0.35):
    """Packed cinnamon-roll buns. Returns (height 0..1, ridge 0..1, crease 0..1)."""
    if len(centres) == 1:  # one bun: its far side acts as the neighbour
        centres = np.vstack([centres, -centres])
    a1, a2, i = nearest2(d, centres)
    c = centres[i]
    u, v = frames(centres)
    u, v = u[i], v[i]
    off = d - c * np.sum(d * c, 1, keepdims=True)
    x, y = np.sum(off * u, 1), np.sum(off * v, 1)
    rng = np.random.default_rng(seed)
    spin = rng.choice([-1.0, 1.0], len(centres))[i]
    rot = rng.uniform(0, math.tau, len(centres))[i]
    theta = np.arctan2(y, x) * spin + rot
    edge = (a1 + a2) / 2  # Voronoi boundary sits at the midpoint
    rn = np.clip(a1 / np.maximum(edge, 1e-6), 0, 1)
    dome = np.sqrt(np.clip(1 - rn ** 2.2, 0, 1))
    phase = theta / math.tau + rn * turns
    ridge = 0.5 + 0.5 * np.cos(math.tau * phase)
    ridge = ridge ** sharp  # rounded rope, narrow groove
    # groove fades out at the bun centre (the coil's eye) and at the rim
    gmask = smooth(0.08, 0.25, rn) * (1 - smooth(0.85, 1.0, rn))
    h = dome * (1 - groove * gmask * (1 - ridge))
    crease = 1 - smooth(0.0, 0.18, 1 - rn)  # 1 at the seam between buns
    return h, ridge * gmask + (1 - gmask), crease


def crack_field(d, n_cells, seed, width=0.02, warp=0.15):
    """Branching crack network from Voronoi cell edges with domain warp."""
    rng = np.random.default_rng(seed)
    w = d + warp * np.stack([np.sin(d[:, 1] * 7 + 1.3), np.sin(d[:, 2] * 6 + 2.1), np.sin(d[:, 0] * 8 + 0.4)], 1)
    w /= np.linalg.norm(w, axis=1, keepdims=True)
    centres = jitter(fib_dirs(n_cells), 0.25, seed)
    a1, a2, _ = nearest2(w, centres)
    return 1 - smooth(0, width, a2 - a1)  # 1 on the crack


def scallop_scales(d, rows, per_row_eq, z_lo, z_hi, seed=0):
    """Overlapping fish scales, tips pointing down. Returns (height, rim, centre_dot)."""
    cs = []
    for r in range(rows):
        el = z_lo + (z_hi - z_lo) * r / (rows - 1)
        n = max(6, int(round(per_row_eq * math.cos(el))))
        for k in range(n):
            az = (k + 0.5 * (r % 2)) / n * math.tau
            cs.append((math.cos(el) * math.cos(az), math.cos(el) * math.sin(az), math.sin(el)))
    centres = np.array(cs)
    # bias toward the scale *above* so each scale overlaps the one below it
    shifted = d + np.array([0, 0, 0.06])
    shifted /= np.linalg.norm(shifted, axis=1, keepdims=True)
    a1, a2, i = nearest2(shifted, centres)
    c = centres[i]
    edge = (a1 + a2) / 2
    rn = np.clip(a1 / np.maximum(edge, 1e-6), 0, 1)
    below = np.sign(c[:, 2] - d[:, 2])  # +1 on the lower half of the scale
    # each scale rises toward its lower rim, then drops onto the next scale
    h = 0.35 + 0.65 * np.clip(0.5 + 0.5 * below * rn, 0, 1) * (1 - smooth(0.9, 1.0, rn) * (below > 0))
    rim = smooth(0.62, 0.85, rn)
    dot = 1 - smooth(0.12, 0.24, np.abs(rn - 0.0) + 0.0 * below)
    return h, rim, dot


# ------------------------------------------------------------------ mesh build
def hi_sphere(subdiv=7):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=1)
    ob = bpy.context.active_object
    ob.name = "Body"
    return ob


def apply_field(ob, radius, colors, glow=None, rough=None):
    me = ob.data
    n = len(me.vertices)
    co = np.empty(n * 3)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    d = co / np.linalg.norm(co, axis=1, keepdims=True)
    r = radius(d)
    me.vertices.foreach_set("co", (d * r[:, None]).ravel())
    me.update()
    for name, data, dom in (("Col", colors(d), 4), ("Glow", glow(d) if glow else np.zeros(n), 1),
                            ("Rough", rough(d) if rough else np.full(n, 0.45), 1)):
        if dom == 4:
            attr = me.color_attributes.new(name, "FLOAT_COLOR", "POINT")
            rgba = np.concatenate([data, np.ones((n, 1))], 1)
            attr.data.foreach_set("color", rgba.ravel())
        else:
            attr = me.attributes.new(name, "FLOAT", "POINT")
            attr.data.foreach_set("value", data)
    for p in me.polygons:
        p.use_smooth = True
    return d


def body_material(glow_color, glow_strength, coat=0.3, sss=0.05):
    m = bpy.data.materials.new("BodyHi")
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    col = nt.nodes.new("ShaderNodeAttribute"); col.attribute_name = "Col"
    glw = nt.nodes.new("ShaderNodeAttribute"); glw.attribute_name = "Glow"
    rgh = nt.nodes.new("ShaderNodeAttribute"); rgh.attribute_name = "Rough"
    nt.links.new(col.outputs["Color"], b.inputs["Base Color"])
    nt.links.new(rgh.outputs["Fac"], b.inputs["Roughness"])
    b.inputs["Emission Color"].default_value = F.hexcol(glow_color)
    nt.links.new(glw.outputs["Fac"], b.inputs["Emission Strength"])
    m["glow_strength"] = glow_strength
    b.inputs["Coat Weight"].default_value = coat
    b.inputs["Subsurface Weight"].default_value = sss
    m["palette"] = "#808080"
    return m


# ------------------------------------------------------------------ recipes
def rubber(fast):
    centres = jitter(fib_dirs(46), 0.05, 3)
    centres = centres[centres[:, 2] < 0.93]  # stem dimple

    def fields(d):
        return swirl_buns(d, centres, turns=2.0, seed=4, groove=0.6)

    def radius(d):
        h, _, _ = fields(d)
        base = 1.0 - 0.08 * d[:, 2] ** 2 - 0.08 * np.exp(-(1 - d[:, 2]) / 0.04)
        return base * (0.80 + 0.24 * h)

    def colors(d):
        h, ridge, crease = fields(d)
        z = (d[:, 2] + 1) / 2
        deep, mid, top = rgb("#2a1f7a"), rgb("#6a4bc4"), rgb("#f0b49a")
        base = lerp(lerp(deep, mid, z * 1.6), top, (z - 0.55) * 2.2)
        light = lerp(base, base * 1.25 + 0.03, ridge * h * 0.7)  # ridge highlight
        dark = lerp(light, base * 0.25, (1 - ridge) * 0.85 + crease * 0.6)
        return np.clip(dark, 0, 1)

    def glow(d):
        h, ridge, crease = fields(d)
        # light shines out of the crevices: the swirl grooves and the seams between buns
        return np.clip(crease * 0.9 + (1 - ridge) ** 5 * 0.45, 0, 1) ** 1.6 * (0.5 + 0.5 * smooth(-0.6, 0.9, d[:, 2]))

    return radius, colors, glow, None, ("#ffa98a", 1.0), dict(stem="vine", stem_col="#b9c75a")


def quake(fast):
    def prof(z):
        bulb = math.sqrt(max(0.0, 1 - ((z + 0.25) / 0.95) ** 2))
        neck = 0.5 * math.sqrt(max(0.0, 1 - ((z - 0.55) / 0.75) ** 2))
        k = 8.0
        if bulb <= 0 and neck <= 0:
            return 0.0
        return math.log(math.exp(k * bulb) + math.exp(k * neck)) / k - math.log(2) / k
    lat = F.lathe_radial(prof, -1.2, 1.3)
    zs = np.linspace(-1, 1, 801)

    def radius(d):
        base = np.array([lat(Vector(v)) for v in d]) if len(d) < 5000 else None
        if base is None:  # fast path: sample the lathe on a grid of directions' z and interpolate
            table = np.array([lat(Vector((math.sqrt(max(0, 1 - z * z)), 0, z))) for z in zs])
            base = np.interp(d[:, 2], zs, table)
        c1 = crack_field(d, 60, 11, 0.025)
        c2 = crack_field(d, 220, 12, 0.012, 0.25)
        bump = 0.012 * np.sin(d[:, 0] * 40) * np.sin(d[:, 1] * 37) * np.sin(d[:, 2] * 43)
        lobes = 0.035 * np.cos(np.arctan2(d[:, 1], d[:, 0]) * 7) * smooth(0.2, -0.9, d[:, 2])
        return base * (1 - 0.03 * c1 - 0.015 * c2 + bump + lobes)

    def colors(d):
        z = (d[:, 2] + 1) / 2
        top, mid, bot = rgb("#1d2f7a"), rgb("#4f6cc0"), rgb("#e6eefc")
        base = lerp(lerp(bot, mid, z * 1.8), top, (z - 0.55) * 2.4)
        c1 = crack_field(d, 60, 11, 0.025)
        c2 = crack_field(d, 220, 12, 0.012, 0.25)
        crack = np.clip(c1 + 0.8 * c2, 0, 1) * smooth(0.95, 0.35, z)  # cracks live on the lower body
        stip = 0.08 * np.sin(d[:, 0] * 211) * np.sin(d[:, 1] * 197) * np.sin(d[:, 2] * 223)  # manga stipple
        col = lerp(base, rgb("#0d1640"), crack * 0.9) + stip[:, None]
        return np.clip(col, 0, 1)

    def glow(d):
        z = (d[:, 2] + 1) / 2
        c1 = crack_field(d, 60, 11, 0.025)
        return 2.5 * c1 * smooth(0.8, 0.2, z)  # faint cyan light inside the big cracks

    return radius, colors, glow, None, ("#8fd8ff", 1.0), dict(stem="t", stem_col="#9cc06a")


def darkness(fast):
    rng = np.random.default_rng(21)
    lobes = []
    for z, n, ring, rr in [(-0.55, 6, 0.55, 0.42), (-0.05, 6, 0.6, 0.44), (0.45, 4, 0.42, 0.38), (0.82, 1, 0.0, 0.32)]:
        for k in range(n):
            a = k / n * math.tau + z * 2
            lobes.append((ring * math.cos(a), ring * math.sin(a) * 0.9, z, rr * rng.uniform(0.92, 1.08)))
    lobes = np.array(lobes)

    def field(d):
        # each direction hits the lobe that sticks out furthest along it (union of buds)
        best_r = np.zeros(len(d))
        best_h = np.zeros(len(d)); best_ridge = np.ones(len(d)); best_cre = np.zeros(len(d))
        for j, (cx, cy, cz, rr) in enumerate(lobes):
            c = np.array([cx, cy, cz])
            # ray from origin along d vs sphere at c radius rr
            b = d @ c
            disc = b * b - (c @ c - rr * rr)
            t = np.where(disc > 0, b + np.sqrt(np.maximum(disc, 0)), 0)
            # local direction on the lobe for its swirl bun
            p = d * t[:, None] - c
            n_ = p / np.maximum(np.linalg.norm(p, axis=1, keepdims=True), 1e-6)
            out = c / max(np.linalg.norm(c), 1e-6) if np.linalg.norm(c) > 0.05 else np.array([0, 0, 1.0])
            h, ridge, cre = swirl_buns(n_, out[None, :], turns=1.8, seed=40 + j, groove=0.55)
            # rose-bud: pointed tip along the lobe's outward axis
            tip = np.clip(n_ @ out, 0, 1) ** 6
            t = t * (0.84 + 0.18 * h) + rr * 0.25 * tip
            take = t > best_r
            best_r = np.where(take, t, best_r)
            best_h = np.where(take, h, best_h)
            best_ridge = np.where(take, ridge, best_ridge)
            best_cre = np.where(take, 1 - h, best_cre)
        return best_r, best_h, best_ridge, best_cre

    cache = {}

    def get(d):
        key = id(d)
        if key not in cache:
            cache.clear(); cache[key] = field(d)
        return cache[key]

    def radius(d):
        r = get(d)[0]
        return np.where(r > 0.05, r, 0.3)

    def colors(d):
        _, h, ridge, cre = get(d)
        z = (d[:, 2] + 1) / 2
        base = lerp(rgb("#5a3fa8"), rgb("#c3a6ef"), 0.35 + 0.6 * z)
        light = lerp(base, base * 1.35 + 0.04, ridge * h)
        return np.clip(lerp(light, rgb("#2a1660"), np.clip((1 - ridge) * 1.5 + cre * 0.6, 0, 1)), 0, 1)

    def glow(d):
        _, h, ridge, cre = get(d)
        return 1.2 * cre * (1 - ridge)  # dark-purple light leaking from the gaps

    return radius, colors, glow, None, ("#6a2cff", 1.0), dict(stem="curl", stem_col="#7fb83a", stem_z=0.98)


def azure_dragon(fast):
    def prof(z):  # round, slightly wider low (canon art), flat-ish top under the calyx
        return 0.98 * math.sqrt(max(0.0, 1 - ((z + 0.08) / 1.08) ** 2)) * (1 - 0.1 * max(0, z))
    lat = F.lathe_radial(prof, -1.2, 1.05)
    zs = np.linspace(-1, 1, 801)
    table = np.array([lat(Vector((math.sqrt(max(0, 1 - z * z)), 0, z))) for z in zs])

    def sc(d):
        return scallop_scales(d, rows=10, per_row_eq=15, z_lo=math.radians(-72), z_hi=math.radians(62))

    def radius(d):
        h, rim, dot = sc(d)
        return np.interp(d[:, 2], zs, table) * (0.88 + 0.16 * h)

    def colors(d):
        h, rim, dot = sc(d)
        inner, edge, eye = rgb("#2a64c8"), rgb("#5fd2ee"), rgb("#122a6b")
        col = lerp(inner, edge, rim)
        col = lerp(col, eye, dot * 0.9)
        col = col * (0.3 + 0.7 * h[:, None])  # shadow where a scale tucks under the next
        return np.clip(col, 0, 1)

    def glow(d):
        h, rim, dot = sc(d)
        return 1.8 * rim * h

    return radius, colors, glow, None, ("#7fe6ff", 1.0), dict(stem="dragon", stem_col="#8a4fd0", calyx="#ff9a2e")


def black_dragon(fast):
    radius, colors, glow, rough, _, extra = azure_dragon(fast)

    def colors2(d):
        c = colors(d)
        lum = c.mean(1, keepdims=True)
        return np.clip(lum * rgb("#2a2430") * 2.2, 0, 1)

    def glow2(d):
        h, rim, dot = scallop_scales(d, 10, 15, math.radians(-72), math.radians(62))
        return 6.0 * (1 - h) ** 2 + 2.0 * dot  # red light from the seams and the scale eyes

    extra = dict(extra, stem_col="#2a0f12", calyx="#3a0d0d")
    return radius, colors2, glow2, None, ("#ff2a1a", 1.0), extra


def soul(fast):
    centres = jitter(fib_dirs(34), 0.05, 41)
    centres = centres[centres[:, 2] < 0.7]

    def prof(z):
        if z < 0.15:
            return math.sqrt(max(0.0, 1 - (z - 0.15) ** 2 / 1.15 ** 2))
        u = min(1.0, (z - 0.15) / 1.0)
        return max(0.0, (1 - u ** 1.5) ** 0.9)
    lat = F.lathe_radial(prof, -1.05, 1.2)
    zs = np.linspace(-1, 1, 801)
    table = np.array([lat(Vector((math.sqrt(max(0, 1 - z * z)), 0, z))) for z in zs])

    def radius(d):
        h, _, _ = swirl_buns(d, centres, turns=1.8, seed=42, groove=0.5)
        return np.interp(d[:, 2], zs, table) * (0.84 + 0.2 * h)

    def colors(d):
        h, ridge, cre = swirl_buns(d, centres, turns=1.8, seed=42, groove=0.5)
        z = (d[:, 2] + 1) / 2
        base = lerp(rgb("#e58fbf"), rgb("#fde3f0"), z)
        return np.clip(lerp(lerp(base, base * 1.15 + 0.05, ridge * h), rgb("#a2457e"), (1 - ridge) * 0.6 + cre * 0.4), 0, 1)

    def glow(d):
        h, ridge, cre = swirl_buns(d, centres, turns=1.8, seed=42, groove=0.5)
        return np.clip(cre * 0.9 + (1 - ridge) ** 5 * 0.45, 0, 1) ** 1.6

    return radius, colors, glow, None, ("#ffd6ee", 1.0), dict(stem="wisp", stem_col="#e9f6ff")


def magma(fast):
    centres = jitter(fib_dirs(44), 0.06, 51)
    centres = centres[centres[:, 2] < 0.93]

    def radius(d):
        h, _, _ = swirl_buns(d, centres, turns=2.0, seed=52, groove=0.7, sharp=0.6)
        rock = 0.02 * np.sin(d[:, 0] * 31) * np.sin(d[:, 1] * 29 + 1) * np.sin(d[:, 2] * 27)
        return (1 - 0.06 * d[:, 2] ** 2) * (0.80 + 0.22 * h + rock)

    def colors(d):
        h, ridge, cre = swirl_buns(d, centres, turns=2.0, seed=52, groove=0.7, sharp=0.6)
        rock = lerp(rgb("#141011"), rgb("#3a2c27"), ridge * h)
        lava = rgb("#ff5a0a")
        return np.clip(lerp(rock, lava, (1 - ridge) * 0.9 + cre * 0.8), 0, 1)

    def glow(d):
        h, ridge, cre = swirl_buns(d, centres, turns=2.0, seed=52, groove=0.7, sharp=0.6)
        return 4.0 * np.clip(cre * 0.9 + (1 - ridge) ** 4 * 0.6, 0, 1) ** 1.5

    def rough(d):
        h, ridge, _ = swirl_buns(d, centres, turns=2.0, seed=52, groove=0.7, sharp=0.6)
        return 0.9 - 0.5 * (1 - ridge)

    return radius, colors, glow, rough, ("#ff6a10", 1.0), dict(stem="curl", stem_col="#231a17")


RECIPES = {
    "rubber": ("Rubber Fruit", rubber, "#ff9a4a"),
    "quake": ("Quake Fruit", quake, "#8fd0ff"),
    "darkness": ("Darkness Fruit", darkness, "#9b6bff"),
    "azure_dragon": ("Azure Dragon Fruit", azure_dragon, "#4fb6ff"),
    "black_dragon": ("Black Dragon Fruit", black_dragon, "#ff2a1a"),
    "soul": ("Soul Fruit", soul, "#ffc2df"),
    "magma": ("Magma Fruit", magma, "#ff6a00"),
}


# ------------------------------------------------------------------ stems
def add_stem(kind, top_z, col, extra):
    m = F.material("Stem", col, rough=0.5)
    obs = []
    base = Vector((0, 0, top_z - 0.05))
    if kind in ("curl",):
        obs += F.curly_stem(base, m, height=0.3, curl_r=0.12, thick=0.06, lean=Vector((0.06, 0, 0)))
    elif kind == "vine":  # Rubber: short stem, then a long vine out to the side ending in a curl
        pts, radii = [], []
        for k in range(60):
            t = k / 59
            if t < 0.2:
                p = base + Vector((0, 0, 0.28 * t / 0.2))
            else:
                s = (t - 0.2) / 0.8
                p = base + Vector((0.95 * s, 0.1 * math.sin(s * 3), 0.28 + 0.18 * math.sin(s * math.pi)))
            pts.append(p); radii.append(1.0 - 0.55 * t)
        top = pts[-1]
        for k in range(1, 30):
            t = k / 29
            a = math.pi / 2 - t * 1.6 * math.tau
            r = 0.14 * (1 - 0.7 * t)
            pts.append(top + Vector((0.14 + math.cos(a) * r - 0.14 * 0, 0, -0.14 + math.sin(a) * r)))
            radii.append(0.45 - 0.25 * t)
        obs.append(F.to_mesh(F.curve_from_points("Stem", pts, 0.06, radii, res=2, mat=m)))
    elif kind == "t":  # Quake: T-shaped stem, curl on one arm, cut end on the other
        up = [base + Vector((0, 0, 0.3 * k / 9)) for k in range(10)]
        obs.append(F.to_mesh(F.curve_from_points("Stem", up, 0.06, [1] * 10, res=2, mat=m)))
        top = up[-1]
        arm = [top + Vector((0.45 * k / 9, 0, 0.02 * k / 9)) for k in range(10)]
        obs.append(F.to_mesh(F.curve_from_points("StemArm", arm, 0.055, [1] * 10, res=2, mat=m)))
        pts = [top + Vector((-0.2 * k / 9, 0, 0)) for k in range(10)]
        for k in range(1, 34):
            t = k / 33
            a = -t * 1.7 * math.tau
            r = 0.17 * (1 - 0.75 * t)
            pts.append(top + Vector((-0.2 - 0.17 + math.cos(a) * r * -1 + 0.17 * 0, 0, 0.17 - 0.17 + math.sin(a) * r)))
        obs.append(F.to_mesh(F.curve_from_points("StemCurl", pts, 0.05, [1 - 0.5 * i / len(pts) for i in range(len(pts))], res=2, mat=m)))
    elif kind == "dragon":  # flat orange star calyx + tall purple double-curl stem
        cm = F.material("Calyx", extra["calyx"], rough=0.45)
        for i in range(7):
            a = i / 7 * math.tau
            pts, radii = [], []
            for k in range(14):
                t = k / 13
                rr = 0.06 + 0.42 * t
                pts.append(Vector((math.cos(a) * rr, math.sin(a) * rr, -0.02 + 0.12 * math.sin(t * math.pi) - 0.32 * t)))
                radii.append(1.1 * math.sin(math.pi * min(1, 0.15 + t * 0.9)))
            leaf = F.curve_from_points(f"Calyx{i}", pts, 0.09, radii, res=1, mat=cm)
            o = F.to_mesh(leaf)
            o.scale = (1, 1, 0.45)  # flatten about the calyx centre, then lift onto the top
            o.location = (0, 0, top_z)
            bpy.context.view_layer.update()
            obs.append(o)
        obs += F.curly_stem(base + Vector((0, 0, 0.08)), m, height=0.55, curl_r=0.15, thick=0.05, lean=Vector((0.1, 0, 0)), turns=1.5)
        obs += F.curly_stem(base + Vector((0, 0, 0.08)), m, height=0.35, curl_r=0.1, thick=0.04, lean=Vector((-0.12, 0.05, 0)), turns=1.2)
    elif kind == "wisp":
        wm = F.material("Wisp", "#e9f6ff", emit="#cfefff", emit_strength=4)
        pts, radii = [], []
        for k in range(40):
            t = k / 39
            pts.append(Vector((0.75 * t + 0.12 * math.sin(t * 8), 0.1 * math.sin(t * 5), top_z - 0.1 + 0.8 * t - 0.5 * t * t)))
            radii.append(1.0 - 0.85 * t)
        obs.append(F.to_mesh(F.curve_from_points("Wisp", pts, 0.13, radii, res=2, mat=wm)))
    return obs


# ------------------------------------------------------------------ bake
def bake(high, low, outdir, key, tex, glow_strength):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 24
    rb = sc.render.bake
    rb.use_selected_to_active = True
    rb.cage_extrusion = 0.15
    rb.max_ray_distance = 0.3
    rb.margin = 8
    bm = bpy.data.materials.new("LowBaked"); bm.use_nodes = True
    nt = bm.node_tree
    tnode = nt.nodes.new("ShaderNodeTexImage"); nt.nodes.active = tnode
    low.data.materials.clear(); low.data.materials.append(bm)
    imgs = {}
    for kind, btype in (("color", "DIFFUSE"), ("normal", "NORMAL"), ("roughness", "ROUGHNESS"), ("ao", "AO"), ("glow", "EMIT")):
        img = bpy.data.images.new(f"{key}_{kind}", tex, tex, alpha=False, float_buffer=(kind == "normal"))
        if kind not in ("color", "glow"):
            img.colorspace_settings.name = "Non-Color"
        imgs[kind] = img
        tnode.image = img
        if btype == "DIFFUSE":
            rb.use_pass_direct = False; rb.use_pass_indirect = False; rb.use_pass_color = True
        bpy.ops.object.select_all(action="DESELECT")
        high.select_set(True); low.select_set(True)
        bpy.context.view_layer.objects.active = low
        if btype == "AO":
            sc.cycles.samples = 64
            # AO from the high-poly only: bake it as the low's own AO would miss the grooves
        bpy.ops.object.bake(type=btype)
        sc.cycles.samples = 24
    # colour map = albedo x AO (Roblox has no AO slot; this is where the depth goes)
    c = np.array(imgs["color"].pixels[:]).reshape(-1, 4)
    a = np.array(imgs["ao"].pixels[:]).reshape(-1, 4)[:, :1]
    c[:, :3] *= 0.35 + 0.65 * a
    imgs["color"].pixels = c.ravel()
    g = np.array(imgs["glow"].pixels[:]).reshape(-1, 4)
    g[:, :3] = np.clip(g[:, :3] / max(1e-6, g[:, :3].max()), 0, 1)
    imgs["glow"].pixels = g.ravel()
    for kind in ("color", "normal", "roughness", "glow"):
        imgs[kind].filepath_raw = os.path.join(outdir, f"{key}_{kind}.png")
        imgs[kind].file_format = "PNG"
        imgs[kind].save()
    # rewire for honest preview (what Roblox gets + glow as emission)
    nt.nodes.remove(tnode)
    b = nt.nodes["Principled BSDF"]
    ci = nt.nodes.new("ShaderNodeTexImage"); ci.image = imgs["color"]
    ni = nt.nodes.new("ShaderNodeTexImage"); ni.image = imgs["normal"]
    ri = nt.nodes.new("ShaderNodeTexImage"); ri.image = imgs["roughness"]
    gi = nt.nodes.new("ShaderNodeTexImage"); gi.image = imgs["glow"]
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(ci.outputs["Color"], b.inputs["Base Color"])
    nt.links.new(ri.outputs["Color"], b.inputs["Roughness"])
    nt.links.new(ni.outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], b.inputs["Normal"])
    nt.links.new(gi.outputs["Color"], b.inputs["Emission Color"])
    b.inputs["Emission Strength"].default_value = glow_strength
    b.inputs["Coat Weight"].default_value = 0.35


def bloom(scene):
    """Compositor glare so the glow reads like Roblox Bloom."""
    scene.use_nodes = True
    tree = scene.compositing_node_group if hasattr(scene, "compositing_node_group") else scene.node_tree
    if tree is None:
        tree = bpy.data.node_groups.new("Comp", "CompositorNodeTree")
        scene.compositing_node_group = tree
    nodes = tree.nodes
    rl = nodes.get("Render Layers") or nodes.new("CompositorNodeRLayers")
    glare = nodes.new("CompositorNodeGlare")
    try:
        glare.glare_type = "BLOOM"
    except Exception:
        glare.glare_type = "FOG_GLOW"
    out = None
    for n in nodes:
        if n.bl_idname in ("CompositorNodeComposite", "NodeGroupOutput"):
            out = n
    if out is None:
        try:
            out = nodes.new("CompositorNodeComposite")
        except Exception:
            out = nodes.new("NodeGroupOutput")
            tree.interface.new_socket("Image", in_out="OUTPUT", socket_type="NodeSocketColor")
    tree.links.new(rl.outputs["Image"], glare.inputs["Image"])
    tree.links.new(glare.outputs["Image"], out.inputs[0])
    for name, val in (("Threshold", 0.8), ("Size", 0.5), ("Strength", 0.6)):
        if name in glare.inputs:
            glare.inputs[name].default_value = val


def post_bloom(path, threshold=0.86, radius=14, strength=0.4):
    """Bloom in post (the compositor needs a GPU here). Mirrors Roblox's Bloom effect."""
    from PIL import Image, ImageFilter
    im = Image.open(path).convert("RGB")
    a = np.asarray(im).astype(np.float32) / 255
    lum = a.max(2, keepdims=True)
    bright = np.clip((lum - threshold) / (1 - threshold), 0, 1) * a
    b = Image.fromarray((bright * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(radius))
    out = np.clip(a + strength * np.asarray(b).astype(np.float32) / 255, 0, 1)
    Image.fromarray((out * 255).astype(np.uint8)).save(path)


def build(key, outdir, fast=False):
    title, fn, accent = RECIPES[key]
    F.reset()
    sc = bpy.context.scene
    radius, colors, glow, rough, (gcol, _), extra = fn(fast)
    hi = hi_sphere(6 if fast else 7)
    apply_field(hi, radius, colors, glow, rough)
    hm = body_material(gcol, 1.0)
    hi.data.materials.append(hm)
    top_z = float(radius(np.array([[0, 0, 1.0]]))[0])
    stem = add_stem(extra.get("stem", "curl"), extra.get("stem_z", top_z), extra.get("stem_col", "#7fb83a"), extra)
    # low poly = decimated copy of the *displaced* body (keeps the lumpy silhouette) + stems
    low_body = F.duplicate(hi, "LowBody")
    F.decimate_to(low_body, 6000 if not fast else 3000)
    low_parts = [low_body] + [F.duplicate(o, "Low" + o.name) for o in stem]
    for o in stem:
        F.decimate_to(o, 500)
    for o in low_parts[1:]:
        F.decimate_to(o, 500)
    high = F.join([hi] + stem, title.replace(" ", "") + "_High")
    low = F.join(low_parts, title.replace(" ", ""))
    bpy.ops.object.select_all(action="DESELECT"); low.select_set(True); bpy.context.view_layer.objects.active = low
    while low.data.uv_layers:
        low.data.uv_layers.remove(low.data.uv_layers[0])
    low.data.uv_layers.new(name="UVMap")
    bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.004)
    bpy.ops.object.mode_set(mode="OBJECT")
    for p in low.data.polygons:
        p.use_smooth = True
    # stems: emit their own colour in the vertex-less material, so bake DIFFUSE picks it up
    os.makedirs(outdir, exist_ok=True)
    gstrength = {"magma": 2.0, "black_dragon": 1.2, "quake": 1.5, "azure_dragon": 0.8, "rubber": 1.0, "soul": 0.6}.get(key, 1.5)
    bake(high, low, outdir, key, 512 if fast else 1024, gstrength)
    high.hide_render = True
    tris = F.triangle_count(low)
    F.export(low, os.path.join(outdir, key))
    cam = F.studio(sc, accent=accent, res=480 if fast else 1000, samples=24 if fast else 96)
    # tone the floor ring down so the fruit carries the glow
    for o in sc.objects:
        if o.name.startswith("Torus"):
            o.data.materials[0].node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 2.0
    sc.view_settings.exposure = -0.4
    bbox_top = max((low.matrix_world @ Vector(c)).z for c in low.bound_box)
    F.aim(cam, dist=6.6, target=(0, 0, (bbox_top - 1.0) / 2))
    F.render(os.path.join(outdir, f"{key}_front.png"))
    post_bloom(os.path.join(outdir, f"{key}_front.png"))
    if not fast:
        F.aim(cam, dist=6.6, elev=38, azim=140, target=(0, 0, (bbox_top - 1.0) / 2))
        F.render(os.path.join(outdir, f"{key}_back.png"))
        post_bloom(os.path.join(outdir, f"{key}_back.png"))
    print(f"[{key}] low tris={tris}")


if __name__ == "__main__":
    k = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 and not sys.argv[2].startswith("--") else "out2"
    build(k, out, fast="--fast" in sys.argv)
