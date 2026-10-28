"""Moon Mop Co. station tower (our own design, after the walkthrough notes in docs section 2b):
an octagonal white panelled tower with vertical blue glass strips, a thin orange pinstripe,
black louvred vents, round orange-framed belt hatches at ground level, a front door with a red
status light, and a concrete apron. Built from beveled primitives, one mesh per material group
("MM_Station__White" etc.) so the game can apply shared SurfaceAppearances.

Usage (from games/moon-mop):  python art/blender/moon_station.py
1 Blender unit = 1 stud. The tower is ~26 studs across and ~34 tall.
Each group must stay under Roblox's 20,000-triangle mesh cap
(https://create.roblox.com/docs/art/modeling/specifications).
"""
import bpy
import bmesh
import json
import math
import os
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
EXPORT = os.path.join(HERE, "..", "export")
PIECE = "MM_Station"
COLORS = {
    "White": (0.86, 0.87, 0.89, 1), "Panel": (0.74, 0.76, 0.79, 1), "Glass": (0.12, 0.42, 0.85, 1),
    "Orange": (1.0, 0.38, 0.05, 1), "Dark": (0.05, 0.055, 0.065, 1), "Concrete": (0.42, 0.42, 0.44, 1),
    "Glow": (1.0, 0.1, 0.05, 1), "Metal": (0.6, 0.62, 0.66, 1),
}
parts = {g: [] for g in COLORS}


def mat(group):
    m = bpy.data.materials.get("ST_" + group)
    if m is None:
        m = bpy.data.materials.new("ST_" + group)
        m.use_nodes = True
        b = m.node_tree.nodes["Principled BSDF"]
        b.inputs["Base Color"].default_value = COLORS[group]
        b.inputs["Roughness"].default_value = {"Glass": 0.08, "Metal": 0.3, "Orange": 0.4}.get(group, 0.55)
        b.inputs["Metallic"].default_value = 1.0 if group == "Metal" else 0.0
        if group in ("Glow",):
            b.inputs["Emission Color"].default_value = COLORS[group]
            b.inputs["Emission Strength"].default_value = 8
        if group == "Glass":
            b.inputs["Emission Color"].default_value = (0.2, 0.55, 1.0, 1)
            b.inputs["Emission Strength"].default_value = 0.6
    return m


def bevel(obj, w, seg=2):
    if w <= 0:
        return
    md = obj.modifiers.new("b", "BEVEL")
    md.width = w
    md.segments = seg
    md.limit_method = "ANGLE"
    md.harden_normals = True


def add(group, obj, bw=0.0, seg=2):
    bevel(obj, bw, seg)
    obj.data.materials.clear()
    obj.data.materials.append(mat(group))
    parts[group].append(obj)
    return obj


def box(group, size, loc, rot_z=0.0, bw=0.08, seg=2):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=(0, 0, rot_z))
    o = bpy.context.active_object
    o.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return add(group, o, min(bw, min(size) * 0.45), seg)


def cyl(group, r, depth, loc, rot=(0, 0, 0), verts=32, bw=0.05):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc, rotation=rot, vertices=verts)
    return add(group, bpy.context.active_object, bw)


def torus(group, R, r, loc, rot=(0, 0, 0), maj=40, mn=10):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, location=loc, rotation=rot,
                                     major_segments=maj, minor_segments=mn)
    return add(group, bpy.context.active_object)


def prism(group, radius, height, z0, sides=8, bw=0.15):
    """Octagonal ring section (outer wall) as a solid prism, flat side facing -Y."""
    bpy.ops.mesh.primitive_cylinder_add(vertices=sides, radius=radius, depth=height,
                                        location=(0, 0, z0 + height / 2), rotation=(0, 0, math.pi / sides))
    return add(group, bpy.context.active_object, bw, 3)


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    R = 13.0           # circumradius of the octagon
    apothem = R * math.cos(math.pi / 8)
    side = 2 * R * math.sin(math.pi / 8)
    # Concrete apron and plinth with steps at the front.
    prism("Concrete", R + 6, 0.8, 0, bw=0.2)
    prism("Concrete", R + 1.5, 1.4, 0.8, bw=0.15)
    for i in range(3):
        box("Concrete", (8, 1.2, 0.47 * (i + 1)), (0, -(apothem + 2.6 - i * 1.0), 0.8 + 0.235 * (i + 1)), bw=0.06)
    # Tower body: three stacked octagonal tiers, the top one set back.
    tiers = [(R, 2.2, 12), (R - 0.6, 14.2, 11), (R - 2.8, 25.2, 7)]
    for rad, z0, h in tiers:
        prism("White", rad, h, z0)
        prism("Orange", rad + 0.08, 0.18, z0 + h - 1.2, bw=0.02)          # pinstripe
        prism("Dark", rad + 0.12, 0.35, z0, bw=0.03)                      # shadow seam between tiers
    prism("Panel", R - 3.4, 1.0, 32.2, bw=0.2)                            # roof cap
    cyl("Metal", 0.25, 4, (3, 2, 34.7), verts=12)                         # antenna mast
    cyl("Glow", 0.32, 0.4, (3, 2, 36.8), verts=12)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=2.2, location=(-3, -1, 34.2), segments=32, ring_count=16)
    add("Panel", bpy.context.active_object)                                # dish/radome
    # Per-face details on the 8 sides.
    for k in range(8):
        ang = -math.pi / 2 + k * math.pi / 4      # k=0 faces -Y (front)
        n = Vector((math.cos(ang), math.sin(ang), 0))
        t = Vector((-n.y, n.x, 0))
        rot = ang + math.pi / 2
        for ti, (rad, z0, h) in enumerate(tiers[:2]):
            if k == 0 and ti == 0:
                continue  # the door takes the front of the ground tier
            ap = rad * math.cos(math.pi / 8)
            # vertical glass strips (two per face) and recessed panel seams
            for s in (-0.28, 0.28):
                p = n * (ap + 0.06) + t * (s * side)
                box("Glass", (0.9, 0.2, h - 3.0), (p.x, p.y, z0 + h / 2 - 0.2), rot, bw=0.05)
                box("Dark", (1.15, 0.14, h - 2.7), (p.x - n.x * 0.04, p.y - n.y * 0.04, z0 + h / 2 - 0.2), rot, bw=0.03)
            for zz in (z0 + 3.5, z0 + h - 3.0):
                p = n * (ap + 0.04)
                box("Panel", (side * 0.92, 0.1, 0.12), (p.x, p.y, zz), rot, bw=0.02)
        if k == 0:
            continue  # front face holds the door
        # louvred vent block on upper tier
        ap2 = tiers[2][0] * math.cos(math.pi / 8)
        base = n * (ap2 + 0.1)
        box("Dark", (side * 0.5, 0.3, 2.6), (base.x, base.y, 28.6), rot, bw=0.05)
        for j in range(6):
            q = n * (ap2 + 0.32)
            box("Metal", (side * 0.46, 0.12, 0.12), (q.x, q.y, 27.6 + j * 0.4), rot, bw=0.03)
        # ground-level belt hatches on alternate faces: rounded square, orange frame, dark mouth
        if k % 2 == 0:
            ap0 = tiers[0][0] * math.cos(math.pi / 8)
            q = n * (ap0 + 0.15)
            bpy.ops.mesh.primitive_cube_add(size=1, location=(q.x, q.y, 4.8), rotation=(0, 0, rot))
            o = bpy.context.active_object
            o.scale = (3.6, 0.5, 3.6)
            bpy.ops.object.transform_apply(scale=True)
            add("Orange", o, 0.9, 6)
            q2 = n * (ap0 + 0.3)
            bpy.ops.mesh.primitive_cube_add(size=1, location=(q2.x, q2.y, 4.8), rotation=(0, 0, rot))
            o = bpy.context.active_object
            o.scale = (2.8, 0.5, 2.8)
            bpy.ops.object.transform_apply(scale=True)
            add("Dark", o, 0.7, 6)
    # Front door: dark portal, double door with blue slits, red light, sign plaque.
    ap0 = tiers[0][0] * math.cos(math.pi / 8)
    box("Dark", (6.4, 0.6, 8.0), (0, -(ap0 + 0.1), 6.2), bw=0.3)
    box("Panel", (2.5, 0.3, 6.6), (-1.3, -(ap0 + 0.35), 5.6), bw=0.08)
    box("Panel", (2.5, 0.3, 6.6), (1.3, -(ap0 + 0.35), 5.6), bw=0.08)
    for x in (-1.3, 1.3):
        box("Glass", (0.35, 0.1, 3.6), (x, -(ap0 + 0.52), 6.2), bw=0.03)
    cyl("Glow", 0.35, 0.3, (0, -(ap0 + 0.5), 10.6), rot=(math.pi / 2, 0, 0), verts=16)
    box("Orange", (7.0, 0.3, 0.3), (0, -(ap0 + 0.3), 10.0), bw=0.05)
    box("White", (4.2, 0.25, 1.6), (0, -(ap0 + 0.45), 12.6), bw=0.1)       # sign plaque (decal goes here)
    # Light poles on the apron corners.
    for k in range(4):
        ang = math.pi / 4 + k * math.pi / 2
        p = Vector((math.cos(ang), math.sin(ang), 0)) * (R + 4.5)
        cyl("Metal", 0.18, 6, (p.x, p.y, 3.8), verts=12)
        box("Dark", (0.8, 0.5, 0.35), (p.x, p.y, 6.9), bw=0.05)
        box("Glow", (0.6, 0.35, 0.08), (p.x, p.y, 6.7), bw=0.0)


def join_and_export():
    report = {}
    os.makedirs(EXPORT, exist_ok=True)
    for group, objs in parts.items():
        if not objs:
            continue
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
            bpy.context.view_layer.objects.active = o
            for md in list(o.modifiers):
                bpy.ops.object.modifier_apply(modifier=md.name)
        bpy.context.view_layer.objects.active = objs[0]
        bpy.ops.object.join()
        o = bpy.context.active_object
        o.name = f"{PIECE}__{group}"
        for p in o.data.polygons:
            p.use_smooth = True
        o.data.calc_loop_triangles()
        t = len(o.data.loop_triangles)
        assert t <= 20000, (o.name, t)
        report[o.name] = t
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.ops.export_scene.fbx(filepath=os.path.join(EXPORT, o.name + ".fbx"), use_selection=True,
                                 axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_tspace=True)
    json.dump(report, open(os.path.join(EXPORT, "station.json"), "w"), indent=2)
    print(json.dumps(report, indent=2), "total", sum(report.values()))


def preview():
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 64
    sc.render.resolution_x, sc.render.resolution_y = 1600, 1000
    w = bpy.data.worlds.new("w")
    sc.world = w
    bpy.ops.mesh.primitive_plane_add(size=200)
    g = bpy.context.active_object
    gm = bpy.data.materials.new("ground")
    gm.use_nodes = True
    gm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.7, 0.69, 0.74, 1)
    g.data.materials.append(gm)
    sun = bpy.data.objects.new("s", bpy.data.lights.new("s", "SUN"))
    sun.data.energy = 4.5
    sun.data.angle = math.radians(0.5)
    sun.rotation_euler = (math.radians(55), 0, math.radians(-35))
    sc.collection.objects.link(sun)
    cam = bpy.data.objects.new("c", bpy.data.cameras.new("c"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam.location = (-44, -70, 22)
    cam.data.lens = 38
    cam.rotation_euler = (Vector((0, 0, 16)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(EXPORT, "preview_station.png")
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    build()
    join_and_export()
    preview()
