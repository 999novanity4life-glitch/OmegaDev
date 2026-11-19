# Showcase visuals research: combat VFX, cutscene cameras, trailers (2026-11-19)

Asked by Sharman: get really good at GUI, VFX, cinematic camera moves and
cutscenes whose animations match fighting styles, and at Roblox trailers and
ads. Findings live in vault/17, 18, 19; this file lists what was read.

Legend: READ = page fetched and read; FAILED = could not be fetched (listed
so nobody cites it as read).

## Official Roblox docs (READ, via github.com/Roblox/creator-docs, 2026-11-19)
- Thumbnails and videos (store video rules, 3 uploads/month, freecam):
  https://create.roblox.com/docs/production/publishing/thumbnails
- Free camera mode (Shift+P, hide GUIs, player lock, DOF/bloom/grading):
  https://create.roblox.com/docs/workspace/camera/free-camera
- Particle emitters (rate caps, flipbooks, Squash, ZOffset, LightEmission):
  https://create.roblox.com/docs/effects/particle-emitters
- ParticleEmitter (Emit, TimeScale), AnimationTrack (AdjustSpeed,
  GetMarkerReachedSignal), CaptureService (30 s player captures), Camera:
  https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter
  https://create.roblox.com/docs/reference/engine/classes/AnimationTrack
  https://create.roblox.com/docs/reference/engine/classes/CaptureService
- Animation events: https://create.roblox.com/docs/animation/events
- Video frames (VideoFrame uploads, 2,000 Robux each):
  https://create.roblox.com/docs/ui/video-frames
- Ads Manager (16:9 thumbnails, up to 10 per campaign):
  https://create.roblox.com/docs/production/promotion/ads-manager
- Beams, trails: https://create.roblox.com/docs/effects/beams ,
  https://create.roblox.com/docs/effects/trails

## DevForum (community advice, READ)
- Battleground cutscenes: camera part on a Motor6D animated with the body;
  anchor root then play: https://devforum.roblox.com/t/3686403 ,
  https://devforum.roblox.com/t/3836175
- Moon Animator camera export, per-frame playback relative to the root:
  https://devforum.roblox.com/t/1181691
- Trailer filming (Shift+P dev camera, scripted tween cams, OBS frame drops on
  low-spec PCs): https://devforum.roblox.com/t/2775430 ,
  https://devforum.roblox.com/t/3878406 , https://devforum.roblox.com/t/2572053
- Anime/fighting VFX scripting (server validates, clients spawn VFX):
  https://devforum.roblox.com/t/1610853
- Drawn impact frames (no official method): https://devforum.roblox.com/t/2591414
- Blender mesh VFX: https://devforum.roblox.com/t/872437
- Video Discovery pilot (6-60 s, mp4/mov, 30 MB, real gameplay, April 2025):
  https://devforum.roblox.com/t/3605294
- Ads Manager 16:9 unit, "up to 40%" play-through (March 2025):
  https://devforum.roblox.com/t/3587640
- Moon Animator 2 playback modules (no named licenses):
  https://devforum.roblox.com/t/3001411 , https://devforum.roblox.com/t/3178584 ,
  https://devforum.roblox.com/t/2975574

FAILED (redirected to create.roblox.com/maintenance or empty on 2026-11-19;
re-read before relying on them): "YouTube Videos Will Be Removed from Game
Detail Pages" (t/4879633), "Gameplay Videos on Home" (t/4842601), "Ads for
Creators: RDC recap" (t/3929106), "Ads Manager RDC recap" (t/4909790),
"Moon Animator camera relative to player" (t/4218860), "How to design a game
trailer" (t/292543), custom flipbook layouts beta (t/4005128).

## Trailer craft (READ)
- Derek Lieu interview, PC Gamer 2018: https://www.pcgamer.com/the-art-of-making-effective-game-trailers
- PC Gamer 2019 (first trailer): https://www.pcgamer.com/the-art-of-creating-the-perfect-first-game-trailer
- Derek Lieu, "Three ways to think of game trailers" (2022):
  https://derek-lieu-yrd2.squarespace.com/blog/2022/9/26/three-ways-to-think-of-game-trailers
- Derek Lieu, "More trailer editing is not better trailer editing" (2023):
  https://derek-lieu-yrd2.squarespace.com/blog/2023/4/23/more-trailer-editing-is-not-better-trailer-editing
- M. Joshua Cauller, "Salvage your game trailer", Game Developer 2016:
  https://gamedeveloper.com/business/salvage-your-game-trailer
- WN Hub summary of Lieu's talk (2022): https://wnhub.io/news/analytics/item-237

## Tools
- Remotion license (READ): https://github.com/remotion-dev/remotion/blob/main/LICENSE.md
- Anton font, SIL OFL 1.1: https://github.com/google/fonts/tree/main/ofl/anton

## Not done yet
- YouTube teardown of top battleground trailers and VFX artists (captions need
  a Remote Control session on the Mac; YouTube is blocked from the cloud).
- The 4 FAILED DevForum posts about store videos and ads.
