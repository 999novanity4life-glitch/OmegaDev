"""Moon boulders: sculpted high-poly (~330k tris at subdivision 8) baked onto low-poly game meshes.

Usage (from games/moon-mop):  python art/blender/moon_rocks.py
Writes art/export/MM_Rock<A..D>.fbx (~2.5k tris each, well under Roblox's 20,000 cap,
https://create.roblox.com/docs/art/modeling/specifications) and per-rock 1024 maps in
art/textures/MM_Rock<X>_color/normal/roughness.png for a SurfaceAppearance.
Walkthrough reference (docs section 2b): dark rounded boulders sitting on pale dust,
e.g. on survey-site crater rims. All shapes are generated from noise.
"""
import bpy
import math
import os
from mathutils import Vector, noise

HERE = os.path.dirname(os.path.abspath(__file__))
EXPORT = os.path.join(HERE, "..", "export")
TEX = os.path.join(HERE, "..", "textures")
LOW_TRIS = 2400
RES = 1024


def fbm(p, octaves):
    a, f, t = 1.0, 1.0, 0.0
    for _ in range(octaves):
        t += a * noise.noise(p * f)
        a *= 0.5
        f *= 2.03
    return t


def sculpt(obj, seed, squash, facets):
    off = Vector((seed * 17.3, seed * 5.1, seed * 9.9))
    planes = [Vector((noise.noise(off + Vector((i, 0, 0))), noise.noise(off + Vector((0, i, 0))),
                      noise.noise(off + Vector((0, 0, i))))).normalized() for i in range(1, facets + 1)]
    for v in obj.data.vertices:
        p = v.co.normalized()
        r = 1.0 + 0.22 * fbm(p * 1.2 + off, 3)
        # Fractured faces: clip against a few random planes for flat chipped sides.
        for n in planes:
            r = min(r, 0.82 / max(p.dot(n), 0.05)) if p.dot(n) > 0.55 else r
        r += 0.035 * fbm(p * 7 + off, 4)                      # lumps
        r += 0.012 * (1 - abs(noise.noise(p * 22 + off)))     # cracks/ridges
        r -= 0.02 * max(0.0, noise.noise(p * 40 + off))       # pits (micro-craters)
        v.co = p * r
        v.co.z *= squash


def make_rock(name, seed, squash, facets, size):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=8, radius=1)
    hi = bpy.context.active_object
    hi.name = name + "_hi"
    sculpt(hi, seed, squash, facets)
    hi.scale = (size, size * 0.85, size)
    bpy.ops.object.transform_apply(scale=True)
    # Sit on the ground: lowest point at z = -0.15*size so it reads as half-buried.
    zmin = min(v.co.z for v in hi.data.vertices)
    for v in hi.data.vertices:
        v.co.z -= zmin + 0.15 * size
    lo = hi.copy()
    lo.data = hi.data.copy()
    lo.name = name
    bpy.context.scene.collection.objects.link(lo)
    dec = lo.modifiers.new("dec", "DECIMATE")
    dec.ratio = LOW_TRIS / len(hi.data.polygons)
    bpy.context.view_layer.objects.active = lo
    bpy.ops.object.modifier_apply(modifier="dec")
    for poly in lo.data.polygons:
        poly.use_smooth = True
    bpy.ops.object.select_all(action="DESELECT")
    lo.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.01)
    bpy.ops.object.mode_set(mode="OBJECT")
    return hi, lo


def bake(hi, lo, name):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 16
    imgs = {}
    mat = bpy.data.materials.new(name + "_bake")
    mat.use_nodes = True
    lo.data.materials.clear()
    lo.data.materials.append(mat)
    nt = mat.node_tree
    for kind in ("normal", "ao"):
        img = bpy.data.images.new(f"{name}_{kind}", RES, RES)
        img.colorspace_settings.name = "Non-Color"
        imgs[kind] = img
    node = nt.nodes.new("ShaderNodeTexImage")
    nt.nodes.active = node
    bpy.ops.object.select_all(action="DESELECT")
    hi.select_set(True)
    lo.select_set(True)
    bpy.context.view_layer.objects.active = lo
    bk = sc.render.bake
    bk.use_selected_to_active = True
    bk.cage_extrusion = 0.08 * max(lo.dimensions)
    bk.margin = 8
    node.image = imgs["normal"]
    bpy.ops.object.bake(type="NORMAL", normal_space="TANGENT")
    node.image = imgs["ao"]
    bpy.ops.object.bake(type="AO")
    return imgs


def write_maps(name, imgs, seed):
    import numpy as np
    from PIL import Image
    nrm = np.array(imgs["normal"].pixels[:]).reshape(RES, RES, 4)[::-1, :, :3]
    ao = np.array(imgs["ao"].pixels[:]).reshape(RES, RES, 4)[::-1, :, 0]
    rng = np.random.default_rng(seed)
    grain = rng.normal(0, 1, (RES, RES))
    base = np.array([68, 66, 72], float)  # dark grey basalt with a faint violet cast
    shade = 0.55 + 0.45 * ao + grain * 0.03
    color = np.clip(base[None, None, :] * shade[..., None] * 1.15, 0, 255).astype(np.uint8)
    rough = np.clip(0.78 + 0.15 * (1 - ao) + grain * 0.02, 0, 1)
    Image.fromarray((nrm * 255).astype(np.uint8)).save(os.path.join(TEX, f"{name}_normal.png"))
    Image.fromarray(color).save(os.path.join(TEX, f"{name}_color.png"))
    Image.fromarray((rough * 255).astype(np.uint8)).save(os.path.join(TEX, f"{name}_roughness.png"))


def export(lo):
    bpy.ops.object.select_all(action="DESELECT")
    lo.select_set(True)
    bpy.context.view_layer.objects.active = lo
    bpy.ops.export_scene.fbx(filepath=os.path.join(EXPORT, lo.name + ".fbx"), use_selection=True,
                             axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_tspace=True)


if __name__ == "__main__":
    os.makedirs(EXPORT, exist_ok=True)
    os.makedirs(TEX, exist_ok=True)
    report = {}
    specs = [("MM_RockA", 3, 0.6, 3, 2.0), ("MM_RockB", 11, 0.75, 4, 3.5),
             ("MM_RockC", 23, 0.55, 5, 6.0), ("MM_RockD", 31, 0.9, 2, 1.2)]
    for name, seed, squash, facets, size in specs:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        hi, lo = make_rock(name, seed, squash, facets, size)
        imgs = bake(hi, lo, name)
        write_maps(name, imgs, seed)
        lo.data.calc_loop_triangles()
        hi.data.calc_loop_triangles()
        t = len(lo.data.loop_triangles)
        assert t <= 20000, (name, t)
        report[name] = {"tris": t, "baked_from": len(hi.data.loop_triangles)}
        export(lo)
        print(name, report[name])
    import json
    json.dump(report, open(os.path.join(EXPORT, "rocks.json"), "w"), indent=2)
