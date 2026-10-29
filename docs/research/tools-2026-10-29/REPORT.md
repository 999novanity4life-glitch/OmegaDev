# Wire Claude to references, not more generators

The biggest quality gain for OmegaDev does not come from a new 3D generator. It comes from closing three loops Claude cannot close today:

- **a visual review loop:** Studio `screen_capture` from fixed camera stations, compared against reference frames;
- **a design-tool loop for UI:** Figma or Penpot, which Claude can now write to and screenshot;
- **a scripted upload path:** Blender to Roblox through Open Cloud.

In order of impact, connect these:

1. The Roblox Studio MCP tools you already have but underuse (`screen_capture` with camera positions, `generate_texture` with a style `hintImage`, `upload_image`, the built-in scene-analysis and device-simulator skills).
2. **MCP for Blender** (free, MIT), whose `look` tool lets Claude see its own models and which pulls in CC0 Poly Haven assets.
3. The **Figma remote MCP**, which can now write to the canvas, plus a Figma-to-Roblox converter. **Penpot** is the free alternative.
4. A small **Open Cloud Assets API** uploader script.
5. **Scenario's MCP**, which trains a custom style model so icons, concepts and textures share one look.
6. **Meshy's official MCP** for low-poly props.

The Unity, Unreal and Godot MCPs are real and well built, but nothing they produce imports into Roblox, so skip them. Licences matter more than they look: free-tier output from Meshy, Tripo, Scenario and Midjourney is either attribution-only or non-commercial, and Hunyuan3D's open-weights licence excludes the EU, UK and South Korea.

The "AI slop" problem is mainly missing references, tokens and image-based panels. Research on Claude's creative connectors found that "stylistic requests get generic results" unless Claude is given references ([Godberry Studios](https://godberrystudios.com/posts/claude-for-creative-work-9-connectors-tested-2026/)). Tools only help once that art direction exists.

## Twelve tools ranked by impact on Roblox art and UI

The ranking weighs three things: how much each tool raises *shipped* visual quality in Roblox, how directly its output carries into Studio, and how much it costs this team (one Apple Silicon MacBook Air, Claude Code, Studio MCP and bpy already in use). "Mac" means the MCP process or app runs on Pranay's machine. "Cloud" means a remote server: Claude can reach it from any session, including this cloud container.

| # | Tool | What it adds | How it carries into Roblox Studio | Cost | Where it runs | Status |
|---|---|---|---|---|---|---|
| 1 | **Roblox Studio MCP (built-in), underused tools** | `screen_capture` with `camera_position`/`look_at_position` for repeatable shots; `generate_texture` with `hintImage`; `generate_procedural_model` from a reference image; `upload_image` from HTTP URLs; skills such as rbx-scene-analysis and rbx-device-simulator-lua | Native: it *is* Studio | Free; no generation quotas or prices published | Mac (Studio binary); generation runs on Roblox servers | Already connected |
| 2 | **MCP for Blender** (ahujasid/blender-mcp, now "mcp-for-blender") | `look` (viewport/render capture), `execute_blender_code`, Poly Haven / Sketchfab / Poly Pizza import, `generate_3d` (Rodin, Hunyuan3D, Tripo, Meshy) | FBX/GLB export, then Open Cloud or the 3D Importer | Free, MIT; generation through it needs your own provider keys or "Premium" at $10–20/mo (vendor-reported) | Mac (localhost socket into Blender 3.0+) | Verified README |
| 3 | **Figma MCP (remote)** + a Figma→Roblox converter (GuiForge, Framewisp, UILint v2) | Claude writes real frames, components and variables (`use_figma`) and checks them with `get_screenshot` | Converter makes Studio instances or React-Lua/Luau modules; Claude moves them into `src/client` | Needs Professional plan or above with a Full seat (seat price not fetched); writing is free during beta; converters are paid with prices not published | Cloud (remote), or desktop server on the Mac | Verified docs; converters are new (mid-2026) |
| 4 | **Open Cloud Assets API uploader** (custom script, `asphalt` or `rbxcloud`) | Headless upload of FBX/glTF/GLB/rbxm/images, with operation polling and returned asset IDs | Returns `rbxassetid`s for `insert_asset` and `Config.luau` | Free API key (no price stated); asphalt is free | Mac or cloud container | Verified docs; Assets API is beta |
| 5 | **Scenario MCP** | Trains a custom style model on 10–30 images; generates icons, concepts and textures in that style; also 3D | PNGs go to Studio through `upload_image`, or into Blender as texture sources | Pro $45/mo needed for training; Starter $15 has no training | Cloud | Verified vendor page; per-tool detail not published |
| 6 | **Meshy MCP** (official) | Text/image→3D, remesh, retexture, UV unwrap, rig; "Smart Topology" budgets | GLB, then bpy cleanup, then upload; Meshy has a documented Roblox workflow | 100 free credits/mo (output CC BY); about 20 credits per generation; paid plans include commercial rights | Local npx process; generation in Meshy cloud | Verified docs |
| 7 | **CC0/CC-BY asset libraries** (Poly Haven, ambientCG, Kenney, Quaternius, game-icons.net) | Clean PBR materials, HDRIs, kit pieces, UI 9-slices, icons | Through Blender (Poly Haven via #2) or as images through `upload_image` | Free | Web/Blender | Verified |
| 8 | **Penpot MCP** (official) | Same write-and-screenshot loop as Figma: `execute_code`, `export_shape`, tokens | Exported PNG 9-slices and tokens; no Roblox converter found | Free, open source | Cloud or local (`@penpot/mcp`, Node 22); the Penpot tab must stay open | Verified docs |
| 9 | **Recraft MCP** | Vector (SVG) and raster icons, custom styles, background removal, upscaling | SVG rasterised to PNG (asphalt can convert SVG to PNG), then upload | Subscription credits; per-image price not stated | Cloud | Verified docs |
| 10 | **fal.ai MCP** | Pay-per-run gateway to Flux and image-to-3D models; `get_pricing` | Same as #5 and #6 | MCP free; pay per run | Cloud | Verified docs |
| 11 | **Official Blender Lab MCP** / Anthropic's Blender connector | Docs-grounded bpy and screenshots; no asset import or generation | Same as #2 | Free, GPL-3.0 | Mac (Blender 5.1+; one review says 4.5 LTS+) | Verified, with a version conflict |
| 12 | **Adobe for Creativity, Canva and Affinity connectors** | Photoshop/Firefly/Illustrator edits and batch exports | Exported PNGs, then upload | Needs an Adobe account; Claude connectors need a Pro plan or higher | Cloud (Adobe, Canva); Affinity is a local app | Exists in the claude.ai directory |

Sources for the table:

- Studio tools: [Roblox Studio MCP docs](https://create.roblox.com/docs/studio/mcp.md). `generate_texture`, `segment_mesh` and the parameter details come from the live tool schemas in this Studio build, which the docs page does not yet list.
- Blender: [blender-mcp README](https://raw.githubusercontent.com/ahujasid/blender-mcp/main/README.md) and [StraySpark](https://www.strayspark.studio/blog/official-blender-mcp-server-comparison-2026), a vendor-reported comparison with a conflict of interest. Also [Blender Lab](https://www.blender.org/lab/mcp-server/).
- Figma: [Figma MCP FAQs](https://help.figma.com/hc/en-us/articles/39252411778583-Figma-MCP-server-FAQs) and [Write to canvas](https://developers.figma.com/docs/figma-mcp-server/write-to-canvas).
- Open Cloud: [Open Cloud assets guide](https://create.roblox.com/docs/en-us/cloud/guides/usage-assets).
- Image and 3D services: [Scenario pricing](https://www.scenario.com/pricing), [Meshy AI integration](https://docs.meshy.ai/de/api/ai), [Meshy pricing](https://docs.meshy.ai/en/webapp/pricing), [Penpot MCP](https://help.penpot.app/mcp/), [Recraft MCP](https://recraft.ai/docs/mcp-reference/getting-started), [fal MCP](https://fal.ai/docs/model-apis/mcp).
- Creative connectors: [Godberry Studios](https://godberrystudios.com/posts/claude-for-creative-work-9-connectors-tested-2026/).

Why this order. Studio's own tools rank first because they are free, already connected, and the only place the final pixels exist. `screen_capture` takes an optional camera and look-at target, so Claude can photograph the same "photo stations" after every change instead of judging from code ([Roblox docs](https://create.roblox.com/docs/studio/mcp.md)). **MCP for Blender ranks above every generator** because its `look` tool gives Claude eyes inside Blender, so it can check silhouette and scale before export. Its one-call Poly Haven import gives CC0 PBR materials and HDRIs with no licence risk ([README](https://raw.githubusercontent.com/ahujasid/blender-mcp/main/README.md)).

**Figma is the strongest UI lever** because its MCP is no longer read-only. `use_figma` "creates and changes real design content: components, variables, frames, and auto layout" ([Figma dev docs](https://developers.figma.com/docs/figma-mcp-server/write-to-canvas)). That gives Claude a design-then-see loop before any Luau is written. Scenario sits below the structural tools because a custom style model only fixes consistency once a style exists to train on. Meshy sits below Scenario because, for stylised sci-fi, hard-surface kit pieces kitbashed in Blender from CC0 packs are often cleaner than single-image AI meshes (an inference from [Wavect](https://wavect.io/blog/ai-3d-model-generators-game-development-2026/), which lists parametric and low-poly tools as the topology-safe options).

A registry conflict needs flagging. A search of the claude.ai connector directory on 29 Oct 2026 returned Figma, Adobe, Canva, SketchUp, Wonder, Magic Patterns, Moda and Unsplash, but **no Blender connector**. Third-party coverage, however, says Anthropic launched a Blender connector on 28 Apr 2026, alongside Adobe, Fusion, SketchUp and others ([mcpplaygroundonline](https://mcpplaygroundonline.com/blog/claude-creative-connectors-adobe-blender-ableton.md); [Gigazine](https://wbgsv0a.gigazine.net/gsc_news/en/20260429-claude-for-creative-work)). Treat the claude.ai Blender connector as **unverified for this account**, and use the local MCP instead. Separately, the directory listing for the Figma connector shows only read-style tools (`get_design_context`, `get_screenshot`, `get_variable_defs`). The write tool `use_figma` is documented for Figma's remote MCP server, so add that server to Claude Code directly rather than relying only on the claude.ai connector.

## Connect these five first, on the Mac and in the cloud

The first-wave stack costs nothing except a Figma seat, and it covers all three missing loops. The Mac-local servers must be added in the Claude Code session that runs on Pranay's MacBook Air. The remote HTTP servers also work from cloud sessions.

```bash
# 0. Roblox Studio MCP — already connected. If it needs re-adding on the Mac, use
#    Studio: Assistant → … → Manage MCP Servers → "Enable Studio as MCP server" → Quick connect (Claude Code).
#    Binary: /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP

# 1. MCP for Blender (Mac). Prereqs: Blender 3.0+, Python 3.10+, uv.
brew install uv
uvx mcp-for-blender setup            # installs/links the Blender add-on (helper per README)
claude mcp add blender uvx mcp-for-blender
export DISABLE_TELEMETRY=true        # telemetry may be used to train AI models unless disabled
# Optional hardening: BLENDER_MCP_SAFE_MODE=1 ; keep the socket on localhost only.

# 2. Figma remote MCP (cloud). Needs Professional plan or above + Full seat to write outside drafts.
claude mcp add --transport http figma https://mcp.figma.com/mcp     # UNVERIFIED exact syntax: standard remote-HTTP pattern

# 2b. Free alternative: Penpot (remote key from Account → Integrations → MCP Server)
npx -y add-mcp -g -n penpot <YOUR_PENPOT_MCP_URL>
#     or local: npx -y @penpot/mcp@stable  then load http://localhost:4400/manifest.json in Penpot

# 3. Open Cloud uploader (Mac or cloud). Create an API key in Creator Dashboard with asset read/write.
export ROBLOX_OPEN_CLOUD_KEY=...     # never commit it
cargo install asphalt                # or Homebrew / Rokit / mise; images, audio, models, fbx/gltf/glb
#     or a ~30-line script: POST https://apis.roblox.com/assets/v1/assets (x-api-key),
#     then poll GET https://apis.roblox.com/assets/v1/operations/{id} until done.

# 4. Scenario MCP (cloud). Custom style training needs the Pro plan ($45/mo).
claude mcp add --transport http scenario https://mcp.scenario.com/   # UNVERIFIED exact syntax; see help.scenario.com setup guide

# 5. Meshy MCP (local process, cloud generation)
npx add-mcp @meshy-ai/meshy-mcp-server --env MESHY_API_KEY=<key>
```

Sources for these commands: the Blender commands and the safety and telemetry flags come from the [MCP for Blender README](https://raw.githubusercontent.com/ahujasid/blender-mcp/main/README.md). The Studio quick-connect path is in the [Roblox Studio MCP docs](https://create.roblox.com/docs/studio/mcp.md), and Penpot setup is in the [Penpot help](https://help.penpot.app/mcp/). The asphalt install and its required `asset:read`/`asset:write` key scopes are in the [asphalt README](https://github.com/jackTabsCode/asphalt), and the Assets endpoints and polling flow are in the [Open Cloud assets guide](https://create.roblox.com/docs/en-us/cloud/guides/usage-assets). The Meshy command is from [Meshy docs](https://docs.meshy.ai/de/api/ai), Scenario's server URL is from [Scenario](https://www.scenario.com/features/mcp), and Figma's server URL and plan rules are from the [Figma FAQs](https://help.figma.com/hc/en-us/articles/39252411778583-Figma-MCP-server-FAQs). The `claude mcp add --transport http` form for Figma and Scenario is the standard Claude Code pattern for remote servers; neither vendor page in the notes confirmed it.

Second-wave options are worth adding once the first five are working:

```bash
claude mcp add --transport http --scope user fal https://mcp.fal.ai/mcp-relay   # pay-per-run gateway (OAuth)
claude mcp add --transport http recraft https://mcp.recraft.ai/mcp              # UNVERIFIED syntax; OAuth, vector icons
```

The fal command is quoted verbatim from [fal's docs](https://fal.ai/docs/model-apis/mcp). The Recraft URL comes from [Recraft's docs](https://recraft.ai/docs/mcp-reference/getting-started).

Two practical cautions. First, **Figma's rate limits gate the free plans out**: Full and Dev seats on Starter get no MCP calls, and View and Collab seats get 20 a month, so a Professional plan is required for real iteration. Professional allows 200 calls a day at 10 a minute. Writing to the canvas is "free during the beta period" but "will eventually become a usage-based paid feature" ([Figma FAQs](https://help.figma.com/hc/en-us/articles/39252411778583-Figma-MCP-server-FAQs)). Second, **both Blender MCPs execute arbitrary Python**. The community server's socket has no authentication, and the Blender Lab page recommends running in a VM ([README](https://raw.githubusercontent.com/ahujasid/blender-mcp/main/README.md); [Blender Lab](https://www.blender.org/lab/mcp-server/)). Pranay's Mac should keep the port on localhost and avoid running untrusted .blend files through it.

## A six-stage pipeline that respects Roblox's hard limits

Roblox constrains art more tightly than Unity or Unreal, and those limits decide which tool sits where:

- **20,000 triangles per mesh** ([Roblox specs](https://create.roblox.com/docs/art/modeling/specifications)).
- **One UV set, with UVs in 0–1** (overlapping UVs are allowed).
- **OpenGL tangent-space normal maps only.**
- **A practical 1024×1024 per-map budget.** The texture docs say "up to 4096×4096" in one place and "1024×1024 pixel spaces" in another ([texture specs](https://create.roblox.com/docs/art/modeling/texture-specifications)).
- **No custom shaders.** Stylisation has to be baked into albedo or emissive, or come from lighting and post-processing.

| Stage | Tool (who drives it) | Key settings and checks |
|---|---|---|
| **1. Concept** | Scenario custom style model (or fal Flux) → PNG concept sheets; references curated by Sharman | One style anchor for all assets; front, side and back views reduce invented backs |
| **2. Mesh** | Meshy MCP (props, Smart Topology 2k–10k tris); `generate_3d` in MCP for Blender (Rodin/Hunyuan/Tripo); Studio `generate_mesh` only for placeholders; CC0 kit pieces for hard-surface | Prefer low-poly or quad modes; Tripo P1 outputs 2k–20k faces; Rodin up to 2M faces always needs decimation |
| **3. Blender cleanup** | MCP for Blender `execute_blender_code` + `look` | Decimate/Remesh to under 20k tris (split big props), Smart UV and pack, delight and flatten albedo, Cycles high→low bake at ≤1024 (Albedo, OpenGL Normal, Roughness, Metal, Emissive), apply transforms, FBX with Path Mode Copy + Embed Textures + "FBX Unit Scale" + no leaf bones |
| **4. Open Cloud upload** | Script or asphalt, from Mac or cloud | `POST /assets/v1/assets` as Model (≤20 MB), poll the operation, write the assetId to a manifest or `Config.luau`; keep FBX as the source because only FBX supports `PATCH` content updates |
| **5. Studio** | Studio MCP `insert_asset` + `execute_luau` | Add SurfaceAppearance with uploaded map IDs, set CollisionFidelity, apply MaterialVariants from `generate_material` or CC0 maps, set Lighting/Atmosphere/ColorCorrection/Bloom |
| **6. Screenshot review** | Studio `screen_capture` at fixed camera stations + a fresh Claude subagent | Blind-rank captures mixed with reference frames on palette, value contrast, silhouette, density and lighting mood; then playtest and `get_console_output` per the definition of done |

Sources for the table:

- Generation and topology: [Meshy Roblox workflow](https://www.meshy.ai/tutorials/3d-model-for-roblox-workflow); [inker](https://inker.si/blog/best-ai-3d-model-generators-2026) and [3daistudio](https://www.3daistudio.com/blog/rodin-2-5-vs-tripo-vs-hunyuan-3d-comparison), both reseller blogs that need caution.
- Blender export settings: [Roblox export requirements](https://create.roblox.com/docs/art/modeling/export-requirements).
- Upload: [Open Cloud assets guide](https://create.roblox.com/docs/en-us/cloud/guides/usage-assets).

Two choices in this pipeline are less obvious than they look. **Use Open Cloud rather than the official Roblox Blender plugin.** The plugin uploads through Open Cloud and keeps package IDs stable, but it logs in with browser OAuth and accepts only bug fixes ([Roblox Blender plugin](https://raw.githubusercontent.com/Roblox/roblox-blender-plugin/main/README.md)), which makes it a poor fit for unattended Claude runs. An API-key script is a better fit. Roblox's own guide also still recommends the Studio 3D Importer for custom models, because it previews and error-checks ([assets guide](https://create.roblox.com/docs/en-us/cloud/guides/usage-assets)). The pragmatic split is to put hero assets through the Importer once, then use Open Cloud `PATCH` for later iterations.

**Do not run the open-weights generators on the MacBook Air.** In a hands-on report, TRELLIS.2 on Apple Silicon needed about 18 GB of RAM at peak, and its author says "24GB is the real minimum". PBR baking took 66–224 minutes and produced unusable red-noise textures ([lilting.ch](https://lilting.ch/en/articles/trellis2-m1-max-hands-on)). Reach those models through cloud APIs instead (fal, or Tencent Cloud through MCP for Blender).

The stage that matters most for Sharman's goal is stage 6. The native pieces exist: `screen_capture` with camera targets, a `screen_capture` subagent type, and a device-simulator skill that pairs `execute_luau` with captures for multi-device UI checks (the last two from the live tool schema). However, **no image-diff or VLM-critique MCP was found**, so the loop has to be assembled from these parts.

There is also a sourcing gap for the reference itself. Moon Sweepers is a DragDrop Games co-op incremental "clean the Moon" game, released 23 Oct 2026 at $8.99 and rated Very Positive ([Steam](https://store.steampowered.com/app/5335510/Moon_Sweepers/)). It drew over 36,000 concurrent players ([Automaton](https://automaton-media.com/articles/newsjp/20261026-475509/)). But **no written source describes its HUD, fonts or palette**. Sharman needs to drop 5–10 screenshots into the vault, or Claude needs to view them through a browser tool, before any of the review loop can judge "looks like Moon Sweepers". Train any Scenario style model on the team's own paintovers, not on another studio's screenshots.

## UI quality comes from native modifiers and image panels

Roblox's UI toolbox is richer than flat Frames suggest:

- **UIStroke** offers inner/outer positioning, miter joins and a child UIGradient, which makes chrome bevels possible.
- **UIShadow** offers blur, spread, inset and gradient tint, which gives the orange glow.
- **UICorner** supports a different radius per corner.
- **UIGradient** adds radial and conic types as a beta.
- **StyleSheets with `StyleQuery` breakpoints** let theme tokens live in one place ([Appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers); [Styling](https://create.roblox.com/docs/en-us/ui/styling/compatibility)).

Pro-looking Roblox UI still leans on image assets. Both Framewisp and GuiForge rasterise what Roblox cannot express (blur, skew, mixed or custom fonts) into images ([Framewisp](https://devforum.roblox.com/t/framewisp-%E2%80%94-turn-a-figma-frame-into-native-roblox-ui-in-one-click/4759239); [GuiForge](https://devforum.roblox.com/t/guiforge-roblox-ui-editorfigma-export/4834077)). Custom fonts still appear to need BMFont sprite sheets ([Custom Fonts Module](https://devforum.roblox.com/t/custom-fonts-module-cfm/2814574)); that is inferred, not stated by Roblox. The fix for "slop" is therefore a theme token module, 9-slice carbon-weave and chrome panels made once in Figma or Penpot, layered native modifiers, and a recoloured icon set. Whether the beta UIGradient and UIShadow flags work in published experiences is **unverified**, so test before relying on them.

None of the Figma-to-Roblox converters writes Rojo files, which matters because OmegaDev treats files as the source of truth. **GuiForge** is the closest fit: it exports Luau modules, React-Lua (beta) or `.rbxmx`, all of which can live in `src/client`. **Framewisp** and **UILint v2** produce Studio instances only. Framewisp also drops auto-layout, so elements end up at absolute positions, and it bakes custom-font text into images. That conflicts with rule 5 (mobile-first Scale and safe insets) and with localisation ([DevForum: UILint v2](https://devforum.roblox.com/t/plugin-uilint-v2-import-figma-ui-into-roblox-studio/4765869)). All three appeared in mid-2026 and none publishes a price.

The most robust route is to use Figma or Penpot as the *visual spec*: Claude writes it with `use_figma`, reads tokens with `get_variable_defs`, and compares against `get_screenshot`. Claude then hand-writes the Luau with the repo's Juice and RemoteGuard conventions, and compares Studio's `screen_capture` to the Figma screenshot. Converters serve as a bootstrap at most.

For free bases, Kenney's CC0 UI Pack includes nine-slice frames, with Sci-Fi and Mobile Controls packs alongside. game-icons.net offers about 4,100 SVG icons under CC BY 3.0, with per-artist credit required ([Cinevva](https://app.cinevva.com/guides/free-game-ui-kits-fonts)). For reference, Game UI Database is free and holds over 55,500 screens, but it has no API ([AlternativeTo](https://alternativeto.net/news/2024/8/game-ui-database-2-0-launches-with-over-55-500-screens-and-enhanced-tools-for-ui-designers/)). Pick screens by hand and save them into the vault.

## What not to bother with, and why

| Skip | Reason |
|---|---|
| **Unity MCPs** (official AI Assistant, CoplayDev, IvanMurzak) | They control C#, scenes, URP/HDRP shaders and builds, and none of that imports into Roblox. The official one also needs Unity 6+ and a Unity AI subscription ([Unity blog](https://unity.com/blog/unity-ai-mcp-how-to-get-started)) |
| **Unreal MCPs** (UE 5.8 experimental plugin, chongdashu) | Blueprints, Nanite and Lumen do not transfer. chongdashu's is marked "not for production" and needs a C++/Xcode build ([README](https://raw.githubusercontent.com/chongdashu/unreal-mcp/main/README.md)) |
| **Godot MCP** | Godot scenes and GDScript have no Roblox path ([README](https://raw.githubusercontent.com/Coding-Solo/godot-mcp/main/README.md)) |
| **SketchUp and Fusion connectors** | Built for CAD and architecture. Their `.skp` output has poor game UVs and topology, and Fusion is a subscription that is weak at surfacing ([Godberry](https://godberrystudios.com/posts/claude-for-creative-work-9-connectors-tested-2026/index.md)) |
| **3ds Max MCP** | 3ds Max is Windows-only, so it cannot run on the MacBook Air (general knowledge) ([CGPress](https://cgpress.org/archives/3dsmax-mcp-connects-claude-to-3ds-max.html)) |
| **Maya, Houdini, ZBrush, Substance MCPs** | Community-only and **unverified**, with costly licences. Substance Painter is the one exception if someone already owns a licence, because its OpenGL PBR exports map 1:1 to SurfaceAppearance |
| **Midjourney** | No official API in the sources found, and private mode needs the $60 Pro tier ([LicenseOrg](https://licenseorg.com/blog/midjourney-license-explained)) |
| **Local TRELLIS/Hunyuan on the Air** | Needs 24 GB+ of RAM and produces broken textures ([lilting.ch](https://lilting.ch/en/articles/trellis2-m1-max-hands-on)) |
| **Community Roblox Studio MCPs** | boshyxd's server was archived on 2026-06-06. The Chrrxs fork adds breakpoints and multi-client playtests, but its Mac support is not stated, and it mostly duplicates the built-in MCP plus the rbx-debug skill ([boshyxd](https://github.com/boshyxd/robloxstudio-mcp); [Chrrxs](https://github.com/Chrrxs/robloxstudio-mcp)) |
| **Paid Blender MCPs** (Blender MCP Pro, StraySpark) | Vendor-reported tool counts in the hundreds, but the free server already covers what this pipeline needs ([StraySpark](https://www.strayspark.studio/blog/official-blender-mcp-server-comparison-2026)) |

The steelman for engine MCPs is lookdev: rendering a lighting reference in Unreal. Blender does this for free, and it is already on the Mac. Roblox has no custom shaders anyway, so a Lumen render sets an expectation Roblox's Future lighting cannot meet.

Pro builder plugins are a different case. F3X, Archimedes, GapFill, Model Reflect, ResizeAlign and Part to Terrain are the community canon ([DevForum, Jan 2026](https://devforum.roblox.com/t/the-best-plugins-for-builders/4207930)), but they are GUI-only with no MCP. Their maths (arcs, mirrored CFrames, wedge gap-fills, `Terrain:FillBlock`) is better reproduced as a studio-owned Luau build-kit module that Claude calls through `execute_luau`. That is an inference, and the APIs must be checked against the engine reference under rule 8.

## Licence gotchas that can sink a shipped asset

| Source | Free tier | Paid tier | Gotcha |
|---|---|---|---|
| Meshy | CC BY 4.0 (attribution) | Commercial rights, private licence | Pay before generating anything you ship |
| Tripo | Public and non-commercial (CC BY 4.0) | Rights cover "models generated during the subscription" | Generations made before upgrading stay non-commercial (aggregator source) |
| Scenario | Personal/evaluation only | Full commercial licence, no royalties | Training on Moon Sweepers screenshots risks copying another studio's IP |
| Hunyuan3D 2.0 open weights | — | — | Territory excludes **EU, UK, South Korea**; licence needed above 1M MAU; outputs may not train other models |
| Stability (SF3D) | Free under $1M annual revenue | Enterprise above that | SPAR3D not named on the licence page |
| Midjourney | Trial images CC BY-NC | Over $1M revenue needs Pro/Mega | Basic and Standard images are public in the gallery |
| Rodin | 10 credits | Creator $24, Business $120 (aggregator) | Contracts auto-renew and generally cannot be cancelled within the term |
| Synty | — | Paid licence names Roblox | Allowed while assets stay "under your direct control"; never re-share them as Creator Store models |
| Sketchfab | Mixed CC licences | — | Check each model; exclude NC and ND; credit CC-BY |
| game-icons.net | CC BY 3.0 | — | Credit each artist |
| Poly Haven, ambientCG, Kenney, Quaternius | CC0 | — | Safest choice |
| blender-mcp | Telemetry on by default | — | Set `DISABLE_TELEMETRY=true` |

Sources for the table: [Meshy pricing](https://docs.meshy.ai/en/webapp/pricing); [CostBench Tripo](https://costbench.com/software/ai-3d-generation/tripo-ai/); [Scenario pricing](https://www.scenario.com/pricing); [Hunyuan3D-2 LICENSE](https://huggingface.co/tencent/Hunyuan3D-2/blob/main/LICENSE); [stability.ai/license](https://stability.ai/license); [LicenseOrg](https://licenseorg.com/blog/midjourney-license-explained); [CostBench Rodin](https://www.costbench.com/software/ai-3d-generation/rodin-hyper3d/); [Synty FAQ](https://syntystore.com/community/faq); [Sketchfab Download API](https://api.sketchfab.com/developers/download-api); [Cinevva](https://app.cinevva.com/guides/free-textures-hdris-materials); [Quaternius FAQ](https://quaternius.com/faq.html); [blender-mcp](https://github.com/ahujasid/blender-mcp).

Two gaps are material for a monetised game. First, **who owns output from Roblox's own GenerationService (Cube 3D) was not found**. Second, Cube 3D's "open source" weights are listed under a research-only licence ([Wikipedia: Cube 3D](https://en.wikipedia.org/wiki/Cube_3D), a secondary source). The safe practice is a provenance log in the vault for every shipped asset, recording tool, plan, date and prompt. Without one, Tripo's "during the subscription" clause, or a free-tier CC BY generation, cannot be defended later.

## Open gaps and unverified items

Several facts that affect spend or the pipeline are still unconfirmed:

- **Prices not fetched:** Figma seat prices, prices for Framewisp, UILint and GuiForge, Recraft's per-image cost, SyntyPass, and Meshy's monthly plan prices (only per-generation credit costs were found).
- **Roblox generation limits:** no quota or price was found for Roblox's `generate_mesh`, `generate_texture` and `generate_material`.
- **Per-map texture size:** whether SurfaceAppearance accepts 2048 maps or caps them at 1024 is contradictory in Roblox's docs. Settle it by importing a 2048 map and running `inspect_instance`.
- **Glass-box material conversion:** whether an Open Cloud Model upload from glTF creates the SurfaceAppearance automatically is unconfirmed.
- **Docs that lag the live build:** the Studio docs do not list `generate_texture` or `segment_mesh`, and they disagree with the live schema on `subagent` types.
- **Tool-count conflict:** the MCP for Blender README lists about 9 tools; StraySpark reports 36.
- **Blender Lab version requirement:** 5.1+ per the Blender Lab page, 4.5 LTS+ per a review.
- **Unverified tools:** Maya, Houdini, Substance and ZBrush MCPs; Tripo's community MCP; roimport; the "figma-to-roblox-ui" skill; and the community Roblox MCPs from hope1026, kolvian and dmae97 all come from directory listings only.
- **Not researched:** Wonder and Magic Patterns, which do appear in the claude.ai directory; Leonardo, OpenAI image, Gemini/Imagen, Layer.ai and Firefly as image sources; whether Sloyd or CSM have an MCP; any independent stylised-asset topology benchmark; and what top Roblox games do for UI.
- **Moon Sweepers' visual language:** still needs screenshots.
- **Blender connector for this account:** not confirmed. The claude.ai directory search did not return it, despite launch coverage.

## Conclusion

The tool landscape changed in 2026 in a way that favours this studio. Figma's MCP gained write access, Roblox Studio became an MCP server with style-referenced generators, and Open Cloud started accepting FBX and glTF models by API. Together, these make a **fully agent-driven, closed-loop art pipeline** possible with almost no new spend. What is missing is not capability but **judgement inputs**: reference frames, a token system, and fixed camera stations that turn "looks like Moon Sweepers" into a test Claude can fail.

The practical implication is to spend the first week on stage 6 and stage 1, not stage 2:

- capture stations and a blind-review rubric;
- 5–10 curated reference screens in the vault;
- a theme token module with chrome, carbon and orange values;
- one Scenario style model trained on the team's own paintovers.

After that, every generator downstream inherits a consistent style instead of contributing its own generic look. The failure mode to avoid is adding Meshy, Rodin and fal before those anchors exist. That produces more assets that drift in style, faster, and only makes the "AI slop" worse.
