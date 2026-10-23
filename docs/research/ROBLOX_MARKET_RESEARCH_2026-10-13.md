# Roblox Market Research: Charts, Brainrot Genre, Monetization, Rules (2026-10-13)

Prepared for Sharman's first Roblox game. Web research plus a live pull of Roblox's public chart API. Anything not checked against a primary source is marked UNVERIFIED. Revenue numbers for individual games are always third-party estimates, because Roblox does not publish them.

---

## 1. Bottom line

The single biggest game on Roblox tonight is not a brainrot game. It is **Steal An Egg** (released July 2026), with about **928K players online, roughly 3x the #2 game**, and #1 on Roblox's own Top Earning chart. It copies the Steal a Brainrot loop (buy or steal a creature, it earns money in your base, defend your base, steal from others) but uses eggs and pets in place of Italian brainrot memes. So the **steal-collect-defend loop is still the strongest formula on the platform. The brainrot meme skin is fading.** Steal a Brainrot set the all-time Roblox record (about 25 million concurrent players, October 2025) but now runs at about 137K, around 99% below its peak. It is still top 6 by players and top 13 by earnings. Two platform changes matter more than the trend itself. (a) Since August 20, 2026, Roblox's Home recommendations reward **long-term return visits plus monetization**, and Roblox says it is cutting impressions for games that "emphasize short-term monetization rather than long-term retention." (b) **New games launch only to age-checked players aged 16+** until they pass an engagement threshold (250 plays from "highly engaged" players in 60 days) and the creator is ID-verified, uses 2FA, and pays a refundable fee or holds Roblox Plus/Premium. The brainrot characters themselves are in an **active lawsuit over who owns Tung Tung Tung Sahur**, so using them carries IP risk.

---

## 2. Charts (live pull)

**Source:** Roblox explore API (`apis.roblox.com/explore-api/v1/get-sorts`, device=all, country=all), the same data behind roblox.com/charts. Pulled **2026-10-14 01:01 UTC (Oct 13, ~8 pm CT)**. "Playing" is concurrent players at that moment. Visits and created dates come from `games.roblox.com/v1/games` at the same time. Top Earning is Roblox's own ranking and shows no dollar figures. "Created" is the universe creation date, which can be earlier than the public launch.

### 2a. Top Playing Now

| # | Game | Genre (Roblox tag) | Playing | Lifetime visits | Created |
|---|---|---|---|---|---|
| 1 | Steal An Egg | Simulation / Tycoon | 928,201 | 8.00B | 2026-07-25 |
| 2 | Brookhaven RP | Roleplay / Life | 339,906 | 88.5B | 2020 |
| 3 | Adopt Me! | Roleplay / Pet care | 238,881 | 45.1B | 2017 |
| 4 | Murder Mystery 2 | Survival / 1 vs all | 205,490 | 31.3B | 2014 |
| 5 | Blox Fruits | Action RPG | 148,535 | 64.9B | 2019 |
| 6 | Steal a Brainrot | Simulation / Tycoon | 136,771 | 74.0B | 2025-05-16 |
| 7 | Jujutsu Shenanigans | Battlegrounds | 130,512 | 7.6B | 2022 |
| 8 | 99 Nights in the Forest | Survival | 129,859 | 30.0B | 2025 |
| 9 | RIVALS | Shooter | 124,047 | 18.7B | 2024 |
| 10 | Dandy's World | Survival / Escape | 118,559 | 7.7B | 2024 |
| 11 | Huss Valley | Battlegrounds | 108,531 | 108M | 2026-08-31 |
| 12 | Break and Steal an Egg | Simulation / Tycoon | 96,422 | 103M | 2026-09-05 |
| 13 | Murderers VS Sheriffs | Battlegrounds | 81,868 | 1.9B | 2025 |
| 14 | Catalog Avatar Creator | Avatar shopping | 68,415 | 8.1B | 2021 |
| 15 | Vanguards | Tower defense | 66,575 | 2.1B | 2024 |

### 2b. Top Earning (Roblox's ranking; no revenue values shown)

| # | Game | # | Game |
|---|---|---|---|
| 1 | Steal An Egg | 9 | Slayers 2 |
| 2 | RIVALS | 10 | +1 Speed Keyboard Escape |
| 3 | Adopt Me! | 11 | Blade Ball |
| 4 | Blox Fruits | 12 | Jujutsu Shenanigans |
| 5 | Dandy's World | 13 | Steal a Brainrot |
| 6 | 99 Nights in the Forest | 14 | Fisch |
| 7 | Brookhaven RP | 15 | Tower Defense Simulator |
| 8 | Murder Mystery 2 | | |

Third-party monthly revenue estimates from RoWatcher, **Q1 2026** (directional ranges, not verified): RIVALS $8-15M+, Blox Fruits $8-14M, Brookhaven $6-12M, Adopt Me $5-10M, Pet Simulator 99 $4-8M, **Steal a Brainrot $3-7M (reported #1 on mobile revenue, Jan 2026)**, Fisch $3-6M, Dress to Impress $2-5M, Anime Defenders $2-5M, Royal High $1.5-4M. No credible revenue estimate exists for Steal An Egg.

### 2c. Top Trending

| # | Game | Playing | Notes |
|---|---|---|---|
| 1 | 99 Nights in the Forest | 129,859 | |
| 2 | Huss Valley | 108,531 | created Aug 31, 2026 |
| 3 | Adopt Me! | 238,881 | Halloween event |
| 4 | Break and Steal an Egg | 96,422 | Steal-an-Egg variant, Sept 2026 |
| 5 | Dandy's World | 117,405 | |
| 6 | Ball VS Ball | 27,511 | party, Aug 2026 |
| 7 | Volleyball Legends | 53,202 | |
| 8 | 7 Days Cat-Sitting | 22,906 | survival, Sept 2026 |
| 9 | Sell Fries! [Anomaly] | 32,702 | anomaly-horror, Sept 21, 2026 |
| 10 | +1 Stone Skipping | 28,830 | "+1" incremental, Sept 2026 |
| 11 | Sarab | 5,924 | |
| 12 | Lethal Ape Experience | 20,699 | |
| 13 | LifeTogether RP | 32,465 | |
| 14 | Berry Avenue RP | 40,977 | |
| 15 | Hide In Pixels | 22,224 | |

### 2d. Up-and-Coming

| # | Game | Playing | # | Game | Playing |
|---|---|---|---|---|---|
| 1 | Apple iPad Original | 6,408 | 9 | Facecard: Makeup Showdown | 9,451 |
| 2 | Sell Fries! [Anomaly] | 32,673 | 10 | Lift Rock For Eggs | 11,134 |
| 3 | Huss Valley | 108,531 | 11 | 7 Days Cat-Sitting | 22,906 |
| 4 | Paint a Pancake | 14,867 | 12 | Climb For Animals Eggs | 17,150 |
| 5 | WRONG WAY! (4-player rally) | 8,679 | 13 | Scooter Empire | 2,610 |
| 6 | Kukirin Life [Testing] | 8,245 | 14 | DIVINE HATCHERS 0.0001% | 1,999 |
| 7 | Hide In Pixels | 22,224 | 15 | Bunker vs Verity | 13,971 |
| 8 | +1 Karate Evolution | 9,477 | | | |

### 2e. Top Revisited (games players return to; not a CCU ranking)

1 Vanguards, 2 Dragon Generations, 3 La Cueva Zua Zua, 4 Project Baki, 5 Heroes: Online World, 6 Dandy's World, 7 Heavyweight Fishing, 8 Bloodlines, 9 Rogue Lineage, 10 Azure Latch, 11 TBSOBR, 12 Outcome Memories, 13 Fallen Survival, 14 Grave/Digger, 15 ObjectVerse. These are mostly anime/RPG/fishing/survival games with deep progression and small, loyal player bases. **No steal/brainrot game appears here.**

### 2f. Month-earlier snapshot (StudioKrew, Sept 30, 2026; GGAID tracker)

Steal An Egg 1.6M (+468% vs August), Brookhaven 329.6K, Blox Fruits 245.2K, **Ride A Pet 208.0K** (egg-hatch-and-ride loop), Murder Mystery 2 192.1K, RIVALS 151.4K, 99 Nights 146.9K, +1 Speed Keyboard Escape 137.9K, Adopt Me 135.4K, Jujutsu Shenanigans 117.2K. Steal a Brainrot was about 108K, just outside the top 10.

### 2g. Platform context (primary: Roblox Q2 2026 shareholder letter, Jul 30, 2026)

- Daily active users about 123M (+10% YoY). Bookings about $1.6B (+8%). Bookings per DAU $12.66 (-2%). 27M monthly unique payers.
- Roblox blamed weak bookings on engagement shifting away from high-monetizing 2025 viral games (Grow a Garden, Steal a Brainrot era). It guided Q3 bookings down 14-18% YoY.
- Stock fell from over $130 to under $40 (Kotaku, Aug 5, 2026).
- Age-check data: 35% of verified users are under 13, 38% are 13-17, 27% are 18+ (UNVERIFIED secondary report).

---

## 3. Brainrot genre anatomy

**What it is.** "Italian brainrot" is a 2025 TikTok meme wave of AI-generated absurd hybrid creatures with fake-Italian chant names: Tralalero Tralala (a shark in sneakers), Tung Tung Tung Sahur, Bombardiro Crocodilo, Ballerina Cappuccina, Chimpanzini Bananini and others. Roblox games turned them into collectible units.

**Hit games and records**

| Game | Released | Peak CCU | Now (Oct 13, 2026) | Note |
|---|---|---|---|---|
| Steal a Brainrot (SpyderSammy / BRAZILIAN SPYDER group; owned by DoBig Studios) | May 16, 2025 | **25.4M, Oct 2025** (all-time Roblox record; RoWatcher says 25.8M); 20M Aug 2025; 24M Sept 13, 2025; 12.8M at the Bruno Mars concert, Jan 2026 | 137K | 74B visits, #2 most-visited game ever. Won 2025 Roblox Innovation Award. Film in development |
| Escape Tsunami For Brainrots (Wave of Brainrots) | Dec 15, 2025 | "nearly 5M" (RoWatcher; other trackers say 343K, so UNVERIFIED) | not in the top 100 tonight | Top Trending #1 Jan 4-Feb 2, 2026. Reportedly hit 50-90% by the April 2026 algorithm change (UNVERIFIED) |
| Swing Obby for Brainrots | Feb 18, 2026 | ~87K | ~57K (Mar 2026) | |
| Catch a Brainrot | 2026 | 9K debut (week's top new game) | n/a | |
| Steal An Egg (MSFMooses; "and Collect Rare Pets" group) | Jul 2026 | conflicting: 2.2M Aug (RoWatcher earlier), **14.3M Sept 2026 (RoWatcher page today)**, "near 9.9M" (another tracker). All UNVERIFIED | **928K, #1** | Not brainrot-skinned, but the same loop. Sammy collaborated on its Sept 19 update. 8B visits in about 11 weeks |

**Core loop (text diagram)**

```
 conveyor/egg shop spawns units (rarity roll)
        │ buy with cash          ┌──────── steal from another base ◄──┐
        ▼                        ▼                                    │
  unit sits in YOUR BASE ──► earns $/sec (rarity × mutation) ───► more cash
        │                                                             │
        ▼                                                             │
  defend: lock/shield timer, traps   ◄── others raid you ─────────────┘
        │
        ▼
  rebirth (reset for multiplier) → bigger base / rarer spawns → events add limited units
```

**Mechanics table**

| Mechanic | How it works in the hits | Why it works |
|---|---|---|
| Rarity tiers | Steal a Brainrot: Common, Rare, Epic, Legendary, Mythic, Brainrot God, Secret, OG | Clear status ladder that is easy to show off on video |
| Mutations | Multipliers that recolor a unit (e.g. Gold x1.25, Diamond x1.5, Lava x6, Rainbow x10; exact values UNVERIFIED and change by update) | A second roll on top of rarity. "Rainbow X" clips go viral |
| Passive income | Units earn $/sec while placed. Steal An Egg pets earn money too | Number keeps going up; the feeling of progress while idle |
| Steal + defend | Carry a unit from another base back to yours. Server-wide alerts. Timed base lock/shield, traps | Built-in drama, revenge, and spending pressure (defensive items) |
| Small servers | Max players: Steal a Brainrot 8, Steal An Egg 7 | Every player is a rival you can see; raids feel personal |
| Rebirth | Reset progress for permanent multipliers | Extends the grind and gives a reason to replay |
| Single speed stat | Steal An Egg, Ride A Pet, +1 Speed escapes all grow one number | Readable progression for young players. Copycats are fast |
| "Admin abuse" events | Developer joins live servers and spawns rare units or weather | Scheduled appointment play, huge CCU spikes, TikTok content |
| Live events / collabs | Grow a Garden crossover (20M, Aug 2025), Bruno Mars concert (12.8M, Jan 2026), Steal An Egg x Sammy | Biggest record spikes are all event-driven |
| Weekly updates | Steal An Egg and Anime Dice ship every Saturday (StudioKrew) | Players return on a schedule |

**Why it spread.** The theft mechanic makes reaction content: clips of rare pulls, robberies, and kids crying after a steal spread on TikTok and YouTube (Wikipedia). Meme characters already had name recognition with young players.

**Meme lifecycle (late 2026): past peak, normalizing.** Evidence:
- Steal a Brainrot is down about 99% from its peak. Escape Tsunami fell out of the top 100. RoWatcher's spring 2026 analysis calls the genre "normalizing", not dying, and says players are loyal to the genre rather than to any one game.
- RoWatcher counted roughly 3,300 live "Steal a ___" clones (UNVERIFIED keyword count).
- A June 2026 digest still called brainrot "a dependable way to attract new players" but near saturation.
- The TikTok "Great Meme Reset" campaign (late 2025) pushed back against brainrot humor; whether it changed anything in 2026 is UNVERIFIED.
- **What is replacing it is a reskin, not a new genre.** The steal/hatch loop moved to eggs and pets (Steal An Egg, Break and Steal an Egg, Ride A Pet, Climb For Animals Eggs, Lift Rock For Eggs). Other growing formats: "+1 per step" speed/incremental games, anomaly-horror ("Sell Fries! [Anomaly]", "Animal Hospital (Anomaly)", which spiked and fell about 90%), fishing (Fish It!, Fisch), and short survival experiences ("7 Days Cat-Sitting").

---

## 4. What the top earners share

1. **Several ways to spend at once.** RoWatcher's top-10 analysis: battle passes (RIVALS); permanent gamepasses (Blox Fruits, Brookhaven, Fisch, PS99); limited-time eggs and events (Adopt Me); trading economies (Adopt Me); gacha/RNG (PS99, Anime Defenders); cosmetics (Dress to Impress, RIVALS skins).
2. **Cheap, obvious gamepasses plus repeatable developer products.** Example from Steal An Egg (checked Sept 5, 2026): X2 Money 399 Robux, X2 Growth Speed 467 Robux, plus timer-skip developer products and a premium egg (StudioKrew).
3. **Retention hooks:** weekly updates on a fixed day, seasonal events (nearly every top game has a Halloween tag tonight), "admin abuse" sessions, rebirths, codes released at like/visit milestones, trading.
4. **Mobile first.** Steal a Brainrot was reported #1 by mobile revenue in Jan 2026, while RIVALS led desktop. Brainrot and steal games are built for one-thumb play.
5. **Premium payouts and ads.** Premium payouts are based on engagement time from Premium subscribers, so long sessions earn more (reported to be roughly 10% of developer revenue; UNVERIFIED). Roblox is adding rewarded-video placements with a no-code Studio plug-in planned for Q4 2026 (MediaPost/eMarketer).
6. **Adult spend pays more.** DevEx is 42% higher for spending by age-verified US players aged 18+ (effective June 8, 2026; creators get 37.8% instead of 26.6% on qualifying spend). UNVERIFIED secondary report; check the Creator Hub.
7. **Small teams can still hit.** Steal a Brainrot was led by one developer (SpyderSammy, on Roblox since 2013, with a community group; not a true solo build). Grow a Garden was made by a 16-year-old in a few days and then bought by Splitting Point (AP). 99 Nights in the Forest was made by 3 people (Grandma's Favourite Games), started as a one-week project, peaked at 14.2M, and has a 20th Century Studios film deal. StudioKrew estimates $25-75K to build a comparable mid-sized game, plus weekly updates.
8. **What the algorithm now rewards (Aug 20, 2026):** long-term return visits plus monetization, measured together. Games strong on only one of the two "may see some changes" in Home distribution (Roblox DevForum, Chief Growth Officer).

---

## 5. Rules and risks

| Risk | Detail | Source |
|---|---|---|
| **Paid random items** | Any random reward bought with Robux, directly or through paid currency (eggs, spins, luck boosts, mutation rolls, pity systems), must show every possible outcome with percentage odds summing to 100%, **before purchase**. Odds must update when boosts apply. Use `PolicyService:GetPolicyInfoForPlayerAsync()` → `ArePaidRandomItemsRestricted` / `IsPaidItemTradingAllowed`. Restricted users must get an alternative (free path, fixed order, direct purchase, or block). Ineligible users cannot trade paid random outcomes. Random rewards earned only through play do not need disclosure. | create.roblox.com paid-random-items |
| **Launch audience** | New games release first **only to age-checked users 16+**. Reaching Roblox Kids (5-8) and Select (9-15) needs: creator age/ID verification, 2FA, a Maturity questionnaire result of Minimal/Mild/Moderate, a refundable fee or Roblox Plus/Premium for 2 consecutive months, and 250 plays from "highly engaged" players in 60 days. Expedited review is a refundable 50K Robux. Kids accounts see only Minimal/Mild content. | create.roblox.com kids-and-select |
| **Feed/scroll mechanics** | After Steal An Egg's treadmill showed an AI short-video feed, Roblox barred games that "[reward] users to consume a continuous feed of content without natural stopping points" for younger accounts. The game was offline about 3-4 hours on Aug 24-25, 2026 and came back without the feed. | MassivelyOP, TechSpot, allthings.how |
| **Discovery demotion** | Roblox says it is lowering the frequency of impressions for games that "emphasize short-term monetization rather than long-term retention" (Baszucki, Q2 call). Low-quality brainrot was reportedly targeted in April 2026 testing (secondary source). | Kotaku; creation.dev (UNVERIFIED) |
| **Brainrot character IP** | **Disputed and in court.** Spyder Games/DoBig Studios sued Mementum Labs (France), which claims Tung Tung Tung Sahur on behalf of Indonesian creator Noxa; Mementum counter-sued for trademark infringement. DoBig argues that AI-generated characters cannot be copyrighted. Steal a Brainrot pulled Tung Tung Tung Sahur in Sept 2025 over a licensing dispute (back Nov 29, 2025). Mementum has licensed it to Fortnite. **Treat named brainrot characters as not free to use.** Original creatures avoid the problem. | NPR Aug 19, 2026; GamesBeat; Wikipedia |
| **Clones** | Spyder Games sued a Fortnite copy over copyright (Oct 2025). Copyright covers art, code, and sound, not mechanics, so clones of your loop are hard to stop. Copied code is a risk: Steal An Egg was accused of copying Pet Simulator 99 code (unconfirmed). | Wikipedia; PlagiarismToday Sept 17, 2026; allthings.how |
| **Regulatory pressure** | US advocacy groups asked regulators to investigate Roblox spending practices (May 2026). Nevada settlement for $12M. Several state AG lawsuits. PEGI rates paid random items 16+ from June 2026 (reclassifying existing games from Oct 1, 2026). Expect stricter spending rules over time. | news reports (secondary) |
| **What gets games moderated** | Feed-reward mechanics (above); undisclosed odds on paid randomness; misleading titles/thumbnails (Roblox discovery roadmap); Community Standards violations (refunds forfeited); copied assets/code. | sources above |

---

## 6. Gaps and player complaints

- **Pay-to-win.** Polygon: "the best items are only available for cash," including purchasable admin-like powers.
- **Theft feels cruel to young players.** Viral clips of crying kids. Losing a rare unit to a stronger or paying player is a major quit trigger.
- **Cheaters and scripts.** Auto-collect and auto-steal exploits (GameRant via Wikipedia).
- **Clone fatigue.** Thousands of near-identical "Steal a X" games. Copies of any one twist appear within weeks and also fade fast (StudioKrew).
- **Spike-then-crash.** Event peaks (25M, 12.8M) are followed by steep drops. Escape Tsunami, Animal Hospital, and +1 Speed Monkey Escape all lost most of their players within months.
- **Low long-term retention is now penalized.** Top Revisited is mostly anime/RPG/fishing games with deep progression; steal games are missing from it.
- **AI-slop backlash.** Forum users and press criticize AI-generated content, and the AI-video treadmill was pulled.

Underserved directions suggested by the data (observations, not concepts):
- A steal loop with **protection for losers or new players** (only the Steal An Egg treadmill and timed locks exist today).
- **Co-op and team raids.** Fun with Friends lists "2 Player Raid Tycoon" and "4 Player Rally"; most steal games are free-for-all.
- **Long-term progression in steal games**, so they can earn Top Revisited-style return visits.
- **Original creatures** instead of contested meme IP.
- **Non-pay-to-win spending** (cosmetics, base decoration), matching the shift top earners have made.

---

## 7. Pattern ingredients a new game could combine

1. **Collect-and-earn base:** units sit in your base and earn money per second. Rarity tier × mutation multiplier = value.
2. **Steal-and-defend in small servers (7-8 players):** visible rivals, timed locks/shields, server alerts.
3. **One readable growth stat** (speed, size, steps) on a "+1" incremental curve, plus rebirth multipliers.
4. **Scheduled live moments:** weekly Saturday update, "admin abuse" sessions, seasonal events, collabs.
5. **Original meme-able creature roster** with absurd names and a clear rarity ladder, owned by you rather than contested brainrot IP.
6. **Long-term return hooks** for the new algorithm: daily rewards, collections and indexes, long goals, trading.
7. **Mobile-first, one-thumb UI** with a 30-second tutorial.
8. **Layered, policy-safe monetization:** cheap 2x passes, timer-skip products, cosmetic/base passes, rewarded video, and paid randomness only with odds shown and a PolicyService fallback.
9. **Social or co-op layer:** team raids, revenge mechanics, protection for new players.
10. **Clip-ready moments:** rare-roll and steal animations that work as 10-second TikTok/Shorts clips.

---

## 8. Sources

Primary or near-primary:
- Roblox explore API, live pull 2026-10-14 01:01 UTC: https://apis.roblox.com/explore-api/v1/get-sorts ; game details: https://games.roblox.com/v1/games
- Roblox Q2 2026 shareholder letter (8-K Ex. 99.1): https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm
- Roblox DevForum, "Boost Your Discovery by Building Games People Want to Play" (Aug 6/20, 2026): https://devforum.roblox.com/t/boost-your-discovery-by-building-games-people-want-to-play/4779042
- Roblox docs, Kids and Select: https://create.roblox.com/docs/production/publishing/kids-and-select
- Roblox docs, Paid random items: https://create.roblox.com/docs/production/monetization/paid-random-items
- Roblox DevForum, Kids and Select global launch: https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717

News and analysis:
- Kotaku, Aug 5, 2026: https://kotaku.com/roblox-tanked-9-billion-in-a-single-day-after-the-company-admitted-it-was-directing-fewer-kids-toward-viral-games-that-emphasize-short-term-monetization-2000722002
- NPR, Aug 19, 2026 (Tung Tung Sahur IP fight): https://www.npr.org/2026/08/19/nx-s1-5867638/artificial-intelligence-brainrot-memes-spyder-tung-tung-sahur
- GamesBeat on the Tung Tung Sahur case: https://gamesbeat.com/?p=331060
- MassivelyOP, Aug 29, 2026: https://massivelyop.com/2026/08/29/roblox-clamps-down-on-gen-ai-brainrot-scrolling-games-after-steal-an-egg-goes-viral/
- TechSpot: https://www.techspot.com/news/113630-roblox-cracking-down-games-reward-kids-doomscrolling.html
- allthings.how (Steal An Egg removal): https://allthings.how/steal-an-egg-roblox-ban-why-it-happened-and-how-it-returned/
- StudioKrew, Top Roblox Games Sept 2026 (Oct 1, 2026): https://studiokrew.com/blog/?p=2016
- Wikipedia, Steal a Brainrot: https://en.wikipedia.org/wiki/Steal_a_Brainrot
- Outlook Respawn, Steal a Brainrot record (Oct 10, 2025): https://respawn.outlookindia.com/gaming/gaming-news/robloxs-steal-a-brainrot-breaks-all-time-player-record
- RoWatcher, "Is the Brainrot Trend Dying?": https://rowatcher.com/news/is-the-brainrot-trend-dying-what-ccu-data-from-three-top-games-reveals
- RoWatcher, top-10 earners 2026 (estimates): https://rowatcher.com/news/the-10-highest-earning-roblox-games-in-2026-and-what-they-mean-for-the-platform
- RoWatcher, weekly digest (brainrot boom): https://rowatcher.com/news/roblox-weekly-digest-brainrot-boom-a-9-7-ccu-slide
- RoWatcher, Steal An Egg page: https://rowatcher.com/games/10563114921/steal-an-egg
- RoWatcher, live charts: https://rowatcher.com/charts
- RoWatcher, How many games are on Roblox in 2026: https://rowatcher.com/news/how-many-games-are-on-roblox-in-2026
- creation.dev, April 2026 algorithm update (secondary): https://www.creation.dev/learn/roblox-algorithm-update-filtering-brain-rot-games-april-2026
- PlagiarismToday, Sept 17, 2026: https://www.plagiarismtoday.com/2026/09/17/the-attack-of-the-roblox-clones/
- AP via Boston Globe, Grow a Garden teen creator: https://www.bostonglobe.com/2025/07/30/wires/roblox-grow-a-garden-teenager/
- DevForum Creator Spotlight, 99 Nights in the Forest: https://devforum.roblox.com/t/creator-spotlight-the-story-behind-99-nights-in-the-forest/4036940
- MediaPost, rewarded video: https://www.mediapost.com/publications/article/417959/roblox-eyes-expanded-placements-for-rewarded-vid.html
- NetInfluencer, DevEx +42% for 18+: https://www.netinfluencer.com/roblox-to-raise-developer-exchange-rate-for-games-aimed-at-18-plus-players-as-adult-cohort-surges/
- Know Your Meme, Great Meme Reset: https://amp.knowyourmeme.com/memes/the-great-meme-reset-of-2026
- Profitable.app (estimates): https://profitable.app/roblox/games/steal-a-brainrot
- Rotrends, Escape Tsunami: https://rotrends.com/game/9363735110/Escape-Tsunami-For-Brainrots
