"""Slime Rise lab kit helpers for Blender (exec'd at the start of each build step).

Units: 1 Blender unit = 1 Roblox stud. Pieces are built standing on z=0 with the
front facing -Y. Every part is tagged with a material group (Frame, Inset, Steel,
Dark, Glass, Glow, Hazard, Rubber, Slime) so the game can apply its own stylized
materials and soft glow per group. finish_piece() joins each group into one mesh
named "<Piece>__<Group>" with its origin at the piece origin.
"""
import bpy
import bmesh
import json
import math
from mathutils import Vector

GROUPS = ["Frame", "Inset", "Steel", "Dark", "Glass", "Glow", "Hazard", "Rubber", "Slime"]
PREVIEW = {
    "Frame": (0.42, 0.34, 0.62, 1), "Inset": (0.26, 0.2, 0.42, 1), "Steel": (0.72, 0.75, 0.83, 1),
    "Dark": (0.12, 0.11, 0.17, 1), "Glass": (0.6, 0.95, 0.85, 0.35), "Glow": (0.42, 1.0, 0.24, 1),
    "Hazard": (1.0, 0.79, 0.24, 1), "Rubber": (0.18, 0.18, 0.22, 1), "Slime": (0.35, 0.95, 0.2, 1),
}


def material(group):
    name = "KIT_" + group
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        bsdf.inputs["Base Color"].default_value = PREVIEW[group]
        mat.diffuse_color = PREVIEW[group]
    return mat


def collection(piece):
    name = "KIT_" + piece
    col = bpy.data.collections.get(name)
    if col is None:
        col = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(col)
    return col


def _link(obj, piece, group):
    col = collection(piece)
    for c in obj.users_collection:
        c.objects.unlink(obj)
    col.objects.link(obj)
    obj["kit_piece"] = piece
    obj["kit_group"] = group
    obj.data.materials.clear()
    obj.data.materials.append(material(group))
    return obj


def _bevel(obj, width, segments=3):
    if width <= 0:
        return obj
    mod = obj.modifiers.new("Bevel", "BEVEL")
    mod.width = width
    mod.segments = segments
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(40)
    mod.harden_normals = True
    obj.modifiers.new("WeightedNormal", "WEIGHTED_NORMAL").keep_sharp = True
    return obj


def box(piece, group, size, loc, bevel=0.08, rot=(0, 0, 0), segments=3):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    obj = bpy.context.active_object
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    _bevel(obj, min(bevel, min(size) * 0.45), segments)
    return _link(obj, piece, group)


def cyl(piece, group, radius, depth, loc, rot=(0, 0, 0), verts=32, bevel=0.06):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=loc, rotation=rot, vertices=verts)
    obj = bpy.context.active_object
    _bevel(obj, min(bevel, radius * 0.4, depth * 0.4), 2)
    return _link(obj, piece, group)


def torus(piece, group, major, minor, loc, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, location=loc, rotation=rot, major_segments=40, minor_segments=12)
    return _link(bpy.context.active_object, piece, group)


def sphere(piece, group, radius, loc, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=loc, segments=32, ring_count=16)
    obj = bpy.context.active_object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.ops.object.shade_smooth()
    return _link(obj, piece, group)


def bolt_grid(piece, xs, zs, y, radius=0.12, depth=0.12):
    for x in xs:
        for z in zs:
            cyl(piece, "Steel", radius, depth, (x, y, z), rot=(math.radians(90), 0, 0), verts=12, bevel=0.03)


def finish_piece(piece, offset_x):
    """Apply modifiers, join per group, origin at piece origin, then shift for preview layout."""
    col = collection(piece)
    by_group = {}
    for obj in list(col.objects):
        by_group.setdefault(obj["kit_group"], []).append(obj)
    for group, objs in by_group.items():
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
            bpy.context.view_layer.objects.active = o
            for m in list(o.modifiers):
                bpy.ops.object.modifier_apply(modifier=m.name)
        bpy.context.view_layer.objects.active = objs[0]
        if len(objs) > 1:
            bpy.ops.object.join()
        joined = bpy.context.active_object
        joined.name = f"{piece}__{group}"
        joined.data.name = joined.name
        joined["kit_piece"] = piece
        joined["kit_group"] = group
        bpy.context.scene.cursor.location = (0, 0, 0)
        bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
        joined.location.x += offset_x
    return [o.name for o in col.objects]


def manifest(path):
    """Size + centre offset of every kit mesh in Roblox space (x, y=up, z=forward)."""
    out = {}
    for obj in bpy.data.objects:
        if obj.type != "MESH" or "kit_piece" not in obj:
            continue
        piece = obj["kit_piece"]
        base = obj.location.copy()
        pts = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
        mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
        mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
        centre = (mn + mx) / 2
        size = mx - mn
        tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
        out.setdefault(piece, {})[obj["kit_group"]] = {
            "mesh": obj.name,
            "size": [round(size.x, 3), round(size.z, 3), round(size.y, 3)],
            "offset": [round(centre.x - base.x, 3), round(centre.z - base.z, 3), round(centre.y - base.y, 3)],
            "tris": tris,
        }
    with open(path, "w") as f:
        json.dump(out, f, indent=1)
    return out
