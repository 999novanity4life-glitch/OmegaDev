# 19 Trailers, Store Videos and Ads

How OmegaDev films and edits game videos with no manual steps: Studio plays
scripted takes on the Mac, the Mac records the screen, and Remotion renders the
edit from a JSON edit list. Code: `template/src/client/Controllers/TrailerMode.luau`,
`trailer/` (Remotion project, see its README).

## 1. Two different videos (don't mix them up)
| | Store video (Roblox detail page / Home) | Social trailer / ad (YouTube, TikTok, Shorts) |
|---|---|---|
| Rules | Roblox's authenticity rules [DOC thumbnails] | platform rules + our taste |
| Content | real gameplay; varied camera angles, curated highlight sequences, minor grading and the game's logo are OK | real gameplay first, then cinematic shots, titles, end card |
| Not allowed | mechanics or UI not in the game, graphics better than players get, real-life footage, voice-over, narration, voice chat, **music with lyrics**, ad text or claims ("50% off", "Free UGC!") | IP we don't own (truth rule 5) |
| Music | Roblox audio catalog only | music we have rights to |
| Limits | 3 uploads per month; rejected videos count; not shown on Xbox/PlayStation/VR [DOC thumbnails] | per platform |
| Edit profile | `"profile": "store"` | `"profile": "social"` |

Doc: https://create.roblox.com/docs/production/publishing/thumbnails (videos,
"Video accuracy"). The Video Discovery pilot asked for 6-60 s, .mp4/.mov, max
30 MB, max 4096x2160, landscape, 13+ ID-verified uploader, and said "Avoid
cinematic trailers. We want real gameplay!" [FORUM 3605294, April 2025];
check the Creator Dashboard for the current numbers before uploading.
In-game `VideoFrame` assets are a separate thing (5 min, 2,000 Robux each
[DOC video-frames]); we don't need them for trailers.

Ads: Sponsored Experiences show 16:9 thumbnails on Home, up to 10 per
campaign [DOC ads-manager]; Roblox said the 16:9 unit raised play-through
"by up to 40%" [FORUM 3587640]. Ad creatives are stills, so the trailer
pipeline also exports key frames for them (section 4). Spending Robux on ads
needs the human (truth rule 4).

## 2. Editing rules (from professional trailer editors)
- **Gameplay in the first seconds.** Attention can wane after "as little as
  five seconds"; no logo or slow establishing shot first [PC Gamer, Lieu 2019].
  Gameplay within ~10 s at the latest; viewers scrub ahead at 30 s
  [Game Developer, Cauller 2016].
- **Genre → hook → features.** Say what kind of game it is, show the one thing
  that's special, then expand [Lieu, "Three ways to think of game trailers"].
  Order the verbs simple to complex and save the most interesting for last
  [PC Gamer, Lieu 2018].
- **Audio first.** Pick the music, then cut to it [PC Gamer, Lieu 2018].
  Our edit lists count in beats, so cuts land on the music by default. Not
  every cut has to be on the beat [Lieu 2023]. Sound design matters more than
  anything else; music alone sounds "dry" [Cauller 2016].
- **Pace to the game.** Average shot length varies (Lieu cites ~4.25 s for a
  puzzle game, 1.3 s for a shooter); cut fast because the game is fast, not
  for its own sake [Lieu 2023]. Combat trailers: 0.5-2 s shots, slower on
  ultimates [RULE].
- **Highs need lows**: "lows don't look low unless there's a high" [Lieu 2018].
  Build to the ultimate, breathe, then the biggest moment.
- **Show, don't tell.** No "epic, amazing" cards; a title says something about
  the game, then the next shot proves it [Lieu 2022; Cauller 2016].
  Max 6 words per card [RULE]; the linter warns.
- **Logo at the end**, biggest, then the call to action [Cauller 2016].
- **Hide the HUD** in hero shots; let the action tell it [Cauller 2016].
  Store videos may keep real in-game UI [DOC thumbnails].
- **Capture ~10x what you use** [Cauller 2016]; Lieu captured five hours for
  under two minutes [PC Gamer 2018].
- Don't copy AAA editing; it hides the gameplay [Lieu 2023].

## 3. Capture (all automated on the Mac)
1. Build the shot list in the game (`CameraRig.Shots` + custom shots) and the
   moments to show (combo string, ultimate, boss, transformation).
2. Playtest in Studio (Studio MCP `start_stop_play`), set graphics high, and
   run `TrailerMode.take(name, shots, subject)` per take via `execute_luau`
   on the Client. It hides UI, CoreGui and name plates, shows a 0.5 s black
   slate, plays the shots, and prints `OMEGA_TAKE` timings.
3. Record the display with `trailer/scripts/capture-mac.sh <seconds> <file>`
   in a Remote Control session (ffmpeg avfoundation 60 fps, or macOS
   `screencapture -v`). Freecam (Shift+P, solo playtest) is the manual
   alternative; it can hide ScreenGuis, nameplates and CoreGui and add DOF,
   bloom and grading [DOC free-camera].
4. `node trailer/scripts/split-takes.mjs <recording> <console.txt>` finds the
   slates (ffmpeg blackdetect) and writes `public/takes/<name>.mp4`.

CaptureService is for players' in-game captures (30 s max, prompts the user)
[DOC CaptureService], not for our footage.

## 4. Edit and render
- Write `trailer/edits/<game>-<cut>.json` (format in `trailer/src/edl.ts`):
  clips with in-points, beats, speed, zoom punch-ins, transitions
  (cut / flash / impact / whip / fade), titles, logo.
- `npm run render:edit -- edits/<file>.json` lints the edit (store rules
  above are errors) and renders H.264. Vertical (1080x1920) for Shorts and
  TikTok uses the same takes, center-cropped; frame the hero shots with room
  on the sides [RULE].
- Thumbnails and ad stills: `npx remotion still Trailer out/thumb.png
  --frame=<n> --props=...` on the hit frame of the best moment, then the
  thumbnail rules in vault/11.
- Review: frames from every shot go to a fresh `visual-reviewer`
  (docs/VISUAL_QA.md). The human approves before anything is uploaded.

## 5. Tools and licenses
- Remotion: free for individuals and for-profit companies with up to 3
  employees; a company license above that
  (https://github.com/remotion-dev/remotion/blob/main/LICENSE.md). Re-check if
  the studio grows.
- Anton font: SIL OFL 1.1, bundled in `trailer/public/fonts`.
- ffmpeg: free. Moon Animator 2 and Blender: see vault/18.
