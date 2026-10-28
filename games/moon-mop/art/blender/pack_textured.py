"""Pack the textured pieces as one glTF with embedded PBR materials, so a single Studio
File > Import uploads the meshes AND their colour/normal/roughness maps and builds the
SurfaceAppearances itself (Importer: "The .fbx and .gltf formats support ... PBR textures",
https://create.roblox.com/docs/studio/importer).

Also adds two 4x4-stud swatch planes carrying the regolith maps. Their uploaded texture ids are
reused for the Terrain MaterialVariants, so the ground needs no separate image upload.

Usage (from games/moon-mop):  python art/blender/pack_textured.py
Writes art/export/textured/MoonMop_Textured.gltf (+ .bin and PNGs next to it).
"""
import bpy
import os

HERE = os.path.dirname(os.path.abspath(__file__))
EXPORT = os.path.join(HERE, "..", "export")
TEX = os.path.join(HERE, "..", "textures")
OUT = os.path.join(EXPORT, "textured")
ROCKS = ["MM_RockA", "MM_RockB", "MM_RockC", "MM_RockD", "MM_RockE"]


def material(name):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Metallic"].default_value = 0.0
    m.use_backface_culling = True  # exports doubleSided false

    def img(kind, non_color):
        n = nt.nodes.new("ShaderNodeTexImage")
        n.image = bpy.data.images.load(os.path.join(TEX, f"{name}_{kind}.png"))
        if non_color:
            n.image.colorspace_settings.name = "Non-Color"
        return n

    nt.links.new(img("color", False).outputs["Color"], b.inputs["Base Color"])
    nt.links.new(img("roughness", True).outputs["Color"], b.inputs["Roughness"])
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(img("normal", True).outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], b.inputs["Normal"])
    return m


bpy.ops.wm.read_factory_settings(use_empty=True)
for name in ROCKS:
    bpy.ops.import_scene.fbx(filepath=os.path.join(EXPORT, name + ".fbx"))
    o = bpy.context.selected_objects[0]
    o.name = name
    o.data.materials.clear()
    o.data.materials.append(material(name))
for i, name in enumerate(["Regolith_Dusty", "Regolith_Clean"]):
    bpy.ops.mesh.primitive_plane_add(size=4, location=(30 + i * 6, 0, 0))
    o = bpy.context.active_object
    o.name = "MM_Swatch_" + name
    o.data.materials.append(material(name))
os.makedirs(OUT, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "MoonMop_Textured.gltf"), export_format="GLTF_SEPARATE",
                          use_selection=True, export_tangents=True, export_image_format="AUTO")
print("wrote", sorted(os.listdir(OUT)))
