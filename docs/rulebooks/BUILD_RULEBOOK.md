# Build rulebook: Steal a Dream environments
Build with `execute_luau` (Edit datamodel, one ChangeHistoryService recording per step). Sources: `../research/MAP_AND_BEDROOM_DESIGN_RESEARCH_2026-10-13.md`. All values are PROPOSALS. Style: Pixar "simplexity" (round shapes first, detail up close), matte SmoothPlastic, Neon only for glow, warm rooms in a cool purple night.

## 1. Scale
| Thing | Studs |
|---|---|
| Character | 5.1 tall |
| Door | 5 W x 8.5 H, round transom window above |
| Room interior | 48 W x 40 D, side walls 12, ridge 28 |
| Bed bay (starter to King) | 16 x 16 |
| Cubby (holds one Dreamling ≤3 tall) | 4.5 W x 4 H x 3 D, boards 0.5 |
| Aisle | 16 wide, kept clear |
| Room island deck | 72 diameter |
| Hub island | 110 diameter |
| Bridge | 10 wide, slope ≤15 deg |
Use a 0.25 grid, a 0.05 offset on coplanar faces, and keep everything within ±240 of the origin.

## 2. Palette (Color3.fromRGB)
| Use | RGB |
|---|---|
| Night sky / deep accents | 34, 27, 74 |
| Cloud top / cloud shade | 214, 204, 245 / 150, 134, 214 |
| Wall plaster (attic) | 128, 104, 178 |
| Trim, crown, posts (dark wood) | 92, 62, 70 |
| Floor planks A / B | 196, 140, 98 / 178, 124, 86 |
| Roof (attic plum) | 96, 64, 140 |
| Pillow / mattress cream | 255, 242, 224 |
| Lamp glow (Neon) | 255, 206, 128 |
| Moon (Neon) | 255, 244, 200 |
| Dream Stream (Neon) | 120, 236, 230 |
| Stars / gold accents | 255, 222, 110 |
| Rug coral / inner | 255, 128, 140 / 255, 186, 170 |
Per-room bedding accent (rooms 1-8): pink 255,150,196 · mint 120,220,170 · sky 120,180,255 · peach 255,176,120 · lilac 190,150,255 · lemon 255,226,120 · teal 80,200,200 · rose 230,90,130.
Rarity pads: C 200,200,210 · U 120,220,120 · R 90,160,255 · E 180,100,255 · L 255,190,60 · M 255,90,160.

## 3. Lighting preset (starting values, tune in Studio)
| Object | Settings |
|---|---|
| Lighting | LightingStyle Realistic, PrioritizeLightingQuality true, ClockTime 0, GeographicLatitude 20, Brightness 2, Ambient 58,48,96, OutdoorAmbient 112,92,168, EnvironmentDiffuseScale 0.4, EnvironmentSpecularScale 0.2, ExposureCompensation 0.3, ShadowSoftness 0.6, GlobalShadows true |
| Atmosphere | Density 0.28, Offset 0.25, Color 150,120,210, Decay 90,70,160, Glare 0, Haze 1.6 |
| Sky | StarCount 5000, MoonAngularSize 22, CelestialBodiesShown true |
| Bloom | Intensity 0.7, Size 28, Threshold 0.9 |
| ColorCorrection | Brightness 0.03, Contrast 0.08, Saturation 0.15, TintColor 245,236,255 |
| SunRays, DepthOfField | off (no sun at night; DoF only in menus) |
| Room lamps | PointLight 255,190,120, Brightness 1.5, Range 20; Shadows on one lamp per room only |
| Window moonlight | SurfaceLight inward, 150,170,255, Brightness 1, Range 14 |
| Jar, crystals, bridge posts | PointLight Range 10-14, Brightness 0.8, Shadows off |
Too dark? Raise OutdoorAmbient first. Low graphics may force Soft.

## 4. Part rules
- Anchor everything. Decor: `CanCollide/CanTouch/CanQuery=false`, CollisionFidelity Box, `CastShadow=false` if <2 studs.
- Soften edges with half-cylinder caps, Ball feet, cylinder rolls and wedge chamfers. Tilt props 3-12 deg.
- Balls are always spheres. A crescent is a Neon disc covered by a background-colour disc offset diagonally, 0.05 nearer the viewer (one-sided views only).
- No unions where players walk. Test `SubtractAsync` before relying on it.
- Each room is an Atomic `Model`. StreamingEnabled, StreamOutBehavior Opportunistic. Slot pads get `SetAttribute("Slot", n)`.
- Budgets: room ≤380 parts, bridge ≤45, hub ≤600, map ≤4,500. Check Render Stats after each room.

## 5. Map layout
Hub centre (0,0,0), deck top y=0. For each room: `RC = CFrame.lookAt(c, Vector3.new(0, c.Y, 0)) * CFrame.Angles(0, math.rad(yaw), 0)`. Local -Z (the open front) faces the hub; +X is the door side.
| Room | Theme | Centre c | Yaw |
|---|---|---|---|
| 1 | Attic | (147, 2, 31) | +20 |
| 2 | Treehouse | (104, 16, 149) | -25 |
| 3 | Cloud Pod | (-22, -4, 156) | +30 |
| 4 | Moon Igloo | (-151, 24, 118) | -15 |
| 5 | Attic | (-151, 6, -21) | +25 |
| 6 | Treehouse | (-117, 20, -145) | -30 |
| 7 | Cloud Pod | (11, -2, -162) | +15 |
| 8 | Moon Igloo | (132, 12, -119) | -20 |

**Hub:** deck Cyl 110 x 6, 16 rim cloud Balls (14-22), underside Cyls 80/50/24.
- **Moon Lighthouse** (centre): striped Cyls 10 tapering to 6, 45 tall, Neon lantern at y 48, topped by a crescent of 9 tapering Neon blocks on a radius-7 arc that spins slowly on the client.
- **Dream Stream:** a 270 deg arc of radius 30, 18 Neon segments 8.5x0.4x6 at y 0.3 with cloud kerbs. A waterfall pours from a cloud at y 25 at the start; the end spills off a lip.
- Spawn (0,0,-42). **Egg Machine** (-30,0,-30): Ball body 12, glass dome, crank, 16x5 odds sign. Shop and leaderboard (30,0,-30). One bridge head per room angle.

**Bridges:** a Bezier from the hub rim (r 55) to the porch (local 31,-0.5,-1.5) with the control point 15 studs to the side. Cyl discs 10x1.5 every 6 studs, Ball-4 puffs every 12 per edge, a lamp post every 30. **Ghosts** fly free at ~22 studs/s (collision group `Ghost` ignores `World`).

## 6. Bedroom kit (local coords; floor top y=0; front z=-20, back z=+20)
| # | Piece | Spec |
|---|---|---|
| 1 | Island | Deck Cyl 72 dia x 4, top y -0.5. 12 rim Balls (14-22) at r 32. Underside Cyls 56/38/20 x 6 at y -7/-13/-19. Neon crystal Ball 4 at y -24 with a PointLight |
| 2 | Floor | 8 planks 48 x 1 x 5 alternating A/B, centres z = -17.5 + 5k, y -0.5. Front edge log Cyl 1.5 dia x 48 |
| 3 | Walls (1.5 thick) | Back 51x12 at z 20.75. Left 40 long at x -24.75. Right in 3 pieces around the door gap z -4..1 (lintel above 8.5) |
| 4 | Back gable | 2 WedgeParts (1.5, 16, 24) at x ±12, y 20, z 20.75, yaw ±90 so the low edge points outward |
| 5 | Roof | 2 slabs (30, 1.5, 44) at (±12.42, 20.62, 0), roll ∓33.69 deg. Ridge Cyl 2 dia x 44 at y 28.6. Fascia trim on the eaves |
| 6 | Trim | Baseboard 1 tall, crown molding 0.75 sq at y 11.6, front corner posts 2x12x2, front truss beams under the slabs at z -21, collar beams (30 x 1.25 x 1.25) at y 18, z -8/4/14 |
| 7 | Dormer (left slope, z 4) | Box 8 W x 6 H x 8 D, mini gable (2 slabs), framed window |
| 8 | Gable window | Ring Cyl 8 dia (dark wood) + glass disc 6.5 (34,27,74) at (0,20,20.75). Crescent moon (Neon 3 + cover 3). 4 Neon star dots. Moonlight SurfaceLight |
| 9 | Side windows | Left wall: two 5x6 openings, each with frame + cross mullion + sill box |
| 10 | Bed: Old Mattress | Frame 8.5x1.5x11.5 at (0,0.75,13.75). 4 Ball feet 1.4. Mattress 8x1.75x11 + 2 edge rolls (Cyl 1.75). Blanket 8.6x0.6x7 + fold Cyl 1.2 + tilted front drape. 2 pillows 3.4x1.4x2.2 tilted 10-15 deg. Headboard 9x7x1 + Cyl 9 arch top + Neon star. Footboard 9x3.5x0.8 with ball posts. Star mobile above at y 15 |
| 11 | Bed upgrades | Same bay, origin (0,0,12): Bunk 9x14 tall · Cloud (Ball puffs) · Moon (crescent headboard) · **Dream King 14x16** with canopy posts and headboard lamps (nightstands removed) |
| 12 | Nightstands + lamps | 3x3x3 at (±6.25,1.5,18.5), drawer face + knob. Mushroom lamp: stem Cyl 0.6x1.4, cap Cyl 2.6x0.9 + Ball 2.6 dome, Neon bulb Ball 1 + PointLight |
| 13 | Shelf towers (slots 1-12) | Two towers 10.5 W x 14.5 H x 3.5 D at x ±15, z 18.25: 3 rows x 2 cols. Rarity pad (Neon Cyl 3 x 0.2) per cubby. Bottom 2 rows = slots 1-8, top row = 9-12 (padlocked, pad Transparency 0.6, until bought). Arched crown on top |
| 14 | Left wall unit (13-20) | 20.5 long x 10 H x 3.5 D at x -21.25, z 4, facing +X. 4x2 cubbies. Plants and books on top |
| 15 | Right wall unit (21-24) | 10.5 long x 10 H at x 21.25, z 8.75, facing -X. 2x2 cubbies |
| 16 | Dream Jar | Gold-rim pad Cyl 7 at (17,0.2,-15). Glass Cyl 3.5x4.5 (Transparency 0.4). Neon fill Cyl 3.1, height = fill level. Cork lid. PointLight 10. ProximityPrompt |
| 17 | Rug | Cyl 16 x 0.2 at (0,0.15,-8) coral, inner ring 11 at y 0.2, Neon star centre |
| 18 | Decor corner | Beanbag (Balls 5+3), 3 toy blocks 1.5 tilted, book stack, slippers, plush. Future decor snaps into x -22..-10, z -19..-9 |
| 19 | Wall art, fairy lights | 2 posters 4x5 above the left unit; 8 Neon balls 0.6 along the front truss |
| 21 | Dream Bell | Post + Neon ball 1.5 inside the door (alarm/lock spot) and a Neon ball 2.5 on a bracket at the front ridge; red pulse while a ghost is inside |
| 22 | Porch + sign | Porch deck 10x1x12 at (31,-0.5,-1.5), 4 posts, 2 rails, a lantern. Owner sign: wood disc 8 hung by 2 chains under the front ridge at (0,24,-21.5), SurfaceGui with the FredokaOne name |

## 7. Theme shells (interior kit 10-23 identical; only the shell and palette change)
| Theme | Replace | Palette swap |
|---|---|---|
| Attic | (base) + brick chimney 4x8x4 on the left slope with a cloud-puff ParticleEmitter | plum roof, honey wood |
| Treehouse | Island underside becomes a trunk Cyl 14 + 3 branch stubs; walls in plank strips; roof becomes a canopy of 10-12 Balls (16-24) | roof 86,170,130, bark 120,80,60 |
| Cloud Pod | Walls 214,204,245; roof becomes a stepped dome of 4 Cyls (50/40/28/14, each 4 tall); porthole windows | lavender + sky 150,200,255 |
| Moon Igloo | Dome of 5 stacked ice-blue Cyl rings; a crescent arch of 9 tapering blocks framing the open front | 190,225,255 + silver + pale gold |

## 8. Build order
1. Lighting.
2. Hub.
3. Room 1, then screenshot it from the hub and from inside and show Sharman.
4. The other rooms via `buildRoom(i, theme, cf, accent)`.
5. Bridges.
6. Render Stats.
7. Log what worked in ROBLOX_STUDIO_NOTES.md.

Never block the line from the open front to the cubbies.
