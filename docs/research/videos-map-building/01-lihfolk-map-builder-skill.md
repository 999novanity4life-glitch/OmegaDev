# 01. "Roblox map generation skill (Claude / Blender)"  (@lihfolk, TikTok, 1:36, 6.9k views at download)
Source: https://www.tiktok.com/@lihfolk/video/7709982456744643853 (sent by Sharman 2026-11-19). Downloaded on the Mac with yt-dlp; frames via ffmpeg; speech via Whisper small.en. Frames: `frames/01-gallery.jpg`, `frames/01-install.jpg`.

What it shows: a promo for a paid-free (Discord-gated) Claude skill `roblox-map-builder` v1.1.0 (zip, 564 files). Webcam talk over a gallery page titled "Roblox Map Builder: maps scripted in Blender and exported Roblox-ready: photoreal interiors to stylised worlds", then the Claude desktop app installing the zip. No build process is shown.

Techniques (heard / seen):
- 0:20 "This is actually more Blender logic than it is Roblox Studio." He drives it "mainly through the Blender MCP". Maps are **scripted in Blender** (Python via MCP) and exported to Roblox (gallery subtitle).
- 0:08 Built over "days and days of prompting", "as many high quality passes as I can, fix as many flaws as I can": the quality comes from repeated critique-and-fix passes, not one shot.
- 0:30-0:55 Gallery of 14 maps across styles: photoreal warehouse (Northgate Distribution), recording studio (Mic Drop Studios, 2 shots), candy kingdom, valley lake with waterfall, observatory island (Starwatch Spire), PvP arena, desert ruins, care centre, lagoon, forest, snow village, sky islands, race track.
- 1:05 Use: ask for a map normally ("make me a forest map"), then call `/roblox-map-builder` so the skill takes over.

Seen in the gallery (inferred, not stated): the strong shots share (a) a single hero composition per shot, (b) bevelled, textured meshes, not parts, (c) dense meso props along walls (racks, crates, forklifts) with an open floor in the middle, (d) warm/cool light contrast. The gallery images look like Blender renders; how they look inside Roblox is **not shown**.

Unclear / not shown: the skill's contents (Discord only), how meshes/materials reach Roblox (upload route, triangle counts), any in-Studio screenshot or playtest.

Applies to our games: confirms our "mesh first" rule (M18) and the Blender MCP already on the Mac. Free MIT alternative found while checking: EL4CTEO/blender-skills (`blender-environment-kits`, `blender-export-pipelines` incl. Roblox, `blender-asset-qa`, `blender-time-of-day`).

Rulebook lines added: M29, M30, M31.
