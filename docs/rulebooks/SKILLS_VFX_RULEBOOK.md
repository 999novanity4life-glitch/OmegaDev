# Skills, combat animation and VFX rulebook (2026-10-23)

How Claude builds skills (combat or not), their animations and their effects for any of Sharman's games, and how to take what marketplace packs do and rebuild it in our own theme. Backed by: a survey of 434 of the 558 BuiltByBit "Animations & VFX" listings (2026-10-23), the descriptions of the 20 leading packs, official Roblox docs, and a working prototype in `src/skills/` that was playtested in Studio.

## 1. What the market sells (434 listings viewed, ranked by purchases/downloads)
| Kind | Leaders (count) | What it teaches us |
|---|---|---|
| Emotes / dances | Dance Animation 200+ (free, 3,064), 20+ R6 Emotes (free, 1,201), 32 Emote Pack (1,054) | Social games want lots of cheap loops; emote wheels |
| VFX libraries | SoulShroud Ultimate VFX (1,078; 6,500+ emitters, 185 auras), Ultimate RPG Combat & Loot VFX (604; 200 objects, 1,300 emitters), 100+ Combat VFX (559), 500+ Abilities & 1,300 VFX (342) | Effects are sold as categorised folders of Attachments + ParticleEmitters, plus a few meshes/flipbooks |
| Combat animation sets | Axe animations (1,083), 80+ weapon animations (417), Tactical Combat (385), Close Combat (300), 5 fist styles (188), R6/R15 combat packs (HydrazDev series) | Per weapon: idle, equip, 3-4 swing combo, block, hit reactions |
| Movement | Movement Animation Pack (555; dashes 4-dir, vaults, slides, climbs, crouch), Dynamic Parkour (297; 55+), Robust Advanced Movement | Dash and traversal animations make any game feel faster |
| Auras (RNG games) | 15 HQ Aura (229), 45 HQ RNG auras, Custom Aura Maker (40), dozens of single-aura listings by SYSTSON | Rarity status shown as a persistent body aura |
| Loot / progression VFX | RPG Combat & Loot (loot shines, chest open, scripted drops, comic pop-ups), Level Up VFX Pack 2, 64 Anime VFX "8 Elements + Loot" (7 rarity reveals, coin/gem bursts, rebirth, unlock) | The same effect kit powers rewards, not just fights |
| Skill frameworks | Combat/Skill Framework ($35: secure server-client, BodyMovers, Camera Shake, Ragdoll, Bezier modules), R6 Combat & Movement + phone support (M1 combo, block/parry, 4-dir dash), Battleground Combat System (M1 + block + 3 skills, mobile), Hammer Combat (combo, E special, F throw) | Every serious pack splits data, client visuals and server authority |
| NPC / life animations | RPG NPC Interactions (104), 30+ R15 "profession" packs (blacksmith, chef, miner...) | Ambient NPCs make hubs feel alive |

**The pattern every top VFX pack follows** (stated in the "64 Anime VFX" and "Ultimate RPG" listings): one module that can play, attach, fire and stop any effect with scale, speed and screen-shake options; effects pooled; each effect kept under a budget (that pack: under 400 particles and 48 mesh parts each). **Ability anatomy** sold per element: Charge, Projectile, Impact, Ground, Slash, Aura. **Rarity reveals** escalate tier by tier, each building on the one below.

## 2. Using a marketplace pack legally
- **Animations are Restricted assets** (Roblox, 2025-07-31): they load only in experiences the owner granted. Grants are made in Creator Hub > experience > Configure > Permissions > Assets, are not revocable, and work across creators. A seller's animation ids will not load in our game until the seller grants our experience (one dash-pack seller tells buyers to open a ticket for exactly this).
- **If a pack ships KeyframeSequences** (AnimSaves or .rbxm), and its licence allows it, open them in the Animation Editor and **Publish to Roblox under the game's owner** (user or group). Then the ids are ours and need no grants.
- **VFX objects** (Attachments, ParticleEmitters, Beams, Trails) are plain instances: recolour and retime freely within the licence. Their textures/meshes are uploaded assets owned by the seller; if they ever stop loading, re-upload the source PNG/OBJ files when the pack includes them.
- Never use a pack we have not bought, never rip assets from games, record every pack and its licence in `assets/SOURCES.md`.

## 3. Our skill system (built and playtested 2026-10-23)
Files in `src/skills/` (push with `src/tools/push_skills.py`):
| File | Lives at | Job |
|---|---|---|
| `SkillData.luau` | ReplicatedStorage.Skills | Every skill as data (shape, key, cooldown, cast time, range, radius, damage, knockback) + **Themes** (colours, labels per game) |
| `SkillAnims.luau` | ReplicatedStorage.Skills | Builds R15 KeyframeSequences in code with markers; loads tracks (published ids if set, else Studio temp ids) |
| `SkillVFX.luau` | ReplicatedStorage.Skills | One module for every effect: burst, ring, flash, shards, projectile + trail, afterimage, damage number, camera shake, and recipes charge / impact / slam |
| `SkillService.server.luau` | ServerScriptService | Validates the request, owns cooldowns, does hit tests (Spherecast, GetPartBoundsInRadius), damage, knockback; broadcasts visuals |
| `SkillClient.client.luau` | StarterPlayerScripts | Input (Q/E/R, T = theme), plays own animation instantly, moves own character for dashes, draws everyone's VFX, skill bar UI with cooldown sweeps |

**Flow:** key press → client plays animation + starts cooldown sweep at once (feels instant) → `UseSkill(id, aimDir)` → server checks type, finiteness, cooldown, alive, uses **its own** origin → after the cast time it computes hits and fires `SkillFx` to all clients → each client draws the effect in the caster's theme.

**Shapes implemented:** Projectile (Bolt), Ground AoE (Slam), Dash. Next shapes to add the same way: Slash (arc in front), Beam (Beam instance between attachments), Aura (persistent emitters on the body), Summon, Loot/Reveal.

**Playtest results (Studio, 2026-10-23):** Slam hit all 3 dummies (100 → 75) with knockback; Bolt hit at range (100 → 85); Dash moved 24 studs with afterimages; T swapped every label and colour (Amber Bolt/Fossil Slam/Raptor Dash ↔ Dream Bolt/Pillow Quake/Sleepwalk Dash); final run zero Output errors. Fixed during testing: torso pitch sign, mouse aim burying the bolt in the floor (pitch clamp ±15°, 0.6-stud sweep), afterimages copying accessories, an invalid particle speed range on the charge effect.

## 4. Turning any pack skill into our theme (the recipe)
1. **Name the shape.** Projectile, Ground, Dash, Slash, Beam, Aura, Loot, Reveal. Every skill in every pack is one of these or a chain of them.
2. **Write the numbers in SkillData** (cooldown, cast time = the animation marker time, range, radius, damage or effect, knockback). Gameplay lives here, never in the VFX.
3. **Pick or build the animation.** Ours from `SkillAnims` (code-built poses) or a pack's KeyframeSequence republished under our owner. Put the impact moment on a marker ("Fire", "Hit", "Go") and make `castTime` equal its time.
4. **Theme the effect.** Swap every `ParticleEmitter.Color`, `Trail.Color`, `Beam.Color`, Neon part colour and PointLight to the theme's `primary` / `secondary` / `dust` / `shard`. Keep LightEmission 1 for glow, 0 for dust. Swap textures that fight the theme (fire on a dream game → sparkles).
5. **Rename for the game** in `Themes.labels`.
6. **Re-balance** for the game type (simulators: no player damage, use the same skill to break ore or knock items loose; battlegrounds: damage).
7. **Budget check** (section 6) and playtest with zero Output errors.

**Non-combat uses of the same shapes (where most of our games will use this):**
| Moment | Shapes chained |
|---|---|
| Egg / fossil reveal | Charge (shake + inward sparkles) → Impact (flash, burst, ring) → Aura on the reveal in rarity colour |
| Steal grab | Dash toward the item → Loot pickup burst → carried item gets an Aura |
| Dig / mine hit | Ground (small) at the pick point + shards in the material colour + damage number = "+12" |
| Level up / rebirth | Ring + rising burst + flash + camera shake 0.6 |
| Rarity tiers | Same reveal, more layers per tier: Common burst only → Rare + ring → Epic + shards → Legendary + screen flash + shake → Mythic + aura + slow-mo (track AdjustSpeed 0.4) |

## 5. Animation authoring rules learned
- R15 pose tree: HumanoidRootPart (weight 0) → LowerTorso → UpperTorso → Head / UpperArms → LowerArms; LowerTorso → UpperLegs → LowerLegs.
- **Sign convention (checked on a rig):** `+X` pitch on UpperTorso/Head leans **back**; `+X` on an UpperArm/UpperLeg swings it **forward/up** (165 ≈ overhead); `-X` on a LowerLeg bends the knee; `LowerTorso = CFrame.new(0, -1.1, 0)` crouches.
- Check poses by spawning a plain R15 rig, colouring arms/legs, playing the track and freezing it (`TimePosition = t`, `AdjustSpeed(0)`), then screenshot from the side. Accessories hide poses on real avatars.
- `KeyframeSequenceProvider:RegisterKeyframeSequence` returned a hash id that worked in Studio play solo. Docs do not say it works in live games or replicates; for production, publish and fill `SkillAnims.ANIM_IDS`.
- Tracks: priority Action, `Play(0.05)`, markers via `GetMarkerReachedSignal`. Hit-stop = `AdjustSpeed(0)` for 0.07 s on the client when the caster's hit lands.
- Our own character's animations replicate automatically (played on the local Animator); other players see them.

## 6. VFX budgets and game-feel numbers
| Rule | Value |
|---|---|
| Emitter rate cap (docs) | 400 particles/s, 100 on mobile; prefer `Emit(n)` bursts |
| Per effect (pack practice) | < 400 particles, < 50 mesh parts, pooled |
| Particle lifetime | 0.25-0.7 s for combat, never > 2 s |
| Highlights | max 31 at once; change properties instead of add/remove |
| ViewportFrames | cannot show particles (use world-space reveals) |
| Hit-stop | 70 ms |
| Camera shake | 0.8° light hit, 1.2-2.2° slam, decays over 0.2-0.35 s |
| Dash | 24 studs in 0.22 s, FOV +10 then back over 0.25 s, afterimage every 45 ms |
| Projectile speed | 70 studs/s, pitch clamp ±15° |
| Cooldown UI | dark cover shrinking from full to 0 over the cooldown; slot pops 0.88 → 1 (Back) on use; stroke ping when ready |

## 7. Not done / open
- Mobile buttons for skills (the bar is display-only; keys only).
- Saving which skills a player owns (ProfileStore).
- Other players seeing code-built animations in a live server: needs published ids.
- Slash, Beam, Aura, Summon shapes; a pooled emitter cache (currently new instances + Debris).
