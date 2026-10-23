# Pitch 9: Big Bad Freeze

**One sentence a kid gets:** The wolf freezes the piglets, and piglets unfreeze their friends.

Data captured 2026-10-23 from Roblox's public games API (stats and votes) and rotrends/rowatcher (peaks). The full table is in `docs/research/PARTY_GAMES_2026-10-23.md`. "Inferred" = my judgment, not measured. "Steam rank" = position on Steam's official Top Wishlists search for that tag. SteamDB follower counts were blocked by a bot check, so read them by hand before greenlighting.

## Why now (Steam signal)
- **Pigs and Wolf**: a fairy-tale chase game. It is #43 on Steam's Party-tag Top Wishlists and releases Q4 2026. https://store.steampowered.com/app/4285870/ ; rank: https://store.steampowered.com/search/?filter=popularwishlist&tags=7178
- Theme borrowed: a big-bad tagger chasing piglets who build quick barricades (no IP; a generic fairy tale).

## Familiar Roblox loop (freeze tag)
- **Freeze Tag 🧊** (4 weeks old): 2,925 playing, 81.7% likes, 5K peak. https://www.roblox.com/games/80048951661785
- The 2016-2018 originals are near zero; ConnorVIII's Freeze Tag has 2 playing. The genre is nearly empty, which is an opening (inferred). https://www.roblox.com/games/364802243

## Loop
- Rounds last 2-3 min.
- The Wolf freezes piglets by touch.
- A piglet unfreezes a friend by standing next to them for 1.5 s.
- Piglets can drop a straw barricade (on a cooldown).
- Piglets win if any survive the timer; the Wolf wins by freezing them all.
- The Wolf role rotates fairly and is never sold.

## Where the depth comes from
- Rescue runs and barricade blocks.
- A frozen-count HUD, so the finale builds.
- The leading old freeze-tag game named thaw responsiveness and a frozen counter as its key polish (https://devforum.roblox.com/t/freeze-tag-update-log/156264).

## Feel and polish (SKILLS_VFX_RULEBOOK shapes)
- **Aura**: a frozen ice block with a frosty shimmer, and a thaw progress ring.
- **Dash**: the Wolf's pounce (a short lunge on a cooldown).
- **Ground**: barricades pop up with a dust ring.
- **Projectile**: a snowball that briefly slows the Wolf (a piglet power).
- **Reveal**: a thaw burst with sparkles, and an end-of-round podium.

## Monetization
- Sell: piglet and wolf skins, ice-block styles and thaw effects.
- Never sell: "Wolf chance". Three hide-and-seek leaders sell seeker chance (flagged).

## v1 scope
- 2 farm maps.
- Freeze and thaw decided on the server.
- Barricades.
- Fair role rotation.
- The frozen-count HUD.

## Risks
- The Wolf can feel overwhelmed or overpowered, so the pounce and thaw times need tuning with Balance (inferred).
