# Map rulebook: intentional builds and placement

Load before placing any environment geometry, even a small area. Short version in `vault/20 Map Building and Placement.md`.

Sources (paraphrased, not copied): benigeci/roblox-world-builder (MIT), SyphoDev-yt/roblox-ai-skills `roblox-map` (free licence, credit SyphoDev), PieLord757/roblox-game-development `level-design-craft` (MIT, which cites GDC talks, Totten, Lynch), arduoussteel/scatter-brush and ghulo/SmartScatter (MIT). Survey: `../research/MAP_BUILDING_REPOS_2026-11-19.md`. Lessons from Sharman's map videos get added in section 10 as they come in. Rule IDs (M1...) so reviews can cite them.

## 0. Why the current greybox looks cheap (fruit-fling, PR #28)
Checked against the feel-test shots (`fruit-throw/feel-test-2026-11-19/`):
- One flat water plane to the horizon, a black band where sky meets nothing. **No macro silhouette** anywhere (M3).
- Nothing at meso scale to frame the lane, nothing at micro scale near the camera (M3).
- No landmark or weenie at the end of the throw lane, so distance has no meaning except the text (M8).
- Lighting is default sky blue; no Atmosphere depth, no grade, no glow accent (M14-M17).
- Distance markers are the only detail and they are flat text, not objects in the world.
A greybox may be ugly, but it must already have the macro masses and the landmark in the right place. This one has neither.

## 1. Workflow (in order, no skipping)
- **M1** Understand → reference board → layout → scale → blockout → macro → meso → micro → lighting → optimize → review. Per Sharman's rule, the reference board is shown to Sharman and approved **before** the blockout.
- **M2** Plan first, in a short `MAP_PLAN.md` per game: archetype (see 4), critical path with distances in studs AND seconds (WalkSpeed 16 = 160 studs in 10 s), landmark per area, a "what happened here" sentence per area, palette, lighting profile.

## 2. Three scales, always
| Scale | Size vs ~5-stud character | Job | Fruit-fling example |
|---|---|---|---|
| Macro | 10-60x+ (50-300+ studs) | Reads from far, navigation anchor | Sea cliffs, a wrecked giant ship, a lighthouse, a Marine fortress on the horizon |
| Meso | 2-8x (10-40 studs) | Shapes spaces and routes, frames the view | Pier pilings, moored boats, crates stacks, rock arches over the lane |
| Micro | under ~8 studs | Rewards a close look | Ropes, barrels, lanterns, gulls, fruit crates, nets |
- **M3** Build macro first, then meso, then micro. Never fix an empty map by scattering hundreds of small props; never call one big structure in empty space finished.
- **M4** Micro gathers at bases, edges, junctions and focal points, with calm areas between. Density follows attention.
- **M5** Check every key structure at three distances: far (silhouette distinct), play (impressive, not toy-like), close (detail rewards). Screenshot all three.

## 3. Composition and placement with intent
- **M6** Every placed thing has a reason: frames a view, guides the eye, blocks a route, tells the story, or rests the eye. If you can't name the reason, delete it.
- **M7** No even spacing, no grids of decor, no copy-pasted clusters. Reuse assets but vary yaw, scale (±10-25%), tilt (3-12°), grouping and ground contact (sunk, wedged, leaning, overhanging).
- **M8** Weenie at the end of every major path or lane: taller, brighter, moving or uniquely coloured. Motion pulls hardest (a turning beacon, smoke, flags). Arriving at one reveals the next.
- **M9** Frame targets with doorways, arches, pilings, masts. Keep negative space around landmarks so they read.
- **M10** Scatter with Poisson-disc sampling (minimum spacing), never pure random (clumps and gaps look fake). Then add deliberate clumps: rocks cluster, trees keep off paths and roofs, lamps line a route, fences follow curves. Keep-clear zones on spawns, doors and the play lane.
- **M11** Every area has a "what happened here" sentence and 3-5 props that prove it: one cause-and-effect pair, one trace of routine. No random clutter in a story space.
- **M12** Districts: each area has its own silhouettes, palette, material and sound. A recolour of the same layout is not a new area.
- **M13** Boundaries are two things: scenery facing inward (cliffs, rocks, fog, ships) and a separate invisible wall. Prefer negative guidance (dark, clutter, a drop) over a bare invisible wall.

## 4. Pick the layout archetype
Linear pearls (runs), hub-and-spoke (progression, return trips), vertical stack (climb), dense room (investigation), districts (open play), arena lanes (PvP), stealth rings. A throw/fling game is **a hub + one long showcase lane**: the lane must read distance through landmarks every ~50 m, not just labels.

## 5. Lighting and atmosphere (measured gotchas)
- **M14** Inspect existing Lighting first; clear the place's own Sky/Atmosphere/PostEffects **by class** before applying ours, or two of each fight.
- **M15** Atmosphere does nothing without a Sky. Outdoor Density 0.08-0.15 (0.36 turned a 300-stud map into fog). `ColorShift_Top` is additive: keep it near (12,10,6)-(18,14,8). Keep ambient near-neutral; blue ambient x blue albedo = navy mush. ColorCorrection tint stays near-white unless a strong grade is the point.
- **M16** Light the critical path: warm or accent light on goals and exits, cooler side areas. Every objective has one emissive element that still reads with shadows off (phones below quality 4 drop shadows). Contrast beats brightness.
- **M17** Glow is for focus: Neon + Bloom on the landmark, the lane end and the fruit, not everywhere. Change one lighting value at a time and screenshot.
- `Lighting.Technology` cannot be set from plugin/`execute_luau` context; set it in the place file (Future) via Rojo or note it.

## 6. Mesh first
- **M18** Trees, rocks, buildings, boats, fences, mounds: meshes (Blender MCP + CC0 Kenney/Quaternius/Poly Haven, or approved Creator Store assets). Parts are allowed in greybox only, visibly as placeholders, and each is a tracked debt.
- **M19** A Ball part's diameter is the smallest size component (no squashed domes). A Cylinder's axis is X; `Terrain:FillCylinder`'s axis is Y. Do not mix them up.

## 7. Terrain and water
- **M20** Never put any surface at y = 0 (Studio grid shows through). Lift the map by a multiple of 4 (default 8). Terrain snaps to 4-stud voxels: plan terrain surfaces on multiples of 4, and never let two materials share a voxel band.
- **M21** No rectangular lakes or seas edges. Fill water as overlapping cylinders around a lobed outline; fill the basin first, then the water. Shorelines get rocks, foam and props from one shared outline.

## 8. Technical
- **M22** Folders: `Map/<Area>/Macro|Meso|Micro|Lighting|Gameplay`. Anchor static geometry. Micro props: CanCollide/CanTouch/CanQuery false, CastShadow false. MeshParts Box/Hull collision unless needed.
- **M23** Budgets (starting point, SyphoDev): per area at most 40 unique meshes and 12 unique textures; triangles grass 120, rock 300, building 800, tree 2500, landmark 3000-8000. StreamingEnabled on large maps.
- **M24** One ChangeHistoryService recording per build step; checkpoint (copy to ServerStorage) before destructive changes. Keep names/tags that scripts reference.

## 9. Review gate (before showing Sharman)
- **M25** Screenshots via Studio MCP `screen_capture` from fixed stations: spawn eye-height, play distance, far/establishing, top-down plan, and a 4-angle orbit of each landmark. Same stations every round so changes are comparable.
- **M26** Fresh `visual-reviewer` judges shots against the approved reference board (docs/VISUAL_QA.md). Fail = fix, max three rounds, then ask.
- **M27** Walk the real route in a playtest (`character_navigation`): spawns not buried, jumps reachable, nothing reachable that should not be, zero console errors.
- **M28** Report honestly: built / verified (how) / unverified.

## 10. Lessons from Sharman's map videos
One line per lesson, with the video note it came from (`docs/research/videos-map-building/`).
- **M29** Build hero areas and kits **in Blender by script** (Blender MCP on the Mac), export as meshes; Roblox assembles, lights and scripts them. Studio parts alone are for greybox. [video 01]
- **M30** Quality comes from passes: after each build pass, list the flaws from fixed-station screenshots, fix them, repeat. Never one-shot a map. [video 01]
- **M31** Judge in Roblox, not in Blender. A Blender render is not the game; only a Studio `screen_capture` counts for review. [video 01, inferred]
- **M32** Per shot: one hero composition, dense meso props along the edges, open floor where the player moves, warm vs cool light contrast. [video 01 gallery, inferred]
