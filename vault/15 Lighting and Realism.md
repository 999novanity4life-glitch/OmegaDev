# 15 Lighting and Realism

How a Roblox scene stops looking like "default Studio" and starts looking art-directed. Tags: **[DOC]** create.roblox.com, **[VIDEO]** a talk or tutorial with notes in `docs/research/videos-2026-10-28/`, **[RULE]** studio rule (our choice, not a fact). Code lives in `template/src/shared/LightingPresets.luau` and `template/src/client/Controllers/LookController.luau`. Every look passes `docs/VISUAL_QA.md` before the human sees it.

## The order of work [RULE, from DOC course order and VIDEO 21/26]
1. **Scenario first.** Pick the time of day and the mood in one line ("late afternoon, warm, calm") before touching a property [VIDEO 26 @0:00].
2. **Sky next.** The skybox is the biggest block of color and tints everything, including Atmosphere [VIDEO 21 @23:15, VIDEO 25 @25:10, VIDEO 14 @8:19].
3. **Sun position.** Place it so light lands somewhere interesting (through a window, along the path to the goal). ClockTime + GeographicLatitude, or the Celestial Body Dragger plugin [VIDEO 21 @22:14, VIDEO 26 @2:05].
4. **Global Lighting** (a preset from `LightingPresets`), then **Atmosphere**, then **post effects**, then **local lights**, then **fake extras** (bounce lights, shadow decals). Volumetric fakes last, trailer shots only [VIDEO 26 @19:59, @13:54].

## Engine facts [DOC]
- `Lighting.LightingStyle` is **Realistic** or **Soft** and replaces the deprecated `Technology`; with `PrioritizeLightingQuality` it sets the renderer ([LightingStyle](https://create.roblox.com/docs/reference/engine/enums/LightingStyle)). Realistic lets local lights cast shadows indoors ([Construct your world](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/construct-your-world)). Set both in `default.project.json` (the template does); a script write may be refused.
- `ExposureCompensation` -5..5; `ShadowSoftness` 0..1, default 0.2; `Ambient` default 0,0,0; `OutdoorAmbient` default 127,127,127 and clamped to at least Ambient per channel; `EnvironmentDiffuseScale`/`EnvironmentSpecularScale` 0..1, default 0 ([Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting)). Metalness in SurfaceAppearance shows nothing until EnvironmentSpecularScale > 0.
- Atmosphere: Density, Offset, Color, Decay, Glare, Haze. **Glare and Decay need Haze > 0** ([Atmosphere](https://create.roblox.com/docs/reference/engine/classes/Atmosphere)). `LightingPresets.validate` flags Glare with Haze 0.
- Post effects that exist: Bloom, Blur, ColorCorrection, DepthOfField, SunRays, ColorGradingEffect (TonemapperPreset Default/Retro). Do not invent others.
- Starter places ship a strong Bloom, SunRays, DepthOfField, a Sky and an Atmosphere. Retire them before applying a look (`LookController.retireStarterEffects`, same pattern as slime-rise).

## Presets with real numbers
| Preset | Use | Source |
|---|---|---|
| `RobloxOutdoorSunset` | outdoor 5 pm, Ambient = Outdoor 156,136,176, Atmosphere Density 0.272 / Haze 1 / Color 85,78,54 | [DOC] [Enhance outdoor environments](https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-outdoor-environments) |
| `RobloxIndoorWarm` | warm room, ClockTime 15.6, Ambient 83,70,57, Exposure 0.5, SunRays 0.023/0.266, Density 0.5, CC Contrast 0.05 / Saturation 0.1 | [DOC] [Enhance indoor environments](https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-indoor-environments) |
| `RobloxSciFiArena` | dark sci-fi interior, Ambient 26,34,36, ShadowSoftness 0.15, Atmosphere 0.285/0.65/Glare 0.3/Haze 2, Bloom 1.5/56 | [DOC] [Environmental art course](https://create.roblox.com/docs/tutorials/curriculums/environmental-art) |
| `AirlessMoon` | no air: no haze, hard shadows, dark cool ambient, warm sun | [INFERRED], tune in Studio |

Add a preset by copying one, tagging its `source`, and running `lune run tests/run` (the spec rejects out-of-range values and untagged sources).

## Art rules that make it look good
- **Warm light, cool shadows.** Ambient/OutdoorAmbient carry the shadow color (blue, teal, purple), `ColorShift_Top` tints the lit side warm. Sunset: strong split; afternoon: subtle [VIDEO 26 @0:00, @3:36, @16:14].
- **Contrast from EnvironmentDiffuseScale.** Lower it for moodier light-to-shadow contrast; nudge Exposure up if too dark [VIDEO 26 @6:09, @6:40].
- **Bloom recipe:** Threshold very low (~0.03), Size very high, then lower Intensity until it only "glues" the image together [VIDEO 26 @7:36]. Not for scenes with lots of white UI-like surfaces (slime-rise washed out).
- **ColorCorrection recipe:** start every value at 0.05, toggle on/off to judge [VIDEO 26 @8:11]; the indoor DOC preset uses the same size of numbers.
- **Separate depth with Atmosphere**, optional DepthOfField, SunRays with the sun behind the scene [VIDEO 21 @18:03]. Mix the Atmosphere color from the scene (water + sky + grass gives a "blurry green") [VIDEO 25 @25:10].
- **Fake bounce light** where window light would hit: one PointLight on the floor, one on the wall, not "quadruple all your lights" [VIDEO 21 @20:09, VIDEO 26 @4:38].
- **Shadow helpers:** CastShadow off on window glass so sunlight comes in [VIDEO 26 @9:16]; turn shadows off on overhead clutter in dark interiors [VIDEO 21 @21:43]; blue-tinted shadow decals under furniture [VIDEO 26 @12:19].
- **Light budget:** add lights, then toggle each one; light radii should not overlap; audit stacked lights with the Lighting Editor plugin [VIDEO 21 @31:31, @32:02]. `scripts/studio/scene-audit.luau` counts lights and shadow-casting lights.
- **Light tells the story and guides the way:** each landmark is a scene with its own mood; placed lights should build a "get from here to there" goal [VIDEO 21 @15:30, @17:01].
- **Learn by matching a still.** Put a film or game still next to Studio and match light direction, shadow placement and color [VIDEO 21 @19:06]. This is exactly the VISUAL_QA goal board.

## Zones: one look per area, blended [VIDEO 14, RULE]
Firewatch drives sky, sun and fog from per-area presets that interpolate as the player crosses trigger volumes, planned with a **color script** (a strip of mood colors per story beat) [VIDEO 14 @10:23, @15:29]. In Roblox: one `LightingPresets` entry per zone, `LookController.blendTo(name)` on zone entry (Reduced Motion snaps). Write the color script in SPEC.md before the greybox.

## Materials and PBR [DOC unless tagged]
- `SurfaceAppearance` works on **MeshParts only**; normal maps are OpenGL tangent-space and the mesh must export tangents; map IDs are written by plugins, not game scripts ([SurfaceAppearance](https://create.roblox.com/docs/reference/engine/classes/SurfaceAppearance)). `Color` tints for free; near-white greyscale maps tint hardest ([surface appearance](https://create.roblox.com/docs/art/modeling/surface-appearance)).
- Textures and trim sheets at most 1024×1024 by guidance; texture memory of 1024² is 4× 512² ([Develop polished assets](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/develop-polished-assets), [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)).
- Three tiers: unique SurfaceAppearance for hero meshes, a shared trim-sheet SurfaceAppearance for architecture, MaterialVariants for Parts and terrain ([Duvall Drive](https://create.roblox.com/docs/resources/the-mystery-of-duvall-drive/materialize-the-world)). Keep trims clean; wear only on unique hero assets (same source).
- Terrain custom looks are MaterialVariants that override one of the built-in terrain materials in MaterialService [VIDEO 25 @13:21].
- Instancing breaks when meshes are re-imported; import once, duplicate in Studio, convert shared SurfaceAppearances to packages ([Improve performance](https://create.roblox.com/docs/performance-optimization/improve), [asset library](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/assemble-an-asset-library)). The scene audit reports duplicate texture IDs.
- Full sourced tables: `docs/research/MAP_ANIMATION_GUI_CRAFT_2026-10-23.md` §1.5, §1.7, §1.8.

## Failure looks (put these in every BRIEF's MUST NOT) [RULE]
Flat grey Soft lighting with Ambient 0; default skybox; every surface Plastic; two Atmospheres or starter Bloom stacked on a preset; neon everywhere; saturated red/green decor that players read as hazard or pickup [VIDEO 21 @26:53]; detail so busy the squint test turns it to mush (chapter 16).
