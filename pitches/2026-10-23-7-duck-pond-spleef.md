# Pitch 7: Duck Pond Spleef

**One sentence a kid gets:** Squirt the floor out from under the other ducks.

Data captured 2026-10-23 from Roblox's public games API (stats and votes) and rotrends/rowatcher (peaks). The full table is in `docs/research/PARTY_GAMES_2026-10-23.md`. "Inferred" = my judgment, not measured. "Steam rank" = position on Steam's official Top Wishlists search for that tag. SteamDB follower counts were blocked by a bot check, so read them by hand before greenlighting.

## Why now (Steam signal)
- **Slowly Sliding Ducks**: up to 50 duck players per pool. It is #34 on Steam's Party-tag Top Wishlists and releases Oct 29, 2026. https://store.steampowered.com/app/2485410/ ; rank: https://store.steampowered.com/search/?filter=popularwishlist&tags=7178
- Theme borrowed: rubber ducks on sinking foam tiles in a bathtub arena (no IP).
- Steam community hub members for **Slowly Sliding Ducks**: 1,673 (Steam's own XML endpoint https://steamcommunity.com/games/2485410/memberslistxml/?xml=1, seen 2026-10-23; hub members, not SteamDB followers, which were blocked).

## Familiar Roblox loop (block drop / spleef)
- **Rocket Spleef**: 227 playing, 87.9% likes, 4K peak. Rockets destroy the floor, and it has pickups and a ledge grab. https://www.roblox.com/games/126857641130765
- **Fading Blocks**, where tiles fall on their own, sits at 58.7% likes. An active verb beats passive falling (inferred). https://www.roblox.com/games/119075643463778
- **Knockout!** uses a tile decay pattern of yellow → orange → red. https://knockout-roblox.fandom.com/wiki/Penguin_Peak

## Loop
- Each duck has a squirt gun. Hit a foam tile 3 times and it sinks.
- The last duck floating wins.
- Pickups: Triple Squirt, Big Splash and Life Ring (one save).
- Rounds last 60-90 s.

## Where the depth comes from
- Trick shots and splash combos.
- Ledge-grab saves, plus a Life Ring that rescues you once to a cheer.
- Sinking tiles wobble and bubble before they go.

## Feel and polish (SKILLS_VFX_RULEBOOK shapes)
- **Projectile**: squirt streams (Trail plus a splash burst).
- **Ground**: a tile flashes when hit, then collapses with a ring splash.
- **Dash**: a belly-slide dodge.
- **Aura**: the Life Ring glows around a saved duck.
- **Reveal**: the winning duck squeaks and gets a bubble-bath podium.

## Monetization
- Sell: duck skins, squirt-stream colours and splash effects.
- Never sell: wins or crates.

## v1 scope
- 2 bathtub arenas.
- Server-owned tiles, with one attribute flip per tile state.
- 3 pickups and a wins leaderboard.
- Bots fill in below 4 players.

## Risks
- Spleef is a small genre; its top game has 227 playing.
- It needs the duck charm and clip-worthy splashes to break out (inferred).
