# Fruit Fling: dock map plan (rule M2)

Status 2026-11-19: **plan + code only, not yet seen in Studio** (Mac offline). Reference board pending Sharman's OK (rule M1); the blockout code exists so the Mac can drop it in the moment refs are approved. Rules: `docs/rulebooks/MAP_RULEBOOK.md`.

Code: `src/shared/DockLayout.luau` (pure plan, tested in `tests/DockLayout.spec.luau`), `src/server/Services/DockBuilder.luau` (plan -> Instances + terrain). Numbers in `Config.Dock`. Set `Config.Dock.Enabled = false` to get the old greybox lane back.

## Archetype (section 4)
Hub + one long showcase lane. Hub = the pier and harbour cove; lane = open sea along -Z to a lighthouse.

## Critical path
| Leg | Studs | Seconds (WalkSpeed 16) |
|---|---|---|
| Spawn to throw line | 18 | ~1 |
| Pier shore end to throw line | 112 | ~7 |
| Throw lane (fruit only) | 800 | flight 1.1-3 s |
| Lighthouse | 880 from the throw line | the weenie (M8) |

## Areas
| Area | What happened here (M11) | Landmark | Palette / material |
|---|---|---|---|
| Pier | A working fruit pier on throwing day: crates just unloaded, nets being mended, lanterns lit for the evening contest | Throw line painted in orange; lantern row leading to it | Warm wood (3 tones), iron, rope; one orange accent |
| Harbour cove | A small fishing village lives in a terraced cliff bowl | Moored ship with the orange sail; huts clustered on the first ledge | Grey slate/rock, whitewash, red roofs |
| Lane | Open sea where fruits land; buoys mark the distance every 50 studs | Sea stacks alternating left/right every 160 studs | Deep teal water, red buoys, pale boards |
| Lane end | The lighthouse that every thrower aims for | Red/white lighthouse, turning beam | Whitewash + red, warm lamp glow |

## Three scales (M3)
- Macro: cove terraces (3 rings), ship hull + masts + sail, sea stacks, lighthouse island.
- Meso: deck, pilings every 8 studs (M34), bunting poles every 24 studs, huts.
- Micro: rope sags between piling tops (M40), lanterns on every 2nd piling (M41), bunting with flags (M36), prop story groups of 3-8 on the pier edges (M38) with a split fruit crate, a handcart and a fallen lantern as "caught mid-task".

## Lighting profile (M14-M17)
Golden-hour preset from `LightingPresets` (`RobloxOutdoorSunset`), Atmosphere density 0.08-0.15 to hide the horizon edge (M43), Bloom only on lanterns, buoy lamps and the lighthouse lamp (M17). Warm path (lanterns, throw line) vs cool sea and cliffs (M16).

## Debts (rule M18: parts are placeholders)
Every piece is tagged with the attribute `PlaceholderFor = <kit piece>`. Mesh pass (Blender kit, rule M29): Piling, Lantern, Crate, Barrel, FruitCrateOpen, Handcart, NetPile, RopeCoil, ShipHull/Mast/Sail, Hut, Buoy, DistanceBoard, Lighthouse. Rope segments become a rope mesh or Beams later.

## Review gate before showing Sharman (M25-M28)
Fixed stations: spawn eye-height looking down the lane; the throw line; far establishing shot from the cove's top terrace; top-down; lighthouse 4-angle orbit. Fresh `visual-reviewer` against the approved reference board. Then a walk of the pier in a playtest.
