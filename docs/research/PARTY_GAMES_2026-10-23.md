# Kid party games on Roblox: catalog (2026-10-23)

Live stats pulled 2026-10-23 (~07:45 UTC) from Roblox's public APIs (`games.roblox.com/v1/games`, `/votes`), with peaks from rotrends.com and rowatcher.com. Every row cites its source; anything marked **inferred** is studio judgment, not a measurement. Notes gathered by the Pulse research pass for OmegaDev.

## The answer in one table (top live game per family)
| Family | Top game now | Playing | Like % | Peak (tracker) | What it teaches |
|---|---|---|---|---|---|
| TNT tag / hot potato | Timebomb Duels | 10,638 | 64.9% | 28K | Touch-to-pass, ~10 s fuse, skill ceiling (ankle-breaks) drives YouTube; zero gamepasses works |
| Rising lava | The Floor Is LAVA! | 1,507 | 76.9% | 35.3K | 75 s cycle (15 prep / 40 lava / 20 intermission); powers are all Robux passes today |
| Rising hazard + collect (hybrid) | Escape Tsunami For Brainrots | 3,703 | 83.1% | 4-5M | The 2026 breakout pairs a rising hazard with collect + rebirth |
| Speed obby | +1 Speed Keyboard Escape | 58,893 | 96.8% | 6.8-7.3M | Zero wait to play, ASMR juice, AFK treadmills |
| Tower race | Tower of Hell | 24,002 | 73.6% | 68-75K | No checkpoints, shared timer that speeds up, 368-section deck |
| Survive the disasters | Natural Disaster Survival | 4,741 | 90.8% | 98.7K | Lobby tower = free spectate; telegraphed disasters |
| Color block / musical | Musical Chairs | 1,596 | 66.4% | 33.2K | One-line rule; pay-to-grief kills likes |
| Hide and seek | Paint Or Seek | 2,528 | 78.5% | 93K | Infection conversion keeps the caught playing |
| Sumo / push-off | Knockout! | 666 | 96.1% | 620.7K | Simultaneous 7 s turns, 11-turn cap, edge auto-rescue |
| Block drop / spleef | Rocket Spleef | 227 | 87.9% | 4K | Active verb (shoot the floor) beats passive falling |
| Red light green light | Squid Game X (anthology) | 12,651 | 93.7% | 154K | 3 hits instead of instant death; lives on only in anthologies |
| Freeze tag | Freeze Tag 🧊 (4 weeks old) | 2,925 | 81.7% | 5K | Genre nearly empty: an opening |
| King of the hill | King Tower! | 191 | 82.2% | 4K | No breakout; mostly a mode inside anthologies |
| Dodgeball | Dodge or Die (Blade Ball adjacent) | 908 | 88.5% | 6K | Players moved to single-ball deflect games |

## Cross-family lessons (inferred unless cited in the sections below)
1. **Cold start kills round games.** Every clone that couldn't keep ~10 players in a server died; plan bots or solo filler and a launch ad burst.
2. **Short rounds, no long spectating.** ~10 s eliminations, ~2 min matches, a final-2 finale; infection or a lobby-with-view so the eliminated still have something to do.
3. **Powers are sold, not earned, in every top lava game.** Crowns that earn cooldown powers is an open, fairer niche.
4. **The 2026 money is in hybrids** (rising hazard + collect/rebirth), but their loot boxes (Spins, Lucky Blocks, Server Luck) are the exact monetization to avoid for kids.
5. **What kills like %:** pay-to-grief (Kill All, Nuke), paid seeker/tagger chance, false-scarcity skins, pay-to-win classes, sold wins.

---

## Tag family: TNT tag, freeze tag, hide and seek, dodgeball

### Method and source key

- **Live stats** were pulled 2026-10-23 at about 07:45 UTC with curl. Each call names its universe IDs.
  - Stats: `https://games.roblox.com/v1/games?universeIds=<id>` (S)
  - Votes: `https://games.roblox.com/v1/games/votes?universeIds=<id>` (V)
  - Like % = up / (up + down).
- **Universe IDs** came from `https://apis.roblox.com/search-api/omni-search?searchQuery=<q>&sessionId=abc&pageType=all` (OS). Queries used: tnt tag, hot potato, freeze tag, freeze, ice tag, tag game, hide and seek, dodgeball, dodgeball classic. The place-to-universe endpoint was not needed, because omni-search returns both IDs.
- **Gamepasses**: `https://apis.roblox.com/game-passes/v1/universes/<id>/game-passes?passView=Full&pageSize=50` (GP). Developer products are not public, so they are not covered here.
- **Peaks**: `https://rowatcher.com/games/<universeId>`, fetched 2026-10-23.
  - RoWatcher's "all-time peak" only covers RoWatcher's own tracking window. Some values are obviously too low, such as ConnorVIII Freeze Tag at 40 and Blade Ball at 60K. Treat these as tracked peaks, not true all-time peaks.
  - `romonitorstats.com/experience/11379739543/` loaded only a title with no stats.
  - `rotrends.com/games/4049246711` returned 404.
- **Tooling problems**: WebSearch and WebFetch hit a session limit partway through. After that I used curl plus DuckDuckGo, YouTube search HTML, the DevForum JSON API and the Fandom API. Some guide pages render their numbers with JavaScript, so those numbers were blank and are not reported here.
- **Labels**: "inferred" marks my own judgment.

---

### 1. TNT Tag / hot potato / bomb tag (deepest section)

#### Stats (seen 2026-10-23, ~07:45 UTC)

| Game | Link | Visits | Like % | Playing | Peak (RoWatcher tracked) | Updated | Source URL | Seen |
|---|---|---|---|---|---|---|---|---|
| Timebomb Duels [Alpha] (Customs Community) | https://www.roblox.com/games/11379739543 | 959,420,801 | 64.9% (234,466/126,983) | 10,638 | 28K (Aug 2026; a search snippet gives 2026-08-16) | 2026-10-22 | S/V universeIds=4049246711; https://rowatcher.com/games/4049246711 | 2026-10-23 |
| Hot Potato 🥔💥 (Potato Experience) | https://www.roblox.com/games/72001091182267 | 55,500,577 | 73.5% (18,952/6,828) | 2,471 | 11K (Oct 2026) | 2026-09-06 | S/V 10403820097; https://rowatcher.com/games/10403820097 | 2026-10-23 |
| TimeBomb AnkleBreak! (Notrox Studios) | https://www.roblox.com/games/100178831086674 | 94,728,779 | 82.4% | 942 | 7K (Mar 2026) | 2026-09-28 | S/V 9758027784; https://rowatcher.com/games/9758027784 | 2026-10-23 |
| Monkey Bomb Tag (Crazay Art) | https://www.roblox.com/games/108843562394237 | 178,790,489 | 86.8% | 542 | 39K (May 2026) | 2026-09-15 | S/V 9564673841; https://rowatcher.com/games/9564673841 | 2026-10-23 |
| 💣 Pass or Explode | https://www.roblox.com/games/134424372433341 | 137,058,458 | 82.1% | 229 | 11K (Jul 2026) | 2026-10-20 | S/V 9661927199; https://rowatcher.com/games/9661927199 | 2026-10-23 |

Smaller bomb games (same sources, same time):
- 💣 Time Bomb (9403708294): 97.3M visits, 73.8% liked, 295 playing, updated 2026-04-11.
- [🎃] Pass the Bomb! (1069466626, from 2019): 217.3M visits, 83.3% liked, 113 playing, tracked peak 1K (Apr 2026).
- Pass or Die 💣 (6611035093): 222.8M visits, 91.6% liked, 75 playing, last updated 2025-07-26. Stale.

Not tag games, but they share the bomb theme:
- 💣 Bomb Chip (9330730057): 301.3M visits, 95.0% liked, 448 playing, tracked peak 85K (Jan 2026). Players "hide bombs in chips", so it is a pick-a-chip luck duel with no tagging.
- untitled tag game (4864117649): 443.8M visits, 90.3% liked, 776 playing. It is a parkour tag sandbox.

Inferred: Timebomb Duels holds about 70% of all live bomb-tag players today. It is the only bomb game whose current count is near its peak; RoWatcher gives it a "peak ratio 0.8123". Every 2026 clone spiked and then fell 90-99% from its peak. Monkey Bomb Tag went from 39K to 542, and Pass or Explode from 11K to 229.

#### Round loop and timings

- **Timebomb Duels**
  - Touch-to-pass is the only interaction. There is no throw or ability button, and every player has the same base speed. (https://bloxodes.com/wiki/timebomb-duels; https://earnaldo.com/blog/timebomb-duels-beginner-guide)
  - Guides disagree on the timer. Most say about **10 s** from when you receive the bomb (summarized via search: https://allthings.how/?p=89896, https://deltiasgaming.com/?p=254037); one says 6 s (https://findingdulcinea.com/timebomb-duels-strategy-guide/). Earnaldo says the timer **does not reset on pass**, and that the last **3 s** is "the game's most dangerous phase."
  - One player is eliminated per round, with no respawn. A 6-8 player game takes "5-7 rounds", and players return to the lobby afterwards. (earnaldo)
  - Modes: Free-for-All, Open Arena, First to Five. First to Five is a round-win series that can run past five. (https://bloxodes.com/wiki/timebomb-duels/game-modes)
  - Servers hold 30 (S: maxPlayers 30). Bloxodes saw public servers at 28-30/30 with 78-132 ms ping.
  - Ranked and skill-based matchmaking are planned for "Beta". Bloxodes lists "Timebomb Duels Beta" and "Global Matchmaking Update" events for Dec 31, 2026. The game wipes stats after each stage, per its own description (S).
- **Pass or Explode** (https://allthings.how/pass-or-explode-how-to-play-and-win-in-roblox/)
  - Each round, a random player gets a bomb with a **10 s** fuse. Rounds last "about 10 to 12 seconds".
  - Eliminated players go back to the lobby. A full 12-player server finishes in "roughly two minutes".
  - Finale: the last 2 players fight with LMB kicks to knock each other into lava.
  - Everyone walks at the same speed and there is no sprint.
- **Hot Potato 🥔💥**: "Make it to the final 2 and duel for the win", with a "Countdown finish = BOOM" (S description, 10403820097). Servers hold 12.
- **TimeBomb AnkleBreak!**: "You have **15 seconds** to pass the bomb" (S description, 9758027784). Servers hold 8.
- **Monkey Bomb Tag**
  - Players vote for a map. Avatars turn into monkeys that can wall-run, sprint and swing on ropes. (https://techwiser.com/roblox-monkey-bomb-tag-wiki/)
  - The bomb passes on proximity with no button. Eliminated players wait for the next round. High ground, vines and wall-jumps decide chases. (https://sportsrant.indiatimes.com/gaming/roblox-monkey-bomb-tag-beginner-guide-how-to-survive-and-win-more-rounds/articleshow/131029193.html; its figures render with JS and were blank)
  - A fan site lists "community-tracked" values: pass range ~2 studs, run speed ~16 studs/s, 8 maps (https://monkeybombtag.com/). These are unverified.
  - The game runs "Admin Abuse" live events (techwiser).
- **Hypixel/Crab Game lineage**: DevForum devs describe their games as "like minecraft tnt tag" (https://devforum.roblox.com/t/detect-player-touches-player/2274583) and as "Heavily inspired by the bomb tag gamemode in Dani's Crab Game" (https://devforum.roblox.com/t/looking-for-16-players-to-help-film-a-trailer-for-my-game/3875302).
- **Not found** for any bomb game: exact intermission seconds, results-screen length, and how long a new joiner waits before entering a round.
  - Inferred from the mechanics above: last-standing games make a joiner wait out the current match, which is up to ~2 min in Pass or Explode. Open Arena and Free-for-All in Timebomb Duels exist partly to shorten that wait.

#### What makes it feel smooth

- **Hit registration**
  - Tags are server-side, so ping matters (earnaldo compares 30 ms with 150 ms).
  - Bloxodes tells players to pick a low-ping server and to "retry early if the first contact doesn't transfer".
  - Timebomb Duels' own description asks players to join the lowest-ping server (S).
- **Movement skill ceiling is the product**: guides rank "Shift Lock Strafing, 3-Second Bomb Pass, Ankle Breaking" as S-tier (earnaldo).
  - The top YouTube results are skill and humiliation videos: "Breaking ANKLES In Timebomb Duels.." (1,005,474 views, https://youtu.be/WXfZdtVDB5w), "DESTROYING Pros As Michael Jackson..." (474,929 views, https://youtu.be/aqE4j7jFHZ4), and "1v1ing EVERY Timebomb Duels Youtuber.." (139,729 views, https://youtu.be/ECqD1br7K6M).
  - One clone is literally named "TimeBomb AnkleBreak!".
- **Pass cooldown**: a paid kit advertises "pass cooldown logic that prevents instant pass-backs" plus rotating speed and low-gravity modifier rounds (BuiltByBit "Bomb Tag v1.0", summarized via search; the page returned 403 on direct fetch: https://builtbybit.com/resources/bomb-tag.95283/updates). Bomb Tag Survival gives the bomber extra speed (same search summary).
- **Kill and explosion VFX are the main cosmetic**
  - Timebomb Duels has 33 kill effects, some only from past events, plus a "Kill Effect Update" (Dec 2025) (bloxodes).
  - Pass or Explode credits the kill effect to whoever passed the bomb; for example, Balloon floats the victim away (allthings.how).
  - AnkleBreak sells "BLACK HOLE KILL EFFECT" and "KJ KILL EFFECT" (GP 9758027784) and advertises "Lots of different sounds" (S).
- **Simple core input**: a Timebomb Duels-side dev on DevForum argued that extra mechanics hurt: "you simply pass the bomb without having to think much about it, like 'here, take it, it's all yours now!' and run" (Delightyes, https://devforum.roblox.com/t/feedbackproblem-hot-potato-slap-counter-game/4450393). The same dev describes "a time bomb game already, with about 8k CCU rn, from 2022"; inferred to be Timebomb Duels.
- **Not documented** in any source I reached: camera shake, countdown style, spectate after elimination, mobile tag button, holder/crown HUD.
  - Inferred: touch-to-pass needs no mobile button, which is one reason the format works on phones.

#### Progression

- **Timebomb Duels**: wins tracking, Alpha/Beta chat-tag badges (the Alpha badge has 50.4M awards), event kill effects, and stats wiped each stage (bloxodes; S description). It has no gamepasses at all (GP 4049246711 returned an empty list). Earnaldo says spending is cosmetic-only.
- **Pass or Explode**
  - Coins scale with survival time. Daily and weekly quests and codes give more.
  - **Abilities come from Coin crates**: Basic 1600 and Rare 3400 Coins, one ability type equipped per match. These are the only win-affecting items. Bomb skins and kill effects are cosmetic. (allthings.how)
- **Hot Potato**: "Earn Cash + unlock skins, trails & titles" (S).
- **Monkey Bomb Tag**: bananas buy cases of tails, bombs, effects and emotes, and the game has a level cap (techwiser; https://www.robloxgames.org/how-to-play/monkey-bomb-tag).
- **Pass the Bomb!**: "15% bonus XP" for joining the group, and like-goal codes (S).

#### Monetization (GP list, seen 2026-10-23)

- **Hot Potato**: VIP 99, Rainbow Potato 29, Pro Pack 29, Rainbow Trail 19, Double Cash 149 R$. Light.
- **Monkey Bomb Tag**: V.I.P 299, X2 Votes 149, X2 Bananas 199 R$.
- **Pass or Explode**: VIP 199, 2X Coins 299 R$.
- **Pass the Bomb!**: VIP 299, Double Coins 199, Instant Unbox (off sale).
- **TimeBomb AnkleBreak!**: 15+ passes.
  - FOMO wording aimed at kids: "LIMITED SKIN (NEVER COMING BACK)" 49, "LIZARD SKIN(LIMITED)" 19, "[OP]" tags on cosmetics.
  - Meme skins: "ISHOWSPEED MEME SKIN", "67 SKIN".
  - "Ultimate Bundle! (Every Gamepass + Future)" 799 R$.
  - **Predatory-leaning (inferred)**: false scarcity and "OP" labels on purely cosmetic items.
- **Timebomb Duels**: zero gamepasses. Revenue presumably comes from shop and dev products (inferred; not public).
- **Pass or Explode**: crate-gated, win-affecting Abilities. These are bought with Coins, but double-coin passes speed that up, which makes it soft pay-to-win (inferred).

#### Complaints / why clones flop

- **Empty-server death spiral**: "I dont have enough funds to keep a ccu of at least 10 players which makes players leave instantly" (ItzBlandy, DevForum 4450393).
  - Another dev spent 30k Robux on sponsors and peaked at ~15 CCU before dropping to 0 with 4.2 min average playtime (https://devforum.roblox.com/t/help-with-getting-players-to-play-my-game/2717202).
  - A 2022 tester couldn't play because the minimum was 2 players (https://devforum.roblox.com/t/feedback-on-my-game-bomb-tag/1626925).
  - Inferred: bots or solo filler are needed.
- **Naming/expectation mismatch**: the game called "Brawl" confused players who expected fighting, not tagging (DevForum 2717202).
- **Twists that add friction**: slap/counter mechanics "may take away from the fun" (DevForum 4450393).
- **Spaghetti round loops**: slow bomb assignment at round start (https://devforum.roblox.com/t/i-need-help-with-this-huge-bug/2492218).
- **Timebomb Duels' own weak spot**: the lowest like ratio in the family (64.9%; V).
  - YouTube titles centre on "TOXIC Pros", rage quits and "Most OP AVATAR(smallest)" (https://youtu.be/8RTXh2XnnpM, https://youtu.be/2OlFSXOeo7o).
  - Inferred: complaints are about skill gaps between pros and new players with no SBMM, avatar-size hitbox advantages, and ping-based "tags from far away" (earnaldo).
- **Trend-wave clones die fast**:
  - Monkey Bomb Tag: created 2026-01-15, peaked at 39K in May, now 542.
  - Pass or Explode: created 2026-02-01, peaked at 11K in Jul, now 229.
  - Pass or Die: not updated since 2025-07.
  - (S/RoWatcher) Delightyes notes that near-identical clones "sometimes" work if polished and well promoted.

---

### 2. Freeze tag

#### Stats (seen 2026-10-23, ~07:45 UTC)

| Game | Link | Visits | Like % | Playing | Peak (RoWatcher tracked) | Updated | Source URL | Seen |
|---|---|---|---|---|---|---|---|---|
| Freeze Tag 🧊 (크롱 커뮤니티, created 2026-09-26) | https://www.roblox.com/games/80048951661785 | 2,726,431 | 81.7% | 2,925 | 5K (Oct 2026) | 2026-10-23 | S/V 10768088991; https://rowatcher.com/games/10768088991 | 2026-10-23 |
| 🎃 Freeze Tag Ultimate! 🎃 (C.D. Studio) | https://www.roblox.com/games/86027188545532 | 25,662,759 | 73.3% | 95 | 1K (May 2026) | 2026-10-21 | S/V 7785204538; https://rowatcher.com/games/7785204538 | 2026-10-23 |
| Freeze Tag🧊 (ConnorVIII, 2016) | https://www.roblox.com/games/364802243 | 174,826,623 | 76.1% | 2 | 40 (Oct 2026; tracking-window artefact) | 2026-07-07 | S/V 138413601; https://rowatcher.com/games/138413601 | 2026-10-23 |
| Freeze Tag! 🧊 [EVENT] (PolyCrunch) | https://www.roblox.com/games/1447061775 | 58,511,796 | 69.6% | 1 | not fetched | 2026-09-30 | S/V 574664526 | 2026-10-23 |

Inferred: the genre is nearly empty. The 2016-2018 originals are dead, and the one live game is a 4-week-old Korean title.

#### Loop/timings
- **Freeze Tag 🧊**: the Tagger freezes Runners, and "A friend can tap you to unfreeze you". Runners win "If even one Runner survives until time runs out". The Tagger wins by freezing everyone. It has daily group rewards. Round length is not stated. (S description)
- **ConnorVIII Freeze Tag**
  - Tag/thaw by team, an "Infection" round variant, crates, Cash/EXP for tagging and thawing, and upgradeable power-up boosts (S description).
  - Its update log adds map-vote UI, a "Frozen/Free Runner counter", a survival win-streak counter, a NINJA badge for "50 concurrent wins as a runner", mobile shift-lock, camera cutscene intros, and "Vastly improved responsiveness of 'freezing' and 'thawing'" (https://devforum.roblox.com/t/freeze-tag-update-log/156264).
- **Freeze Tag Ultimate**: a gear loadout (Ray Guns, Rockets, Landmines), plus cosmetic ice blocks, thaw effects and trails (S description).

#### Feel / progression / monetization
- **Feel**: thaw responsiveness and a frozen-count HUD are the polish items the leading dev called out (update log above). Custom ice-block cosmetics are the signature visual (ConnorVIII "Ice editing room"; Ultimate's "Custom Ice Blocks, Thaw Effects").
- **Freeze Tag 🧊 GP**: paid **skills** that look pay-to-win, at 149 / 399 (시간 정지 "time stop") / 899 / 1549 / **2499 R$** (얼음 드래곤 "ice dragon"). Also "술래 확률 UP" (tagger chance up) 99, VIP 199 and 2x coins 249 (GP 10768088991).
  - Inferred: this is the most aggressive pricing in the whole tag family. Paid abilities sold to a young audience.
- **ConnorVIII**: Boost-change, Rainbow Ice and Pet passes (update log).

#### Complaints / why it flopped (inferred unless cited)
- The rule that the Tagger has to freeze *everyone* drags out the end of a round. One good Runner can stall, and frozen players just stand there.
- ConnorVIII's Freeze Tag shows a 76.1% like ratio on 237K up-votes and 2 players today (S/V).
- No player-complaint threads were retrieved; search tools hit their limit.

---

### 3. Hide and seek

#### Stats (seen 2026-10-23, ~07:45 UTC)

| Game | Link | Visits | Like % | Playing | Peak (RoWatcher tracked) | Updated | Source URL | Seen |
|---|---|---|---|---|---|---|---|---|
| [🎃UPD🎃] Paint Or Seek [Chameleon] (10 CCU) | https://www.roblox.com/games/85245205758607 | 211,145,198 | 78.5% | 2,528 | 93K (Jul 2026) | 2026-10-18 | S/V 10278774552; https://rowatcher.com/games/10278774552 | 2026-10-23 |
| [NEW RIGS] Chameleon! 🎨 (Palette Games) | https://www.roblox.com/games/84449017742177 | 91,966,677 | 78.4% | 1,981 | not fetched | 2026-08-21 | S/V 10289201563 | 2026-10-23 |
| Hide and Seek Extreme (Tim7775, 2015) | https://www.roblox.com/games/205224386 | 3,426,563,437 | 91.1% | 1,564 | 18K (Jan 2025) | 2026-08-28 | S/V 93740418; https://rowatcher.com/games/93740418 | 2026-10-23 |
| 💀 Hide or OOF! (0 CCU Games) | https://www.roblox.com/games/18799085098 | 813,257,191 | 86.3% | 1,288 | 48K (Oct 2024) | 2026-10-19 | S/V 6369934270; https://rowatcher.com/games/6369934270 | 2026-10-23 |
| [🎃] Mega Hide and Seek! (Blox Games) | https://www.roblox.com/games/5708035517 | 548,957,960 | 84.1% | 1,088 | 16K (Feb 2026) | 2026-10-13 | S/V 2020908522; https://rowatcher.com/games/2020908522 | 2026-10-23 |

#### Loop/timings
- **Hide and Seek Extreme**
  - Random map and random seeker each round. The seeker is frozen at spawn but can watch, while hiders get "a short period of time to hide". Contact catches a hider.
  - Hiders win if the timer runs out; the seeker wins by catching everyone. (https://hide-and-seek-extreme.fandom.com/wiki/Gameplay)
  - The seeker plays as an "It" character with an ability (Sprint, Glue, Place Camera). The Yeti is the only Robux character (https://hide-and-seek-extreme.fandom.com/wiki/%22It%22). Press 1 for the ability and T to taunt (S description).
- **Mega Hide and Seek**: "one minute to explore & hide" before the seeker arrives. Maps have cannons, slides, teleporters and bounce pads. VIP-server owners get a control panel to pick mode, map and seeker (S description).
- **Paint Or Seek**: hiders paint themselves to blend in. Caught hiders "join the Seekers", which is infection-style and keeps eliminated players playing (S description).
- **Hide or OOF**: prop-morph hiders and armed seekers. Killed hiders join the seekers (S description).
- Seek-phase length is not documented in the sources I reached.

#### Feel / progression
- **Infection conversion** (Paint Or Seek, Hide or OOF) means nobody spectates for long. Inferred: this is the main retention edge over classic one-seeker formats.
- **Paint mechanic**: Paint Or Seek's 93K peak came 1 month after it was created on 2026-06-06 (S/RoWatcher). It needs a moderation rule against "inappropriate or offensive drawings" (S description).
- **Progression**: coins/credits for It characters (HSE), quests, diamonds and seeker power-ups (Mega), and a Battle Pass S1 (Paint Or Seek).

#### Monetization (GP, seen 2026-10-23)
- **HSE**: Yeti 50, Boombox 300, "Seeker chance multiplier" 100, Triple Coin Value 30 R$.
- **Mega H&S**: "Select Seeker Chance" 499, VIP 499, 2x Coins **799 R$**.
- **Hide or OOF**: "More Damage" 299 and "More Health" 149 R$. These are pay-to-win.
- **Paint Or Seek**: "Permanent Bazooka!" **1999 R$**, "Dragon RPG" 1499, Golden shotgun 298, +Speed 89, private-server commands 299, Battle Pass 39/129, plus many 9-39 R$ emotes. Inferred: high-priced weapons in a kids' hide-and-seek game.
- **Selling the chance to be seeker** shows up in HSE, Mega and Freeze Tag 🧊, so it is a genre norm.

#### Complaints (inferred; no complaint threads retrieved)
- Seeker-chance passes make role assignment feel bought.
- In one-seeker formats, a hider caught early spectates a long round.

---

### 4. Dodgeball

#### Stats (seen 2026-10-23, ~07:45 UTC)

| Game | Link | Visits | Like % | Playing | Peak (RoWatcher tracked) | Updated | Source URL | Seen |
|---|---|---|---|---|---|---|---|---|
| [🎃] Dodge or Die (AllOut Games) | https://www.roblox.com/games/131794278839305 | 46,690,021 | 88.5% | 908 | 6K (Oct 2026) | 2026-10-23 | S/V 9845585365; https://rowatcher.com/games/9845585365 | 2026-10-23 |
| Dodgeball Legends (InfinitySports) | https://www.roblox.com/games/84529258884762 | 44,431,049 | 84.9% | 24 | 468 (May 2026) | 2026-07-21 | S/V 6920930774; https://rowatcher.com/games/6920930774 | 2026-10-23 |
| ⚡Ultimate Dodgeball (Who Crew) | https://www.roblox.com/games/11106338443 | 293,920 | 60.0% | 122 | not fetched | 2026-10-23 | S/V 3974441055 | 2026-10-23 |
| Adjacent: [🎃] Death Ball | https://www.roblox.com/games/15002061926 | 1,643,206,877 | 96.1% | 3,804 | 28K (Dec 2025) | 2026-10-17 | S/V 5166944221; https://rowatcher.com/games/5166944221 | 2026-10-23 |
| Adjacent: Blade Ball | https://www.roblox.com/games/13772394625 | 6,502,377,167 | 93.5% | 11,785 | 60K (Dec 2024; tracking-window value) | 2026-10-18 | S/V 4777817887; https://rowatcher.com/games/4777817887 | 2026-10-23 |

Other dodgeball games:
- Phantom Ball (4538598064): 219.4M visits, 93.2% liked, 936 playing.
- ASIMO's DODGEBALL! (New) (10768782390): 33 playing in omni-search despite an "Official Trailer" with 101,802 views (https://youtu.be/074M6t6ZrJs).

Inferred: classic team dodgeball is weak on Roblox. The genre's players moved to deflect-the-homing-ball games (Blade Ball, Death Ball), which are last-standing survival with a single shared projectile.

#### Loop / feel / progression
- **Dodge or Die**: dodge flying balls in last-standing arenas, use tools and abilities, upgrade movement and speed, and open crates where a duplicate "upgrades it" (S description). Servers hold 15.
- **Dodgeball Legends**: up to 7v7 with special abilities (S description).
- **YouTube**: "Using OP ABILITIES in Roblox Dodgeball" (1,012,419 views, https://youtu.be/oki86M30n-s). Abilities drive the views.
- No timings were found for dodgeball rounds.

#### Monetization
- **Dodge or Die GP**: Ninja Jump Tool 189, Human Shield Tool 189, Freeze Ray 149, Attack Dog 199, Mafia Boss 199, VIP 299, x2 Luck 199 R$ (GP 9845585365).
  - Inferred: these are pay-to-win combat tools, and "x2 Luck" boosts crate odds.

#### Complaints (inferred)
- Team dodgeball needs about 8+ players to feel good, so it hits the same empty-server wall as the bomb clones. Dodgeball Legends fell from a 468 peak to 24 players.

---

### Cross-family takeaways (inferred)

1. **The bomb market is one winner plus a churn of clones.**
   - Timebomb Duels has 10.6K live players.
   - The next biggest is Hot Potato with 2.5K, made in Jun 2026 and peaking at 11K in Oct.
   - The winner has the worst like % but the deepest skill ceiling, made visible by YouTube ankle-break content.
2. **Fast eliminations work.** Rounds of about 10 s, an ~2 min match and a final-2 duel finale are standard: Pass or Explode, Hot Potato and the Slap-or-Die concept all use them.
3. **Infection conversion beats spectating** (hide-and-seek leaders). Bomb games still lack this; the open question is what eliminated players do.
4. **Monetization to avoid for kids**: false-scarcity "LIMITED (NEVER COMING BACK)" skins, paid skills or weapons at 1,500-2,500 R$, and "seeker/tagger chance" passes. Timebomb Duels proves a top game can run with zero gamepasses.
5. **Biggest risk for a new entry**: cold-start CCU. Plan bots or solo play, and a burst of ad spend, before launch.


---

## Lava, tower race and speed obby

**How the numbers were collected.** All live numbers were pulled 2026-10-23 at about 07:45 UTC from Roblox public APIs:
- Stats: `https://games.roblox.com/v1/games?universeIds=<id>` (visits, playing, updated)
- Votes: `https://games.roblox.com/v1/games/votes?universeIds=<id>` (like % = up / (up + down))
- Game passes: `https://apis.roblox.com/game-passes/v1/universes/<id>/game-passes?passView=Full&pageSize=50`
- Dev products: `https://apis.roblox.com/developer-products/v2/universes/<id>/developerproducts?limit=50` (names only; prices came back null)
- Candidates: `https://apis.roblox.com/search-api/omni-search?searchQuery=<q>&sessionId=abc&pageType=all`

**About the peaks.** Peaks are all-time concurrent players as reported by third-party trackers: rotrends.com (`/game/<universeId>`) and rowatcher.com (`/games/<universeId>/<slug>`). The two trackers often disagree, so both figures are given.
- romonitorstats.com: the page loaded, but the stats render in JavaScript and no numbers came through (https://romonitorstats.com/experience/815405518/).
- tower-of-hell.fandom.com: returned 402 to WebFetch and a Cloudflare 403 to curl, so it was not readable.
- A search snippet said Rotrends would be deprecated on Aug 31. Its game pages still showed live counts on 2026-10-23, though.
- My own judgment is labeled **(inferred)**.

---

### 1. Rising lava / floor is lava / escape the lava (deepest)

#### Stats

| Game | Link | Visits | Like % | Playing | Peak (all-time) | Updated | Source URL | Seen |
|---|---|---|---|---|---|---|---|---|
| The Floor Is LAVA! (TheLegendOfPyro, 2017, 16-player servers) | https://www.roblox.com/games/815405518 | 3,213,970,702 | 76.9% (860,966 / 258,137) | 1,507 | 35.3K (rotrends); 27K, Aug 2025 (rowatcher) | 2026-10-09 | https://games.roblox.com/v1/games?universeIds=341654025 ; https://rotrends.com/game/341654025 ; https://rowatcher.com/games/341654025/the-floor-is-lava | 2026-10-23 |
| Escape The Lava (STOP INC., created 2025-08-21, 26-player servers) | https://www.roblox.com/games/140481779622210 | 206,618,700 | 92.0% (43,932 / 3,797) | 1,501 | 18K (rotrends); 16K, Sep 2025 (rowatcher) | 2026-03-14 | https://games.roblox.com/v1/games?universeIds=8504461817 ; https://rotrends.com/game/8504461817 ; https://rowatcher.com/games/8504461817/escape-the-lava | 2026-10-23 |
| 100 Player Lava Escape (Colorful Coconut, created 2025-10-17, 100-player servers) | https://www.roblox.com/games/135535794227264 | 25,139,046 | 76.8% (6,141 / 1,850) | 1,467 | 13.8K (rotrends); 14K, Oct 2026 (rowatcher) | 2026-10-20 | https://games.roblox.com/v1/games?universeIds=8965717730 ; https://rotrends.com/game/8965717730 ; https://rowatcher.com/games/8965717730/100-player-lava-escape | 2026-10-23 |
| 100 Player Floor Is LAVA! (Expeariments, 2023, 50-player servers) | https://www.roblox.com/games/14842128242 | 129,168,347 | 90.6% (62,462 / 6,511) | 198 | 9.6K (rotrends); 4K, Oct 2026 (rowatcher) | 2026-10-20 | https://games.roblox.com/v1/games?universeIds=5114328099 ; https://rotrends.com/game/5114328099 ; https://rowatcher.com/games/5114328099/100-player-floor-is-lava | 2026-10-23 |
| *Adjacent: rising-hazard collectors* | | | | | | | | |
| Escape Tsunami For Brainrots! (Wave of Brainrots, created 2025-12-15, 8-player servers) | https://www.roblox.com/games/131623223084840 | 5,738,378,035 | 83.1% | 3,703 | 5M (rotrends); 4.1M, Feb 2026 (rowatcher) | 2026-10-22 | https://games.roblox.com/v1/games?universeIds=9363735110 ; https://rotrends.com/game/9363735110 ; https://rowatcher.com/games/9363735110/escape-tsunami-for-brainrots | 2026-10-23 |
| Survive LAVA for Brainrots! (Johnny Lava, created 2026-01-30, 5-player servers) | https://www.roblox.com/games/119987266683883 | 753,569,589 | 93.6% | 465 | 1.0M, Feb 2026 (rowatcher) | 2026-10-23 | https://games.roblox.com/v1/games?universeIds=9649298941 ; https://rowatcher.com/games/9649298941/survive-lava-for-brainrots | 2026-10-23 |
| Survive the Lava for Eggs! (La Maison Studio, created 2026-10-06; new) | https://www.roblox.com/games/91907352069556 | 529,581 | 97.7% | 410 | 896, Oct 2026 (rowatcher) | 2026-10-22 | https://games.roblox.com/v1/games?universeIds=10769648429 ; https://rowatcher.com/games/10769648429/survive-the-lava-for-eggs | 2026-10-23 |
| *Flop example:* TOH but with rising lava (EIocution) | https://www.roblox.com/games/8815018120 | 236,214,624 | **44.5%** (40,152 / 50,161) | 270 | n/a | 2024-05-04 | https://games.roblox.com/v1/games?universeIds=3340228749 | 2026-10-23 |

- The three main lava games each showed about 1,500 playing at the same moment (1,507 / 1,501 / 1,467). Rotrends also listed 1,488 / 1,473 / 1,506 at about the same time. This is probably a coincidence, not a cap (inferred). Sources: API above, https://rotrends.com/game/341654025
- **The genre's money moved to "rising hazard plus collect-and-base" hybrids (inferred).** Tsunami For Brainrots peaked at 4-5M CCU. Survive LAVA for Brainrots peaked at 1.0M. Classic round-based lava games peak at 14-35K. Sources: the rotrends/rowatcher pages in the table.

#### Round loop and timings
- **The Floor Is LAVA, per a third-party Robux-earning blog (treat with caution).** Each cycle has three phases, about 75 s in total. https://earnaldo.com/blog/the-floor-is-lava-free-robux-guide
  - 15 s prep: you spawn on the ground and climb.
  - About 40 s lava phase.
  - About 20 s intermission while the next map loads.
- **Lava rise curve.** Rise speed varies by map: some start fast and slow near the top, others rise steadily (same source). https://earnaldo.com/blog/the-floor-is-lava-free-robux-guide
- **Damage.** Lava drains health over time rather than killing instantly (same source). https://earnaldo.com/blog/the-floor-is-lava-free-robux-guide
- **Death rule.** You die once your body is submerged, at the point the swim animation triggers. Spam-jumping at the surface buys time. https://namu.moe/w/The%20Floor%20Is%20LAVA
- **Map destruction.** Rising lava blackens structures, which then fade and vanish. A structure can still be stood on until it is gone, so tall buildings are not permanently safe. https://namu.moe/w/The%20Floor%20Is%20LAVA
- **Gear-gated maps.** Some maps are described as unsurvivable without shop gear. https://namu.moe/w/The%20Floor%20Is%20LAVA
- **What counts as escaping.**
  - Classic mode: be alive when the lava phase ends, for +10 points. https://namu.moe/w/The%20Floor%20Is%20LAVA
  - Escape The Lava: "Survive lava to get to the end and earn wins", so it is a linear run to a finish (game description via API). https://games.roblox.com/v1/games?universeIds=8504461817
  - 100 Player Lava Escape: a "rising lava tsunami" troll obby where you race to the end and slap rivals into the waves. https://games.roblox.com/v1/games?universeIds=8965717730
  - 100 Player Floor Is LAVA: pitched as Red Light Green Light plus "Be Crushed By A Speeding Wall" plus lava, with pushing. https://games.roblox.com/v1/games?universeIds=5114328099
- **Spawn bonus.** In Floor Is LAVA, clearing the jump map at spawn pays 5 points, which gives players something to do between rounds. https://namu.moe/w/The%20Floor%20Is%20LAVA
- **Seconds until a new player plays.** No source measured this. With a ~75 s cycle and a ~20 s intermission, the worst case is about 55-75 s for a mid-round joiner (inferred from https://earnaldo.com/blog/the-floor-is-lava-free-robux-guide).
- **DevForum advice on intermission screens.** A reviewer suggested cutting a "We are going to play" screen to 3-5 s because players get bored waiting. https://devforum.roblox.com/t/feedback-on-my-rising-lava/1215711

#### Powers (dash / double jump / shield / grapple)
- **The Floor Is LAVA game passes (Robux, live).** https://apis.roblox.com/game-passes/v1/universes/341654025/game-passes?passView=Full&pageSize=50
  - DOUBLE JUMP! 39
  - Grapple Hook 499
  - Lava Shield 249
  - Jetpack 399
  - Ultra Coil (Speed/Jump) 149
  - PUNCH! 599
  - V.I.P. 299
  - ADMIN COMMANDS 2999
  - Healing Coil 25
  - Pets 35-125
- **Floor Is LAVA pass details from older sources.** https://namu.moe/w/The%20Floor%20Is%20LAVA ; https://earnaldo.com/blog/the-floor-is-lava-free-robux-guide
  - Lava Shield gives 50% less lava damage.
  - The Grapple Hook can hold position after hooking.
  - The Jetpack has limited fuel.
  - VIP gives 2x speed, 2x health and a glider.
  - PUNCH has a 60 s cooldown.
- **Floor Is LAVA items bought with points.** https://namu.moe/w/The%20Floor%20Is%20LAVA
  - Banana: 1,000 points (trap).
  - Gravity Gun: 4,000 points.
  - Ninja Jump Potion.
  - Shovel: temporary platform for about 15 s.
  - Slate Skin (more HP).
  - Items unlocked with survival points: Speed Shoes, Trampoline, Deluxe Hook Shot, Ice Gun, Ladder.
- **Floor Is LAVA dev products (consumables).** Names include +Points packs, Revive, Deluxe Grapple, Web Shooter, Speed Shake, Push, SPIN / DISCOUNT SPIN, LUCKY BLOCK and crates. https://apis.roblox.com/developer-products/v2/universes/341654025/developerproducts?limit=50
- **Escape Tsunami For Brainrots: permanent power passes (Robux).** This is the closest match to "powers". https://apis.roblox.com/game-passes/v1/universes/9363735110/game-passes?passView=Full&pageSize=50
  - Rainbow Shield 295
  - Double Jump Coil 160
  - Harpoon Gun 640 (grapple-like, inferred)
  - Anti-Wave Device 699
  - Shockwave Bomb 349
  - Super Speed Boost 329
  - Speed Boost 129
  - VIP 175
  - VIP+ 888
  - A "+1 Jump" dev product.
- **Survive LAVA for Brainrots passes (Robux).** https://apis.roblox.com/game-passes/v1/universes/9649298941/game-passes?passView=Full&pageSize=50
  - Bunny Ears (Double Jump) 199
  - Gravity Coil 149
  - Speed Coil 19
  - Ladder 49
  - VIP 149 / VIP+ 499
  - 2x Money 99
  - Admin Panel 7499
  - Its description adds "Rebirth to upgrade your jump height". https://games.roblox.com/v1/games?universeIds=9649298941
- **Escape The Lava.** The only pass is "Deadly Treadmill" (200). Power progression is speed: "Train your speed", pets give speed. https://apis.roblox.com/game-passes/v1/universes/8504461817/game-passes?passView=Full&pageSize=50 ; https://games.roblox.com/v1/games?universeIds=8504461817
- **No top lava game was found that gives dash, double jump, shield and grapple as earnable, cooldown-based abilities.** Every one sells them as Robux passes or gear. +1 Speed Parkour Obby Escape does bind Double Jump (Space x2), Dash (E), Slide (Ctrl) and Super Jump (F) as base controls. https://games.roblox.com/v1/games?universeIds=10307582366
  - That is a gap a powers-earned-by-crowns design could fill (inferred).

#### Crowns / wins and what they buy
- **Floor Is LAVA points.** https://namu.moe/w/The%20Floor%20Is%20LAVA
  - Coin: 2 points (about 4-5 per map).
  - Diamond/star: 5 points.
  - Surviving a round: 10 points.
  - Clearing the spawn obby: 5 points.
  - A separate "survival" counter goes up by 1 per survived round and is never spent. It unlocks the survival-item tier.
  - Points are also sold for Robux.
- **Escape The Lava wins.** Wins unlock new worlds. Dev products sell the worlds directly ("Unlock Volcano/Frozen/Space/Beach World"), plus +Wins packs, Speed Multi levels 1-11, +100 up to +1QD Speed and "Instant Level Up [NEXT TREADMILL]". https://games.roblox.com/v1/games?universeIds=8504461817 ; https://apis.roblox.com/developer-products/v2/universes/8504461817/developerproducts?limit=50
- **100 Player Lava Escape** uses coins to unlock items. **100 Player Floor Is LAVA** uses gems. https://games.roblox.com/v1/games?universeIds=8965717730 ; https://games.roblox.com/v1/games?universeIds=5114328099
- **No game in this family uses "crowns" as its currency** (checked descriptions and passes above). Crowns would be a differentiator (inferred).

#### What makes it feel smooth (sourced and inferred)
- **Lava movement.** Server-side tweens look choppy because replication runs below the frame rate. The usual fix: the server fires a RemoteEvent with the tween parameters, each client tweens locally, and the server sets the final position. A batching library (BridgeNet2) is suggested when there are many tweens. https://devforum.roblox.com/t/smoothing-tween/2653125 ; https://devforum.roblox.com/t/simplify-tweenservice-replication-to-client/3041718 ; https://devforum.roblox.com/t/tweenservice-v-2/199815
  - For lava, the server should own a start time and a height curve. Clients compute height(t) every frame, and the server checks deaths against the same curve (inferred).
- **Lava visual artifacts.**
  - The lava surface z-fought with the ground, causing flashing that a reviewer warned could be a seizure risk.
  - Overlapping lava textures look sloppy.
  - Reviewers recommend TweenService with a fixed duration so the round timer and lava stay in sync.
  - https://devforum.roblox.com/t/feedback-on-my-rising-lava/1215711
- **Collapsing buildings.** Lava Touched unanchors parts and destroys welds, giving a physical collapse. The mechanic is confirmed in Floor Is LAVA as fade-out, not physics. https://devforum.roblox.com/t/rising-lava-collapsing-buildings/3057570 ; https://namu.moe/w/The%20Floor%20Is%20LAVA
- **Variety.** Reviewers ask for more maps, random disaster patterns and destroyable structures, because identical rounds get repetitive. A spectate button is also expected. https://devforum.roblox.com/t/feedback-on-my-rising-lava/1215711 ; https://devforum.roblox.com/t/can-you-guys-tell-me-what-might-be-missing-from-my-game-the-rising-lava/1222716
- **Exploit.** Players could earn wins after dying or leaving mid-round. Remove players from the alive table on death or leave. https://devforum.roblox.com/t/feedback-on-my-rising-lava/1215711
- **ASMR and juice in the top speed game.** It advertises "Smooth movement, satisfying keyboard clicks, creamy visuals" and sells soundpacks (Unlock Soundpacks 85 R$). https://games.roblox.com/v1/games?universeIds=9584852943 ; https://apis.roblox.com/game-passes/v1/universes/9584852943/game-passes?passView=Full&pageSize=50
- **Not found in public sources:** exact ragdoll, camera, HUD lava-height bar and mobile-control implementations in these games. Standard expectations (inferred):
  - A lava-height or timer bar.
  - A 3-2-1 countdown with sound.
  - A heat-shimmer or red vignette near the surface.
  - A glowing neon surface with a bubbling particle emitter.
  - Mobile jump-button sizing.
  - Auto-spectate on death.
- **Server sizes vary widely: 5 to 100 players.**
  - "100 Player" branding is a growth lever: both 100-player titles are still updated and 100 Player Lava Escape peaked at 14K in Oct 2026.
  - The collect-and-base hybrids run tiny servers of 5-8 players.
  - https://games.roblox.com/v1/games?universeIds=8965717730,5114328099,9363735110,9649298941

#### Monetization: flags for kids
- **PREDATORY FLAG: Escape Tsunami For Brainrots** sells many randomized items: Spins (Radioactive, UFO, Doom, Bloodmoon, Atlantis...), Lucky Blocks in 1x/3x/10x bundles, 2x/4x Server Luck, and Trade Tokens. Loot-box mechanics in a kid-skewed game. https://apis.roblox.com/developer-products/v2/universes/9363735110/developerproducts?limit=50
- **PREDATORY FLAG: Survive LAVA for Brainrots** sells Lucky Blocks (1x/3x/10x across several themes), Spins and 2x/4x/8x Server Luck, plus a 7,499 R$ Admin Panel. https://apis.roblox.com/developer-products/v2/universes/9649298941/developerproducts?limit=50 ; https://apis.roblox.com/game-passes/v1/universes/9649298941/game-passes?passView=Full&pageSize=50
- **Escape The Lava** sells world unlocks and "+1QD Speed"-style pay-to-skip progression (pay-to-win, inferred). https://apis.roblox.com/developer-products/v2/universes/8504461817/developerproducts?limit=50
- **The Floor Is LAVA** sells a 2,999 R$ Admin pass, 599 R$ PUNCH (griefing other players), Lucky Block and SPIN products, and points for Robux. Some maps are described as unwinnable without gear, which is pay-to-win. https://apis.roblox.com/game-passes/v1/universes/341654025/game-passes?passView=Full&pageSize=50 ; https://namu.moe/w/The%20Floor%20Is%20LAVA
  - Its description also says "PREMIUM Users: Play for 10 minutes to get a Lucky Block for FREE!" https://games.roblox.com/v1/games?universeIds=341654025

#### Complaints and why clones flop
- **Floor Is LAVA criticisms.** https://namu.moe/w/The%20Floor%20Is%20LAVA
  - Pay-to-win passes and maps.
  - The overpowered "cheap" Deluxe Hook Shot clears most maps.
  - Pets are cosmetic and poor value.
  - A Nov 2021 bug wiped survival progress.
- **"TOH but with rising lava" sits at 44.5% likes and was last updated May 2024.** Bolting lava onto a precision no-checkpoint tower likely felt unfair (inferred). https://games.roblox.com/v1/games?universeIds=3340228749
- **Clone pitfalls raised on DevForum.** https://devforum.roblox.com/t/feedback-on-my-rising-lava/1215711 ; https://devforum.roblox.com/t/can-you-guys-tell-me-what-might-be-missing-from-my-game-the-rising-lava/1222716
  - Crude GUI.
  - Same scenery and lava every round.
  - Long pre-round screens.
  - Jittery lava.
  - A broken shop.
- **YouTube attention favors the brainrot lava games.** "ROBLOX SURVIVE LAVA FOR BRAINROTS!" has 2,877,449 views and "$0 - $1 Trillion in Survive Lava For Brainrots.." has 2,318,876. Classic Floor Is LAVA videos run 54K-1.1M. https://www.youtube.com/results?search_query=roblox+escape+the+lava+wins ; https://www.youtube.com/results?search_query=roblox+floor+is+lava+2026

---

### 2. Tower race (Tower of Hell style)

#### Stats

| Game | Link | Visits | Like % | Playing | Peak (all-time) | Updated | Source URL | Seen |
|---|---|---|---|---|---|---|---|---|
| Tower of Hell (YXceptional Studios, 2018, 20-player servers) | https://www.roblox.com/games/1962086868 | 29,233,348,634 | 73.6% (4,380,121 / 1,569,586) | 24,002 | 68.1K (rotrends); 75K, Aug 2026 (rowatcher) | 2026-10-10 | https://games.roblox.com/v1/games?universeIds=703124385 ; https://rotrends.com/game/703124385 ; https://rowatcher.com/games/703124385/tower-of-hell | 2026-10-23 |
| [2x Coins] Tower of Misery (Limitless Studio, 2020) | https://www.roblox.com/games/4954752502 | 4,042,023,958 | 78.3% | 338 | 6.1K (rotrends); 2K, Jul 2026 (rowatcher) | 2026-09-11 | https://games.roblox.com/v1/games?universeIds=1701623492 ; https://rotrends.com/game/1701623492 ; https://rowatcher.com/games/1701623492/tower-of-misery | 2026-10-23 |
| Longest Tower Race (Mega More Fun, 2022) | https://www.roblox.com/games/9992339729 | 96,163,856 | 70.3% | 70 | not fetched | 2025-05-13 | https://games.roblox.com/v1/games?universeIds=3681669024 | 2026-10-23 |

#### Loop and timings
- **Format.** Randomly generated tower with "absolutely no checkpoints". VIP-server owners can skip rounds, set tower size and lock the shop. https://games.roblox.com/v1/games?universeIds=703124385
- **Round.** 6 sections, an 8-minute timer and up to 100 coins (described as rough figures). Timer speed doubles for each player who reaches the top (Fandom per search snippet). https://bloxodes.com/articles/tower-of-hell-beginner-guide ; https://tower-of-hell.fandom.com/wiki/Lengthen
- **Content deck.** Each section has a name, color, difficulty and length that costs against the shared timer. The deck has 368 sections, with purist and secret pools. A fall restarts you, and the clock keeps running. https://bloxodes.com/wiki/tower-of-hell
- **Shop: 6 gears, all lasting one round.** https://bloxodes.com/wiki/tower-of-hell ; https://bloxodes.com/wiki/tower-of-hell/gears
  - Gravity Coil
  - Speed Coil: 90 coins on Noob Tower / 180 coins on Pro Tower, or 270 R$
  - Fusion Coil
  - Trowel
  - Hook
  - Hourglass (freezes moving parts)
- **Mutators: 12 server-wide modifiers that expire at round end.** https://bloxodes.com/wiki/tower-of-hell/mutators
  - Coin prices scale with tower length.
  - Extra Time: 50 / 86 coins.
  - High Speed: 100 / 160 coins.
  - Low Gravity: 130 / 220 coins.
  - Invincibility: 500 / 860 coins.
- **Passes (live).** Double Coins 195, Haunted Bundle 480, Halloween Coils Bundle 90. https://apis.roblox.com/game-passes/v1/universes/703124385/game-passes?passView=Full&pageSize=50
- **Seconds to play.** Joiners climb immediately because there is no lobby gate. The timer only gates the reset (inferred from the round description).

#### Feel and complaints
- **Feel.** Simple movement, killparts that are exact, and the shared timer with a doubling rush create tension. Sections are recognizable by color. https://bloxodes.com/wiki/tower-of-hell
- **Recent change.** A YouTube video is titled "TOWER OF HELL JUST CHANGED TO R15.. (Roblox Update)". The movement-feel change is a likely complaint point (inferred). https://www.youtube.com/results?search_query=roblox+tower+of+hell+2026
- **Low like ratio.** 73.6% is low for its size. Precision deaths with no checkpoints frustrate players (inferred). https://games.roblox.com/v1/games/votes?universeIds=703124385
- **Clones.** Tower of Misery positions itself as "Mega Easy" and openly "inspired by Tower of Hell". It holds 338 players versus ToH's 24,002. The original's network effect dominates (inferred). https://games.roblox.com/v1/games?universeIds=1701623492,703124385

---

### 3. Speed obby / +1 speed escape

#### Stats

| Game | Link | Visits | Like % | Playing | Peak (all-time) | Updated | Source URL | Seen |
|---|---|---|---|---|---|---|---|---|
| +1 Speed Keyboard Escape (SecretVerse Studio, created 2026-01-18, 22-player servers) | https://www.roblox.com/games/95082159892680 | 6,544,595,752 | 96.8% (9,997,332 / 330,912) | 58,893 | 6.8M (rotrends); 7.3M, Jul 2026 (rowatcher) | 2026-10-23 | https://games.roblox.com/v1/games?universeIds=9584852943 ; https://rotrends.com/game/9584852943 ; https://rowatcher.com/games/9584852943/1-speed-keyboard-escape | 2026-10-23 |
| Hyper Speed Runner (created 2026-01-02) | https://www.roblox.com/games/88933961678687 | 96,024,068 | 98.0% | 1,521 | 11.6K (rotrends); 12K, Mar 2026 (rowatcher) | 2026-04-11 | https://games.roblox.com/v1/games?universeIds=9485131494 ; https://rotrends.com/game/9485131494 ; https://rowatcher.com/games/9485131494/hyper-speed-runner | 2026-10-23 |
| +1 Speed Motorcycle Escape (created 2025-09-28) | https://www.roblox.com/games/106382577640892 | 71,810,534 | 78.6% | 430 | not fetched | 2026-10-08 | https://games.roblox.com/v1/games?universeIds=8826767123 | 2026-10-23 |
| +1 Speed Parkour Obby Escape (Pixel Gold, created 2026-06-11) | https://www.roblox.com/games/133457381057432 | 7,974,065 | 84.1% | 324 | 4K, Oct 2026 (rowatcher) | 2026-10-19 | https://games.roblox.com/v1/games?universeIds=10307582366 ; https://rowatcher.com/games/10307582366/1-speed-parkour-obby-escape | 2026-10-23 |

- One rowatcher page section for Keyboard Escape showed a stale summary (6,702 CCU, 84.77M visits). I used only its structured "All-time peak players" line. https://rowatcher.com/games/9584852943/1-speed-keyboard-escape

#### Loop
- **Keyboard Escape loop.** https://allthings.how/1-speed-keyboard-escape-how-to-build-speed-farm-wins-and-rebirth/
  - Every step adds +1 Speed, and speed thresholds raise your level.
  - The world has 13 stages. Later jumps are longer, bridges vanish seconds after you reach them, and faster "brainrot" enemies chase you.
  - Wins come only from yellow pads after a stage, which bank the Wins and teleport you back to spawn.
  - Wins buy Trails, Auras and stage teleports.
  - Rebirth resets your level for a permanent multiplier.
  - A treadmill sits in every safe zone for AFK farming.
  - There is no tutorial.
- **Keyboard Escape free speed.** A like, a group join and the social code each grant 15,000 speed. https://allthings.how/1-speed-keyboard-escape-how-to-build-speed-farm-wins-and-rebirth/
- **Keyboard Escape stage teleports cost Wins or Robux,** from 2 Wins / 3 R$ for stage 2 up to 20,000 Wins / 99 R$ for stage 13. https://allthings.how/1-speed-keyboard-escape-how-to-build-speed-farm-wins-and-rebirth/
- **Keyboard Escape trails multiply speed gain.** https://allthings.how/1-speed-keyboard-escape-how-to-build-speed-farm-wins-and-rebirth/
  - Green 1.5x (500 Wins / 19 R$)
  - Rainbow 5x (100,000 Wins / 249 R$)
  - Galaxy 10x (399 R$, Robux only)
  - Choco 20x (499 R$, Robux only)
  - Treadmills: free 1x, Diamond 9x, Admin 100x (Robux).
- **Keyboard Escape juice.** "ASMR vibes... satisfying keyboard clicks". Seasonal reskins (Halloween world, previously Easter). https://games.roblox.com/v1/games?universeIds=9584852943 ; https://www.youtube.com/results?search_query=roblox+%2B1+speed+keyboard+escape
- **+1 Speed Parkour Obby Escape.** Treadmill for speed, then parkour through stages for trophies and new shoes. Controls: double jump, dash, slide and super jump. https://games.roblox.com/v1/games?universeIds=10307582366
- **Hyper Speed Runner.** EXP-to-speed levels, AFK treadmills, races, and a 50% EXP boost for Premium. https://games.roblox.com/v1/games?universeIds=9485131494
- **Seconds to play.** Effectively 0, since you spawn and run with no rounds. This, plus AFK treadmills that pad session time, likely explains the CCU (inferred).

#### Monetization and complaints
- **PREDATORY / WHALE FLAG: Keyboard Escape** sells many cosmetic-plus-multiplier Robux passes: Ascendant Trail 2645, Transcendant 2350, Celestial 2200, Wild Trail/Aura 1999, ADMIN Treadmill 1199, plus Speed Multiplier tiers up to 12. Small kids can spend a lot (inferred). https://apis.roblox.com/game-passes/v1/universes/9584852943/game-passes?passView=Full&pageSize=50
- **Other complaint signals.** "Modded +1 speed keyboard escape" and "Unlimited rainbow keys" videos (311K and 102K views) suggest an exploit and hack culture around the stat. https://www.youtube.com/results?search_query=roblox+%2B1+speed+keyboard+escape
- **Why clones flop (inferred).** The genre is a template (a "+1 Slide Speed Obby Escape" kit is sold on BuiltByBit). Clones with no hook (theme, ASMR, brainrot enemies) stall at a few hundred CCU, like Parkour Obby Escape at 324 and Motorcycle Escape at 430. https://builtbybit.com/resources/1-slide-speed-obby-escape.114868/ ; API table above

---

### Cross-family takeaways (all inferred unless cited)
- **The classic round-based lava game is stable but small:** about 1.5K CCU, peaks of 14-35K. The 2026 breakouts paired a rising hazard or speed with collect, upgrade and rebirth loops. Peaks: Tsunami 4-5M, Keyboard Escape 6.8-7.3M (tracker pages cited above).
- **The powers in these games are all paid passes.** Double jump, shield and grapple are Robux passes in Floor Is LAVA and Tsunami For Brainrots. A fair version where crowns earn powers, with cooldowns, would be differentiated. It must avoid the "unwinnable without gear" complaint (namu.moe link above).
- **Must-haves:**
  - Client-simulated lava driven by a server clock (DevForum links above).
  - A short pre-round screen of 3-5 s, and a spawn mini-obby during intermission.
  - Varied maps with destructible structures.
  - Spectate.
  - Strip players from the alive table on death or leave.
- **Avoid loot-box style Spins, Lucky Blocks and Server Luck** if targeting kids ethically. These are prevalent in the brainrot lava hybrids (dev product links above).


---

## Arena families: color block, disasters, king of the hill, spleef, red light green light, sumo

### Method and sources

- **Candidates:** Roblox omni-search (`https://apis.roblox.com/search-api/omni-search?searchQuery=<q>&sessionId=abc&pageType=all`), queried 2026-10-23 for: color block, musical floor, block party, color tiles, natural disaster survival, survive the disasters, disasters, king of the hill, koth, hill, crown battle, block drop, spleef, falling tiles, tile drop, red light green light, glass bridge, sumo, sumo battle, push off, knockout, bumper, slap battles.
- **Universe IDs:** taken from omni-search. Spot-checked with `https://apis.roblox.com/universes/v1/places/<placeId>/universe`: 5926001758 returned 2126386806 and 136764190843219 returned 9384605736, both matching.
- **Live stats:** `https://games.roblox.com/v1/games?universeIds=<id>` (visits, playing, updated, maxPlayers). Like % = up/(up+down) from `https://games.roblox.com/v1/games/votes?universeIds=<id>`. Pulled 2026-10-23 ~07:45 UTC.
- **Peaks:**
  - **"RT all-time"** is the `alltime_peak_ccu` field on `https://www.rotrends.com/game/<universeId>`.
  - **"RW Jun–Oct"** is the highest *sampled* point in `https://rowatcher.com/api/games/<universeId>/history?from=2026-06-01T00:00:00Z&to=2026-10-23T08:00:00Z`. The series is downsampled to about 600 points, so the true peak may be higher. RoWatcher's tracking began about 2026-06-30, and earlier points cluster around 2026-06-06/07.
  - Both were pulled 2026-10-23.
- **Session length:** "Sess" is `est_avg_session_duration_naive` (seconds) from the same RoTrends page.
- **Monetization:**
  - Game passes come from `https://apis.roblox.com/game-passes/v1/universes/<id>/game-passes?passView=Full&pageSize=50`.
  - Developer products come from the RoTrends page's `dev_products`. Some product names come back localized (Polish).
- **Sources that failed:**
  - romonitorstats.com (`/experience/<placeId>/`) is a JS shell with no stats in the HTML.
  - rotrends `/games/<id>` returns 404. The working path is `/game/<id>`.
  - rowatcher.com game pages are a JS SPA. Its `/api` endpoint works.
  - The NDS fandom page returned HTTP 402 through WebFetch, so I used its MediaWiki API instead.
  - WebFetch and WebSearch both returned "session limit" partway through, so qualitative sources were limited to fandom wikis (MediaWiki API), DevForum (Discourse JSON) and game descriptions from the API.
- **Not found:** exact intermission and round lengths for most games aren't published anywhere I could reach. Where a number is missing, I say so. Anything marked "inferred" is my judgment, not a sourced fact.

---

### 1. Color block / musical floor (stand on the called color)

| Game | Link | Visits | Like % | Playing | Peak | Updated | Source URL | Seen |
|---|---|---|---|---|---|---|---|---|
| Color Block | https://www.roblox.com/games/5926001758 | 2,682,639,514 | 84.6% | 596 | RT all-time 22,498; RW Jun–Oct 4,297 (2026-07-29) | 2026-05-08 | https://games.roblox.com/v1/games?universeIds=2126386806 ; https://www.rotrends.com/game/2126386806 | 2026-10-23 |
| Musical Chairs 🎵🪑 (adjacent: "music stops, reach a target") | https://www.roblox.com/games/113323927469374 | 540,321,772 | 66.4% | 1,596 | RT all-time 33,241; RW Jun–Oct 12,321 (2026-10-08) | 2026-10-14 | https://games.roblox.com/v1/games?universeIds=6688157118 ; https://www.rotrends.com/game/6688157118 | 2026-10-23 |
| Falling Color Block (hybrid with family 4) | https://www.roblox.com/games/6211217272 | 149,649,426 | 69.2% | 185 | RT all-time 1,044; RW Jun–Oct 805 (2026-08-14) | 2026-10-20 | https://games.roblox.com/v1/games?universeIds=2278167893 ; https://www.rotrends.com/game/2278167893 | 2026-10-23 |

Excluded: "Color Game! 🎨" (201.7M visits, 250 playing). Its description is territory painting ("spread your color across the board"), not called-color survival (https://games.roblox.com/v1/games?universeIds=7289427971).

- **Round loop:**
  - Color Block's rules: a color is shown, you run to it, anyone on the wrong color when time runs out is eliminated, and the last player standing wins (description, https://games.roblox.com/v1/games?universeIds=2126386806). Servers hold 12.
  - Color Block 2's page says each round picks a color you must stand on in time, and rounds "progressively get more difficult" (https://roblox.com/games/6122489999/Color-Block-2, via search result).
  - Per-call timer is said to be 5–8 s, cut to 3–4 s in Speed Mode, with 10 colors including 3–4 confusable pairs. This is **unverified**: the source is a free-Robux site (https://earnaldo.com/blog/color-block-free-robux-guide).
  - Intermission and results durations: not found.
  - Session length is about 452 s for Color Block, 467 s for Musical Chairs and 456 s for Falling Color Block (RoTrends pages above).
- **Musical Chairs loop:** run around the chairs and find a seat when the music stops; anyone without a seat is out; last alive wins (https://games.roblox.com/v1/games?universeIds=6688157118). Its products show which knobs are part of the loop: "Reveal Timer" 9 R$, "Delay Song" 15, "Buy Next Song" 35, "Choose Next Map" 30, "Fake Stop" 15, "Extra Chair" 15, "Revive" 19, "First Revive" 9 (https://www.rotrends.com/game/6688157118).
- **What makes it smooth (inferred from the mechanics above):**
  - The rule fits in one line.
  - Each call is a few seconds, so dying costs little.
  - Shrinking reaction windows give the round an arc.
  - A colorblind mode matters, since the confusable pairs are real (earnaldo above, unverified).
  - Color Block added a "riding mode" (description).
- **Progression:**
  - Color Block sells cosmetics: trails 199–299 R$, wings, pets, plus "+1 Pets Slots" 199 and Money/Coins packs from 10 to 1,499 R$ (https://apis.roblox.com/game-passes/v1/universes/2126386806/game-passes?passView=Full&pageSize=50 ; https://www.rotrends.com/game/2126386806).
  - Musical Chairs has coins for pets, trails and chair skins, extra coins per win for Premium (description), and a Season Pass at 199 / Complete Season Pass at 799 (RoTrends).
- **Monetization flags:**
  - **PREDATORY — Musical Chairs pay-to-grief:** "Kill All" 65, "Jail All" 59, "Fling All" 39, "Freeze All" 39, "Blind All" 49, "Delete Chairs" 49, "NUKE" 199, "Fake Stop" 15, consumable packs ("+10 Blind/Freeze/Slip/Slow" 390 each), plus the pass "Music Timer" 99, which shows when the music stops and is a pay-to-win information edge (https://www.rotrends.com/game/6688157118 ; https://apis.roblox.com/game-passes/v1/universes/6688157118/game-passes?passView=Full&pageSize=50).
  - Musical Chairs also sells "10 Hours AFK Luck" at 999 and 10 Exclusive Crates at 899 (lootboxes).
  - Color Block is mostly cosmetic; there is a "Gears of War" pass at 399 (game-pass API above).
- **Complaints and why clones flop:**
  - Musical Chairs has the lowest like ratio of these top games (66.4%) despite high CCU (API). Paid "Kill All" and "Fake Stop" are the obvious suspects (inferred).
  - Color Block's last update was 2026-05-08, and RW's Jun–Oct high is 4,297 against an all-time 22,498, so it is coasting on legacy (API + RoTrends; trend reading inferred).
  - Clones: omni-search shows many near-zero copies, e.g. "Color Block Party" with 0 playing and 25 likes, and "Color Block Tower!" with 21 playing (omni-search "block party" / "color block", 2026-10-23). A one-line loop is trivial to copy, so a copy needs players to work; see the DevForum critical-mass post in Cross-family.

---

### 2. Survive the disasters / natural disaster survival

| Game | Link | Visits | Like % | Playing | Peak | Updated | Source URL | Seen |
|---|---|---|---|---|---|---|---|---|
| Natural Disaster Survival | https://www.roblox.com/games/189707 | 4,521,840,347 | 90.8% | 4,741 | RT all-time 98,735; RW Jun–Oct 52,291 (2026-09-18, the day after the 09-17 update) | 2026-09-17 | https://games.roblox.com/v1/games?universeIds=65241 ; https://www.rotrends.com/game/65241 ; https://rowatcher.com/api/games/65241/history | 2026-10-23 |
| What If Disasters (created 2026-10-05) | https://www.roblox.com/games/109440485612336 | 2,629,625 | 90.4% | 6,473 | RT all-time 8,878; RW 8,511 (2026-10-22) | 2026-10-23 | https://games.roblox.com/v1/games?universeIds=10769484703 ; https://www.rotrends.com/game/10769484703 | 2026-10-23 |
| Disaster Island 🏝️ Survival | https://www.roblox.com/games/14833592591 | 158,243,121 | 92.3% | 990 | RT all-time 20,265; RW Jun–Oct 4,581 (2026-09-20) | 2026-09-16 | https://games.roblox.com/v1/games?universeIds=5111507958 ; https://www.rotrends.com/game/5111507958 | 2026-10-23 |

Fading legacy title: Survive The Disasters 2 has 58.7M visits, 88.7% likes and 15 playing; its RW Jun–Oct high is 198 (https://games.roblox.com/v1/games?universeIds=85651869).

- **Round loop:**
  - Players are teleported to a map, a warning card names the disaster, the disaster plays out, and survivors return to the **Lobby Tower**. The tower overlooks the island, so spectating is passive and free; the exception is Blizzard or Sandstorm, which blocks the view (https://natural-disaster-survival.fandom.com/wiki/Lobby_Tower).
  - Dead players also go back to the lobby, which makes it double as the waiting room (same).
  - Telegraphing: some disasters show cues before the warning. Acid Rain has a wind track, Avalanche a rock slant, Blizzard and Sandstorm a thickening haze, storms cloudy weather. The volcano spawns with the warning card and erupts 15 s later (https://natural-disaster-survival.fandom.com/wiki/Disasters).
  - Thunderstorm lightning strikes about every 2 s (same).
  - Intermission and round lengths are not published on the wiki pages I could reach.
  - What If Disasters advertises 25 disasters and 9 maps (description, https://games.roblox.com/v1/games?universeIds=10769484703).
  - Session length: NDS ~522 s, Disaster Island ~875 s, What If ~940 s (RoTrends).
- **What makes it smooth:**
  - Passive spectating from the tower.
  - Map and weather foreshadowing gives skill expression in reading the disaster early (wiki above).
  - Servers hold 30 in NDS and Disaster Island and 20 in What If (API).
  - Physics destruction is the spectacle, and it is also the performance risk. DevForum threads on NDS-style games cover gradual map loading and lag from unanchoring many parts (https://devforum.roblox.com/t/how-is-it-possible-to-load-maps-gradually-like-in-natural-disaster-survival-and-other-games/4808503/1 ; https://devforum.roblox.com/t/how-to-make-parts-that-fall-from-a-height-during-an-earthquake-deal-damage-to-a-player-efficiently/2738142/2).
- **Progression:**
  - NDS is famously thin: three gear passes, Green Balloon 95, Red Apple 80 and Yellow Compass 60 (https://apis.roblox.com/game-passes/v1/universes/65241/game-passes?passView=Full&pageSize=50), plus small "Power Up machine" products from 10 to 140 R$ (names localized, https://www.rotrends.com/game/65241).
  - Survive The Disasters 2: survive to earn coins, buy and upgrade gear, 2x coins on Fridays and Saturdays (description).
  - What If Disasters: Credits packs from 49 to 999 R$, 2x XP timers from 19 to 129 R$, and gift variants (RoTrends).
- **Monetization flags:**
  - Mild. Disaster Island's VIP is 449 and its Crowbar 300 (https://apis.roblox.com/game-passes/v1/universes/5111507958/game-passes?passView=Full&pageSize=50).
  - NDS private-server "Round Control" lets the host pick map and disaster and pause or skip rounds; the wiki gives its cost as 300 Robux (https://natural-disaster-survival.fandom.com/wiki/Round_Control).
  - Balloon and coil passes make some disasters easier (inferred: mild pay-to-survive).
- **Complaints and why clones flop:**
  - A DevForum reply notes the old NDS was uncopylocked, which is "why you see so many clones of the original that don't work" (https://devforum.roblox.com/t/a-remake-of-maps-from-natural-disaster-survival/1546829/8).
  - Exploit and lag complaints: servers crashed by UGC animation spam in NDS (https://devforum.roblox.com/t/spamming-ugc-animations-can-crash-entire-servers/4200275/1).
  - What If Disasters shows the current playbook. It went from creation on 10-05 to 6.5k CCU with 2.6M visits in 18 days, using a "WHAT IF" spectacle hook and a fresh disaster list (API; reading inferred).

---

### 3. King of the hill

| Game | Link | Visits | Like % | Playing | Peak | Updated | Source URL | Seen |
|---|---|---|---|---|---|---|---|---|
| King Tower! (climb + knock down) | https://www.roblox.com/games/83556772114521 | 17,207,177 | 82.2% | 191 | RT all-time 3,972; RW Jun–Oct 2,635 (2026-06-07) | 2026-10-21 | https://games.roblox.com/v1/games?universeIds=9882110948 ; https://www.rotrends.com/game/9882110948 | 2026-10-23 |
| 👑 Crown Divers (hold the crown) | https://www.roblox.com/games/17322888048 | 29,053,561 | 71.8% | 20 | RT all-time 1,145; RW Jun–Oct 161 | 2026-10-09 | https://games.roblox.com/v1/games?universeIds=5926943574 ; https://www.rotrends.com/game/5926943574 | 2026-10-23 |
| King Of The Hill 👑 (red vs blue, new) | https://www.roblox.com/games/82590268023833 | 2,589 | 52.6% | 0 | not tracked/no data pulled | 2026-10-20 | https://games.roblox.com/v1/games?universeIds=10769172773 | 2026-10-23 |

- **Genre health (inferred):** there is no breakout standalone KotH. Omni-search for "king of the hill", "koth" and "hill" returned no game above ~200 CCU with that core (omni-search 2026-10-23). KotH mostly lives as a mode inside minigame anthologies; for example, Epic Minigames' KotH mode uses a ban hammer (https://devforum.roblox.com/t/ban-hammer-for-king-of-the-hill-game/1066530/1). One DevForum poster calls KotH and CTF "used too much" as voting modes (https://devforum.roblox.com/t/what-are-some-good-game-mode-ideas/1234658/1).
- **Round loop:**
  - King Tower!: climb the tower, knock others down, become king (description). It sells OP classes, Vampire and Frost Sorcerer, at 500 each (game-pass API).
  - Crown Divers: chase and steal the crown to build CrownTime. Controls are double jump, dive (Q/LT/RT) and camera lock (LShift/Y). Several maps, 30+ free emotes, a global CrownTime leaderboard, weekend 2x coins (description).
  - Round lengths: not found. Session length: King Tower ~875 s, Crown Divers ~615 s (RoTrends).
- **Smooth factors (inferred):** a crown or top marker readable from anywhere, a dive or knockback verb, and a timed tally (CrownTime) rather than first-to-touch.
- **Monetization flags:**
  - **PREDATORY — Crown Divers:** buyable "NUKE!" 30, "Missile" 15 and "Change Map" 20 directly disrupt other players (https://www.rotrends.com/game/5926943574).
  - **King Tower!:** "[OP]" classes at 500 R$ are pay-to-win by their own label (https://apis.roblox.com/game-passes/v1/universes/9882110948/game-passes?passView=Full&pageSize=50); also Gold packs up to 10000 Gold = 3,750 R$ (RoTrends).
- **Why it flops (inferred):**
  - Snowballing, where the holder keeps winning, plus pay-to-win classes.
  - It needs a dense server to be fun, while these servers average far below their 10–30 caps.
  - Crown Divers is at 20 CCU against a 1,145 all-time peak (API + RoTrends).

---

### 4. Block drop / spleef (floor tiles fall)

| Game | Link | Visits | Like % | Playing | Peak | Updated | Source URL | Seen |
|---|---|---|---|---|---|---|---|---|
| Rocket Spleef 💥 | https://www.roblox.com/games/126857641130765 | 27,833,762 | 87.9% | 227 | RT all-time 3,978; RW Jun–Oct 2,616 (2026-08-14) | 2026-09-24 | https://games.roblox.com/v1/games?universeIds=9903685259 ; https://www.rotrends.com/game/9903685259 | 2026-10-23 |
| Falling Color Block | https://www.roblox.com/games/6211217272 | 149,649,426 | 69.2% | 185 | RT all-time 1,044; RW 805 | 2026-10-20 | https://games.roblox.com/v1/games?universeIds=2278167893 | 2026-10-23 |
| [🍂] Fading Blocks (hex-a-gone style) | https://www.roblox.com/games/119075643463778 | 23,739,114 | 58.7% | 17 | RT all-time 1,819; RW 171 | 2026-09-12 | https://games.roblox.com/v1/games?universeIds=7347621592 ; https://www.rotrends.com/game/7347621592 | 2026-10-23 |

- **Round loop:**
  - Rocket Spleef: rockets destroy the floor, last alive wins. It has pickups (Rapid Fire, Triple Shot, Low Gravity, Lifeline, Mega Rocket), ledge grab (hold jump near an edge) and rocket jump (shoot below, then jump) (description). Servers hold 12.
  - Falling Color Block: run, jump, don't fall, last one wins (description).
  - Fading Blocks: hex-a-gone or disappearing-tiles style, with private-server admin (description).
  - Round lengths: not found. Session length: Rocket Spleef ~659 s, Falling Color Block ~456 s, Fading Blocks ~470 s (RoTrends).
- **Smooth factors:**
  - The ledge grab and Lifeline pickup give second chances, which reduces the sting of falling (description).
  - Pickups keep the middle of a round varied (description).
  - Telegraphed tile decay (yellow, orange, red, collapse) is the proven pattern in Knockout's Penguin Peak map (https://knockout-roblox.fandom.com/wiki/Penguin_Peak), and it applies directly here (inferred).
- **Progression:** Rocket Spleef has Voxels currency, crates, and launcher, trail and explosion cosmetics; passes Instant Spin 79, Double Luck 189, VIP 249, 2x Voxels 149; Voxel packs from 29 to 799 R$ (https://apis.roblox.com/game-passes/v1/universes/9903685259/game-passes?passView=Full&pageSize=50 ; RoTrends).
- **Monetization flags:**
  - **PREDATORY — Fading Blocks sells wins:** "+1 Win" 5 R$ up to "+100 Wins" 249 R$, which corrupts any wins leaderboard (https://www.rotrends.com/game/7347621592).
  - Falling Color Block is cosmetic-only plus donations; it has no game passes (game-pass API returned empty; RoTrends lists 84 products).
- **Complaints and why clones flop:**
  - Fading Blocks has a 58.7% like ratio and Falling Color Block 69.2% (votes API).
  - Rocket Spleef, the one with an active verb (shooting the floor) rather than passive falling, holds 87.9% (inferred: an agency gap).
  - Indie spleef projects are still being started, e.g. "Explosive Spleef: Reverb" devlogs (https://devforum.roblox.com/t/explosive-spleef-reverb-devlogs/4746414/1).

---

### 5. Red light, green light

| Game | Link | Visits | Like % | Playing | Peak | Updated | Source URL | Seen |
|---|---|---|---|---|---|---|---|---|
| [⚔️] Ink Game (Squid Game anthology) | https://www.roblox.com/games/99567941238278 | 3,361,774,404 | 79.2% | 7,704 | RT all-time 810,470; RW Jun–Oct 62,529 (2026-07-26) | 2026-10-22 | https://games.roblox.com/v1/games?universeIds=7008097940 ; https://www.rotrends.com/game/7008097940 | 2026-10-23 |
| [🦑] Squid Game X | https://www.roblox.com/games/7554888362 | 2,313,100,297 | 93.7% | 12,651 | RT all-time 154,098; RW Jun–Oct 31,558 (2026-09-06) | 2026-10-22 | https://games.roblox.com/v1/games?universeIds=2936053166 ; https://www.rotrends.com/game/2936053166 | 2026-10-23 |
| Impossible Red Light, Green Light! (obby variant) | https://www.roblox.com/games/9817495903 | 152,725,730 | 60.6% | 20 | RT all-time 6,128; RW 35 | 2025-10-26 | https://games.roblox.com/v1/games?universeIds=3631776461 ; https://www.rotrends.com/game/3631776461 | 2026-10-23 |

- **Genre note (inferred):** standalone RLGL is dead. RLGL survives as game 1 of Squid Game anthologies with 80–100-player servers (API maxPlayers: 80 and 100).
- **Round loop:**
  - Squid Game X RLGL: 2 minutes to cross the field. The doll turns and calls "Red Light", and anyone moving is shot. Each hit slows you, and the third hit eliminates (https://squid-game-x.fandom.com/wiki/RedLight_GreenLight).
  - Squid Game X's other modes: Honeycomb, Pentathlon, Hide & Seek, Musical Chairs, Jump Rope, Sky Squid, Mingle, Night Brawl, Rebellion, Tug of War, Marbles, RPS Minus One, Glass Bridge, Final Dinner (description).
  - Ink Game: RLGL is the first game. Pushing requires the SUPER PUSH gamepass, injured players can be carried to safety, and Medic carries faster (https://ink-game.fandom.com/wiki/Red_Light,_Green_Light). There are 3 endings: Rebel, Final Fight, Sky Squid (description).
  - Session length: Ink Game ~941 s, Squid Game X ~523 s, Impossible RLGL ~251 s (RoTrends).
  - Fairness tip: a DevForum dev adds a 1 s grace before checking movement on red (https://devforum.roblox.com/t/wait-only-working-once/3046147/1).
- **Smooth factors:**
  - Three hits instead of instant death softens latency unfairness (SGX wiki above).
  - Ink Game has carry/rescue for social play and a "rebel" alternate ending (wiki and description).
  - Mobile is supported: Ink Game says it works on PC, console and mobile (description).
- **Progression:**
  - Ink Game: Power Rolls at R$175 each or R$1,699 for 10, also earned via endings or 6 h in AFK World. Powers are rarity-weighted, e.g. COMMON at 72% (https://ink-game.fandom.com/wiki/Powers ; https://ink-game.fandom.com/wiki/Player_120).
  - Ink Game: Super Strength gives 3x push distance (https://ink-game.fandom.com/wiki/Super_Strength).
  - Ink Game: Sharpshooter comes from a 30-day login or a 799 R$ "all rewards" purchase (https://ink-game.fandom.com/wiki/Sharpshooter).
- **Monetization flags:**
  - **PREDATORY — Ink Game:**
    - Gacha Power Rolls with combat-affecting powers (wiki above).
    - Pushing behind the SUPER PUSH paywall (wiki).
    - Donation products up to **100,000 R$** (https://www.rotrends.com/game/7008097940).
    - Guard role 799 and "2x Vote Count" 249 (https://apis.roblox.com/game-passes/v1/universes/7008097940/game-passes?passView=Full&pageSize=50).
  - **PREDATORY — Squid Game X:** "Permanent Extra Life!" 399, "Extra Speed" 249, Frontman 2,499, Detective 1,799, Guard 1,499 (https://apis.roblox.com/game-passes/v1/universes/2936053166/game-passes?passView=Full&pageSize=50).
  - Impossible RLGL sells consumable "+Lives" from 9 R$ and "+Pushes" from 9 R$ (RoTrends).
- **Complaints:** Ink Game's like ratio is 79.2% against Squid Game X's 93.7% (votes API). Ink Game's description warns cheaters of permanent bans (description).

---

### 6. Sumo / push-off-the-platform

| Game | Link | Visits | Like % | Playing | Peak | Updated | Source URL | Seen |
|---|---|---|---|---|---|---|---|---|
| [🎩] Knockout! 🐧 | https://www.roblox.com/games/136764190843219 | 1,052,411,273 | 96.1% | 666 | RT all-time 620,670; RW Jun–Oct 17,203 (2026-06-06) | 2026-10-22 | https://games.roblox.com/v1/games?universeIds=9384605736 ; https://www.rotrends.com/game/9384605736 | 2026-10-23 |
| [🎃UPD] Bumper Balls🟡 | https://www.roblox.com/games/75056101860138 | 11,081,659 | 88.1% | 45 | RT all-time 3,721; RW 1,953 (2026-07-27) | 2026-10-22 | https://games.roblox.com/v1/games?universeIds=10187488536 ; https://www.rotrends.com/game/10187488536 | 2026-10-23 |
| Sumo Wrestling Simulator (simulator, not pure rounds) | https://www.roblox.com/games/14021953565 | 90,592,406 | 88.9% | 60 | RT all-time 9,620; RW 909 | 2026-10-13 | https://games.roblox.com/v1/games?universeIds=4857352699 ; https://www.rotrends.com/game/4857352699 | 2026-10-23 |

Adjacent, and not round-based: Slap Battles has 3,668,394,162 visits, 86.1% likes, 4,488 playing and an RT all-time peak of 144,538 (https://games.roblox.com/v1/games?universeIds=2380077519 ; https://www.rotrends.com/game/2380077519).

- **Round loop (Knockout!):**
  - Each turn gives a **7-second** aim window (https://knockout-roblox.fandom.com/wiki/Strategy_and_Techniques).
  - Everyone aims angle and power hidden from others; when the countdown ends, all penguins launch at once (https://knockout-roblox.fandom.com/wiki/Guides).
  - The platform shrinks each turn, and players too close to an edge are auto-moved to safety before it shrinks (Guides).
  - **Sudden-death cap:** the match ends at last penguin, no penguins, or round 11 without a winner (Guides).
  - Modes: FFA, 2 Teams, Hot Potato (https://knockout-roblox.fandom.com/wiki/Saint_Patrick's_Update).
  - Penguin Peak map: tiles heat yellow, then orange, then red, and collapse after a round (https://knockout-roblox.fandom.com/wiki/Penguin_Peak).
  - Servers hold 12. Session length ~543 s (API ; RoTrends).
- **Why Knockout! feels smooth (inferred from the sourced mechanics):**
  - Simultaneous turns remove latency and aim-skill gaps, which is mobile-friendly and lag-proof.
  - The 7 s decisions keep downtime tiny.
  - The guaranteed 11-turn cap bounds match length.
  - Telegraphed tile decay.
  - Edge auto-rescue avoids cheap deaths.
- **Bumper Balls:** bump players off the platform to win (description). Servers hold 12; session ~489 s (RoTrends).
- **Progression:**
  - Knockout!: Ice from daily and weekly tasks, KOs, assists, wins, an obby and a wheel. Ice buys eggs that give cosmetic skins, and Tokens are used for player trading (Guides).
  - Sumo Sim: eat, train, pets, worlds (description).
- **Monetization flags:**
  - **Knockout!:** lootbox eggs and crates (99 R$ each), Trade Tokens sold up to **10,000 R$**, season premium passes 79–499, 2x Ice 499 (https://www.rotrends.com/game/9384605736 ; https://apis.roblox.com/game-passes/v1/universes/9384605736/game-passes?passView=Full&pageSize=50). Gameplay itself stays cosmetic-only (Guides). Flag: the paid trading economy and gacha.
  - Bumper Balls sells Trade Tokens up to 2,500 R$ (RoTrends).
- **Complaints and why clones flop:**
  - Knockout! hit 620,670 CCU (RT all-time) but is now at 666, while still holding 96.1% likes (API + RoTrends).
  - Pattern: a viral spike that decays, with likes intact (inferred: novelty decay rather than dissatisfaction).
  - Knockout! clones flooded omni-search under "push" and "sumo", e.g. "Boom Sumo" at 0–1 playing and 57.8% likes (omni-search 2026-10-23 ; https://games.roblox.com/v1/games?universeIds=6195229367).

---

### Cross-family design notes (DevForum)

- **Intermission guidance:** devs suggest 15–35 s, with one example of 30 s split into 10 s results and 20 s voting (https://devforum.roblox.com/t/ideal-intermission-time/724439/1). Another dev cites 15 s with an explorable lobby (https://devforum.roblox.com/t/are-round-based-games-still-worth-creating/93385/11).
- **Mid-round joins:** a 10-minute round can leave new joiners waiting about 9 minutes, and devs asked Roblox for a way to deprioritize such servers for new players (https://devforum.roblox.com/t/allow-developers-to-mark-servers-as-unpreferred-for-new-player-joins/3680997/1). This argues for short rounds or join-in-progress spectate (inferred).
- **Critical mass:** round games fail at low CCU. Keeping lone players "busy" while they wait doesn't fix it (https://devforum.roblox.com/t/how-do-you-prevent-players-from-leaving-a-round-based-game/4671460/3), and a reply claims sponsored ads are required to reach a baseline (same thread, #6).
- **Progression tension:** progression in a minigame game can make it too easy and kill the fun (https://devforum.roblox.com/t/player-progression-in-a-minigame-styled-game/297039/6).
- **Fairness:** devs report RNG rounds feel unfair (https://devforum.roblox.com/t/making-rounds-less-rng-and-more-skill-based/584897/1).

---

## Engineering, kids policy and Steam themes
Date seen for all sources: 2026-10-23. Roblox docs were read live on create.roblox.com and also from the docs source repo (https://github.com/Roblox/creator-docs, CC-BY-4.0, last commit 2026-10-22). Anything marked **(inferred)** is my judgment, not a quoted fact. I did not guess any numbers.

---
### A. Engineering

#### A1. Hard platform numbers (all official)
| Item | Number | Source |
|---|---|---|
| Server heartbeat cap | 60 FPS for all games | https://create.roblox.com/docs/performance-optimization/identify |
| Server memory | 6.25 GiB + 100 MiB x peak connected players (30 players ≈ 9.18 GiB). Keep usage below 50%. Memory does not shrink when players leave | same |
| Client FPS cap | default 60, up to 240 on Windows | same |
| Physics stepping | adaptive 60/120/240 Hz; Fixed mode forces 240 Hz | https://create.roblox.com/docs/performance-optimization/improve |
| Client→server remote rate limit | about 500 req/s per client, shared across all RemoteEvents (and separately across all UnreliableRemoteEvents) | https://create.roblox.com/docs/reference/engine/classes/RemoteEvent |
| UnreliableRemoteEvent payload | events over 1000 bytes are dropped | https://create.roblox.com/docs/reference/engine/classes/UnreliableRemoteEvent |
| Max players vs voice | voice chat needs place Max Players ≤ 100 | https://create.roblox.com/docs/chat/voice-chat |
| MaxPlayers / PreferredPlayers | set only in Creator Dashboard place settings. The matchmaker fills servers to PreferredPlayers (< MaxPlayers) | https://create.roblox.com/docs/reference/engine/classes/Players |
| OrderedDataStore | stored values must be integers. GetSortedAsync page size is 1–100 | https://create.roblox.com/docs/reference/engine/classes/OrderedDataStore , https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits |
| Data store per-server limits (req/min) | Read 60+40·N. Standard write 60+40·N. **Ordered write 30+5·N**. List 5+2·N. Ordered remove 30+5·N. UpdateAsync counts against both read and write | error-codes-and-limits (above) |
| Data store experience limits (req/min) | read 300+40·CCU, write 300+20·CCU, list 300+2·CCU | same |
| Data store sizes | name/key/scope 50 chars; value 4,194,304 chars; per-key throughput 25 MB/min read, 4 MB/min write | same (the page states no "6-second per-key cooldown", so don't rely on one) |
| MemoryStore | memory 64 KB + 1.2 KB x users. Requests 1,000 + 120 x CCU per minute. Item ≤ 32 KB. Expiry ≤ 3,888,000 s (45 days). A queue uses a single partition (throttling at about 30k units/min) | https://create.roblox.com/docs/cloud-services/memory-stores |
| Textures | most images ≤ 512x512; minor ones < 256x256 | improve page |

Worked example for a 30-player server **(inferred arithmetic from the formulas above)**: the ordered write budget is 30+5·30 = 180/min per server. Writing a "wins" OrderedDataStore entry for each player at round end is about 30 writes per round. With 2-minute rounds that is about 15/min, which is fine. Write once at round end, never on every tag.

#### A2. Round state machine (lobby → intermission → round → sudden death → results)
- Classic community tutorial (DevForum, 197 likes, 2020): intermission 20 s → pick a map → assign roles → 200 s round → clean up and teleport back. The round is skipped when fewer than 2 players are present. https://devforum.roblox.com/t/487712
- Retention warning from a 2026 DevForum thread (30 likes): the poster says players "often leave the game after 1 round or even half a round", about 6 minutes in. https://devforum.roblox.com/t/4664307 . **(inferred)** Keep rounds at 60–150 s, intermission at 10–20 s, and results at 8 s or less.
- Pattern **(inferred, my code)**: one server module owns the state. It sets attributes (`State`, plus `EndsAt` as server Unix time) on a ReplicatedStorage folder, and each client draws its own timer. Workspace:GetServerTimeNow() gives all clients roughly the same server time (https://create.roblox.com/docs/reference/engine/classes/Workspace).
```lua
-- ServerScriptService/RoundService (inferred pattern)
local DUR = {Intermission=15, Round=120, SuddenDeath=30, Results=8}
local rs = game.ReplicatedStorage.RoundState -- Folder holding attributes
local function setState(s, dur)
  rs:SetAttribute("State", s)
  rs:SetAttribute("EndsAt", dur and workspace:GetServerTimeNow() + dur or 0)
end
while true do
  setState("Lobby"); repeat task.wait(1) until #game.Players:GetPlayers() >= 2
  setState("Intermission", DUR.Intermission); task.wait(DUR.Intermission)
  Round.start()                                   -- spawn map, build alive set
  setState("Round", DUR.Round)
  local t0 = os.clock()
  while os.clock() - t0 < DUR.Round and Round.aliveCount() > 1 do task.wait(0.25) end
  if Round.aliveCount() > 1 then setState("SuddenDeath", DUR.SuddenDeath); Round.suddenDeath() end
  setState("Results", DUR.Results); Round.awardWinners(); task.wait(DUR.Results)
  Round.cleanup()
end
```
- Handle PlayerRemoving in the middle of a round by removing the player from the alive set. Clean up per-player tables, and consider Workspace.PlayerCharacterDestroyBehavior (https://create.roblox.com/docs/performance-optimization/improve).

#### A3. Server-authoritative tag/hit validation and anti-exploit
Official sources: https://create.roblox.com/docs/scripting/security/security-tactics and https://create.roblox.com/docs/scripting/security/client-server-boundary
- Never trust the client. Exploiters can fire remotes at any rate with any arguments; only the Player argument can be trusted. They can trigger Touched and ProximityPrompt from any range, and they own their character's physics.
- The official example checks requests in this order: type check, then NaN check, cooldown, permission, range check (the doc's example rejects `distance > 100`), and only then broadcast.
- For shots, the doc checks the reported origin against the server-side character "with extra tolerance" for latency. It raycasts only against static geometry, so lag doesn't reject valid shots.
- The token-bucket rate limiter is the recommended pattern (code on the same page). Use the Ban API for repeat offenders: https://create.roblox.com/docs/scripting/security/server-side-detection
- Movement checks: average positions over time, use leaky-bucket accumulators, project onto the XZ plane, and exempt legitimate teleports such as round spawns. https://create.roblox.com/docs/scripting/security/network-ownership
- Server Authority (beta) is described as "the most reliable" fix for movement and physics exploits. It uses client prediction with rollback. It requires these Workspace settings: AuthorityMode=Server, NextGenerationReplication, PlayerScriptsUseInputActionSystem, SignalBehavior=Deferred, UseFixedSimulation and StreamingEnabled. https://create.roblox.com/docs/projects/server-authority
- Player:GetNetworkPing() returns round-trip latency in seconds. https://create.roblox.com/docs/reference/engine/classes/Player

TNT-tag validator **(inferred, my code; the numbers are tuning starting points, not Roblox figures)**:
```lua
local TAG_RANGE = 6          -- studs, tune
local SPEED = 16             -- default WalkSpeed; tolerance grows with ping
local bucket = {}            -- token bucket per player: capacity 4, refill 4/s
TagRemote.OnServerEvent:Connect(function(p, target)
  if typeof(target) ~= "Instance" or not target:IsA("Player") or target == p then return end
  if not RateLimit.take(bucket, p, 4, 4) then return end
  if Round.holder ~= p or not Round.isAlive(target) then return end
  local a, b = Util.hrp(p), Util.hrp(target); if not (a and b) then return end
  local slack = SPEED * math.min(p:GetNetworkPing() + target:GetNetworkPing(), 0.5)
  if (a.Position - b.Position).Magnitude > TAG_RANGE + slack then return end
  Round.passBomb(p, target)  -- server sets holder; clients read it from an attribute
end)
```
Better **(inferred)**: let the server detect tags itself, e.g. with workspace:GetPartBoundsInRadius around the bomb holder on Heartbeat, and treat the client remote only as a hint. Then there is nothing for an exploiter to forge.
- Repos (licence and last push; these have few stars, so review before using): Clovis500c/Chronos, server-side lag compensation (MIT, 2026-08-13) https://github.com/Clovis500c/Chronos ; RegularTetragon/roblox-lag-compensation (no licence, 2023-06-23) https://github.com/RegularTetragon/roblox-lag-compensation ; DevForum "Client Prediction + Server Verification" for projectiles (2026-09-01) https://devforum.roblox.com/t/4844029

#### A4. Rising lava / falling tiles replication
- Official guidance: if TweenService tweens an object on the server, "the tweened property is replicated to each client every frame". The doc says this makes the tween jittery and wastes network traffic, so tween on the client. Create visual effects locally, because the server only needs the outcome. https://create.roblox.com/docs/performance-optimization/improve
- Creating or destroying large instance trees (maps) at runtime is network-heavy, so load maps in chunks. Same page.
- Community consensus: the server fires the tween parameters and each client runs the tween. TweenInfo can't be sent through a remote, so rebuild it on the client. If the server also sets the same property, it overrides the client tween. Modules: TweenService V2 https://devforum.roblox.com/t/tweenservice-v2/199815 , TweenService Plus+ https://devforum.roblox.com/t/tweenservice-plus/716025 , thread https://devforum.roblox.com/t/smoothing-tween/2653125 . The community asks for a rising-lava kill pattern but has no canonical answer: https://devforum.roblox.com/t/2084310
- Lava pattern **(inferred)**, with no per-frame replication:
  - The server stores attributes `LavaStart` (server time), `LavaY0` and `Rate` (studs/s).
  - Each client computes `y = Y0 + Rate*(GetServerTimeNow()-Start)` in RenderStepped and moves a client-only lava part.
  - Every 0.2 s the server computes the same y and eliminates anyone whose HumanoidRootPart is lower than y - 1.
  - Powers such as "freeze lava for 3 s" just rewrite the attributes.
  - If a real lava part exists on the server, keep it anchored with CanCollide and CanTouch off. Don't rely on Touched, which exploiters can fake (see A3).
- Falling tiles, spleef and color block pattern **(inferred)**:
  - Tiles are anchored and owned by the server.
  - The server sets a `FallAt` attribute on a tile (or a whole color group), then later sets CanCollide=false and Transparency=1.
  - Clients play the shake and fall tween locally when the attribute changes. That costs one property change per tile instead of streaming CFrame every frame.
  - Part budget: Roblox publishes no part-count threshold (improve page). As a starting point, aim for about 400–1,000 anchored tiles per arena, merge static décor, and turn CanTouch and CanQuery off on décor **(inferred)**.

#### A5. Spectate after elimination
- Set Camera.CameraSubject to a living player's Humanoid; it accepts a Humanoid or a BasePart. https://create.roblox.com/docs/reference/engine/classes/Camera
- Community pattern: build the target list only from players still in the round (marked with an attribute or BoolValue) and cycle through it with left/right buttons. https://devforum.roblox.com/t/1037836 . An MIT-licensed example UI: https://github.com/ZERO-Sentinel/Spectate-Menu (last push 2026-08-20).
- **(inferred)** Prefer setting CameraSubject over a Scriptable camera driven from RenderStepped. Rebuild the list whenever the alive set changes, and move to the next player automatically when the target dies.

#### A6. Teleport / queue / matchmaking
- Call TeleportService:TeleportAsync(placeId, players, TeleportOptions) from the server only; the client-side Teleport() is deprecated. Setting ShouldReserveServer=true creates a new reserved server, or you can pass a ReservedServerAccessCode. https://create.roblox.com/docs/projects/teleport
- Wrap the call in pcall and retry. TeleportInitFailed fires on late failures: wait on Flooded, retry on Failure. The doc sample uses 5 attempts, a 1 s delay and a 15 s flood delay. Same page.
- Teleport data is visible to the client, so never put currency in it. Teleports don't work in Studio. Set Access Control to "Secure within universe only". Same page.
- TeleportService:ReserveServer is tagged Deprecated; ReserveServerAsync is the current method. https://create.roblox.com/docs/reference/engine/classes/TeleportService
- For a cross-server queue, use MemoryStore queues or sorted maps. Lobby servers run matching on a timer and remove items once processed. https://create.roblox.com/docs/cloud-services/memory-stores . Tutorials: https://devforum.roblox.com/t/2707983 (2023, 77 likes) and https://devforum.roblox.com/t/1366126 . MatchMaker module (MemoryStore with promises): https://devforum.roblox.com/t/3663545
- Repos: g0ofycat/Match, ELO matchmaking (MIT, 2026-05-10) https://github.com/g0ofycat/Match ; bstummer/PartyService (MIT, 2026-03-17) https://github.com/bstummer/PartyService ; bstummer/openskill.lua (MIT, 2026-04-26) https://github.com/bstummer/openskill.lua ; playcurrent/shards, region-based matchmaking (MPL-2.0, 2025-09-08) https://github.com/playcurrent/shards
- Recommendation **(inferred)**: at launch, run each round on a single server, with lobby and arena in the same place and 12–20 players per server. This avoids teleport failures, splitting a small player count across servers, and code you can't test in Studio. Add reserved-server private matches only once there are enough concurrent players to fill public servers.

#### A7. Mobile controls
- ContextActionService:BindAction(name, fn, createTouchButton=true, ...inputs) creates a touch button automatically. Customize it with SetPosition(UDim2), SetTitle, SetImage, SetDescription and GetButton (which returns nil on non-touch devices). BindActionAtPriority controls the order. BindActionToInputTypes is deprecated. https://create.roblox.com/docs/reference/engine/classes/ContextActionService
- The newer **Input Action System** uses InputContext, InputAction and InputBinding objects. A touch binding points at an on-screen button through its `UIButton` property. Setting priority 2000 with Sink on suppresses default controls. It requires Workspace.PlayerScriptsUseInputActionSystem, which Server Authority also needs. https://create.roblox.com/docs/input/input-action-system
- UserInputService.PreferredInput tells you which input device is active. Orientation defaults to landscape. HapticEffect is available for vibration. https://create.roblox.com/docs/input/mobile
- **(inferred)** For tag games, put one large "Tag" button above jump plus a "Power" button. Avoid hold-to-act inputs during parkour. The docs I fetched give no minimum touch-target size.

#### A8. Leaderboards (crowns/wins)
- Write wins to an OrderedDataStore (integers only) at round end. Read the top 100 with GetSortedAsync (max page size 100) and cache the result on each server for 60 s or more **(cache interval inferred)**. The ordered write budget per server is 30+5·N per minute (see A1).
- Save player data with session locking. ProfileStore (Apache-2.0, last push 2025-07-31): https://github.com/MadStudioRoblox/ProfileStore
- Supporting libraries:
  - Sleitnick/RbxUtil, which includes Signal, Trove and Timer (MIT, 2026-08-11): https://github.com/Sleitnick/RbxUtil
  - 1Axen/blink, a buffer-networking IDL compiler (MIT, 2026-09-23): https://github.com/1Axen/blink
  - ffrostfall/ByteNet (MIT, 2025-08-01): https://github.com/ffrostfall/ByteNet
  - ZonePlus (MIT, 2024-07-04): https://github.com/1ForeverHD/ZonePlus
  - spavdigital/roblox-round-loop (MIT, 2026-08-26, 0 stars, so review it first): https://github.com/spavdigital/roblox-round-loop

#### A9. 20–40 player performance budget (inferred from A1)
- A 40-player server gets about 10.16 GiB of memory (6.25 GiB + 40 x 100 MiB). Keep usage under about 5 GiB to stay below the 50% guideline.
- Remotes: send events when something changes, not state every frame. Use UnreliableRemoteEvent for cosmetic bursts and keep those payloads well under 1000 bytes. The documented limit is about 500 requests/s per client; design for fewer than 10 per second.
- Turn on StreamingEnabled. Set arena models to Atomic or load them in chunks. Avoid unanchored physics props, because exploiters can take network ownership of them.

---
### B. Kids policy (2025–2026)

#### B1. Roblox Kids & Select evaluation
Official page: https://create.roblox.com/docs/production/publishing/kids-and-select
- Account types:
  - **Roblox Kids**, ages 5–8: Minimal or Mild content. Chat is off by default; a parent can turn it on after an age check.
  - **Roblox Select**, ages 9–15: up to Moderate content. Chat is off for self-declared ages and introduced gradually after an age check.
  - **Roblox**, age-checked 16+: chat is on by default where available.
- To publish for Kids and Select, the creator needs all of the following:
  - an age-checked account;
  - verification (facial age estimation if under 18, government ID if 18 or older);
  - 2-Step Verification;
  - either a refundable fee of **1,000 Robux per game** (https://create.roblox.com/docs/production/publishing/publish-games-and-places) or a Roblox Plus/Premium subscription that has been active for 2+ months;
  - the full Maturity & Compliance Questionnaire, with a Minimal, Mild or Moderate result;
  - a passed **evaluation**.
- Evaluation steps:
  - The game starts as a trial for age-checked 16+ users only.
  - It becomes eligible after **250 unique plays by highly engaged age-checked users within a 60-day window**. "Highly engaged" means account tenure, playtime in your game, and a purchase anywhere on Roblox in the last 60 days. Free-to-play games count.
  - Progress is tracked on the Audience Reach dashboard.
  - The fee is refunded 90 days after the game becomes eligible.
  - Conflict note: one search summary said "500 unique plays". The official page and the docs source (commit 2026-10-22) both say **250**, so use 250.
- An expedited review costs a refundable **50,000 Robux per game**.
- Effective date: third-party coverage says May 19 (https://nerdschalk.com/robloxs-new-publishing-and-alternative-requirements-for-roblox-kids-and-select-will-go-into-effect-on-may-19-heres-what-you-need-to-know/). I did not confirm this against an official source.
- **(inferred) design impact**: at launch only age-checked 16+ players can find the game, so it must appeal to teens. It also needs 250 qualified players before kids can see it. Plan a 16+ playtest or ad push, and budget the 1,000 R$ fee or a Plus subscription.

#### B2. Maturity labels and questionnaire (formerly "Experience Guidelines")
Official page: https://create.roblox.com/docs/production/promotion/content-maturity
- A game without maturity information is restricted for all players.
- Label reach: Minimal and Mild games are eligible for Kids and Select; Moderate for Select and 16+; Content May Vary for 16+ only; Restricted for age-verified 18+ only.
- Minimal = "occasional mild violence and/or light unrealistic blood". Mild adds repeated mild violence, mild fear-based content and mild crude humor. The page's example of mild violence is bodies disappearing as soon as health reaches zero.
- Roblox restricts free-form user creation and social hangouts to players over 16. Retake the questionnaire whenever an update changes your answers.
- **(inferred)** TNT explosions, lava eliminations and knock-offs with no blood, where the character poofs into spectate, should rate Minimal if occasional or Mild if repeated. Eliminations every round likely count as "repeated", so expect Mild, which is still eligible for Kids.

#### B3. Paid random items
Official page: https://create.roblox.com/docs/production/monetization/paid-random-items
- Applies to anything random bought directly or indirectly with Robux, including capsules, enhancement and combination items, luck boosts and pity systems. Free random rewards are exempt.
- Before purchase, show every outcome with its odds as a percentage, summing to exactly 100% (rounding is allowed with a disclaimer).
- A pop-up list needs descriptive link text; an "(i)" icon alone is not enough. For one-time outcomes, update the remaining odds for each user.
- Call PolicyService:GetPolicyInfoForPlayerAsync() for each player:
  - If `ArePaidRandomItemsRestricted` is true, apply one treatment: an earnable path, a fixed disclosed order, direct purchase, hiding, blocking the purchase, or keeping the player out of those areas.
  - If `IsPaidItemTradingAllowed` is not true, block trading of those items.
- **(inferred)** Sell cosmetics such as trails, bomb skins and crowns directly, and skip paid crates entirely in a kids game.

#### B4. Chat and age rules for party games
- Since January 2026, chat worldwide requires an age check by facial age estimation or ID. The age groups are under 9, 9–12, 13–15, 16–17, 18–20 and 21+. Chat is limited to similar ages, and under-9s have chat off unless a parent consents. Sources: Roblox press release via Nasdaq https://www.nasdaq.com/press-release/roblox-requires-users-worldwide-age-check-access-chat-2026-01-07 (the page timed out; facts come from the search summary) and https://gulfnews.com/technology/media/roblox-now-requires-age-checks-for-all-users-to-access-chat-worldwide-1.500401325
- **Quick Words** is Roblox's built-in preset chat for all ages. You get up to 3 custom categories with 3–10 words each, every word under 25 characters, written in English and auto-translated. Roblox reviews them before they go live. Set them up in Creator Hub > Configure > Chat > Quick Words. https://create.roblox.com/docs/chat/quick-words
- Custom preset systems must express gameplay intent only, and presets must not combine into free conversation. "Ready" and "Need help" are allowed; "Do you like me?" is not. https://create.roblox.com/docs/chat/preset-system-guidelines
- **(inferred)** Many kids in a party game will have chat off. Design around emotes, Quick Words such as "Run!", "Pass it!" and "GG", and big visual cues, so nothing depends on text chat.

---
### C. Themes (Steam upcoming, kid-friendly inspiration, no IP)
**SteamDB follower counts were NOT retrieved.** On 2026-10-23, https://steamdb.info/upcoming/mostfollowed/ returned 403 to WebFetch and showed a Cloudflare bot check in the browser. I did not try to bypass the check, and SteamDB has no public API, so a person would need to read the counts manually.

Instead, the table below lists each game's rank on Steam's official "Top Wishlists" search:
- Party Game tag (104 results): https://store.steampowered.com/search/?filter=popularwishlist&tags=7178
- Platformer tag (435 results): https://store.steampowered.com/search/?filter=popularwishlist&tags=1625

Descriptions come from the official Steam appdetails API. Date seen: 2026-10-23.

| # | Game (wishlist rank) | Release (Steam) | URL | Theme idea we could borrow (no IP) |
|---|---|---|---|---|
| 1 | Golf With Your Friends 2 (Party #2) | Coming soon | https://store.steampowered.com/app/3209660/ | "Ball race" round: every player is a rolling ball on a mini-golf course, and the holes are elimination pits |
| 2 | Rayman Legends Retold (Party #3, Platformer #11) | Dec 3, 2026 | https://store.steampowered.com/app/4084710/ | Music-synced lava: lava rises in beats and tiles flash on the rhythm |
| 3 | Hold My Thing (Party #9) | Coming soon | https://store.steampowered.com/app/4498480/ | Clumsy construction crew: the color-block floor is "wet cement" tiles under renovation |
| 4 | Meltdown Crew (Party #10) / Split Happens (#47) | Dec 2026 / Nov 27, 2026 | https://store.steampowered.com/app/4824220/ , https://store.steampowered.com/app/4408560/ | Overheating cartoon candy/goo factory: players fix valves to slow the rising goo in co-op sudden death |
| 5 | just volleyball (Party #12) / Keep It Up! (#21) | Nov 4, 2026 / Q4 2026 | https://store.steampowered.com/app/5037200/ , https://store.steampowered.com/app/4374530/ | "Don't let the balloon drop": the hot-potato bomb is a balloon that must stay in the air |
| 6 | Slowly Sliding Ducks (Party #34; up to 50 players per pool) | Oct 29, 2026 | https://store.steampowered.com/app/2485410/ | Bath-toy spleef: rubber-duck avatars on sinking foam tiles |
| 7 | Carry On Together (Party #36) | Nov 16, 2026 | https://store.steampowered.com/app/4776500/ | "Fragile parcel" tag: pass a wobbly gift box before it pops into confetti |
| 8 | Vikings On Trampolines (Party #40) | Coming soon | https://store.steampowered.com/app/748810/ | Bouncy-arena knock-off: trampoline tiles that break after 3 bounces (spleef variant) |
| 9 | Pigs and Wolf (Party #43) | Q4 2026 | https://store.steampowered.com/app/4285870/ | Fairy-tale tag: one "big bad" tagger chases piglets, who build quick barricades |
| 10 | Dumpster Gang (Platformer #14) | Dec 3, 2026 | https://store.steampowered.com/app/2870790/ | Raccoon gang vs. an exterminator: tag with grab-the-snack objectives |
| 11 | Froggin' Around (Platformer #10) | TBA | https://store.steampowered.com/app/4005900/ | Stretchy-tongue grapple as a power in rising lava |
| 12 | Human Fall Flat 2 (Platformer #5) | TBA | https://store.steampowered.com/app/1388550/ | Wobbly ragdoll obstacle rounds (ragdoll is cosmetic only; the server owns positions) |

Excluded as not suitable for kids: Party #1 We Are So Cooked (body-disposal premise, https://store.steampowered.com/app/4258290/) and #18 Drunkslop (pub crawl).

The strongest pattern **(inferred)** is physics-chaos co-op ("clumsy crew", "everything is falling apart") combined with cute animals (ducks, raccoons, frogs, piglets). One theme could cover TNT tag, rising goo, color block and spleef: a crew of cute animals escaping a malfunctioning cartoon factory.

---
### Gaps / caveats
- The docs I read publish no per-arena part-count budget and no remote bandwidth budget in KB/s; the improve page states neither.
- I found no official maximum server size. The only documented cap is Max Players ≤ 100 for voice chat.
- I couldn't open the Roblox chat press release directly (timeout and bot wall), so those facts come from search summaries.
- SteamDB follower counts are missing (see C).
- Housekeeping: a temporary sparse clone of Roblox/creator-docs was left at C:\rbxdocs_tmp (the working path was too long for git). A safety check blocked its automatic deletion, so it needs to be removed manually.
