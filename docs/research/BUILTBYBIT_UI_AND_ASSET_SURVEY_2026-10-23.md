# BuiltByBit Roblox survey: UI styles by game vibe, maps, models, VFX, templates (2026-10-23)

Source: builtbybit.com Roblox marketplace, read in the built-in browser on 2026-10-23. Purchase and download counts are from listing cards that day. Everything here is **OBSERVED** from listing screenshots and text unless tagged otherwise. Nothing was bought or downloaded. We learn layouts, techniques and numbers, then build our own originals. We never copy a paid pack's art or code (see section 8).

## 0. What was covered
| Area | Indexed | Looked at |
|---|---|---|
| Graphics & UI (1,390 listings) | 562 unique via popular list + 47 vibe tags | ~330 as thumbnail sheets; 2 packs at full resolution with pixel sampling; 6 top packs' full galleries |
| Game setups, Maps, Models, Animations & VFX | top 50 each by popularity | all 200 as thumbnails; 9 template descriptions + reviews |
| Scripts, Vehicles, Weapons, Clothing, Audio | top 50 each (Audio 28) | titles, prices, purchase counts only |

Biggest single fact: **"stud style" is the 2026 trend**. It is the top seller in UI (Studs UI Pack 2, 664 purchases), shows up in maps (Studs-Style plots map, stud island), models (stud animals, stud eggs, Mega Studs asset pack) and the #1 game template in our genre (Steal An Egg, 205 purchases) uses classic stud-textured plots.

## 1. UI style families, sorted by game vibe
Each family: who uses it, examples, then the recipe to rebuild it with plain Instances (our UIKit approach).

### A. Stud Cartoon (dominant 2026) — simulators, brainrot, steal-a-X, +1 speed, tycoons, pet/RNG
- **Examples:** Studs UI Pack 2 (664 purchases, $14.99), Essential STUD UI Pack (253), Roblox Simulator GUI Pack (free, 3,364 downloads), Stud Themed Shop UI (free, 2,731), UXR Stud UI Pack ($49.99, 36 panels), Ultra Stud UI Pack, Big Studded, Mega Studs ($59.99), Steal an Egg UI templates.
- **Look (measured on the free Simulator GUI Pack, 1920x1080 previews):**
  - Panel body dark charcoal `#32353A` (variants `#2E3237`, `#272A2C`) covered in an **embossed stud tile**: rounded squares ~22 px at 1080p, a hair darker with a lighter lower-right edge, very low contrast.
  - Panel rim: ~8 px lighter grey `#58585D` border, then a dark outline.
  - **Title bar** in the screen's colour (Rebirth red `#A92B06`→`#8A2609`, Playtime/Watch green, Index periwinkle, Daily neutral `#3A3A3A`), same stud emboss, a 2-4 px brighter inner rim (`#E0300C` on red), and **two diagonal translucent white "glass" stripes** over the left third.
  - Title text: white heavy geometric sans, outline is a **darkened shade of the bar colour** (not pure black) ~4 px, plus a soft lighter halo.
  - **Close button:** rounded square, red gradient light-top, a lighter pink inner ring (~4 px), dark maroon outer ring, white X with thick maroon stroke.
  - **Cards:** dark header strip with the same 2 diagonal stripes, body light-grey vertical gradient (`#979797` top → `#48484A` bottom) with stud emboss, 6 px corners, 2 px dark outline; amount text ("x100") white with dark stroke, bottom-right over the icon. Claimable card turns green (`#84AD72`), the big Day 7 card is orange with "OP!" in yellow `#E8C21F`.
  - **Buttons:** flat fill with stud emboss, darker bottom band (`#2CB517` body over `#238D15`), dark 2-3 px outline. Grey = neutral (`#727272`/`#888888`), purple = Robux skip (`#7A01A5`), green = buy/claim.
  - **Progress bars:** track `#2C2C2C`, fill green `#2A9715`→`#2BA713` with darker lower half, text centred white with stroke ("Cash: 5.4T$/1Qa$").
  - **Rarity chips:** pill buttons each in a tier colour with stud emboss (Normal silver, Gold yellow, Diamond cyan, Candy magenta, Vulcan orange, Rainbow purple).
  - **Backdrop splat:** an irregular paint-splash silhouette behind every window, tinted to the window colour. One image, reused.
  - Icons: glossy 3D renders with a 3 px black outline that **overflow the top of their tile** (side buttons).
- **HUD layout (identical across Studs UI Pack 2, Steal An Egg, UXR):**
  - Top centre: 3 big tab buttons (Shop / My Base / Upgrades, or Sell / Fuse).
  - Left: 2x2 or vertical stack of square icon buttons (Shop, Pass, Rebirth, Index), Daily Rewards pill above, red "!" badges.
  - Right: Starter Pack gift, X2 Money, X2 Luck gamepass buttons.
  - Bottom-left: currency in green with suffix ($572,831) + "Friend Boost +10%".
  - Bottom-centre: XP bar ("Level 5 57/100 XP") with Robux skip buttons (+5 / +10 / +25 Levels) and a 9-slot hotbar.
  - Bottom-right: active multiplier chips.
- **Screens every pack ships:** Daily Rewards (7-day grid, Day 7 big), Playtime Rewards (timed cells "18:18" → "Claim!", "Leaving Resets Progress!", Skip All for Robux), Index with rarity tabs and "(5/20)" counter, Rebirth (before → after multiplier, progress bar, Skip Rebirth for Robux), Season Pass (free row + premium row), Stock Shop with restock timer, Trading (two-side READY), Spin Wheel, Codes, Settings, Watch Ads reward.
- **Recipe (ours):** make our own 64x64 stud tile texture in Blender/PIL, tile it with `ImageLabel.ScaleType = Tile` at ImageTransparency ~0.85 over flat Frames. Title bar = Frame + UIGradient + the tile + 2 rotated white Frames at 0.85 transparency clipped by the bar. Text = FontFace bold geometric + UIStroke in `bar colour * 0.35`. Keep one splat image per window, `ImageColor3` tinted.

### B. Bright Glossy Cartoon (pre-stud classic) — speed/+1 games, obbies, cheap simulators
- **Examples:** 1 Speed GUI Template, Cartoons Style Simulator UI Pack, Blue Cartoonish Store UI, Simulator Style Spin Wheel, AzmanShop cartoon series, Shop UI ($1.99).
- **Look:** saturated vertical gradients (sky blue, lime, hot pink), thick black outlines, white text with black stroke, no texture, big rounded corners, star/sparkle decorations. Light or pastel panel interiors.
- **Recipe:** UIGradient light→dark + UIStroke 3 px black + UICorner 0.2 scale. Cheapest family to build; reads younger and lower-effort next to A.

### C. Anime Neon Frame — anime simulators, tower defense, RNG/summon games
- **Examples:** Anime Simulator UI Kit (34), Anime Style HUD + Frames, Anime RNG/TD Ultra UI, Anime Units UI, Anime Summon UI, Anime Battlepass.
- **Look:** dark navy/black panels, **rainbow or magenta-cyan gradient borders**, angled/slanted header tabs, glowing title text, card grids with rarity-coloured frames, "Summon x1 / x10" buttons, often a character art panel on one side.
- **Recipe:** UIStroke with a rotating UIGradient (animate `Rotation`, not the colour sequence), angled headers from rotated Frames, ViewportFrames for units.

### D. Dark Glass Modern — premium settings and menus in any genre (Sharman's pick, 2026-10-23)
- **Examples:** 3d Dynamic Settings System (39 purchases, $3.99), 9 Sleek Style Game UIs, Check UI Pack, Settings UI.
- **Look:** charcoal `#202126` panels near-opaque, thin white strokes at 85-90% transparency, pill tabs, inset rows, blue accent toggles and sliders, soft shadow, the world blurred or dimmed behind, **3D tilt toward the cursor**.
- **Status:** rebuilt from scratch in Studio, see section 7.

### E. Military / Tactical — milsim groups, FPS, SCP, army roleplay
- **Examples:** Project Alpha/Colossal/Tactical military main menus, Project Vangst (rank/credits), Battlelog, overhead nametag systems (v3/v4/v5), DEFCON control panel, death screens.
- **Look:** near-black flat panels, condensed/monospace caps, thin grey separators, cinematic soldier render backgrounds, one green DEPLOY button, rank insignia, overhead rank tags. Very little colour.
- **Fit for us:** none for the core game; useful only for reading what "flat dark" feels like.

### F. Light Minimal / App-like — hangout and roleplay, phones in games, profiles
- **Examples:** Modern light UI pack, Modern Payment UI, Discord UI template, Profile UI, Leaderboard UI, Avatar editor.
- **Look:** white/light grey cards, 12-16 px corners, small grey text, iOS-style toggles, emoji-free line icons.

### G. RPG / Fantasy — RPGs, dungeons, souls-likes, medieval
- **Examples:** RPG UI Kit, RPG Style UI Bars + Hotbar ("Souls-like"), Immersive RPG UI, Medieval UI pack, Wooden Styled Shop GUI, Dark Fantasy Spin Wheel.
- **Look:** ornate dark frames, deep red and gold, serif titles, slanted-end health/stamina bars, square hotbar slots with dark bevels, wood and parchment textures.

### H. Sci-fi / Cyber — sci-fi shooters, cyberpunk, space
- **Examples:** Sci-fi UI HUD, Sci-fi Health Bar, Futuristic Tech Index, Neon Simulator UI Kit, Project 2077 menu.
- **Look:** cyan/teal line art on black, angled corners, thin glowing strokes, scanline textures.

### I. Horror — horror games
- **Examples:** Horror Game Main Menu.
- **Look:** almost no UI, dark green-grey, flickering text, vignette.

### Vibe → family picker
| Game vibe | First choice | Second |
|---|---|---|
| Collect/steal/simulator/brainrot/+1 | A Stud Cartoon | B Glossy Cartoon |
| Anime simulator / TD / gacha | C Anime Neon | A |
| Cozy/premium menus in any game (settings, pause) | D Dark Glass | F Light Minimal |
| Roleplay / hangout | F Light Minimal | D |
| Military / FPS / SCP | E Tactical | H Sci-fi |
| RPG / dungeon | G RPG Fantasy | E |
| Horror | I Horror | E |

## 2. Maps (top 50 by popularity)
| Family | Examples (purchases) | What it teaches |
|---|---|---|
| Realistic city (PBR, roleplay) | California USA Big City (563), United States (361), Japan City (254), American (231), Compton (151), Fairfield (134) | The best sellers are huge RP cities at $6.99. Not our style |
| Stylized hand-painted | Stylized Japanese, Stylized Forest v2, Japanese School, Festival Village, Japanese Game Lobby, Anime-Stylized Japanese City (115), Stylized Seoul | Saturated foliage clusters, mushrooms/props for scale, warm lantern pools, bloom; $15-30 |
| Stud-style plots and islands | Studs-Style Plots Map (76), Stud-Style Island Map (130), Big Stud Map Pack | Bright plots fenced in a grid with a central path; floating islands linked by thin bridges; cheap ($5.99) |
| Arena maps | Azure/Mirage/Inferno Arena, Astral Combat Arena (72) | Circular centrepiece platform, one elemental theme per arena, framing walls |
| Interiors | Museum Map, Midnight Resort, Aurelis Nightclub, Luxury Penthouse, Grand Fantasy Library | Strong single lighting colour per room; props packed along walls |
| Sci-fi / neon | Futuristic Cyberpunk City (86), Coruscant border | Blue emissive strips, fog |
| Fantasy dungeon | Cartenon Temple Anime Dungeon, Crystal Cave, Anime Throne Boss Room | Blue/cyan glow, symmetry, a glowing floor sigil as the focal point |
- **Takeaway for our maps:** the stud plot map and the stylized lobby are the two references closest to a base-raiding game. Combine stud-revival plots (readable, cheap to render) with a stylized hub that has one warm-lit landmark.

## 3. Models (top 50)
- **Creature packs dominate:** Advanced (389), Stylized Nature Asset Pack (254), Low Poly Nature (205), Mythical Animals (167), Prehistoric Animals (153), Animals (135), Sea Animals (121), Classic Stud Eggs (115), 290/1,300 Pet Models. Most are voxel/stud creatures on a stage with a rainbow sky, sold by count ("400+ models").
- **Modular resource kits:** Stylized Crops, Stylized Ores (mining nodes), Stylized Medieval Village Houses, Treadmills, Lucky Blocks.
- **Lesson:** the store sells breadth; quality packs show each model on a podium, consistent palette, rigged where animated ("113 animated studded animals").

## 4. Animations and VFX (top 50)
- **Top sellers:** SoulShroud Ultimate VFX Pack (1,078), Ultimate RPG Combat & Loot VFX (604), 100+ Combat VFX (559), Movement Animation Pack (555), 80+ weapon animations (417), Tactical Combat (385), 500+ abilities/1,300 VFX (342).
- **Relevant to us:** loot/reveal VFX (hatch moments), RNG aura packs (45 HQ auras, 15 HQ aura) for rarity glows, movement packs. Combat packs are not our genre.

## 5. Game setups: what top templates include
- **Steal An Egg template (RCF Studio, 205 purchases, 40 screenshots):** walled stud plots, sleeping guard monsters (Zzz) protecting eggs, red screen vignette + "RUN!" banner + Drop button while carrying, egg shop popup with per-pet odds (65 / 30 / 4.5 / 0.5%) and x1/x3/x6 buy, Server Luck banner, Eggs quick menu with hatch timers, Gifts (free timed rewards for staying), Sell / Fuse top buttons, Slow Mode, Admin panel.
- **+1 Speed Keyboard Escape:** procedural keycap generation from a CollectionService tag, XP per key press, treadmills, global admin events across servers, stage skips for Robux.
- **Plush Factory Tycoon (224):** 3 floors, gamepasses (AutoCollect, x2 Money, x2 Gems, VIP, Flying Carpet), codes, rebirths, daily rewards, car spawner.
- **Review signals worth remembering:** "lacks many of the features needed for strong player retention ... below the 10th percentile" (Steal An Egg, 3-star); "some plants are VERY unoptimized ... so many unnecessary parts" (Grow a Garden template). Templates win on systems, lose on optimisation and retention depth.

## 6. Scripts, weapons, vehicles, clothing, audio (titles only)
- Scripts top: UXR systems (679), Advanced (327, 323), Dynamic (251), Billiards (165), Claw machine (151), Parry, Roll RNG.
- Weapons top: R6 weapons (467), Stylized weapons (403), OTS camera (290). Vehicles and clothing sell little. Audio is a tiny category (45 listings).

## 7. Rebuilt: 3D tilt settings panel (Dark Glass, family D)
- **Files:** `src/ui/Screen3D.luau` (ReplicatedStorage), `src/ui/Settings3D.client.luau` (StarterPlayerScripts). Screenshots: `assets/renders/settings3d_tilt_right.jpg`, `settings3d_tilt_left.jpg`.
- **How it works:** a SurfaceGui (in PlayerGui, Adornee = an invisible part parented to the camera) is sized each frame to exactly fill the view at 3 studs (`h = 2*d*tan(fov/2)`), then rotated up to 3 degrees toward the cursor with exponential smoothing. Background: DepthOfField focused at 3 studs plus a dark plane at 3.6 studs (DoF is quality-gated).
- **Verified in Studio (play mode):** renders sharp, centred, tilts the correct way for both cursor corners, dims the world, zero Output errors.
- **Learned the hard way:** a SurfaceGui with `AlwaysOnTop = true` on a camera-locked part did not render; BlurEffect blurs the SurfaceGui too; `CanQuery` must be true on the part for SurfaceGui input, so it is toggled with visibility.
- **Not verified:** clicking toggles, sliders and tabs. The MCP's synthetic clicks do not fire GuiButton events, even on a plain ScreenGui button. Needs a 30-second manual test. Settings do not save yet (wire to ProfileStore).

## 8. Licence rule for this marketplace
- Paid packs: learn layout, numbers and technique only; rebuild everything ourselves. Never import a purchased pack into a game unless Sharman bought it and its licence allows commercial use.
- Free packs: check the listing's licence or ask the author before using any asset; record it in `assets/SOURCES.md`.
- Stud textures, splats, icons: make our own (Blender/PIL) so every game owns its look.
