# fruitgen: Devil-Fruit-style fruits, modelled by script in Blender

Headless Blender (the `bpy` 5.3 wheel from PyPI, Python 3.13) builds each fruit from a recipe, then bakes it to a game-ready low-poly mesh. No GPU needed; Cycles CPU renders the previews. Works in the cloud container and on the Mac.

```
python3.13 -m venv bvenv && ./bvenv/bin/pip install bpy pillow
./bvenv/bin/python tools/blender/fruitgen/fruits.py rubber out/            # full quality
./bvenv/bin/python tools/blender/fruitgen/fruits.py rubber out/ --fast     # quick look
```

Per fruit it writes: `<key>.fbx` + `<key>.glb` (low poly, ~2.4k triangles), `<key>_color.png`, `<key>_normal.png`, `<key>_roughness.png` (1024², for a `SurfaceAppearance`), and `<key>_front.png` / `<key>_back.png` previews rendered **from the low-poly + baked maps**, so the preview is what Roblox will get, not the high-poly.

## How a fruit is built (shape spec: design doc section 4c)
1. Body: UV sphere pushed to a shape. Simple shapes are radial functions; pears/teardrops/eggs are lathe profiles turned into radial functions (`lathe_radial`).
2. Swirl curls: one raised spiral tube per point of an even (farthest-point) spread over the body, each sitting on a small bulge, like the show's art.
3. Curly stem: a tube that rises and curls into a flat spiral.
4. Extras per recipe: crack lines (Quake), scale rows + leaf crown (dragons), ghost wisp (Soul), lava seams (Magma).
5. Bake: everything except the body and stem is baked (colour, tangent normal, roughness) onto a decimated low-poly shell. Swirls and scales live in the normal map.

## Into Roblox (the Mac does this; never a manual step for Sharman)
Import `<key>.fbx` as a MeshPart (Studio MCP / Open Cloud upload), upload the three PNGs, add a `SurfaceAppearance` with ColorMap/NormalMap/RoughnessMap. Emissive parts (Magma seams, Black Dragon seams, Soul wisp) need an in-game glow on top (a PointLight or a Neon shell), since the baked colour map has no emission. Judge it in Studio, not from these renders (rule M31).
