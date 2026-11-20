# Map-building video lessons

Videos Sharman sends to teach map building. Each video gets one note here (`NN-short-name.md`); every lesson that holds up goes into `docs/rulebooks/MAP_RULEBOOK.md` section 10 with a link back.

## How to study a video (same pipeline as `video-lessons-2026-11-19/`)
1. **Get the file.** Camera-roll uploads land in project files `uploads/hearth/` (no extension). TikTok/YouTube links: the cloud container is blocked; fetch on the Mac through Remote Control (yt-dlp), never ask Sharman to download.
2. **Frames.** `ffmpeg -i in.mp4 -vf "fps=1,scale=480:-1,tile=4x3" sheet_%02d.jpg` for contact sheets, plus full-size frames at every scene change (`-vf "select='gt(scene,0.3)'"`). Look at them, don't guess.
3. **Speech.** Whisper small.en via sherpa-onnx (GitHub release assets work, HuggingFace is blocked).
4. **Note** (template below). Only what was seen or heard; label inferences.
5. **Rules.** Promote each concrete, repeatable technique to a numbered rule in the rulebook; skip pure showcases.

## Note template
```
# NN. <title>  (creator, length, source)
What it shows: one paragraph.
Techniques (seen/heard, with timestamp):
- 0:12 ...
Numbers worth keeping (sizes, counts, settings):
Applies to our games: ...
Rulebook lines added: M__
Unclear / not shown:
```

## Index
| # | Note | Creator | Lesson |
|---|---|---|---|
| 01 | [Roblox map generation skill (Claude/Blender)](01-lihfolk-map-builder-skill.md) | @lihfolk | Script maps in Blender via MCP, export meshes; many critique passes |
| 01b | [Detail teardown of video 01's showcase maps](01b-detail-teardown.md) | (our analysis) | How the warehouse/studio/lake reach that detail: rhythm, trim, overhead layer, hero accent |
