# 03 Rarity and RNG

Facts: paid random items must show every outcome with numeric odds summing to 100% before purchase, including items bought with Robux-bought currency; boosters and pity must state their numeric effect; respect `PolicyService:GetPolicyInfoForPlayerAsync().ArePaidRandomItemsRestricted` with an alternative path ([paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items)).

Studio rules:
- Tiers with fixed colors everywhere: Common (grey), Uncommon (green), Rare (blue), Epic (purple), Legendary (gold), Mythic (red/rainbow). Never reuse a tier color for anything else.
- Show odds as "1 in N" — players read it faster than percentages.
- Rarer = bigger reveal: longer anticipation, screen flash, unique sound, server-wide announcement for the top tiers.
- Pity/luck systems are visible (a bar that fills), and stated numerically.
- Roll logic lives in a pure, seeded, unit-tested module. The server rolls; the client only animates the result.
