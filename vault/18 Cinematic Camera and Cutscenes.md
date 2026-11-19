# 18 Cinematic Camera and Cutscenes

Camera work that makes a Roblox game look like its trailer: ability cams for
ultimates and transformations, story cutscenes, boss intros, and the shots
the trailer is filmed with. Code: `template/src/shared/CameraRig.luau` (shot
math, tested), `template/src/client/Controllers/CinematicCamera.luau` (player),
numbers in `Config.Cinematic`. The older step-by-step cutscene recipe is
`docs/rulebooks/ANIMATION_CUTSCENE_RULEBOOK.md`.

## 1. Three ways to drive the camera
| Method | Use for | How | Source |
|---|---|---|---|
| **Shot list** relative to a subject | ability cams, boss intros, trailer shots | `CinematicCamera.play(shots, rootPart)`; shots are `{right, up, back}` offsets in the subject's frame, so they work anywhere in the map | our module; relative-to-root pattern from [FORUM 1181691] |
| **Camera part in the animation** | ultimates where camera and body must be frame-locked | Motor6D a `CameraBone` part to the rig, keyframe it with the body (Moon Animator or Blender), play the animation, `CinematicCamera.followPart(bone, length)` | [FORUM 3686403, 3836175] |
| **Baked frames** | cutscenes authored in Moon Animator 2 | Export one CFrame per frame (60 fps default), play with `CinematicCamera.playFrames(frames, 60, root)` so camera = root * frame | [FORUM 1181691] |

Battleground-style in-game cutscenes: anchor the HumanoidRootPart at the start
position, play the animation, and drive the camera from the same animation
[FORUM 3836175]. Blender gives better animation than Studio's editor (IK)
[FORUM 3836175]; the Blender MCP is on the Mac.

Moon Animator 2 playback modules exist (Moon2Cutscene, "Moon Animator 2 to In
Game Animations"); they say "free" but name no license, so we don't vendor
them. Use their file format knowledge, our player [RULE].

## 2. Shot grammar (built-ins in `CameraRig.Shots`)
| Shot | When | Feel |
|---|---|---|
| `pushIn` | charge-up, "something is about to happen" | slow, SineInOut, FOV 60 → 45 |
| `heroOrbit` | transformation, reveal, boss entrance | low angle, 120° sweep, CubicInOut |
| `overShoulder` | wind-up of a beam or throw toward a target | QuadOut settle |
| `whipToFront` | the hit lands | 0.2-0.35 s, ExpoOut, FOV punch to 40, light shake |
| `craneOut` | aftermath, crater, knocked-back crowd | rise and pull back |
| `lockedWide` | trailers: let the action play in a still frame | static |

Typical ultimate (2.4 s): pushIn 0.8 → heroOrbit 0.9 (aura ignites) →
whipToFront 0.25 (impact frames + hit-stop from vault/17) → craneOut 0.45.
Cut on the hit marker, not between them [RULE].

Rules [RULE unless cited]:
- No camera roll in gameplay; it causes motion sickness [VIDEO 15 @24:36].
  Small roll is fine in trailer-only shots.
- FOV stays in 1-120 [DOC Camera]; CameraRig.validate rejects the rest.
- In-combat cams max `Config.Cinematic.AbilityCamMaxSeconds` (3 s), not
  skippable (skipping breaks sync). Story cutscenes are always skippable.
- Every cutscene has a guaranteed cleanup: CameraType back to Custom, subject
  back to the Humanoid, FOV restored. `CinematicCamera` does it even when a
  shot errors.
- Letterbox bars 11% each, Skip in a separate `CoreUISafeInsets` ScreenGui
  after 1 s (CLAUDE.md rule 5).
- Reduced Motion: hard cuts to each shot's end pose, no shake.
- Effects for one player go under `workspace.CurrentCamera`
  (ANIMATION_CUTSCENE_RULEBOOK rule 7).
- Sync with the server using `workspace:GetServerTimeNow()` when everyone must
  see the cutscene at the same moment [FORUM 3686403].

## 3. Animations in cutscenes must match the style
- One animation per style beat (charge, release, recover), authored with
  markers for VFX ("Charge", "Release", "Hit") [DOC Animation events].
- The camera rhythm follows the style: fast styles = more, shorter shots and
  whips; heavy styles = fewer, longer shots and crane moves [RULE].
- Animations are restricted assets: they load only in experiences the owner
  allows, so publish them under the game's owner (SKILLS_VFX_RULEBOOK
  section 2).

## 4. Proving it
1. `CameraRig.validate` passes for every shot list (spec it in tests).
2. Preview each shot in Edit with `screen_capture` (camera_position +
   look_at_position), then playtest and read `get_console_output`.
3. Frame strip of the ultimate (start, hit, aftermath) to a fresh
   `visual-reviewer` (docs/VISUAL_QA.md).
