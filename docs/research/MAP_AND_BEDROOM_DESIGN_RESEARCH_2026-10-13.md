# Map and bedroom design research (2026-10-13)
For *Steal a Dream*. Why: Sharman disliked the v1 grey-box (8 identical square rooms in a tight ring around a glowing strip). He wants rooms **spread out, oriented differently, intricate, "dimensional", Pixar-like, dreamy, low poly**. ~55 searches/fetches, no sub-agents. Build instructions distilled into `../reference_dev/BUILD_RULEBOOK.md`.

Confidence tags: **SOURCED** (URL given), **UNVERIFIED** (memory, fan site, or conflicting sources), **PROPOSAL** (Claude's design choice, tune in playtest).

---
## 0. Answer first (revised after Sharman's 2026-10-13 follow-up: LARGE rooms, intricate, reference popular games)
1. **Layout:** hub-and-spoke of floating cloud islands. One central hub (Dream Stream + Egg Machine + a 60-stud Moon Lighthouse landmark) and **8 bedroom islands at irregular angles, radii 150-192 studs and heights -4 to +24**, each yawed toward the hub ±15-30 deg. Awake players walk curving cloud bridges (59-102 studs long); dream ghosts fly straight across the gaps. Neighbours are 126-151 studs apart, the opposite room 302.
2. **Bedroom (LARGE):** a **48 W x 40 D stud** "dollhouse cutaway" (about 9 characters wide), with the open front facing the hub. Side walls are 12, the steep gable ridge is 28, the island deck is 72 across. The floor is divided into **fixed expansion zones** so every upgrade has a reserved place: a bed bay (16x16, fits the starter mattress up to the Dream King Bed), starter shelf towers (slots 1-8, then a top row for 9-12), a left-wall unit (13-20), a right-wall unit (21-24), a Dream Jar pad, a decoration corner, and a 16-wide central aisle. **About 300-380 parts per room** with layered trim, bevels, props and 3-4 lights.
3. **Variety:** the same interior kit inside 4 shells (Attic, Treehouse, Cloud Pod, Moon Igloo), with a unique bedding/accent colour per room so players can say "the mint room".
4. **Look:** night, LightingStyle Realistic, purple ambient, a big moon (MoonAngularSize up from 11), Atmosphere haze, Bloom so Neon glows, warm gold PointLights in every room. Warm inside, cool outside.
5. **What popular games teach (section 1b):** they keep the *base shell* simple and readable and put the density in **repeated display slots, trim and signage**; detail is spent where players look (the slots and the entrance). Exact stud sizes for these games are **not published anywhere searchable**. To get real numbers, insert a free Creator Store "steal-a-base" template in Studio and measure it (next step, needs Sharman's Toolbox click).

---
## 1. How top Roblox games lay out player bases
| Game | What we know | Tag |
|---|---|---|
| **Steal a Brainrot** | **8 bases spaced evenly around the map**, assigned at random on join. Brainrots walk a central **Red Carpet** conveyor from a cave; anyone can buy one before it reaches the end. Bases have floors unlocked by rebirth (floor 2 at rebirth 2, floor 3 at rebirth 10); slots grow from 10 toward high-20s. A **Base Lock** (step on a yellow circle) seals the entrance with **lasers** for a while. A trading plaza sits near the carpet; "Los Traders" is on a raised platform in the middle overlooking the conveyor. Fuse machines flank the carpet. Guides: thieves "grab the first brainrot they see"; corner bases are safer; upper floors slow thieves. | SOURCED (fan guides: [u7buy](https://www.u7buy.com/blog/steal-a-brainrot-game-mechanics/), [playnews](https://www.playnews.gg/en/guides/steal-a-brainrot-roblox-the-complete-strategy-rebirth-and-tier-list-guide-for-july-2026), [rblxguide](https://rblxguide.com/games/steal-a-brainrot/updates/steal-a-brainrot-best-base-layouts-2026)) |
| Steal a Brainrot server size | **8 players per server** (public and private). | SOURCED by fan sites only ([allthings.how](https://allthings.how/how-to-use-steal-a-brainrot-private-servers-in-january-2026/), [ofzenandcomputing](https://www.ofzenandcomputing.com/steal-a-brainrot-private-server-links/)) |
| Steal a Brainrot exact geometry | My memory: two rows of 4 bases facing each other across the carpet, open fronts toward the carpet. Fandom wiki blocked (402). | **UNVERIFIED** |
| **Grow a Garden** | Each player gets a plot; base farmland is described as a 4x2 or 3x2 grid (sources differ); plots expand left/right (+8 studs per side purchase) and back, **never the front** (the front faces the shared street). Shops (Seeds, Sell, Gear, Eggs, Cosmetics) sit on the shared strip; Gear Shop is opposite Seed/Sell. Server size reported as **6**, newer reports say **4-5**. | SOURCED but conflicting ([bloxodes](https://bloxodes.com/wiki/grow-a-garden/plot-expansions), [beebom](https://beebom.com/how-to-expand-plot-in-grow-a-garden-roblox/amp/), [sportskeeda](https://www.sportskeeda.com/roblox-news/all-merchants-in-grow-a-garden), [allthings.how](https://allthings.how/grow-a-garden-player-count-server-limit-and-record-highs/)) |
| **Bloxburg** | Plot **30x30**, **50x50** with Large Plot pass (units = studs, UNVERIFIED that the wiki means studs); up to 5 floors with a pass. | SOURCED ([Bloxburg wiki](https://welcome-to-bloxburg.fandom.com/wiki/House)) |
| **Adopt Me** | Houses are interiors entered from plots placed around a town; Premium Plots are 4 glowing lots beside landmarks (hospital, farm shop, baby shop). Guides praise clear paths and teleporters. | SOURCED ([Adopt Me wiki](https://adoptme.fandom.com/wiki/Premium_Plots)) |
| **Pet Simulator 99** | Not a base game: a linear chain of numbered areas from a **Spawn hub** (shop, mailbox, rewards, leaderboards, index machine). Useful only as "hub holds the social/monetisation stuff". | SOURCED ([bloxodes](https://bloxodes.com/wiki/pet-simulator-99/areas)) |
| **Tycoons** | Plot count = server max players (one plot per slot); one common map pattern is a "central island hub for spawning, social, shops with player plots surrounding the island". Keep each plot compact so the owner sees the whole operation at a glance. | SOURCED ([creation.dev tycoon template](https://www.creation.dev/templates/tycoon-template), BuiltByBit listing) |
| Steal an Egg / Steal Animal Egg | Base = garden you bring eggs back to; biomes ordered by difficulty further from base. No layout data. | SOURCED, thin ([games.gg](https://games.gg/roblox/guides/steal-an-egg-beginner-guide/)) |

**Patterns that transfer**
- **Plots = server size.** 8 rooms means an 8-player server, the same as Steal a Brainrot. (The DREAMLINGS doc already says 8.)
- **The shared money source sits in the middle and every base's front faces it.** This is the readability trick: from the hub you can see into every base, so raids are visible. Grow a Garden never lets the front expand, which keeps the street readable.
- **Hub holds the shops, leaderboards and social space** (PS99 spawn, SAB trading plaza, tycoon hub islands).
- **Defence depth matters:** SAB players value corner/far bases and upper floors because thieves need more time. **Our distance and height spread does the same job.**
- **Readable raid feedback:** SAB has an alarm ping a few seconds after entry and a visible laser lock. We need the same: an alarm light on the room, the ghost trail, and "room glows while owner sleeps" (already in the design doc).

### 1b. How popular games build and decorate bases and interiors (added for Sharman's follow-up)
Search reality: wikis are paywalled (Fandom returned 402) and guides cover mechanics, not geometry. **No source publishes stud dimensions for SAB, Grow a Garden or Adopt Me bases.** Observations below are sourced where marked; the rest is Claude's recollection of the games' public look (**UNVERIFIED**, check by playing or by measuring a template in Studio).

| Game | Base / interior construction and decoration | Tag |
|---|---|---|
| **Steal a Brainrot** | Purchased units walk to the base and fill a **slot**; units sit on **pillars/pedestals** ("display it on a pillar to generate income"). Starter floor has 10 slots; **Rebirth 2 adds a staircase on the right side of the base and a 2nd floor with 10 more slots (20 total)**; floor 3 at Rebirth 10. The 2nd floor has two barriers (trapdoor + barrier) against the ground floor's one. A **Lock Base button** sits in a fixed corner (one guide: "north corner"), with a 60 s cooldown. **Base skins** (Lava, Galaxy, Gold, Diamond...) are purely cosmetic re-colours of the same shell. | SOURCED ([sportskeeda 2nd floor](https://www.sportskeeda.com/roblox-news/how-get-second-floor-steal-brainrot), [u7buy base guide](https://www.u7buy.com/blog/steal-a-brainrot-base-guide/), [progameguides](https://progameguides.com/guides/complete-steal-a-brainrot-beginners-guide/), [BuiltByBit skin pack](https://builtbybit.com/resources/brainrot-studs-map-pack.116457/)) |
| SAB look | Open-fronted multi-storey platforms in bright SmoothPlastic, the owner's colour on trim, glowing laser bars across the entrance, a cash-collect pad in front of each pedestal, big floating owner name/sign. Detail lives in **repeated slot modules + signage**, and the shell itself is plain. | **UNVERIFIED** (recollection) |
| **Grow a Garden** | Fenced plots on a shared street; plot expands **+8 studs per side purchase**, left/right/back only, the street-facing front fixed. A style-copy map lists "6 garden plots, fully fenced, each with 4 sub-plots". Shops line the street (Seed, Sell, Gear with a green roof, Eggs, Cosmetics). | SOURCED ([bloxodes](https://bloxodes.com/wiki/grow-a-garden/plot-expansions), [BuiltByBit GaG map](https://builtbybit.com/resources/grow-a-garden-style-map.102181/), [sportskeeda](https://www.sportskeeda.com/roblox-news/all-merchants-in-grow-a-garden)) |
| GaG look | Low-poly cartoon farm: flat grass, wooden fences, simple box shops with big painted signs, bright daylight. Players supply the density (crops). | **UNVERIFIED** |
| **Adopt Me** | Houses are interiors, often **bigger inside than the exterior suggests** (Futuristic House wiki); furniture can't be placed on balconies or at the front of houses, so **reserved no-build zones** exist. | SOURCED ([Adopt Me wiki](https://adoptme.fandom.com/wiki/Futuristic_House)) |
| **Bloxburg** | Plot 30x30, 50x50 with a pass; up to 5 floors. Community build advice: **trims, baseboards, crown molding, window frames from thin blocks**; **2-3 colour palette (neutral base + one accent on doors/frames)**; **expensive materials only as accents** (a stone skirt, a wood panel); mix textures for depth; lamps and fixtures for ambience; plants and wall art for character. | SOURCED ([Bloxburg wiki](https://welcome-to-bloxburg.fandom.com/wiki/House); build-tip blogs, low quality but consistent) |
| **99 Nights in the Forest** | **Campfire = hub** (the crafting Grinder sits at the campfire site; a dinner table spawns there in events). The campfire keeps threats away after dark, a warm safe pool in a dark cold forest. The **Decorations Update added 60+ furniture pieces, a paint tool, writable signs, grid snapping**; decor includes tables, shelves, couches, **mushroom decor, flowers, ponds, fences, fairy-light arches**. | SOURCED ([deltiasgaming decorations](https://deltiasgaming.com/?p=341744), [backyarddrunkard](https://backyarddrunkard.com/games/99nitf-decoration/)) |
| **Pet Simulator 99** | Bright, saturated, "kooky" themed worlds; spawn hub with shop, mailbox, rewards, leaderboards, index machine. | SOURCED, thin ([bloxodes](https://bloxodes.com/wiki/pet-simulator-99/areas)) |
| **Tycoons** | One plot per server slot; a central hub island with plots around it is a sold layout pattern; plots stay compact so the owner sees the whole operation. | SOURCED ([creation.dev](https://www.creation.dev/templates/tycoon-template)) |

**Takeaways applied to our rooms**
1. **Reserve upgrade space from day one** (SAB stairs and floors, GaG expansion strips, Adopt Me no-build zones). Locked shelf cubbies are *built but dimmed* so players see what they're working toward.
2. **Density goes into the repeated display modules** (cubbies with rarity pads, labels, little lights) and **the entrance/sign**, not into random clutter, so the shelves stay readable for thieves.
3. **Skins = re-colour the same shell** (SAB base skins). Our 4 themes swap only the shell and palette, never the slot positions, which keeps stealing fair.
4. **Bloxburg trim recipe** (baseboard, crown molding, window frames, corner posts, an accent colour on frames) is the cheapest way to make a part-built room look finished.
5. **99 Nights' warm hub in a dark world**: our hub and each lamp-lit room are warm pools in a cool purple night. Fairy-light arches and mushroom decor fit our dream theme directly.
6. **Put the lock/alarm control in a fixed spot in every room** (SAB lock button). Ours is the **Dream Bell** by the door.

**Level-design principles (non-Roblox, SOURCED)**
- **Weenies / landmarks + hub-and-spoke** (Disneyland): a tall landmark at the end of each route pulls players and orients them; a central hub with radial spokes stops "museum feet"; each branch needs its own lure so the strongest one doesn't pull everyone; vertical pointy things are reliable lures; make unwanted routes bland ("anti-weenies"). [above-the-garage.com/wienies](https://www.above-the-garage.com/wienies/), [Scott Rogers GDC 2009 via BoingBoing](https://boingboing.net/2009/03/27/gamedesign-lessons-f.html/amp).
- **Ruski's map tutorial (DevForum):** decide genre/theme/player count first; avoid boxy layouts and use curves; always give players something to look at; 2-3 entries per building; block out first, playtest, then detail. [devforum 277853](https://devforum.roblox.com/t/277853/1)
- **Environmental storytelling** (Smith & Worch, GDC 2010): stage spaces so the player reads "what happened here" from props, lighting and composition; some details should be missable. [GDC Vault](https://gdcvault.com/play/1012647/What-Happened-Here-Environmental), [Nieman Storyboard](https://niemanstoryboard.org/2011/01/14/harvey-smith-on-environmental-storytelling-and-embedding-narrative/)

---
## 2. Roblox building craft
### Scale (SOURCED unless tagged)
- Default R15 character is about **5.1 studs** tall ([devforum measurement](https://devforum.roblox.com/t/measurement-conversion/137419)). Our existing chest test used 1 Blender m = 3 studs.
- A DevForum builder suggests a normal door of **4.5-5 wide x 6-6.5 tall**; **16 studs** is about the tallest single closed floor ([door thread](https://devforum.roblox.com/t/how-can-i-improve-my-door-model/2217315), [donut shop critique](https://devforum.roblox.com/t/thoughts-on-donut-shop/270063/5)). For Pixar exaggeration we go chunkier: door 4.5 x 7.5 with an arched top (PROPOSAL).
- Default camera max zoom is reported as **128 studs** (community report, UNVERIFIED). Rooms are therefore viewed from 10-40 studs inside and 60-150 studs from the hub, so silhouettes and colour blocking must read at 150 studs.

### Part technique
- **Increments of 0.25 (or 0.125)** keep edges meeting cleanly; 0.1-style values make gaps and z-fighting. Use a single wedge for simple bevels; converted base parts beat hand-placed wedges; cylinders + spheres at joints give near-seamless curves. **Avoid unions on walkable areas and doorways** (collision inaccuracies, hard to edit). [FP1 curvature guide](https://devforum.roblox.com/t/building-curvature-in-studio/635127)
- **Low-poly roofs:** a flat top slightly overlapping the walls, wedges for slopes, union then export/reimport as a mesh if it must be resized. [devforum roof thread](https://devforum.roblox.com/t/idk-how-to-make-my-roof/1101823). Corner wedges can overlap a gap and be scaled to fit ([wedge corner thread](https://devforum.roblox.com/t/how-to-fill-this-wedge-corner/2164567)).
- **Z-fighting:** offset coplanar surfaces by about **0.01-0.05**, or resize so faces don't coincide; avoid 0.001 tricks (parts drifted ~0.008, mostly cylinders). Far-from-origin flicker is float precision, so **keep the map near the origin** (ours stays inside ±200). [glitchy blocks](https://devforum.roblox.com/t/glitchy-looking-blocks/566033/8), [0.001 drift](https://devforum.roblox.com/t/parts-randomly-changed-their-size-when-using-a-z-fighting-prevention-trick/4007417)
- **Ball parts are always spheres** (Size forced uniform), so squashed blobs need Cylinders, a SpecialMesh, or MeshParts (Roblox engine behaviour; UNVERIFIED wording).

### Budgets and performance (SOURCED: [Roblox perf guide](https://create.roblox.com/docs/performance-optimization/improve), devforum threads)
- No hard part limit. Triangles and draw calls matter more; about **500k triangles/frame** performs on weak devices (forum figure). Lag reports start around **30-50k parts** on old PCs; spread parts so no ~10k cluster is in one view.
- **Instancing:** identical mesh + material + appearance share one draw call (Parts and CSG count too). Unions are mid-efficiency; heavy unions should become meshes.
- **CollisionFidelity Box** for decor; set `CanCollide/CanTouch/CanQuery = false` on pure decor; anchor everything; **`CastShadow = false` on small props**; **light Shadows only where needed**; limit light count and range; avoid stacked transparent parts (overdraw).
- **Solid modeling** got faster (GeometryService), and MeshPart booleans now exist ([Studio beta](https://devforum.roblox.com/t/studio-beta-improved-solid-modeling-behavior-and-performance-in-studio/4357808)). Whether `SubtractAsync` works from Studio MCP `execute_luau` in Edit mode is **UNVERIFIED**, so test it once before relying on negated shapes.
- **StreamingEnabled:** StreamingMinRadius 64, TargetRadius 1024 defaults; use `StreamOutBehavior = Opportunistic` and `ModelStreamingBehavior = Improved`; `Atomic` models stream as a unit; Persistent is "very rare cases". [streaming docs](https://create.roblox.com/docs/workspace/streaming). Our whole map fits in ~400 x 400 studs, below the target radius, so streaming barely kicks in. **Make each room an Atomic model** so a room never pops in half-built.

### Lighting (SOURCED: [Lighting.md](https://create.roblox.com/docs/reference/engine/classes/Lighting.md), [indoor tutorial](https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-indoor-environments), [outdoor tutorial](https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-outdoor-environments), [robloxapi defaults v731](https://robloxapi.github.io/ref/class/Lighting.html))
- **`Lighting.Technology` is superseded** by **`LightingStyle`** (`Realistic` = naturalistic; `Soft` = stylised, flatter, softer, retro) and **`PrioritizeLightingQuality`** (keep shading quality vs view distance as quality drops). Technology is read-only to scripts. The tutorials say new places default to Soft; robloxapi lists the class default as Realistic. **Set both explicitly.** Players on low graphics may be dropped to Soft regardless ([devforum](https://devforum.roblox.com/t/realistic-lighting-on-lower-quality-settings/4027710)).
- Defaults: Brightness 1, ClockTime 14, Ambient/OutdoorAmbient 127 grey, EnvironmentDiffuse/SpecularScale 0, ExposureCompensation 0 (range -5..5, +1 = 2x), ShadowSoftness 0.2 (docs) or 0.5 (api), GlobalShadows true (voxels 4x4x4).
- **Official tutorial values worth copying:** indoor uses Realistic, Env scales 1, **Ambient 83,70,57** warm, Atmosphere Density 0.5, **candle PointLight Brightness 0.7, Color 255,202,156, Shadows on**; desk-lamp **SpotLight Angle 140, Brightness 4, Range 12, Color 255,238,202**; screen **SurfaceLight Brightness 2, Range 4**; **ExposureCompensation 0.5** (lifts highlights without washing darks); ColorCorrection Contrast 0.05, Saturation 0.1. Outdoor uses **Ambient/OutdoorAmbient 156,136,176 (light purple) at ClockTime 17**, Atmosphere Density 0.272, Haze 1; campfire PointLight Range 48, Brightness 2, Color 255,179,73.
- Indoor walls should be **≥1 stud thick** (tutorial uses 2.5) to stop light leaking.
- **Light range is clamped to 120 studs.** PointLight Brightness default 1. **PointLight is the most expensive on low-end devices.**
- **Atmosphere** (defaults Density 0.395, Offset 0, Color 200,170,108, Decay 92,60,14, Glare 0, Haze 0): Density hides distance; **Offset higher = distant objects silhouetted against the sky**; Color works with Haze; Decay needs Haze + Glare > 0. Fog properties hide when Atmosphere exists.
- **Bloom** defaults Intensity 0.4, Size 24, Threshold 0.95; Threshold 1 = only white blooms. **Neon parts + Bloom = our glow.**
- **Sky** defaults StarCount 3000, **MoonAngularSize 11**, SunAngularSize 21 (0-60); MoonTextureId default `rbxasset://sky/moon.jpg`.
- **SunRays** defaults Intensity 0.25, Spread 1; it follows the sun, so it is **useless at night**. DevForum: no built-in moon rays; people fake them with semi-transparent beam parts or retexture the sun as a moon ([moonrays request](https://devforum.roblox.com/t/moonrays-lighting-effect/3939228), [moonlight thread](https://devforum.roblox.com/t/how-do-i-achieve-moonlight/1235118)). DepthOfField defaults Far 0.75, FocusDistance 0.05, InFocusRadius 10, Near 0.75 (menus only).
- **Clouds** (Terrain clouds): Cover 0-1, Density, Color; lighting tints them. It probably must be parented to `workspace.Terrain` (**UNVERIFIED**).
- Night tip from DevForum: **dim the night with Ambient/OutdoorAmbient and ColorCorrection, not by zeroing Brightness**, because the moon disappears at Brightness 0 when a retextured sun is the moon. A reviewer of a night island said dark islands need "the slightest hint of torches", i.e. scattered warm lights ([feedback thread](https://devforum.roblox.com/t/feedback-on-map/3872688)).

---
## 3. Pixar-style + low-poly environment principles
- **Believability, not realism: "caricature reality to our needs."** Detail goes on the characters and a few key areas; the rest simplifies (Finding Nemo). Colour scripts map emotion scene to scene. Ralph Eggleston, [Production Designers Collective](https://www.productiondesignerscollective.org/?p=14345), [MoMA audio](https://www.moma.org/audio/playlist/192/2581).
- **"Simplexity"** (Up, art director Ricky Nierva): **simple shapes on first read (squares, circles), detail on closer look.** Carl is square (past), Russell and Ellie are round (future). **Carl's house is "dollhouse"-like, with oversized material textures and rounded table corners for a handmade, warm, cozy feel.** Colour saturation follows emotion. [AWN](https://www.awn.com/animationworld/going-simplexity)
- **Blender Studio "Sprite Fright" (Pixar-trained director):** "chunkification": remove thin, fragile elements and use big toy-like forms. Simplexity is selective detail. Bend pure geometric bases so they aren't sterile. Silhouette and shape hierarchy come first, detail last. Keep surfaces matte; avoid gloss. [Blender Studio](https://studio.blender.org/blog/sprite-fright-the-illusion-of-simplicity)
- **Shape language:** circles mean safe and friendly, squares mean stable, triangles mean danger and dynamism ([3dsense](https://3dsense.net/blogs/shape-language-in-character-design-communicating-through-geometry), [pixune](https://pixune.com/blog/shape-language-technique/)). For us, **rooms and Dreamlings use circles and soft boxes, nightmare elements use triangles**, and the danger read stays on the Nightmare mutation and ghosts.
- **Stylisation moves:** exaggerated proportions; curved, irregular, **tilted** shapes; scale features up cohesively; restrained asymmetry; bevel edges that should catch light ([Lynda stylized env course](https://origin-www.lynda.com/3ds-Max-tutorials/Elements-stylization/503885/573623-4.html), [novedge bevel tips](https://novedge.com/blogs/design-news/cinema-4d-tip-beveling-best-practices-for-realistic-hard-surface-modeling)). In parts, that means tilting props 3-12 deg, making beds and lamps oversized, and putting a wedge chamfer or half-cylinder cap on edges facing the camera.
- **Silhouette test:** every prop should be identifiable as a black fill ([Creative Bloq](https://www.creativebloq.com/how-to/concept-design-tips-for-artists/2)).
- **Rooms tell character:** Andy's room is bright with cloud wallpaper, Sid's room is dark; in Toy Story 2 the clouds became stars to show growth ([Pixar wiki](https://pixar.fandom.com/wiki/Andy%27s_house)). **Inside Out's Imagination Land took its cues from theme parks and includes a city where everything is made of cloud**; Dream Productions concept art uses soft blue and purple light around colourful sets ([Inside Out wiki](https://insideout.fandom.com/wiki/Imagination_Land), [D23](https://d23.com/directing-dreams-filmmakers-jaclyn-simon-valerie-lapoint-and-austin-madison-talk-creating-dream-productions/)). This gives direct licence for **a cloud-built dream world with theme-park weenies**.
- **Cozy bedroom composition** (interior-design sources, applied): **one focal point (the bed)**, pools of warm light from low lamps instead of overhead light, warm ~2700-3000K tones in rest zones, cool light at the window, and soft fabric shades ([osmoz](https://www.osmoz.com/inspiration/osmoz-magazine/1774/13-cozy-gamer-bedrooms-that-actually-feel-like-a-vibe), [hammonds](https://www.hammonds-uk.com/blogs/easy-bedroom-lighting-ideas-that-might-surprise-you/)).
- **Diorama / cutaway:** floor + 2 adjoining walls ("open corner"), with the ceiling and foreground walls removed; give wall edges something (hanging plants, lanterns, beams); avoid tangents; separate foreground/mid/background by value and temperature ([Womp room base](https://womp.com/assets/isometric-room-base-p79mhw9uj1/), [Clip Studio diorama](https://tips.clip-studio.com/en-us/articles/10690)).
- **Low-poly room references:** Sketchfab "Low Poly Room" (6.5k tris, CC-BY) and "Low Poly Bedroom scene" (10.2k tris); BlenderNation isometric bedroom tutorial (2025); low-poly room challenge budget <15k tris. [sketchfab low-poly room](https://sketchfab.com/3d-models/low-poly-room-a6bf7976f3ac401e96907aa5b8a0c1c1), [BlenderNation](https://www.blendernation.com/2025/07/09/isometric-bedroom-tutorial/), [challenge](https://www.blendernation.com/2017/09/14/low-poly-challenge-isometric-room/). Look only; we build from parts.

---
## 4. Proposal for OUR map (PROPOSAL)
### Concept: "The Dreamsea"
A night sky over a sea of lavender clouds. Each bedroom is a little house on its own floating cloud island. In the middle is **Hub Island**: spawn, the **Dream Stream** (a glowing river curling in a 270 deg arc around the hub), the **Egg Machine**, and the main weenie, a 60-stud **Moon Lighthouse** (a tower topped by a giant Neon crescent moon, visible from every room so ghosts can orient).

### Why this beats the v1 ring
| Sharman's complaint | Fix |
|---|---|
| Identical, tight ring | Irregular angles (12/55/98/142/188/231/274/318 deg), radii 150-192, heights -4 to +24, so no two rooms sit alike |
| Same orientation | Each room yaws toward the hub ±15-30 deg (alternating), so open fronts still face the hub for readability but the silhouettes vary |
| Cramped | 48 x 40 interior (v1 was 30 x 30 with 10-high walls), reserved upgrade zones, 16-wide aisle |
| Simple boxes | Steep gable with a dormer, crown molding, baseboards, corner posts, framed windows, chunky bed, arched cubby towers, porch, chimney, a cloud island with underside "roots" and a dangling crystal |
| Not dreamy | Night sky, big moon, clouds everywhere, Neon glow + Bloom, warm windows against cool purple |

### Positions (studs; hub centre at origin, hub deck top y=0, hub diameter 110)
| Room | Theme | Centre (x, y, z) | Yaw offset | Hub dist |
|---|---|---|---|---|
| 1 | Attic | (147, 2, 31) | +20 | 150 |
| 2 | Treehouse | (104, 16, 149) | -25 | 183 |
| 3 | Cloud Pod | (-22, -4, 156) | +30 | 158 |
| 4 | Moon Igloo | (-151, 24, 118) | -15 | 193 |
| 5 | Attic | (-151, 6, -21) | +25 | 152 |
| 6 | Treehouse | (-117, 20, -145) | -30 | 187 |
| 7 | Cloud Pod | (11, -2, -162) | +15 | 162 |
| 8 | Moon Igloo | (132, 12, -119) | -20 | 178 |
Room islands are 72 across. Neighbour room-to-room is 126-151 studs, opposite rooms (1 to 5) 302. Bridge spans (hub edge to island edge) are 59-102 studs, steepest about 13 deg. The whole map fits in about ±240 studs, close to the origin.

### Travel
- **Awake players** walk **cloud bridges** (10 wide, overlapping flattened discs, curved through 2 waypoints, slope ≤15 deg) from the hub to each room's side porch. At 16 studs/s that is about 5-8 s from hub to home. **There are no bridges between neighbouring rooms in v1**, so defenders and buyers pass through the hub, which keeps it busy.
- **Dream ghosts fly** at ~22 studs/s, ignoring bridges, via a `Ghost` collision group that doesn't collide with the World. Neighbour about 6-7 s, opposite about 14 s out and about 20 s back carrying a heavy Dreamling (-30%), so about 34 s of a 45 s timer. **Neighbours are easy and far rooms are a real gamble**, the same role SAB's corner bases play.
- **Raid readability:** open fronts face the hub, so a ghost inside is visible from the hub and from neighbours. A roof **Dream Bell** (Neon ball) turns red and pulses while a ghost is inside. A sleeping owner's windows glow blue (design doc). Ghosts leave a soft particle trail.

### Bedroom kit (summary; exact numbers in the rulebook)
**48 W x 40 D interior, side walls 12, ridge 28 (33.7 deg roof)**, open front facing the hub, an arched door on the right side wall onto a porch where the bridge lands. Floor zones (local x across, z front -20 to back +20):
| Zone | Area | Holds | Upgrade path |
|---|---|---|---|
| Bed bay | x -8..8, z 4..20 (16x16) | Old Mattress 8x11 + 2 nightstands | Bunk / Cloud / Moon / **Dream King Bed 14x16** replace it in place (King has headboard lamps, so the nightstands are removed) |
| Shelf towers | x ±9.5..±20.5, z 16.5..20 | 2 towers, 2x2 cubbies each = **slots 1-8** | 3rd row on top = **slots 9-12** (built from the start, dimmed and padlocked) |
| Left wall unit | x -23..-19.5, z -6..14 | 4 cols x 2 rows = **slots 13-20** | 12 to 16 unlocks the bottom row, 16 to 24 the top |
| Right wall unit | x 19.5..23, z 4..14 | 2x2 = **slots 21-24** | with 16 to 24 |
| Dream Jar pad | x 13..21, z -19..-11 | Jar 3.5 dia | bigger jar models on the same pad |
| Decor corner | x -22..-10, z -19..-9 | toys, beanbag | future decorations snap here + 2 wall poster spots |
| Aisle | x -8..8, z -20..4 | oval rug | keep clear (ghost and owner path) |
**About 300-380 parts per room, about 3,500-4,000 for the map**, far under the 30-50k lag reports.

### Theme variants (same interior, different shell)
| Theme | Shell change | Palette swap |
|---|---|---|
| **Attic** | Gable roof slabs + shingle stripes, brick chimney with a cloud-puff particle | plum roof, honey wood |
| **Treehouse** | Island replaced by a giant trunk + 3 branch stubs; plank walls; canopy of 9-12 green-teal balls instead of slabs; rope-plank bridge | moss/teal, bark brown |
| **Cloud Pod** | Walls white-lavender; roof = stepped dome of 4 shrinking cylinders; porthole windows; puffier island | lavender, sky blue |
| **Moon Igloo** | Dome of stacked cylinder rings in ice blue; a crescent-moon arch (wedge segments) over the open front; frosty glow | ice blue, silver, pale gold |

---
## 5. Open questions for Sharman
1. Should ghosts fly over the gaps (proposed) or follow the bridges too?
2. Is a 4-theme rotation enough, or should every room be unique?
3. Should higher rooms be safer (a longer flight) and be assigned by rebirth, or random like SAB?

## Not verified / to test in Studio
- `SubtractAsync`/negate from `execute_luau` in Edit mode.
- How bright the moon is as the directional light at ClockTime 0 under Realistic.
- Whether Clouds must sit under Terrain.
- The default camera max zoom (128).
- The exact Steal a Brainrot base geometry.
