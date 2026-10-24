"""Regenerates src/server/Services/KitManifest.luau from the Blender kit manifests.
Usage: python art/gen_kit_manifest.py <vault assets dir>   (run from games/slime-rise)
Every *_kit_manifest.json in the folder is merged (lab kit, cryo kit, ...)."""
import glob, json, os, sys

assets = sys.argv[1] if len(sys.argv) > 1 else r"C:\jarvis\brain\vault\40_projects\game\assets"
pieces = {}
sources = []
for path in sorted(glob.glob(os.path.join(assets, "*_kit_manifest.json"))):
    sources.append(os.path.basename(path))
    for piece, groups in json.load(open(path, encoding="utf-8")).items():
        if piece in pieces:
            raise SystemExit(f"duplicate piece {piece} in {path}")
        pieces[piece] = groups

def v(xs):
    return "Vector3.new(" + ", ".join(repr(round(float(x), 4)) for x in xs) + ")"

out = ["--!strict",
       "-- Generated from the Blender kits (" + ", ".join("assets/" + s for s in sources) + ") by art/gen_kit_manifest.py. Do not edit by hand.",
       "-- size/offset are in studs, Roblox axes (x, y up, z forward); offset is from the piece origin (base centre).",
       "",
       "export type Part = { mesh: string, size: Vector3, offset: Vector3 }",
       "",
       "local KitManifest: { [string]: { [string]: Part } } = {"]
for piece in sorted(pieces):
    out.append(f"\t{piece} = {{")
    for group in sorted(pieces[piece]):
        g = pieces[piece][group]
        out.append(f"\t\t{group} = {{")
        out.append(f'\t\t\tmesh = "{g["mesh"]}",')
        out.append(f"\t\t\tsize = {v(g['size'])},")
        out.append(f"\t\t\toffset = {v(g['offset'])},")
        out.append("\t\t},")
    out.append("\t},")
out += ["}", "", "return KitManifest", ""]
open("src/server/Services/KitManifest.luau", "w", encoding="utf-8", newline="\n").write("\n".join(out))
print(len(pieces), "pieces from", sources)
