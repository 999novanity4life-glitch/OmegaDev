# 07 Characters, VFX and Assets

Studio rules:
- Original characters only. "Anime-inspired" style is fine; named characters, logos and copied designs are not.
- Bosses: readable silhouette, name plate + HP bar, telegraphed attacks, hit reactions, a death moment.
- VFX scale with importance: common = small puff, rare = burst + light, mythic = screen-wide.
- Damage numbers pop, rise and fade; crits are bigger and a different color.
- Every asset id lives in `src/shared/Assets.luau` and `assets/ASSETS.md` (Librarian). Vet free models for scripts.

## Party games (added 2026-10-23, see chapter 14)
- Kill/explosion effects are the main cosmetic in bomb tag: Timebomb Duels ships 33 kill effects ([bloxodes](https://bloxodes.com/wiki/timebomb-duels)); credit the effect to the player who passed the bomb ([allthings.how](https://allthings.how/pass-or-explode-how-to-play-and-win-in-roblox/)).
- Lava: compute height(t) on every client from a server start time; server tweens look choppy ([DevForum](https://devforum.roblox.com/t/smoothing-tween/2653125)). Avoid z-fighting flicker on the lava surface ([DevForum](https://devforum.roblox.com/t/feedback-on-my-rising-lava/1215711)).
- Telegraph collapses: tiles heat yellow → orange → red ([Knockout wiki](https://knockout-roblox.fandom.com/wiki/Penguin_Peak)). Powers reuse the skill kit (`docs/rulebooks/SKILLS_VFX_RULEBOOK.md`).
