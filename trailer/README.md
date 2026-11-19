# OmegaDev trailer editor

Turns Studio footage into trailers, Roblox store videos and ad stills. A whole
video is a JSON **edit list** in `edits/`; Remotion renders it. Rules and
editing craft: `vault/19 Trailers, Store Videos and Ads.md`.

```
npm ci
npm test                                      # edit-list + take-splitting tests
npm run demo:media                            # stand-in footage + click track (needs ffmpeg)
npm run render:edit -- edits/demo-social.json # lint, then render out/demo-social.mp4
npm run dev                                   # Remotion Studio preview
```
In a container without Chrome downloads, point at an installed browser:
`REMOTION_BROWSER=/path/to/chrome-headless-shell npm run render:edit -- ...`

## Pipeline
1. **Film** (Studio on the Mac): playtest, then per take run
   `TrailerMode.take(name, shots, subject)` (template client controller) via
   Studio MCP `execute_luau` on the Client. Each take opens with a 0.5 s black
   slate and prints `OMEGA_TAKE` lines.
2. **Record**: `scripts/capture-mac.sh <seconds> <file.mov>` (Remote Control
   session on the Mac; needs Screen Recording permission once).
3. **Split**: `node scripts/split-takes.mjs <file.mov> <console.txt>` →
   `public/takes/<name>.mp4` (ffmpeg blackdetect finds the slates).
4. **Edit**: copy an `edits/demo-*.json`, point clips at `takes/<name>.mp4`.
5. **Render**: `npm run render:edit -- edits/<file>.json`. Store edits that
   break Roblox's video rules fail the lint before rendering.
6. **Stills** for thumbnails/ads: `npx remotion still Trailer out/thumb.png --frame=<n> --props=out/.props-<file>.json`.

## Edit list (see `src/edl.ts`)
| Field | Meaning |
|---|---|
| `profile` | `store` (Roblox detail page: real gameplay, catalog music, no claims) or `social` |
| `format` | `landscape` 1920x1080 or `vertical` 1080x1920 |
| `music` | `src`, `bpm`, `offset` (s before the first downbeat), `source`, `hasLyrics` |
| `events[]` | `clip` (`src`, `in`, `beats`/`seconds`, `speed`, `zoom`, `shake`, `transition`), `title` (`text`, `sub`), `logo` (`name`, `tagline`) |
| `transition` | `cut`, `flash` (white pop), `impact` (2 inverted anime impact frames), `whip` (streak + blur), `fade` |

Timing counts in beats, so cuts land on the music; positions are computed from
the running beat count, so they never drift.

`public/takes`, `public/music` and `public/demo` are local working files (git-ignored).

## Licenses
Remotion: free for individuals and companies with up to 3 employees
(https://github.com/remotion-dev/remotion/blob/main/LICENSE.md). Anton font:
SIL OFL 1.1 (`public/fonts/OFL-Anton.txt`).
