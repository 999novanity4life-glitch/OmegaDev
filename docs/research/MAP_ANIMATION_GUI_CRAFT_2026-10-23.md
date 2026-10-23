# Kits, springs and tokens make Roblox premium

A Pixar-like low-poly Roblox game built by Claude through the Studio MCP and Blender looks "intentional" when three systems are made deterministic and token-driven. **Maps:** generate in Edit mode from seeded, grid-snapped kit functions (Roblox's own `ProceduralModel` contract, Studio beta 2026-04-23, generate then bake) on a 5-stud grid with corner pivots, then run a "handmade pass" (seeded prop jitter, trim, ≤3-4 materials per room, 2-4 shadowed local lights steering the eye) inside a hub-plus-ring-of-plots layout that every top base game uses. **Motion:** use TweenService for choreographed beats (hatch, cutscene, fades), springs (spr, Ripple, Otter, Nevermore Spring) for anything the player can interrupt, and engine-native Styling Transitions (full release 2026-07-27) for hover/press. Escalate hatch reveals by rarity (shake, particles, flash, hold time), keep audio within ~20 ms of the visual beat, and pre-stream destinations with `RequestStreamAroundAsync` behind a fade. **GUI:** the "chunky cartoon simulator" family (PS99, Pls Donate, Grow a Garden, Steal a Brainrot) can now be built natively: UICorner + per-corner radii, UIStroke, UIGradient, and UIShadow (full release 2026-06-23). Theme it through a token StyleSheet + StyleQuery (full release 2026-05-11). Two caveats run through the whole report. First, almost no top game publishes stud dimensions, UI radii or hatch timings, so every per-game visual number below is either a guide-site figure or UNVERIFIED. Second, the strongest numbers come from Roblox's docs and showcase write-ups, a few DevForum code threads and engine-neutral game-feel research. Read the recipes as tested defaults to tune in Studio, not as reverse-engineered copies of shipped games.

**Tag key (kept from the research notes):** [DOC] = create.roblox.com or a Roblox-authored post (including staff DevForum announcements); [GH] = GitHub; [FORUM] = DevForum community post; [WIKI] = fan wiki or wiki aggregator; [GUIDE] = games-press guide; [STORE] = marketplace listing; [VIDEO] = YouTube; [BLOG] = third-party article; **UNVERIFIED** = not confirmed against a fetched source. **Derived** = composed by the researchers on top of the cited APIs; not yet run in Studio.

---

## Part 1. Maps and buildings: seeded kit functions baked in Edit mode beat hand-placing and runtime generation

### 1.1 Roblox now ships the exact pipeline an MCP builder needs

The engineering picture changed in April 2026. Roblox released a first-party `ProceduralModel` instance whose generator contract is a reusable kit function, and it made Studio MCP "Quick Connect" and `/generate_procedural_model` official features. Driving builds from Claude through the MCP is now a supported workflow.

| Fact | Detail | Tag / source |
|---|---|---|
| ProceduralModel beta | Announced 2026-04-23; enable via File > Beta Features > "Edit-Time Procedural Models", then Insert Object > ProceduralModel. Assistant/MCP accept a reference image with the prompt (2026-04-28). Assistant output "built from primitive parts, so they remain editable" | [DOC] [Studio Beta: Procedural Models](https://devforum.roblox.com/t/studio-beta-introducing-procedural-models-build-parametrized-3d-models-with-code-or-ai/4592056) |
| Generator contract | ModuleScript returns `{ Attributes = {...}, OnGenerate = function(parameters, targetContainer) end }`; `parameters.Attributes`, `parameters.Size`, `parameters:Pause()` for cooperative yields; anything not parented under `targetContainer` is discarded; use a fixed seed because generation re-runs on every property edit; errors via `GenerationError` / `WaitForGenerationAsync()` returning false | [DOC] [ProceduralModel](https://create.roblox.com/docs/reference/engine/classes/ProceduralModel) |
| Bake | Output lands in a `Generated` folder. Clearing `Generator` bakes it into a plain Model. Manual edits inside `Generated` are overwritten on regenerate. Not yet usable as Packages. Creator Store generators are sandboxed to their own hierarchy. Team Create can duplicate `Generated` folders | [DOC] [beta post](https://devforum.roblox.com/t/studio-beta-introducing-procedural-models-build-parametrized-3d-models-with-code-or-ai/4592056) |
| Official samples | "Default Generator" (attrs `BorderThickness`, `RandomSeed`; helpers set Parent last) and "Classic Ladder Generator" (`RungSpacing`, `RungThickness`, `PostSize`, `Color`; `parameters:Pause()` per rung) | [DOC] [ProceduralModel](https://create.roblox.com/docs/reference/engine/classes/ProceduralModel) |
| Runtime support | Studio-only during beta; "in-game generation can be expensive". Third-party claims of full release on 2026-05-18 with runtime support | UNVERIFIED |
| MCP | Quick Connect links Claude Code/Desktop/Cursor to Studio; a Data Model Search subagent searches large workspaces (2026-04-24) | [DOC] [Assistant updates](https://devforum.roblox.com/t/assistant-updates-the-data-model-search-subagent-and-quick-connect-for-mcp-clients/4596579) |
| Templates | The 23 official templates include no procedural, plot or tycoon template | [DOC] [Templates](https://create.roblox.com/docs/resources/templates) |

**Recipe: dual-mode generator skeleton (Derived).** Write every kit as a ProceduralModel-style module. Call it from MCP `execute_luau` today, and host it in a ProceduralModel once that is available in your build.

```lua
local Gen = {}
Gen.Attributes = { Seed = 1, Grid = 5, WallHeight = 15, Style = "Pastel" }
function Gen.OnGenerate(parameters, targetContainer)
    local A, size = parameters.Attributes, parameters.Size
    local rng = Random.new(A.Seed)                  -- pass rng down, never math.random
    -- 1) layout in cell space (BSP zones, anchors, Poisson clutter)
    -- 2) kit placement with PivotTo on the grid, Parent last, into targetContainer
    -- 3) handmade pass: jitter props, light fixtures, trim
    if parameters.Pause then parameters:Pause() end
end
function Gen.RunStandalone(root: Model, size: Vector3, overrides)
    local attrs = table.clone(Gen.Attributes)
    for k, v in pairs(overrides or {}) do attrs[k] = v end
    root:ClearAllChildren()
    Gen.OnGenerate({ Attributes = attrs, Size = size, Pause = function() end }, root)
    root:SetAttribute("Seed", attrs.Seed)
end
return Gen
```

**Persistence rule (Derived from the [DOC] bake model):** generate in Edit mode into `Workspace/Islands/<name>` and stamp the root Model with `Seed` and `GenVersion` attributes. Save the place, so the baked instances are the artifact. Regenerate only islands whose `GenVersion` is stale. Use runtime generation only for per-player contents, and build those by cloning pre-baked templates from **ServerStorage** (not ReplicatedStorage, which exploiters can clone from: [FORUM] [Problem making a tycoon](https://devforum.roblox.com/t/problem-making-a-tycoon/1742414)) with `PivotTo` onto plot anchors.

### 1.2 Every proven kit uses one coarse grid and corner pivots

| Rule | Number | Tag / source |
|---|---|---|
| Greybox snap | **5 studs / 90°** | [DOC] [Greybox](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/greybox-your-environment) |
| Doorways / hallways | **≥10 studs wide** (two players pass, camera doesn't clip) | [DOC] same |
| Wall height | **≥10 studs** (default jump = 5 studs) | [DOC] same |
| Character | ~5 studs tall × 4 wide; 1 stud ≈ 0.28 m (3.57 studs/m) | [FORUM] [Door dimensions](https://devforum.roblox.com/t/what-are-good-door-dimensions/539045); [studs per meter](https://devforum.roblox.com/t/how-many-studs-is-there-in-a-meter/103417) |
| Doors (community) | 5×7 studs common; "10 tall, 5 wide to be safe" | [FORUM] [Door dimensions](https://devforum.roblox.com/t/what-are-good-door-dimensions/539045) |
| Wall thickness | ≥1 stud; official sample 2.5; wrap mesh rooms in thick Parts to stop light leaks | [DOC] [Indoor lighting](https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-indoor-environments) |
| Kit piece minimum | every piece ≥5 studs tall and wide; largest divisible by smallest (sample 15×5 vs 5×5); one trim sheet across all building pieces | [DOC] [Develop polished assets](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/develop-polished-assets) |
| Pivot | at the "forward-most lower corner" (or mount point such as balcony/cornice edge). Centre pivots break snapping once rotated: "A 1-stud-wide part moved 5 studs from its center leaves 0.5 studs of overlap" | [DOC] [Assemble modular environments](https://create.roblox.com/docs/tutorials/use-case-tutorials/modeling/assemble-modular-environments) |
| Other official grids | Modern City mesh kit **7.5 studs** + 45°, collisions off; Beyond the Dark **16-stud** grid for a large station | [DOC] [Modular environments](https://create.roblox.com/docs/tutorials/use-case-tutorials/modeling/assemble-modular-environments); [Beyond the Dark](https://create.roblox.com/docs/resources/beyond-the-dark/building-architecture) |
| Multi-select trap | moving several meshes at once averages pivots and "destroys the alignment" | [DOC] same |
| Placement API | `PVInstance:PivotTo/GetPivot`; `Model.WorldPivot`; `Model:GetBoundingBox()`; `ScaleTo/GetScale`. **Deprecated:** `SetPrimaryPartCFrame`, `Model.moveTo` | [DOC] [PVInstance](https://create.roblox.com/docs/reference/engine/classes/PVInstance); [Model](https://create.roblox.com/docs/reference/engine/classes/Model) |
| Part shapes | `Enum.PartType` Ball 0, Block 1, Cylinder 2, **Wedge 3, CornerWedge 4** (wedges as `Part.Shape`) | [DOC] [PartType](https://create.roblox.com/docs/reference/engine/enums/PartType) |
| Overlap queries | `GetPartBoundsInBox/InRadius`, `GetPartsInPart` (Write Parallel); `BulkMoveTo(parts, cframes, mode)` | [DOC] [WorldRoot](https://create.roblox.com/docs/reference/engine/classes/WorldRoot) |
| Z-fighting | offset ≥0.01 stud or resize; "do not use Unions as a crutch"; a 0.001 offset drifted ~0.008 (2025-10); Textures can z-fight geometry ~2 studs away | [FORUM] [Glitchy blocks](https://devforum.roblox.com/t/glitchy-looking-blocks/566033/8); [drift report](https://devforum.roblox.com/t/parts-randomly-changed-their-size-when-using-a-z-fighting-prevention-trick/4007417); [Texture z-fight](https://devforum.roblox.com/t/texture-causes-z-fighting/401764) |

**Grid choice for Steal-a-Dream-scale rooms:** the curriculum's 5-stud grid matches the 5-stud character. 7.5 is tuned to Modern City meshes and 16 to a space station. No source states which grid top simulators use (UNVERIFIED).

**Seam rule (Derived):** butt-joined coplanar walls are fine. Never stack two faces on one plane: raise rugs 0.05, make trim 0.1-0.2 proud, and overlap wall modules 0.1 into a corner post that covers the joint. Treat 0.01 as the floor and 0.05-0.1 as the safe range given the drift report.

**Placement helper (Derived):**
```lua
local G = 5
local function normalizePivot(model: Model)          -- pivot to min corner
    local cf, size = model:GetBoundingBox()
    model.WorldPivot = cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2)
end
local function placeModule(template: Model, ix, iy, iz, rot, parent)
    local m = template:Clone()
    -- rotate about cell centre so a corner pivot doesn't sweep out of the cell
    m:PivotTo(CFrame.new(ix*G + G/2, iy*G, iz*G + G/2) * CFrame.Angles(0, math.rad(90*rot), 0) * CFrame.new(-G/2, 0, -G/2))
    m.Parent = parent                                  -- Parent last
    return m
end
```

### 1.3 Door-graph prefab rooms dominate Roblox generation; BSP and L-systems are DIY

| Algorithm | Best Roblox implementation found | Key details | Tag / source |
|---|---|---|---|
| Prefab rooms + door graph (dominant) | "Dungeon Generator (Page Update)", 2025-06-11, Creator Store 107507738735295 | Weighted pool in `ServerStorage.RoomTemplates` (`NumberValue Weight`), `SpawnPlacer` alignment part, `RoomSpawnPoints`, AABB rejection via `OVERLAPBOXS` parts, `FurnIsh` swaps placeholder parts for `ServerStorage.Objects` clones; no licence | [FORUM] [link](https://devforum.roblox.com/t/dungeon-generator-page-update/3707965) |
| Grid room graph + loops + retries | "SCP Procedural Facility Generator", 2026-07-11, .rbxl | Main path per zone + branches/loops; role-based template choice (corner, dead end); seeded; connectivity validation; **up to 35 retries then "Relaxed" fallback** (one seed: 211 rooms, no collisions); segment lengths cut from 4..9 to 2..5 because hallways felt empty | [FORUM] [link](https://devforum.roblox.com/t/scp-procedural-facility-generator/4731238) |
| DOORS-style chain | 2025-10-19 thread | Entrance/Exit parts; biome modules with weights; block impossible routes by removing a direction after a double turn | [FORUM] [link](https://devforum.roblox.com/t/what-is-a-good-approach-for-room-generation/4015405) |
| Voxel + MST corridors | `Mythus-Z/Procedural-Dungeon-Generation-Roblox-` (MIT, 1★) | Claims 2,000 rooms in ~0.5 s (author's claim, unbenchmarked) | [GH] [repo](https://github.com/Mythus-Z/Procedural-Dungeon-Generation-Roblox-) |
| Semi-procedural chunks | `RyanChang25/Dungeon-Generation-Service` (MIT, 3★, last 2022-06) | Six chunk categories (Start, Front, Left/Right Corners, Room End, Dungeon End), anti-loop checks | [GH] [repo](https://github.com/RyanChang25/Dungeon-Generation-Service) |
| Wave function collapse | One 2023 .rbxl demo (61.2 KB, side-name adjacency, lowest-entropy first) | GitHub search for "roblox wave function collapse" = 0 repos | [FORUM] [WFC](https://devforum.roblox.com/t/wave-function-collapse-algorithm/2747386); [GH] [search](https://github.com/search?q=roblox+wave+function+collapse&type=repositories) |
| Poisson-disk scatter | azqjanna, 2023-02-17: Bridson, **r = 5, k = 30**, annulus r..2r | Full Luau in post | [FORUM] [Poisson](https://devforum.roblox.com/t/poisson-sampling-example/2185617) |
| Bezier / splines | `bstummer/bezier` (any degree, normals, splitting; PolyBezier C1 joins) | The official "Bezier Curves" doc 404s | [GH] [bezier](https://github.com/bstummer/bezier); [FORUM] [post](https://devforum.roblox.com/t/2043623) |
| Runtime terrain | `maddoxbouldin/roblox-runtime-terrain` (2026-07, chunk streaming, parallel Luau) | Licence not shown | [GH] [search](https://github.com/search?q=luau+procedural+generation&type=repositories) |
| BSP, L-systems | **none found** | Write them yourself (~60 lines) | Gap |

Common failure mode: grid generators where rooms generate "backwards and fail to align with the grid" (32×32 grid, 2026) ([FORUM] [link](https://devforum.roblox.com/t/issues-with-procedural-room-generation/4764229)).

**For a single bedroom-on-an-island (Derived):** a dungeon chain is the wrong tool. Treat it as constrained placement inside one rectangle. BSP-split zones (bed, desk, play), put big furniture against walls, then run two Poisson passes for clutter: a small `r` near anchors and a larger `r` elsewhere. Keep sizes in cells, snap at the end, and store template weights as attributes.

```lua
local rng = Random.new(seed)
local function bsp(x0, z0, w, d, minW, minD, out)          -- Derived
    local canV, canH = w >= 2*minW, d >= 2*minD
    if not (canV or canH) or (w*d < 4*minW*minD and rng:NextNumber() < 0.5) then
        table.insert(out, {x=x0, z=z0, w=w, d=d}); return
    end
    if canV and (not canH or rng:NextNumber() < w/(w+d)) then
        local cut = rng:NextInteger(minW, w - minW)
        bsp(x0, z0, cut, d, minW, minD, out); bsp(x0+cut, z0, w-cut, d, minW, minD, out)
    else
        local cut = rng:NextInteger(minD, d - minD)
        bsp(x0, z0, w, cut, minW, minD, out); bsp(x0, z0+cut, w, d-cut, minW, minD, out)
    end
end
```

Poisson core loop as published ([FORUM] [link](https://devforum.roblox.com/t/poisson-sampling-example/2185617)):
```lua
while #active > 0 do
    local activeIndex = math.random(1, #active)
    local selActive = active[activeIndex]
    local placedAtLeastOne = false
    for _ = 1, k do
        local randomAngle = math.random() * math.pi * 2
        local randomRange = r * (math.random() + 1)
        local x = math.round(selActive.i + math.cos(randomAngle) * randomRange)
        local y = math.round(selActive.j + math.sin(randomAngle) * randomRange)
        if CheckActiveClearance(x, y) then PlaceActive(x, y); placedAtLeastOne = true end
    end
    if not placedAtLeastOne then table.remove(active, activeIndex) end
end
```
(Swap `math.random` for the seeded `rng` so layouts reproduce.)

### 1.4 Roofs, arches and clouds: three formulas cover most shapes

| Shape | Recipe | Tag / source |
|---|---|---|
| Gable roof gap | Extend slab length by `2*height*thickness/eaveWidth` (≈ `t·tanθ`); no solution when the ridge angle is <90°, so cap the ridge with a cylinder | [FORUM] [Roof gap](https://devforum.roblox.com/t/help-with-basic-roof-generation-resolving-a-small-gap-between-2-parts-at-top-is-my-formula-the-most-effective/831074) |
| Hip roof | WedgeParts for the two main slopes, CornerWedgeParts for the four hip corners | [FORUM] [Need help roof](https://devforum.roblox.com/t/need-help-to-create-a-roof/536971) |
| Octagonal/gazebo roof | 45° corner wedges (GapFill plugin automates) | [FORUM] [Gazebo](https://devforum.roblox.com/t/gazebo-roof-help/1337387) |
| Arc around a point | `focus.CFrame:PointToWorldSpace(CFrame.Angles(0, math.rad(i), 0).LookVector * r)` | [FORUM] [Arc](https://devforum.roblox.com/t/how-would-i-base-this-arc-about-a-lookvectordirection/3169994) |
| Chained arcs | Only continuous if segment X/Z sizes match the step | [FORUM] [Arc generator](https://devforum.roblox.com/t/creating-an-arc-generator/61059) |
| Segment count | Sagitta `s = r(1 − cos(π/n))`, chord `2r·sin(π/n)`. For s < 0.1 stud: **r 4 → n 16 (s 0.077); r 8 → n 24 (0.068); r 16 → n 32 (0.077)**; halve n for a 180° arch. For an owned low-poly look, n = 8-12 visible facets | Derived |
| Bevel look | One imported ~80-triangle beveled cube reused everywhere (Cardboard Box Simulator) batches to one draw call; townhouses went from 12 draws/~100 instances to 6 draws/6 meshes | [FORUM] [McNeill optimization](https://devforum.roblox.com/t/3127146) |

Ring placer (Derived): a 2% chord overlap hides hairline seams.
```lua
local function ring(center: CFrame, r, n, a0, a1, h, t, parent)
    local step = (a1 - a0) / n
    local chord = 2 * r * math.sin(step / 2) * 1.02
    for i = 0, n - 1 do
        local p = Instance.new("Part"); p.Anchored = true
        p.Size = Vector3.new(chord, h, t)
        p.CFrame = center * CFrame.Angles(0, a0 + (i + 0.5) * step, 0) * CFrame.new(0, h/2, -r)
        p.Parent = parent
    end
end
```

**Terrain for cloud islands [DOC]** ([Terrain class](https://create.roblox.com/docs/reference/engine/classes/Terrain); [Terrain guide](https://create.roblox.com/docs/parts/terrain)): voxels are 4×4×4 studs. There are 22 materials plus Air, and the editable range is ±128,000 studs per axis. `FillBall/FillBlock/FillCylinder/FillWedge` take studs and overwrite. `FillRegion`/`WriteVoxels` need resolution exactly 4 and `Region3:ExpandToGrid(4)`. `WriteVoxels` caps at **4,194,304 voxels per call** (e.g. a 640×160×640-stud block). Only `WriteVoxels`/`WriteVoxelChannels` give fractional occupancy, which is what soft cloud rims need (0.3-0.7 at the edge, Derived). Fill methods require `Capabilities: Environment`. The Studio MCP context is UNVERIFIED in docs but has worked in practice. Terrain can't be tinted beyond its materials (Snow/Glacier/Salt are the whites). For pastel clouds, use overlapping `Ball` Parts (SmoothPlastic, CastShadow off). **Deprecated:** `SetCell(s)`, `GetCell`, `AutowedgeCell(s)`, `ConvertToSmooth`, `IsSmooth`.

### 1.5 "Hand-made" comes from set dressing, colour zoning and light pools, not geometry

| Technique | Specific values | Tag / source |
|---|---|---|
| Lighting style | Switch Soft → **Realistic** so local lights cast shadows indoors | [DOC] [Construct your world](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/construct-your-world) |
| Indoor warm-room preset | EnvironmentDiffuse/SpecularScale 1; ClockTime 15.6; **Ambient 83,70,57** (default 70,70,70); **ExposureCompensation 0.5**; SunRays Intensity 0.023 / Spread 0.266; **Atmosphere Density 0.5** ("0 cold and dark; 0.5 warm and hazy"); ColorCorrection **Contrast 0.05, Saturation 0.1** | [DOC] [Indoor lighting](https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-indoor-environments) |
| Local lights | Candle PointLight Brightness 0.7, Color 255,202,156, Shadows on; desk SpotLight Angle 140, Brightness 4, Range 12, Color 255,238,202; radio SurfaceLight Brightness 2, Range 4, Color 146,255,251; lights placed so attention moves fireplace → window → exit; one point light per candle group (cost) | [DOC] same |
| Fixtures | Perimeter glow = Neon part + SurfaceLight; doorway accent = Neon part + SpotLight; spawn = ceiling-sized Neon slab in zone colour; skylight glass Neon, Transparency 0.6, 105,162,172 | [DOC] [Construct your world](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/construct-your-world) |
| Atmosphere particles | Foreground clouds: ParticleEmitter Size 100, Lifetime 30, Rate 0.25, LightEmission 0.3, LightInfluence 0.2, Squash −0.25, Drag 0.1, Acceleration (0,−0.8,0), textures rbxassetid://10714362544 / 10714433747, plus a second emitter at Rate 0.1; dust Color 192,241,255, Rate 50000, Lifetime 1-10, Speed 1-5, texture 14302399641 | [DOC] same |
| Colour zoning | Distinct hue per zone; greybox colours 255,176,0 / 255,89,89 / 16,42,220 / 75,151,75; different indoor vs outdoor floor material; one tower "much larger than the player" for scale | [DOC] [Greybox](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/greybox-your-environment); [Construct](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/construct-your-world) |
| Break tiling | Grunge decal/texture child on wall meshes; props (balconies, AC units, foliage) to look "lived in" | [DOC] [Modular environments](https://create.roblox.com/docs/tutorials/use-case-tutorials/modeling/assemble-modular-environments) |
| Clean trims | Keep trim textures clean (grime reads as repetition); heavy wear only on unique hero assets | [DOC] [Duvall Drive materials](https://create.roblox.com/docs/resources/the-mystery-of-duvall-drive/materialize-the-world) |
| Colour variation | A per-part colour-offset plugin with a "roughness" control; author planned seeded/Perlin variation | [FORUM] [topic 2333459](https://devforum.roblox.com/t/2333459) |
| Interior critique set | "The walls look empty" → plants, wall trim; randomise repeated props (remove half the hangers, rotate the rest 5-25°); swap overheads for spotlights; darken pillars/roof for contrast; "add outlines, margins, pillars, and contrast, while trying to not overdo it" | [FORUM] [Builds look better](https://devforum.roblox.com/t/how-can-i-make-my-builds-look-better/3038390) |
| Low-poly material convention | SmoothPlastic, one material family per build, few textures | [FORUM] [Low poly build](https://devforum.roblox.com/t/how-can-i-make-a-low-poly-build/539908); [Stylized Low Poly](https://devforum.roblox.com/t/stylized-low-poly/3780170) |
| Stylized exemplars | Dandy's World: all floors handmade (19 at May 2025, wiki now 26), rubber-hose 1930s reference, point lights "draw players into rooms", one art director checks every asset. Ahlvie: "cute, stylized fantasy, with bold colors, natural lighting, and a variety of flowers", curved paths, unique flower per floor | [DOC] [Qwelver spotlight](https://devforum.roblox.com/t/creator-spotlight-how-qwelver-dreamed-up-dandy%E2%80%99s-world/3639226); [Ahlvie spotlight](https://devforum.roblox.com/t/creator-spotlight-meet-ahlvie-the-environmental-artist-behind-fantastical-worlds/2964648) |

**Handmade pass (Derived; values unsourced practice):**
```lua
local function jitterProp(model: Model, posJ, yawDeg, scaleJ, hueJ, rng)
    local cf = model:GetPivot()
    model:PivotTo(cf * CFrame.new(rng:NextNumber(-posJ, posJ), 0, rng:NextNumber(-posJ, posJ))
                     * CFrame.Angles(0, math.rad(rng:NextNumber(-yawDeg, yawDeg)), 0))
    model:ScaleTo(model:GetScale() * (1 + rng:NextNumber(-scaleJ, scaleJ)))
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") and p.Material ~= Enum.Material.Neon then
            local h, s, v = p.Color:ToHSV()
            p.Color = Color3.fromHSV((h + rng:NextNumber(-hueJ, hueJ)) % 1, s, math.clamp(v + rng:NextNumber(-0.04, 0.04), 0, 1))
        end
    end
end
-- books/toys (0.3, 25, 0.08, 0.02); furniture (0.15, 4, 0.03, 0.01); structural kit: never jitter
```
Tilt (X/Z, 1-3°) only things that can lean: frames, books, cushions. Use ≤3-4 Materials per room and tint via `Color`. Vary the skyline (headboards, lamps, stacked boxes) and give each island one oversized landmark.

**Pixar bedroom scale (Derived from the 5-stud rig and the cited minimums, not published):** ceiling 14-20 studs, door 6-7 wide × 10 tall, walls 1-2.5 thick, bed ~8-10 studs long. Outline/cel shading: no cited top game uses it (UNVERIFIED).

### 1.6 Top base games share one map skeleton: hub plus ring of plots, growth by slots, floors and skins

| Game | Structure | Numbers | Tag / source |
|---|---|---|---|
| Steal a Brainrot | Grid of slots; single entrance → corridor → back "Secret" slots (linear gauntlet); traps on that path; up to 3 sentry turrets in zigzag; 5 lock tiers | Floor 1 = 10 slots (Rebirth 0-1), Floor 2 = 11-18 (R2-9), Floor 3 = 19-25 (R10-17), Floor 4 = 26-31 (R18+); lock 60 s +10 s/rebirth, +10 s VIP; skins 799-999 Robux, earned at 60-90% index with a mutation. Floor-unlock thresholds conflict between guides (R2 vs R8) → UNVERIFIED | [GUIDE] [TechWiser](https://techwiser.com/steal-a-brainrot-base-skins-how-get-guide/); [RBLXGuide](https://rblxguide.com/games/steal-a-brainrot/updates/steal-a-brainrot-best-base-layouts-2026) |
| Grow a Garden | Fenced plots facing hub; expand left/right then Back T1, T2, **never the front** | 5 shops, stock refresh every 5 min; back-tier timers 24 h / 3 days with 199 / 399 Robux skips; prices conflict (UNVERIFIED); 751 cosmetics, 57 cosmetic crates | [GUIDE] [Beebom](https://beebom.com/how-to-expand-plot-in-grow-a-garden-roblox/); [WIKI] [Bloxodes](https://bloxodes.com/wiki/grow-a-garden/plot-expansions) |
| Steal an Egg | Biomes gated by speed (Forest 0 → Enchanted Forest 50B); nest → run → base loop; Pen capacity upgrades; Treadmill at $1,000 | — | [GUIDE] [games.gg](https://games.gg/roblox/guides/steal-an-egg-beginner-guide/) |
| Pet Simulator 99 | Numbered linear chain, 279 areas (Spawn 99, Tech 100, Void 40, Fantasy 40); one hero landmark per area; world transitions via landmark machines (rocket after Rebirth 4, Black Hole after Rebirth 8) | Unlocks 900 / 2.5k / 8k / 20k / 60k / 150k / 400k coins | [WIKI] [Bloxodes](https://bloxodes.com/wiki/pet-simulator-99/areas) |
| Adopt Me | Pre-built houses (56) + catalog (1,966 furniture, 198 surfaces); Premium Plots gamepass moves the home near the Nursery (proximity is monetised) | — | [WIKI] [Bloxodes](https://bloxodes.com/wiki/adopt-me) |
| Bloxburg | Free placement on plot; precision sold as gamepasses (Advanced Placing, Transform Plus, Large Plot 50×50, Basement) | Grid/rotation steps UNVERIFIED | [WIKI] [Bloxodes](https://bloxodes.com/wiki/welcome-to-bloxburg) |
| Bee Swarm | Hub + gates; Hive Hub with 36 hives; tiled flower fields (Clover 26×29 = 754) | — | [WIKI-snippet] [Hive Hub](https://bee-swarm-simulator.fandom.com/wiki/Hive_Hub) |
| Dress to Impress | Station-ordered dressing room → salon → VIP → runway; teleport menu, not walking | 18 items/outfit (24 with pass) | [GUIDE] [Pixel Twelve](https://pixeltwelve.com/articles/dress-to-impress-freeplay-mode) |
| Fisch | Islands ~1,000-3,000 studs apart around a statue landmark (e.g. Moosewood 400,135,250) | — | [GUIDE] [Mejoress](https://www.mejoress.com/fisch-map-guide-coordinates-npcs/) |
| 99 Nights | Campfire safe hub; Forest connects all; per-run Snow **or** Volcanic biome (50/50) | — | [GUIDE] [RBLXGuide](https://rblxguide.com/games/99-nights-in-the-forest/updates/map-locations-guide) |

**Rules for Steal a Dream (Derived):** use a compact hub holding every shop and sell point, with bedroom islands ringed around it and their fronts facing the hub. Progression means more display slots, then loft/attic tiers, then whole-room theme skins, never freeform building. If stealing exists, give each base one obvious entrance → corridor → back "vault" read. Plot counts per server, ring radii and hub geometry for GaG, Brainrot and Steal an Egg are UNVERIFIED (Fandom pages returned HTTP 402).

**Plot claim (Derived):**
```lua
local function claimPlot(player: Player): Model?
    for _, plot in ipairs(workspace.Plots:GetChildren()) do
        if not plot:GetAttribute("Owner") then
            plot:SetAttribute("Owner", player.UserId)
            local room = ServerStorage.RoomTemplates.Bedroom_A:Clone()   -- Clone, never move the original
            room.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
            room:PivotTo(plot.Anchor.CFrame)
            room.Parent = plot
            return plot
        end
    end
end
```

### 1.7 Blender → Studio: 1 unit = 1 stud, one trim sheet, packages for instancing

| Spec | Value | Tag / source |
|---|---|---|
| Mesh triangle limit | **20,000 per mesh**; ≤4 bone influences/vertex; watertight | [DOC] [Modeling specs](https://create.roblox.com/docs/art/modeling/specifications) |
| Units | No conversion: 2 m in DCC = 2 studs; set Studio snap 1 stud so the Blender grid = 1 stud | [DOC] [Beyond the Dark](https://create.roblox.com/docs/resources/beyond-the-dark/building-architecture); [FORUM] [Realism 101](https://devforum.roblox.com/t/realism-101-building-in-roblox-using-blender/4081400) |
| Texture size | Engine up to 4096² but UV guidance "up to 1024×1024"; 256² for 5×5-stud object, 512² for 10×10, 1024² for 20×20; Normal maps **OpenGL tangent-space only**; flat normal 127,127,255 | [DOC] [Texture specs](https://create.roblox.com/docs/art/modeling/texture-specifications); [SurfaceAppearance](https://create.roblox.com/docs/art/modeling/surface-appearance) |
| Trim sheet | Square, ≤1024, six rows of treatments in the sample; ~90% of architecture on a few trim sets (Beyond the Dark) | [DOC] [Develop polished assets](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/develop-polished-assets) |
| Tinting | `SurfaceAppearance.Color` multiplies texels; near-white greyscale tints hardest; "Tinting has no performance cost" | [DOC] [SurfaceAppearance](https://create.roblox.com/docs/art/modeling/surface-appearance) |
| 3D Importer | .fbx/.obj/.gltf (only fbx/gltf carry multi-mesh/PBR/rigs/vertex colours); Set Pivot to Scene Origin on, Use Imported Pivot on, Merge Meshes off, Make Double Sided off | [DOC] [3D Importer](https://create.roblox.com/docs/art/modeling/3d-importer) |
| Material tiers | Unique 1:1 SA for hero meshes; shared trim SA for furniture/architecture; MaterialVariants for Parts/terrain; texture sizes often dropped 1-2 steps (leather: Normal 1024, BaseColor 512, Roughness 256) | [DOC] [Duvall Drive](https://create.roblox.com/docs/resources/the-mystery-of-duvall-drive/materialize-the-world) |
| Packages | SurfaceAppearance → Convert to Package (AutoUpdate); one wall-panel package had >1,000 instances | [DOC] [Asset library](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/assemble-an-asset-library); [Beyond the Dark](https://create.roblox.com/docs/resources/beyond-the-dark/building-architecture) |
| Per-part flags | Anchor everything but doors; CanCollide off on foliage; CanQuery off where raycasts needn't hit; CastShadow off where unnoticed; Box/Hull collision for trim | [DOC] [Asset library](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/assemble-an-asset-library) |
| Layout process | 2D layout by story beats → box rooms → test "with an avatar"; furniture spreadsheet per room; "spacious, but not absurdly large" | [DOC] [Duvall Drive house](https://create.roblox.com/docs/resources/the-mystery-of-duvall-drive/construct-the-house) |
| Low-poly texturing | Collapse UVs onto a tiny palette/gradient image | [VIDEO] [Gradient trick](https://www.youtube.com/watch?v=9ITJgW9hVrE); [Color palettes](https://www.youtube.com/watch?v=fNZtXN0WOec) |

### 1.8 Performance: draw calls beat triangles; budget 500 draws / 500k tris on phones

| Rule | Value | Tag / source |
|---|---|---|
| Batching | Identical meshes batch only if MeshContent **and** SurfaceAppearance (or TextureContent, or Material) match; re-imports get new IDs and break instancing ("import maps as individual assets and duplicate them in Studio"); decals/textures/particles batch poorly; "Draw calls matter more than triangle count" | [DOC] [Improve performance](https://create.roblox.com/docs/performance-optimization/improve) |
| Texture memory | 1024² = 4× 512²; most images ≤512², minor ≤256² | [DOC] same |
| Collision | Box lowest cost → Hull → Default → PreciseConvexDecomposition; decor: CanCollide/CanTouch/CanQuery false and still Box/Hull | [DOC] [Collisions](https://create.roblox.com/docs/workspace/collisions) |
| RenderFidelity Automatic | <250 studs highest, 250-500 medium, ≥500 lowest | [DOC] [Meshes](https://create.roblox.com/docs/parts/meshes) |
| Frame budget | 16.67 ms at 60 FPS; MicroProfiler Ctrl+F6; orange = jobs, blue = render, red = GPU wait >2.5 ms | [DOC] [MicroProfiler](https://create.roblox.com/docs/studio/microprofiler) |
| Streaming | `StreamingMinRadius` 64 / `TargetRadius` 1024 (keep defaults); StreamOutBehavior Opportunistic; ModelStreamingBehavior Improved; IntegrityMode PauseOutsideLoadedArea; models under ~64 studs extent stream together; test at TargetRadius 64; guard one-time effects with a `Spawned` attribute | [DOC] [Instance streaming](https://create.roblox.com/docs/workspace/streaming); [Techniques](https://create.roblox.com/docs/workspace/streaming/techniques) |
| Community budget | **500,000 tris / 500 draw calls**, client memory <1.3 GB on 2 GB phones, network well under 50 KB/s; map ~300k/300 fixed, ~200k/200 flexible; zones ~100×100 studs, 5-8 visible, ~40k tris/40 draws each; each ParticleEmitter and Beam = 1 draw call; Detail_Small culled beyond 300 studs, checking 50 objects/frame | [FORUM] [McNeill, 2024-08-20](https://devforum.roblox.com/t/3127146) |
| Bulk builds | Set Parent last; yield when `os.clock()-t0 > 1/60`; destroy ~1,000 parts/0.1 s; reparenting a 13,000-part map to ReplicatedStorage avoided a ~0.5 s freeze (anecdotal) | [FORUM] [Parent PSA](https://devforum.roblox.com/t/30296); [Regenerate map](https://devforum.roblox.com/t/how-to-regenerate-a-map-without-lagging/3977310) |

Decor defaults (Derived, all [DOC]-backed): `Anchored=true; CanCollide=false; CanTouch=false; CanQuery=false; CastShadow=false` for anything under ~1 stud. MeshParts get `CollisionFidelity=Box` and `RenderFidelity=Automatic`. Twenty islands × ~2,200 parts needs StreamingEnabled, with each room an Atomic model or split sub-models.

### 1.9 Player placement: one licensed module, the rest need rewrites

| Module | Licence / status | Features | Tag / source |
|---|---|---|---|
| zblox164/PlacementService v1.6.2 | **Apache-2.0**, 21★, "not updated in over two years" | Grid/no-grid, rotation + tilt, collision colours, stacking, floors, server-side placement, PC/Xbox/mobile | [GH] [repo](https://github.com/zblox164/PlacementService) |
| dementional/PlacingService | No LICENSE file (author: use without credit); rewrite 2026-05-14 | Client-only; GridUnit 1, RotationUnit 15°, LerpSpeed 25, R rotate / X cancel | [GH] [repo](https://github.com/dementional/PlacingService) |
| Known bug | Rotated-plot collision errors from flooring the grid offset per axis; floor the whole result | | [FORUM] [link](https://devforum.roblox.com/t/placement-system-detecting-unwanted-collisions-on-rotated-plots/2044928) |

No open-source module ships DataStore save/load of layouts. The Derived stack is: 1-stud grid (0.5 as a premium "precise" mode), 15° or 45° steps, CFrames stored relative to the island origin, client preview plus server re-validation, and `{itemId, relCFrame, colorTint}` serialized per item.

### 1.10 Low-effort vs polished: the build review checklist

Low-effort markers per reviewers: "random models thrown in there", mixed low-poly and realistic styles, purposeless props ("ask why each object is placed where it is"), one material everywhere, flat roofs and blank walls, scale ignoring the "3 robloxians tall" tree, and passed-off free models ([FORUM] [Feedback on a build](https://devforum.roblox.com/t/feedback-on-a-build/1856452); [Less boring](https://devforum.roblox.com/t/how-can-i-make-these-buildings-and-map-less-boring-but-keeping-the-classic-look/2869129)). "Lighting isn't going to make your city detailed on its own." Creator Store free "low poly bedroom" hits exist (e.g. [8390966414](https://create.roblox.com/store/asset/8390966414)). No verified-creator stylized bedroom or cloud kit was found, and paid kits carry attribution or non-commercial terms (e.g. the itch.io 50-asset pack is **personal non-commercial only**: [STORE] [link](https://iterminal.itch.io/low-poly-furniture-pack-50-stylized-game-ready-assets-for-unity-unreal-roblox)). Use free models only as greybox placeholders, as Duvall Drive did.

**Checklist (Derived, aligned to [DOC] and [FORUM] language):** (1) one style, one kit, one trim sheet; (2) no wall without trim plus one object; (3) every repeated prop varied by tint, rotation or accessory; (4) ≥1 shadowed light pool per focal point; (5) each island colour-coded so it is recognisable from the hub; (6) one oversized landmark per island; (7) every prop scale-checked against a 5-stud rig.

---

## Part 2. Motion: tweens choreograph, springs respond, and rarity escalates every channel

### 2.1 Pick the motion tool by whether the player can interrupt it

| Library | Stars / last push | Use | API essentials | Tag / source |
|---|---|---|---|---|
| TweenService | Built-in; "not being deprecated" | Fixed-duration beats needing `Completed` (cutscenes, hatches, fades) | Defaults Quad/Out; `GetValue(alpha, style, dir)` for custom per-frame curves; `SmoothDamp(...)` | [DOC] [TweenService](https://create.roblox.com/docs/reference/engine/classes/TweenService); [UI animation](https://create.roblox.com/docs/ui/animation) |
| Styling Transitions | Full release **2026-07-27** | Stateless hover/press on tagged buttons; native, "outperform manual Luau tweening" | `rule:SetPropertyTransitions({ BackgroundColor3 = TweenInfo.new(0.25) })`; selector `.Tagged:Hover`; fire only on Tag/GuiState changes, not layout size; per-property beats `["*"]` | [FORUM/DOC] [Styling Transitions](https://devforum.roblox.com/t/full-release-styling-transitions/4646870) |
| spr (Fraktality) | 146★, 2024-07-31, MIT, stable | Interruptible UI/props | `spr.target(obj, dampingRatio, frequency, props)`, `spr.completed`, `spr.stop`; Model `Pivot`/`Scale` pseudo-props; README: ratio 1/freq 1 = slow no overshoot; **0.6/4 = quick overshoot and wobble** | [GH] [spr](https://github.com/Fraktality/spr); [FORUM] [spr](https://devforum.roblox.com/t/spring-driven-motion-spr/714728) |
| Ripple (littensy) | 134★, 2026-07-18, MIT, active | Springs + tweens, React-friendly | `createMotion`; spring defaults **tension 170, friction 26, mass 1**, precision 0.001; button: hover `setGoal(20)`, press `setGoal(-20, {impulse=-100})` | [GH] [ripple](https://github.com/littensy/ripple) |
| Otter (Roblox) | 23★, 2026-09-02, read-only mirror | Roblox's in-house spring lib (+ReactOtter) | `frequency` default 1, `dampingRatio` default 1; `Otter.instant(v)` | [GH] [otter](https://github.com/Roblox/otter); [docs](https://roblox.github.io/otter-internal/usage/goals) |
| Nevermore Spring | 624★ (monorepo), 2026-10-22 | Camera offsets, shake | `Spring.new(v)`, Target/Position/Velocity/Damper(1)/Speed(1), `Impulse(v)` | [GH] [Spring.lua](https://raw.githubusercontent.com/Quenty/NevermoreEngine/main/src/spring/src/Shared/Spring.lua) |
| Flipper | 144★, 2021-11-25 | **Avoid** (untouched ~5 years) | | [GH] [Flipper](https://github.com/Reselim/Flipper) |
| RbxUtil Shake | 470★, 2026-08-11 | Perlin camera shake, maintained | Amplitude/Frequency/FadeIn/FadeOut/Sustain; `InverseSquare` falloff | [GH] [Shake](https://sleitnick.github.io/RbxUtil/api/Shake) |
| RbxCameraShaker | 128★, 2023-07 (stale) | Presets Bump, Explosion, Earthquake… | `ShakeOnce(mag, rough, fadeIn, fadeOut)`; conflicts if you also set CFrame at the same priority | [GH] [repo](https://github.com/Sleitnick/RbxCameraShaker) |
| GG-CameraShake | 1★, 2026-07 | New; `SetStrengthScale()` accessibility multiplier | | [FORUM] [link](https://devforum.roblox.com/t/gg-camera-shake-screenshake-that-doesnt-suck/4731267) |

spr's own guidance: "Critical damping is recommended as the most visually neutral option," and "Underdamping is recommended for animations that need to 'pop.'" Re-targeting mid-flight blends "in a physically-accurate way." That blending is why springs own anything interruptible. No library named "Motion" exists; Otter is Roblox's. Ripple `config.*` preset numbers are UNVERIFIED (its `src/config.luau` returned 404).

### 2.2 Timing sheet: what is sourced and what is a tuned default

| Interaction | Value | Basis |
|---|---|---|
| Roblox defaults | Quad / Out; easing ladder Linear → Sine → Quad → Cubic → Quart → Quint → Exponential → Circular → Back → Bounce → Elastic; Linear ignores direction | [DOC] [UI animation](https://create.roblox.com/docs/ui/animation) |
| Styling transition sample | 0.25 s; per-property Cubic Out 0.5 s | [FORUM/DOC] [Styling Transitions](https://devforum.roblox.com/t/full-release-styling-transitions/4646870) |
| Hover pop | 0.2 s Back Out from AnchorPoint (0.5,0.5); never InOut on hover | [FORUM] [hover](https://devforum.roblox.com/t/button-hover-effect/1275766); [InOut](https://devforum.roblox.com/t/trouble-with-hover-tweening/2618400) |
| Button press | 80-120 ms to 0.9 scale; visible feedback within 100 ms | [BLOG] [eastondev feel](https://eastondev.com/blog/en/posts/dev/20260521-game-feedback-feel/) |
| Material 3 tokens | short1 50 … short4 200, medium1 250, medium2 300 … long4 600, extralong4 1000 ms; standard curve (0.2,0,0,1), emphasized-decelerate (0.05,0.7,0.1,1); "standard + 300 ms direct; emphasized + 650 ms stylized" | [DOC-ish] [Flutter Durations](https://api.flutter.dev/flutter/material/Durations-class.html); [GH] [motion.dart](https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/motion.dart); [Material](https://material.io/design/motion/customization.html) |
| Typewriter text | 0.05 s per grapheme (`MaxVisibleGraphemes`), 1 s pause | [DOC] [UI animation](https://create.roblox.com/docs/ui/animation) |
| Microinteractions | 100-300 ms | [BLOG] [uxdesign.cc](https://uxdesign.cc/disneys-12-principles-of-animation-exemplified-in-ux-design-5cc7e3dc3f75) |

**Derived house sheet (starting values to tune):**

| Element | In | Out |
|---|---|---|
| Press | 0.08-0.12 s Quad Out to 0.92-0.95 | release 0.18-0.25 s Back Out, or spr 0.6-0.7 / 5 |
| Hover | 0.15-0.2 s Quad Out to 1.04 | same |
| Panel | 0.25-0.35 s Quint Out from 0.9 scale + GroupTransparency 1→0 (or spr 1 / 2-3) | 0.15-0.2 s Quad In (exits faster than entries) |
| Toast | 0.3 s Back Out, hold 2-3 s | 0.2 s |
| Full-screen fade | 0.3-0.5 s Quad | 0.4-0.6 s up |
| Counter roll-up | 0.4-0.8 s Quint Out (or spr 1 / 1-2 on a NumberValue, format in `.Changed`), 1.15 pop on gain | |
| List stagger | 30-50 ms per item | |
| Reduced motion | shorten or skip when `GuiService.ReducedMotionEnabled` | [DOC] [GuiService](https://create.roblox.com/docs/en-us/reference/engine/classes/GuiService) |

### 2.3 Hatch and reveal: two published code paths, plus a rarity-escalation layer

No developer breakdown of PS99, Adopt Me, GaG or Brainrot hatch choreography exists in text. Videos confirm only that top tiers get distinct animations: PS99 "Huge Hatch Animation" ([VIDEO](https://www.youtube.com/shorts/1N34Pk0tfbs)) and Adopt Me "ALL NEW HATCH Animations", ~Aug/Sep 2026 ([VIDEO](https://www.youtube.com/watch?v=WjehLwJ577I)). PS99 Update 61 (2025-05-24) signals rarity **on the egg before hatching** ("Eggs can now transform into Golden, Rainbow, or Shiny") ([BLOG, BIG Games](https://www.biggames.io/post/pet-simulator-99-update-61)).

| Beat | Shr3ne ViewportFrame framework (2021) [FORUM] [link](https://devforum.roblox.com/t/pet-hatching-framework-part-1/1480291) | Aceleith camera-pinned egg (2023) [FORUM] [link](https://devforum.roblox.com/t/how-to-achieve-egg-hatch-animation-without-the-use-of-viewportframes/2568503) |
|---|---|---|
| Setup | Egg in `HatchFrame` ViewportFrame, camera at `CFrame.new(0,0,6)`; slots x = 0, ±4.5, rot 0/±45°; **BlurEffect Size 26** | Egg tweens from below camera to front **0.75 s Back In**, wait 1 s; pinned via `BindToRenderStep(Camera+1)` |
| Anticipation | Lift +10 studs, **0.65 s Quad In** | — |
| Build-up | **10 cycles of ±15° Z wobble, step 0.11 s minus 0.007 s per cycle** (accelerating) | Tilt −45° (0.2 s Quad In), wait 0.5, +45° (0.2 s), wait 0.5, 0° (0.2 s), wait 0.5; shrink 0.4 s, wait 0.8 |
| Impact | Flash image to transparency 1 and 1.5× over **0.2 s** | Expand + Transparency 1 (0.2 s) |
| Reveal | Pet cloned, rotated ~1.35 rad; name + rarity label; **hold 1 s** | Pet at camera offset (0,0,−8), drops + rotates 180° (1 s Quad In), bobs 0.5 s up / 0.5 s down |
| Exit | Blur fades 10 × 0.05 s; frame to `UDim2.fromScale(0,1)` 0.2 s; ≈4.1 s total | After 2 s, text fades 0.2 s, pet shrinks 0.4 s |
| Weakness | Rarity only tints text (flash tint commented out); no sound | Tweening rotation fights the per-frame re-pin |

Pinned-egg snippet ([FORUM] [link](https://devforum.roblox.com/t/egg-hatching-animation/2542547)):
```lua
RunService.RenderStepped:Connect(function()
    EggModel.CFrame = workspace.CurrentCamera:GetRenderCFrame() * CFrame.new(0, 0, -8)
end)
```
**ViewportFrames cannot render ParticleEmitters** (same thread). Particle-heavy reveals therefore need the camera-pinned model or an authored Animation on a rig. Fix the tween-vs-pin fight by tweening a `CFrameValue` or Motor6D offset that the pin loop reads (Derived). Do the roll and coin deduction on the server with separate single/triple remotes, and run animation client-side ([FORUM] [2025 pet system](https://devforum.roblox.com/t/new-how-to-make-a-pet-system-in-roblox-2025-high-effort-post/3792525)).

**Production hatch (Derived from the sourced pieces):**
1. Anticipation: lift 0.6-0.75 s Back/Quad In while blur/DOF ramps and a rumble starts.
2. Build-up: Shr3ne's accelerating wobble (0.11 → ~0.04 s), with camera `ShakeOnce` magnitude scaled by tier.
3. Impact: 0.1-0.2 s flash + `ParticleEmitter:Emit(n)` + hit sound within 20 ms of the flash frame, plus an optional 50-100 ms hit-stop via `AdjustSpeed(0)`.
4. Reveal: creature springs from scale 0 (spr 0.5-0.6 / 4-5 on `Scale`) while rarity colour fills the label.
5. Settle: 1 s hold, exit with short Quad In.

Escalation means multiplying shake, particle count (10 → 60), flash duration and hold time by tier, adding a Highlight pulse, and sending a server-wide notification for top tiers.

### 2.4 Feel numbers (engine-neutral, with provenance)

| Channel | Number | Tag / source |
|---|---|---|
| Hit-stop | 0.05-0.1 s; hit stop, sound coherence and camera control rank highest for impact (Lin et al. 2022, as cited) | [BLOG] [eastondev](https://eastondev.com/blog/en/posts/dev/20260521-game-feedback-feel/); [Wayline](https://www.wayline.io/learn/game-feel/1) |
| Flash | 50-100 ms (30 ms unnoticed, 150 ms blurry) | [BLOG] eastondev |
| Screen shake | weak 2-3 px, strong 8-10 px, duration matched to flash | [BLOG] eastondev (attributed to Sense Central) |
| Audio sync | perceptible beyond ~20 ms; <15 ms linked to 22% faster confirmation (attributed to Sony Labs) | [BLOG] eastondev |
| Sequencing | vibration + sound at 0, flash +20 ms, particles +50 ms, text +100 ms; particles 20-30, 0.5-1 s life; floating text 1-2 s; cap 3-5 feedbacks/s | [BLOG] eastondev |
| Roblox hit-stop | No `AnimationTrack:Pause()`; `AdjustSpeed(0)` after `Play()`; raise Priority above Core; freeze on clients, not the server | [FORUM] [Pausing animations](https://devforum.roblox.com/t/pausing-animations/288995) |
| Shake example | RbxUtil: FadeInTime 0, Frequency 0.1, Amplitude 5, RotationInfluence (0.1,0.1,0.1), bound at RenderPriority.Last | [GH] [Shake source](https://raw.githubusercontent.com/Sleitnick/RbxUtil/main/modules/shake/init.luau) |

### 2.5 Cutscenes and camera: scriptable camera, Focus every frame, compose shake in the same step

| Fact | Detail | Tag / source |
|---|---|---|
| Scriptable camera | `CameraType = Scriptable` (value 6); drive `CFrame`; **update `Focus` every frame** (render detail depends on it); FOV 1-120, default 70; restore afterwards | [DOC] [Camera](https://create.roblox.com/docs/workspace/camera); [CameraType](https://create.roblox.com/docs/reference/engine/enums/CameraType) |
| Deprecated | `Camera:Interpolate`, `SetRoll/GetRoll`, `CoordinateFrame`, `InterpolationFinished` | [DOC] [Camera class](https://create.roblox.com/docs/reference/engine/classes/Camera) |
| Tutorial pattern | Scenes `{InitialOffset, EndOffset, TweenInfo, Delay}`; offsets captured via `rootPart.CFrame:ToObjectSpace(camera.CFrame)`; 7 s Cubic InOut (+3), 6 s Sine InOut (+2), 5 s Quart InOut (+2) | [FORUM] [Camera cutscenes](https://devforum.roblox.com/t/how-to-create-camera-cutscenes/1629318) |
| CutsceneService (Vaschex) | MIT, pushed 2026-04-26; `Create(folder, 5)` with parts named "1","2"…; Play/Pause/Resume/Cancel; easing strings incl. "InOutSine" | [FORUM] [718571](https://devforum.roblox.com/t/718571); [GH] [repo](https://api.github.com/repos/Vaschex/CutsceneService) |
| CineCam v3 plugin | $5.99 (2026-07); per-keyframe FOV, Duration, hard cut, Track, Shake; Catmull-Rom with 0-1 tension; export toggles Skip/Letterbox/Fade; exports dependency-free TweenService LocalScripts | [FORUM] [CineCam](https://devforum.roblox.com/t/plugin-cinecam-v3-%E2%80%94-build-preview-camera-cutscenes-live-in-studio-no-playtesting-needed/4713811) |
| Letterbox | Two black Frames, or LetterBoxer module | [FORUM] [LetterBoxer](https://devforum.roblox.com/t/letterboxer-a-cool-letterboxing-module-for-cinematic-scenes/4224471) |
| Menu blur | Tween `BlurEffect.Size`; cancel the previous tween rather than a boolean debounce | [FORUM] [blur](https://devforum.roblox.com/t/how-can-i-improve-my-menuclosedopened-blur-effect/2299747) |
| DOF | Only when Enabled under Lighting or CurrentCamera; differs on low-end; DOF-glass UI blur trick has heavy limitations (hides Surface/BillboardGuis, can't coexist with other DOF) | [DOC] [DepthOfField](https://create.roblox.com/docs/reference/engine/classes/DepthOfFieldEffect); [FORUM] [DOF blur](https://devforum.roblox.com/t/blurred-uis-using-depth-of-field-effect/4734313) |
| CameraModule | Made private by FFlag; customizing requires forking PlayerModule | [FORUM] [CameraModule API](https://devforum.roblox.com/t/do-not-remove-the-cameramodule-api/475287/1) |
| Camera springs | Spring the mouse input inside a forked camera rather than the final CFrame; shortest-path springs can rotate the wrong way | [FORUM] [smooth camera](https://devforum.roblox.com/t/smooth-camera-movement-how/249578) |

**Shot runner (Derived):** a shot is `{cf0, cf1, duration, easing, fov0, fov1, lookAt?, shake?, holdAfter}`. Bind it to RenderStepped at `Enum.RenderPriority.Camera.Value + 1`. Compute `alpha = TweenService:GetValue(t/duration, style, dir)` and the position along a Bézier/Catmull-Rom, then set `camera.CFrame = CFrame.lookAt(pos, lookAt)`, `camera.Focus = CFrame.new(lookAt)` and lerp FOV. Compose `camera.CFrame *= shakeCF` in the **same** step, which avoids the RbxCameraShaker priority conflict. Always expose Skip. Reveal push-in: FOV 70 → 55-60 over 0.6-1.0 s Quint Out. Impact FOV kick: 70 → 74 → 70 (0.1 s + 0.3 s). Menu blur: Size 0 → 16-24 over 0.2-0.3 s. Reserve DOF for the hatch close-up.

### 2.6 Transitions: hide every load behind a fade the player never sees pop

| Transition | Official pattern | Tag / source |
|---|---|---|
| Join loading screen | ReplicatedFirst LocalScript: build ScreenGui (`IgnoreGuiInset = true`), `RemoveDefaultLoadingScreen()`, minimum display time, `if not game:IsLoaded() then game.Loaded:Wait() end`, destroy | [DOC] [Loading screens](https://create.roblox.com/docs/players/loading-screens) |
| Place teleport | `SetTeleportGui(gui)` before `TeleportAsync(placeId, players, options)`; on arrival `GetArrivingTeleportGui()` in ReplicatedFirst. **Scripts in that GUI do not run**; not used across different games; Studio can't playtest teleports; retry on `TeleportInitFailed` (Flooded = wait longer, Failure = retry). Deprecated: `Teleport`, `TeleportToPlaceInstance`, `TeleportPartyAsync`, etc. | [DOC] [TeleportService](https://create.roblox.com/docs/reference/engine/classes/TeleportService); [Teleport guide](https://create.roblox.com/docs/projects/teleport) |
| Preload | `ContentProvider:PreloadAsync(ids, callback(id, status))` yields; `Preload` deprecated | [DOC] [ContentProvider](https://create.roblox.com/docs/reference/engine/classes/ContentProvider) |
| In-place teleport with streaming | Server `player:RequestStreamAroundAsync(target)` first; IntegrityMode PauseOutsideLoadedArea; **"Don't wait for a spatial map instance to stream in before dismissing a loading screen"**; no guarantee pauses can't occur | [DOC] [Streaming techniques](https://create.roblox.com/docs/workspace/streaming/techniques); [FORUM] [announcement](https://devforum.roblox.com/t//651626) |
| Fall-through fix | Small always-loaded landing part, freeze until a ground raycast hits, or raise landing height | [FORUM] [StreamingEnabled dilemma](https://devforum.roblox.com/t/streamingenabled-dilemna/981332) |
| Group fades | `CanvasGroup.GroupTransparency` | [DOC] [UI animation](https://create.roblox.com/docs/ui/animation) |

**Island-hop recipe (Derived structure from [DOC]; numbers are the researchers'):**
1. Client fades to black, 0.25-0.35 s Quad Out, and fires the server.
2. Server anchors the character, runs `RequestStreamAroundAsync(dest)` in a pcall with a timeout, and calls `PivotTo` onto an always-loaded landing pad.
3. Client waits for a ground raycast, holds ≥0.3 s, then fades up over 0.4-0.6 s with an FOV ease of 70 → 72 → 70.

Keep teleport GUIs script-free and animate them with UIGradient or spritesheets. Preload only what the first 10 seconds need. Never stack the default loading screen with a custom one (double fade).

### 2.7 Creature animation: own every animation, layer procedural life on top

| Fact | Detail | Tag / source |
|---|---|---|
| Permissions (2025-07-31) | Animations are "Restricted" and can't be Open Use; per-experience grants that "cannot be revoked"; other creators' experiences can load your animation once granted; free or stranger animations fail unless granted. Author everything under the game's owner/group | [FORUM/DOC] [Animation permissions](https://devforum.roblox.com/t/improving-animation-asset-permissions/3852101) |
| Tracks | `Play(fadeTime=0.1, weight=1, speed=1)`, `Stop(0.1)`, `AdjustWeight`, `AdjustSpeed`; `GetMarkerReachedSignal(name)` (**KeyframeReached deprecated**); fit duration with `speed = track.Length / duration` | [DOC] [AnimationTrack](https://create.roblox.com/docs/reference/engine/classes/AnimationTrack) |
| Priority | Action4(5) > Action3 > Action2 > Action(2) > Movement(1) > Idle(0) > Core(1000, lowest); blended per joint until weight 1.0 | [DOC] [AnimationPriority](https://create.roblox.com/docs/reference/engine/enums/AnimationPriority) |
| IK | `IKControl` Type Position/Transform/LookAt, ChainRoot → EndEffector, Target, Pole, Weight, SmoothTime; constraint attachments must match Motor6D C0/C1 and share the parent Model; BallSocket `UpperAngle = 80` for wrists | [DOC] [IKControl](https://create.roblox.com/docs/reference/engine/classes/IKControl); [IK guide](https://create.roblox.com/docs/animation/inverse-kinematics) |
| Scale | `Model.Scale` is Not Scriptable, so use `ScaleTo` or spr's `Scale` pseudo-prop for uniform pops; non-uniform squash needs Bone.Transform or Motor6D offsets | [DOC] [Model](https://create.roblox.com/docs/reference/engine/classes/Model) |
| Editors | Curve Editor (free; Linear/Constant/Cubic; bounce/elastic via "Generate Curve"); Moon Animator 2 ~$29.99 (UNVERIFIED); Animation Capture: face 60 s webcam, body <15 s video → R15 | [DOC] [Curve editor](https://create.roblox.com/docs/animation/curve-editor); [Capture](https://create.roblox.com/docs/animation/capture) |
| AI animation | Cube 4D generation beta (Feb 2026) makes functional objects (cars), not creature animation; no text-to-animation in Studio as of Oct 2026 | [BLOG, Roblox newsroom](https://about.roblox.com/de/newsroom/2026/02/accelerating-creation-powered-roblox-cube-foundation-model) |

**"Alive" layer stack (Derived):**

| Layer | Implementation |
|---|---|
| Base | Looped Idle at `Idle` priority |
| Breathing | Procedural sine at 0.4-0.6 Hz on a root Motor6D `Transform` |
| Head tracking | `IKControl` LookAt, Weight springing 0 → 1 (SmoothTime ~0.15-0.3) when the player is near |
| Reactions | `Action` track with `Play(0.05)` |
| Sleep | Fade idle weight to 0.3 while a Movement-priority sleep track blends in |
| Squash | Applied to a non-collidable visual clone, never the physics model |

### 2.8 VFX limits and kit

| Limit | Value | Tag / source |
|---|---|---|
| Particle rate | **400/s per emitter (100/s mobile)**; lifetime max 20 s; size drives fill-rate; overlapping transparency = overdraw | [DOC] [Particle emitters](https://create.roblox.com/docs/effects/particle-emitters) |
| Flipbooks | Square power-of-two 8-1024 px; Grid2x2/4x4/8x8/Custom; ≤30 fps; costs memory, may be disabled on low-memory devices; modes Loop/OneShot/PingPong/Random | [DOC] same; [FlipbookMode](https://create.roblox.com/docs/reference/engine/enums/ParticleFlipbookMode) |
| Bursts | `Emit(count=16)`; `Emit()` bypasses automatic graphics-level particle reduction | [DOC] [ParticleEmitter](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter); [FORUM] [perf](https://devforum.roblox.com/t/performance-considerations-improvements-and-optimizations-when-making-a-game/817499) |
| Shapes | Sphere/Cylinder emitter shapes render wrong on Attachments; use BasePart parents | [DOC] [Particle emitters](https://create.roblox.com/docs/effects/particle-emitters) |
| Highlight | **31 simultaneous**, extras silently ignored; disabled ones still count; add/remove = geometry rebuild (change properties instead). Older pages say 255 | [DOC] [Highlight](https://create.roblox.com/docs/reference/engine/classes/Highlight); [Highlighting](https://create.roblox.com/docs/effects/highlighting) |
| Beam | Cubic Bézier via CurveSize0/1; TextureMode Wrap/Static/Stretch | [DOC] [Beams](https://create.roblox.com/docs/effects/beams) |
| Grayscale textures | `LightEmission = 1` hides dark regions | [DOC] [Particle emitters](https://create.roblox.com/docs/effects/particle-emitters) |

**Hatch VFX kit (Derived):**

| Element | Implementation |
|---|---|
| Confetti | Pre-warmed `Rate = 0` emitter, `Emit(10…60)` by tier; ribbon look from Squash 1.5-2 + VelocityParallel |
| Shockwave | Beam ring tweened on Width |
| Glow pulse | One persistent Highlight; tween its transparency, never add/remove it |
| Crack/sparkle | One 4×4 flipbook at 256-512 px |
| Shells and shine planes | Mesh VFX kept in a persistent folder, tweened on Transparency |

### 2.9 Motion anti-patterns that read as slop

These are sourced unless marked:
- InOut easing on hover ([FORUM](https://devforum.roblox.com/t/trouble-with-hover-tweening/2618400)).
- Boolean debounces that swallow open/close ([FORUM](https://devforum.roblox.com/t/how-can-i-improve-my-menuclosedopened-blur-effect/2299747)).
- Cancelled tweens not recreated ([FORUM](https://devforum.roblox.com/t/tween-does-not-play-after-being-cancelled/2769718)).
- Adding/removing Highlights per event ([DOC](https://create.roblox.com/docs/effects/highlighting)).
- Gating loading screens on streamed parts ([DOC](https://create.roblox.com/docs/workspace/streaming/techniques)).
- Relying on others' animations ([FORUM](https://devforum.roblox.com/t/improving-animation-asset-permissions/3852101)).
- `["*"]` Styling Transitions ([FORUM](https://devforum.roblox.com/t/full-release-styling-transitions/4646870)).
- Deprecated `Interpolate`/`SetRoll`/`KeyframeReached`/`Preload`.
- Rarity that only recolours a label ([FORUM](https://devforum.roblox.com/t/pet-hatching-framework-part-1/1480291)).
- Audio more than ~20 ms off the beat ([BLOG](https://eastondev.com/blog/en/posts/dev/20260521-game-feedback-feel/)).
- Unsourced but consistent: instant `Visible = true` pops; tweening Size and Position with different easings on one element; server-fired cosmetic sounds or tweens; shaking the camera on every click; a double loading-screen fade.

---

## Part 3. GUI: native 2026 primitives now build the chunky cartoon look without images

### 3.1 Three template families; Steal a Dream is family A

| Family | Games (evidence level) | Construction | Tag / source |
|---|---|---|---|
| **A: chunky cartoon simulator** | PS99, Pls Donate (image-based ImageButton UIs, confirmed); GaG, Steal a Brainrot, BGSI, Adopt Me, TTD (UNVERIFIED) | Image/9-slice panels or native equivalents, thick dark strokes, top-light gradients, rounded display fonts | [FORUM] [Unique UI](https://devforum.roblox.com/t/unique-or-good-looking-ui/2914121); [STORE] [Cartoony UI Kit](https://builtbybit.com/resources/cartoony-ui-kit-25-frames.117327/), [GaG UI Pack](https://adrianart.itch.io/gag-ui-pack) |
| B: flat modern | Evade (reverse-engineered); others UNVERIFIED | Corner radius ~Scale 0.1, white text, solid buttons darkening downward, grey+black double outline, black 0.5-transparency backing | [FORUM] [Evade style](https://devforum.roblox.com/t/how-to-recreate-such-ui-style/1943553) |
| C: glass/translucent | Aspirational; creators "wish Roblox could blur UI backdrops" | Faked with semi-transparent frames and gradient strokes | [FORUM] [Show off UI p128](https://devforum.roblox.com/t/show-off-your-ui-designs/311776?page=128) |

A GaG-style game ships these screens: Seed Shop, Confirmation, Codes, Limited Shop, Pet/Cosmetic Shop, HUD, Inventory, Hotbar, Notification, Quests, Settings ([STORE] [GaG UI Pack](https://adrianart.itch.io/gag-ui-pack)). The flat style "may not suit simulators, since the UI needs to attract a younger audience" ([FORUM] [Modern UI tutorial](https://devforum.roblox.com/t/how-to-make-simple-modern-ui/1937876)).

Roblox's own UX examples ([DOC] [UI/UX design](https://create.roblox.com/docs/en-us/production/game-design/ui-ux-design)):
- Jailbreak's "golden stripe" on premium rewards.
- Dragon Adventures makes the best-value bundle larger, with more padding.
- Tower Defense Simulator groups shop items by size and proximity.
- BotClash and Winds of Fortune show button containers and shadows.

Per-game radii, stroke widths and fonts are **UNVERIFIED**. The researcher's memory of PS99 (white/cream panels, coloured title tab, 3-4 px dark outlines, Fredoka-like text) must be checked in-game.

**Shop and odds conventions [WIKI]:**
- Per-item percentages, e.g. PS99 Sad Egg "Sad Doge 50%… Huge Sad Doge 1.25%… Titanic Sad Cat 0.05%" ([Sportskeeda](https://sportskeeda.com/roblox-news/pet-simulator-99-sad-egg-how-get-huge-pets)).
- Multiplier text on passes: "Increases huge chance by 6250%" ([PS99 wiki](https://pet-simulator.fandom.com/wiki/Gamepasses_(Pet_Simulator_99))).
- GaG restocks every 5 min with ladder Common → Uncommon → Rare → Legendary → Divine → Mythical ([Gamezebo](https://gamezebo.com/walkthroughs/grow-a-garden-seeds)).
- Brainrot ladder: Common, Rare, Epic, Legendary, Mythic, Brainrot God, Secret, OG ([Digital Citizen](https://www.digitalcitizen.life/all-brainrots-in-steal-a-brainrot/)).

### 3.2 Pro process: design in Figma, rebuild natively, convert to Scale

| Step | Detail | Tag / source |
|---|---|---|
| Design | Sketch with timing notes → Figma layout → colours/icons → gradients/corners/shadows; export PNG (SVG doesn't import); export icons **white** and tint with ImageColor3 | [FORUM] [Ultimate UI Design Guide](https://devforum.roblox.com/t/the-ultimate-ui-design-guide/1236916) |
| Import pain | Imported UI "doesn't scale properly"; design with Auto Layout + offset, then convert to Scale; Figblox needs a 1920×1080 frame | [FORUM] [Figma import sucks](https://devforum.roblox.com/t/importing-ui-from-figma-sucks/3381689) |
| 2026 importers | roimport (free; `_Button`, `_Scroll`, `_Slice` layer tags; exports auto-layouts, rich text, UIShadow); UILint v2; GuiForge (brings strokes, gradients, 9-slice; rasterizes the rest); UI Designer Pro | [FORUM] [roimport](https://devforum.roblox.com/t/free-figma-to-roblox-plugin-roimport/4731967); [UILint](https://devforum.roblox.com/t/plugin-uilint-v2-import-figma-ui-into-roblox-studio/4765869); [GuiForge](https://devforum.roblox.com/t/guiforge-roblox-ui-editorfigma-export/4834077) |
| 9-slice | `ScaleType = Slice`, SliceCenter editor (editor offsets ≠ property values); Kenney 96×96 border → SliceCenter 48,48,48,48; SliceScale = screenHeight/2700 for constant stroke; Slice/Tile ImageLabels don't work well with UICorner | [DOC] [9-slice](https://create.roblox.com/docs/en-us/ui/9-slice); [FORUM] [borders](https://devforum.roblox.com/t/how-to-properly-use-custom-ui-borders/4092984), [SliceScale](https://devforum.roblox.com/t/slicescale-formula/1338744), [GUI optimization](https://devforum.roblox.com/t/gui-optimization-tips/3986563) |
| Image sizes | ≤512² unless large on screen; minor <256²; sprite sheets via ImageRectOffset/Size | [DOC] [Improve performance](https://create.roblox.com/docs/en-us/performance-optimization/improve) |
| Pre-2026 norm | "Depth and custom shapes previously required external image assets and 9-slice workarounds" | [DOC] [UIShadow release](https://devforum.roblox.com/t/full-release-new-ui-capabilities-shadows-individual-corners/4636263) |
| Rates | 1k Robux/frame; 8 frames 16-19k Robux; small game 1-10k, medium 10-25k, large 25-50k+ Robux | [FORUM] [rates](https://devforum.roblox.com/t/portfolio-ui-designer-for-hire-animate-uis-as-well/1407238); [metatablesnow](https://devforum.roblox.com/t/open-metatablesnow-uiux-design-portfolio-2-years-of-experience/3656083) |

**Image vs native (Derived):** pure Instances (Frame + UICorner + UIStroke + UIGradient + UIShadow) are the default. Reserve 9-slice images for one or two signature silhouettes, such as a notched tab, painted border or hatch burst. Native panels stay recolourable, while uploaded images "can't be customized afterward" ([FORUM](https://devforum.roblox.com/t/unique-or-good-looking-ui/2914121)).

### 3.3 2026 UI technology status

| Primitive | Status (Oct 2026) | Key facts | Tag / source |
|---|---|---|---|
| StyleSheet / StyleRule / StyleLink / StyleDerive | Publishable since client beta 2026-01-20; docs show no beta label | Token sheets as attributes referenced with `$` (e.g. `$Gold` = FFCC00); theme sheets must share token sets; one StyleSheet per tree; selectors class/tag/name/pseudo-instance/state (`:Hover`)/query (`@`) | [FORUM] [publish styles](https://devforum.roblox.com/t/client-beta-you-can-now-publish-styles-in-your-experience/3901480); [DOC] [Styling](https://create.roblox.com/docs/en-us/ui/styling) |
| StyleQuery | **Full release 2026-05-11** | MinSize/MaxSize/AspectRatioRange; ViewportDisplaySize, PreferredInput, ReducedMotionEnabled, PreferredTextSize; selectors `@PreferredInputTouch`, `@ViewportDisplaySizeSmall`; multiple UIStrokes as pseudo-instances (unique names, distinct offsets); size-in-size-query can flicker | [FORUM] [StyleQuery](https://devforum.roblox.com/t/full-release-stylequery-more-styling-features/4566519) |
| UIShadow + per-corner UICorner | **Full release 2026-06-23** | BlurRadius (≤1000), Color, Transparency, Offset, Spread, negative ZIndex; multiple per instance; ≤100 on screen; shadows text background, not glyphs; sample **BlurRadius 30, black, Transparency 0.5, Offset 10/10**; jagged on large radii; per-corner TopLeft/TopRight/BottomLeft/BottomRightRadius (don't mix with CornerRadius); "faster than 9-sliced ImageLabels" | [FORUM/DOC] [UIShadow release](https://devforum.roblox.com/t/full-release-new-ui-capabilities-shadows-individual-corners/4636263) |
| Upgraded UIShadow | Studio beta | Contents unknown | same |
| Styling Transitions | Full release 2026-07-27 | See 2.1 | [FORUM/DOC] [link](https://devforum.roblox.com/t/full-release-styling-transitions/4646870) |
| Flex layouts | Live | UIListLayout HorizontalFlex/VerticalFlex, ItemLineAlignment, Wraps; UIFlexItem Fill/Grow/Shrink/Custom; "slight cost"; no UIFlexLayout class | [DOC] [Flex](https://create.roblox.com/docs/en-us/ui/list-flex-layouts) |
| UIDragDetector | Live (ref updated 2026-10-15) | TranslateLine/Plane/Rotate/Scriptable; BoundingUI; AddConstraintFunction snapping | [DOC] [Drag detectors](https://create.roblox.com/docs/en-us/ui/ui-drag-detectors) |
| UIStroke | Live; some properties may need "Improved UIStrokes" beta | Child UIGradient colours stroke separately; LineJoinMode Round/Bevel/Miter | [DOC] [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers) |
| Rich text | Live | `<stroke color thickness joins sizing>`, `<font weight=100-900>`, `<mark>`, `<uppercase>`; e.g. `You won <stroke color="#00A2FF" thickness="2">25 gems</stroke>` | [DOC] [Rich text](https://create.roblox.com/docs/en-us/ui/rich-text) |
| Backdrop blur (UIBlur) | **Does not exist** | No announcement; creators still asking | [FORUM] [UIShadow release](https://devforum.roblox.com/t/full-release-new-ui-capabilities-shadows-individual-corners/4636263) |

### 3.4 Component recipes (family A)

Starting values are Derived unless a tag says otherwise. The [DOC] constraints that bind them: ≤6 gradient stops; no UIGradient on stroked text; animate gradient Offset/Rotation, not sequences ([UIGradient](https://create.roblox.com/docs/en-us/reference/engine/classes/UIGradient.md)). Grey means unusable, red means unaffordable, X closes, and every action gets feedback ([UI/UX](https://create.roblox.com/docs/en-us/production/game-design/ui-ux-design)).

| Component | Recipe |
|---|---|
| Button | Frame/ImageButton, AnchorPoint 0.5,0.5, Scale size + UIAspectRatioConstraint (3.2:1 text, 1:1 icon); UICorner Scale 0.2-0.3 of height (pill = per-corner `UDim.new(1,0)`); UIStroke 2-3 px @1080p, Round joins, colour = fill darkened ~45%; UIGradient 90° white → ~#C8C8C8 (lighter top); UIShadow Blur 8-14, Offset 0,4-6, Transparency 0.6; hover 1.04 (80 ms), press 0.95 + darker gradient (60 ms), spring release; disabled = grey fill + 0.5 text transparency |
| Button text | TextScaled + UITextSizeConstraint (Min ~14, Max ~36); FredokaOne labels, LuckiestGuy titles/numbers; UIStroke on text 2-3 px black Round; rich-text `<stroke>` for partial emphasis |
| Panel | UICorner Scale ~0.04 (16-24 px @1080p); 3-4 px dark stroke; UIShadow 24-30 blur; title ribbon overlapping the top edge by ~35%, saturated, LuckiestGuy + stroke; X close 1:1 red, ~0.9× title height, centred on the top-right corner, hover 1.1 + slight rotation; inner content area darker/desaturated with UIPadding 2-3%; dim backdrop black at 0.5 transparency ([FORUM] Evade thread) |
| Currency pill | Per-corner `UDim.new(1,0)`; icon on the left overflowing ~20%; LuckiestGuy number + stroke; green "+" on the right; tweened count-up + 1.15 pop |
| Progress bar | Pill track + 2 px inner padding; fill = child Frame Scale X with its own UICorner; or a full-width fill with tweened UIGradient Transparency Offset |
| Toggle | Pill track + circle knob tweened in Position (or UIDragDetector TranslateLine); green/grey |
| Tabs | UIListLayout HorizontalFlex Fill; active = lighter + raised 4 px; inactive = darker, 0.3 text transparency |
| Tooltip | Top-level Frame, high DisplayOrder, dark 0.2 transparency, 1 px stroke, 8 px corner, 100 ms fade |
| Toast | Top-centre below `GuiService.TopbarInset`; slide from Y −20 px + fade; 3 s auto-dismiss; rarity-coloured stroke for drops |
| Rarity badge | Pill in rarity colour + 2 px darker stroke; same colour on the card stroke and a subtle gradient wash |
| Shop/egg card | 1:1.25; UICorner ~0.08; 3 px stroke; top 55% image; per-item odds to 2 significant figures; price pill; "x left / restock mm:ss"; green Buy; red price when unaffordable |
| Semantic colours | green = buy/confirm, red = close/sell/can't afford, gold = premium/luck/Robux, purple/pink = rare/boost, blue = info/rebirth; one hue per meaning everywhere |

**Fonts [DOC]** ([Enum.Font](https://create.roblox.com/docs/en-us/reference/engine/enums/Font); [Font datatype](https://create.roblox.com/docs/en-us/reference/engine/datatypes/Font)): the enum has 52 entries. Cartoon-relevant ones are FredokaOne (26), LuckiestGuy (32), Bangers (22), Gotham family (17-20), BuilderSans family (46-49) and Nunito (35). `Font.fromName/fromId` reach non-enum families. TitanOne is absent.

### 3.5 Responsive and platform rules

| Rule | Detail | Tag / source |
|---|---|---|
| Safe area | `ScreenGui.ScreenInsets` default **CoreUISafeInsets** (clear of top bar and cutouts) for interactive UI; TopbarSafeInsets for in-topbar UI; `IgnoreGuiInset = true` switches to DeviceSafeInsets; don't use SafeAreaCompatibility for new work | [DOC] [ScreenGui](https://create.roblox.com/docs/en-us/reference/engine/classes/ScreenGui.md); [ScreenInsets](https://create.roblox.com/docs/en-us/reference/engine/enums/ScreenInsets.md) |
| GuiService | `TopbarInset` (Rect), `PreferredTextSize`, `PreferredTransparency`, `ReducedMotionEnabled`, `ViewportDisplaySize` (Small/Medium/Large), `SelectedObject`; IsTenFootInterface deprecated | [DOC] [GuiService](https://create.roblox.com/docs/en-us/reference/engine/classes/GuiService) |
| Mobile | Default controls own the bottom-left and bottom-right; "a button 40% from the top edge is reachable on a phone but hard to reach on a tablet"; place custom buttons relative to jump (sample: 20 px left, 0.8× size); contextual buttons only when relevant | [DOC] [Position and size](https://create.roblox.com/docs/en-us/ui/position-and-size) |
| Console | 8-10 ft viewing; relative sizes; UISizeConstraint; every element reachable by D-pad + select + back; ButtonA selects, ButtonB cancels; glyphs via `GetImageForKeyCode`; haptics at list ends; disable chat window | [DOC] [Console guidelines](https://create.roblox.com/docs/en-us/production/publishing/console-guidelines); [Gamepad](https://create.roblox.com/docs/en-us/input/gamepad) |
| Known bug | TopbarSafeInsets mis-sizes on consoles (fix status unknown) | [FORUM] [bug](https://devforum.roblox.com/t/screenguiscreeninsets-topbarsafeinsets-is-incorrect-on-consoles/4111410) |

Derived placement: keep HUD/menus on CoreUISafeInsets and put the dim backdrop in a separate ScreenGui with IgnoreGuiInset. Place primary actions (hatch/steal) bottom-centre or right, sized relative to the jump button. Set `Selectable` only on real buttons, give them a SelectionImageObject matching the stroke style, and set `GuiService.SelectedObject` when a window opens.

### 3.6 What UI actually costs

| Item | Guidance | Tag / source |
|---|---|---|
| CanvasGroup | Extra texture memory; blank texture past the QualityLevel cap; resize = new texture; blurry at quality 1-4 ("480p or lower") | [DOC] [CanvasGroup](https://create.roblox.com/docs/en-us/reference/engine/classes/CanvasGroup.md); [FORUM] [GUI optimization](https://devforum.roblox.com/t/gui-optimization-tips/3986563) |
| ScreenGuis | Separate ScreenGuis render separately; any change rerenders its whole ScreenGui; appearances cached until changed; Frames faster than ImageLabels | [FORUM] [GUI optimization](https://devforum.roblox.com/t/gui-optimization-tips/3986563) |
| UIStroke on text | "Essentially double the cost" (self-flagged guess); RichText + UIStroke in BillboardGuis very expensive | [FORUM] [strokes flicker](https://devforum.roblox.com/t/ui-strokes-flickering/3304676) |
| UIShadow | ≤100 on screen | [FORUM/DOC] [release](https://devforum.roblox.com/t/full-release-new-ui-capabilities-shadows-individual-corners/4636263) |
| StyleQuery | Many queries on one instance hurt; prefer built-in selectors | [FORUM] [StyleQuery](https://devforum.roblox.com/t/full-release-stylequery-more-styling-features/4566519) |

Derived budget:
- One ScreenGui per surface (HUD, Shop, Index, Hatch, Toasts), so a ticking currency counter doesn't rerender the shop.
- CanvasGroup only for whole-window fades: static size, destroyed after the fade.
- Text strokes only on HUD numbers, titles and prices.
- ViewportFrames only in the hatch reveal and the selected index entry, never per grid cell.
- Collapse list-item shadows into the container.

### 3.7 GUI slop vs polish markers

Reviewers converge on a consistent set of complaints:
- Italics "should not be used in a GUI like this", and "the font and the artstyle clash".
- Misaligned text and inconsistent sizing across tabs.
- Uneven padding, and shop slots "unevenly positioned and sized".
- Neon greens that "do not contrast well with the white text".
- Mixed filled and outlined icons, and "AI-generated icons look poor".
- Dark-only themes on cartoony games, overlapping close buttons, and offset-sized panels that break on phones.

Sources: [FORUM] [First UI](https://devforum.roblox.com/t/feedback-on-my-first-ui/1560744); [Feedback wanted](https://devforum.roblox.com/t/feedback-wanted-for-this-ui/637517); [newbie](https://devforum.roblox.com/t/ui-feedback-for-a-newbie/2865723); [Show off p128](https://devforum.roblox.com/t/show-off-your-ui-designs/311776?page=128); [Ultimate guide](https://devforum.roblox.com/t/the-ultimate-ui-design-guide/1236916). Roblox's docs add missing feedback ("leaves players unsure of outcomes"), clutter, inconsistent colour meaning, and a call to keep a Style Guide ([DOC] [UI/UX](https://create.roblox.com/docs/en-us/production/game-design/ui-ux-design)).

**Review checklist (Derived):** fail any screen with:
1. Default SourceSans/Gotham text on a cartoon screen.
2. Italics.
3. Unstroked or unbacked text over 3D.
4. Sibling buttons with different radii; derive all radii from one token.
5. Mixed icon sets (pick Kenney or Lucide; never AI-generated).
6. Neon on white, or white on neon.
7. A missing hover, press or disabled state.
8. Offset sizes inside a panel.
9. HUD elements in the bottom corners on mobile.
10. Floating panels with no shadow or container.
11. Two different "Buy" greens.

The polish bar is one token sheet, a fixed title ribbon + X position on every window, shadows on all floating panels, currency pops with sound, odds shown with rarity colours, stock counters, and every screen checked at phone, tablet, 16:9 and 21:9.

**Kits and icons:**

| Source | Terms | Tag / source |
|---|---|---|
| Kenney | CC0 (credit optional) | [WIKI] [OpenGameArt](https://opengameart.org/content/game-icons) |
| Lucide | ISC library, MIT for Feather-derived icons; keep notices; Studio plugin 7734363201 | [lucide.dev/license](https://lucide.dev/license); [FORUM] [tutorial](https://devforum.roblox.com/t/how-to-make-simple-modern-ui/1937876) |
| Marketplace kits | Per-listing terms; free and paid examples: Luabox free, BuiltByBit "Roblox Simulator GUI Pack" free, gfxcomet $19, HopsDev €5.49+ | [STORE] [Luabox](https://luaboxassets.gumroad.com/l/free-ui); [BuiltByBit](https://builtbybit.com/resources/roblox-simulator-gui-pack.105322/); [gfxcomet](https://gfxcomet.gumroad.com/l/cartoonkit); [HopsDev](https://hopsdev.itch.io/essential-gui-pack) |
| Roblox demos | IndividualRoundedCorner_Demo.rbxl, UIShadow_Demo.rbxl | [DOC] [release](https://devforum.roblox.com/t/full-release-new-ui-capabilities-shadows-individual-corners/4636263) |

Use marketplace kits as layer-tree references, then rebuild natively.

---

## Open gaps (what the evidence does not settle)

| Area | Gap |
|---|---|
| Top-game measurements | No published stud dimensions, plot counts per server, ring radii or hub geometry for GaG, Steal a Brainrot, Steal an Egg, Adopt Me, Bloxburg, Brookhaven. Fandom pages returned HTTP 402. Brainrot floor-unlock rebirths conflict (R2 vs R8); GaG expansion prices conflict |
| Top-game UI | No measured corner radii, stroke widths or fonts for any of the twelve games; per-game descriptions are UNVERIFIED memory. No Uplift/Gigi/BIG Games UI write-ups |
| Hatch choreography | No text breakdown of PS99/Adopt Me/GaG/Brainrot hatch, steal or purchase presentation, sound layering or slow-mo; only gameplay videos. The DevForum "How does Pet Simulator do it?" thread was unretrievable |
| ProceduralModel | Full-release date and runtime (in-game) support are UNVERIFIED; `ForceGeneration` not yet implemented per the beta post |
| Algorithms | No Roblox BSP or L-system implementation; WFC only as a 2023 .rbxl; DevForum generators publish no licences; Mythus-Z performance claims unbenchmarked |
| Budgets | No official draw-call/instance/triangle budget (500/500k is community); unclear how plain Parts batch per material; no official union-vs-mesh cost; `CastShadow=false` benefit disputed; SLIM LOD talk ([SIGGRAPH 2026 PDF](https://www.advances.realtimerendering.com/s2026/content/SMAK_SIG26_SLIM-Scaling_User-Generated_3D_Worlds_on_Roblox_8_Aug_2026.pdf)) not extracted |
| Engine limits | `BasePart.Size` limits, `PointLight.Range` max, `Lighting.Technology` user-settable status, terrain Fill `Capabilities: Environment` in MCP context: all UNVERIFIED |
| Motion numbers | No published Roblox spring values for buttons, panels, counters or cameras; Ripple preset numbers unknown; no Roblox hit-stop studies; no official fade/iris-wipe durations; `RequestStreamAroundAsync` timeout undocumented |
| Camera | No 2025-26 Camera scripting API additions found (UNVERIFIED negative); no official cutscene sample place |
| Animation | IKControl Weight/SmoothTime/Priority defaults undocumented; Moon Animator 2 live price unconfirmed; no text-to-animation tool shipped |
| UI tech | Upgraded UIShadow beta contents unknown; no UIBlur; VideoFrame not researched; no official UI image-size cap (1024 comes from the 3D page); no official UIStroke/CanvasGroup/ViewportFrame cost benchmarks; console TV-safe percentage and min text size unstated |
| Stylized look | No verified outline/cel shading in any top game; no official Bloom numbers; no official stylized bedroom/cloud kit on the Creator Store; free-model licence text not read |
| Placement | No open-source placement module with DataStore save/load; Bloxburg/Adopt Me grid and rotation steps unconfirmed |

## Conclusion

The research shifts where effort should go. Roblox shipped native primitives in 2026: ProceduralModel, StyleSheets/StyleQuery, UIShadow with per-corner radii, and Styling Transitions. Together they remove the excuses that used to separate "AI-built" from "studio-built", namely image-dependent panels, hand-placed geometry and Luau-tweened hover states. The remaining gap is taste encoded as data: one grid, one trim sheet, one token sheet, one timing sheet and one rarity-escalation table. A code-driven pipeline holds those more consistently than a human team does. For a rulebook, the highest-leverage rules are the ones that make variation deterministic: seeded RNG passed through every generator, `GenVersion` on every baked island, tokens instead of literals in every UI property, and tier multipliers instead of bespoke animations per rarity.

The evidence is also lopsided. Roblox's docs are precise about limits (20k triangles per mesh, 31 Highlights, 400 particles/s, 100 UIShadows, 4,194,304 voxels per write) but silent on taste, and top games publish almost nothing. Polish therefore has to be verified empirically. The practical next step is a capture-and-measure pass: open PS99, Grow a Garden and Steal a Brainrot, screenshot their panels, hatches and plots, and measure radii, stroke widths, timings and plot spacing. Those measurements should replace the UNVERIFIED and Derived defaults above before the rulebooks harden.
