# EPC2018 | Wave Function Collapse in Bad North | Oskar Stalberg
- Channel: BUas Games | URL: https://www.youtube.com/watch?v=0bcZb-SsnrA | Length: 37:41 | Upload: 2018-07-11 | Captions: auto

- [1:01] Publish interactive demos, not just screenshots or videos.
- [2:05] Wave Function Collapse (credited to Maxim Gumin) derives adjacency constraints from examples and builds a larger output consistent with them. It works in 3D and on any tile layout.
- [3:35] WFC is content-agnostic: it just fits things together.
- [5:08] Art lesson from an earlier prototype: it was "too colorful". A very colorful environment makes gameplay and UI hard to read on top of it.
- [6:10] A slot is a grid position and a module is what goes in it.
- [8:15] Missing transitions cause failures. Sets with no transition piece collapse the whole grid into one material.
- [8:50] Every slot starts with every module possible. "Placing" a module means removing all other possibilities.
- [9:21] Propagation: removing the last module that offered a socket forces neighbors to drop what relied on it, recursively.
- [9:54] Start naive (re-check everything after each change), then optimize so a slot only notifies a neighbor when it loses the last module of a socket type.
- [11:25] Derive sockets automatically: sample each edge at 3 points, hash, round values first; show the hashes for debugging.
- [12:25] WFC is constraint programming: hard constraints for adjacency, heuristics (probabilities, noise) to choose between valid options.
- [15:30] Resolve initial constraints first: sky on the outside, water at the bottom. That alone outlines the island.
- [16:00] Place key gameplay anchors first (a hole for the house).
- [17:12] A few hundred modules plus rotations and mirrors gives roughly 100,000 possibilities. Generation time grows exponentially with size, so keep islands small.
- [18:54] Navigability: bake a simple navigation graph into each module rather than validating and discarding levels afterwards.
- [19:59] Heuristic: score tiles higher if they grow the navigable area.
- [20:29] Validate during and after generation; discard levels with too little beach or a closed-off network.
- [21:00] Backtracking: snapshot the state once initial constraints are resolved and reload it on any contradiction.
- [23:18] Start with a tiny set to define the key decisions, then add content. Final set about 300 tiles.
- [24:21] Build tooling: an adjacency checker that highlights every module whose side fits the selected side.
- [24:52] Model everything in one scene, auto-slice it into tiles; triangles spanning two tiles merge them into a multi-tile piece, which breaks up obvious tiling.
- [27:28] Make corners slightly asymmetrical so mirroring gives several variants cheaply.
- [28:30] Detail goes where surfaces meet: grass-to-cliff edges and the lip of convex edges tell "small stories". Detail should mostly mark transitions.
- [30:04] The environment is a canvas for gameplay: beautiful but not overly detailed.
- [31:41] Triangles and hexes suit large terrain shapes; cubes suit houses and small shapes.
- [34:15] No module next to its own mirror (looks bad and happens often). Use themes plus color and foliage swaps to fight sameness.

Applies to Roblox how (inferred): Build island terrain as WFC over a slot grid of tile Models with hashed edge sockets. Seed spawns and key buildings first, score picks by how much they grow a walkable graph, and restore a snapshot on contradiction. Keep tile art muted so VFX and UI stay readable.
