# 17 Combat Feel, VFX and Showcase GUI

How OmegaDev makes fights look and feel like the top battleground and anime
combat games: every hit lands, every style reads, every ultimate is a moment.
Code: `template/src/shared/CombatFeel.luau` (rules, tested), `ImpactFX.luau`
(client player), numbers in `Config.Feel`. Skill shapes and budgets stay in
`docs/rulebooks/SKILLS_VFX_RULEBOOK.md`.

Tags: [DOC] = create.roblox.com, [FORUM] = DevForum community advice (not
official), [VIDEO n] = note in `docs/research/videos-2026-10-28/`, [RULE] =
studio rule (our taste, not a fact).

## 1. The hit stack (every hit, in this order)
| Beat | What | Tool |
|---|---|---|
| Anticipation | Wind-up frames the player can read; stretch forward, then snap [VIDEO 15 @26:45] | `CombatFeel.beats` checks hits fall in the active window |
| Contact | Hit-stop on attacker AND victim tracks (`AnimationTrack:AdjustSpeed(0)` pauses [DOC AnimationTrack]) | `ImpactFX.hitStop` |
| Flash | White Highlight or impact frames on big hits | `ImpactFX.impactFrames` |
| Burst | `ParticleEmitter:Emit(n)` at the contact point [DOC ParticleEmitter] | `ImpactFX.spawnAt` / `emitAll` |
| Camera | Shake + FOV kick, only for the attacker and the victim | `Juice.shakeCamera`, `ImpactFX.fovKick` |
| Sound | Layered, bassy, random pitch; pitch climbs with the combo [VIDEO 1 @7:25, VIDEO 6 @3:41] | `ImpactFX.sound` |
| Aftermath | Knockback, debris and marks that linger and fade [VIDEO 2 @13:07] | game code |

Tiers escalate (`Config.Feel.Tiers`, checked by `CombatFeel.validateConfig`):
Light (30 ms stop, tiny shake) → Heavy (70 ms, FOV +3) → Finisher (100 ms, 2
impact frames, 0.35 s slow-mo) → Ultimate (120 ms, 4 impact frames, 0.8 s
slow-mo at 0.2x). Hit-stop around 20 ms registers without being noticed
[VIDEO 2 @17:44]; heavier tiers are longer on purpose [RULE]. Reduced Motion
keeps hit-stop and sound, drops shake, FOV, impact frames and slow-mo
(CLAUDE.md rule 4).

## 2. Fighting styles that read
A style is a **silhouette + a color + a rhythm** [RULE]:
- **Silhouette**: each style's idle and wind-ups have a distinct pose (low and
  wide, tall and coiled, floating). Check poses on a plain colored R15 rig from
  the side (SKILLS_VFX_RULEBOOK section 5).
- **Color**: one primary + one secondary per style, used by every emitter,
  trail, beam and UI accent of that style. LightEmission 1 for glow, 0 for
  dust and smoke [DOC ParticleEmitter: 1 = additive blending].
- **Rhythm**: frame data per move (`CombatFeel.Move`: windup / active /
  recovery at 60 fps). A fast style is 4-6 frame wind-ups; a heavy style 12-18
  with bigger hit-stop. Combos alternate short and long beats so they don't
  drone [RULE].
- **Transformations** (elastic/rubber forms, awakened states, giant forms):
  swap the moveset, recolor every effect, add a persistent aura, and give the
  change itself a 2-3 s ability cam (vault/18). Original designs only: no
  names, looks or signature moves from anime or other games (00 For Any AI,
  truth rule 5).

## 3. Building effects (what top VFX packs do)
- An effect is a Part or Model of **Attachments holding disabled emitters,
  Beams and Trails**, triggered by `Emit` bursts; packs sell them as folders
  by element and shape (Charge, Projectile, Impact, Ground, Slash, Aura)
  (BuiltByBit survey in SKILLS_VFX_RULEBOOK section 1).
- Store burst sizes as `EmitCount` / `EmitDelay` attributes on each emitter
  and fire them all with one call (`ImpactFX.emitAll`) [FORUM convention], so
  pack effects and our own drop in the same way.
- Emitter under an Attachment spawns from a point; Sphere and Cylinder shapes
  "will not display correctly" under an Attachment [DOC particle-emitters].
- **Flipbooks** (animated fire, smoke, slashes): `FlipbookLayout` Grid2x2 /
  4x4 / 8x8 or Custom, `FlipbookFramerate` max 30 fps, frames need
  transparent spacing, and clients turn flipbooks off on low-memory devices,
  so the effect must still read without them [DOC particle-emitters].
- **Squash** stretches particles (positive = taller) for speed streaks;
  `VelocityParallel` orientation for sparks [DOC particle-emitters].
- **ZOffset** layers emitters front to back without changing size; use it to
  keep the core flash in front of the smoke [DOC particle-emitters].
- **Slow-mo**: `ParticleEmitter.TimeScale` 0..1 slows particles in place
  [DOC ParticleEmitter]; pair it with track speed for ultimates.
- Mesh effects (shockwave rings, slash arcs, twisting tornadoes) are modeled
  in Blender, exported .obj/.fbx and tweened (size, transparency) in Roblox
  [FORUM VFX Tutorial 872437]. Use the Blender MCP on the Mac to make them.
- Drawn **impact frames** have no official method; options are a
  ColorCorrection flash (ours), particle flipbooks, or an ImageLabel flipbook
  in a BillboardGui [FORUM 2591414].

## 4. Budgets (phones first)
- Rate cap 400 particles/s, 100/s on mobile; Lifetime max 20 s [DOC
  particle-emitters]. Combat particles live 0.25-0.7 s (SKILLS_VFX_RULEBOOK).
- Big, overlapping transparent particles cost GPU fill rate (overdraw) [DOC
  particle-emitters]: fewer, smaller, shorter.
- Test every effect at the lowest and highest Editor Quality Level [DOC].
- Pack practice: < 400 particles and < 50 mesh parts per effect, pooled.
- Highlights: max 31 at once (SKILLS_VFX_RULEBOOK section 6).

## 5. Networking effects
- Server decides hits and damage; clients draw effects (CLAUDE.md rule 2).
- The attacker plays its own animation and VFX instantly; the server tells
  every other client to draw the same effect [FORUM 3686403, 1610853].
- Trigger VFX from animation markers (`GetMarkerReachedSignal`) so effects
  stay on the frame the animator chose [DOC Animation events; FORUM 3686403].
- Camera shake and impact frames are client-only: send them to the attacker
  and the victim, never to everyone [RULE].

## 6. Showcase GUI (combat HUD)
- **Ability bar**: per-slot cooldown sweep, pop 0.88 → 1 (Back) on use,
  stroke ping on ready (SKILLS_VFX_RULEBOOK section 6). Big mobile buttons on
  the right thumb arc, never under jump (vault/08).
- **Combo counter**: number punches in with `Juice.popIn` and grows a little
  per hit; color climbs with tier; resets with a fade, not a snap [RULE].
- **Damage numbers**: pop, rise and fade; crits bigger and a different color
  (vault/07).
- **Ultimate meter**: fills with a glow sweep (UIGradient offset tween); when
  full it pulses and the slot gets the style's color.
- **Style and form banners**: kinetic title (slam from 2x to 1x, chrome
  gradient text, accent glow), the same motion the trailer titles use
  (`trailer/src/components/Title.tsx`), so the game and its ads share one
  visual language (UITokens.Motion) [RULE].
- Use Forge GUI / Figma for layouts, then build with UIKit + UITokens.

## 7. Done means
1. `CombatFeel.validateMove` passes for every move; `validateConfig` passes.
2. A 6-10 frame strip of each effect in daylight from three angles
   (`docs/imported/claude-roblox-gamedev-kit/skills/vfx-review.md`).
3. Fresh `visual-reviewer` against a reference board (docs/VISUAL_QA.md).
4. Zero console errors in a playtest with two dummies taking every tier.
