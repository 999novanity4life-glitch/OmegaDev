# Moon Mop: Studio build scripts

These rebuild the round Moon map in Studio (command bar, or the Studio MCP `execute_luau` tool).
They are map tools, not game code. `MoonGravity.client.luau` moves to `src/client` once the game is
scaffolded from `template/`.

Order:
1. `MoonFeatures.luau`: hills, craters and station pads into `ServerStorage.MoonMapData` (seed 42).
2. `MoonSphere.luau` (ModuleScript in ServerStorage): call `run(20)` repeatedly until it reports the last slab.
   Radius 2000 studs, centre (0, -2000, 0), North Station at the origin.
3. `BuildStation.luau` (ModuleScript): `build(CFrame.new(0, groundY - 0.6, 0), "N STATION")`.
4. `DecorateMoon.luau` (ModuleScript): `hexPad(Vector3.yAxis, 110)` and `scatterRocks(800, 7)`.
5. `MoonGravity.client.luau`: LocalScript in StarterPlayerScripts. Set `workspace.Gravity = 0` and
   `workspace.FallenPartsDestroyHeight = -50000` in the place.

Sky: `art/sky/make_sky.py` makes the six faces (Earth painted into the Ft face). The face
orientation was measured in Studio: SkyboxFt looks -Z, Bk +Z, Lf +X, Rt -X.
