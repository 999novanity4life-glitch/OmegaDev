"""Lit preview of the boulders on regolith, using only the exported game meshes and baked maps
(what Roblox will get), under a hard low sun like an airless Moon.

Usage (from games/moon-mop):  python art/blender/preview_rocks.py
Writes art/export/preview_rocks.png and preview_rocks_close.png.
"""
import bpy
import math
import os
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
T = os.path.join(HERE, "..", "textures")
E = os.path.join(HERE, "..", "export")


def pbr(name, scale=1.0, disp=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    tc = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (scale, scale, 1)
    nt.links.new(tc.outputs["UV"], mp.inputs["Vector"])

    def img(kind, nc):
        n = nt.nodes.new("ShaderNodeTexImage")
        n.image = bpy.data.images.load(os.path.join(T, f"{name}_{kind}.png"))
        if nc:
            n.image.colorspace_settings.name = "Non-Color"
        nt.links.new(mp.outputs["Vector"], n.inputs["Vector"])
        return n

    c, r, nm = img("color", False), img("roughness", True), img("normal", True)
    nmap = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(c.outputs["Color"], b.inputs["Base Color"])
    nt.links.new(r.outputs["Color"], b.inputs["Roughness"])
    nt.links.new(nm.outputs["Color"], nmap.inputs["Color"])
    nt.links.new(nmap.outputs["Normal"], b.inputs["Normal"])
    return m


def scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 128
    sc.cycles.use_denoising = True
    sc.view_settings.view_transform = "AgX"
    sc.view_settings.look = "AgX - Medium High Contrast"
    sc.render.resolution_x, sc.render.resolution_y = 1920, 1080
    w = bpy.data.worlds.new("space")
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.0, 0.0, 0.0, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 0.0
    sc.world = w
    bpy.ops.mesh.primitive_plane_add(size=80)
    g = bpy.context.active_object
    g.data.materials.append(pbr("Regolith_Dusty", 8))
    rocks = [("MM_RockE", (-9, 9, 0), 0.4), ("MM_RockC", (2, 6, 0), 1.9), ("MM_RockB", (8, 0, 0), 0.8),
             ("MM_RockA", (-2, -1.5, 0), 2.6), ("MM_RockD", (3.5, -3.5, 0), 0.3), ("MM_RockD", (-6, -3, 0), 1.7),
             ("MM_RockA", (12, 6, 0), 1.1)]
    for name, loc, rot in rocks:
        bpy.ops.import_scene.fbx(filepath=os.path.join(E, name + ".fbx"))
        o = bpy.context.selected_objects[0]
        o.location = loc
        o.rotation_euler[2] = rot
        o.data.materials.clear()
        o.data.materials.append(bpy.data.materials.get(name) or pbr(name))
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
    sun.data.energy = 6.0
    sun.data.angle = math.radians(0.53)  # the real Sun's disc: razor shadows
    sun.rotation_euler = (math.radians(72), 0, math.radians(-50))
    sc.collection.objects.link(sun)
    fill = bpy.data.objects.new("earthshine", bpy.data.lights.new("earthshine", "SUN"))
    fill.data.energy = 0.08
    fill.data.color = (0.6, 0.75, 1.0)
    fill.rotation_euler = (math.radians(40), 0, math.radians(140))
    sc.collection.objects.link(fill)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    return sc, cam


def shot(sc, cam, loc, target, lens, out):
    cam.location = loc
    cam.data.lens = lens
    cam.rotation_euler = (Vector(target) - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(E, out)
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    sc, cam = scene()
    shot(sc, cam, (4, -26, 5.5), (0, 3, 1.5), 32, "preview_rocks.png")
    shot(sc, cam, (7, -9, 3.2), (3, 2, 1.6), 45, "preview_rocks_close.png")
