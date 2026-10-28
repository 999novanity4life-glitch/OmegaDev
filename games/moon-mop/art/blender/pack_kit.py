"""Pack every exported piece into one FBX for a single Studio "Import 3D" (each object
becomes its own MeshPart named after the piece), plus a zip of the PBR textures.

Usage (from games/moon-mop):  python art/blender/pack_kit.py
"""
import bpy
import glob
import os
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
EXPORT = os.path.join(HERE, "..", "export")
TEX = os.path.join(HERE, "..", "textures")
SKIP = ()  # superseded blockout files were removed

bpy.ops.wm.read_factory_settings(use_empty=True)
files = sorted(f for f in glob.glob(os.path.join(EXPORT, "MM_*.fbx")) if not os.path.basename(f).startswith(SKIP))
x = 0.0
for f in files:
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=f)
    for o in set(bpy.data.objects) - before:
        o.name = os.path.splitext(os.path.basename(f))[0]
print(len(files), "pieces")
bpy.ops.object.select_all(action="SELECT")
out = os.path.join(EXPORT, "MoonMop_Kit.fbx")
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, axis_forward="-Z", axis_up="Y",
                         mesh_smooth_type="FACE", use_tspace=True)
with zipfile.ZipFile(os.path.join(EXPORT, "MoonMop_Textures.zip"), "w", zipfile.ZIP_DEFLATED) as z:
    for t in sorted(glob.glob(os.path.join(TEX, "*_*.png"))):
        if "preview" not in t:
            z.write(t, os.path.basename(t))
print("wrote", out)
