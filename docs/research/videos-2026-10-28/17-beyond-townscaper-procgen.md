# SGC21 - Oskar Stålberg - Beyond Townscaper
- Channel: Sweden Game Arena | URL: https://www.youtube.com/watch?v=Uxeo9c-PX-w | Length: 52:01 | Upload: 2021-12-08 | Captions: auto

- [2:31] Use tiles for architecture. Procedural code places standardized tiles, and artists handcraft what goes inside them, so you don't have to write a system for each architectural element.
- [3:32] Townscaper's grid is made entirely of irregular quads, squeezed and skewed. The "organic European" streets come from that skew.
- [4:32] Build every module as square corners and skew them to fit. One standard makes everything possible.
- [5:03] The common approach slices tiles with the transition (the cliff) pushed in or out, which needs tiles for the full 3x3 (8-neighbor) neighborhood.
- [7:08] Graph duality: build tiles on the dual grid, where tile corners sit at cell centers. On a hex grid this needs only about 4 triangle modules.
- [8:39] The interesting visuals are in the transitions (grass to border to cliff to water to waves). Dual-grid slicing gives transitions the most space. Use it for terrain and large amorphous buildings.
- [9:09] Small objects such as small houses and characters go on the primary cells, not the dual.
- [9:09] Put rivers on edges between tiles; roads go cell to cell.
- [10:41] Square grids suit architecture; hex grids suit organic world maps. Hex drawback: long, wavy "straight" coastlines.
- [12:47] Mixing triangle and square tiles: rivers and deltas on triangles; beach-meets-cliff and waterfalls on squares, so you avoid more than one transition meeting at a single point.
- [14:17] Workflow: one big messy Maya scene imported as "triangle soup". An import script slices it into modules, color-codes matching edges, generates shifted variants, and removes duplicates that are only rotations or mirrors.
- [15:52] Wave Function Collapse places the tiles. If it runs fast, restarting until it succeeds is fine.
- [16:52] Generate from the edges inward and only allow the same height or higher. Natural landscapes rarely have local minima: "erosion backwards".
- [18:22] To guarantee navigability, only allow a tile if it extends the current navigable area. Reject dead ends and unreachable land.
- [19:56] Pipeline: Delaunay triangulation, relax, build a 3D cage around placed modules, then deform. Tiles too small or large for gameplay are weighted to grow or shrink.
- [21:28] Then smooth the mesh carefully, since triangles can flip or paths become too narrow to walk. Lots of iteration on "magic numbers."
- [22:28] Advantage of tile-based generation over heightfield and erosion: a known, valid topology with tiles of roughly equal size, paths wide enough, and taggable tiles.
- [23:29] Place doors and windows with a separate prop placement pass that fits as many props as possible without overlap.
- [24:30] Fake boolean with the stencil buffer for windows (not available in Roblox).
- [25:31] Mix clear, distinct cliffs (readable walkable areas) with gentle slopes generated as discrete steps and smoothed after.
- [28:02] Don't let players edit the base grid.
- [28:33] Grid generation: triangulate, join some triangles into quads, then subdivide everything into quads. Generate in chunks and aim for roughly uniform quad sizes. Hand-designed grid patches add special spots.
- [29:35] Support legs come from a rule, not structural analysis: every hanging corner needs a leg.
- [34:10] Edge matching: hash the border geometry of each cell; round carefully. Mark faces by material (navigable, water, cliff).
- [37:15] Minimize manual markup. Derive as much as possible automatically.
- [42:57] Hide UV seams with very subtle textures ("you don't need to tell the player over and over this is brick"). Pixel-thin outlines keep a drawn look and make textures of different scales fit together.
- [46:29] Fake AO from a low-res voxel slice atlas, fast enough for mobile.
- [49:34] Setting games on water removes the need for horizons and background LODs. Keep reflections more abstract than the source.

Applies to Roblox how (inferred): For procedural zones, generate on a grid with a small kit of corner modules with tagged edge sockets, place them from the edges inward with a "height never decreases" rule, and reject placements that break reachability. Scatter props as a separate non-overlapping pass. Roblox has no stencil buffer, so cut-out windows need real geometry or CSG.
