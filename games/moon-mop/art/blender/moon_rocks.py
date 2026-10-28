"""Moon boulders, v2: realistic weathered breccia, sculpted high-poly and baked to game meshes.

Usage (from games/moon-mop):  python art/blender/moon_rocks.py [--preview-only]
Writes art/export/MM_Rock<A..E>.fbx (5,120 tris each; Roblox caps a mesh at 20,000,
https://create.roblox.com/docs/art/modeling/specifications) and 1024 px maps per rock in
art/textures/MM_Rock<X>_color/normal/roughness.png for a SurfaceAppearance
(tangent-space OpenGL normals, https://create.roblox.com/docs/art/modeling/texture-specifications).

How the look is made (all procedural, nothing copied):
- Shape: a convex fracture chunk (soft-min of random cutting planes, so edges are rounded by
  weathering), eroded by fBm, with chipped facets, cracks and micro-impact pits.
- Base: a flared skirt so the rock sits half-buried in dust instead of on top of it.
- Albedo: dark basaltic matrix with lighter angular clasts (breccia), fine speckle, edges a little
  lighter and cavities darker (from mesh curvature), and pale regolith dust settled on
  up-facing surfaces and the buried skirt. Roughness follows: dust is matte, fresh faces less so.
All of that is baked from the high-poly shader onto the low-poly UVs (diffuse colour, roughness,
normal and AO), so Roblox gets the full detail at game cost.
"""
import bpy
import json
import math
import os
import random
import sys
from mathutils import Vector, noise

HERE = os.path.dirname(os.path.abspath(__file__))
EXPORT = os.path.join(HERE, "..", "export")
TEX = os.path.join(HERE, "..", "textures")
LOW_SUBDIV = 5  # icosphere level 5 = 5,120 tris per rock
RES = 1024


def fbm(p, octaves, lac=2.07):
    a, f, t = 1.0, 1.0, 0.0
    for _ in range(octaves):
        t += a * noise.noise(p * f)
        a *= 0.5
        f *= lac
    return t


def softmin(values, k):
    """Smooth minimum: like min() but rounds the corners where planes meet."""
    m = min(values)
    s = sum(math.exp(-(v - m) / k) for v in values)
    return m - k * math.log(s)


def sculpt(obj, seed, n_planes, squash, roundness, detail=True):
    """Same seed gives the same big shape; detail=False is the game mesh, True the bake source."""
    rng = random.Random(seed)
    off = Vector((seed * 17.3, seed * 5.1, seed * 9.9))
    planes = []
    for _ in range(n_planes):
        n = Vector((rng.gauss(0, 1), rng.gauss(0, 1), rng.gauss(0, 1) * 0.7)).normalized()
        planes.append((n, rng.uniform(0.6, 0.92)))
    # A couple of real fractures: narrow V-grooves along random planes, fading in and out.
    cracks = []
    for _ in range(rng.randint(1, 3)):
        n = Vector((rng.gauss(0, 1), rng.gauss(0, 1), rng.gauss(0, 1))).normalized()
        cracks.append((n, rng.uniform(-0.35, 0.35)))
    for v in obj.data.vertices:
        p = v.co.normalized()
        # Distance to each cutting plane along this ray; the rock surface is the nearest one.
        dists = [d / p.dot(n) for n, d in planes if p.dot(n) > 0.08]
        dists.append(1.1)
        r = softmin(dists, roundness)
        q = p * r
        r += 0.05 * fbm(q * 1.4 + off, 3)                         # large erosion
        if detail:
            r += 0.02 * fbm(q * 5.0 + off, 5)                    # lumps and chipped facets
            r += 0.007 * fbm(q * 22 + off, 3)                     # grain
            for n, d in cracks:
                w = abs(q.dot(n) - d)
                if w < 0.016:
                    fade = max(0.0, noise.noise(q * 5 + n * 7))  # crack only runs part way
                    r -= 0.022 * (1 - w / 0.016) * min(1.0, fade * 2)
            pit = noise.noise(q * 30 + off * 2)
            r -= 0.016 * max(0.0, pit - 0.4) / 0.6                # small vesicles and impact pits
            pit2 = noise.noise(q * 70 + off * 3)
            r -= 0.006 * max(0.0, pit2 - 0.35) / 0.65
        v.co = p * r
        v.co.z *= squash


def add_skirt(obj, size):
    """Flare the lowest vertices outward and flatten them: the dust fillet round a buried rock."""
    zmin = min(v.co.z for v in obj.data.vertices)
    zmax = max(v.co.z for v in obj.data.vertices)
    h = zmax - zmin
    for v in obj.data.vertices:
        t = (v.co.z - zmin) / h
        if t < 0.22:
            k = (0.22 - t) / 0.22
            flat = Vector((v.co.x, v.co.y, 0))
            v.co.x += flat.x * 0.35 * k * k
            v.co.y += flat.y * 0.35 * k * k
            v.co.z = zmin + (v.co.z - zmin) * (1 - 0.6 * k)
    # Sink: about a fifth of the height below ground.
    for v in obj.data.vertices:
        v.co.z -= zmin + 0.2 * h


def rock_material(seed):
    """High-poly look shader: breccia + edge wear + settled dust. Baked to textures."""
    m = bpy.data.materials.new(f"rockhi_{seed}")
    m.use_nodes = True
    nt = m.node_tree
    N = nt.nodes
    L = nt.links
    bsdf = N["Principled BSDF"]
    tc = N.new("ShaderNodeTexCoord")
    geo = N.new("ShaderNodeNewGeometry")
    mapn = N.new("ShaderNodeMapping")
    mapn.inputs["Location"].default_value = (seed * 3.1, seed * 1.7, seed * 0.9)
    L.new(tc.outputs["Object"], mapn.inputs["Vector"])

    def noise_tex(scale, detail, rough=0.55):
        n = N.new("ShaderNodeTexNoise")
        n.inputs["Scale"].default_value = scale
        n.inputs["Detail"].default_value = detail
        n.inputs["Roughness"].default_value = rough
        L.new(mapn.outputs["Vector"], n.inputs["Vector"])
        return n

    def ramp(src, stops):
        r = N.new("ShaderNodeValToRGB")
        cr = r.color_ramp
        cr.elements[0].position, cr.elements[0].color = stops[0]
        cr.elements[1].position, cr.elements[1].color = stops[-1]
        for pos, col in stops[1:-1]:
            e = cr.elements.new(pos)
            e.color = col
        L.new(src, r.inputs["Fac"])
        return r

    def rgb(c):
        n = N.new("ShaderNodeRGB")
        n.outputs[0].default_value = c
        return n.outputs[0]

    def value(v):
        n = N.new("ShaderNodeValue")
        n.outputs[0].default_value = v
        return n.outputs[0]

    def mix(a, b, fac, blend="MIX"):
        mx = N.new("ShaderNodeMix")
        mx.data_type = "RGBA"
        mx.blend_type = blend
        L.new(fac, mx.inputs["Factor"])
        L.new(a, mx.inputs[6])
        L.new(b, mx.inputs[7])
        return mx.outputs[2]

    # Matrix: dark basalt with soft mottling.
    mott = noise_tex(2.2, 6)
    base = ramp(mott.outputs["Fac"], [(0.3, (0.085, 0.082, 0.088, 1)), (0.7, (0.17, 0.165, 0.175, 1))])
    # Clasts: angular lighter inclusions (Voronoi cells, thresholded).
    vor = N.new("ShaderNodeTexVoronoi")
    vor.inputs["Scale"].default_value = 11.0
    vor.inputs["Randomness"].default_value = 1.0
    vor.feature = "F1"
    vor.distance = "CHEBYCHEV"  # boxy cells read as broken, angular fragments
    warp = noise_tex(4, 2)
    wmix = N.new("ShaderNodeMix")
    wmix.data_type = "VECTOR"
    wmix.inputs["Factor"].default_value = 0.12
    L.new(mapn.outputs["Vector"], wmix.inputs[4])
    L.new(warp.outputs["Color"], wmix.inputs[5])
    L.new(wmix.outputs[1], vor.inputs["Vector"])
    cl_noise = noise_tex(5, 3)
    cl_mask = ramp(vor.outputs["Distance"], [(0.0, (1, 1, 1, 1)), (0.12, (1, 1, 1, 1)), (0.135, (0, 0, 0, 1))])
    cl_sel = ramp(cl_noise.outputs["Fac"], [(0.55, (0, 0, 0, 1)), (0.6, (1, 1, 1, 1))])
    clast_fac = N.new("ShaderNodeMath")
    clast_fac.operation = "MULTIPLY"
    L.new(cl_mask.outputs["Color"], clast_fac.inputs[0])
    L.new(cl_sel.outputs["Color"], clast_fac.inputs[1])
    col = mix(base.outputs["Color"], rgb((0.3, 0.295, 0.305, 1)), clast_fac.outputs[0])
    # Fine speckle.
    spk = noise_tex(140, 2, 0.8)
    spk_r = ramp(spk.outputs["Fac"], [(0.62, (0, 0, 0, 1)), (0.7, (1, 1, 1, 1))])
    col = mix(col, rgb((0.5, 0.49, 0.5, 1)), spk_r.outputs["Color"])
    # Edge wear and cavity dirt from curvature (Cycles "pointiness").
    pt = ramp(geo.outputs["Pointiness"], [(0.46, (0.55, 0.55, 0.55, 1)), (0.5, (0.5, 0.5, 0.5, 1)), (0.56, (0.85, 0.85, 0.85, 1))])
    col = mix(col, pt.outputs["Color"], value(0.45), "OVERLAY")
    # Settled dust: up-facing normals plus a noisy edge, and the buried skirt.
    sep = N.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["Normal"], sep.inputs["Vector"])
    dn = noise_tex(9, 5)
    up = N.new("ShaderNodeMath")
    up.operation = "ADD"
    L.new(sep.outputs["Z"], up.inputs[0])
    L.new(dn.outputs["Fac"], up.inputs[1])
    dust_top = ramp(up.outputs["Value"], [(1.18, (0, 0, 0, 1)), (1.32, (1, 1, 1, 1))])
    sepp = N.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["Position"], sepp.inputs["Vector"])
    lowz = N.new("ShaderNodeMath")
    lowz.operation = "ADD"
    L.new(sepp.outputs["Z"], lowz.inputs[0])
    L.new(dn.outputs["Fac"], lowz.inputs[1])
    dust_low = ramp(lowz.outputs["Value"], [(0.35, (1, 1, 1, 1)), (0.65, (0, 0, 0, 1))])
    dmax = N.new("ShaderNodeMath")
    dmax.operation = "MAXIMUM"
    L.new(dust_top.outputs["Color"], dmax.inputs[0])
    L.new(dust_low.outputs["Color"], dmax.inputs[1])
    dust_col = N.new("ShaderNodeRGB")
    dust_col.outputs[0].default_value = (0.6, 0.59, 0.63, 1)
    col = mix(col, dust_col.outputs[0], dmax.outputs[0])
    L.new(col, bsdf.inputs["Base Color"])
    # Roughness: rock 0.72-0.82, dust 0.97.
    rr = ramp(mott.outputs["Fac"], [(0.3, (0.72, 0.72, 0.72, 1)), (0.7, (0.84, 0.84, 0.84, 1))])
    rough = mix(rr.outputs["Color"], rgb((0.97, 0.97, 0.97, 1)), dmax.outputs[0])
    L.new(rough, bsdf.inputs["Roughness"])
    return m


def make_rock(name, seed, planes, squash, roundness, size):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=8, radius=1)
    hi = bpy.context.active_object
    hi.name = name + "_hi"
    sculpt(hi, seed, planes, squash, roundness)
    hi_scale = (size, size * random.Random(seed).uniform(0.75, 0.95), size)
    hi.scale = hi_scale
    bpy.ops.object.transform_apply(scale=True)
    add_skirt(hi, size)
    for p in hi.data.polygons:
        p.use_smooth = True
    hi.data.materials.append(rock_material(seed))
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=LOW_SUBDIV, radius=1)
    lo = bpy.context.active_object
    lo.name = name
    sculpt(lo, seed, planes, squash, roundness, detail=False)
    lo.scale = hi_scale
    bpy.ops.object.transform_apply(scale=True)
    add_skirt(lo, size)
    for p in lo.data.polygons:
        p.use_smooth = True
    bpy.ops.object.select_all(action="DESELECT")
    lo.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.006, area_weight=1.0)
    bpy.ops.uv.pack_islands(margin=0.004)
    bpy.ops.object.mode_set(mode="OBJECT")
    return hi, lo


def bake_maps(hi, lo, name):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 24
    bk = sc.render.bake
    bk.use_selected_to_active = True
    bk.cage_extrusion = 0.06 * max(lo.dimensions)
    bk.max_ray_distance = 0.12 * max(lo.dimensions)
    bk.margin = 12
    m = bpy.data.materials.new(name + "_bake")
    m.use_nodes = True
    lo.data.materials.append(m)
    node = m.node_tree.nodes.new("ShaderNodeTexImage")
    m.node_tree.nodes.active = node
    imgs = {}

    def run(kind, btype, color_space, **kw):
        img = bpy.data.images.new(f"{name}_{kind}", RES, RES)
        img.colorspace_settings.name = color_space
        node.image = img
        bpy.ops.object.select_all(action="DESELECT")
        hi.select_set(True)
        lo.select_set(True)
        bpy.context.view_layer.objects.active = lo
        bpy.ops.object.bake(type=btype, **kw)
        imgs[kind] = img

    run("normal", "NORMAL", "Non-Color", normal_space="TANGENT")
    run("ao", "AO", "Non-Color")
    bk.use_pass_direct = False
    bk.use_pass_indirect = False
    bk.use_pass_color = True
    run("albedo", "DIFFUSE", "sRGB", pass_filter={"COLOR"})
    run("rough", "ROUGHNESS", "Non-Color")
    return imgs


def write_maps(name, imgs):
    import numpy as np
    from PIL import Image

    def arr(img, ch=None):
        a = np.array(img.pixels[:]).reshape(RES, RES, 4)[::-1]
        return a[:, :, :3] if ch is None else a[:, :, ch]

    alb = arr(imgs["albedo"])
    ao = arr(imgs["ao"], 0)
    # Albedo is baked linear-to-sRGB by Blender already; fold in a gentle AO so crevices hold shadow
    # even under Roblox's flat ambient.
    color = np.clip(alb * (0.45 + 0.55 * ao[..., None]), 0, 1)
    Image.fromarray((color * 255).astype(np.uint8)).save(os.path.join(TEX, f"{name}_color.png"))
    Image.fromarray((arr(imgs["normal"]) * 255).astype(np.uint8)).save(os.path.join(TEX, f"{name}_normal.png"))
    Image.fromarray((np.clip(arr(imgs["rough"], 0), 0, 1) * 255).astype(np.uint8)).save(
        os.path.join(TEX, f"{name}_roughness.png"))


def export(lo):
    lo.data.materials.clear()
    bpy.ops.object.select_all(action="DESELECT")
    lo.select_set(True)
    bpy.context.view_layer.objects.active = lo
    bpy.ops.export_scene.fbx(filepath=os.path.join(EXPORT, lo.name + ".fbx"), use_selection=True,
                             axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_tspace=True)


SPECS = [  # name, seed, cutting planes, squash, roundness, size (studs)
    ("MM_RockA", 3, 11, 0.66, 0.025, 2.2),
    ("MM_RockB", 11, 9, 0.8, 0.035, 3.8),
    ("MM_RockC", 23, 13, 0.6, 0.025, 6.5),
    ("MM_RockD", 31, 8, 0.85, 0.045, 1.3),
    ("MM_RockE", 47, 15, 0.5, 0.02, 9.0),  # big flat-topped slab for crater rims
]

if __name__ == "__main__":
    os.makedirs(EXPORT, exist_ok=True)
    os.makedirs(TEX, exist_ok=True)
    report = {}
    for name, seed, planes, squash, rnd, size in SPECS:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        hi, lo = make_rock(name, seed, planes, squash, rnd, size)
        imgs = bake_maps(hi, lo, name)
        write_maps(name, imgs)
        lo.data.calc_loop_triangles()
        hi.data.calc_loop_triangles()
        t = len(lo.data.loop_triangles)
        assert t <= 20000, (name, t)
        report[name] = {"tris": t, "baked_from": len(hi.data.loop_triangles)}
        export(lo)
        print(name, report[name], flush=True)
    json.dump(report, open(os.path.join(EXPORT, "rocks.json"), "w"), indent=2)
