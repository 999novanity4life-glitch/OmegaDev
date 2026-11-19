"""Fruit recipes. Run: python fruits.py <name> [outdir] [--fast]"""
import sys, math, os, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
from mathutils import Vector, noise
import fruitlib as F


def rubber():
    """Rubber / Sun God fruit (canon): round violet melon, lighter purple swirl curls, curly green stem."""
    body_m = F.material("Body", "#55247f", rough=0.38, sss=0.08, coat=0.35)
    swirl_m = F.material("Swirl", "#c08ae6", rough=0.32, coat=0.3)
    stem_m = F.material("Stem", "#7fb83a", rough=0.5)
    centres = F.fib_points(30, cap_skip=0.1, seed=3)

    def shape(d):  # slightly squat melon, flatter top, dimple at the stem
        r = 1.0 - 0.07 * d.z * d.z
        r -= 0.06 * math.exp(-((1 - d.z) / 0.05))
        return r

    def bumpy(d):
        s = max(math.exp(-(d.angle(c) / 0.3) ** 2) for c in centres)
        return shape(d) * (1 + 0.075 * s)

    body = F.make_body(shape, body_m, segs=96, rings=64, bumps=centres, bump_h=0.075, bump_w=0.3)
    sw = F.swirl_curls(bumpy, centres, swirl_m, size=0.3, turns=2.1, tube=0.042, lift=0.004, seed=5)
    stem = F.curly_stem(Vector((0, 0, bumpy(Vector((0, 0, 1))) - 0.04)), stem_m, height=0.34, curl_r=0.12,
                        thick=0.06, lean=Vector((0.08, 0, 0)))
    return [body] + sw + stem


def quake():
    """Quake fruit (canon): pale blue pear, white swirls, crack lines."""
    body_m = F.material("Body", "#9cc0ea", rough=0.42, sss=0.06, coat=0.25)
    swirl_m = F.material("Swirl", "#eef4ff", rough=0.35)
    crack_m = F.material("Crack", "#1d2c52", rough=0.6)
    stem_m = F.material("Stem", "#5f9e2f", rough=0.5)

    def prof(z):  # pear: fat bulb at the bottom, narrowing neck up to the stem
        bulb = math.sqrt(max(0.0, 1 - ((z + 0.15) / 0.95) ** 2)) * 1.0
        neck = 0.42 * math.sqrt(max(0.0, 1 - ((z - 0.75) / 0.5) ** 2))
        return max(bulb, neck, 0.0)
    shape = F.lathe_radial(prof, -1.1, 1.25)

    centres = [c for c in F.fib_points(30, cap_skip=0.1, seed=7) if c.z < 0.8]
    body = F.make_body(shape, body_m, bumps=centres, bump_h=0.03, bump_w=0.3)
    sw = F.swirl_curls(shape, centres, swirl_m, size=0.22, turns=1.8, tube=0.03, lift=0.006, seed=8)
    # crack lines: random walks over the lower half
    rnd = random.Random(11)
    cracks = []
    for i in range(16):
        d = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1.0, 0.5))).normalized()
        pts = []
        step = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1))).normalized()
        for k in range(22):
            pts.append(d * (shape(d) + 0.006))
            step = (step + Vector((rnd.uniform(-.8, .8), rnd.uniform(-.8, .8), rnd.uniform(-.8, .8)))).normalized()
            d = (d + step * 0.06).normalized()
        cracks.append(F.to_mesh(F.curve_from_points(f"Crack{i}", pts, 0.03, [1 - k / 24 for k in range(22)], res=1, mat=crack_m)))
    top = shape(Vector((0, 0, 1)))
    stem = F.curly_stem(Vector((0, 0, top - 0.04)), stem_m, height=0.3, curl_r=0.11, thick=0.05, lean=Vector((-0.06, 0, 0)))
    return [body] + sw + cracks + stem


def darkness():
    """Darkness fruit (canon): purple bunch of swirl lobes like a grape cluster."""
    body_m = F.material("Body", "#5b3d9e", rough=0.4, sss=0.06, coat=0.3)
    swirl_m = F.material("Swirl", "#b9a2f0", rough=0.35)
    stem_m = F.material("Stem", "#5f9e2f", rough=0.5)
    obs = []
    rnd = random.Random(21)
    lobes = []
    # cluster: ~11 lobes arranged as a squat heap
    layers = [(-0.35, 5, 0.62), (0.15, 4, 0.46), (0.6, 2, 0.25)]
    for z, n, ring in layers:
        for i in range(n):
            a = i / n * math.tau + z
            lobes.append((Vector((math.cos(a) * ring, math.sin(a) * ring * 0.85, z)), rnd.uniform(0.40, 0.48)))
    lobes.append((Vector((0, 0, -0.1)), 0.5))
    for i, (c, r) in enumerate(lobes):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=20, radius=r, location=c)
        o = bpy.context.active_object
        o.name = f"Body{i}"
        o.data.materials.append(body_m)
        for p in o.data.polygons:
            p.use_smooth = True
        obs.append(o)
        # one swirl per lobe, facing outward
        out = (c - Vector((0, 0, -0.1)))
        out = out.normalized() if out.length > 0.01 else Vector((0, 0, -1))
        fn = (lambda rr: (lambda d: rr))(r)
        s = F.swirl_curls(fn, [out], swirl_m, size=0.62, turns=1.9, tube=0.03, lift=0.004, seed=30 + i)
        for so in s:
            so.location = c
        obs += s
    stem = F.curly_stem(Vector((0, 0, 0.82)), stem_m, height=0.26, curl_r=0.1, thick=0.05, lean=Vector((0.05, 0, 0)))
    return obs + stem


def azure_dragon():
    """Azure Dragon fruit (canon): blue scaly pineapple body, orange leaf crown, purple curl stem."""
    body_m = F.material("Body", "#1f5f9e", rough=0.4, coat=0.3)
    scale_m = F.material("Scale", "#7fd0f5", rough=0.3, coat=0.4)
    leaf_m = F.material("Leaf", "#ff9a2e", rough=0.45)
    stem_m = F.material("Stem", "#8a4fd0", rough=0.45)

    def prof(z):  # tall rounded egg, wider low, like the canon art
        return 0.95 * math.sqrt(max(0.0, 1 - ((z + 0.05) / 1.2) ** 2)) * (1 - 0.18 * max(0, z))
    shape = F.lathe_radial(prof, -1.3, 1.2)

    body = F.make_body(shape, body_m, segs=64, rings=40)
    obs = [body]
    # scales: rows of pointed, overlapping teardrop scales (tip down), offset each row
    rows = 12
    for r in range(rows):
        el = math.radians(-70 + r * (135 / (rows - 1)))
        n = max(6, int(17 * math.cos(el)))
        for i in range(n):
            a = (i + 0.5 * (r % 2)) / n * math.tau
            d = Vector((math.cos(a) * math.cos(el), math.sin(a) * math.cos(el), math.sin(el))).normalized()
            p = d * (shape(d) - 0.01)
            bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.13, location=p)
            o = bpy.context.active_object
            # long axis along local Y (= down the fruit), thin along the normal
            for v in o.data.vertices:
                y = v.co.y
                v.co.x *= 0.95 * (1 - 0.55 * max(0.0, -y / 0.13))  # taper to a point at the bottom
                v.co.y *= 1.45
                v.co.z *= 0.35
            down = (Vector((0, 0, -1)) - d * d.z).normalized() if abs(d.z) < 0.99 else Vector((1, 0, 0))
            side = down.cross(d)
            from mathutils import Matrix
            o.rotation_euler = Matrix((side, down, d)).transposed().to_euler()
            o.data.materials.append(scale_m)
            for pp in o.data.polygons:
                pp.use_smooth = True
            obs.append(o)
    top = shape(Vector((0, 0, 1)))
    # crown of curled leaves
    for i in range(7):
        a = i / 7 * math.tau
        pts, radii = [], []
        for k in range(12):
            t = k / 11
            rr = 0.1 + 0.32 * t
            pts.append(Vector((math.cos(a) * rr, math.sin(a) * rr, top - 0.05 + 0.35 * math.sin(t * 2.2))))
            radii.append(1.0 - 0.8 * t)
        leaf = F.curve_from_points(f"Leaf{i}", pts, 0.06, radii, res=1, mat=leaf_m)
        leaf.data.bevel_mode = "ROUND"
        o = F.to_mesh(leaf)
        o.scale = (1, 1, 1)
        obs.append(o)
    obs += F.curly_stem(Vector((0, 0, top + 0.1)), stem_m, height=0.35, curl_r=0.12, thick=0.045)
    return obs


def black_dragon():
    """Black Dragon fruit (ours): same scaly dragon body, black with red glowing seams, horn stem."""
    obs = azure_dragon()
    for o in obs:
        for m in o.data.materials:
            pass
    mats = {m.name: m for m in bpy.data.materials}
    def recolor(name, col, emit=None, strength=0):
        m = mats[name]
        b = m.node_tree.nodes["Principled BSDF"]
        b.inputs["Base Color"].default_value = F.hexcol(col)
        if emit:
            b.inputs["Emission Color"].default_value = F.hexcol(emit)
            b.inputs["Emission Strength"].default_value = strength
        m["palette"] = emit or col
    recolor("Body", "#1a0f12", emit="#ff2a1a", strength=1.5)  # seams glow between scales
    recolor("Scale", "#17171c")
    recolor("Leaf", "#2a1416")
    recolor("Stem", "#3a0d0d")
    return obs


def soul():
    """Soul fruit (ours): plump pale-pink teardrop, ghost-wisp stem."""
    body_m = F.material("Body", "#f2a6c8", rough=0.35, sss=0.15, coat=0.3)
    swirl_m = F.material("Swirl", "#fff0f7", rough=0.3)
    wisp_m = F.material("Wisp", "#e9f6ff", emit="#cfefff", emit_strength=2.5)

    def prof(z):  # plump teardrop with a soft point at the top
        if z < 0.1:
            return math.sqrt(max(0.0, 1 - (z - 0.1) ** 2 / 1.1 ** 2)) * 1.0
        u = min(1.0, (z - 0.1) / 1.15)
        return max(0.0, (1 - u ** 1.7) ** 1.1)
    shape = F.lathe_radial(prof, -1.0, 1.25)

    centres = [c for c in F.fib_points(20, cap_skip=0.15, seed=41) if c.z < 0.6]
    body = F.make_body(shape, body_m, bumps=centres, bump_h=0.04, bump_w=0.34)
    sw = F.swirl_curls(shape, centres, swirl_m, size=0.3, turns=1.6, tube=0.026, lift=0.008, seed=42)
    top = shape(Vector((0, 0, 1)))
    # ghost wisp: wavy tapered tube flaring sideways
    pts, radii = [], []
    for k in range(30):
        t = k / 29
        pts.append(Vector((0.7 * t + 0.12 * math.sin(t * 8), 0.08 * math.sin(t * 5), top - 0.08 + 0.75 * t - 0.45 * t * t)))
        radii.append(1.0 - 0.85 * t)
    w = F.to_mesh(F.curve_from_points("Wisp", pts, 0.11, radii, res=2, mat=wisp_m))
    return [body] + sw + [w]


def magma():
    """Magma fruit (ours): black basalt rind, glowing orange swirl seams."""
    body_m = F.material("Body", "#1d1715", rough=0.85)
    swirl_m = F.material("Swirl", "#ff6a00", emit="#ff7a12", emit_strength=8)
    stem_m = F.material("Stem", "#2b211d", rough=0.8)
    centres = F.fib_points(22, cap_skip=0.12, seed=51)

    def shape(d):  # rough rocky sphere
        n = noise.noise(d * 3.2) * 0.05 + noise.noise(d * 9) * 0.015
        return 1.0 - 0.05 * d.z * d.z + n

    body = F.make_body(shape, body_m, bumps=centres, bump_h=0.05, bump_w=0.34)

    def bumpy(d):
        s = max(math.exp(-(d.angle(c) / 0.34) ** 2) for c in centres)
        return shape(d) * (1 + 0.05 * s)

    # seams sit slightly *into* the rock so they read as cracks of lava
    sw = F.swirl_curls(bumpy, centres, swirl_m, size=0.34, turns=1.7, tube=0.028, lift=-0.004, seed=52)
    stem = F.curly_stem(Vector((0, 0, bumpy(Vector((0, 0, 1))) - 0.04)), stem_m, height=0.3, curl_r=0.11, thick=0.06)
    return [body] + sw + stem


RECIPES = {
    "rubber": ("Rubber Fruit", rubber, "#ff7a1a"),
    "quake": ("Quake Fruit", quake, "#9fd0ff"),
    "darkness": ("Darkness Fruit", darkness, "#a07bff"),
    "azure_dragon": ("Azure Dragon Fruit", azure_dragon, "#4fb6ff"),
    "black_dragon": ("Black Dragon Fruit", black_dragon, "#ff2a1a"),
    "soul": ("Soul Fruit", soul, "#ffc2df"),
    "magma": ("Magma Fruit", magma, "#ff6a00"),
}


LOW_PREFIX = ("Body", "Stem", "Wisp", "Leaf")


def build(key, outdir, fast=False, low_tris=2400, tex=1024):
    title, fn, accent = RECIPES[key]
    F.reset()
    scene = bpy.context.scene
    parts = fn()
    os.makedirs(outdir, exist_ok=True)
    lows = [F.duplicate(o, "Low_" + o.name) for o in parts if o.name.startswith(LOW_PREFIX)]
    high = F.join(parts, title.replace(" ", "") + "_High")
    bpy.ops.object.select_all(action="DESELECT")
    high.select_set(True)
    bpy.context.view_layer.objects.active = high
    raw = F.triangle_count(high)
    low = F.bake_lowpoly(high, lows, title.replace(" ", ""), outdir, key, tex=512 if fast else tex, low_tris=low_tris)
    final = F.triangle_count(low)
    F.export(low, os.path.join(outdir, key))
    cam = F.studio(scene, accent=accent, res=420 if fast else 1000, samples=24 if fast else 128)
    F.aim(cam)
    F.render(os.path.join(outdir, f"{key}_front.png"))
    if not fast:
        F.aim(cam, elev=38, azim=140)
        F.render(os.path.join(outdir, f"{key}_back.png"))
    print(f"[{key}] tris high={raw} low={final}")
    return raw, final


if __name__ == "__main__":
    key = sys.argv[1]
    outdir = sys.argv[2] if len(sys.argv) > 2 and not sys.argv[2].startswith("--") else "out"
    build(key, outdir, fast="--fast" in sys.argv)
