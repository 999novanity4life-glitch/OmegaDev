"""Moon Mop Co. terrain kit, built headless with Blender's Python module (bpy).

Usage (from games/moon-mop):  python art/blender/moon_kit.py [out_dir]
Writes one .fbx per piece plus preview renders and a tris.json budget report.

Units: 1 Blender unit = 1 Roblox stud, Z up in Blender (Roblox Y up after FBX import).
Every piece is original geometry generated from noise; nothing is copied from Moon Sweepers.
Budget: Roblox caps a single mesh at 20,000 triangles
(https://create.roblox.com/docs/art/modeling/specifications), so every export is checked.
"""
import bpy
import bmesh
import json
import math
import os
import random
import sys
from mathutils import Vector, noise

TRI_CAP = 20000
OUT = sys.argv[-1] if len(sys.argv) > 1 and not sys.argv[-1].endswith(".py") else os.path.join(os.path.dirname(__file__), "..", "export")
os.makedirs(OUT, exist_ok=True)

HEX_R = 8.0  # sector circumradius in studs (flat-to-flat 13.86); matches HexGrid in src/shared once built


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, color, rough=0.95, metal=0.0, emit=None):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1)
        b.inputs["Emission Strength"].default_value = 4.0
    return m


def fbm(p, octaves=5, lac=2.0, gain=0.5):
    amp, freq, total = 1.0, 1.0, 0.0
    for _ in range(octaves):
        total += amp * noise.noise(p * freq)
        amp *= gain
        freq *= lac
    return total


def tris(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def finish(obj, material):
    obj.data.materials.clear()
    obj.data.materials.append(material)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def hex_disc(name, radius, rings, seed, height, rough_amp, pile=0.0):
    """Subdivided flat-top hex with fbm displacement. pile>0 domes it like a dust drift."""
    bm = bmesh.new()
    verts = {}
    # axial-style triangular lattice inside a hex: rings*6 triangles per ring
    step = radius / rings
    pts = []
    for q in range(-rings, rings + 1):
        for r in range(max(-rings, -q - rings), min(rings, -q + rings) + 1):
            x = step * (q + r / 2.0)
            y = step * (r * math.sqrt(3) / 2.0)
            pts.append((q, r, x, y))
    off = Vector((seed * 13.1, seed * 7.7, seed * 3.3))
    for q, r, x, y in pts:
        d = math.hypot(x, y) / radius
        edge = max(0.0, 1.0 - d) ** 0.6
        z = height + fbm(Vector((x, y, 0)) * 0.35 + off) * rough_amp + pile * (1 - d * d)
        z *= edge if pile > 0 else 1.0
        verts[(q, r)] = bm.verts.new((x, y, z))
    for q, r, *_ in pts:
        for a, b in (((q + 1, r), (q, r + 1)), ((q + 1, r - 1), (q + 1, r))):
            if a in verts and b in verts:
                bm.faces.new((verts[(q, r)], verts[a], verts[b]))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def boulder(name, size, seed, subdiv=5, sharp=0.35):
    random.seed(seed)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=1)
    obj = bpy.context.active_object
    obj.name = name
    off = Vector((seed * 5.1, seed * 2.3, seed * 9.7))
    for v in obj.data.vertices:
        p = v.co.copy()
        n = fbm(p * 1.3 + off, 6)
        ridge = 1 - abs(noise.noise(p * 2.6 + off))
        v.co = p * (1 + 0.28 * n + sharp * 0.25 * ridge)
        v.co.z *= 0.62  # squat, sits in regolith
    obj.scale = (size, size * random.uniform(0.75, 1.1), size)
    bpy.ops.object.transform_apply(scale=True)
    obj.location.z = size * 0.25
    return obj


def crater_rim(name, radius, width, height, seed, seg=160, rad_seg=40):
    """A full crater: bowl floor, raised rim, falloff. Radial grid so tris = seg*rad_seg*2."""
    bm = bmesh.new()
    off = Vector((seed * 3.7, seed * 1.9, 0))
    outer = radius + width
    grid = []
    for j in range(rad_seg + 1):
        t = j / rad_seg
        rr = outer * t
        row = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            x, y = rr * math.cos(a), rr * math.sin(a)
            u = rr / radius
            if u < 1:  # bowl
                z = -height * 0.9 * (1 - u * u) + height * u ** 6
            else:  # rim falloff
                z = height * math.exp(-((u - 1) * radius / (width * 0.45)) ** 2)
            z += fbm(Vector((x, y, 0)) * 0.08 + off, 5) * height * 0.22
            z += fbm(Vector((x, y, 0)) * 0.6 + off, 3) * 0.25
            row.append(bm.verts.new((x, y, z)))
        grid.append(row)
    centre = bm.verts.new((0, 0, -height * 0.9))
    for i in range(seg):
        bm.faces.new((centre, grid[1][i], grid[1][(i + 1) % seg]))
    for j in range(1, rad_seg):
        for i in range(seg):
            a, b = grid[j][i], grid[j][(i + 1) % seg]
            c, d = grid[j + 1][(i + 1) % seg], grid[j + 1][i]
            bm.faces.new((a, b, c, d))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def export(obj, report):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    t = tris(obj)
    assert t <= TRI_CAP, f"{obj.name} has {t} tris, over the {TRI_CAP} cap"
    report[obj.name] = t
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(OUT, obj.name + ".fbx"), use_selection=True, apply_unit_scale=True,
        global_scale=1.0, axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_tspace=True,
    )


def build():
    reset()
    dust = mat("Regolith_Dusty", (0.43, 0.42, 0.40), 0.98)
    clean = mat("Regolith_Clean", (0.22, 0.22, 0.23), 0.85)
    rock = mat("Basalt", (0.30, 0.29, 0.28), 0.9)
    report = {}

    # Dust sector: the dirty layer on one hex. Cleaning hides/fades it.
    sector = finish(hex_disc("MM_DustSector", HEX_R, 56, 1, 0.25, 0.12, pile=0.35), dust)
    export(sector, report)
    # Dust sub-cell (1 of 19 per sector) for partial cleaning: a small drift.
    cell = finish(hex_disc("MM_DustCell", HEX_R / 4.2, 12, 2, 0.12, 0.05, pile=0.22), dust)
    export(cell, report)
    # Clean regolith hex top, shown once a sector is done.
    cleanhex = finish(hex_disc("MM_CleanSector", HEX_R, 40, 3, 0.0, 0.05), clean)
    export(cleanhex, report)
    # Boulders: three variants for reuse (one upload each, many copies).
    for k, s in enumerate((2.2, 4.0, 7.5)):
        export(finish(boulder(f"MM_Boulder{'ABC'[k]}", s, 10 + k), rock), report)
    # Crater, 30-stud bowl radius.
    export(finish(crater_rim("MM_Crater30", 30, 18, 6, 4), dust), report)
    return report


def preview(report):
    """Lay the pieces out and render one Cycles still per piece group."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 48
    scene.cycles.device = "CPU"
    scene.render.resolution_x, scene.render.resolution_y = 1600, 900
    world = bpy.data.worlds.new("Space")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.005, 0.006, 0.01, 1)
    scene.world = world
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 4.5
    sun.data.angle = math.radians(0.6)  # hard lunar shadows
    sun.rotation_euler = (math.radians(62), 0, math.radians(35))
    scene.collection.objects.link(sun)
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    objs = {o.name: o for o in scene.objects if o.type == "MESH"}
    layout = {"MM_Crater30": (0, 0, 0), "MM_DustSector": (-60, -40, 0), "MM_CleanSector": (-44, -48, 0),
              "MM_DustCell": (-52, -30, 0.3), "MM_BoulderA": (-30, -44, 0), "MM_BoulderB": (-22, -36, 0),
              "MM_BoulderC": (40, -10, 0)}
    for n, loc in layout.items():
        objs[n].location = loc
    cam.location = (-95, -105, 42)
    cam.data.lens = 40
    direction = Vector((-20, -20, 0)) - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(OUT, "preview_kit.png")
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    rep = build()
    json.dump(rep, open(os.path.join(OUT, "tris.json"), "w"), indent=2)
    print(json.dumps(rep, indent=2))
    preview(rep)
