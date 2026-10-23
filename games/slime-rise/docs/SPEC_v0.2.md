# Slime Rise v0.2: the Slime Lab (spec)

Direction from Sharman, 2026-10-23: the game is a **slime lab facility** with a slime leak.
Players ride an **elevator** into a containment shaft. They solve **team puzzles** that unlock
the next platforms, climbing toward the exit while the slime rises. Saving and sounds land first.
Then come cutscenes, the elevator and Blender-built maps. v0.1 (spiral tower) is in `SPEC.md`.

**One sentence a kid gets:** The lab is leaking slime. Team up, fix the leak, climb out!

## Flow
| Step | Where | What happens |
|---|---|---|
| 1 Lobby | Lab atrium (reception, slime tanks, hazard signs, monitors) | Spawn, walk around, see the crown leaderboard |
| 2 Elevator | 3 elevator pods along one wall | Step in. First player in is host: **Solo** or **Public**, max players 1-8 (stepper). Public pods show `2/6` above the door so others can walk in |
| 3 Ride | Inside the pod | Host presses **GO**, or 10 s auto-start when full. Doors close (animated), camera cutscene: light flicker, shake, floor counter `B1 … B7 CONTAINMENT`, fade |
| 4 Flyover | Match map | Camera cutscene from the exit hatch down the shaft to the leak, title card `SECTOR 7: SLIME LEAK`, then 3-2-1 |
| 5 Match | Containment shaft | Climb tiers; each tier's puzzle extends the platforms to the next tier. Slime rises the whole time |
| 6 Results | Match, then lobby | Escapes, crowns earned, back to the atrium |

**Matches (prototype):** each elevator party gets its own copy of the map in this server,
offset far apart (`MatchService`, one match = one party). **Launch:** each party gets its own
reserved server through TeleportService (needs a published place, so this ships later).

## Match map: containment shaft (4 tiers)
- A tall lab shaft: catwalks, pipes, tanks, glass panels, rotating warning lights, hazard stripes.
- **Tier = a climbable section** (pads and catwalks) ending at a **gap**. The puzzle station on that tier
  extends hydraulic bridge platforms (animated slide-out plus sound) across the gap to the next tier.
- Top tier: the exit hatch. Reaching it = escape.
- The slime starts below tier 1 and rises on the same server-time curve as v0.1 (`SlimeCurve`).
  The match is longer (about 150 s) so there is time for 4 puzzles.

## Team puzzles (server-authoritative, one per tier, picked by seed)
| Puzzle | How | Scales with party |
|---|---|---|
| Valve Wheels | Hold a ProximityPrompt (2 s) on every valve on the tier | valves = min(players, 3) + 1, spread around the tier |
| Pressure Plates | Plates must all be stood on at the same time for 1.5 s | plates = min(players, 3) |
| Color Code | A monitor shows a 3-color code; levers cycle colors until all match | 3 levers, anyone can pull |
| Fuse Run | Carry a fuse canister from a shelf to the socket (slower walk while carrying) | 1 fuse, + 1 per 3 players |

- A solved puzzle gives **+1 crown to everyone alive** in the match ("Team bonus" banner) and extends the bridge.
- Clients never decide a solve: prompts and plates are checked on the server.

## Crowns
v0.1 rules (escape, speedy, podium) plus team bonuses. **Saved** with ProfileStore:
`{ Crowns, Escapes, BestTime }`, session-locked. Studio uses a mock store, so tests never touch real data.

## Sounds and music
Lab ambience hum (lobby), elevator ding, hum and doors, alarm and siren loop in the match, slime bubbling (3D, at the surface), a sound per power,
puzzle progress click plus solve chime, hydraulic bridge, escape fanfare, slimed splat. Roblox audio library only, ids in `Config.Sounds`.

## Look (visual: screenshots to Sharman before the art pass)
- Sky: dark facility interior, no daylight. Cold teal/purple ambient, green slime glow from below, red rotating alarm lights.
- Lighting: Future, Atmosphere haze tinted green near the slime, bloom on neon.
- Materials: dark plum metal panels, hazard yellow/black stripes, glass tanks with glowing slime.
- Blender: modular kit (wall panel, catwalk, railing, pipe run, tank, elevator pod, bulkhead door, hatch). Low-poly, exported FBX, imported by Sharman (Studio Import 3D).
- Detail bar: match or beat the v2 icons (`reference_dev/UI_RULEBOOK.md`, "Detail bar").

## Acceptance test (v0.2)
1. Crowns persist across a rejoin (published place) and use the mock store in Studio.
2. Sounds play for every action listed above. Music and ambience loop without gaps.
3. Two parties can run separate matches at once in one server.
4. Each tier's puzzle extends the bridge; the next tier is unreachable before the solve.
5. Elevator cutscene, then the flyover, then the match, with no camera stuck after the cutscene (camera returns to Custom).
6. Zero Output errors across a full solo run and a two-player run.
