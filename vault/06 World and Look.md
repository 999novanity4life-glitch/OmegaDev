# 06 World and Look

Studio rules:
- One art direction per game: palette (5–6 colors), material set, lighting preset. Write it in SPEC.md and keep to it.
- Each zone: one silhouette landmark visible from spawn, a readable path, a distinct color mood.
- The spawn shot is the trailer's first frame. Make it beautiful before anything else.
- StreamingEnabled is on: keep detail where players are; no huge unanchored part piles ([streaming](https://create.roblox.com/docs/en-us/workspace/streaming)).
- Profile with MicroProfiler on a phone-class device; stay under 33 ms/frame, aim for 16.7 ms ([MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler)).

## Go deeper (added 2026-10-28)
- Lighting, atmosphere, presets and PBR materials: chapter 15. Map layout, landmarks, negative space and procedural terrain: chapter 16.
- Build order: overhead map and color script → greybox → art pass from a small kit → lighting pass (a `LightingPresets` entry per zone) → `docs/VISUAL_QA.md`. Nothing reaches the human before the blind review passes.
- Write the art direction as a style bible (template: `docs/imported/claude-roblox-gamedev-kit/Style Bible template.md`).
