# 08 Mobile

Fact: "The majority of Roblox users play on a mobile device"; design mobile-first ([design for Roblox](https://create.roblox.com/docs/en-us/production/game-design/design-for-roblox)).

Studio rules:
- Test every screen in Studio's device emulator at a short phone landscape size before PC.
- Drawn size is what counts: a 22 px label in a window scaled to 0.5 draws at 11 px. Keep drawn text ≥ 9 px (`UITextSizeConstraint.MinTextSize`), aim ≥ 12 px for anything read.
- Touch targets ~44 px drawn or larger; spacing so thumbs don't hit two at once.
- No instruction paragraphs; one short line or show it.
- Text "Tap" on touch, "Click" on mouse, "Press A" on gamepad.

## Party games (added 2026-10-23, see chapter 14)
- Touch-to-pass needs no button, which is part of why bomb tag works on phones (inferred from [bloxodes](https://bloxodes.com/wiki/timebomb-duels)).
- Simultaneous aim turns (Knockout!, 7 s) remove lag and aim gaps and are mobile-friendly ([wiki](https://knockout-roblox.fandom.com/wiki/Strategy_and_Techniques)).
- Parkour controls on phones: big jump button, power button above it, nothing else in the bottom corners.
