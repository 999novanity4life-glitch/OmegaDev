# Animation + cutscene rulebook (Steal a Dream)
Backed by `research\GITHUB_UI_AND_ANIMATION_2026-10-13.md` (sources there). Pair with `UI_RULEBOOK.md` (UIKit helpers).

## 1. Ground rules
1. **Camera work is client-only** (LocalScript). The server stores flags and decides outcomes.
2. Cutscene: set `CameraType = Scriptable`, move the camera with TweenService or our Bezier sampler, update `camera.Focus` every frame, then **restore** `CameraSubject = Humanoid` and `CameraType = Custom`. `Camera:Interpolate` is deprecated, so never use it.
3. Every cutscene is **skippable**, has a **cleanup that always runs**, and hides the player's controls and CoreGui only while it plays.
4. **Dreamlings animate procedurally** (sine bob, squash-stretch tweens) until Sharman publishes real animations. Claude has no MCP tool to upload animation assets. `KeyframeSequenceProvider` IDs are "temporary and cannot be used outside of Studio".
5. **Animation ownership:** an animation only loads in experiences owned by the same owner as the animation, unless it's shared via Creator Hub > Permissions (since 2025-08-21). If the game moves to a group, re-publish the animations to the group.
6. **Animator replication:** create the Animator **on the server**. Client-played tracks replicate only on the player's own character. For a Dreamling, play on the server for everyone to see, or on the client for a local-only cosmetic.
7. Effects for one player go under **`workspace.CurrentCamera`** (ColorCorrection, Blur, Bloom, DepthOfField). Under **Lighting** they hit everyone.
8. Test loop: place camera-point Parts with `execute_luau` (Edit), preview each shot with `screen_capture` (it accepts a camera position + look-at), then playtest and read `get_console_output`.

## 2. Core snippets
**Skippable tween wait + Bezier flight**
```lua
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local cam = workspace.CurrentCamera
local skipped = false

local function play(tw)               -- returns early on skip
  tw:Play()
  while tw.PlaybackState == Enum.PlaybackState.Playing and not skipped do task.wait() end
  if skipped then tw:Cancel() end
end

local function bez(p0, p1, p2, p3, t) -- cubic Bezier (Vector3)
  local u = 1 - t
  return u*u*u*p0 + 3*u*u*t*p1 + 3*u*t*t*p2 + t*t*t*p3
end

local function fly(pts, lookAt, dur)  -- pts = 4 Vector3s
  local t0 = os.clock()
  repeat
    local a = math.min((os.clock() - t0) / dur, 1)
    local e = TweenService:GetValue(a, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    cam.CFrame = CFrame.lookAt(bez(pts[1], pts[2], pts[3], pts[4], e), lookAt)
    cam.Focus = CFrame.new(lookAt)
    RunService.RenderStepped:Wait()
  until a >= 1 or skipped
end
```
For straight moves, tween `cam.CFrame` (and `FieldOfView` for push-ins) with Sine/Quad InOut. FOV range is 1-120, default 70.

**Procedural idle (all Dreamlings, one client loop)**
```lua
local bobbers = {} -- [model] = {cf = base pivot, ph = random phase}
RunService.RenderStepped:Connect(function()
  local t = os.clock()
  for m, b in bobbers do
    m:PivotTo(b.cf * CFrame.new(0, math.sin(t*2 + b.ph) * 0.25, 0)
      * CFrame.Angles(0, math.sin(t*0.7 + b.ph) * 0.15, 0))
  end
end)
```
Register a model when it's placed on a shelf and unregister it when it's stolen or sold (watch an attribute). It's client-local, so the server's copy stays still and nothing extra replicates. Breathing: tween the body MeshPart's `Size` Y up by 5% with `RepeatCount = -1, reverses = true`.

**Squash-and-stretch pop (single-MeshPart creature)**
```lua
local function popIn(body)            -- body = MeshPart, Size scales the mesh
  local s = body.Size
  local function sz(x, y) return Vector3.new(s.X*x, s.Y*y, s.Z*x) end
  body.Size = s * 0.05
  play(TweenService:Create(body, TweenInfo.new(.18), {Size = sz(.7, 1.4)}))   -- stretch
  play(TweenService:Create(body, TweenInfo.new(.12), {Size = sz(1.3, .7)}))   -- squash
  play(TweenService:Create(body, TweenInfo.new(.25, Enum.EasingStyle.Back), {Size = s}))
end
```
Size grows from the centre, so also tween the CFrame up by half the height change if the feet must stay on the shelf. For multi-part models, use `Model:ScaleTo()` for uniform scale (UNVERIFIED in combination with tweens: drive it from a NumberValue's Changed event).

**Effects**
- Burst: `attachment.Sparkles:Emit(30)`. Emitters live on Attachments with `Enabled = false`. `LightEmission = 1` for glow. Keep Rate × Lifetime small.
- Glow outline: a `Highlight` (client max 255; destroy unused ones, don't just disable them).
- Shake: random CFrame offsets for 0.3 s, or vendor `RbxCameraShaker` (MIT).
- Dreamy grade (per player): `ColorCorrectionEffect` in the Camera. Tween `TintColor` toward lavender and `Saturation` to -0.2, plus a light `BloomEffect`. Dream-ghost mode reuses this, stronger.
- Sound: `SoundService:PlayLocalSound(sound)` for UI and cutscene stingers. Only use audio the experience is allowed to use (UNVERIFIED: check each asset's permissions).

**Character animations (later, when Sharman publishes some)**
```lua
local animator = humanoidOrController:FindFirstChildOfClass("Animator") -- created on server
local track = animator:LoadAnimation(animObject) -- Animation with AnimationId
track.Priority = Enum.AnimationPriority.Action
track:Play(0.1) -- fade in
track:GetMarkerReachedSignal("Snore"):Connect(playSnore) -- SFX on markers
```
Creatures from Blender: rig, then skin. Max 4 bone influences per vertex, frozen bones, root at the origin with no weights. Export FBX (Path Mode Copy, Embed Textures, FBX Unit Scale). Studio creates `Bone`s and an AnimationController drives them. A single rigged mesh (R1-style) suits simple Dreamlings.

## 3. First-join cutscene: "Into the Dream" (~11 s)
**Shot list**
| # | Time | Camera | Action |
|---|---|---|---|
| 0 | 0.0-1.0 | holds on shot 1 start | Screen black; letterbox bars slide in; soft chime |
| 1 | 1.0-3.5 | Bezier glide **through the dream clouds** above the map, FOV 80 → 70 | Fade from black (0.8 s); cloud particles, stars, dreamy grade on |
| 2 | 3.5-5.0 | Bezier dive down to **the player's own bedroom window** | Clouds part; room lights glow |
| 3 | 5.0-6.5 | Tween **push-in on the bed**, FOV 70 → 55 | Zs float from the pillow |
| 4 | 6.5-8.0 | Quick pan to **the shelf** | **Snorelet pops** in: squash-stretch + sparkle burst + tiny snore |
| 5 | 8.0-10.0 | Slow drift | **"Steal a Dream"** title: UIScale 0 → 1 Back Out, purple-pink UIGradient, outlined FredokaOne/LuckiestGuy |
| 6 | 10.0-11.5 | Tween to a CFrame behind the player's head | Title and letterbox out, grade off, controls back |

**Camera points:** global cloud points in `workspace.Cutscenes.Intro` (anchored, invisible, non-colliding Parts named `C1..C8`). Bedroom shots use a `CamPoints` folder **inside the room template**, so every room has its own and the cutscene targets the player's assigned room (`RoomId` attribute set by the server).

**Implementation outline**
1. **Server** (`ServerScriptService.IntroFlag`, Script):
```lua
local flags = game:GetService("DataStoreService"):GetDataStore("PlayerFlags_v1")
local done = Instance.new("RemoteEvent"); done.Name = "IntroDone"
done.Parent = game.ReplicatedStorage
game.Players.PlayerAdded:Connect(function(p)
  local ok, data = pcall(flags.GetAsync, flags, "u" .. p.UserId)
  p:SetAttribute("IntroSeen", ok and data ~= nil and data.introSeen == true)
end)
done.OnServerEvent:Connect(function(p)
  if p:GetAttribute("IntroSeen") then return end
  p:SetAttribute("IntroSeen", true)
  pcall(flags.UpdateAsync, flags, "u" .. p.UserId, function(old)
    old = old or {}; old.introSeen = true; return old end)
end)
```
   Testing in Studio needs *Experience Settings > Security > Enable Studio Access to API Services* (test place only). Later, fold the flag into the main player save.
2. **Client** (`StarterPlayerScripts.IntroCutscene`, LocalScript): wait for the `IntroSeen` attribute and return if it's true. Wait for the character, the `RoomId` attribute and the room. Run `ContentProvider:PreloadAsync` on the cutscene's sounds and decals only.
3. **Lock**: `cam.CameraType = Scriptable`, `StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)`, `humanoid.AutoRotate = false`, and disable movement with `require(player.PlayerScripts.PlayerModule):GetControls():Disable()` (common community pattern, UNVERIFIED in official docs; fallback: WalkSpeed 0 and JumpPower 0, saving the old values).
4. **UI**: ScreenGui `IntroUI` (DisplayOrder 10, `ScreenInsets = None`, IgnoreGuiInset true) holds the black fade Frame, two letterbox bars (tween height 0 → 0.12 scale) and the title. The **Skip** button goes in a second ScreenGui with default `CoreUISafeInsets`, so it's never under a notch. It appears after 1 s and sets `skipped = true`.
5. **Run shots 0-6** with `play()` / `fly()`. Each shot checks `skipped`.
6. **Cleanup (always runs, wrap the shots in `pcall`)**: cancel tweens, destroy IntroUI and the camera effects, re-enable the CoreGui and controls, AutoRotate on, `cam.CameraSubject = humanoid`, `cam.CameraType = Custom`. If it was skipped, cut straight to the player. Then `IntroDone:FireServer()`.
7. **Acceptance:** a first join plays it once; a rejoin doesn't; Skip at any moment returns full control with no errors; no leftover bars or blur; phone-sized `screen_capture` shows Skip clear of the notch and top bar.

## 4. Don'ts
- Don't leave the camera Scriptable after an error. Cleanup goes in a guaranteed path.
- Don't save "seen" on the client, and don't trust the client to grant anything.
- Don't use free-model animations or audio we don't own.
- Don't tween text UIStroke Thickness. Don't preload the whole Workspace.
