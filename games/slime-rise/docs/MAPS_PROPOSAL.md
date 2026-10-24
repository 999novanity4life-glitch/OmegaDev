# Slime Rise: map set (PROPOSED, 2026-10-23)

Sharman's brief: several maps players choose from, ranked by difficulty; each a clearly different room of the lab (own shape, size, palette accents, own models) with the same vibe, procedure and detail; harder maps are larger, with more tasks and harder (proven obby) parkour; solo always works. Research: `research/obby_parkour_difficulty.md` (Tower of Hell / EToH).

## The four rooms

| # | Map | Difficulty | Shape (not a tube) | Size | Run | Signature models (new Blender kit) | Signature parkour |
|---|---|---|---|---|---|---|---|
| 1 | **Containment Shaft** (today's map) | Easy (1 star) | Round shaft | ~170 st tall, 4 floors | 4 sections + 4 puzzles, ~3 min | current lab kit | wide jumps, crates, catwalks, conveyors, bounce pads |
| 2 | **Cryo Vault** | Medium (2 stars) | Tall **rectangular hall** (90x60), mezzanines that zig-zag between the long walls | ~250 st, 5 floors | 5 + 5, slime faster | cryo pods, freezer racks, frost pipes, coolant tanks, ice crystals | slippery slime-ice ledges, freezer crate conveyors, fading frost panels, 1-3 st wraps |
| 3 | **Bio Greenhouse** | Hard (3 stars) | **Hexagonal chambers** stacked and rotated, glass dome ribs, open atrium in the middle | ~350 st, 6 floors | 6 + 6, slime speeds up after each gate | hydroponic towers, mutant plant pods, vine trusses, sprinkler arms, grow lights | vine truss climbs, mushroom bounce chains, swinging plant sweepers, phantom leaves, pillar wraps |
| 4 | **Reactor Core** | Extreme (4 stars) | **Cross-shaped** shaft around a giant reactor column, with short **outside segments** on the cooling vents | ~450 st, 8 floors | 8 + 8, slime surges | turbines, coils, capacitor banks, heavy cables, magnet rings | rotating turbine blades, timed electric rails, tightropes, wind and kill-strip combos, up to 10 st gaps |

Same across all: lab vibe, MaterialVariants, Blender kit detail, IntroPath cinematic (wide then push-in per floor, dips to black), the surface lift bay ending (re-themed per map), solo versions of every team puzzle.

## Difficulty rules (from the research, tune by playtest)
- Gaps: Easy 3-6 st, no wraps. Medium 6-8 st, 1-3 st wraps. Hard 8-9.5 st, 3-5 st wraps, 1x1 corners. Extreme up to 10 st, 5-7 st wraps, thin beams. (Max flat gap ~10-11 st at WalkSpeed 16 / JumpHeight 7.2.)
- Never the same obstacle family twice in a row; use 6 of 8 families per map; finish on a "final stretch", not a spike.
- Falls cost time and height (back to the floor start; on Hard/Extreme back 1-2 floors), only the slime ends a run. Mobile-safe: no required wall hops/flicks/11+ st gaps.
- Pressure: slime slack 30-40% (Easy) down to 5-10% with telegraphed surges (Extreme).

## Map picker
In the elevator pod screen next to Solo/Public and party size: a carousel of map cards (preview shot, name, difficulty stars plus colour band, size, your best time). The host picks; public pods show the map on the door sign. Easy is the default; harder maps can unlock after clearing the one before.

## Build order
1. Framework: map definitions (shape polygon, floors, size, difficulty numbers), perimeter-path course builder for any shape, picker UI, per-map best times. The current shaft becomes map 1.
2. Cryo Vault (Blender kit, then build, test, cinematic).
3. Bio Greenhouse.
4. Reactor Core.
Each new kit needs one Studio "Import 3D" click from Sharman (the meshes upload to his account), like the first lab kit.
