# OmegaDev game template

A Roblox game template for building with AI agents: Rojo files as the source
of truth, strict Luau, lint/format/type/test gates in CI, Roblox Studio MCP
for playtesting, and reviewer agents.

## One-time setup (your computer)
1. Install Roblox Studio.
2. Install Rokit: `curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash`
   (Windows: see https://github.com/rojo-rbx/rokit).
3. In this folder: `rokit install` (installs the exact versions in `rokit.toml`).
4. `rojo plugin install` to add the Rojo plugin to Studio.
5. In VS Code, install the "Luau Language Server" extension for live types.
6. Turn on Studio's MCP server: open Assistant → … → Manage MCP Servers →
   "Enable Studio as MCP server", then use Quick connect for Claude Code.
   Manual alternative: copy `.mcp.json.example` to `.mcp.json` (macOS path;
   on Windows the command is `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`).
   The playtester agent expects the server to be named `Roblox_Studio`.

## Every session
```
rojo serve            # then press Connect in the Studio Rojo plugin
claude                # in a second terminal; it reads CLAUDE.md
```

## Checks (same as CI)
```
stylua --check src tests
selene src
rojo sourcemap default.project.json --output sourcemap.json
curl -sSfLO https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json --definitions=@roblox=globalTypes.d.luau --base-luaurc=.luaurc --ignore="Packages/**" src
lune run tests/run
rojo build default.project.json --output game.rbxl
```

## Publishing
`.github/workflows/publish.yml` builds and uploads with Open Cloud when you run
it by hand. Add repo secrets `ROBLOX_API_KEY` (scope `universe-places:write`),
`ROBLOX_UNIVERSE_ID`, `ROBLOX_PLACE_ID`. Use `Saved` to test privately first.

## What is in here
- `src/shared/Config.luau`: all tunable numbers.
- `src/shared/Progression.luau`, `RateLimiter.luau`, `Validate.luau`: pure, unit-tested.
- `src/server/Services/RemoteGuard.luau`: rate limit + validation on every remote.
- `src/client/Controllers/Juice.luau`: button press, pop-in, sound, camera shake (Reduced Motion aware).
- `.claude/agents/`: planner, code reviewer, feel reviewer, playtester.
- `docs/QUALITY_CHECKLIST.md`: score every build against it.

Not yet included: player data (add ProfileStore by loleris,
https://devforum.roblox.com/t/profilestore/3190543), and in-engine tests
(Jest-Lua via Open Cloud Luau Execution) for code that needs Roblox services.
