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

## Feel and juice (added 2026-10-28, notes in `docs/research/videos-2026-10-28/`)
Tags: [VIDEO n] = video note n; "how in Roblox" lines are our inference.
- **Feel first.** Tune movement on an empty baseplate before content; if the core verb isn't fun with no art, fix that first [VIDEO 6 @0:55, @1:06].
- **Every hit stacks cheap effects**: white flash (Highlight), small knockback, particle burst (`ParticleEmitter:Emit`), a layered bassy sound with random pitch, a little camera shake [VIDEO 1 @6:54, VIDEO 2 @12:06, VIDEO 3 @12:30, VIDEO 6 @3:10]. A complex shatter "no one can tell" from the simple one [VIDEO 1 @11:04].
- **Hit-stop about 20 ms** on hits and kills: the brain registers the impact without noticing the pause [VIDEO 2 @17:44]. How in Roblox: pause the hit animation tracks (`AnimationTrack:AdjustSpeed(0)`) for 1-2 frames.
- **Sound is the cheapest juice**; randomize pitch every play instead of shipping many files [VIDEO 1 @7:25, VIDEO 3 @12:30]. Rising pitch sells a combo [VIDEO 6 @3:41].
- **Permanence**: debris, splats and marks stay a while (fade them with a tween) so fights read afterwards [VIDEO 2 @13:07, VIDEO 3 @15:01]. Cap counts for performance.
- **Juice must match what the game is about**; don't stack effects at random [VIDEO 6 @4:30]. Offer a screen-shake toggle and respect Reduced Motion (Juice.luau already does) [VIDEO 2 @32:27].
- **Stretch and snap**: anticipation frames stretch far forward, then snap back; per-character spring sway gives personality [VIDEO 15 @26:45, @19:29]. Avoid camera roll (motion sickness) [VIDEO 15 @24:36].
- **Eyes add personality** at almost no cost [VIDEO 1 @12:41, VIDEO 3 @19:38].
- **You are the worst playtester of your own game**; watch someone else play [VIDEO 2 @33:30]. That is why VISUAL_QA uses a fresh reviewer.
- **Models**: run `docs/imported/claude-roblox-gamedev-kit/skills/mesh-qa.md` (back faces render magenta, check from below and at play distance) and review effects with `skills/vfx-review.md` (frame strips in daylight) before VISUAL_QA.
