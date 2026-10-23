# OmegaDev research: building high-quality Roblox games with AI agents

Researched 2026-10-23. **[V]** = verified on the linked primary source during this research.
**[I]** = inferred or only seen second-hand. Nothing here is from memory alone.

## TL;DR: why the last game felt mediocre, and what changes

The strongest AI-built Roblox games found in this research don't come from a smarter prompt.
They come from a loop:

**spec → code in files → automatic checks → playtest in Studio with screenshots → review against a checklist → fix**

Andy Garcia's write-up of an agent-built mining tycoon reports these results [V] ([Medium](https://medium.com/@andy.a.g/i-built-a-roblox-game-using-only-ai-agents-heres-what-happened-ed57b553facc)):
- Server logic came out nearly right on the first pass.
- Visuals and UI failed often, and only got fixed through a screenshot-debugging loop.

So OmegaDev adds the parts a one-shot build skips:
- pinned tools
- strict types
- lint and tests in CI
- Studio playtesting through MCP
- separate reviewer agents
- a quality checklist built from Roblox's own design docs

## 1. What the "AI builds many games" creators actually show

**I could not verify any creator who builds "multiple Roblox games at high accuracy".** What I could find:

| Claim | Status |
|---|---|
| RoBuilder, "I Made 4 Roblox Games in 12 Hours with This AI.." (YouTube, Oct 18, 2026) | The video exists [V], [link](https://www.youtube.com/watch?v=CqURW0YPo4A). The description doesn't name the AI or claim results. Quality is unverified [I] |
| Tizzy RBLX, "This AI-Made Roblox Game is PRINTING Money" (~40k Robux/day) | The transcript was seen [V], [link](https://sozai.app/transcript/ai-made-roblox-game-printing-money/). The revenue comes from a third-party estimator, and "AI-made" is the creator's guess from the UI. **Unverified** |
| TikTok @andythropic: one game took "a ton of testing, debugging, reprompting" | Caption seen in search results only. TikTok blocks fetching [I] |
| Takuma (note.com, Apr 2026): sixth game with Claude Code + Studio MCP, reusable library for "mass production" | Post seen [V], [link](https://note.com/takfuj/n/nb0b6fadecbe8?hl=en). He calls mass production himself "unverified" and makes no revenue claim |
| "Claudeblox": AI with 21 agents that builds Roblox games autonomously | Repo exists [V], [link](https://github.com/Claudeblox). 13 stars, no evidence, linked to a memecoin. **Treat as hype** |
| The TikTok Sharman sent (tiktok.com/t/ZTffbqKBd) | **Could not open.** TikTok blocks automated access, so nothing about it is known yet |

What the honest public accounts have in common: a human picks the design, and the agent iterates many times with testing in between. Nobody showed one-shot "high accuracy".

## 2. Official Roblox AI tooling (current)

- **Studio has a built-in MCP server.** Enable it in Assistant → … → Manage MCP Servers → "Enable Studio as MCP server". It offers Quick connect for Claude Code, Claude Desktop, Cursor, Codex CLI, Gemini CLI, VS Code and Antigravity [V] ([docs](https://create.roblox.com/docs/en-us/studio/mcp)).
  - Manual command on macOS: `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`.
  - Manual command on Windows: `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`.
- **26 tools** [V] (same page):
  - Scripts: `script_read`, `multi_edit`, `script_search`, `script_grep`
  - Generation: `generate_mesh`, `generate_material`, `generate_procedural_model`, `wait_job_finished`
  - Assets: `search_asset`, `insert_asset`, `upload_image`, `store_image`
  - Exploring the game: `subagent` (explore/playtest), `search_game_tree`, `inspect_instance`
  - Running code: `execute_luau`
  - Playtesting: `get_studio_state`, `start_stop_play`, `get_console_output`, `screen_capture`
  - Input: `character_navigation`, `user_keyboard_input`, `user_mouse_input`
  - Other: `http_get`, `skill`, `list_roblox_studios`
  - Tool names change with Studio versions, so re-check the page.
- The old standalone server `Roblox/studio-rust-mcp-server` was **archived Apr 3, 2026** in favour of the built-in one [V] ([repo](https://github.com/Roblox/studio-rust-mcp-server)).
- "Roblox Studio going agentic" (Apr 15, 2026) announced [V] ([newsroom](https://about.roblox.com/newsroom/2026/04/roblox-studio-going-agentic)):
  - Planning Mode
  - Mesh Generation
  - Procedural Models ("soon")
  - a Playtesting Agent (beta)
  - parallel and cloud agents are described as "working on"
- Assistant can bring your own model key (Anthropic, OpenAI, Gemini) [V] ([DevForum](https://devforum.roblox.com/t/studio-mcp-server-updates-and-external-llm-support-for-assistant/4415631)).
- Assistant Skills are Markdown files with `name`, `description` and `enabled` frontmatter [V] ([docs](https://create.roblox.com/docs/en-us/assistant/skills)).
- Script Sync is Studio's built-in two-way file sync. Roblox's docs suggest Rojo when the filesystem should be the source of truth [V] ([docs](https://create.roblox.com/docs/en-us/scripting/sync.md)).
- Community MCP servers:
  - `boshyxd/robloxstudio-mcp` was archived Jun 2026; its owner points to the fork `Chrrxs/robloxstudio-mcp` (v2.23.1, has screenshot and multiplayer playtest tools) [V] ([repo](https://github.com/Chrrxs/robloxstudio-mcp)).
  - There is no official AGENTS.md/CLAUDE.md convention from Roblox. That practice comes only from community repos [V absence].

## 3. Toolchain (versions checked on GitHub releases, 2026-10-23)

| Tool | Version | Role | Source |
|---|---|---|---|
| Rojo | 7.7.1 | Files ↔ Studio sync, `build`, `sourcemap` | [V] [repo](https://github.com/rojo-rbx/rojo), [project format](https://rojo.space/docs/v7/project-format/) |
| Rokit | 1.2.0 | Pins tool versions via `rokit.toml`. Aftman is archived; Rokit is the successor | [V] [repo](https://github.com/rojo-rbx/rokit) |
| luau-lsp | 1.70.1 | `luau-lsp analyze` type-checks in CI. Since 1.56, definitions are named: `--definitions=@roblox=globalTypes.d.luau` | [V] [repo](https://github.com/JohnnyMorganz/luau-lsp) |
| selene | 0.32.0 | Linter, `std = "roblox"` | [V] [repo](https://github.com/Kampfkarren/selene) |
| StyLua | 2.6.0 | Formatter, `syntax = "Luau"` | [V] [repo](https://github.com/JohnnyMorganz/StyLua) |
| Lune | 0.11.1 | Standalone Luau runtime, used for fast unit tests of pure modules | [V] [repo](https://github.com/lune-org/lune) |
| Wally / pesde | 0.3.2 / 0.7.4 | Package managers. Wally hasn't released since 2023; pesde is active | [V] [wally](https://github.com/UpliftGames/wally), [pesde](https://github.com/pesde-pkg/pesde) |
| Jest-Lua | 3.10.0 | Jest for Luau. **Runs only inside Roblox**, not under Lune | [V] [repo](https://github.com/jsdotlua/jest-lua) |
| TestEZ | archived 2024 | Don't start new projects on it | [V] [repo](https://github.com/Roblox/testez) |

**Open Cloud** [V]:
- **Luau Execution** runs a script against a place version in the cloud. It has full engine API and DataStore access, a 5-minute timeout, and a limit of 5 tasks per minute. Endpoint: `POST /cloud/v2/universes/{u}/places/{p}/luau-execution-session-tasks`, scope `universe.place.luau-execution-session:write` ([docs](https://create.roblox.com/docs/cloud/reference/features/luau-execution.md)).
  - This is the Studio-free way to run in-engine tests in CI [I: the workflow is my synthesis].
- **Place publishing**: `POST https://apis.roblox.com/universes/v1/{u}/places/{p}/versions?versionType=Saved|Published` with an `x-api-key` header and scope `universe-places:write` ([guide](https://create.roblox.com/docs/en-us/cloud/guides/usage-place-publishing.md)).

**GitHub Actions** [V]: `CompeyDev/setup-rokit@v0.2.1` and `JohnnyMorganz/stylua-action@v5`. There is no official selene action, so install selene through Rokit.

## 4. What makes a Roblox game feel high quality (Roblox's own guidance)

**Game feel** [V]:
- Every action needs feedback. Buttons need hover, pressed and released states. Without feedback, players "may not know whether an action worked or whether a feature is bugged" ([UI/UX](https://create.roblox.com/docs/en-us/production/game-design/ui-ux-design)).
- "Juice" means tweens, squash and stretch, sound, shake and particles: "maximum output for minimum input" ([GDC 2013 talk](https://www.gamedeveloper.com/design/video-is-your-game-juicy-enough-)).
- Respect `GuiService.ReducedMotionEnabled` ([accessibility](https://create.roblox.com/docs/en-us/production/publishing/accessibility)).
- Server Authority mode (full release Jul 9, 2026) gives client prediction with rollback. It's opt-in and has limits ([DevForum](https://devforum.roblox.com/t/full-release-ship-fair-and-competitive-games-with-server-authority/4727993)).

**Mobile first** [V]:
- "The majority of Roblox users play on a mobile device" ([docs](https://create.roblox.com/docs/en-us/production/game-design/design-for-roblox)). A figure of 80% for 2024 appears only via PocketGamer.biz [I: second-hand] ([article](https://www.pocketgamer.biz/80-of-roblox-users-are-on-mobile-contributing-46-of-robux-revenue/)).
- Use `ScreenInsets.CoreUISafeInsets` and `UIAspectRatioConstraint`, keep text size at 9 or more, and keep clear of thumb zones ([cross-platform](https://create.roblox.com/docs/ui/cross-platform-design)).

**First five minutes** [V]:
- Get players to the fun in 5 minutes or less ([retention](https://create.roblox.com/docs/en-us/production/analytics/retention)).
- Teach what to do and why, keep early thresholds low, show short, mid and long-term goals, and end on a "moment of joy" ([onboarding](https://create.roblox.com/docs/en-us/production/game-design/onboarding)).
- Long tutorials hurt.
- Roblox publishes **no** official D1/D7 target numbers.

**Discovery** [V]: the official signals for Recommended are listed on the [discovery page](https://create.roblox.com/docs/discovery.md):
- play-through rate
- first-play bounce under 60s and 61–180s (negative)
- play days per user
- playtime, capped at 60 min per day
- co-play with friends
- qualified sessions
- spend days and Robux per user

A custom thumbnail is required for homepage impressions.

**Core loop** [V]: Roblox defines it as minute-to-minute action, plus the most-repeated set of actions, plus a progression engine. Without the engine the game is "repetitive and shallow" ([core loops](https://create.roblox.com/docs/en-us/production/game-design/core-loops)).

**Monetization** [V]:
- Passes are one-time; Developer Products are repeatable ([monetize](https://create.roblox.com/docs/monetize-experiences)).
- **Premium Payouts are gone.** They were deprecated Jul 24, 2025 and replaced by Creator Rewards ([creator rewards](https://create.roblox.com/docs/creator-rewards)).
- Rewarded video ads exist. At launch they required 100K+ DAU ([DevForum](https://devforum.roblox.com/t/more-creators-can-now-use-rewarded-video-ads/3838678)); the current threshold is unverified.
- Paid random items must show numeric odds before purchase and respect `ArePaidRandomItemsRestricted` ([policy](https://create.roblox.com/docs/production/monetization/paid-random-items)).
- `ProcessReceipt` must be idempotent ([guide](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing)).

**Technical** [V]:
- Assume every client payload has been manipulated. Check NaN and inf, types, sizes and `IsDescendantOf`, and rate-limit with a token bucket ([boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary)).
- Session-lock player data. ProfileStore by loleris is the maintained library ([DevForum](https://devforum.roblox.com/t/profilestore/3190543)).
- Profile with MicroProfiler on mobile: 16.67 ms per frame for 60 FPS, 33.33 ms for 30 FPS ([docs](https://create.roblox.com/docs/performance-optimization/microprofiler)).

## 5. Community agent setups worth knowing [V that they exist, not that they work]
- **roxlit.dev guide**: Claude Code + `rojo serve` + a CLAUDE.md ([link](https://roxlit.dev/blog/how-to-use-claude-code-with-roblox)).
- **`rodrigo-guerraa/roblox-hub`**: Rojo template, CLAUDE.md, and the rule that a change is done only after a fresh Studio MCP playtest ([repo](https://github.com/rodrigo-guerraa/roblox-hub)).
- **`m4bwav/roblox-agent`**: skills for MCP, Rojo, offline checks (selene, StyLua, luau-lsp, Lune) and Open Cloud. The author says it has not been run against live Studio ([repo](https://github.com/m4bwav/roblox-agent)).

## Could not verify
- The TikTok video Sharman sent, and any creator's "high accuracy, multiple games" claim.
- Any independently confirmed revenue for AI-built Roblox games. All figures found came from third-party estimators.
- Whether Procedural Models and the Playtesting Agent are generally available yet.
- The current eligibility for rewarded video ads.
- Official D1/D7 benchmarks: none are published.
