# OmegaDev game project: rules for AI agents

This is a Roblox game built with Rojo. The files in `src/` are the source of truth;
Studio is a view of them. Read this whole file before changing anything.

## Layout (see default.project.json)
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

## Definition of done (run all of these, paste the output)
```
stylua --check src tests
selene src
rojo sourcemap default.project.json --output sourcemap.json
luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json --definitions=@roblox=globalTypes.d.luau --base-luaurc=.luaurc --ignore="Packages/**" src
lune run tests/run
rojo build default.project.json --output game.rbxl
```
Then, if Roblox Studio MCP is connected: start a playtest (`start_stop_play`),
read `get_console_output` (zero errors/warnings from our scripts), take a
`screen_capture` of each new screen, and stop the playtest. A change is not
done because it compiles; it is done when the playtest evidence matches the spec.

## Workflow
Use the subagents in `.claude/agents/`: `omega-planner` writes the spec,
you implement, `omega-code-reviewer` and `omega-feel-reviewer` review,
`omega-playtester` proves it in Studio. Fix every blocker they raise before
moving on. Score the build with `docs/QUALITY_CHECKLIST.md` before shipping.
