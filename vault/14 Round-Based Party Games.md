# 14 Round-Based Party Games

How to build kid party games (bomb tag, rising lava, color block, spleef, push-off, hide and seek) that a 7-year-old gets in one sentence and still wants to replay. Facts cite a source; everything else is a studio rule. Full data, every game and every number: `docs/research/PARTY_GAMES_2026-10-23.md`.

## What the market says (2026-10-23)
- Fact: one bomb-tag game holds most of that genre's live players: Timebomb Duels at 10,638 playing, 28K tracked peak, with **zero gamepasses** (Roblox games API; [RoWatcher](https://rowatcher.com/games/4049246711)). Its 2026 clones peaked and fell 90-99% (Monkey Bomb Tag 39K → 542; Pass or Explode 11K → 229).
- Fact: classic round lava games sit around 1.5K players each with 14-35K peaks, while the 2026 breakouts pair a rising hazard with collect + rebirth (Escape Tsunami For Brainrots, 4-5M peak; [rotrends](https://rotrends.com/game/9363735110)).
- Fact: Knockout! (push-off, simultaneous 7 s turns) peaked at 620,670 CCU and still holds 96.1% likes ([rotrends](https://www.rotrends.com/game/9384605736); [wiki](https://knockout-roblox.fandom.com/wiki/Guides)).
- Fact: round games die at low player counts. Devs report players leaving instantly when servers have fewer than ~10 players ([DevForum](https://devforum.roblox.com/t/feedbackproblem-hot-potato-slap-counter-game/4450393), [DevForum](https://devforum.roblox.com/t/how-do-you-prevent-players-from-leaving-a-round-based-game/4671460/3)).

## The round state machine (studio rule)
```
LOBBY (free roam + mini obby) → INTERMISSION 15-20 s (map vote, 3-2-1) → ROUND → SUDDEN DEATH (if capped) → RESULTS 5-8 s → back to INTERMISSION
```
- One server-owned state value (`RoundState`) and a server clock (`RoundEndsAt`, from `workspace:GetServerTimeNow()`); clients only render it.
- Intermission 15-35 s is the range devs use; one split is 10 s results + 20 s voting ([DevForum](https://devforum.roblox.com/t/ideal-intermission-time/724439/1)). Keep any "get ready" card to 3-5 s ([DevForum](https://devforum.roblox.com/t/feedback-on-my-rising-lava/1215711)).
- **A new joiner must be playing within 60 s.** Long rounds strand joiners for minutes ([DevForum](https://devforum.roblox.com/t/allow-developers-to-mark-servers-as-unpreferred-for-new-player-joins/3680997/1)). Use rounds under ~2 min, join-in-progress where the mode allows, and a lobby obby that pays a little (Floor Is LAVA pays 5 points for its spawn obby, [namu](https://namu.moe/w/The%20Floor%20Is%20LAVA)).
- Remove a player from the alive set on death **and** on leave, or they still collect the win ([DevForum](https://devforum.roblox.com/t/feedback-on-my-rising-lava/1215711)).
- Below 4 players, fill with bots or switch to a solo mode (score attack). Never show an empty arena.

## Bomb tag rules (studio rules from the market leaders)
- Touch-to-pass, no button: works on phones without UI and keeps the verb dumb-simple ("here, take it"), per a genre dev ([DevForum](https://devforum.roblox.com/t/feedbackproblem-hot-potato-slap-counter-game/4450393)).
- Fuse 10 s per holder is the market norm (Pass or Explode 10 s; AnkleBreak 15 s; [allthings.how](https://allthings.how/pass-or-explode-how-to-play-and-win-in-roblox/)). Flash and beep faster in the last 3 s, the moment guides call the most dangerous ([earnaldo](https://earnaldo.com/blog/timebomb-duels-beginner-guide)).
- Pass cooldown ~0.5 s so the bomb can't bounce straight back (paid kits advertise this, [BuiltByBit](https://builtbybit.com/resources/bomb-tag.95283/updates)). Holder gets +10% speed so chases resolve.
- Server decides every pass: distance check (≤ 4-5 studs between root parts, plus a small latency allowance), holder alive, cooldown elapsed. Never trust a client "I tagged".
- One elimination per fuse, final 2 duel, credit the kill effect to whoever passed last (Pass or Explode does this, [allthings.how](https://allthings.how/pass-or-explode-how-to-play-and-win-in-roblox/)).
- Skill ceiling is the content: dodges and "ankle-break" jukes top YouTube (1,005,474 views, [video](https://youtu.be/WXfZdtVDB5w)). Keep the same base speed for everyone so skill shows.

## Rising lava rules
- Classic cycle: ~15 s prep, ~40 s lava, ~20 s intermission (one guide, [earnaldo](https://earnaldo.com/blog/the-floor-is-lava-free-robux-guide)). Rise curves differ by map (fast start then slow, or steady).
- **Lava height is a function of time, not a replicated part.** Server stores `startTime` and the curve; every client computes `height(t)` per frame; the server checks deaths against the same curve. Server-side tweens look choppy ([DevForum](https://devforum.roblox.com/t/smoothing-tween/2653125)).
- Lava drains health over a short time instead of instant-kill, and death triggers at full submersion (Floor Is LAVA, [namu](https://namu.moe/w/The%20Floor%20Is%20LAVA)). Gives a "barely made it" moment.
- Structures blacken and fade as lava reaches them, so no perch is safe forever (same source).
- Avoid z-fighting flicker on the lava surface; reviewers flagged it as a seizure risk ([DevForum](https://devforum.roblox.com/t/feedback-on-my-rising-lava/1215711)).
- Never ship a map that is unwinnable without a paid item (the top complaint about Floor Is LAVA, [namu](https://namu.moe/w/The%20Floor%20Is%20LAVA)).

## Powers and crowns (our differentiator)
- Fact: in every top lava game, double jump, shield, grapple and jetpack are **Robux passes** (Floor Is LAVA: Double Jump 39, Lava Shield 249, Grapple 499; Tsunami For Brainrots: Rainbow Shield 295, Harpoon 640; [game-pass API](https://apis.roblox.com/game-passes/v1/universes/341654025/game-passes?passView=Full&pageSize=50)). No currency in the family is called crowns.
- Studio rule: **crowns are earned, never sold.** Crowns for escaping (1), for a clean parkour route (+1), and for round placement. Crowns unlock powers permanently; Robux buys only cosmetics.
- One power equipped per round, on a cooldown, shown as a single button. Starter set: Dash (8 s), Double Jump (passive), Shield (bubble 2 s, 20 s cooldown), Grapple (12 s). Build them with the skill kit shapes (Dash, Aura, Projectile) in `docs/rulebooks/SKILLS_VFX_RULEBOOK.md`.
- Server validates every power use (cooldown, alive, distance for grapple targets). Clients play the effect instantly.

## Other proven rules from the families
- **Color block:** a 5-8 s call window that shrinks to 3-4 s; 10 colors with confusable pairs, so ship a colorblind mode with symbols on tiles ([earnaldo, unverified](https://earnaldo.com/blog/color-block-free-robux-guide)).
- **Disasters:** a lobby that overlooks the map is free spectating, and every disaster is telegraphed (volcano erupts 15 s after its warning card, [wiki](https://natural-disaster-survival.fandom.com/wiki/Disasters)).
- **Spleef:** tiles heat yellow → orange → red before collapse ([Knockout wiki](https://knockout-roblox.fandom.com/wiki/Penguin_Peak)); give an active verb (Rocket Spleef 87.9% likes vs passive Fading Blocks 58.7%).
- **Push-off:** simultaneous 7 s turns remove lag and aim gaps; cap at 11 rounds; auto-rescue players hugging an edge before it shrinks ([Knockout wiki](https://knockout-roblox.fandom.com/wiki/Guides)).
- **Red light green light:** 3 hits before elimination instead of instant death, and a 1 s grace before checking movement ([SGX wiki](https://squid-game-x.fandom.com/wiki/RedLight_GreenLight), [DevForum](https://devforum.roblox.com/t/wait-only-working-once/3046147/1)).
- **Hide and seek:** caught hiders join the seekers so nobody spectates for long (Paint Or Seek, 93K peak).

## Spectate (studio rule)
- Eliminated players go to a lobby with a view of the arena, or get an auto-spectate camera that follows the leader, with a "Next round in 0:42" timer and a mini obby to kill time.
- Never park a kid on a black screen. Never make them wait more than one round.

## Feel checklist (ship gate for any party game)
- [ ] 3-2-1 countdown with sound and a camera push-in; "GO!" stinger.
- [ ] Every tag, pass and hit: hit-stop 70 ms, screen shake, a sound, a VFX burst (`SKILLS_VFX_RULEBOOK.md` numbers).
- [ ] Bomb/hazard state readable at a glance: holder outline + timer above the head; lava height bar.
- [ ] Death: ragdoll or comic effect credited to the player who caused it; eliminated → spectate within 1 s.
- [ ] HUD: round timer, players left, crowns, one power button; nothing in the bottom corners on phones.
- [ ] Results: top 3 podium, crowns earned animation (count-up + pop), 5-8 s, then straight to the next intermission.
- [ ] Mobile: touch-to-pass, big jump button, power button above jump.
- [ ] Server: all tags, passes, powers and deaths decided on the server; win counted only for players still in the alive set.

## Monetization rules for kid party games
- Fact: Timebomb Duels leads its genre with no gamepasses at all (game-pass API, universe 4049246711).
- Sell: cosmetics (bomb skins, explosion effects, trails, crown skins), VIP servers with round controls, a season pass of cosmetics.
- Never sell: wins (Fading Blocks sells "+1 Win", corrupting leaderboards), pay-to-grief ("Kill All", "Nuke", "Fake Stop" in Musical Chairs, 66.4% likes), paid tagger or seeker chance, gameplay powers, false-scarcity "NEVER COMING BACK" skins, loot boxes or Server Luck.
- Anything random that touches Robux shows full odds first (chapter 03, CLAUDE.md rule 7).

## Engineering and platform limits (official numbers)
- Server heartbeat is capped at 60 FPS; server memory is 6.25 GiB + 100 MiB per peak player, keep usage under 50% ([identify](https://create.roblox.com/docs/performance-optimization/identify)).
- Client remotes are limited to about 500 requests/s per client, shared; unreliable remotes drop payloads over 1000 bytes ([RemoteEvent](https://create.roblox.com/docs/reference/engine/classes/RemoteEvent), [UnreliableRemoteEvent](https://create.roblox.com/docs/reference/engine/classes/UnreliableRemoteEvent)). Design for under 10 events/s.
- Server-side tweens replicate every frame and look jittery; tween on clients, keep only the outcome on the server ([improve](https://create.roblox.com/docs/performance-optimization/improve)). Tiles: one attribute flip per state change, clients animate.
- Tag validation order from Roblox's security docs: type → NaN → rate limit (token bucket) → permission → range, with latency tolerance ([security tactics](https://create.roblox.com/docs/scripting/security/security-tactics)). Better: the server detects tags itself (GetPartBoundsInRadius around the holder) and treats the client remote as a hint.
- Wins/crowns leaderboards: OrderedDataStore values are integers, pages ≤ 100, ordered writes limited to 30 + 5×players per minute per server; write once at round end ([limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)).
- Spectate with `Camera.CameraSubject` set to a living player's Humanoid ([Camera](https://create.roblox.com/docs/reference/engine/classes/Camera)).
- Teleports use `TeleportAsync` (server only) with pcall + retry; `ReserveServer` is deprecated ([teleport](https://create.roblox.com/docs/projects/teleport)). Studio rule: at launch, keep lobby and arena in one server (12-20 players).

## Kids policy (what it means for launch)
- New games start as a trial for age-checked 16+ players and reach under-16s after **250 unique plays by highly engaged age-checked users within 60 days**. The creator needs verification, 2-Step Verification, the maturity questionnaire, and a refundable 1,000 R$ fee or 2+ months of Plus/Premium ([Kids & Select](https://create.roblox.com/docs/production/publishing/kids-and-select)). So the launch build must also appeal to teens.
- Cartoon eliminations with no blood (pop, poof, splash) fit Minimal or Mild, which are eligible for Kids and Select ([content maturity](https://create.roblox.com/docs/production/promotion/content-maturity)).
- Many kids have chat off; design around emotes and Quick Words ("Pass it!", "Run!", "GG") ([Quick Words](https://create.roblox.com/docs/chat/quick-words)).

## Measured timings from the second pass (2026-10-23)
- Hide and Seek Extreme: 1 min hide + 4 min seek, 2-14 players ([wiki](https://hide-and-seek-extreme.fandom.com/wiki/Gameplay)); a guide says 60 s + 3 min, so treat 4-5 min as the range.
- Natural Disaster Survival: rounds of about 2-4 min depending on the disaster; dead players watch from the Lobby Tower ([earnaldo, low confidence](https://earnaldo.com/blog/natural-disaster-survival-free-robux-guide); [wiki](https://natural-disaster-survival.fandom.com/wiki/Lobby_Tower)).
- Color Block: 5-8 s per call shrinking to 3-4 s, called colour shown at the top of the screen, needs 4+ players (earnaldo, low confidence; timer speed-up confirmed in a gameplay transcript). Full sources in the catalog's "Gap fill" section.
- Escape The Lava has no rounds: lava rises and falls in waves, so a joiner plays at once (inferred from its description and gameplay).
- Still unpublished for every game: results-screen length and mid-round joiner wait. Time them in a live server before locking our numbers.
