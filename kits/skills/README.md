# Skills kit: themed combat and reveal skills

Working, playtested (2026-10-23) skill system: Projectile, Ground slam and Dash, with server-checked hits, code-built R15 animations, one VFX module, and a skill bar with cooldown sweeps. Press **T** in a playtest to swap the whole theme (labels, colours) without touching code.

| File | Put it at | Job |
|---|---|---|
| `SkillData.luau` | ReplicatedStorage.Skills.SkillData | Every skill as data + Themes (colours, names per game) |
| `SkillAnims.luau` | ReplicatedStorage.Skills.SkillAnims | Builds R15 animations in code, with markers |
| `SkillVFX.luau` | ReplicatedStorage.Skills.SkillVFX | One module for every effect (burst, ring, shards, projectile, afterimage, numbers, shake) |
| `SkillService.server.luau` | ServerScriptService.SkillService | Validates requests, cooldowns, hits, damage, knockback |
| `SkillClient.client.luau` | StarterPlayerScripts.SkillClient | Keys Q/E/R, own animation, dash movement, everyone's VFX, skill bar |

How to reuse it for any game, the reskin recipe, budgets and game-feel numbers: see **Rulebooks → Skills, combat animation and VFX rulebook**.

Before shipping: these files predate the template's `--!strict` + RemoteGuard rules. Port the remotes to `Remotes.luau` + `RemoteGuard.connect`, and publish the animations under the game's owner (fill `SkillAnims.ANIM_IDS`).
