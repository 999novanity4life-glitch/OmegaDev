# OmegaDev studio: rules for AI agents

This repo is an AI game studio for Roblox. Read `vault/00 For Any AI.md` first.
Each game lives in `games/<slug>/` as its own Rojo project (copied from
`template/`). The files are the source of truth; Studio is a view of them.

## Layout of a game (see games/<slug>/default.project.json)
- `src/shared`  -> ReplicatedStorage.Shared   (pure logic + config, used by both sides)
- `src/server`  -> ServerScriptService.Server (all authority: data, currency, damage, purchases)
- `src/client`  -> StarterPlayerScripts.Client (input, UI, camera, sounds, effects)
- `tests/*.spec.luau` -> Lune unit tests for pure modules in `src/shared`
- `Config.luau` holds every tunable number. Balance there, not in logic.

## Hard rules
1. Every `.luau` file in `src/` starts with `--!strict`. No `any` unless a comment says why.
2. The server decides outcomes. The client only sends intent through a remote
   declared in `Remotes.luau`, connected via `RemoteGuard.connect` with a
   `Validate` check on every argument. Assume every client payload is hostile:
   check types, ranges, NaN/inf, string length, and that Instances are where
   they should be.
3. Game rules (math, progression, economy, odds) go in pure modules in
   `src/shared` with no `game`/service access, and get a spec in `tests/`.
4. Every player action gets feedback in the same frame on the client (see
   `Juice.luau`: press scale, pop-in, sound, shake), then a confirmation when
   the server answers. Respect `GuiService.ReducedMotionEnabled`.
5. UI is mobile-first: Scale sizing, `UIAspectRatioConstraint`, text min size 9+,
   `ScreenInsets = CoreUISafeInsets` for anything tappable, nothing under the
   default thumbstick or jump button.
6. Player data uses ProfileStore (session-locked) or the official
   session-locking pattern. Never write raw `SetAsync` on player data.
   `ProcessReceipt` is idempotent: record PurchaseId, save, then grant.
7. Paid random items must show every outcome with numeric odds before purchase
   and respect `PolicyService` `ArePaidRandomItemsRestricted`.
8. Never invent Roblox APIs. If unsure a class, property or method exists,
   check https://create.roblox.com/docs/reference/engine or run it in Studio
   via the MCP `execute_luau` tool before relying on it.

## Definition of done (paste the output)
```
node scripts/omega.mjs check <slug>
```
It runs StyLua, selene, Rojo sourcemap, luau-lsp strict analysis, Lune tests and
a Rojo build for that game. Every line must say PASS.
Then, if Roblox Studio MCP is connected: start a playtest (`start_stop_play`),
read `get_console_output` (zero errors/warnings from our scripts), take a
`screen_capture` of each new screen, and stop the playtest. A change is not
done because it compiles; it is done when the playtest evidence matches the spec.

## Workflow
The Lead (`.claude/agents/lead.md`) runs the studio: Pulse pitches, Architect
specs, Balance tunes, Scenic/Frame/Librarian make the world and assets, Builder
codes, code-reviewer reviews, Playtest and Kid Tester prove it in Studio,
Producer gates quality against `docs/QUALITY_CHECKLIST.md`, Splash makes store
art, LiveOps runs it after launch. Shared state goes through
`node scripts/omega.mjs` only. One agent in Studio at a time (`omega lock studio`).
