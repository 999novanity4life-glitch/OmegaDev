# 16 Level Design and Wayfinding

How to lay out a map players read at a glance, want to explore, and never get lost in, and how to generate one procedurally without it looking procedural. Tags: **[DOC]** create.roblox.com, **[VIDEO]** notes in `docs/research/videos-2026-10-28/`, **[LDB]** [The Level Design Book](https://book.leveldesignbook.com) (CC BY-NC-SA: paraphrased and cited, never copied), **[RULE]** studio rule. Code: `template/src/shared/TerrainGen.luau` (pure math, tested) and `template/src/server/Services/WorldBuilder.luau` (writes terrain).

## The order of work [DOC + VIDEO 21]
Roblox's environmental art course runs **greybox → polished assets → asset library → construct the world → optimize** ([course](https://create.roblox.com/docs/tutorials/curriculums/environmental-art)). An RDC art director adds concept sketches before the greybox and says the first two stages are the ones teams skip [VIDEO 21 @10:24]. So:
1. **Overhead map and a color script** in SPEC.md: each zone, its landmark, its mood color, its lighting preset (chapter 15). Redrawing a map is cheaper than undoing a built city [VIDEO 21 @7:51].
2. **Greybox** in plain parts, one distinct color per zone ([greybox](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/greybox-your-environment)). Playtest scale and travel time before any art [VIDEO 21 @10:55, VIDEO 14 @16:02].
3. **Art pass** from a small kit (below), then **lighting pass**, then **VISUAL_QA**.

## Grid and scale [DOC]
Snap 5 studs and 90°; doors at least 10 studs tall; walls at least 10 studs (jump height is about 5, so lower walls get climbed); modular pivots at the front lower corner; pieces at least 5×5 studs and divisible into each other ([greybox](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/greybox-your-environment)). Check every prop next to a 5-stud rig [VIDEO 25 @14:21].

## Read the map from the player's eye
- **Compose from spawn.** Set up the spawn view like a film shot: the next destination prominent and close enough, then repeat at every landmark ("where is the next place I need to be?") [VIDEO 21 @12:27]. These shots double as thumbnails [VIDEO 21 @13:00]. VISUAL_QA's first required shot is the spawn shot.
- **Landmarks with a reward.** Breath of the Wild's few towers made testers follow a rope (about 80%) or wander lost (about 20%); many varied landmarks, each with an obvious benefit, fixed it [VIDEO 11 @3:08, @3:41]. Every point of interest pays: currency, a shortcut, a view, a secret.
- **Readable at distance.** Small landmarks need a tall tell: glow, a smoke column, a giant statue [VIDEO 11 @4:42]. In Roblox: a Neon beacon, a Beam, a ParticleEmitter column [RULE].
- **Triangle rule.** Hills shaped like triangles force "climb or go around", draw the eye to the peak, and hide what is behind them, so only two or three attractions show at once and moving reveals more [VIDEO 11 @5:12, @5:42]. TerrainGen craters and fBm hills give the shapes; put points of interest on peaks.
- **Look up.** Players look up only when the game teaches them: high ground, enemies on roofs, cables, a lone overhead light [VIDEO 9 @12:36].
- **One visual language for interaction.** Only usable doors look like usable doors; blocked ones always use the same blocker prop [VIDEO 9 @7:35]. ProximityPrompts only on things that work [RULE].
- **Choices visible from a junction.** Put the big choice where both options can be seen [VIDEO 9 @9:05].
- **Long goals, not waypoint chains.** "Reach the crater rim, up to you how" beats "go here, press this" [VIDEO 9 @18:12].
- **Wayfinding toolkit** [LDB, paraphrased from [Wayfinding](https://book.leveldesignbook.com/process/blockout/wayfinding)]: pair a tall landmark with a wide sightline or a framing window; put cues ahead of where players move; mark the route with color contrast; light entrances and exits; breadcrumb collectibles; walls and fences are the most reliable blockers, pits and rivers block movement but not sight; signs alone get mistaken for set dressing. Start subtle, add stronger aids when playtests show people getting lost, and layer subtle aids over reliable ones.
- **Blockout habits** [LDB, paraphrased from [Blockout](https://book.leveldesignbook.com/process/blockout)]: a scale figure and a gridded floor in the scene; walls 150-200% of figure height; doorways at least twice the figure's width; walk it at normal speed with collision, not by flying; expect most blockouts to fail their first playtest; terraces for slopes, no erosion generators at this stage.

## Negative space and clarity [VIDEO 12]
- **Squint/blur test** on every zone shot: paths, entrances, objectives and players must still read when blurred; if foreground and background fight, "neither's going to win" [@13:46, @16:21]. VISUAL_QA reviewers do this on each capture.
- **Figure and ground.** Players must stand out from the world. A popular map lost its players purely from murky tone and color with the same layout, then recovered when cleaned up [@17:56, @19:51].
- **Ask what to remove.** Replace detail with a change of light or color [@25:34]. Keep branch points few: the best version of a famous map had about 4-5 branches from center to base [@33:17, @41:59].
- **Colorful worlds hide gameplay.** Bad North's earlier prototype was "too colorful" for UI and units to read on top [VIDEO 18 @5:08]. Keep the terrain palette muted; saturate pickups, hazards and players [RULE].

## Dressing the world [VIDEO 25, VIDEO 14, VIDEO 18]
- No straight lines in organic land; give cliffs a lip; sand in the shallows, stone on steep slopes, grass on tops [VIDEO 25 @5:39, @8:13, @9:57]. TerrainGen.materialFor does the slope/height part.
- Ring the play area with facade cliffs or background hills so the world feels bigger and players cannot see out [VIDEO 25 @5:39, @6:10, @15:22].
- Rocks: a few big, wide rocks layered like real formations, then smaller ones; never three identical rocks in a row; rotate one rock for four variants [VIDEO 25 @17:52, @19:30]. A small kit of distinct-from-every-angle "rock words" makes "rock sentences" [VIDEO 14 @21:15]. "If you only need three rocks don't make a fourth" [VIDEO 14 @22:18].
- **Detail goes at transitions**: grass-to-cliff edges, path corners and intersections [VIDEO 18 @28:30, VIDEO 25 @26:58].
- Rotate neighbouring trees and props 90° or more, mix sizes, keep plant density down for performance [VIDEO 25 @26:58]. WorldBuilder.scatterProps gives every copy a random yaw.
- Spend texture detail on story props; keep big shapes simple [VIDEO 14 @23:49].

## Procedural generation that doesn't look procedural [VIDEO 17, VIDEO 18]
- **Bake in Edit mode, then hand-polish.** Generate with WorldBuilder through the Studio MCP `execute_luau`, save, then dress by hand (see `docs/research/MAP_ANIMATION_GUI_CRAFT_2026-10-23.md` §1.1).
- **Terrain limits** [DOC]: `WriteVoxels` at resolution 4, grid-aligned, at most 4,194,304 voxels per call ([Terrain](https://create.roblox.com/docs/reference/engine/classes/Terrain)). `TerrainGen.planChunks` splits regions under that cap and is tested.
- **Tile-based (WFC) maps:** a slot grid of tile Models with hashed edge sockets; resolve hard constraints first (sky outside, water below), place gameplay anchors (spawn, shops) first, score picks by how much they grow the walkable area, snapshot and reload on contradiction [VIDEO 18 @15:30, @16:00, @19:59, @21:00].
- **Generate from the edges inward, height never decreasing** ("erosion backwards"); reject tiles that leave unreachable land [VIDEO 17 @16:52, @18:22].
- **Dual grid for terrain transitions**, primary cells for small objects; rivers on edges, roads cell to cell [VIDEO 17 @7:08, @9:09].
- **No module next to its own mirror**, and swap themes, colors and foliage to fight sameness [VIDEO 18 @34:15]. Slightly asymmetric corners make mirrors useful [VIDEO 18 @27:28].
- **Props are a separate non-overlapping pass** [VIDEO 17 @23:29]: `TerrainGen.scatter` keeps a minimum distance, seeded and tested.
- **Validate** each generated map: reachable spawn-to-every-landmark, enough flat build space, no landmark hidden from every approach [VIDEO 18 @20:29, RULE].

## Check before VISUAL_QA [RULE]
Overhead map and color script in SPEC.md; greybox playtested for travel time; landmark visible from spawn; each zone passes the squint test; terrain palette muted next to gameplay colors; procedural maps validated for reachability.
