# What the TikTok actually shows ("roblox development will never be the same…")

Source: the 2:09 MP4 Sharman uploaded (720x1280, 30 fps). I went through it frame by frame,
every 2 seconds, plus full-resolution stills of the key moments.
**Seen** = readable on screen. **Unclear** = blurred or cut off, so I'm guessing from fragments.
Audio transcript: see the end of this file.

## On-screen captions
- "This will change roblox development forever." / "(the obsidian vault is insane)" (0:00–0:06)
- "(in less than a week while i sleep btw)" (over gameplay, ~0:50–1:00)

## 1. A custom "control room" dashboard (Seen)
A dark desktop app titled **"robdev control room"**, branded **robdev / Inclined Games studio**.
It sits on top of Roblox Studio (the Studio Home/Avatar/UI/Script/Model/Plugins ribbon shows behind it). The OS is Windows.

**Left sidebar**
- **Workspace:** Home (badge 4), Lead, Team (2), Tasks (2), Review
- **Studio:** Games, Pitches (4), Market, Library
- **Team:** a grid of 15 colored agent icons
- **Footer:**
  - "2 agents working · Playtest has Studio"
  - "AGENTS RUN ON [Max] trevor77077@gm… · Switch". This is most likely a Claude Max subscription login (inferred from the "Max" badge plus "ur claude can reconfigure anything" in their Discord).

**Top tabs:** "All games 3 · Anime Awakening RNG 3 · Dig Up a Dino". So 3 games are in progress at once.

**Team page:** "Team · 2 working · 0 need you". Each agent is listed with its last status line:

| Agent | Status line shown | What it seems to do |
|---|---|---|
| Lead | "Playtest has the zone 7 arena…" | Orchestrator; you chat with it ("Ask the Lead anything, or say what you want done") |
| Builder | WORKING "On: Game 2: the guide v4…" | Writes the game code |
| Playtest | WORKING "On: Zone 7 underwater arena…" | Holds Studio and playtests (only one agent "has Studio" at a time) |
| Pulse | "Finds what is trending and pit…" | Market research and game pitches |
| Architect | "The 12-step guide is written…" | Writes the build plan / spec |
| Librarian | "I've picked and uploaded a ne…" | Picks and uploads assets |
| Frame | "Yes, the player's avatar is R15…" | Characters / avatar |
| Scenic | "Zones 1 and 2 are fuller and h…" | World / zone building |
| Kid Tester | "Plays each build twice on a pho…" | Plays as a kid would, on a phone layout |
| Balance | "The numbers for fuller zone 1–…" | Economy and tuning numbers |
| Splash | "Makes the icon and thumbnails" | Store art |
| Producer | "++Flow check, Anime Awaken…" | Checks the flow and pacing of the game |
| LiveOps | "Rotating notifications are set u…" | Post-launch content and events |

That's 13 named agents, and the grid shows 15 icons, so 2 are unnamed (Unclear).

**Home page:**
- "Needs you" cards: "PICK THE NEXT GAME · 4 game pitches from Pulse waiting for your pick".
- "TRY IT" cards give the human exact manual test steps. Examples:
  - "Game 2: try a party raid's QUICK JOIN with a second account (PC + phone)…"
  - "Game 2: test the Training Grounds server hop on the private game (about 20 min)…"
  - "Game 2: publish Saved v1429 to the private game and try the training mat…"
- Each card has Reply / Done / Details buttons.
- "Later (13): not doable yet, nothing to do now".
- Buttons: "Ask →", "New task", "Pause all", and "Live · updated just now / Refresh".

**"Live now" panel:**
- Builder: "On: Game 2: the guide v4 server, 25 card…"
- Playtest: "On: Zone 7 underwater arena…"
- **"Where each game is":**
  - Dig Up a Dino: v404 published, Live, "fixes and live ops"
  - Anime Hero RNG: v1497 saved, "Assets ready, Now: the Builder builds it, with Frame and Scenic"
  - Each has a "Play the current build" button.
- **"Studios for agents: Off / 1 / 2 / All"** — how many Studio instances agents may use. "Playtest · Lane 1 · anime-sword-rng · 8m ago".

**Review page:**
- "Everything the agents made for you to look at. Approve it, ask for changes, or reject it; the agent picks up your verdict on its next pass."
- Tabs: Images & video / Stages & publish.
- Counters: To review 0 · Changes asked 120 · Approved 435 · Rejected 22 · Everything 577.
- Items are AI-generated icons, thumbnails and a trailer ("Use this thumbnail on Anime Hero RNG"), shown in an approve / changes / reject side panel.
- Footer: "build ab6202f Lane 1 · 2026-10-21".

**Market page:**
- Roblox chart data: "top trending 93 · up and coming · top playing now · fun with friends · top-revisited".
- A table with rank, change, name and player count. Examples: Dress To Impress, Forsaken, Tribes 3v3, Blackhawk Rescue Mission 5…
- Fine print mentions "pulse.saturationCount". This is what Pulse uses to pitch games. The data source isn't shown (Unclear).

## 2. The game it built (Seen)
"Anime Awakening RNG" / "Anime Hero RNG":
- An underwater boss arena with the boss "Kisharku BOSS 7" and an HP bar (1.5M → 255K).
- Combo counter, floating damage numbers.
- Bottom HUD: Backpack / **ROLL!** / Upgrades, a "FREE ROLL!" button, and an auto toggle.
- A hub world with "RAID" and "MARKET" signs.
- A raid lobby screen, "BAMBOO RAID":
  - Rooms 1–2 then a boss.
  - Normal / Hard / Nightmare / Calamity difficulties.
  - A Calamity requirement of "rebirth 4".
  - Rewards, party slots 1/4, recommended power, "PLAY SOLO / QUICK JOIN".
- An "Index" collection book with silhouettes of characters not yet collected, and a progress bar.

It's a polished, fairly standard anime RNG/raid game.

## 3. The "Obsidian vault" (Seen)
An Obsidian knowledge base that the agents read. The folder list on screen:
- img, Inbox
- **00 For Any AI**, **00 Start Here**
- 01 The First Five Minutes, 02 The Core Loop, 03 Rarity and RNG
- 04 Progression and Economy, 05 UI and HUD, 06 World and Look
- 07 Characters, VFX and Assets, 08 Mobile, 09 Shops and Monetization
- 10 Retention and Social, 11 Thumbnails, Icons and the Store Page
- 12 Live Ops and Launch, 13 Building It Right
- "Claude Design prompts", "assets", "skills" (partly cut off)

The pages are detailed design rules with screenshots of top games. Readable examples:
- **HUD layout maps** as ASCII diagrams for PC and for phone ("Phone (landscape, 844x390 notched / 800x360 short)").
  - The core verb button (ROLL, DIG, CLICK) sits bottom-centre at 1.5x size.
  - The menu grid sits middle-left, currencies top-right, and the Roblox corners are kept clear.
- "Readability on phones": "A 22 px label in a window scaled to 0.5 draws at 11 px"…
- "8. Text fitting and localisation": about half the players of a big game may not read English. Leave about 30% spare width. Prefer icon + number.
- "9. The no-HUD-clutter rule": when a player is confused, the first fix is never a new permanent widget.
- A "What the zones mean" table.

## 4. It's a paid product (Seen)
The last ~15 s show the creator's Discord server with these channels:
- buyers → #setup, #buyer-general, #faq
- Mentorship Stuff, #vouches, #sales

Buyers talk about:
- "the 200 dollar version"
- "everything in the zip is mutable by claude… ur claude can reconfigure anything… nothing locked down or dependent on me"
- "mac isnt supported YET"
- "I just asked obsidian to help me set it up"

So this is a sold kit: a Windows app plus an Obsidian vault plus Claude agent configs. It runs on the buyer's own Claude subscription.

## What I can't confirm
- That the game was really built "in less than a week while I sleep". The video shows a 435-approved / 120-changes-asked review history and v1497 saves, which means a lot of iterations. It doesn't show it being unattended.
- Revenue or player counts for their games. None were shown for their own games.
- Which tools sit under the hood: Studio MCP, Rojo, or Script Sync. None of them are visible by name.

## Audio
Not transcribed: the speech-to-text models could not be downloaded in the build environment. If the narration matters, add the key points here.
