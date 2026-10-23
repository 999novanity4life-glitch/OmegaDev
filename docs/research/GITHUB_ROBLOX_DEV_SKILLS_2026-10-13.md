# GitHub Roblox developer knowledge: what's out there and what to learn (2026-10-13)

For *Steal a Dream*, which Claude Code builds through Roblox's built-in Studio MCP and Blender MCP.
Method: about 50 searches and page reads on github.com, raw.githubusercontent.com, Roblox's official creator-docs repo (github.com/Roblox/creator-docs), and two official doc sites. Nothing was installed, cloned or run.
Star counts are what the GitHub pages showed on 2026-10-13. Most pages did not show a last-commit date; where the date is unknown the table says "date not shown".
The companion rulebook is `../reference_dev/ROBLOX_ENGINEERING_RULES.md`.

---

## 1. AI-assistant packs for Roblox (skills, rules, MCP servers)

| Name | URL | What it is | Stars / status | License | Worth using? |
|---|---|---|---|---|---|
| **Roblox built-in Studio MCP** (what we use) | create.roblox.com/docs/studio/mcp | The official MCP server built into Studio. Tools include `script_read`, `multi_edit`, `script_grep`, `execute_luau` (Edit/Client/Server), `start_stop_play`, `get_console_output`, `screen_capture`, `character_navigation`, `user_keyboard_input`, `user_mouse_input`, `generate_mesh`, `generate_material`, `generate_procedural_model` + `wait_job_finished`, `search_asset`/`insert_asset`, `subagent` (explore/playtest), `http_get` (Roblox docs only), and `skill` (built-in best-practice notes) | Official, current | Roblox ToS | **Yes, it's what we use.** Two tools we under-use: `skill` (Roblox's own best-practice notes) and `http_get`, which fetches the official API reference so we don't have to guess an API |
| Roblox/studio-rust-mcp-server | github.com/Roblox/studio-rust-mcp-server | The original official MCP server: `run_code`, `insert_model`, `get_console_output`, `start_stop_play`, `run_script_in_play_mode`, `get_studio_mode` | 496 stars, **archived 2026-04-03**; it points users to the built-in server | MIT | No. Superseded by the built-in server |
| boshyxd/robloxstudio-mcp | github.com/boshyxd/robloxstudio-mcp | A community server with 43 tools plus a 31-tool read-only "Inspector" edition. Needs a plugin and HTTP requests turned on | 493 stars, **archived 2026-06-06**; points to the Chrrxs fork | MIT | No. Archived |
| Chrrxs/robloxstudio-mcp | github.com/Chrrxs/robloxstudio-mcp | The maintained fork of boshyxd. Adds `multiplayer_playtest` (several clients), `eval_server_runtime`/`eval_client_runtime` during play, non-pausing breakpoints, per-peer logs, script and micro profiler captures, and a memory breakdown | 300 stars, date not shown | MIT | **Maybe later.** Multi-client playtests would test steal/tag with two players, which the built-in server may not do. Don't install it without Sharman's OK |
| Meganugger/roblox-studio-mcp | (glama.ai listing) | A security-focused server with a bearer token, localhost-only binding, and a `get_roblox_docs` tool | Not checked on GitHub, **UNVERIFIED** | ? | No. The built-in `http_get` covers the docs lookup |
| **TabooHarmony/roblox-brain** | github.com/TabooHarmony/roblox-brain | 29 agent skills (Claude Code, Codex, Cursor) in four groups: core (luau-core/types/patterns, architecture, networking, security, data, server-data, performance), gameplay (building, physics, npc-ai, camera, input, gui, animation-vfx, lighting, audio, localization), design (game-design, player-psychology, growth, analytics, monetization), and tools (studio-mcp, tooling, cloud, publish-checklist). Each skill has a SKILL.md plus references/full.md | 89 stars, 136 commits, date not shown | MIT | **Best of the lot.** Its data, networking and studio-mcp skills are precise and up to date (ProfileStore, `player.User`, UnreliableRemoteEvent's 1000-byte cap, the built-in MCP tool names). Read it; don't install it |
| brockmartin/roblox-game-skill | github.com/brockmartin/roblox-game-skill | A big Claude Code skill: a 121-line router, 16 references, 7 genre templates (one is a **simulator with pet hatching**), and 7 workflows (security audit, publish checklist and others) | 223 stars, 3 commits | **No LICENSE file seen**, so don't copy code from it | **Read it critically.** The sharp-edges list is useful. The simulator template has real bugs: its odds are weighted per pet rather than per rarity, so the odds it shows are wrong; it has no pity counter, no offline earnings, and no proximity check on hatch. Its data example calls `ProfileStore:LoadProfileAsync`, which is ProfileService's old API under ProfileStore's name |
| stackfox-labs (now luumenlabs)/luau-skills | github.com/stackfox-labs/luau-skills | 9 skills: luau-core, luau-types, luau-performance, roblox-core, roblox-networking, roblox-api, roblox-data, roblox-cloud, roblox-oauth | 12 stars, 8 commits | MIT | Low priority. It's young and doesn't say where its content comes from |
| dig1t/skills | github.com/dig1t/skills | luau-type-expert, luau-best-practices, rojo-pro, luau-roblox-optimizer (a review checklist for leaks, remotes, polling and DataStores) | 5 stars | not shown | Low priority |
| greedychipmunk/agent-skills | github.com/greedychipmunk/agent-skills | A general skill pack that includes `roblox-game-developer` | 21 stars | MIT | No. Too generic |
| christopher-buss/skills | github.com/christopher-buss/skills | roblox-ts, ECS design, and jecs skills | 8 stars | MIT | No. We write Luau, not roblox-ts |
| Smokestack-Games/rbxsync rules | (tomevault / neura listings) | Cursor rules for the RbxSync tool. Notes strict types and `task.wait()` | Not opened on GitHub, **UNVERIFIED** | ? | No |
| elevenpassin/awesome-roblox | github.com/elevenpassin/awesome-roblox | A curated list of frameworks, tools, plugins and learning links | 197 stars, 25 commits | ? | **Mostly outdated:** Aero, Roact, Rodux, old catalog links, robloxdev.com. Useful only for history |
| JodeRBX/awesome-roblox | github.com/JodeRBX/awesome-roblox | Another awesome list | not opened | ? | Skip |

**Lessons for area 1**
- With the built-in MCP: discover, inspect, edit in small batches, **read back**, play, check live, collect evidence (console + screenshot), clean up (roblox-brain studio-mcp skill). `execute_luau` is stateless, so look up instances again on every call. An Edit-context script can't reach a running playtest.
- Big scripts: split them into bounded `multi_edit` writes, then read the whole script back.
- Call `wait_job_finished` before using anything made by `generate_*`.
- Don't trust skill packs blindly. The most-starred genre template (brockmartin) has wrong odds math and mixes up two library APIs. Check every claim against the official docs (`http_get`) before using it.

---

## 2. Core Roblox engineering practice

| Name | URL | What | Stars / status | License | Use in 2026? |
|---|---|---|---|---|---|
| **ProfileStore** (loleris / MadStudio) | github.com/MadStudioRoblox/ProfileStore, docs madstudioroblox.github.io/ProfileStore | Player-data saving with **session locking**, auto-save, `Reconcile`, `MessageAsync` (safe gifting), `ProfileStore.Mock` for Studio | 344 stars | Apache-2.0 | **YES. This is the standard.** It replaces ProfileService. Not meant for leaderboards or global state |
| ProfileService | github.com/MadStudioRoblox/ProfileService | The older library from the same author (`LoadProfileAsync`, `:Release()`) | old | Apache-2.0 | **Outdated** for new games. Code that uses `LoadProfileAsync` or `Release` comes from old tutorials |
| Lapis | github.com/nezuo/lapis | A DataStore wrapper with session locks, migrations, validation, retries, throttling, and a 5-minute auto-save | 82 stars | MIT | An alternative, but its own README says it **hasn't been tested in a large production game** |
| DataStore2 | (not fetched) | Old wrapper | — | — | **Don't use.** Roblox's official best-practices page says not to use DataStore2 for new experiences |
| Knit | github.com/Sleitnick/Knit | Services/controllers framework | 629 stars, **archived 2024-07-31** | MIT | **No.** Its author says to use plain ModuleScripts plus a thin RemoteEvent wrapper with runtime `assert` checks instead, because Knit can't use Luau types well |
| RbxUtil (Sleitnick) | github.com/Sleitnick/RbxUtil | Trove 1.8.0, Signal 2.0.3, Comm, TypedRemote, Timer, TableUtil, Net, Ser and others | 467 stars, active | MIT | **Yes, pick modules à la carte.** Trove for cleanup, Signal for events |
| Janitor | github.com/howmanysmall/Janitor | Cleanup object: `Add` returns the item, custom cleanup method, custom keys, links to an Instance | 150 stars | MIT | Fine, but pick **one** of Trove or Janitor. Maid is the older, slower pattern |
| GoodSignal | github.com/stravant/goodsignal | Pure-Luau signal with the same API as RBXScriptSignal; gets garbage-collected even if you never disconnect | 73 stars | MIT | OK, or use RbxUtil Signal |
| Rojo | github.com/rojo-rbx/rojo | Syncs scripts from the filesystem and Git into Studio | 1.8k stars | MPL-2.0 | Standard for file-based teams. **We edit through MCP inside Studio, so Studio is our source of truth.** Rojo would only matter if we move to Git-managed code |
| Rokit | github.com/rojo-rbx/rokit | Toolchain manager (pins Rojo, Selene, StyLua). Reads `aftman.toml` and `foreman.toml` | 477 stars | MIT | **Current.** Aftman is archived and Rokit replaces it |
| Wally | github.com/UpliftGames/wally | Package manager (Cargo/npm style) | 500 stars, active | MPL-2.0 | Only with Rojo. pesde is a newer alternative (not checked, **UNVERIFIED**) |
| Zap | github.com/red-blox/zap | IDL → generated buffer-packed networking; it says it "validates all data received" | 190 stars, 0.6.x (rewrite under way) | MIT | Overkill for v1 |
| Blink | github.com/1Axen/blink | IDL compiler, buffer networking, validates what clients send | 192 stars | MIT | Overkill for v1 |
| ByteNet | github.com/ffrostfall/ByteNet | Simple buffer-based networking | 183 stars | MIT | Overkill for v1 |
| TestEZ | github.com/Roblox/testez | Old test framework | **archived 2024-09-14** | Apache-2.0 | **Outdated** |
| Jest-Lua | github.com/jsdotlua/jest-lua | Lua port of Jest 27, used inside Roblox, installed with Wally; runs only inside Roblox | 57 stars | MIT | Current choice if we add a test suite. For now we test with `execute_luau` and playtests |
| Roblox Lua style guide | roblox.github.io/lua-style-guide | Naming, file layout, formatting | official | — | **Yes** for naming and file layout |
| Roblox creator-docs | github.com/Roblox/creator-docs | The official docs as Markdown (DataStore best practices, security tactics, remote events, type checking, performance, paid random items) | official | CC-BY-4.0 (UNVERIFIED) | **The ground truth.** Everything in the rulebook was checked against it |

**Key lessons for area 2**

*Structure and style*
- Plain ModuleScripts with one owner each, a narrow API, no circular requires, and **no yields in a module body** (use `Init` then `Start` from one bootstrap script). Knit is dead.
- File order: services, requires, constants (`LOUD_SNAKE`), variables and functions, `return`. `PascalCase` for classes and Roblox APIs, `camelCase` for locals and functions. Use `if-then-else` expressions instead of `x and y or z`. Indent with tabs.
- Put `--!strict` at the top of a script to turn on full checking (`--!nonstrict` checks only annotated values). Share types from a Types module with `export type`. Use `::` to cast.
- Legacy `wait`/`spawn`/`delay` are replaced by `task.wait`/`task.spawn`/`task.delay`/`task.defer`/`task.cancel`.
- Always give `WaitForChild` a timeout and handle a `nil` result.

*Data (the area most likely to lose players' items)*
- Use one DataStore (`PlayerData`) with one key per player (`Player_<UserId>`, no hashing; this keeps automated right-to-be-forgotten erasure working). Each key holds at most 4 MB.
- **Session locking is mandatory** for a game where items move between players (we steal). ProfileStore does it for you.
- If `StartSessionAsync` returns nil, the load failed. Never treat it as a new player. Kick and ask them to rejoin.
- A custom `Cancel` function turns off ProfileStore's built-in timeout.
- Call `Reconcile()` after load. Add a `Version` field and migrate first, then reconcile.
- `UpdateAsync` for read-modify-write, `SetAsync` only for brand-new keys. Retry transient failures with capped exponential backoff plus jitter. Don't retry invalid requests.
- Validate before saving: no NaN or infinity, `utf8.len` on strings, no Instances or functions. One bad value fails the whole write.
- Use `ProfileStore.Mock` (or an environment-scoped store name) in Studio so tests never touch live data.
- `BindToClose`: save **in parallel** (`task.spawn` for each player). Saving one after another can run past the 30-second shutdown limit.
- `Profile:IsActive()` only holds until the next yield, so write critical data straight after checking.
- Never use `Steal`; it's for debugging only and breaks the lock.
- Developer products: grant only in `ProcessReceipt`. Keep a `PurchaseId` cache in the profile (capped at about 100) so a purchase is never granted twice. Return `PurchaseGranted` only after the save is confirmed; otherwise return `NotProcessedYet` (Roblox retries when the player rejoins). `PromptProductPurchaseFinished` is **not** proof of purchase.

*Networking and anti-exploit*
- The server is the source of truth: client sends a request, server validates, server acts, server replicates. Prices and rewards come from server tables, never from what the client sends.
- An exploiter can fire any remote at any rate with any arguments. Only the first `player` argument can be trusted.
- Validate type, then NaN/infinity (`x ~= x`, `math.abs(x) == math.huge`), then range, ownership, game state, **distance**, and cooldown. Touched events, ProximityPrompts and ClickDetectors can be faked too, so check distance on the server.
- Rate-limit every remote for each player, and still validate. Log suspicious patterns; don't punish one bad packet.
- Remote payload rules: functions arrive as nil, metatables are dropped, don't mix array and dictionary keys, tables arrive as copies, and server-only Instances arrive as nil.
- Avoid `InvokeClient`; a client can make the server wait forever.
- UnreliableRemoteEvent: only for data it's fine to lose (VFX). The payload limit is about 1000 bytes, and order isn't guaranteed.
- Keep logic in ServerScriptService. Anything in ReplicatedStorage or Workspace can be decompiled.
- Exploiters own their character's physics. Never trust client positions for important decisions.

*Cleanup and performance*
- Whoever creates a connection, instance or task owns its cleanup. Use a Trove per player and per object, call `trove:Clean()` on PlayerRemoving, and remove per-player table entries.
- Don't do heavy work in Heartbeat or RenderStepped. Clients make VFX and tweens locally. Pool objects that respawn often. Anchor static parts. Use Box/Hull collision fidelity. Turn on StreamingEnabled. Send only changed data over remotes.

---

## 3. Genre-specific (steal / collect / simulator)

| Name | URL | What | License | Worth using? |
|---|---|---|---|---|
| brockmartin genre-simulator template | github.com/brockmartin/roblox-game-skill/blob/main/templates/genre-simulator.md | PetService with hatch validation (type check, 1 s cooldown, egg exists, storage not full, zone unlocked, coins), weighted pool, luck multiplier | **none seen** | Learn from it, don't copy. Its hatch validation order is a good checklist. Its odds math is the bug to avoid |
| Blockzez/RobloxFormatNumber | github.com/Blockzez/RobloxFormatNumber | Full number formatter. Compact suffixes via `Notation.compactWithSuffixThousands({...})`; handles infinity and negatives | BSD-2-Clause | Optional. A 15-line formatter of our own is enough (see the rulebook) |
| EternityNum / InfiniteMath / BigNumber / AlephNum | DevForum posts (GitHub repos not found) | Numbers above 1e308 for idle games | ? | **Not needed.** Our top numbers (1.5M Mythic, 15k/s × x20 × rebirth) stay far below 2^53 ≈ 9e15, the limit for exact integers in Luau doubles |
| "Simple RNG" module / alias-method thread | DevForum | Weighted pickers | ? | Not needed; our picker is about 10 lines |
| Hiro gacha docs (Heroic Labs) | heroiclabs.com/docs/hiro/guides/gameplay-mechanics/gacha | Design reference: a **pity threshold** per rarity track, with a separate counter for each track | — | Matches our lucky meter design |

**No open-source GitHub repo with a hard-pity Luau egg system was found.** Search results were DevForum threads, paid templates and itch.io kits. Write it ourselves (see the rulebook).

**Key lessons for area 3**
- **Roll the rarity first, then pick the Dreamling inside that rarity.** If you put weights on individual creatures, a rarity with more creatures gets more chance, and the odds you show on the sign become false. That's the brockmartin bug: the template said 1% Legendary and actually gave 0.625%.
- Do every roll on the server with `Random.new()`, which seeds itself from an entropy source. Decide the result first; the wheel animation only shows it (that's the "honest wheel" in our design).
- Pity: keep a counter per egg and per track in the profile, add one on each miss, reset it on a hit, and force the result at the threshold.
- Paid random items policy (official creator-docs page): luck boosts and **pity systems count as "probability modifiers."** If an egg, or the currency spent on it, is bought **directly or indirectly with Robux**, you must show all odds as percentages that add to 100% before purchase. While a boost is active, show the boosted odds. Check `PolicyService:GetPolicyInfoForPlayerAsync().ArePaidRandomItemsRestricted`. Allowed handling for restricted players: a free earnable path, a fixed order, direct sale at expected value, hiding, or blocking. Gameplay-earned random rewards need no disclosure.
  - **UNVERIFIED:** whether Dust earned under a **Robux-bought x2 multiplier** counts as "indirectly bought with Robux." Safest choice: always show egg odds anyway (the design already does), and apply the policy check to the Lucky Boost and Server Luck products.
- Offline earnings: no source library was found. Compute it on the server from a saved `LastSeen` (`os.time()`), clamp it between 0 and the cap (2 h, or 8 h with Long Sleep), then multiply by income. This follows the server-authority rule; it is not a library pattern.
- Stealing moves an item between two profiles. Both players are on the same server, both profiles are session-locked there, so the move is one server function with **no yield between removing the item and adding it** (the `IsActive` caveat). That gives no duplication and no loss. Trades should be atomic and validated on both sides (roblox-brain security skill).

---

## 4. What changed recently (current in 2026 vs outdated)

| Current | Outdated |
|---|---|
| Built-in Studio MCP | studio-rust-mcp-server (archived Apr 2026), boshyxd MCP (archived Jun 2026) |
| ProfileStore (`StartSessionAsync`, `EndSession`) | ProfileService (`LoadProfileAsync`, `Release`), DataStore2 |
| Plain modules + thin remote wrapper | Knit (archived 2024), Aero |
| Rokit | Aftman (archived), Foreman (still Roblox-maintained) |
| Jest-Lua | TestEZ (archived 2024) |
| `task.*` library | `wait()`, `spawn()`, `delay()` |
| `player.User` / `User.Id` for new identity code (roblox-brain; **UNVERIFIED** against the official docs) | — `UserId` still works; just don't mix the two in one key scheme |
| Server Authority mode (client prediction + rollback) for physics games | — Not needed for us; noted only |

---

## Sources (all fetched 2026-10-13)
- https://create.roblox.com/docs/en-us/studio/mcp.md
- https://github.com/Roblox/studio-rust-mcp-server
- https://github.com/boshyxd/robloxstudio-mcp
- https://github.com/Chrrxs/robloxstudio-mcp
- https://github.com/TabooHarmony/roblox-brain (skills core/roblox-data, core/roblox-data/references/full.md, core/roblox-networking, core/roblox-security, core/roblox-luau-patterns, tools/roblox-studio-mcp, tools/roblox-tooling, design/roblox-monetization, design/roblox-player-psychology)
- https://github.com/brockmartin/roblox-game-skill (templates/genre-simulator.md, references/sharp-edges.md)
- https://github.com/stackfox-labs/luau-skills
- https://github.com/christopher-buss/skills
- https://github.com/dig1t/skills
- https://github.com/greedychipmunk/agent-skills
- https://github.com/elevenpassin/awesome-roblox
- https://github.com/MadStudioRoblox/ProfileStore and https://madstudioroblox.github.io/ProfileStore/ (tutorial/, api/, devproducts/)
- https://github.com/nezuo/lapis
- https://github.com/Sleitnick/Knit and ARCHIVAL.md
- https://github.com/Sleitnick/RbxUtil and modules/trove/init.luau
- https://github.com/howmanysmall/Janitor
- https://github.com/stravant/goodsignal
- https://github.com/rojo-rbx/rojo
- https://github.com/rojo-rbx/rokit
- https://github.com/UpliftGames/wally
- https://github.com/red-blox/zap
- https://github.com/1Axen/blink
- https://github.com/ffrostfall/ByteNet
- https://github.com/Roblox/testez
- https://github.com/jsdotlua/jest-lua
- https://roblox.github.io/lua-style-guide/
- https://github.com/Roblox/creator-docs: cloud-services/data-stores/best-practices.md, scripting/security/security-tactics.md, scripting/events/remote.md, luau/type-checking.md, performance-optimization/improve.md, production/monetization/paid-random-items.md, reference/engine/datatypes/Random.yaml
- https://github.com/Blockzez/RobloxFormatNumber
- DevForum (search summaries only): BigNumber/AlephNum/EternityNum posts, Weighted Chance System, Simple RNG module
- https://heroiclabs.com/docs/hiro/guides/gameplay-mechanics/gacha/ (pity design reference)
