# Fruit models v2 (generated 2026-11-20 by tools/blender/fruitgen/fruit2.py)

Per fruit: `<key>.fbx` (low poly, 6,500-8,100 triangles, keeps the carved silhouette), `<key>_color.png` (AO multiplied in), `<key>_normal.png` (tangent space, 8-bit), `<key>_roughness.png`, `<key>_glow.png` (greyscale mask of where light shines out of the crevices), all 1024².

v2 builds each body as a height field: swirls are carved coils (deep grooves, raised rope), not painted lines, and glow lives only in the seams between swirls, per Sharman's feedback on v1. Previews and the side-by-side sheet against the show art: project files `fruit-throw/models-v2-2026-11-20/`. In Roblox: MeshPart + SurfaceAppearance (ColorMap / NormalMap / RoughnessMap). Previews: project files `fruit-throw/models-2026-11-19/`.

| Key | In-game name | Tier | Source of the look (design doc 4c) |
|---|---|---|---|
| rubber | Rubber Fruit (Sun God when awakened) | Mythical | Canon |
| quake | Quake Fruit | Mythical | Canon |
| darkness | Darkness Fruit | Mythical | Canon |
| azure_dragon | Azure Dragon Fruit | Mythical | Canon |
| black_dragon | Black Dragon Fruit | Mythical | Ours |
| soul | Soul Fruit | Mythical | Ours |
| magma | Magma Fruit | Mythical | Ours |

Glow in Roblox: SurfaceAppearance has no emission map we have verified, so `_glow.png` is the mask for the in-game effect (a slightly larger Neon/ForceField shell textured with it, or a PointLight tinted to the glow colour). Check the SurfaceAppearance reference before relying on any emissive property. Not yet imported or judged in Studio (rule M31).
