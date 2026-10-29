# AI generators for 3D models, textures and 2D game art that Claude can drive, and how their output gets into Roblox

Researched 2026-10-29. Every price below was copied from a vendor page or a price tracker. Aggregator prices (CostBench, inker, Sloyd's own leaderboard) are marked "aggregator" and can be stale; check them against the vendor before budgeting. Tools I could not source in this pass are listed under Gaps, not guessed.

Context: small team, Claude Code on an Apple Silicon MacBook Air, Roblox Studio MCP plus Blender bpy already in use, target look is stylized sci-fi ("Moon Sweepers").

---

## Q1. Which 3D generators have a working MCP today, and which give the cleanest low-poly stylized game-ready meshes?

### Takeaway
Meshy has the most complete official MCP: generate, remesh, retexture, rig, UV unwrap and download, all from Claude. Low-poly/topology controls and a documented Roblox workflow make it the best fit for this studio's direct API route. Tripo's official MCP is alpha and only works through Blender. Rodin, Hunyuan3D, Meshy and Tripo are all reachable through the community `blender-mcp` add-on, which fits the team's existing Blender step. fal.ai's official MCP is a generic gateway to its image-to-3D catalogue. Roblox's own generate_mesh is the zero-setup option inside Studio, but it gives less control.

### Cited Findings

**MCP availability**
- **Meshy has an official open-source MCP server** at https://github.com/meshy-dev/meshy-mcp-server (`npx add-mcp @meshy-ai/meshy-mcp-server --env MESHY_API_KEY=...`). Its tools cover text-to-3D, image-to-3D, multi-image-to-3D and refine, then remesh, retexture, rig, animate, convert, resize, UV unwrap, text-to-image/image-to-image, task status/download, and balance. MCP calls cost the same credits as the REST API. — [Meshy docs: AI integration](https://docs.meshy.ai/de/api/ai)
- **Tripo has an official MCP** at https://github.com/VAST-AI-Research/tripo-mcp. The README says it is "in alpha" and "currently supports only the Tripo Blender Addon integration", so Blender and the Tripo addon are prerequisites. — [GitHub tripo-mcp](https://github.com/VAST-AI-Research/tripo-mcp)
- **blender-mcp (community)** at https://github.com/ahujasid/blender-mcp connects to:
  - Poly Haven (HDRIs, textures, models; no key needed)
  - Hyper3D Rodin via a `generate_3d` tool (your own key in `BLENDERMCP_HYPER3D_API_KEY`, or the paid "Premium")
  - Sketchfab (API key), Poly Pizza low-poly models (free key)
  - Hunyuan3D via Tencent Cloud (depends on account region), Meshy (needs a paid plan or Premium), and Tripo
  
  It collects minimal anonymous telemetry by default; set `DISABLE_TELEMETRY=true` to turn it off. — [GitHub blender-mcp](https://github.com/ahujasid/blender-mcp)
- **fal.ai has an official remote MCP** at `https://mcp.fal.ai/mcp-relay`. Install with `claude mcp add --transport http --scope user fal https://mcp.fal.ai/mcp-relay`, then sign in with OAuth. Tools: `search_models`, `run_model`, `submit_job`/`check_job`/`get_job_result`, `upload_file`, `get_pricing`. The catalogue has an image-to-3D category. The MCP itself is free and you pay per model run at API rates. The page does not name Hunyuan3D, TRELLIS or Tripo specifically. — [fal docs: MCP](https://fal.ai/docs/model-apis/mcp)
- **Scenario's official MCP** at https://mcp.scenario.com/ also covers 3D generation, alongside image, video and audio. It gives no per-tool detail. — [Scenario MCP feature page](https://www.scenario.com/features/mcp)
- **Roblox Studio MCP** (built into Studio; macOS binary `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`; Claude Code is a listed quick-connect client) includes:
  - `generate_mesh`: "textured 3D mesh from a text prompt"
  - `generate_material`: "custom material variant", returns base material + variant name
  - `generate_procedural_model`: a ProceduralModel built from primitive parts, accepts reference images
  
  Doc page last updated 2026-10-28. — [Roblox Studio MCP docs](https://create.roblox.com/docs/studio/mcp.md)

**Topology, polycount and quality**
- **Tripo P1** outputs clean meshes with "proper edge flow" capped at 20K faces, and the article says no retopo is needed for game engines. Rodin Gen-2.5 goes up to 2M faces and Hunyuan 3D up to 1.5M. Hunyuan has a LowPoly mode (plus Normal/Geometry/Sketch). Rodin has no low-poly mode, but its "creative mode" gives more polished, stylized surfaces. (3D AI Studio, 22 May 2026; a reseller.) — [3daistudio comparison](https://www.3daistudio.com/blog/rodin-2-5-vs-tripo-vs-hunyuan-3d-comparison)
- **Quad and face-range options** (inker, a reseller, published 8 Oct 2026):
  - Quad mesh is optional on Meshy 7.1/7/6 and Tripo H3.1.
  - Tripo P2 offers 5k–25k faces; Tripo P1 offers 2k–20k faces.
  - Hunyuan 3D 3.1, Rodin Gen-2.5 and TRELLIS 2 have no quad option.
  - Rodin Gen-2.5 has a 4K texture option.
  
  — [inker comparison](https://inker.si/blog/best-ai-3d-model-generators-2026)
- **Meshy for Roblox:**
  - Roblox caps a mesh at 20,000 tris, and rigid accessories at 4,000.
  - Meshy suggests 2,000–10,000 tris for most props, set with "Smart Topology" during generation rather than decimating afterwards.
  - Generate characters in a T-pose.
  - A Meshy→Roblox Bridge ("Send to Roblox") needs Meshy Pro or higher.
  
  — [Meshy Roblox workflow tutorial](https://www.meshy.ai/tutorials/3d-model-for-roblox-workflow)
- **Strengths per tool (no overall winner, per the article):**
  - Meshy: a low-poly mode, optional remeshing and PBR.
  - Sloyd: parametric hard-surface props with "clean topology" and sliders.
  - Tripo: fast image-to-model iteration.
  
  — [Wavect, 13 Aug 2026](https://wavect.io/blog/ai-3d-model-generators-game-development-2026/)

**Running locally on Apple Silicon**
- **TRELLIS.2** runs on Apple Silicon via the community port https://github.com/shivampkumar/trellis-mac. On an M1 Max 64GB:
  - Peak RAM was about 18GB. "16GB Macs don't run this model"; "24GB is the real minimum".
  - Generation took about 3.3 min.
  - PBR texture baking took 66–224 min and produced unusable red-noise textures, so vertex colours are the practical default.
  - The 1024 pipeline crashed.
  - A pixel-art input produced a flat, broken mesh.
  
  (21 Apr 2026.) — [lilting.ch hands-on](https://lilting.ch/en/articles/trellis2-m1-max-hands-on)
- **Hunyuan3D 2.1 on Mac:** a community Mac fork exists at https://github.com/VladimirTalyzin/hunyuan3d-2.1-mac, and a Japanese write-up runs Hunyuan-3D from ComfyUI on a Mac GPU. I did not open either to check quality or RAM. — [Search result: hunyuan3d-2.1-mac README](https://raw.githubusercontent.com/VladimirTalyzin/hunyuan3d-2.1-mac/main/README.md); [zenn.dev article](https://zenn.dev/renue/articles/144cd47fbe9d7a)

**Prices**

| Tool | Free tier | Paid plans | Cost per generation | Source (date) |
|---|---|---|---|---|
| Meshy | 100 credits/month | Monthly prices not on this page | Text-to-3D 20 credits (Meshy 6) or 10 (Lite); image-to-3D 20–25; AI texturing 10 | [Meshy pricing docs](https://docs.meshy.ai/en/webapp/pricing) |
| Tripo | $0, 200 credits | Pro $20/mo (3,000 cr), Max $90 (25,000), Team $110/seat (90,000); API billed separately by usage | — | [CostBench Tripo](https://costbench.com/software/ai-3d-generation/tripo-ai/) (aggregator, verified 20 Oct 2026; internally inconsistent on the Team price) |
| Rodin (Hyper3D) | 10 one-time credits; previews free, credits spent on download | Creator $24/mo, Business $120/mo (includes API) | API base about $0.40/generation | [CostBench Rodin](https://www.costbench.com/software/ai-3d-generation/rodin-hyper3d/) (aggregator, Aug 2026; page contradicts itself with $15/$30 elsewhere) |
| Sloyd | Guest: one AI generation/day | Plus $15/mo (commercial licence), Pro $50/mo | — | [Sloyd pricing blog](https://www.sloyd.ai/blog/ai-3d-model-generator-pricing) (vendor) |

- Sloyd's per-generation leaderboard (3 Aug 2026): Meshy 6 $0.40, Tripo v3.1 $0.30, Rodin Gen 2.5 $0.29. — [Sloyd pricing blog](https://www.sloyd.ai/blog/ai-3d-model-generator-pricing)

### Inferences
- For this studio, the lowest-friction stack:
  - Meshy MCP for API-driven props: low-poly/remesh plus UV unwrap from Claude, GLB out.
  - blender-mcp for Rodin/Hunyuan/Tripo, plus Poly Haven/Poly Pizza kitbash, with bpy cleanup in the same Blender session.
  - Roblox generate_mesh for quick placeholders.
- TRELLIS/Hunyuan locally on a MacBook Air is not practical: 24GB+ RAM, very slow texture baking, broken textures. Use them through cloud APIs (fal, Tencent Cloud, blender-mcp) instead.
- Tripo P1/P2's face caps (2k–25k) suit Roblox's 20k-triangle mesh limit well. Rodin's 2M-face output always needs decimation.

### Gaps
- No official MCP found for Rodin, Hunyuan3D, CSM, Luma Genie or Sloyd beyond blender-mcp. Community `pasie15/tripo-ai-mcp-server` and Scenario MCP forks exist on glama, but I did not inspect them.
- CSM, Luma Genie and Stability SPAR3D: no quality or price data gathered. SF3D's licence is in Q3.
- Independent topology benchmarks focused on stylized assets: none found. The comparisons above are reseller blogs (3daistudio, inker) and vendors (Meshy, Sloyd), so treat them with caution.

---

## Q2. Which image tool gives the most consistent custom art style (trained on reference images) for icons, UI art and textures, and has an MCP or simple API?

### Takeaway
Scenario is the strongest fit. It is built for game art, trains custom style LoRAs from 10–30 images, and has an official MCP that can run training and generation from Claude. Recraft has an official MCP with custom styles and native vector (SVG) output, which suits flat UI icons. fal.ai's official MCP is the cheap generic route to Flux and similar models. Midjourney has no official API, so Claude cannot drive it cleanly.

### Cited Findings
- **Scenario MCP** at https://mcp.scenario.com/ (setup guide on help.scenario.com):
  - Supports uploading reference images, starting a training run, and generating with your custom LoRA "through natural language", including composing LoRAs.
  - Also covers image, video, 3D and audio generation and asset search.
  
  — [Scenario MCP page](https://www.scenario.com/features/mcp); [Scenario blog announcement](https://scenario.com/blog/Scenario-Is-Now-Available-Directly-in-Your-AI-Agent)
- **Scenario pricing:**
  - Starter $15/mo (1,500 credits, no custom training).
  - Pro $45/mo (5,000 credits, custom model training).
  - Max $75/mo (10,000 credits).
  - Free tier: "50 free daily credits" (the FAQ says "50 credits", so it is unclear whether it resets daily).
  - Style models need 10–30 images; character/object models need 5–15. Training takes 30 min to a few hours.
  - "API-first" (docs.scenario.com).
  
  — [Scenario pricing](https://www.scenario.com/pricing)
- **Recraft remote MCP** at `https://mcp.recraft.ai/mcp`, sign in with OAuth:
  - Raster and vector generation, custom styles, vectorization, background removal and upscaling.
  - Calls draw subscription credits.
  - No per-generation price or licence on that page.
  
  — [Recraft MCP getting started](https://recraft.ai/docs/mcp-reference/getting-started)
- **fal official MCP** (details in Q1) reaches the fal model catalogue, e.g. the `fal-ai/flux/dev` endpoint, with per-run billing and a `get_pricing` tool. It recommends submit/check/result for long jobs, including training. — [fal MCP docs](https://fal.ai/docs/model-apis/mcp)
- **Midjourney:**
  - Plans: Basic $10, Standard $30, Pro $60, Mega $120/mo.
  - Stealth (private) mode only on Pro/Mega.
  - The article does not mention an official API.
  
  — [LicenseOrg, 26 Feb 2026](https://licenseorg.com/blog/midjourney-license-explained)
- **Roblox Studio MCP** includes `generate_texture`, `upload_image` (batch from HTTP URLs, returns asset IDs) and `store_image` (local image to URI). That means images generated elsewhere can be pushed straight into Roblox from Claude. — [Roblox Studio MCP docs](https://create.roblox.com/docs/studio/mcp.md); generate_texture appears in this session's Studio MCP tool list, but the docs page does not describe it.

### Inferences
- Recommended pipeline for icons, UI and decals:
  - Train a Scenario style model on 10–30 curated Moon Sweepers-like reference frames. Use your own paintovers or licensed refs, not the game's screenshots, to avoid copying another studio's IP.
  - Generate from Claude via the Scenario MCP.
  - Push results into Roblox with Studio MCP `upload_image`.
  - Use Recraft for flat vector UI icons where crisp scaling matters.
- Midjourney is a poor fit for an agent-driven studio: there is no official API, and private mode needs the $60 tier.

### Gaps
- Leonardo, OpenAI gpt-image, Google Gemini/Imagen, Layer.ai, Adobe Firefly: I gathered no sourced pricing, MCP or style-training details in this pass. Layer.ai pricing exists on toolradar (https://toolradar.com/tools/layer-ai/pricing), but I did not open it.
- Recraft's per-image price and custom-style training limits were not stated on the MCP page.
- No benchmark found that compares style consistency across these tools. Rankings are by feature set only.

---

## Q3. What are the licence and commercial-use gotchas for each?

### Takeaway
On every major 3D SaaS, free-tier output is either CC BY 4.0 or non-commercial: Meshy free is CC BY (attribution required); Tripo free is public and non-commercial; Scenario free is personal/evaluation only. Pay before generating anything you ship. The Hunyuan3D open-weights licence excludes the EU, UK and South Korea, which matters if anyone on the team, or the service you run, is located there. Stability's licence is free under $1M revenue. Poly Haven and ambientCG are CC0, the safest choice.

### Cited Findings
- **Meshy:** free plan output is CC BY 4.0 (commercial use with attribution). All paid plans include commercial rights, ownership of output and a "private license". — [Meshy pricing docs](https://docs.meshy.ai/en/webapp/pricing)
- **Tripo:** free plan models are "public and non-commercial", CC BY 4.0. Paid plans include commercial rights "for models generated during the subscription". — [CostBench Tripo](https://costbench.com/software/ai-3d-generation/tripo-ai/) (aggregator); Tripo's own licensing article: [tripo3d.ai blog](https://www.tripo3d.ai/blog/commercial-use-ai-3d-models) (not opened)
- **Rodin:** contracts auto-renew and generally cannot be cancelled within the term. Credits are spent on download. — [CostBench Rodin](https://www.costbench.com/software/ai-3d-generation/rodin-hyper3d/) (aggregator)
- **Hunyuan3D 2.0 Community Licence:**
  - Territory is worldwide **except the EU, UK and South Korea**; use outside the Territory is unlicensed (§1.l, §5(c)).
  - Products with more than 1M MAU must request a licence from Tencent (§4).
  - Tencent claims no rights in outputs (§6(d)).
  - Outputs cannot be used "to improve any other AI model" (§5(b)).
  - Services built on it must disclose the provider and that Tencent does not endorse it (§3(e)).
  
  — [HF Hunyuan3D-2 LICENSE](https://huggingface.co/tencent/Hunyuan3D-2/blob/main/LICENSE)
- **Stability AI Community Licence:** free for organisations under $1M annual revenue. Above that you need an Enterprise licence. You own outputs. Stable Fast 3D (SF3D) is listed under it; SPAR3D is not named on the page. — [stability.ai/license](https://stability.ai/license)
- **Scenario:** all paid plans include a "full commercial license", you own outputs, and there are no royalties. Free outputs are personal/evaluation only. — [Scenario pricing](https://www.scenario.com/pricing)
- **Midjourney:**
  - Free trial images are CC BY-NC 4.0.
  - Companies with more than $1M prior-year gross revenue need Pro or Mega.
  - Basic and Standard images are public in the gallery.
  
  — [LicenseOrg](https://licenseorg.com/blog/midjourney-license-explained)
- **Sloyd:** the Plus plan includes a commercial licence; Guest is personal use. — [Sloyd pricing blog](https://www.sloyd.ai/blog/ai-3d-model-generator-pricing)
- **Poly Haven and ambientCG:**
  - Both are CC0 with no attribution required, and both have free APIs with no key.
  - Poly Haven: 850+ PBR textures (1K–8K; diffuse/normal/rough/disp/AO), 990+ HDRIs, 520+ models (Blend/glTF).
  - ambientCG: 2,000+ CC0 materials.
  - Stylized CC0 alternatives: 3DTextures.me (sci-fi panels) and Kenney (flat/prototype).
  
  — [Cinevva free textures guide, Sept 2026](https://app.cinevva.com/guides/free-textures-hdris-materials)
- **blender-mcp telemetry** may be used "to train AI models" unless disabled. — [GitHub blender-mcp](https://github.com/ahujasid/blender-mcp)

### Inferences
- Check team location before using Hunyuan3D open weights. If any team member is in the UK or EU, self-hosting Hunyuan is unlicensed. Tencent Cloud's hosted API has its own terms, which I did not check.
- Keep a provenance log (tool, plan, date, prompt) per shipped asset. Free-tier generations made before upgrading may stay CC BY or non-commercial (Tripo's rights cover "models generated during the subscription").

### Gaps
- Roblox's terms for GenerationService / Cube 3D output ownership: not found in this pass.
- Recraft, Leonardo, OpenAI, Google, Adobe Firefly and fal-hosted Flux licences (FLUX.1 [dev] is non-commercial weights, but fal's terms for outputs were not checked): not sourced.

---

## Q4. What do Roblox's own Studio MCP generate_mesh / generate_texture / generate_material produce, how do they compare, and how do you get external output into Roblox?

### Takeaway
Roblox's tools are built on the Cube 3D model (GenerationService). They give in-engine textured meshes with a MaxTriangles knob, part schemas (Car5/Body1/custom) and segmentation. They are convenient for placeholders and functional props, but offer less style control and no PBR detail compared with Meshy, Tripo or Rodin plus Blender cleanup. For external assets: one mesh is at most 20,000 triangles; single material per mesh; PBR via SurfaceAppearance with OpenGL normals; a practical 1024px texture target; GLB is the easiest import.

### Cited Findings
- **GenerationService** (Cube 3D foundation model):
  - `GenerateMeshAsync` (server) returns a generation ID; `LoadGeneratedMeshAsync` (client) returns a Model holding one MeshPart with an **EditableMesh**. Editable meshes are not replicated, and each ID loads once.
  - `GenerateModelAsync` takes text and/or an image, with options `Size` (approximate), `MaxTriangles` (lower = lower-poly) and `GenerateTextures` (default true). Schemas: `Car5`, `Body1` or custom Groups.
  - `SegmentMeshAsync` splits an existing MeshPart into named parts (Studio only).
  - There are per-minute rate limits, moderation, and a prompt character limit (value not given).
  
  — [GenerationService reference](https://create.roblox.com/docs/reference/engine/classes/GenerationService.md)
- **Studio MCP tools:**
  - `generate_mesh`: textured mesh from text.
  - `generate_material`: "custom material variant", returns base material + variant name to apply to parts. This is MaterialVariant-style tiling surface material, not a SurfaceAppearance.
  - `generate_procedural_model`: a ProceduralModel from primitives (blocks, spheres, cylinders, wedges), accepts reference images and part schemas.
  - `wait_job_finished` returns job status.
  
  — [Roblox Studio MCP docs](https://create.roblox.com/docs/studio/mcp.md)
- **Mesh specifications:**
  - "Individual meshes can not exceed 20,000 triangles."
  - Watertight, no zero-thickness geometry; quads preferred, no N-gons.
  - Bones frozen at scale 1 / rotation 0, at most 4 influences per vertex, one animation track per mesh.
  
  — [Roblox general specifications](https://create.roblox.com/docs/en-us/art/modeling/specifications.md)
- **Texture specifications:**
  - PBR set: Albedo (RGB), Normal (**OpenGL tangent-space only**), Roughness, Metalness and Emissive Mask (8-bit grayscale).
  - Uploads up to 4096², but the UV section says texture maps are supported up to 1024².
  - Guidance: 256² for 5-stud objects, 512² for 10, 1024² for 20.
  - One material per mesh, one UV set; png/jpg/tga/bmp.
  
  — [Roblox texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications)
- **Import route:**
  - Prefer GLB: a single file with textures embedded. Meshy FBX needs manual texture upload.
  - Use File > Import (Ctrl+M) and set Scale Unit, because the default stud is often wrong.
  - Fix yellow warnings (usually missing textures).
  - Set CollisionFidelity per MeshPart (Box/Hull/Default/PreciseConvexDecomposition).
  - Keep uploads under 20MB; large PBR sets are the usual culprit.
  - A "grey mesh" means textures did not link, so check SurfaceAppearance/TextureID.
  - Split architecture into several meshes rather than over-decimating.
  
  — [Meshy Roblox workflow](https://www.meshy.ai/tutorials/3d-model-for-roblox-workflow)
- **Practical tri budgets** (vendor blog, self-contradictory on accessory limits): simple props 500–2,000, complex props 2,000–5,000, characters 2,000–8,000. Freeze scale at 1,1,1 and keep textures at 1024² or below. — [Nilo triangle-limit article](https://nilo.io/articles/vibe-code-roblox-triangle-limit)
- **Typical failure modes and fixes:**

  | Failure mode | What goes wrong | Fix |
  |---|---|---|
  | Topology | Dense triangles follow appearance, not deformation | Retopo or decimate to budget; approve deformation loops before rigging |
  | Baked lighting in albedo | Shows up once the asset is relit | Check PBR maps under neutral light; bake normal/AO from a high-poly source onto low-poly |
  | Style drift across a set | Bevels, materials, scale and detail level vary between assets | An approved style set plus a human art-direction gate |
  | UV seams, overlaps, texel density | Visible artifacts | Validate UVs against a seam/overlap policy |
  | Single-view ambiguity | Backs and undersides are invented | Multi-view references |

  Measure "cost per accepted asset", not credits. — [Wavect](https://wavect.io/blog/ai-3d-model-generators-game-development-2026/)
- **Rodin offers "delighting"**, which removes baked lighting, plus 5 texture quality levels. — [3daistudio comparison](https://www.3daistudio.com/blog/rodin-2-5-vs-tripo-vs-hunyuan-3d-comparison)
- **Hunyuan's Sketch mode** turns rough concept art into 3D, which supports a concept-first workflow. — [3daistudio comparison](https://www.3daistudio.com/blog/rodin-2-5-vs-tripo-vs-hunyuan-3d-comparison)

### Inferences
- Pipeline that avoids the "AI slop" look:
  1. Generate concept art in the trained Scenario style. That gives one style anchor for all assets.
  2. Run image-to-3D (Meshy/Tripo via MCP, or Rodin/Hunyuan via blender-mcp) with low-poly or quad settings.
  3. In Blender via bpy: decimate to ≤10k tris, rebuild UVs, flatten or delight the albedo, bake down at ≤1024², export GLB.
  4. Import via the Studio MCP / 3D Importer and apply SurfaceAppearance.
  5. Use playtest `screen_capture` to check against the style set.
- For stylized sci-fi, hard-surface kit pieces (panels, crates, consoles) are often better as Sloyd/parametric output or as Blender kitbash from CC0 packs (Kenney, Poly Pizza, Poly Haven) than as single-image AI meshes. AI output fits better for organic or hero props.
- Roblox `generate_material` makes tiling MaterialVariants. For terrain or panel surfaces it overlaps with CC0 ambientCG/Poly Haven, which give full PBR maps and no licence risk.

### Gaps
- No Roblox doc or DevForum source found that describes `generate_texture` output (it is not on the MCP docs page), or quality comparisons of Cube 3D against Meshy, Tripo or Rodin.
- The Roblox texture docs contradict themselves (4096 upload vs 1024 support). Test in Studio.
- Adobe Substance 3D Sampler, Withpoly and Meshy texturing were not compared beyond Meshy's 10-credit texturing price.
- Reddit r/gamedev and r/blender reputation threads were not retrieved in this pass.
