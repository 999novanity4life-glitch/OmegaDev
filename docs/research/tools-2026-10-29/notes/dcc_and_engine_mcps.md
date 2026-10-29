# MCP servers for DCC tools and game engines, and how they carry over to Roblox (as of 29 Oct 2026)

Method note: The GitHub API was blocked in this session (403), so star counts and push dates could not be pulled directly. Every star or date figure below comes from the page cited next to it. Where the only source is a vendor blog selling a competing product (StraySpark), the figure is marked "vendor-reported". Items found only in MCP directories (glama.ai, PyPI, itch.io) without a README fetch are marked "UNVERIFIED (directory listing only)".

## Q1. Which Blender MCPs exist, which is the most capable and best maintained, and what tools do they expose?

### Takeaway
There are two serious free options. **MCP for Blender** (formerly ahujasid/blender-mcp, MIT, Blender 3.0+) is the most feature-rich free option. It has viewport/render capture (`look`), Python execution, Poly Haven, Sketchfab and Poly Pizza asset import, and AI mesh generation (Hyper3D Rodin, Hunyuan3D, Tripo, Meshy). The **official Blender Lab MCP server** (GPL-3.0, Blender 5.1+) powers Anthropic's Blender connector (28 Apr 2026). It is leaner: no asset libraries or generation, but it bundles the Blender API docs and manual for grounded answers. For a Roblox studio already using bpy, MCP for Blender is the best fit, mainly because of `look` (visual feedback) and the CC0 asset import from Poly Haven.

### Cited Findings
**MCP for Blender (ahujasid/blender-mcp, renamed "mcp-for-blender")**
- It is a third-party integration, "not made by Blender". A Blender add-on runs a socket server, and the MCP server connects to it. MIT licensed. [README](https://raw.githubusercontent.com/ahujasid/blender-mcp/main/README.md)
- Tools: `execute_blender_code` (runs Python in the live session); `look` (captures viewport, camera, multi-angle or animation views, or renders); `get_scene_info`; `generate_3d` (generates and imports models through Tripo, Hunyuan3D, Hyper3D Rodin or Meshy); `search_assets` / `import_asset` (Poly Haven, Sketchfab, Poly Pizza); `get_addon_status`; `disable_telemetry`; `record_trajectory_feedback`. [README](https://raw.githubusercontent.com/ahujasid/blender-mcp/main/README.md)
- Install: `uvx mcp-for-blender`, where the old `uvx blender-mcp` still works. For Claude Code: `claude mcp add blender uvx mcp-for-blender`. Claude Desktop config: `{"mcpServers":{"blender":{"command":"uvx","args":["mcp-for-blender"]}}}`. Setup helper: `uvx mcp-for-blender setup`. An `update` command exists from 2.1.7. [README](https://raw.githubusercontent.com/ahujasid/blender-mcp/main/README.md)
- Mac prerequisites: Blender 3.0+, Python 3.10+, and uv via `brew install uv`. [README](https://raw.githubusercontent.com/ahujasid/blender-mcp/main/README.md)
- Security: the socket has no authentication or encryption ("anyone who can reach that port can run Python inside Blender"), so keep it on localhost. Opt-in safe mode is `BLENDER_MCP_SAFE_MODE=1`. Poly Haven downloads run on the main thread and can freeze the UI. Telemetry sends a minimal anonymous record by default and is disabled with `DISABLE_TELEMETRY=true`. [README](https://raw.githubusercontent.com/ahujasid/blender-mcp/main/README.md)
- Vendor-reported figures: about 29,326 stars (25 Sep 2026), 36 tools, renamed to "MCP for Blender" on 16 Sep 2026, created March 2025, PyPI `mcp-for-blender` 2.1.0. Generation features (Rodin, Hunyuan3D, Tripo) are listed as "Premium $10–20/mo". This comparison has a conflict of interest (StraySpark sells a competing server). [StraySpark](https://www.strayspark.studio/blog/official-blender-mcp-server-comparison-2026)
  - Note the conflict: the README lists about 9 tools, while StraySpark says 36. The difference may come from counting sub-actions. Unresolved.

**Official Blender Lab MCP server**
- Home pages: [blender.org/lab/mcp-server](https://www.blender.org/lab/mcp-server/) and [projects.blender.org/lab/blender_mcp](https://projects.blender.org/lab/blender_mcp). Requires Blender 5.1.0+. Install by dragging the v1.0.3 zip into Blender twice: the first drop adds the Lab repository, the second installs the add-on. The MCP server installs as a `.mcpb` bundle or from source. The page warns that it runs LLM code "without any guards" and recommends a VM. [Blender Lab](https://www.blender.org/lab/mcp-server/)
- Vendor-reported details: v0.1.0 on 24 Mar 2026, v1.0.0 on 27 Apr 2026, v1.0.3 on 11 Sep 2026. GPL-3.0-or-later. 26 tools, covering code execution, blend-file and object summaries, screenshots, viewport navigation, renders, and search over bundled Blender API and manual copies. Six tools have `_for_cli` variants that run on .blend files in the background. It is described as the server behind Anthropic's Blender connector. [StraySpark](https://www.strayspark.studio/blog/official-blender-mcp-server-comparison-2026)
- Anthropic launched 9 creative connectors on 28 Apr 2026: Adobe, **Blender**, Ableton, Splice, **Autodesk Fusion**, **SketchUp**, Affinity, Resolume Arena and Resolume Wire. You enable them in Claude's Customize/Connectors panel. [mcpplaygroundonline](https://mcpplaygroundonline.com/blog/claude-creative-connectors-adobe-blender-ableton.md); [Gigazine](https://wbgsv0a.gigazine.net/gsc_news/en/20260429-claude-for-creative-work)
- One review says the Blender connector needs "Blender 4.5 LTS or newer" and runs against the local install. This conflicts with the Lab page's 5.1+ requirement. [Godberry](https://godberrystudios.com/posts/claude-for-creative-work-9-connectors-tested-2026/index.md) vs [Blender Lab](https://www.blender.org/lab/mcp-server/)

**Paid alternatives (vendor-reported)**
- Blender MCP Pro: 120+ tools, $5/month or $15 one-time. StraySpark Blender MCP Server: 556 tools, $79.99 to $249.99, with code execution off by default. [StraySpark](https://www.strayspark.studio/blog/official-blender-mcp-server-comparison-2026)
- Other community Blender MCPs found only in directory listings (UNVERIFIED): [naab007/blender_mcp](https://github.com/naab007/blender_mcp), [llm-use/Blender-MCP-Server](https://glama.ai/mcp/servers/@llm-use/Blender-MCP-Server/blob/d4a14b26ec47516751f2461965d9a64ca982ac58/README.md), [PyPI blenderstudiomcp](https://pypi.org/project/blenderstudiomcp/).

### Inferences
- The team already drives bpy, probably through scripts or Bash. Adding MCP for Blender mainly buys two things: (a) `look`, so Claude can visually check the silhouette, scale and stylization against "Moon Sweepers" reference images before export, and (b) one-call import of CC0 Poly Haven textures and HDRIs. The official Lab server is the safer, docs-grounded choice. You can run both, but not on the same socket port at the same time. Check the ports before doing this.
- AI-generated meshes (Rodin, Hunyuan3D, Tripo) produce dense, triangulated, poorly UV'd output. For Roblox they need retopology or decimation under 20k triangles and rebaked textures before they are usable. Treat them as blockout or kitbash sources, not as final art.
- Neither server should run on a machine with sensitive data, because both execute arbitrary Python.

### Gaps
- Live GitHub star counts and last-commit dates could not be verified (GitHub API blocked). The 29k star figure is vendor-reported.
- No exact tool list for the official Lab server from a primary source. The Lab page gives only example use cases.
- Whether the Poly Haven, Sketchfab and generation integrations need API keys or a paid "Premium" tier was not confirmed from the README.

## Q2. Is there any reason to connect Unity, Unreal, Godot or other DCC MCPs for a Roblox studio?

### Takeaway
Mostly no. Engine MCPs (Unity, Unreal, Godot) control engine scenes, scripts and builds, and none of that transfers to Roblox: C#, Blueprints, Nanite, Lumen, Unity shaders and Godot scenes do not import. The only defensible uses are (a) a lookdev or lighting reference render, which Blender also does for free, or (b) checking a mesh's FBX import into another engine. Maya, 3ds Max, Houdini and Substance MCPs exist as community projects, but they need costly licenses (some are Windows-centric) and add little over Blender for the team's goal. Substance Painter is the one exception worth considering for PBR texturing if someone has a license. SketchUp and Fusion connectors are CAD/architectural and poorly suited to stylized game art.

### Cited Findings
**Unity**
- Unity's official MCP server ships in the AI Assistant package (`com.unity.ai.assistant`). The guide was published 11 May 2026. It requires Unity 6+, an active trial or subscription to Unity AI (open beta, 14-day trial), and a Unity Cloud-connected project. Claude Code and Desktop are auto-configured from Project Settings > AI > Unity MCP through a relay in `~/.unity/relay/`. Tools cover scenes and GameObjects, C# scripts, console, component inspection and build settings, and custom tools can be written in C#. [Unity blog](https://unity.com/blog/unity-ai-mcp-how-to-get-started)
- CoplayDev "MCP for Unity" is free, MIT licensed, with 47 tools. Install via the Package Manager git URL `https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity#main`, then Window > MCP for Unity > Configure All Detected Clients. Supports Unity 2021.3 to 6.x and needs Python 3.10+ with uv. Latest is v10.0.0, released 30 Jun 2026. [README](https://raw.githubusercontent.com/CoplayDev/unity-mcp/main/README.md)
- IvanMurzak/Unity-MCP ("AI Game Developer") has 70+ tools, including screenshot tools (`screenshot-camera`, `screenshot-game-view`, `screenshot-scene-view`). Install with `openupm add com.ivanmurzak.unity.mcp` or `unity-mcp-cli`. The project path cannot contain spaces. [README](https://raw.githubusercontent.com/IvanMurzak/Unity-MCP/main/README.md)

**Unreal**
- UE 5.8 ships an experimental first-party MCP server plugin with a "foundational", minimal tool set whose APIs will change. It is free with the engine. [StraySpark](https://www.strayspark.studio/blog/epic-official-mcp-plugin-ue5-8-vs-third-party) (vendor blog; see also [Unreal Engine: State of Unreal 2026](https://www.unrealengine.com/news/state-of-unreal-2026-top-news-from-the-show), not fetched)
- chongdashu/unreal-mcp: UE 5.5+, Python 3.12+. Tools cover actors, Blueprint classes and node graphs, and viewport camera. Marked experimental, "not for production". MIT. You must build the C++ plugin, which on macOS needs Xcode. [README](https://raw.githubusercontent.com/chongdashu/unreal-mcp/main/README.md)
- Paid: StraySpark Unreal MCP Server, 455 tools, from $129. [StraySpark](https://www.strayspark.studio/blog/epic-official-mcp-plugin-ue5-8-vs-third-party)

**Godot**
- Coding-Solo/godot-mcp: launch the editor, run or debug projects, capture output, create scenes and nodes, export a MeshLibrary. MIT. Install with `claude mcp add godot -- npx @coding-solo/godot-mcp` (optionally `-e GODOT_PATH=...`). Needs Node 18+. [README](https://raw.githubusercontent.com/Coding-Solo/godot-mcp/main/README.md)

**Maya, 3ds Max, Houdini**
- 3dsmax-mcp by Oğulcan Sarıca ([github.com/cl0nazepamm/3dsmax-mcp](https://github.com/cl0nazepamm/3dsmax-mcp)), 9 Feb 2026, open source, TCP bridge supporting MaxScript, Python and OSL. [CGPress](https://cgpress.org/archives/3dsmax-mcp-connects-claude-to-3ds-max.html) Note that 3ds Max is a Windows-only application, so it cannot run on a MacBook Air (general knowledge, not from that article).
- Maya MCPs, UNVERIFIED (directory listing only): [Jeffreytsai1004/maya-mcp](https://glama.ai/mcp/servers/@Jeffreytsai1004/maya-mcp/blob/fbefb311b0891fda32b603b12892e0b58fa67649/README.md), [bdeda/maya_mcp](https://glama.ai/mcp/servers/@bdeda/maya_mcp/tree/459ad1ed007764bf03f3e788be7b3bbde5c5f255). No official Autodesk Maya MCP was found. Autodesk's official Claude connector is for **Fusion**, which needs a subscription and runs in the cloud. [mcpplaygroundonline](https://mcpplaygroundonline.com/blog/claude-creative-connectors-adobe-blender-ableton.md)
- Houdini: glama lists about 12 community Houdini MCPs, ranging from 57 to 168 tools and mostly MIT, including viewport capture and PDG/USD. No official SideFX MCP was found. [glama Houdini list](https://images.glama.ai/mcp/servers/integrations/houdini); example [capoom/houdini-mcp](https://glama.ai/mcp/servers/@capoom/houdini-mcp) (UNVERIFIED).

**Substance, ZBrush**
- Substance 3D Painter: community MCPs only. [elliezu/SubstancePainterMCP](https://github.com/elliezu/SubstancePainterMCP); [PyPI dcc-mcp-substance3d-painter 0.1.x](https://pypi.org/project/dcc-mcp-substance3d-painter/); [Painter MCP Pro on itch.io](https://y1uda.itch.io/painter-mcp-pro). All UNVERIFIED (READMEs not fetched). Adobe's official Claude connector covers Photoshop, Illustrator, Firefly and similar apps, but **not Substance**. [mcpplaygroundonline](https://mcpplaygroundonline.com/blog/claude-creative-connectors-adobe-blender-ableton.md)
- ZBrush: [newsbubbles/zbrush-mcp](https://github.com/newsbubbles/zbrush-mcp), UNVERIFIED (README not fetched).

**SketchUp (Trimble) and Fusion connectors**
- The SketchUp connector builds geometry in a cloud SketchUp session from text, images or floor plans. Output is `.skp` with a thumbnail and download link. It is free for up to 30 saved models, after which a paid entitlement is required. "SketchUp is a sketching tool, not a CAD tool." [Godberry](https://godberrystudios.com/posts/claude-for-creative-work-9-connectors-tested-2026/index.md)
- The Fusion connector requires a subscription, runs in the cloud, and is weak at surfacing and lofting. It suits mechanical parts. [Godberry](https://godberrystudios.com/posts/claude-for-creative-work-9-connectors-tested-2026/index.md)

### Inferences
- **Worthless for Roblox output:** Unreal Nanite, Lumen, Blueprints and Materials; Unity shaders, URP/HDRP and C#; Godot scenes and GDScript. None import into Roblox, so a Roblox-only studio does not need the Unity, Unreal or Godot MCPs.
- **Marginal:** SketchUp. It could block out greybox architecture for station or ship interiors, but it exports `.skp`, which would have to be converted through Blender, with poor UVs and topology. Fusion has the same problem and costs a subscription.
- **Potentially valuable if licensed:** Substance Painter, for PBR texture authoring. Its exports (BaseColor, Normal OpenGL, Roughness, Metallic, Emissive) map directly onto SurfaceAppearance. A Blender-only route (bake plus procedural nodes plus hand-paint) is free and already scriptable, though.
- **Keep Blender as the hub.** Everything else either converts through Blender or does not transfer at all.

### Gaps
- Exact pricing for Unity AI beyond the trial was not captured.
- Official Epic documentation for the UE 5.8 MCP plugin was not fetched (only a vendor blog).
- Maya, Houdini, Substance and ZBrush community MCP READMEs were not individually verified for maintenance status or macOS support.

## Q3. What are Roblox's exact import constraints, and what is the cleanest automated Blender-to-Roblox path?

### Takeaway
The hard limits are 20,000 triangles per individual mesh; 4 bone influences per vertex; frozen bones with the root at the origin; one animation per export; watertight geometry with no zero-thickness faces; and `_InnerCage` / `_OuterCage` naming for layered clothing. PBR uses SurfaceAppearance with Color/Albedo, Normal (OpenGL tangent-space only), Roughness, Metalness and Emissive mask. Texture size is ambiguous in the docs (the page says "up to 4096x4096" but also "1024x1024 pixel spaces" for UV-mapped maps), so treat 1024 as the safe effective budget. The 3D Importer takes FBX, OBJ, glTF and GLB. The cleanest automated path is Blender (bpy) → FBX/glTF export → Open Cloud Assets API (`POST https://apis.roblox.com/assets/v1/assets`, Model type, 20 MB max) → `insert_asset` through the Roblox Studio MCP. Roblox's own Blender plugin and the `asphalt` CLI already wrap this.

### Cited Findings
**Mesh specs**
- "Individual meshes can not exceed 20,000 triangles." Avatar items have separate budgets. [Roblox modeling specifications](https://create.roblox.com/docs/art/modeling/specifications)
- Skinning rules: at most 4 bones or joints per vertex; bones frozen (scale 1, rotation 0); root at 0,0,0 with no influences on the root; one animation track per export. [specs](https://create.roblox.com/docs/art/modeling/specifications)
- Cages are named `<mesh>_InnerCage` / `_OuterCage`, and character models need an outer cage for layered accessories. Do not delete cage vertices or alter cage UVs. [specs](https://create.roblox.com/docs/art/modeling/specifications)
- Geometry must be watertight with no backfaces or zero thickness. Prefer quads and avoid N-gons. [specs](https://create.roblox.com/docs/art/modeling/specifications)

**Textures and PBR**
- Textures support "up to 4096×4096", but the UV mapping section says texture maps support "1024×1024 pixel spaces". The two statements are inconsistent. [Roblox texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications)
- Map formats: Albedo is 24-bit RGB; Normal is 24-bit RGB; Roughness, Metalness and Emissive Mask are 8-bit grayscale. "Roblox only supports OpenGL format – Tangent Space normal maps." [texture specs](https://create.roblox.com/docs/art/modeling/texture-specifications)
- SurfaceAppearance supports color, normal, roughness, metalness and emissive maps (`EmissiveMaskContent`, `EmissiveTint`, `EmissiveStrength`). AlphaMode can be Opaque (beta), Overlay (default), Transparency or TintMask. It is added to a MeshPart. [Surface appearance](https://create.roblox.com/docs/art/modeling/surface-appearance)

**Import**
- The 3D Importer accepts .fbx, .obj and .gltf/.glb. FBX and glTF carry basic and PBR textures. It has an import queue for bulk imports, and "Merge Meshes" is off by default. glTF imports create a Model for each mesh with one MeshPart per primitive. [3D Importer](https://create.roblox.com/docs/art/modeling/3d-importer)
- Blender FBX export settings: Path Mode = Copy with Embed Textures on; Apply Scalings = "FBX Unit Scale"; Add Leaf Bones off; Bake Animation off unless animated. [Export requirements](https://create.roblox.com/docs/art/modeling/export-requirements)

**Automated upload (Open Cloud)**
- Assets API: `POST https://apis.roblox.com/assets/v1/assets`. Model type accepts .fbx, .gltf, .glb, .rbxm and .rbxmx, and imports as a Model of MeshParts uploaded as a package. One asset per call, up to 20 MB. `PATCH .../assets/{id}` updates content, but for FBX only, and each update creates a new version. Poll `GET .../assets/v1/operations/{id}` until `done`. Auth is an API key in `x-api-key` with assets read/write, or OAuth `asset:read`/`asset:write`. Images under 8000x8000 are accepted. The API is in beta. [Usage guide for assets](https://create.roblox.com/docs/en-us/cloud/guides/usage-assets)
- The guide still recommends the Studio 3D Importer for custom models, because it offers a preview, error checking and import settings. [Usage guide for assets](https://create.roblox.com/docs/en-us/cloud/guides/usage-assets)
- Roblox Blender plugin (official, MIT): uploads the selected meshes or a Collection as packages through Open Cloud, with OAuth login in the browser. Re-uploading updates the package (via the custom property `Roblox Package ID`), and PackageLink.AutoUpdate can pull changes in Studio. Requires Blender 3.2+. It is a reference implementation that accepts bug fixes but not new features. [README](https://raw.githubusercontent.com/Roblox/roblox-blender-plugin/main/README.md)

### Inferences
- **Recommended pipeline:**
  1. bpy builds or cleans the mesh: decimate or retopologize to well under 20k triangles per MeshPart, split larger props into several MeshParts, triangulate, and apply transforms.
  2. bpy bakes high-to-low PBR maps at 1024: Albedo, OpenGL Normal, Roughness, Metal and Emissive.
  3. Export to FBX with the documented settings, or to GLB.
  4. Upload through Open Cloud: a small Python or Node script, `asphalt upload`, or the Roblox Blender plugin.
  5. Use the Studio MCP `insert_asset(assetId)`, add a SurfaceAppearance with the uploaded texture IDs, and `screen_capture` to verify.
  Because FBX is the only format that supports content updates through PATCH, keep FBX as the source format for meshes you plan to iterate on, so asset IDs stay stable.
- The Roblox Blender plugin's OAuth flow is interactive (browser), so it is less suited to unattended Claude runs than an API-key script.

### Gaps
- An authoritative per-map size limit for SurfaceAppearance (1024 vs 4096) needs confirming in Studio, for example by importing a 2048 map and running `inspect_instance` or `execute_luau`.
- No per-mesh vertex limit or bounding-size limit was found on the specs page.
- Whether Open Cloud Model uploads auto-create SurfaceAppearance from glTF PBR materials was not confirmed.

## Q4. Is there an MCP or tool that auto-uploads assets to Roblox via Open Cloud? And which Blender add-ons for pro game-art quality can Claude script?

### Takeaway
No official Roblox Open Cloud MCP was found. The **built-in Roblox Studio MCP** exposes `upload_image` (images from HTTP URLs only), `store_image`, `insert_asset` and `generate_mesh`, but no general mesh/FBX upload. For meshes, the best tools are the **asphalt** CLI (Rust; images, audio, video, animations, rbxm, and fbx/gltf/glb), the **rbxcloud** crate, or a 30-line script against the Assets API, which Claude can call through Bash. Several community "Roblox MCP" servers exist but are unverified. On add-ons, UVPackmaster 4 ($55, has an embedded Python scripting engine) and Quad Remesher (Exoside, paid) are the standard pro tools. Blender's native bake, Smart UV Project, the Decimate/Remesh modifiers and Geometry Nodes are all fully bpy-scriptable for free.

### Cited Findings
**Uploading to Roblox**
- The Roblox Studio MCP tools include `generate_mesh` (text to a textured mesh), `insert_asset` (by ID; models, meshes, images, audio, packages), `upload_image` ("Uploads a batch of images from HTTP URLs to the Roblox asset server"), and `store_image` (local file to image URI). There is no general-purpose upload. On macOS, Claude Code connects via `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP` or Studio's Assistant Settings > MCP Servers > Quick connect. [Roblox Studio MCP docs](https://create.roblox.com/docs/en-us/studio/mcp)
- asphalt "uploads assets to Roblox and generates code" and is "a modern alternative to Tarmac". It needs an API key with `asset:read`/`asset:write`. Supported types: images (with SVG→PNG conversion and alpha bleed), audio, video, rbxm/rbxmx animations and models, and .fbx/.gltf/.glb, although the README advises the 3D Importer for meshes. Install with `cargo install asphalt`, mise, Rokit or Homebrew. Config lives in `asphalt.toml` plus a lockfile, and `asphalt sync --dry-run` works for CI. [asphalt](https://github.com/jackTabsCode/asphalt)
- rbxcloud is a Rust crate and CLI for Open Cloud. Version 0.17.0 was seen. [docs.rs rbxcloud](https://docs.rs/crate/rbxcloud/latest). There is also a Python wrapper, [rblx-open-cloud](https://rblx-open-cloud.readthedocs.io/en/latest/creator.html).
- Community Roblox MCPs, UNVERIFIED (none confirmed to do Open Cloud mesh upload): [hope1026/roblox-mcp](https://glama.ai/mcp/servers/hope1026/roblox-mcp), [kolvian/roblox-mcp-server](https://github.com/kolvian/roblox-mcp-server), [dmae97/roblex-studio-mcp-server](https://cdn.jsdelivr.net/gh/dmae97/roblex-studio-mcp-server@main/README.md), [Vibe Blocks MCP](https://glama.ai/mcp/servers/vtu1k6v86e).

**Pro Blender add-ons**
- UVPackmaster 4: $55 single-user, $199 for 2–5 seats. Blender 2.93–5.2 and Extension-compatible, GPL. CPU and GPU engines (CUDA, Vulkan). "We embedded Python into the newest engine release, giving you a possibility to code your own operation logic." Apple Silicon / Metal support is not stated. [Superhive](https://superhivemarket.com/products/uvpackmaster/)
- Quad Remesher (Exoside) works through a Python add-on that bridges to an external proprietary engine. Tips: triangulate the source first, keep the Quad Count low (default 5000), and use Data Transfer to recover UVs. Price and macOS support are not stated in the FAQ. [BlenderNation FAQ](https://www.blendernation.com/2019/10/18/quad-remesher-auto-retopologizer-for-blender-unofficial-faq/)

### Inferences
- **Recommendation:** have Claude write a small `scripts/` uploader that uses the Assets API directly (create, then poll the operation, then return the assetId) with a Creator Dashboard API key stored in an env var. Alternatively, adopt asphalt for images and audio, where it also generates Luau ID tables, which fits the repo's Rojo workflow. Then call Studio MCP `insert_asset`. This makes the entire Blender→Roblox loop scriptable without an extra MCP.
- **Claude scripting of add-ons:** any Blender add-on that registers operators can be called through `bpy.ops.<module>.<op>()` from `execute_blender_code` or headless `blender -b -P`. Paid add-ons (Quad Remesher, UVPackmaster) can be driven this way once installed, but operator names must be discovered in the live session, for example with `dir(bpy.ops.qremesher)`. They are not documented in the sources above.
- Free bpy equivalents that cover most Moon Sweepers-style needs:
  - Retopology: the Decimate modifier (collapse/planar) and the Remesh modifier (voxel/quad).
  - UVs: `bpy.ops.uv.smart_project` and `pack_islands`. Blender 3.6+ has a much improved native packer (general knowledge).
  - Baking: Cycles high-to-low bake with cage and extrusion for normal and AO maps.
  - Trim sheets: an atlas texture plus UV snapping.
  - Stylized look: a baked toon/hand-painted look built from AO, curvature and gradient maps, since Roblox has no custom shaders, so stylization must be baked into Albedo or Emissive.

### Gaps
- Quad Remesher price, macOS ARM support and Python operator names were not verified from Exoside's own site.
- UVPackmaster scripting API docs were not fetched, and Apple Silicon support is unconfirmed.
- No sources were gathered on trim-sheet or stylized-shader add-ons (for example Hard Ops/BoxCutter, or Ucupaint for texture painting). Not researched within the tool-call budget.
