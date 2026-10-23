# OmegaDev

An AI game studio for Roblox, run by a team of Claude Code agents, with a local
control room to watch them and approve their work.

- **14 agents** in `.claude/agents/`: Lead, Pulse, Architect, Builder, Scenic,
  Frame, Librarian, Balance, Splash, Playtest, Kid Tester, Producer, LiveOps,
  Code Reviewer.
- **Control room** (`control-room/`), organised for beginners: **Start here** (Today, Guide),
  **Make games** (Game ideas with a Build-this-one button, My games), **The team** (Who's working,
  Work queue), **Check work** (Review) and **Learn** (Library: the vault playbook, `docs/rulebooks/`,
  `docs/research/` and `kits/`, searchable, with NEW tags). Plus Ask the Lead and Pause all.
- **Kits** (`kits/`): playtested building blocks to reuse (themed skills + VFX, 3D tilt menu).
- **Vault** (`vault/`): the studio's design rules, chapters 00–13. Open the
  folder in Obsidian if you like; it's plain Markdown.
- **Template** (`template/`): Rojo + strict Luau game skeleton with tests.
  Every game in `games/` starts as a copy of it.
- **CI**: format, lint, strict types, Lune tests and a Rojo build for the
  template and every game, plus a control-room smoke test.

## One-time setup (Windows or macOS)
1. Install Roblox Studio, Node 18+, and Claude Code (`npm i -g @anthropic-ai/claude-code`, then `claude` to log in).
2. Install Rokit: https://github.com/rojo-rbx/rokit, then in this folder run `rokit install`.
3. `rojo plugin install` to add the Rojo plugin to Studio.
4. Download Roblox types for the type checker:
   `curl -sSfLo globalTypes.d.luau https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau`
5. Turn on Studio's MCP server: Assistant → … → Manage MCP Servers → "Enable Studio as MCP server",
   then Quick connect → Claude Code. The agents expect the server to be named `Roblox_Studio`;
   if Quick connect names it differently, copy `.mcp.json.example` to `.mcp.json` instead
   (Windows command: `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`).

## Daily use
```
node scripts/omega.mjs room                  # control room at http://localhost:4321
node scripts/omega.mjs lead                  # one Lead cycle
node scripts/omega.mjs lead --cycles 20      # keep going (e.g. overnight), 2 min apart
node scripts/omega.mjs pause                 # or the Pause all button
```
For a game in progress, keep Studio open on its place with `rojo serve` running
in `games/<slug>/` so Playtest can test it.

`.claude/settings.json` pre-approves the safe commands the agents need
(omega, rojo, selene, stylua, luau-lsp, lune, git status/diff/add/commit, the
Studio MCP), so cycles can run without you clicking "allow". Review it before
running overnight. Pushing to GitHub and publishing to Roblox stay manual.

## Publishing
Run the **Publish** workflow by hand with the game folder name. Put
`universeId` and `placeId` in `games/<slug>/game.json` and the repo secret
`ROBLOX_API_KEY` (scope `universe-places:write`). Publish `Saved` first.

## Honest limits
- Agents can't make painted art; Splash captures real gameplay and writes
  prompts for your image tool.
- Studio's device emulator and Roblox uploads need your Studio session.
- "Builds games while you sleep" depends on Studio staying open and the MCP
  connected; check the Review and Home tabs in the morning, not just the log.

See `docs/RESEARCH.md` (sources), `docs/VIDEO_ANALYSIS.md` (the TikTok setup
this matches) and `docs/QUALITY_CHECKLIST.md` (shipping gate).
