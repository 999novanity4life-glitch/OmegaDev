# THE Ultimate Lighting Tutorial [ADVANCED] {Roblox Studio}
- Channel: DatBoiEle | URL: https://www.youtube.com/watch?v=aq0Fi0R2FAY | Length: 21:16 | Upload: 2024-12-13 | Captions: auto

- [0:00] Decide the lighting scenario first. In a sunset, the light patches are strongly warm (yellow/red) and the shadows are cool (blue, purple or green).
- [1:01] Afternoon has the same warm/cool split but subtler: slight yellow light, slight teal shadows. At night you rely on separate light sources.
- [1:33] Pick the scenario that suits the build's colors.
- [2:05] For interiors, place the sun (Sun Adjuster plugin) so beams come through the windows at an interesting angle.
- [3:01] Choose a skybox that matches the scenario before you touch the lighting settings.
- [3:36] Lighting.Ambient sets the shadow color (he made it blue). ColorShift_Top tints the lit areas (subtle yellow). This warm-light/cool-shadow split is the core "art rule".
- [4:38] Fake outside bounce light: a Part with a PointLight outside the window, Shadows on, slightly yellow, brighter.
- [6:09] For a moody look, lower EnvironmentDiffuseScale: the lower, the stronger the light-to-shadow contrast.
- [6:40] Raise ExposureCompensation "just a tiny bit" if too dark. OutdoorAmbient sets the shadow color outdoors.
- [7:36] Bloom recipe: very low Threshold ("something like 0.03"), very high Size, then lower Intensity to taste: a subtle blur that blends everything together.
- [8:11] ColorCorrection recipe: start every property at 0.05, toggle off and on to judge. He raised Contrast to 0.1 and lowered Brightness slightly.
- [9:16] Window trick: uncheck CastShadow on transparent window parts so sunlight comes through.
- [9:44] Glass material tinted slightly yellow to match the outside light.
- [10:30] If lighting looks too harsh, raise Atmosphere Density a little.
- [10:47] Terrain Clouds and Lighting.ShadowSoftness soften shadows; real shadows are a bit soft.
- [12:19] Custom shadow decals under furniture, tinted slightly blue to match the cool shadow color.
- [13:20] Light decals: a soft circle decal over the window to emphasize light coming through.
- [13:54] Fake volumetric light with a near-transparent Neon "fog mesh" along the beams. It causes a lot of lag: "only for showcases", not a real game.
- [16:14] Afternoon example: slightly teal dark shadows (Ambient), slightly yellow light (ColorShift_Top), Brightness up a little, EnvironmentDiffuseScale down.
- [19:59] 5-step summary: (1) choose a scenario; (2) position the sun so light lands in a unique spot; (3) pick a matching skybox; (4) set Lighting with warm lights and cool shadows; (5) add custom shadows and lights. Volumetrics last.

Applies to Roblox how (inferred): Set Ambient cool and ColorShift_Top warm, lower EnvironmentDiffuseScale for contrast, Bloom with tiny Threshold and high Size, ColorCorrection starting at 0.05. Turn off CastShadow on windows. Fog-mesh volumetrics only for trailer shots.
