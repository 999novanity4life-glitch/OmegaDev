# 3D tilt menu kit (Dark Glass settings panel)

A settings panel that floats in 3D and leans toward the cursor, with the world dimmed behind it. Rebuilt from scratch after a BuiltByBit reference; hand-tested by Sharman (all buttons work) and sharpened to a 2x canvas on 2026-10-23.

| File | Put it at |
|---|---|
| `Screen3D.luau` | ReplicatedStorage.Screen3D |
| `Settings3D.client.luau` | StarterPlayerScripts.Settings3D |

Open with **M** or the gear button. Tabs: Gameplay, Graphics, Sound, Accessibility, Info.

Rules learned building it: SurfaceGui on a camera-locked part with `AlwaysOnTop = false` (AlwaysOnTop did not render); blur with DepthOfField plus a dim plane (BlurEffect blurs the panel too); part `CanQuery` only while open; no CanvasGroup (renders soft); tilt at most 3 degrees.
