# UI icon quality research: making Steal a Dream's icons pop (2026-10-13)
For *Steal a Dream*. Requirement from Sharman (STYLE_GUIDE non-negotiable): icons must be glossy, outlined and high quality like the top Roblox games, never emoji or dull flat images. Current v1 uses emoji/text (a clover for Luck, a plain circle for Dream Dust). The step-by-step recipe distilled from this is `reference_dev\ICON_PIPELINE.md`.

Tags: **[DOC]** official Roblox/Blender docs. **[FORUM]** DevForum/community reports. **[LOCAL]** checked on this PC today. **[JUDGMENT]** Claude's reasoning. **UNVERIFIED** means not confirmed and to be tested before relying on it.

## 1. Bottom line
1. **Top simulator UIs are image-based.** Each menu button is a custom PNG icon on a styled tile. The icons are not Studio shapes [FORUM: "most of the UI in games like Pls Donate and Pet Simulator 99 are all image-based"]. BIG Games has never published its icon workflow, so the exact pipeline behind PS99 icons is UNVERIFIED.
2. **The look has the same parts everywhere.** Chubby rounded objects shown 3/4 from slightly above, saturated colours with a light-to-dark gradient, a specular "candy" highlight top-left, a **thick dark outline baked into the PNG**, and often a soft glow or sparkle. Commission briefs describe it as "bright, playful" "Pet Sim / BGS style" icons, and artists produce them either as 2D vector art (Photoshop/Illustrator) or as Blender renders finished in Photoshop [FORUM]. The Photoshop finish is a layer stroke of **6-15 px, positioned Outside**, plus inner shadow and a colour overlay [FORUM tutorial 2895762].
3. **Roblox cannot outline an image's shape.** A UIStroke on an ImageLabel strokes the rectangle border, not the drawn object [DOC inference: "applies to the border" for non-text objects]. So **the outline has to be baked into the PNG**. Tile strokes, tile gradients and shadows can be live in Roblox.
4. **Best pipeline for Claude: Blender (local, Eevee) → Python post-process (outline + alpha bleed) → upload → ImageLabel on a gradient tile.** Everything runs on this PC with tools already present: Blender 5.2, and Python with Pillow 12.3, numpy 2.4 and scipy 1.17 [LOCAL]. It is consistent, original, has no license risk, and can be re-rendered when the style changes.
5. **Fastest stopgap: Microsoft Fluent Emoji "3D" PNGs** (MIT licence, 256×256, transparent) plus the same outline post-process. Every icon we need exists in the set (§5). They look glossy and 3D, far better than flat emoji, but they're generic, recognisable as Microsoft emoji and only 256 px. Use them as placeholders, and replace hero icons with Blender renders.
6. **Upload.** The Studio MCP has `upload_image` ("uploads a batch of images from HTTP URLs ... returning an image path to asset ID map") and `store_image` (local file → image URI) [DOC]. Assets go to the account or group that owns the open place, which is Sharman's. Whether a `http://127.0.0.1` URL works is UNVERIFIED, so test with one icon first. The fallback is that Sharman drags the folder into Studio Asset Manager > Import. Every image passes moderation, usually within "a few hours" [DOC].

## 2. How the top games' icons are built (what to copy)
| Trait | What it looks like | How we reproduce it |
|---|---|---|
| Form | Chunky, rounded, exaggerated (fat coin, puffy egg, oversized clover). No thin parts | Bevel every edge in Blender; minimum feature width ≈ 6% of the icon |
| View | 3/4 view from ~15-25° above, a slight yaw, often a small tilt for energy | Camera elevation 20°, yaw 25°, roll 0-8° |
| Colour | Saturated base, lighter top and darker bottom (gradient), coloured shadows (not grey) | Principled base colour + Standard view transform (not AgX, which desaturates) |
| Gloss | A bright specular blob or stripe top-left plus a rim highlight | Low roughness + Coat layer; key light top-left, coloured rim light back-right |
| Outline | Thick dark outline, often dark-tinted rather than pure black (e.g. dark purple on purple items) | Post-process: dilate alpha, fill #160A2B, composite under |
| Sparkle | Small 4-point stars or glints on rare/premium items | A sparkle mesh in the render or a separate sparkle PNG layered in Roblox |
| Growth | The value ladder grows the object (shoe → pile → chest in ref 03) | Render variants: 1 dust mote → pile → jar → chest |
| Placement | Icon sits on a rounded gradient tile with a stroke and drop shadow, **pokes out of the tile's top edge**, chunky label overlapping the bottom edge, red "!" badge top-right | Luau recipe in ICON_PIPELINE §6 |
| Motion | Idle bob/tilt, periodic shine sweep, pop on hover/press, scale-punch on gain | TweenService (sine, infinite reverse) + UIGradient offset sweep |

UI packs sold for "Steal a Brainrot" and "Grow a Garden" style games ship frames and buttons but **explicitly not icons**: "Icons are not Inclued" (hopsdev pack), and icons in other packs are made by separate artists [FORUM/itch]. The icon art is the scarce, high-value part, so it's worth doing properly.

## 3. Pipelines compared
| Pipeline | Quality | Cost | Claude can run it? | License risk | Verdict |
|---|---|---|---|---|---|
| **A. Blender render + post-process** | Highest, fully on-style, any subject | Free | Yes: BlenderMCP execute_code + Eevee render + local Python | None (our own work) | **Primary** |
| B. Fluent Emoji 3D + post-process | Good, glossy, but generic, 256 px max | Free | Yes (fetch PNGs; downloading needs Sharman's OK) | MIT, keep the notice in SOURCES.md | **Placeholder / filler** |
| C. ViewportFrame live 3D | Good for Dreamlings (real model), no baked outline, limited lighting (Ambient, LightColor, LightDirection only [DOC]) | Free, no upload | Yes | None | **Use for Dreamling cards and hatch reveal only**, not menu icons |
| D. Studio `generate_mesh` → ViewportFrame or Blender | Unknown quality; textured mesh from text | Free inside Studio (quotas UNVERIFIED) | Yes (MCP tool) | Roblox-generated, owned in Studio (terms UNVERIFIED) | Optional source of base meshes; still needs Blender restyle |
| E. AI image (free Gemini image tier) | Can look great; no alpha, style drift between icons | Free tier is shaky (§7) | Partly (SketchForge used it 2026-09-09) | Google claims no ownership; 18+ rule | Concept art and reference only |
| F. Free 2D icon packs (game-icons.net, Kenney) | Flat or monochrome, not the target look | Free | Yes | CC BY 3.0 / CC0 | Only as silhouettes to model from |
| G. Commission an artist | Highest | Robux/USD | No | Contract | Later, for the game icon/thumbnail if budget appears |

### 3a. Blender details (Blender 5.2 local, AMD RX 9070 XT, Eevee)
- **Engine: Eevee.** It's fast on AMD, and Cycles HIP on this GPU is untested. Film > **Transparent ON**. Resolution 1024×1024, downscaled to 512 later for clean anti-aliasing.
- **Colour management: View Transform = Standard, Look None.** The default AgX (and the newer ACES views in 5.0) compress saturated colours [JUDGMENT, common practice]; the genre wants punchy colours.
- **Material, "candy gloss":** Principled BSDF with Roughness 0.25-0.35, **Coat Weight 0.5-0.8, Coat Roughness 0.03-0.08**, Specular IOR Level 0.5. Glowing items get Emission 0.5-2 in their own colour. Optional cel look (Eevee only): Diffuse BSDF → Shader to RGB → ColorRamp (Constant, 3 stops: shadow tint, base, highlight) mixed with a Glossy layer for the specular blob.
- **Lights (3-point, coloured):** Key Area 2 m at upper-left front (≈(-2.5,-3,4)), 800-1200 W, warm white. Rim Area at back-right, pink (1.0,0.55,0.85), 400-700 W. Fill Area front-right, cool blue (0.6,0.7,1.0), 150-250 W. World: solid dark violet (0.05,0.03,0.10) at strength 0.3-0.6. A CC0 studio HDRI from Poly Haven would be better reflections, but downloading needs Sharman's OK.
- **Shadows:** No ground plane. Disable shadows where they muddy the icon; a DevForum fix for stray shadows on icon renders was "disable shadows on objects" [FORUM].
- **Outline options:**
  - (i) **Post-process silhouette outline (recommended).** Works in any Blender version, gives exact pixel thickness, and keeps every icon identical.
  - (ii) **Inverted hull** for interior contour lines: Solidify modifier, Flip Normals ON, Material Offset 1, thickness ≈ 2-3% of the object size, with an outline material using Emission black/plum and Backface Culling ("Camera" checkbox in 4.2+/5.x) [DOC/FORUM]. Use it when an icon needs inner lines, such as egg spots or the book cover edge.
  - (iii) Freestyle: slower and fiddly. Its 5.x status is UNVERIFIED.
  - (iv) Grease Pencil Line Art: the API moved in 4.3+/5.0 [DOC], so avoid it.
- **Framing:** Orthographic camera (or 50 mm), object fills ~80% of the frame, centred, with 6-8% padding left for the outline and glow.

### 3b. ViewportFrame vs images
Static ViewportFrames "don't re-render unless you make a change" and cost about the same as images. Many spinning ones lag, especially in scrolling grids and on low-end phones, and developers with large inventories pre-render to images [FORUM: boatbomber; several perf threads]. UIShadow, UIStroke and outlines can't follow a 3D model inside a viewport. **Decision [JUDGMENT]:** menu, currency and shop icons are PNGs. Dreamling odds tiles, Journal cards and the hatch reveal use ViewportFrames, which show the real model; spin only the hovered or revealed one.

## 4. Upload realities
| Fact | Detail | Tag |
|---|---|---|
| Who uploads | Images become assets owned by the user or group that owns the game, so they must be uploaded under Sharman's account (Studio logged in as him, or his Creator Hub) | [DOC] |
| Cost | Image/decal uploads cost no Robux (long-standing; no price listed in docs) | UNVERIFIED (no fee shown in any official page read) |
| Formats | .png, .jpeg, .bmp, .tga | [DOC Open Cloud] |
| Size | Open Cloud: "smaller than 8000x8000" and up to 20 MB per call. In-game textures/images are widely reported downscaled to **1024×1024** max | [DOC] / [FORUM] |
| Our spec | **512×512 PNG RGBA**, under 300 KB each. Forum consensus is that 512 is a safe target that stays crisp on phones | [FORUM] |
| Moderation | Every import enters moderation, generally approved "within a few hours"; an unapproved image is invisible to players | [DOC] |
| Monthly cap | No monthly image-upload cap found in docs (audio has 10 unverified / 100 ID-verified). Creator Store *distribution* of images is capped (10 unverified / 200 verified per 30 days), which doesn't matter for private in-game use | [DOC] |
| Edges | Transparent PNGs show white or dark fringes in Roblox because hidden RGB bleeds in under bilinear filtering; Roblox's own answer is "color bleeding" (premultiplied alpha not on the roadmap). Fix with an alpha-bleed step (PixelFix, alphafix [MIT/Apache], or our scipy script) | [FORUM] |
| Images can't be updated | A new version means a new asset ID ("Not available for updating") | [DOC Open Cloud] |

**Claude's upload paths:**
1. **Studio MCP `upload_image` from a local HTTP server.** Run `python -m http.server 8765 --bind 127.0.0.1` in the export folder, then pass `http://127.0.0.1:8765/icon_dust.png`. Whether the fetch happens inside Studio (where localhost would work) or on Roblox servers (where it would fail) is **UNVERIFIED**, so test one icon first. Each upload puts an asset on Sharman's account, so ask him before each batch.
2. **`store_image` → `upload_image`.** `store_image` turns a local path into an "image URI" for other tools. Whether `upload_image` accepts that URI is UNVERIFIED and worth one test, because it would avoid the HTTP server.
3. **Fallback (always works):** Sharman opens Studio > Asset Manager > Import and selects the 512 PNGs (multiple at once). Claude then reads the new IDs with `search_game_tree` or the Asset Manager, or Sharman pastes them.
4. Open Cloud API key upload: needs Sharman to create an API key, and Claude must never handle the key itself (prohibited). Not recommended.

Asset IDs go in one module, `ReplicatedStorage.Config.Icons` (`Dust = "rbxassetid://..."`), so a re-render only changes one line.

## 5. Source catalog (licences checked 2026-10-13)
| Source | What | Licence | Fit |
|---|---|---|---|
| **Microsoft Fluent Emoji** (github.com/microsoft/fluentui-emoji) | ~1,500 emoji in 3D, Color, Flat and High Contrast styles. The 3D style is 256×256 transparent PNG (checked: four_leaf_clover_3d.png = 256×256, 37 KB) | **MIT**, "Copyright (c) Microsoft Corporation"; keep the notice in assets\SOURCES.md | Placeholder icons with a 3D look. Folders confirmed present: Ghost, Crescent moon, Wrapped gift, Egg, Shopping cart, Sparkles, Cloud, Crystal ball, Basket, Gem stone, Star, Glowing star, Books, Closed book, Counterclockwise arrows button, Cyclone, Bed, Zzz, Shooting star, Milky way, Hatching chick, Money bag, Coin, First quarter moon face, Package, Calendar, Trophy, Four leaf clover |
| **Kenney** (kenney.nl) | 2D/3D game assets incl. Board Game Icons (250+), Game Icons (105) | **CC0**, commercial OK, credit optional; don't use the Kenney logo | Clean but flat; silhouettes or base models |
| **Quaternius** (quaternius.com) | Low-poly 3D packs (fantasy props, RPG, food) | **CC0**, commercial OK, modification OK | Base meshes for Blender renders (chest, potion, coin) |
| **Poly Haven** (polyhaven.com) | HDRIs, textures, models | **CC0** | Studio HDRI for icon reflections |
| Poly Pizza | Low-poly models | Mixed per model (many CC-BY 3.0 from Google Poly) | Check each model; credit CC-BY |
| game-icons.net | 4,000+ monochrome SVG icons | **CC BY 3.0**, credit required ("Icons made by {author}. Available on https://game-icons.net") | Silhouette reference only |
| Flaticon | Huge icon library incl. 3D | Free tier needs attribution; redistribution limits | Avoid (attribution and terms friction) |
| Icons8 "3D Fluency" | Glossy 3D icons | Free tier needs a link attribution, size limits; commercial terms unclear | Avoid |
| Roblox Creator Store images | Community decals | Per-asset; free models are risky (stolen art) | Avoid for icons |
| Typbloxian "Free Simulator UI Pack" | PSD of frames, **no icons** | Informal: credit, practice only | Not usable for release |

Note: Fluent Emoji are MIT for copyright purposes, but the style is recognisably Microsoft's. Not a legal problem [JUDGMENT], but it weakens our own look, so use them as placeholders only.

## 6. Proposed icon style: "Dream Candy"
- **Shape language:** Puffy, rounded, bevelled. Every icon carries one tiny **4-point sparkle** (the dream motif). No sharp corners, no thin lines, readable at 48 px.
- **Camera:** 3/4 from above (elevation 20°, yaw 25°). Hero objects tilt 8° clockwise.
- **Light:** Key from the **top-left at 45°**, pink rim back-right, cool fill front-right. The specular blob always sits upper-left.
- **Outline:** **14 px dark plum #160A2B (22,10,43) at 512 px** (2.7%), plus a 3 px inner light rim (a white edge highlight at 35% opacity on the top-left only) for the "pop".
- **Glow:** Rare and premium icons get a soft outer glow in their key colour (blur 18 px, 50%) baked outside the outline.

| Icon | Subject | Key colours (RGB) |
|---|---|---|
| Dream Dust (currency) | A puffy pink-lilac **star-dust orb** with a swirl of glitter (the "plain circle" becomes a glowing sphere with stars inside) | core (255,214,255), mid (255,138,216), shade (155,63,209), sparkle (255,240,160) |
| Dream Shards (2nd currency) | Faceted crystal shard | (120,220,255) → (90,110,255) |
| Luck | Four-leaf clover with a gold star in the centre | mint (91,240,160), shade (30,150,110), star (255,201,60) |
| Cloud Egg | Lilac-white egg with soft cloud puffs and blue spots | (243,237,255), spots (143,211,255), shade (170,150,230) |
| Shop | Woven **basket** overflowing with dust orbs (matches ref 01 "Store" basket) | wicker (255,184,90) / (190,110,40), ribbon (255,95,162) |
| Rebirth | Spiral swirl arrow, cyan to violet | (92,225,255) → (160,102,255) |
| Index / Dream Journal | Chunky purple book with a gold star clasp and a crescent on the cover | cover (122,75,255), clasp (255,201,60), pages (255,246,230) |
| Daily rewards | Gift box with a gold ribbon and a sparkle | box (255,95,162), ribbon (255,201,60) |
| Sleep | Crescent moon with "Zzz" | moon (255,216,107), Zzz (200,190,255) |
| Ghost (dream ghost / steal) | Round lilac ghost with a cyan glow and a little sack | body (237,230,255), glow (143,243,255) |
| Multiplier chips | Small round badge, "x2" chunky text | per boost type |

**Rarity frames** (tile gradient top → bottom; stroke darker):
| Rarity | Top | Bottom | Stroke |
|---|---|---|---|
| Common | (205,205,220) | (140,140,165) | (70,70,90) |
| Uncommon | (120,235,130) | (50,170,80) | (20,90,40) |
| Rare | (110,190,255) | (40,120,235) | (15,55,130) |
| Epic | (200,120,255) | (130,50,220) | (65,20,120) |
| Legendary | (255,225,90) | (255,150,30) | (140,70,0) |
| Mythic | (255,110,160) | (220,30,90) | (110,10,45) |
| Secret | rainbow conical UIGradient rotating | — | (20,10,40) |

Menu tiles use the night palette instead: top (120,70,220) → bottom (60,30,130), stroke (22,10,43) 3 px, with the icon poking 15% above the tile.

## 7. Free AI image generation (option E), terms
- **Gemini API terms:** "Google won't claim ownership over that content". Google may produce similar outputs for others. Unpaid-tier inputs and outputs may be used to improve Google's products and seen by human reviewers. **Users must be 18+** and must not build products aimed at under-18s with the Services. A Roblox game's audience skews young, so using the API's *outputs* as art is different from offering the Service to players; whether this clause matters for static art is UNVERIFIED (ask before relying on it). [DOC]
- **Free-tier image quota is unstable:** third-party reports say quotas were cut in Dec 2025, Nano Banana Pro has 0 free RPD, and forum users hit 429 errors after a single request. SketchForge got a free image on 2026-09-09 [LOCAL memory], so it currently works, but limits are UNVERIFIED.
- Outputs have no alpha, so they need background removal; rembg isn't installed and nothing was installed. Style also drifts from icon to icon.
- **Use:** concept sketches to pick shapes, then model in Blender. Local diffusion is blocked on this PC (no CUDA, Smart App Control blocks ROCm, per memory).

## 8. Open questions for Sharman
1. Approve the "Dream Candy" style (plum outline, pink rim light, sparkle motif)?
2. OK to use Fluent Emoji 3D as placeholders this week while Blender icons are made? (Download from GitHub, MIT.)
3. OK for Claude to upload icon batches to your account via Studio MCP (one test icon first)?

## Sources
- Roblox Studio MCP tool list (upload_image, store_image, generate_mesh): https://create.roblox.com/docs/studio/mcp
- Asset moderation and import: https://create.roblox.com/docs/projects/assets , https://create.roblox.com/docs/projects/assets/manager
- Open Cloud asset limits/formats: https://create.roblox.com/docs/cloud/guides/usage-assets
- Creator Store distribution limits / verification: https://create.roblox.com/docs/production/publishing/account-verification
- Texture spec (1024 standard): https://create.roblox.com/docs/art/modeling/texture-specifications
- 1024 downscale request thread: https://devforum.roblox.com/t/approval-feature-request-allow-images-higher-than-1024x1024-to-be-uploaded-to-roblox-studio/1741374
- UI appearance modifiers (UIStroke border rule, UIGradient): https://create.roblox.com/docs/ui/appearance-modifiers
- UIShadow class: https://create.roblox.com/docs/en-us/reference/engine/classes/UIShadow.md (GA status UNVERIFIED; pending in release notes 712-716 per https://devforum.roblox.com/t/release-notes-for-716/4565301)
- ViewportFrame: https://create.roblox.com/docs/ui/viewport-frames ; perf: https://devforum.roblox.com/t/are-viewportframes-moreless-efficient-than-images/254323/13 , https://devforum.roblox.com/t/performance-issues-with-lots-of-viewportframes-mostly-occurring-on-low-end-devices/958962
- Image-based UI in PS99: https://devforum.roblox.com/t/unique-or-good-looking-ui/2914121
- Simulator UI tutorial (stroke 6-15 px Outside, PixelFix): https://devforum.roblox.com/t/how-to-make-ui-styled-for-simulator-detailed-tutorial/2895762
- Blender-made icons with Solidify outlines: https://devforum.roblox.com/t/roblox-desktop-icons-made-in-blender/757759 ; pet icon renders: https://devforum.roblox.com/t/pet-and-item-icon/286230
- Alpha halo: https://devforum.roblox.com/t/weird-white-outline-on-imageguis/26001 ; alphafix: https://lib.rs/crates/alphafix
- Shine sweep: https://devforum.roblox.com/t/uigradient-animation/2637300 , https://github.com/ryanlua/Shime , https://devforum.roblox.com/t/open-source-simple-ui-shineglint-module/4816664
- Icon resolution: https://devforum.roblox.com/t/does-a-game-icon-need-to-be-512x512/673216
- Inverted hull / backface culling: https://www.katsbits.com/codex/?p=9407 , https://docs.blender.org/manual/en/dev/render/eevee/material_settings.html
- Blender 5.0 colour management: https://developer.blender.org/docs/release_notes/5.0/eevee/ , https://osarch.org/2025/11/18/blender-5-0-released/
- Fluent Emoji: https://github.com/microsoft/fluentui-emoji (LICENSE: MIT)
- Kenney licence: https://kenney.nl/support ; Quaternius: https://quaternius.com/faq.html ; game-icons: https://game-icons.net/about.html
- Brainrot UI pack (no icons): https://hopsdev.itch.io/brainrot-starter-pack ; Typbloxian pack: https://devforum.roblox.com/t/free-simulator-ui-pack-by-typbloxian/1436927
- Gemini API terms: https://ai.google.dev/gemini-api/terms ; free-tier image reports: https://discuss.ai.google.dev/t/does-gemini-2-5-flash-image-preview-have-free-tier/100509
