# UI design tools for Claude and how they turn into Roblox Studio UI (research as of Oct 29, 2026)

## Q1: What pipeline turns a designer-quality mockup into Roblox ScreenGuis automatically (Figma -> plugin/script -> Rojo files)?

### Takeaway
No tool goes straight from Figma to Rojo files. The tools that exist (Framewisp, UILint v2, GuiForge, roimport) produce Studio instances or Luau/React-Lua code. The closest fit is Figma -> GuiForge (Luau modules or React-Lua output) or Figma -> Framewisp/UILint (instances in Studio). From either, Claude would serialize the instances into `src/client` Luau or `.rbxmx`/`.model.json` through the Roblox Studio MCP (`execute_luau`/`inspect_instance`).

### Cited Findings
**Figma MCP (official)**
- The remote server is `https://mcp.figma.com/mcp`. The desktop server is turned on in Dev Mode with "Enable desktop MCP server", which needs the desktop app open with a Design file. Remote-only tools include `use_figma` and `generate_figma_design`. — [Figma MCP server FAQs](https://help.figma.com/hc/en-us/articles/39252411778583-Figma-MCP-server-FAQs)
- **It can write now, not just read.** `use_figma` runs Plugin API code in the file and "creates and changes real design content: components, variables, frames, and auto layout", using your existing libraries. `upload_assets` adds images and `generate_image` creates them. — [Figma dev docs: Write to canvas](https://developers.figma.com/docs/figma-mcp-server/write-to-canvas); [FAQs](https://help.figma.com/hc/en-us/articles/39252411778583-Figma-MCP-server-FAQs)
- Write limits: 20 KB of output per call, no new images from `use_figma` alone, fonts must be uploaded to the account, and it is "Beta quality" (test on a draft or duplicate). — [FAQs](https://help.figma.com/hc/en-us/articles/39252411778583-Figma-MCP-server-FAQs)
- There is also a "code to canvas" flow (`generate_figma_design`) that turns rendered code or UI into Figma layers. — [Figma dev docs: code to canvas](https://developers.figma.com/docs/figma-mcp-server/code-to-canvas/); [Help: Code to canvas with your design system](https://help.figma.com/hc/en-us/articles/40287261761559-Code-to-canvas-with-your-design-system)
- Plans: writing to canvas works on the Professional, Education, Organization and Enterprise plans and needs edit access. "You need a Full seat to write to files outside your drafts"; Dev seats can write only in drafts. — [Write to canvas](https://developers.figma.com/docs/figma-mcp-server/write-to-canvas); [FAQs](https://help.figma.com/hc/en-us/articles/39252411778583-Figma-MCP-server-FAQs)
- Rate limits: View and Collab seats get 20 calls a month on every plan. Full and Dev seats on Starter get "None". Professional gets 200/day at 10/min, Organization 200/day at 15/min, Enterprise 600/day at 20/min. Writing is "free during the beta period", but it "will eventually become a usage-based paid feature". `generate_image` and `send_prompt` use Figma AI credits. — [FAQs](https://help.figma.com/hc/en-us/articles/39252411778583-Figma-MCP-server-FAQs)
- Earlier community threads called the Figma MCP "read only"; that is now out of date. — [Figma forum thread](https://forum.figma.com/ask-the-community-7/can-figma-mcp-be-used-for-programmatic-design-generation-seems-like-read-only-only-57148)

**Figma -> Roblox converters (real DevForum posts, all from 2026)**
- **Framewisp** (posted Jul 27, 2026). It is a Figma plugin plus a Studio plugin: you get a 6-character code that you paste into Studio. Auto-sync re-imports by diffing the existing tree. Output is native instances (Frame, TextLabel, ScrollingFrame and so on, with UICorner, UIStroke and UIGradient) plus one injected LocalScript. Sizing uses Scale (`UDim2.fromScale`) with an aspect lock. Images upload to your account through OAuth, 30 per convert. **Limits:** no auto-layout (becomes absolute positions), strokes reduced to one solid colour, one corner radius per element, no blend modes, blur baked to an image, and custom-font text baked into an image. Price: 7-day free trial, then a subscription; the amount is not stated. — [DevForum: Framewisp](https://devforum.roblox.com/t/framewisp-%E2%80%94-turn-a-figma-frame-into-native-roblox-ui-in-one-click/4759239)
- **UILint v2** (posted Jul 30, 2026). A Figma plugin lints the file, cleans layer names and exports the hierarchy and images; a Studio companion rebuilds it as "structured Roblox UI objects". It supports ScrollingFrames, custom scrollbars, asset reuse and "Smart Scale". The free tier covers local linting and manual snapshot plus image ZIP export; Smart Sync, Live Sync and the Component Extractor are paid, with no prices given. Output is instances, with no Rojo or code output mentioned. — [DevForum: UILint v2](https://devforum.roblox.com/t/plugin-uilint-v2-import-figma-ui-into-roblox-studio/4765869)
- **GuiForge** (posted Aug 27, 2026). A browser UI editor with a companion Figma plugin that imports frames with layout, text, strokes, gradients and 9-slice, and rasterizes what Roblox can't do (skew, mixed fonts). **Code outputs:** a single LocalScript, Modules (runtime, config and init), React-Lua (beta, `jsdotlua/react`) and `.rbxmx` (beta). It also has theme tokens, device presets, UIShadow and 9-slice. "Free to try", pricing not stated. Rojo is not mentioned, but `.rbxmx` and module output can go into a Rojo tree. — [DevForum: GuiForge](https://devforum.roblox.com/t/guiforge-roblox-ui-editorfigma-export/4834077)
- **roimport** is a free Figma-to-Roblox plugin. I saw only its title in search results and did not read the post (UNVERIFIED details). — [DevForum: roimport](https://devforum.roblox.com/t/free-figma-to-roblox-plugin-roimport/4731967)
- **Figma Importer Assistant** is an older DevForum post (UNVERIFIED, not read). — [DevForum](https://devforum.roblox.com/t/2961561)
- A community post explains why Figma import is painful (UNVERIFIED content, title only): [DevForum: Importing UI From Figma SUCKS](https://devforum.roblox.com/t/importing-ui-from-figma-sucks/3381689)
- **Instance -> code converters** (titles seen, not read): FFusion turns GUIs into Fusion components ([DevForum](https://devforum.roblox.com/t/ffusion-convert-your-roblox-guis-into-fusion-components-free/4810694)), Vigets turns GUIs into Vide components ([DevForum](https://devforum.roblox.com/t/vigets-convert-your-roblox-guis-into-vide-components-free/4760321)), and "GUI to Lua" turns GUIs into Luau ([DevForum](https://devforum.roblox.com/t/updated-gui-to-lua-%E2%80%94-effortlessly-convert-guis-to-lua-code/3346850)).
- A "figma-to-roblox-ui" agent skill is listed on a skills directory (UNVERIFIED, not read). — [skillsdirectory](https://www.skillsdirectory.com/skills/xtrair-figma-to-roblox-ui)
- **Luix** is a VS Code extension for authoring React-Luau, Roact, Fusion and Vide UI, with asset previews (title only). — [GitHub: ericplane/Luix](https://github.com/ericplane/Luix)

### Inferences
- Best automatic chain for OmegaDev, which keeps files as the source of truth:
  1. Claude designs or edits in Figma through `use_figma`.
  2. GuiForge's Figma plugin exports React-Lua or Modules into `src/client/ui/`, and Rojo builds it.
  3. Or Framewisp/UILint drops instances into Studio. Claude then reads them through the Studio MCP and serializes them to Luau (or to Fusion/Vide via FFusion/Vigets) in `src/client`, so Rojo stays authoritative.
- Framewisp's lack of auto-layout and its baking of custom fonts into images clash with the mobile-first and localization rules. Generated UI still needs a manual pass to add UIListLayout, Scale and aspect constraints, and safe-insets.
- An alternative with no converter: Claude uses Figma only as a visual spec (`get_screenshot` + `get_variable_defs` for tokens) and hand-writes the Luau, building 9-slice image assets from exported PNGs. This is likely the most robust option given how young the converters are (all posted in mid-2026).

### Gaps
- Prices for Framewisp, UILint paid tiers and GuiForge are not published in the posts.
- No tool was found that writes Rojo `.model.json` directly from Figma.
- Whether Claude Code is on Figma's list of "supported clients" for write-to-canvas was not confirmed on the page fetched. The page links to a client list.

## Q2: Which connectors can Claude use both to design and to see screenshots so it can iterate?

### Takeaway
Figma (remote MCP: `use_figma` writes, `get_screenshot` shows the result) and Penpot (free and open source, read and write, `export_shape`) both close the design-then-see loop. Adobe for Creativity and Canva create assets but give less pixel control. Inside Roblox, the Studio MCP's `screen_capture` is the final check.

### Cited Findings
- **Penpot MCP (official).** It has three parts: the MCP server, a plugin running in the open Penpot tab, and the client. It can read and write components, styles, **tokens**, pages and layers. Tools: `execute_code`, `high_level_overview`, `penpot_api_info`, `export_shape`, `import_image`. Remote setup: Account -> Integrations -> MCP Server -> generate key -> `npx -y add-mcp -g -n penpot <URL>`. Local setup: `npx -y @penpot/mcp@stable` (tested on Node v22) and load `http://localhost:4400/manifest.json`. Limits: the tab must stay open and focused, remote can't import local files, and writes affect the focused page. A vision-capable model is needed for image understanding. Pricing is not stated on the page; Penpot itself is open source. — [Penpot help: MCP server](https://help.penpot.app/mcp/); [penpot.app MCP page](https://penpot.app/penpot-mcp-server)
- **Adobe for Creativity** (claude.ai connector). It spans 50+ tools across Photoshop, Illustrator, InDesign, Lightroom, Premiere, Express, Firefly and Stock, and runs in Adobe's cloud. It needs an Adobe account. Weak spot: "pixel-level control". Claude connectors need Pro, Max, Team or Enterprise; the free tier doesn't get them. — [Godberry Studios: 9 creative connectors tested](https://godberrystudios.com/posts/claude-for-creative-work-9-connectors-tested-2026/)
- **Affinity by Canva** connector: automates batch image adjustments, layer renaming and export in the local Affinity app (free account). "Claude runs the script you describe; it can't yet decide what the script should do." — [Godberry Studios](https://godberrystudios.com/posts/claude-for-creative-work-9-connectors-tested-2026/)
- **Canva** has an official "Canva AI Connector" (MCP server) with setup docs. — [Canva dev docs](https://www.canva.dev/docs/connect/canva-mcp-server-setup)
- **Claude Design** (claude.com/design) is included on every plan, including Free. It makes mockups, assets and clickable flows. It exports PPTX, PDF and HTML, sends work to Adobe, Canva and others, and hands off to Claude Code via `/design` or `/design-sync`. Design systems can be imported from GitHub, design files or uploads, and Claude "checks its output against the system". Figma export is not mentioned. — [claude.com/design](https://claude.com/design)
- Wonder and Magic Patterns: no sources were researched in time (see Gaps).

### Inferences
- For OmegaDev on a MacBook Air, add the remote Figma MCP to Claude Code (`claude mcp add --transport http figma https://mcp.figma.com/mcp`, the standard pattern for remote HTTP MCPs; the exact command was not confirmed on Figma's page). This needs a Figma Professional plan with a Full seat. Penpot is the zero-cost alternative with the same read, write and screenshot loop.
- Claude Design plus `/design-sync` can hold a "carbon fibre / orange glow / chrome" design system (tokens and fonts) as a reference style guide, even though it outputs HTML rather than Roblox.

### Gaps
- Figma seat prices were not fetched; check figma.com/pricing.
- Wonder and Magic Patterns MCPs were not verified, so no claims are made about them.
- The Canva connector's game-UI usefulness was not tested; its docs page was found but not read.

## Q3: Game-UI reference libraries pros use. Can Claude access them?

### Takeaway
Game UI Database (by Edd Coates) is free and is the standard reference, with over 55,500 screens at its 2.0 launch. Claude can WebFetch its pages, but there is no API or MCP, so browsing it visually needs a browser tool.

### Cited Findings
- Game UI Database is free, created "as a free resource for UI/UX Designers in the games industry" by Edd Coates and funded by donations. The About page mentions no API and no scraping or AI terms. — [gameuidatabase.com/about](https://www.gameuidatabase.com/about.php)
- Version 2.0 launched with over 55,500 screens and better tools. — [AlternativeTo news](https://alternativeto.net/news/2024/8/game-ui-database-2-0-launches-with-over-55-500-screens-and-enhanced-tools-for-ui-designers/); [Creative Bloq](https://creativebloq.com/3d/video-game-design/game-ui-database-20-is-the-ultimate-free-reference-tool-for-game-designers)

### Inferences
- A practical workflow: Sharman picks 5 to 10 reference screens (for example sci-fi or industrial HUDs) and saves them into the repo, and Claude reads the images directly. That beats scraping.

### Gaps
- Interface In Game, Behance and ArtStation were not researched (tool budget). Behance and ArtStation are known to be JS-heavy and login-gated, which is unverified here.

## Q4: Roblox UI frameworks and techniques that raise quality

### Takeaway
Roblox now has rich native styling: UIGradient (radial and conic in beta), UIStroke (inner/outer, miter joins), per-corner UICorner, UIShadow with blur, spread and inset, 9-slice, and a StyleSheet/StyleQuery styling system. These primitives can deliver "carbon fibre + orange glow + chrome" without flat-frame slop. Native custom font upload still does not appear to exist; bitmap fonts are the workaround.

### Cited Findings
- **UIGradient:** Color, Transparency, Offset, Rotation. **Beta:** Type (Linear, Radial, Elliptical, Conical), Scale, TileMode (Clamp, Repeat, Mirror). Enable via File > Beta Features > Upgraded UIGradients. — [Creator docs: Appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers)
- **UIStroke:** StrokeSizingMode (scale with parent or font size), ApplyStrokeMode, BorderStrokePosition (Center, Inner, Outer), BorderOffset, LineJoinMode (Round, Bevel, Miter), ZIndex for stacking strokes. A child UIGradient gives gradient strokes (chrome bevels). The docs warn against tweening UIStroke.Thickness on text. — [Appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers)
- **UICorner:** per-corner radii (TopLeftRadius and the others). **UIShadow:** Shape or Text mode, BlurRadius, Spread, Offset, Inset, ShowBehindParent, a child UIGradient for multicolour shadows (orange glow). Some features are beta under "Upgraded UIShadows". — [Appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers)
- **9-slice** (SliceCenter on ImageLabel/ImageButton) is covered in the official guide. — [Creator docs: UI 9-slice design](https://create.roblox.com/docs/ui/9-slice)
- **UI Styling:** styleable properties cover GuiObjects, modifiers, layouts and constraints, and `StyleQuery` gives conditional breakpoints "similar to container or media queries". — [Creator docs: Styling compatibility](https://create.roblox.com/docs/en-us/ui/styling/compatibility)
- **Fonts:** a community module renders custom fonts as BMFont sprite-sheet ImageLabels "because of Roblox's limited fonts library" (2024). This implies there is no native upload, though the post doesn't say so outright. — [DevForum: Custom Fonts Module](https://devforum.roblox.com/t/custom-fonts-module-cfm/2814574). Framewisp also bakes custom-font text into images, which suggests the same. — [DevForum: Framewisp](https://devforum.roblox.com/t/framewisp-%E2%80%94-turn-a-figma-frame-into-native-roblox-ui-in-one-click/4759239)
- **React-Lua** is used via `jsdotlua/react`, with a DevForum tutorial. — [DevForum: How To: React + Roblox](https://devforum.roblox.com/t/how-to-react-roblox/2964543). GuiForge outputs it. — [GuiForge](https://devforum.roblox.com/t/guiforge-roblox-ui-editorfigma-export/4834077)

### Inferences
- Recipes for this theme:
  - Carbon fibre: a tiled carbon-weave ImageLabel (ScaleType Tile) under the panel, or a 9-slice panel texture.
  - Chrome rim: a UIStroke with a multi-stop grey/white UIGradient, Rotation 90, BorderStrokePosition Inner.
  - Orange glow: a UIShadow (orange, BlurRadius, Spread) or an outer UIStroke with a transparency gradient.
  - Text: a font-sized stroke plus a Text-mode shadow.
- The styling system (StyleSheets with tokens) is the Roblox equivalent of design tokens. It maps onto `Config.luau`-style theme tokens and enforces consistency.
- Pick an engine font that fits sci-fi/industrial (for example Michroma, Orbitron or Oxanium in Roblox's Font list). This is unverified: check the `Enum.Font`/FontFace catalogue in Studio via `execute_luau` before relying on it (CLAUDE.md rule 8).

### Gaps
- Fusion and Vide were not compared in depth. ViewportFrame 3D icons and SurfaceGui were not researched with sources.
- Whether the beta flags (Upgraded UIGradients and UIShadows) are live in published experiences was not confirmed.
- What top Roblox games do was not researched in this pass.

## Q5: Icon and 2D UI art sources

### Takeaway
game-icons.net (about 4,100 SVGs, CC BY 3.0, credit each artist) and Kenney's CC0 UI packs (the UI Pack includes nine-slice frames, plus Sci-Fi and Mobile Controls packs) are safe, high-quality bases. Recolour them to the orange-and-chrome palette.

### Cited Findings
- game-icons.net: about 4,100 SVG icons, CC BY 3.0, credit each artist. — [Cinevva: free game UI kits 2026](https://app.cinevva.com/guides/free-game-ui-kits-fonts); [game-icons.net](https://game-icons.net)
- Kenney (all CC0): UI Pack (430 elements including nine-slice frames), UI Pack Sci-Fi, Input Prompts, Mobile Controls, Kenney Fonts. — [Cinevva](https://app.cinevva.com/guides/free-game-ui-kits-fonts)
- OFL Google Fonts that suit sci-fi: Orbitron, Russo One, Audiowide (OFL; keep the licence file). — [Cinevva](https://app.cinevva.com/guides/free-game-ui-kits-fonts)
- Figma's `generate_image` creates images and uses Figma AI credits. — [FAQs](https://help.figma.com/hc/en-us/articles/39252411778583-Figma-MCP-server-FAQs)
- The Roblox Studio MCP in this environment exposes `generate_texture`, `upload_image` and `store_image` (tool names seen in this session; behaviour not tested).

### Gaps
- Recraft and Scenario (pricing, MCP availability, licence) were not researched in this pass. No claims are made about them.

## Q6: Moon Sweepers art direction

### Takeaway
Moon Sweepers (DragDrop Games, released Oct 23, 2026, $8.99) is a 16-player co-op incremental "clean the Moon with a toothbrush" game in the PowerWash genre. Its tone is deadpan corporate comedy (the "Lunar Surface Department"). No written source describes its UI or visual style, so screenshots must be viewed directly.

### Cited Findings
- Developer and publisher: DragDrop Games. Released Oct 23, 2026. $8.99 (15% launch discount). Tagline: "An entire Moon to clean. One toothbrush to start." Loop: collect dust -> deliver to depots -> launch shipments for payment -> upgrade tools, storage and cleaning vehicles. Tags include Incremental, Automation, Co-op, First-Person, Comedy, Relaxing. Reviews: Very Positive (80% of 1,396). — [Steam store](https://store.steampowered.com/app/5335510/Moon_Sweepers/)
- Over 36,000 concurrent players on Steam. — [Automaton](https://automaton-media.com/articles/newsjp/20261026-475509/); [4Gamers](https://www.4gamers.com.tw/news/detail/82860/moon-sweepers-steam-36000-players-16-player-coop-moon-cleaning-simulator)
- Tone: a deadpan "routine contract work" framing, an "underfunded crew", and "One small brush. One giant cleaning bill." Visually, "dusty terrain visibly becomes cleaner as you pass over it". It is compared to PowerWash Simulator. — [iTechGuides](https://www.itechguides.com/clean-a-whole-moon-with-a-toothbrush-in-moon-sweepers-the-powerwash-genres-latest-crime-against-perfectionists/); [Netto's Game Room](https://www.nettosgameroom.com/2026/10/16-player-moon-cleaning-game-moon.html)
- Update 1.0.4 coverage exists (not read). — [samlover.com](https://samlover.com/2026/10/27/moon-sweepers-update-1-0-4/)

### Inferences
- Its "satisfaction" signals are a visible before/after surface change, storage-fill meters, payout and shipment moments, and upgrade trees. The HUD probably centres on capacity, money and progress (an inference from the loop, not observed).
- The OmegaDev theme (carbon fibre, orange glow, chrome) suits an "industrial space-contractor" reading of this genre: corporate-issue panels and hazard-orange accents.

### Gaps
- No text source describes Moon Sweepers' HUD, fonts or palette. The Steam screenshots were not viewable through WebFetch (text only). Claude should view the screenshots on the Steam page with a browser or image tool, or Sharman should drop screenshots into the repo.
- No press kit was found.

## Cross-cutting: what causes "AI slop" UI and what fixes it

### Cited Findings
- Framewisp and GuiForge both rasterize effects Roblox can't express natively (blur, skew, mixed fonts). That shows pro-looking Roblox UI depends heavily on image assets (9-slices, baked text), not just flat Frames. — [Framewisp](https://devforum.roblox.com/t/framewisp-%E2%80%94-turn-a-figma-frame-into-native-roblox-ui-in-one-click/4759239); [GuiForge](https://devforum.roblox.com/t/guiforge-roblox-ui-editorfigma-export/4834077)
- Claude Design checks output against an imported design system. — [claude.com/design](https://claude.com/design)
- The Figma MCP builds with "your existing libraries", components and variables. — [Write to canvas](https://developers.figma.com/docs/figma-mcp-server/write-to-canvas)
- Blender connector testers found "stylistic requests get generic results", and the Affinity connector "can't yet decide what the script should do". AI connectors execute well but have weak taste unless given references. — [Godberry Studios](https://godberrystudios.com/posts/claude-for-creative-work-9-connectors-tested-2026/)

### Inferences
- Slop comes from four things: flat default Frames with one corner radius, the default Gotham/Builder fonts, no texture or material, generic emoji or icons, and no reference. The fixes:
  1. A written style guide with 5 to 10 reference images (Game UI Database, Moon Sweepers screenshots).
  2. Design tokens: colour, stroke, glow and type scale, stored in a shared Theme module or a Roblox StyleSheet.
  3. Image-based 9-slice panels and buttons (carbon weave, chrome bevel) made once in Figma, Penpot or Photoshop and uploaded.
  4. Layered native modifiers: gradient stroke, UIShadow glow, Text-mode shadow.
  5. Consistent icons (game-icons.net recoloured).
  6. A screenshot-compare loop: Studio MCP `screen_capture` against the Figma `get_screenshot` reference.
