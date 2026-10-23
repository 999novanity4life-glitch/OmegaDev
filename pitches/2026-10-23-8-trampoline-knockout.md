# Pitch 8: Trampoline Knockout

**One sentence a kid gets:** Bounce everyone else off the trampolines.

Data captured 2026-10-23 from Roblox's public games API (stats and votes) and rotrends/rowatcher (peaks). The full table is in `docs/research/PARTY_GAMES_2026-10-23.md`. "Inferred" = my judgment, not measured. "Steam rank" = position on Steam's official Top Wishlists search for that tag. SteamDB follower counts were blocked by a bot check, so read them by hand before greenlighting.

## Why now (Steam signal)
- **Vikings On Trampolines**: a bouncy-arena party game. It is #40 on Steam's Party-tag Top Wishlists and is coming soon. https://store.steampowered.com/app/748810/ ; rank: https://store.steampowered.com/search/?filter=popularwishlist&tags=7178
- Theme borrowed: a trampoline park where pads break after 3 bounces (no IP).
- Steam community hub members for **Vikings On Trampolines**: 1,640 (Steam's own XML endpoint https://steamcommunity.com/games/748810/memberslistxml/?xml=1, seen 2026-10-23; hub members, not SteamDB followers, which were blocked).

## Familiar Roblox loop (sumo / push-off)
- **Knockout!**: 620,670 all-time peak and 96.1% likes. Everyone aims at once in 7 s turns, the platform shrinks, matches are capped at round 11, and players near an edge get rescued automatically. https://www.roblox.com/games/136764190843219 ; https://www.rotrends.com/game/9384605736 ; https://knockout-roblox.fandom.com/wiki/Guides
- **Bumper Balls**: 88.1% likes, 3.7K peak. https://www.roblox.com/games/75056101860138

## Loop
- Each turn, everyone secretly picks a direction and power within 7 s, then all bounce at once.
- Pads crack after 3 landings.
- The last player left on the park wins.
- Matches are capped at 11 turns.

## Where the depth comes from
- Reading where other players are likely to bounce.
- Combo bounces off walls.
- Simultaneous turns are lag-proof and play the same on phones (inferred from Knockout!).

## Feel and polish (SKILLS_VFX_RULEBOOK shapes)
- **Dash**: the launch, with a stretch-and-squash bounce.
- **Ground**: pads telegraph their cracks, and landings throw up a dust ring.
- **Projectile**: an aim arrow preview during the 7 s window.
- **Aura**: a "last bounce" glow on any pad about to break.
- **Reveal**: slow motion on the final knock-off, and confetti on the winner's trampoline.

## Monetization
- Sell: bounce trails, landing effects, outfits and a season pass of cosmetics.
- Never sell: paid trade tokens or eggs. Knockout! sells these (flagged).

## v1 scope
- 2 parks.
- The simultaneous-turn system.
- Pad health and edge auto-rescue.
- The 11-turn cap.
- Bots.

## Risks
- Knockout! fell from 620K to 666 playing while keeping 96% likes, which points to novelty decay (inferred).
- It needs weekly park updates.
