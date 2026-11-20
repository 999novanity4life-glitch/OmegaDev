"""Procedural Devil-Fruit-style fruit builder for Blender (bpy 5.x, headless).

Each fruit = body mesh (shape follows the power) + raised swirl curls + curly stem.
Exports one joined mesh per fruit with a tiny palette texture (one MeshPart in Roblox,
colour via TextureID/SurfaceAppearance) plus a GLB/FBX, and renders a preview.
"""
import math, random, os
import bpy, bmesh
from mathutils import Vector, Matrix, noise

# ---------------------------------------------------------------- helpers
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    import addon_utils
    addon_utils.enable("cycles", default_set=True)


def hexcol(h, a=1.0):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    # sRGB -> linear
    c = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
    return (*c, a)


def material(name, color, rough=0.45, emit=None, emit_strength=0.0, sss=0.0, coat=0.0, grad=None):
    """grad=(bottom_hex, top_hex): vertical colour gradient over the object's bounds."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = hexcol(color)
    if grad:
        tc = nt.nodes.new("ShaderNodeTexCoord")
        sep = nt.nodes.new("ShaderNodeSeparateXYZ")
        ramp = nt.nodes.new("ShaderNodeValToRGB")
        ramp.color_ramp.elements[0].color = hexcol(grad[0])
        ramp.color_ramp.elements[1].color = hexcol(grad[1])
        ramp.color_ramp.elements[0].position = 0.15
        ramp.color_ramp.elements[1].position = 0.8
        nt.links.new(tc.outputs["Generated"], sep.inputs[0])
        nt.links.new(sep.outputs["Z"], ramp.inputs["Fac"])
        nt.links.new(ramp.outputs["Color"], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = rough
    if sss:
        b.inputs["Subsurface Weight"].default_value = sss
        b.inputs["Subsurface Radius"].default_value = (0.2, 0.1, 0.1)
    if coat:
        b.inputs["Coat Weight"].default_value = coat
        b.inputs["Coat Roughness"].default_value = 0.15
    if emit:
        b.inputs["Emission Color"].default_value = hexcol(emit)
        b.inputs["Emission Strength"].default_value = emit_strength
    m["palette"] = color if not emit else emit
    return m


def fib_points(n, cap_skip=0.0, seed=0):
    """Fibonacci sphere points; skip points within cap_skip (cos) of +Z (stem)."""
    pts = []
    ga = math.pi * (3 - math.sqrt(5))
    rnd = random.Random(seed)
    i = 0
    total = n * 3
    for k in range(total):
        z = 1 - 2 * (k + 0.5) / total
        r = math.sqrt(1 - z * z)
        th = ga * k
        p = Vector((r * math.cos(th), r * math.sin(th), z))
        if p.z > 1 - cap_skip:
            continue
        pts.append(p)
    rnd.shuffle(pts)
    # thin to n by farthest-point sampling for even coverage
    chosen = [pts[0]]
    while len(chosen) < n and len(chosen) < len(pts):
        best = max(pts, key=lambda q: min((q - c).length for c in chosen))
        chosen.append(best)
    return chosen


def tangent_frame(nrm):
    up = Vector((0, 0, 1)) if abs(nrm.z) < 0.95 else Vector((1, 0, 0))
    u = nrm.cross(up).normalized()
    v = nrm.cross(u).normalized()
    return u, v


def curve_from_points(name, pts, radius, radii=None, res=2, mat=None):
    cd = bpy.data.curves.new(name, "CURVE")
    cd.dimensions = "3D"
    cd.bevel_depth = radius
    cd.bevel_resolution = res
    cd.use_fill_caps = True
    sp = cd.splines.new("POLY")
    sp.points.add(len(pts) - 1)
    for i, p in enumerate(pts):
        sp.points[i].co = (p.x, p.y, p.z, 1)
        sp.points[i].radius = radii[i] if radii else 1.0
    ob = bpy.data.objects.new(name, cd)
    bpy.context.collection.objects.link(ob)
    if mat:
        cd.materials.append(mat)
    return ob


def to_mesh(ob):
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.convert(target="MESH")
    return bpy.context.view_layer.objects.active


# ---------------------------------------------------------------- body
def make_body(radial, mat, segs=72, rings=48, bumps=None, bump_h=0.0, bump_w=0.35, cracks=None):
    """radial(theta, phi_dir:Vector) -> radius multiplier; built from a UV sphere."""
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segs, ring_count=rings, radius=1)
    ob = bpy.context.active_object
    ob.name = "Body"
    me = ob.data
    for v in me.vertices:
        d = v.co.normalized()
        r = radial(d)
        if bumps:
            # lumpy "bun" surface: each swirl centre bulges
            s = 0.0
            for c in bumps:
                ang = d.angle(c)
                s = max(s, math.exp(-(ang / bump_w) ** 2))
            r *= 1 + bump_h * s
        v.co = d * r
    me.materials.append(mat)
    for p in me.polygons:
        p.use_smooth = True
    return ob


def surface_point(body_fn, d):
    d = d.normalized()
    return d * body_fn(d)


# ---------------------------------------------------------------- swirls
def swirl_curls(body_fn, centres, mat, size=0.33, turns=1.6, tube=0.028, lift=0.012, seed=1, name="Swirl"):
    """Raised spiral curls lying on the body surface, one per centre."""
    rnd = random.Random(seed)
    obs = []
    for i, c in enumerate(centres):
        u, v = tangent_frame(c)
        rot = rnd.uniform(0, math.tau)
        sz = size * rnd.uniform(0.85, 1.12)
        direction = 1 if rnd.random() < 0.5 else -1
        pts, radii = [], []
        n = 64
        for k in range(n):
            t = k / (n - 1)
            r = sz * (0.06 + 0.94 * t)
            a = rot + direction * t * turns * math.tau
            off = (u * math.cos(a) + v * math.sin(a)) * r
            d = (c + off).normalized()
            p = d * (body_fn(d) + lift)
            pts.append(p)
            # taper both ends: fat in the middle of the curl, thin tail
            radii.append(0.55 + 0.6 * math.sin(math.pi * min(1, t * 1.15)) if t < 0.95 else 0.35)
        ob = curve_from_points(f"{name}{i}", pts, tube, radii, res=1, mat=mat)
        obs.append(to_mesh(ob))
    return obs


# ---------------------------------------------------------------- stem
def curly_stem(base, mat, height=0.38, curl_r=0.13, thick=0.055, lean=Vector((0.15, 0, 0)), turns=1.3, leaf_mat=None):
    """Stem rises from `base`, then curls into a flat spiral like the show's stems."""
    pts, radii = [], []
    n1 = 14
    for k in range(n1):
        t = k / (n1 - 1)
        p = base + Vector((0, 0, height * t)) + lean * (t * t)
        pts.append(p)
        radii.append(1.0 - 0.15 * t)
    top = pts[-1]
    # curl in the XZ plane, spiralling inward
    n2 = 30
    for k in range(1, n2):
        t = k / (n2 - 1)
        a = math.pi + t * turns * math.tau
        r = curl_r * (1 - 0.7 * t)
        centre = top + Vector((curl_r, 0, 0))
        pts.append(centre + Vector((math.cos(a) * r, 0, -math.sin(a) * r)))
        radii.append(0.85 - 0.45 * t)
    ob = curve_from_points("Stem", pts, thick, radii, res=2, mat=mat)
    return [to_mesh(ob)]


# ---------------------------------------------------------------- finishing
def join(obs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in obs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = obs[0]
    bpy.ops.object.join()
    ob = bpy.context.active_object
    ob.name = name
    return ob


def palette_uvs(ob, size=8):
    """Give every material its own palette cell; write the palette PNG (for Roblox TextureID)."""
    mats = list(ob.data.materials)
    n = len(mats)
    cols = math.ceil(math.sqrt(n))
    img = bpy.data.images.new(ob.name + "_palette", size * cols, size * cols, alpha=False)
    px = [0.0] * (size * cols * size * cols * 4)
    for i, m in enumerate(mats):
        cx, cy = i % cols, i // cols
        c = hexcol(m["palette"])
        for y in range(cy * size, cy * size + size):
            for x in range(cx * size, cx * size + size):
                o = (y * size * cols + x) * 4
                px[o:o + 4] = list(c)
    img.pixels = px
    if not ob.data.uv_layers:
        ob.data.uv_layers.new(name="UVMap")
    uv = ob.data.uv_layers.active.data
    for p in ob.data.polygons:
        i = p.material_index
        cx, cy = i % cols, i // cols
        u = (cx + 0.5) / cols
        v = (cy + 0.5) / cols
        for li in p.loop_indices:
            uv[li].uv = (u, v)
    return img


def triangle_count(ob):
    dg = bpy.context.evaluated_depsgraph_get()
    me = ob.evaluated_get(dg).to_mesh()
    me.calc_loop_triangles()
    n = len(me.loop_triangles)
    ob.evaluated_get(dg).to_mesh_clear()
    return n


def decimate_to(ob, target):
    tris = triangle_count(ob)
    if tris <= target:
        return tris
    mod = ob.modifiers.new("Dec", "DECIMATE")
    mod.ratio = target / tris
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier="Dec")
    return triangle_count(ob)


# ---------------------------------------------------------------- render
def studio(scene, accent="#ff7a1a", res=900, samples=96):
    scene.render.engine = "CYCLES"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.render.resolution_x = res
    scene.render.resolution_y = res
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    world = bpy.data.worlds.new("W")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = hexcol("#0d0f13")
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.6
    # carbon floor disc
    bpy.ops.mesh.primitive_cylinder_add(radius=3.2, depth=0.1, location=(0, 0, -1.25), vertices=96)
    floor = bpy.context.active_object
    fm = material("Floor", "#15171c", rough=0.35)
    floor.data.materials.append(fm)
    # orange rim ring (theme glow)
    bpy.ops.mesh.primitive_torus_add(major_radius=1.55, minor_radius=0.025, location=(0, 0, -1.19))
    ring = bpy.context.active_object
    ring.data.materials.append(material("Ring", "#000000", emit=accent, emit_strength=6))

    def area(name, loc, energy, color, size):
        L = bpy.data.lights.new(name, "AREA")
        L.energy = energy
        L.color = hexcol(color)[:3]
        L.size = size
        o = bpy.data.objects.new(name, L)
        o.location = loc
        scene.collection.objects.link(o)
        o.rotation_euler = (Vector((0, 0, 0)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()

    area("Key", (2.6, -2.8, 3.0), 650, "#fff4e6", 2.5)
    area("Fill", (-3.2, -1.5, 1.2), 160, "#cfe0ff", 3.0)
    area("Rim", (-0.5, 3.4, 2.4), 700, accent, 1.6)
    cam = bpy.data.cameras.new("Cam")
    cam.lens = 70
    co = bpy.data.objects.new("Cam", cam)
    scene.collection.objects.link(co)
    scene.camera = co
    return co


def aim(cam, dist=6.3, elev=12, azim=-28, target=(0, 0, 0.05)):
    e, a = math.radians(elev), math.radians(azim)
    t = Vector(target)
    cam.location = t + Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e))) * dist
    cam.rotation_euler = (t - cam.location).to_track_quat("-Z", "Y").to_euler()


def render(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def export(ob, base):
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.fbx(filepath=base + ".fbx", use_selection=True, apply_scale_options="FBX_SCALE_ALL",
                             axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", path_mode="COPY", embed_textures=False)
    bpy.ops.export_scene.gltf(filepath=base + ".glb", use_selection=True, export_format="GLB")


# ---------------------------------------------------------------- bake to a game-ready low poly
def duplicate(ob, name):
    c = ob.copy()
    c.data = ob.data.copy()
    c.name = name
    bpy.context.collection.objects.link(c)
    return c


def bake_lowpoly(high, low_parts, name, outdir, key, tex=1024, low_tris=2400):
    """Bake high-poly colour/normal/roughness onto a low-poly shell.

    high: joined high-poly object (body + swirls + stem ...)
    low_parts: objects to keep as low-poly geometry (body copy before swirls, stem copy)
    Returns the low object, with a material wired to the baked maps (what Roblox will show
    through SurfaceAppearance)."""
    low = join(low_parts, name)
    decimate_to(low, low_tris)
    bpy.ops.object.select_all(action="DESELECT")
    low.select_set(True)
    bpy.context.view_layer.objects.active = low
    for p in low.data.polygons:
        p.use_smooth = True
    low.data.materials.clear()
    while low.data.uv_layers:
        low.data.uv_layers.remove(low.data.uv_layers[0])
    low.data.uv_layers.new(name="UVMap")
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.006)
    bpy.ops.object.mode_set(mode="OBJECT")

    imgs = {}
    for kind in ("color", "normal", "roughness"):
        img = bpy.data.images.new(f"{key}_{kind}", tex, tex, alpha=False, float_buffer=(kind == "normal"))
        if kind != "color":
            img.colorspace_settings.name = "Non-Color"
        imgs[kind] = img
    bm = bpy.data.materials.new(name + "_Baked")
    bm.use_nodes = True
    nt = bm.node_tree
    tnode = nt.nodes.new("ShaderNodeTexImage")
    nt.nodes.active = tnode
    low.data.materials.append(bm)

    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 16
    sc.render.bake.use_selected_to_active = True
    sc.render.bake.cage_extrusion = 0.12
    sc.render.bake.max_ray_distance = 0.26
    sc.render.bake.margin = 8
    bpy.ops.object.select_all(action="DESELECT")
    high.select_set(True)
    low.select_set(True)
    bpy.context.view_layer.objects.active = low
    for kind, btype in (("color", "DIFFUSE"), ("normal", "NORMAL"), ("roughness", "ROUGHNESS")):
        tnode.image = imgs[kind]
        if btype == "DIFFUSE":
            sc.render.bake.use_pass_direct = False
            sc.render.bake.use_pass_indirect = False
            sc.render.bake.use_pass_color = True
        bpy.ops.object.bake(type=btype)
        imgs[kind].filepath_raw = os.path.join(outdir, f"{key}_{kind}.png")
        imgs[kind].file_format = "PNG"
        imgs[kind].save()

    # rewire the low material to the baked maps for honest preview renders
    nt.nodes.remove(tnode)
    bsdf = nt.nodes["Principled BSDF"]
    c = nt.nodes.new("ShaderNodeTexImage"); c.image = imgs["color"]
    n = nt.nodes.new("ShaderNodeTexImage"); n.image = imgs["normal"]
    r = nt.nodes.new("ShaderNodeTexImage"); r.image = imgs["roughness"]
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(c.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(r.outputs["Color"], bsdf.inputs["Roughness"])
    nt.links.new(n.outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    high.hide_render = True
    high.hide_set(True)
    return low


def lathe_radial(R, zmin, zmax):
    """Turn a lathe profile R(z) (radius at height z, origin inside) into a radial
    function d -> distance to the surface along unit direction d (bisection)."""
    def inside(p):
        if p.z <= zmin or p.z >= zmax:
            return False
        return math.hypot(p.x, p.y) < R(p.z)

    def fn(d):
        lo, hi = 0.0, 3.0
        for _ in range(30):
            mid = (lo + hi) / 2
            if inside(d * mid):
                lo = mid
            else:
                hi = mid
        return lo
    return fn
