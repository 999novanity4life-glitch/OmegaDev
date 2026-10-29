# Roblox-native AI/building tools and the pro indie art pipeline (as of 2026-10-29)

Method note: about 16 search/fetch calls, plus a direct read of the tool schemas exposed by the user's connected Roblox Studio MCP (`mcp__remote-devices__Roblox_Studio__*`, loaded on 2026-10-29). Those schemas are primary evidence of what the user's Studio build exposes. Where this note says "schema", it means that live tool definition. YouTube was not used.

## 1. What can Roblox Studio's built-in MCP do, what is underused, and what are its quality ceilings?

### Takeaway
On 2026-10-28 the official docs list 26 tools. The user's live Studio also exposes `generate_texture` and `segment_mesh`, which the docs table does not yet list. The underused tools are the generators (procedural models from reference images, AI texture re-skins, MaterialVariant generation), `screen_capture` with scripted camera positions, and the built-in `skill` docs (scene-analysis, device-simulator). The ceilings are hard: generated meshes top out at 20k triangles, and Roblox caps PBR texture maps at 1024×1024, so Roblox's own generators cannot produce a hero-quality art direction on their own.

### Cited Findings
- **Official tool list (26 tools; docs updated 2026-10-28):**
  - Scripts: script_read, multi_edit, script_search (max 10 results), script_grep (max 50 matches).
  - Generation and assets: generate_mesh, generate_material, generate_procedural_model, wait_job_finished, search_asset, insert_asset, upload_image, store_image.
  - Agents and docs: subagent, skill, http_get (allow-listed Roblox docs only).
  - Scene and runtime: search_game_tree, inspect_instance, execute_luau (Edit/Client/Server datamodel), get_studio_state, start_stop_play, get_console_output, screen_capture, character_navigation, user_keyboard_input, user_mouse_input, list_roblox_studios.
  - Every call takes `studio_id`.
  - Setup: Assistant → … → Manage MCP Servers → "Enable Studio as MCP server", then Quick connect for Claude Code. The Mac binary is at `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`.
  - [Roblox docs: Connect to the Studio MCP server](https://create.roblox.com/docs/studio/mcp.md)
- **generate_mesh (schema):** "Generates a textured mesh from a prompt." `maxTriangles` must be 12–20000. Optional bounding-box `size`. `segmentation` is auto, none or explicit, with at most 8 named parts. Has an `async` mode that you poll with wait_job_finished. — [Roblox docs MCP page](https://create.roblox.com/docs/studio/mcp.md) (tool exists); limits are from the live tool schema on the user's Studio.
- **In-Studio mesh generation:** reported default of 10,000 triangles. The MCP tools generate_mesh, generate_material, Creator Store insert and screen_capture shipped in the Assistant update of March 19, 2026. This is a secondary source. — [BloxBot guide, 2026-03-22](https://www.bloxbot.ai/guide/roblox-studio-mesh-generation-mcp-tools)
- **generate_procedural_model (schema):**
  - Builds objects from primitives (blocks, spheres, cylinders, wedges) as a `ProceduralModel`, with user-editable attributes such as size, colour and proportions.
  - Accepts a reference image through `attachedImageUri`, which comes from `store_image` (png/jpg, max 5 MB).
  - Supports up to 8 named parts. Recommended to run async.
  - The docs describe it as "Accepts reference images and custom part schemas." — [Roblox docs](https://create.roblox.com/docs/studio/mcp.md)
- **generate_material (schema):**
  - Inputs: one of 40 base materials (Plastic … Rubber), `materialPattern` Regular or Organic, a free-text description and an id.
  - Returns a BaseMaterial plus a MaterialVariant name. You must set both on BaseParts yourself, for example via execute_luau.
- **generate_texture (schema; not in the docs table):**
  - "Re-textures an existing mesh using AI, given a text prompt… Replaces the source in place."
  - Takes an optional `hintImage` reference image for style.
  - Modes: "Fast" (default), or "Quality", a research preview that first generates a reference image from an auto-selected view.
- **segment_mesh (schema; not in the docs table):** "Segments an existing mesh into named sub-parts using AI… up to 5 part names". Returns a new sibling Model.
- **subagent (schema):** types are listed as `explore`, `screen_capture` and `unit_test`. Explore subagents can run Luau queries. The docs list the types as `explore` and `playtest`, so the docs and the live schema disagree. — [Roblox docs](https://create.roblox.com/docs/studio/mcp.md)
- **skill (schema):** built-in Roblox skills are rbx-create-skill, rbx-debug, rbx-device-simulator-lua, rbx-docs-search, rbx-perf-profiling (MicroProfiler via LibMP), rbx-scene-analysis (SceneAnalysisService: rendering, memory, instance composition) and rbx-unit-test. rbx-create-skill means custom skills can be authored.
- **screen_capture (schema):** captures the edit-time viewport. Optional `camera_position` and `look_at_position` temporarily move the camera, which allows repeatable, scripted "photo stations" for visual review.
- **upload_image (schema):** uploads a batch of images from HTTP URLs, for example a localhost server or the Figma MCP, to the Roblox asset server and returns rbxassetid values. This is the built-in route for getting Blender-baked textures and UI art into the game.
- **Texture ceilings:** "Roblox supports up to 1024×1024 pixel spaces for texture maps." PBR maps are albedo, normal (OpenGL tangent-space only), roughness, metalness and emissive mask. Only one UV set is allowed, and UVs must be in 0–1 (overlap is OK). Upload formats are png, jpg, tga and bmp. — [Roblox texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications.md)
- **RDC 2025 (2025-09-05):** Assistant became an MCP client and Studio an MCP server, so Assistant can drive third-party tools such as Figma layouts and Blockade Labs skyboxes. The same event announced:
  - 4D object generation (prompt → scripted, functional object, starting with vehicles and weapons).
  - Text-to-Speech, Speech-to-Text and real-time voice translation.
  - A dynamic asset-quality pipeline and SLIM (scalable lightweight interactive models).
  - [Roblox newsroom RDC 2025](https://about.roblox.com/newsroom/2025/09/roblox-rdc-2025); [Roblox IR release](https://ir.roblox.com/news/news-details/2025/Roblox-Unveils-AI-Monetization-and-Performance-Innovations-for-Creators/default.aspx)
- **Cube 3D:**
  - Announced and open-sourced March 2025 (GitHub Roblox/cube; Hugging Face cube3d-v0.1 and v0.5). Licence is listed as "Cube3D Research-Only Rail-MS", which conflicts with the "open source" label.
  - Over 1.8 million assets generated.
  - 4D early access in November 2025, public beta in February 2026, with modes Car-5 (modular) and Body-1 (single mesh).
  - Source is Wikipedia, so verify the dates against Roblox posts. — [Wikipedia: Cube 3D](https://en.wikipedia.org/wiki/Cube_3D); [Roblox newsroom Mar 2025](https://about.roblox.com/newsroom/2025/03/unveiling-future-creation-native-3d-generation-collaborative-studio-tools-economy-expansion); [GDC 2025 coverage](https://www.creativebloq.com/ai/gdc-2025-roblox-says-its-new-ai-generator-will-allow-groundbreaking-4d-creation)
- **Texture Generator** (beta) and **Avatar Auto Setup** (alpha) were both announced on DevForum. — [Texture Generator Beta](https://devforum.roblox.com/t/texture-generator-beta/2880635); [Avatar Auto Setup Alpha](https://devforum.roblox.com/t/avatar-auto-setup-alpha/2880686)
- **Secondary (RoWatcher, 2026-03-31):**
  - Material Generator makes tileable PBR (diffuse, normal, roughness) from text.
  - Avatar Auto Setup predicts joints and produces an R15 rig with cages. Roblox surveys cite 60–70% time savings.
  - "Luau Assist" covers inline autocomplete plus chat. This is the source's name for what the brief calls Code Assist.
  - Scene generation and level blocking, plus AI playtest agents, are announced.
  - [RoWatcher](https://rowatcher.com/news/roblox-ai-tools-in-2026-what-s-actually-changed-for-developers)

### Inferences
- The highest-leverage underused combination for art quality is: Blender bake → local HTTP server → `upload_image` → `execute_luau` to build SurfaceAppearance/MaterialVariant → `screen_capture` from fixed camera stations → VLM critique. Roblox's generators are best kept for filler props, quick greybox (procedural model), and re-skinning (generate_texture with a `hintImage` taken from a Moon Sweepers reference frame).
- generate_texture with a reference `hintImage` and generate_procedural_model with a reference image are the only native tools that take style references. They are the closest native route to "match this look".
- AI generators trained on Roblox meshes (Cube) are likely to drift toward a generic Roblox look. A curated kit plus a strict palette and lighting is likely to matter more for a Moon Sweepers match than any generator. This is an inference.
- Everything runs inside Studio on the Mac. Generation itself runs on Roblox's servers, with no cost stated in any source found.

### Gaps
- No official quotas, rate limits or pricing for generate_mesh, generate_texture or generate_material were found.
- The docs have not caught up on generate_texture and segment_mesh, so I found no official dates for them.
- 4D generation availability through the MCP is unverified; no MCP tool for it is exposed.
- No primary source was found for a "Code Assist" product name; the closest match is Luau Assist (secondary source).
- The Texture Generator and Auto Setup thread dates were not fetched. The thread IDs suggest about March 2024, but this is unverified.

## 2. Which community tools and MCPs add capability beyond the built-in one (Open Cloud upload, batch asset ops)?

### Takeaway
The best-known community server (boshyxd/robloxstudio-mcp) was archived on 2026-06-06 and points to the Chrrxs fork. That fork adds breakpoints, multi-client playtests and runtime eval. Open Cloud is what closes the upload gap: its Assets API accepts FBX/glTF Models, rbxm, Roblox meshes and animations from a script. That allows a Blender → Roblox pipeline that runs from the Mac or the cloud without Studio clicks.

### Cited Findings
- **boshyxd/robloxstudio-mcp:**
  - MIT licence, about 485 stars. Archived 2026-06-06 and now read-only, with the README recommending the Chrrxs fork.
  - Full edition has 43 tools (v2.7.0-next.6). An inspector edition has 31 read-only tools: mass_get_property, compare_instances, export_build, search_materials, get_asset_thumbnail, preview_asset, capture_screenshot and others.
  - Install: Studio plugin + "Allow HTTP Requests" + `npx -y robloxstudio-mcp@latest`.
  - No Open Cloud upload.
  - [GitHub boshyxd/robloxstudio-mcp](https://github.com/boshyxd/robloxstudio-mcp); [DevForum thread](https://devforum.roblox.com/t/v260-roblox-studio-mcp-speed-up-your-workflow-by-letting-ai-read-paths-and-properties/3707071?page=3)
- **Chrrxs/robloxstudio-mcp (fork):**
  - v2.23.1, MIT, about 177 stars.
  - Adds eval_server_runtime and eval_client_runtime, breakpoints, get_runtime_logs, solo_playtest, multiplayer_playtest, profiling, Creator Store tools, screenshots and mouse/keyboard input.
  - Mac support is not stated.
  - [GitHub Chrrxs/robloxstudio-mcp](https://github.com/Chrrxs/robloxstudio-mcp)
- **Other community servers found:**
  - [Mishaadevv/Roblox-MCP](https://github.com/Mishaadevv/Roblox-MCP): launch/close Studio, open places, scene/GUI building, Toolbox inserts, Play Solo.
  - [dax8it/roblox-mcp](https://github.com/dax8it/roblox-mcp).
  - [m4bwav/roblox-agent cloud skill](https://github.com/m4bwav/roblox-agent/blob/main/skills/roblox-agent-cloud/SKILL.md): an agent skill around Open Cloud. I did not read its contents in depth.
- **Open Cloud upload support (2025-10-23):**
  - Models can be uploaded "with either an FBX or glTF file". rbxm and rbxmx work for Models and Animations, and Roblox-format meshes are supported.
  - Plugins cannot be uploaded with an API key.
  - Legacy Upload.ashx, UploadNewMesh and UploadNewAnimation endpoints are to be deprecated.
  - [DevForum: Open Cloud Upload Support for More Asset Types](https://devforum.roblox.com/t/open-cloud-upload-support-for-more-asset-types/4022082); [Open Cloud assets usage guide](https://create.roblox.com/docs/cloud/guides/usage-assets); [Assets API intro](https://devforum.roblox.com/t/introducing-open-cloud-assets-api/2245171)
- **Luau Execution API:** runs Luau against a place headlessly, announced as beta. Useful for CI checks without Studio. — [DevForum beta announcement](https://devforum.roblox.com/t/beta-open-cloud-engine-api-for-executing-luau/3172185)
- **Place Publishing API** exists, described by an API catalogue. — [apis.io: Open Cloud Place Publishing](https://apis.io/apis/roblox/roblox-open-cloud-place-publishing/)

### Inferences
- A thin script (Node or Python with an Open Cloud API key) could do the following, all on the Mac or in a cloud container:
  1. Upload Blender-exported FBX/glTF.
  2. Poll the operation.
  3. Return asset IDs into `Config.luau` or an asset manifest.
- No Studio is needed for that; only an API key with asset write scope.
- The built-in MCP plus Open Cloud likely covers what most community servers add. The Chrrxs fork's distinctive features (multi-client playtest, breakpoints) are only partly matched natively, through the rbx-debug skill.

### Gaps
- 0CE4NS/claude-roblox-gamedev-kit: not found or verified in my searches, so treat it as unverified.
- I found no dedicated MCP that wraps Open Cloud asset upload (only the m4bwav skill, unread in detail).
- Open Cloud upload rate limits and size limits were not stated in the sources fetched.

## 3. Which Roblox building plugins do pros use for world quality, and which can Claude script?

### Takeaway
The community canon in January 2026 was F3X, Archimedes, Resurface, Beveler, Terrain Adjuster, Stravant plugins (GapFill, ResizeAlign, Model Reflect), Part to Terrain and the Performance Heatmap. All of these are GUI plugins with no MCP API. Most of what they do, though, is CFrame and geometry maths that Claude can reproduce directly with `execute_luau`.

### Cited Findings
- "The Best Plugins for Builders" (2026-01-02) lists F3X, Archimedes, Performance Heatmap, Resurface, Beveler, Terrain Adjuster, "Stravant and Load character", and Part to Terrain. Replies add GapFill ("lifesaver when it comes to filling stuff up") and Reflect. — [DevForum, 2026-01-02](https://devforum.roblox.com/t/the-best-plugins-for-builders/4207930)
- Older canon threads: [What plugins are you using](https://devforum.roblox.com/t/what-plugins-are-you-using/576629); [List of building tools](https://devforum.roblox.com/t/list-of-building-tools/558358); [Building techniques](https://devforum.roblox.com/t/new-builder-building-techniques/997814)

### Inferences
- The scriptable equivalents via execute_luau are:
  - Archimedes: arc and rotate-copy around an edge.
  - GapFill: a wedge pair between two edges.
  - Model Reflect: mirror a CFrame across a plane.
  - ResizeAlign: extend a face to meet a face.
  - Part to Terrain: `Terrain:FillBlock`, `FillBall` and similar.
  - Lighting, Atmosphere, post-processing (Bloom, ColorCorrection, DepthOfField, SunRays), Future lighting and Atmosphere presets: these are plain properties, so they are fully scriptable.
- A studio-owned Luau "build kit" module that reproduces these would serve Claude better than driving the plugin GUIs with computer-use.
- Moon Animator is GUI-only; Claude cannot drive it reliably.

### Gaps
- No primary pages were fetched for the individual plugins (authors, prices, current maintenance). The brief's mention of Brushtool and Moon Animator was not verified this session.
- Exact API names for Terrain and post-processing should be checked against the engine reference before use (CLAUDE.md rule 8).

## 4. Asset sources and licences: which packs are legal in a monetized Roblox game?

### Takeaway
CC0 kits (Quaternius, Kenney, Poly Haven) are the clean choice: commercial use, no attribution. Synty's paid licence explicitly names Roblox. It allows use when the assets stay "under your direct control" and are not shared or sublicensed, so a commercial Roblox game is allowed but republishing models to the Creator Store is not. Sketchfab is mixed CC licences that need per-model checks and attribution.

### Cited Findings
- **Quaternius:** "All models are under the CC0 License." Free for commercial use, credit not required, modification allowed, .blend and FBX available. — [Quaternius FAQ](https://quaternius.com/faq.html)
- **Kenney:** "All of my #gameassets are CC0 licensed." — [Kenney on X](https://x.com/KenneyNL/status/1989626866336993559)
- **CC0 aggregator list** (includes Poly Haven): [awesome-cc0](https://github.com/madjin/awesome-cc0)
- **Synty FAQ (Metaverse section):**
  - Users of creation platforms "like Roblox, Second Life, VRChat" may use licensed assets in a project others experience "as long as they remain under your direct control and are not sublicensed in any way".
  - For Roblox, "assets are not allowed to be shared with other users for projects outside of your product".
  - Platform owners need a custom licence.
  - [Synty Store FAQ](https://syntystore.com/community/faq)
- **Free Synty packs on Roblox:** Synty released free packs (Nature, City, four Dungeon packs) into the Roblox Toolbox on 2021-06-10, "completely free to use in anything you want to create on Roblox!". Reported issues: some black textures, and Studio freezing on large MeshPart packs. — [DevForum announcement](https://devforum.roblox.com/t/free-synty-asset-packs-released-in-the-marketplace/1283755); [Synty Nature Pack on Creator Store](https://create.roblox.com/store/asset/6933438443/Synty-Nature-Pack)
- **Sketchfab Download API:**
  - Over 1 million free models "under Creative Commons licenses"; "Most models allow commercial use".
  - Needs a user account and login flow.
  - Formats are glTF, GLB and USDZ only, with no FBX or OBJ.
  - [Sketchfab Download API](https://api.sketchfab.com/developers/download-api)
  - Several Blender MCP forks expose `download_sketchfab_model`. — [Glama listing example](https://glama.ai/mcp/servers/Vertiiii/blender-mcp/tools/download_sketchfab_model); [sketchfab-mcp-server](https://glama.ai/mcp/servers/%40gregkop/sketchfab-mcp-server)
- **Roblox's own limited-use licence** (Roblox-provided assets): [Roblox Limited Use License](https://create.roblox.com/docs/es-es/resources/limited-use-license)

### Inferences
- Synty is legal for a monetized Roblox game when assets are uploaded privately (not distributed as free models). Synty's low-poly flat style is likely far from the Moon Sweepers look, though; check against reference.
- For Sketchfab, filter to CC0 or CC-BY and keep a credits list in-game. Exclude CC-BY-NC and ND.
- On free Creator Store models: avoid them for hero art. Licence provenance is unclear and they risk scripts or backdoors. These are known community concerns, not sourced in this session.

### Gaps
- SyntyPass price was not found on the FAQ page.
- Poly Haven's licence page was not fetched directly; I relied on the CC0 aggregator.
- No source was found on Creator Store free-model quality or malware statistics.
- Curated paid Roblox packs were not researched.

## 5. How do Steam/indie studios structure the art pipeline, and how does it map to Roblox?

### Takeaway
The pro pattern is: art bible and references → greybox on a strict grid with gameplay metrics → modular kit of high-use pieces → trim sheets and decals → lighting and post → polish. Bethesda shipped 400+ Skyrim cells with 2 kit artists and 8 level designers using this method. Everything except the custom shaders maps onto Roblox. The binding constraints are 1024² PBR maps, a single UV set, OpenGL normals, and MaterialVariants and lighting as the main "shader" levers.

### Cited Findings
- **Joel Burgess, GDC 2013 (Skyrim/Fallout kits):**
  - "Kits are systems", snapped to a grid.
  - Set global standards early: doorframes, minimum widths, slopes, jump and cover heights. 128 units ≈ 6 ft.
  - Phases: concept (~1 week) → proof → greybox core of high-use pieces → build-out → polish.
  - Pieces stay inside their footprint, pivots go at bottom-centre, naming is consistent with numeric variant suffixes.
  - Stress-test awkward combinations.
  - 400+ cells were built by 2 kit artists and 8 level designers over ~30 months.
  - [Slideshare: GDC2013 Kit Building](https://www.slideshare.net/slideshow/gdc2013-kit-buildingfinal/17728576)
- **Other pipeline references (not fetched in detail):**
  - [Greybox→final modular kit workflow (UE5)](https://www.strayspark.studio/blog/modular-kit-workflow-greybox-to-final-ue5)
  - [GDC 2026 schedule: Modular and expressive world art of Keeper](https://schedule.gdconf.com/session/the-modular-and-expressive-world-art-of-keeper/915052)
  - [GDC Indie Summit talk](https://gdcvault.com/play/1027974/Independent-Games-Summit-An-Approach)
  - [Trim sheets course](https://flippednormals.com/product/trim-sheets-for-game-artists-3292)
- **Roblox constraints:** 1024×1024 PBR maps; albedo, normal (OpenGL), roughness, metalness and emissive mask; one UV set; UVs in 0–1, overlap allowed. — [Roblox texture specs](https://create.roblox.com/docs/art/modeling/texture-specifications.md)
- **Asset LOD and quality:** RDC 2025 describes the asset pipeline adjusting quality by importance and distance, and SLIM model merging. — [RDC 2025](https://about.roblox.com/newsroom/2025/09/roblox-rdc-2025)

### Inferences (mapping, not sourced individually)

| Pro step | Roblox equivalent |
|---|---|
| Art bible | Palette, lighting preset and reference screenshots in the vault |
| PureRef | A reference folder of Moon Sweepers frames |
| Greybox | Parts on a 1/2/4-stud grid with metrics in Config, or generate_procedural_model |
| Modular kit | Blender-modelled pieces → FBX → Open Cloud, as MeshParts sharing one trim texture |
| Trim sheets | A 1024² SurfaceAppearance trim atlas reused across the kit, since overlapping UVs are allowed |
| Tiling surfaces | MaterialVariants (generate_material, or custom maps) |
| Substance Painter / Marmoset bakes | Blender bpy bakes (free); Substance is optional |
| Houdini / SpeedTree | Blender Geometry Nodes, or Luau-procedural placement at runtime or edit time |
| Shaders | None; replaced by Future lighting + Atmosphere + ColorCorrection/Bloom/DoF + emissive masks + Beams/ParticleEmitters |

### Gaps
- Pricing and licence for Substance, Marmoset, Houdini, SpeedTree and PureRef were not fetched this session.
- The Moon Sweepers art direction itself was not researched (out of scope here; another researcher may have it).
- Primary sources were not fetched for Future lighting or MaterialVariant StudsPerTile limits.

## 6. What visual feedback loops can an AI use (screenshot comparison, reference matching, blind review)?

### Takeaway
The native building blocks exist: `screen_capture` with fixed camera and look-at positions, `subagent` of type screen_capture, `store_image`, and reference-image inputs on generate_texture and generate_procedural_model. I found no dedicated image-diff or VLM-critique MCP in this session. The loop has to be assembled: fixed camera stations → capture → compare against Moon Sweepers reference frames with Claude vision, plus scripted metrics.

### Cited Findings
- screen_capture "Captures the viewport, with an optional custom camera position and look-at target." — [Roblox docs](https://create.roblox.com/docs/studio/mcp.md)
- The Device Simulator skill (rbx-device-simulator-lua) explicitly pairs execute_luau with screen_capture for multi-device UI comparisons. This comes from the live `skill` tool schema.
- The boshyxd inspector edition includes `capture_screenshot`, `get_asset_thumbnail` and `preview_asset`, useful for previewing Creator Store assets before insert. — [GitHub boshyxd](https://github.com/boshyxd/robloxstudio-mcp)

### Inferences
- A practical blind review:
  1. Capture N fixed stations.
  2. Strip the labels.
  3. Mix the frames with Moon Sweepers reference frames.
  4. Ask a fresh Claude subagent to rank them on a rubric (palette, value contrast, silhouette, density, lighting mood).
- Numeric checks can be added with Python in the container (SSIM or palette histograms via scikit-image or Pillow). This is not sourced as an existing MCP.

### Gaps
- I did not search for image-diff MCP servers or VLM art-critique tools because of the call budget. This needs a follow-up search.
