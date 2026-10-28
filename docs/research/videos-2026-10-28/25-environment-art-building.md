# Roblox Studio - Building Tutorial | Environmental Art
- Channel: BONES | URL: https://www.youtube.com/watch?v=-DoOf32pkPo | Length: 35:00 | Upload: 2024-10-05 | Captions: auto (the voiceover is AI text-to-speech, per the description)

- [0:30] Gather references. A form reference sets the shape of an object; a style reference sets only the style or genre.
- [1:20] Keep a clean workspace: sort assets into folders.
- [1:42] Studio settings: Render > editor quality level 21 (skip on a weak PC).
- [2:13] The "Part to Terrain" plugin converts parts into terrain as a rough shape to sculpt on. It does not work on unions or corner wedges; use a normal wedge at an angle.
- [2:39] Terrain tools: Fill, Select + Transform, Draw (and Subtract), Sculpt, Smooth (needs enough terrain), Paint.
- [3:35] Flatten has three modes: top-and-bottom, top only, bottom only.
- [4:35] Block out modularly with parts; a "double slope" (second wedge layer) smooths the slope.
- [5:39] "There is no such thing as straight lines" in organic landscapes. Add steep cliffside wedges as barrier facades so the world feels bigger than the play area.
- [6:10] Facades plus distant background items suggest a world beyond the scene. Ideally the player should not be able to see out of the scene. Check the player has room to walk freely.
- [7:12] Stay logical: ask "where does the water come from?"
- [8:13] Materials: grass on top surfaces, stone on steep slopes, sand in the shallows around the river.
- [9:14] Terrain has LOD: farther terrain uses fewer polygons.
- [9:57] "Normalization": turn straight surfaces into organic ones with Sculpt. Give cliffs a "lip", a slight overhang at the top edge.
- [10:47] Sculpt sand into a wavy shape, as wave erosion forms it. Clean up edges with Paint.
- [13:21] Custom terrain materials: import PBR textures as a MaterialVariant with a terrain base material, then select it as the override in MaterialService. Paint paths with small bends and off-shoots, "but not too many".
- [14:21] Avoid flat terrain. Judge the scene from a low, player-eye angle. Use photos of real cliff faces, and place a rig for scale.
- [15:22] Sculpt background hills that the main cliffs overlook. Recolor foliage to fit the grass color and keep a good color gradient.
- [16:52] Greybox the builds as plain parts to reserve space before adding detail.
- [17:52] Rock cliffs: many large, wide rocks rather than lots of mini rocks, layered like real formations. Rotating one rock gives 4 variations. Big shapes first, then smaller rocks for detail.
- [19:30] Don't repeat anything in close succession: "three duplicate rocks look really abnormal". Let some rocks protrude for depth.
- [20:10] Grade rocks toward the ground with flatter, stubbier rocks offset from the rock above. Rocks get gradually larger closer to the cliff.
- [22:11] Fake grass growing over rocks with a tiny, weak Sculpt brush.
- [23:20] Build one small rock formation as a modular model and reuse it with slight changes. Splash particles around water rocks, not overdone.
- [24:25] Roblox water hides things under it that aren't fully visible; he set the water wave size to 0.
- [25:10] Run a screenshot through a palette maker to check the color scheme. Change the skybox first, since it affects the Atmosphere. For a green scene, make the Atmosphere color a "blurry green" mixing water, sky and grass. Desaturate terrain colors that read too bright.
- [26:58] Props: fences with gaps and variations, rocks along the path. Corners and path intersections are "one of the safest options to detail". Rotate neighboring trees 90° or more, mix shapes and sizes, don't overcrowd. Trees on the outer rim suggest a world outside. Keep plant density down in real games for performance.

Applies to Roblox how (inferred): Block out coasts and cliffs as parts, convert to terrain, sculpt, add cliff lips, and layer large rocks with stubby transitions. Ring the playable area with facade cliffs or background hills, and keep plant counts modest.
