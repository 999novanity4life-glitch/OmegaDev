"""Moon Mop Co. props, our own designs after the walkthrough notes (docs section 2b):
- MM_DustHex: the raised dust layer for one hex sector (circumradius 20 studs), with a soft lip
  so the cleaned edge reads as a small step down. Planar UVs at 10 studs per tile.
- MM_SurveyCrater: shallow crater with a raised rim and a pale glowing floor disc.
- MM_Capsule: waist-high dust canister (white body, orange rims, grey windows, cyan fill pips).
- MM_DepositDrum: orange ring hood round a black grille drum on a dark plinth, with a console.
One mesh per material group ("<Piece>__<Group>"), each under Roblox's 20,000-triangle cap
(https://create.roblox.com/docs/art/modeling/specifications). 1 Blender unit = 1 stud.

Usage (from games/moon-mop):  python art/blender/moon_props.py
"""
import bpy
import bmesh
import json
import math
import os
from mathutils import Vector, noise

HERE = os.path.dirname(os.path.abspath(__file__))
EXPORT = os.path.join(HERE, "..", "export")
HEX_R = 20.0
TILE = 10.0
COLORS = {
    "Dust": (0.86, 0.85, 0.89, 1), "Ground": (0.66, 0.65, 0.7, 1), "Glow": (1.0, 0.86, 0.6, 1),
    "White": (0.88, 0.89, 0.9, 1), "Orange": (1.0, 0.38, 0.05, 1), "Dark": (0.05, 0.055, 0.065, 1),
    "Grey": (0.45, 0.46, 0.5, 1), "Cyan": (0.1, 0.95, 1.0, 1), "Screen": (0.1, 0.35, 0.9, 1),
}
EMISSIVE = {"Glow": 1.5, "Cyan": 6, "Screen": 2}
pieces = {}


def mat(g):
    m = bpy.data.materials.get("P_" + g)
    if m:
        return m
    m = bpy.data.materials.new("P_" + g)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = COLORS[g]
    b.inputs["Roughness"].default_value = 0.95 if g in ("Dust", "Ground") else 0.45
    if g in EMISSIVE:
        b.inputs["Emission Color"].default_value = COLORS[g]
        b.inputs["Emission Strength"].default_value = EMISSIVE[g]
    return m


def put(piece, g, o, bw=0.0, seg=2):
    if bw > 0:
        md = o.modifiers.new("b", "BEVEL")
        md.width, md.segments, md.limit_method = bw, seg, "ANGLE"
        md.harden_normals = True
    o.data.materials.clear()
    o.data.materials.append(mat(g))
    pieces.setdefault(piece, {}).setdefault(g, []).append(o)
    return o


def cyl(piece, g, r, d, loc, rot=(0, 0, 0), v=32, bw=0.03):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=d, location=loc, rotation=rot, vertices=v)
    return put(piece, g, bpy.context.active_object, bw)


def box(piece, g, size, loc, rz=0.0, bw=0.04):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=(0, 0, rz))
    o = bpy.context.active_object
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    return put(piece, g, o, min(bw, min(size) * 0.45))


def torus(piece, g, R, r, loc, rot=(0, 0, 0), maj=48, mn=12):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, location=loc, rotation=rot,
                                     major_segments=maj, minor_segments=mn)
    return put(piece, g, bpy.context.active_object)


def planar_uv(o):
    me = o.data
    uv = me.uv_layers.new(name="UVMap")
    for loop in me.loops:
        co = me.vertices[loop.vertex_index].co
        uv.data[loop.index].uv = (co.x / TILE, co.y / TILE)


def dust_hex():
    """Hex top on a triangular lattice + a sloped lip ring down to z=0."""
    rings, lip = 10, 0.6
    bm = bmesh.new()
    step = (HEX_R - lip) / rings
    grid = {}
    for q in range(-rings, rings + 1):
        for r in range(max(-rings, -q - rings), min(rings, -q + rings) + 1):
            x = step * (q + r / 2)
            y = step * r * math.sqrt(3) / 2
            z = 0.35 + 0.05 * noise.noise(Vector((x, y, 0)) * 0.2)
            grid[(q, r)] = bm.verts.new((x, y, z))
    for (q, r), v in grid.items():
        for a, b in (((q + 1, r), (q, r + 1)), ((q + 1, r - 1), (q + 1, r))):
            if a in grid and b in grid:
                bm.faces.new((v, grid[a], grid[b]))
    # Lip: walk the boundary ring of the lattice and extrude outward/down.
    bm.edges.ensure_lookup_table()
    boundary = [e for e in bm.edges if e.is_boundary]
    ret = bmesh.ops.extrude_edge_only(bm, edges=boundary)
    for v in [e for e in ret["geom"] if isinstance(e, bmesh.types.BMVert)]:
        th = math.atan2(v.co.y, v.co.x) % (math.pi / 3)
        edge_r = HEX_R * math.cos(math.pi / 6) / math.cos(th - math.pi / 6)  # flat-top hex, vertex at 0 deg
        d = Vector((v.co.x, v.co.y, 0)).normalized() * edge_r
        v.co = (d.x, d.y, 0.0)
    me = bpy.data.meshes.new("MM_DustHex")
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("MM_DustHex", me)
    bpy.context.scene.collection.objects.link(o)
    planar_uv(o)
    put("MM_DustHex", "Dust", o)


def survey_crater():
    R, rim, depth, seg, rs = 14.0, 1.4, 2.2, 96, 28
    bm = bmesh.new()
    outer = R * 1.7
    rows = []
    for j in range(1, rs + 1):
        rr = outer * j / rs
        row = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            x, y = rr * math.cos(a), rr * math.sin(a)
            u = rr / R
            z = -depth * (1 - u * u) if u < 1 else 0.0
            z += rim * math.exp(-((u - 1) / 0.18) ** 2)
            z += 0.25 * noise.noise(Vector((x, y, 3)) * 0.25)
            z *= min(1.0, (1.7 - u) / 0.25) if u > 1.45 else 1.0
            row.append(bm.verts.new((x, y, z)))
        rows.append(row)
    c = bm.verts.new((0, 0, -depth))
    for i in range(seg):
        bm.faces.new((c, rows[0][i], rows[0][(i + 1) % seg]))
    for j in range(rs - 1):
        for i in range(seg):
            bm.faces.new((rows[j][i], rows[j][(i + 1) % seg], rows[j + 1][(i + 1) % seg], rows[j + 1][i]))
    me = bpy.data.meshes.new("crater")
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("crater", me)
    bpy.context.scene.collection.objects.link(o)
    planar_uv(o)
    put("MM_SurveyCrater", "Ground", o)
    cyl("MM_SurveyCrater", "Glow", R * 0.42, 0.06, (0, 0, -depth + 0.25), v=48, bw=0)


def capsule():
    P = "MM_Capsule"
    cyl(P, "Dark", 0.75, 0.25, (0, 0, 0.125), v=32)
    cyl(P, "White", 0.7, 2.3, (0, 0, 1.4), v=40, bw=0.25)
    for z in (0.35, 2.5):
        torus(P, "Orange", 0.72, 0.09, (0, 0, z), maj=32, mn=8)
    for a in (0.0, math.pi):
        box(P, "Grey", (0.55, 0.12, 1.1), (0.68 * math.cos(a), 0.68 * math.sin(a), 1.35), a + math.pi / 2, 0.05)
    for k in range(6):
        box(P, "Cyan", (0.08, 0.16, 0.16), (0, -0.71, 0.75 + k * 0.24), 0, 0.02)
    torus(P, "Grey", 0.32, 0.06, (0, 0, 2.75), rot=(math.pi / 2, 0, 0), maj=24, mn=8)


def deposit_drum():
    P = "MM_DepositDrum"
    box(P, "Dark", (7, 7, 0.8), (0, 0, 0.4), 0, 0.1)
    for s in (-1, 1):
        box(P, "Orange", (7.05, 0.15, 0.2), (0, s * 3.45, 0.75), 0, 0.03)
        box(P, "Orange", (0.15, 7.05, 0.2), (s * 3.45, 0, 0.75), 0, 0.03)
    rot = (math.pi / 2, 0, 0)
    cyl(P, "Dark", 2.2, 2.2, (0, 0, 3.4), rot, v=48)
    for k in range(9):
        x = -1.6 + k * 0.4
        box(P, "Grey", (0.12, 2.3, 2 * math.sqrt(2.2 ** 2 - x * x) - 0.1), (x, -0.05, 3.4), 0, 0.03)  # grille bars
    torus(P, "Orange", 2.45, 0.42, (0, -1.15, 3.4), rot, maj=56, mn=14)
    for k in range(8):
        a = k * math.pi / 4
        box(P, "White", (0.18, 0.2, 0.5), (2.45 * math.cos(a), -1.6, 3.4 + 2.45 * math.sin(a)), 0, 0.03)
    cyl(P, "White", 0.45, 6, (0, 0.6, 8.0), v=24)
    # console
    box(P, "Grey", (1.6, 1.0, 2.4), (3.6, -0.2, 2.0), 0, 0.1)
    box(P, "Screen", (1.2, 0.05, 0.8), (3.6, -0.73, 2.6), 0, 0.01)
    for k in range(3):
        box(P, "Cyan", (0.15, 0.06, 0.15), (3.2 + k * 0.3, -0.73, 1.9), 0, 0.01)
    cyl(P, "Orange", 0.18, 0.2, (3.95, -0.78, 1.6), (math.pi / 2, 0, 0), v=16)


def export_all():
    os.makedirs(EXPORT, exist_ok=True)
    rep = {}
    for piece, groups in pieces.items():
        for g, objs in groups.items():
            bpy.ops.object.select_all(action="DESELECT")
            for o in objs:
                o.select_set(True)
                bpy.context.view_layer.objects.active = o
                for md in list(o.modifiers):
                    bpy.ops.object.modifier_apply(modifier=md.name)
            bpy.context.view_layer.objects.active = objs[0]
            if len(objs) > 1:
                bpy.ops.object.join()
            o = bpy.context.active_object
            o.name = f"{piece}__{g}" if piece != "MM_DustHex" else piece
            for p in o.data.polygons:
                p.use_smooth = True
            o.data.calc_loop_triangles()
            t = len(o.data.loop_triangles)
            assert t <= 20000, (o.name, t)
            rep[o.name] = t
            bpy.ops.object.select_all(action="DESELECT")
            o.select_set(True)
            bpy.ops.export_scene.fbx(filepath=os.path.join(EXPORT, o.name + ".fbx"), use_selection=True,
                                     axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_tspace=True)
    json.dump(rep, open(os.path.join(EXPORT, "props.json"), "w"), indent=2)
    print(json.dumps(rep, indent=2))


def preview():
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 64
    sc.render.resolution_x, sc.render.resolution_y = 1600, 900
    sc.world = bpy.data.worlds.new("w")
    layout = {"MM_SurveyCrater": (-22, 14, 0), "MM_DustHex": (14, 6, 0), "MM_Capsule": (-2, -10, 0),
              "MM_DepositDrum": (6, -14, 0)}
    for o in sc.objects:
        for k, loc in layout.items():
            if o.name.startswith(k):
                o.location = loc
    bpy.ops.mesh.primitive_plane_add(size=300, location=(0, 0, -0.01))
    g = bpy.context.active_object
    g.data.materials.append(mat("Ground"))
    sun = bpy.data.objects.new("s", bpy.data.lights.new("s", "SUN"))
    sun.data.energy, sun.data.angle = 4.5, math.radians(0.5)
    sun.rotation_euler = (math.radians(58), 0, math.radians(-30))
    sc.collection.objects.link(sun)
    cam = bpy.data.objects.new("c", bpy.data.cameras.new("c"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam.location = (-8, -52, 24)
    cam.data.lens = 32
    cam.rotation_euler = (Vector((-2, 2, 0)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(EXPORT, "preview_props.png")
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    bpy.ops.wm.read_factory_settings(use_empty=True)
    dust_hex()
    survey_crater()
    capsule()
    deposit_drum()
    export_all()
    preview()
