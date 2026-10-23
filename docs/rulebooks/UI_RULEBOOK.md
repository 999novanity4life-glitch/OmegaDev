# UI rulebook: how Claude builds Steal a Dream's UI
Backed by `research\GITHUB_UI_AND_ANIMATION_2026-10-13.md` (sources there). Style target: `DESIGN\UI_REFERENCE_NOTES.md`. Check every screen against `UI_CHECKLIST.md`.

## 0. Pick the style family first (added 2026-10-23)
Before building any screen, pick the family for the game's vibe from `research/BUILTBYBIT_UI_AND_ASSET_SURVEY_2026-10-23.md` section 1 (A Stud Cartoon for collect/steal/simulator, C Anime Neon, D Dark Glass for premium menus, E Tactical, F Light Minimal, G RPG, H Sci-fi, I Horror). One family per game; settings/pause menus may use D Dark Glass in any game. The family's measured recipe (colours, rims, strokes, stripes, splat backdrop, HUD layout) overrides the generic tokens in section 3.
- **Dark Glass 3D tilt panel is built and reusable:** `src/ui/Screen3D.luau` + `src/ui/Settings3D.client.luau`. Rules: SurfaceGui on a camera-locked part, `AlwaysOnTop = false`, blur via DepthOfField + dim plane (never BlurEffect), part `CanQuery` only while visible, tilt <= 3 degrees, smoothing `1 - exp(-dt*8)`.

## 1. Approach (decided)
- **Plain Instances + TweenService.** No Fusion, react-lua, Roact (archived) or Vide. One in-house ModuleScript, `ReplicatedStorage.UI.UIKit`, holds the helpers below.
- **Where the code lives:** UI scripts are LocalScripts/ModuleScripts written with `multi_edit` (datamodel Edit), so they're saved in the place. Static layout can be built once with `execute_luau` (Edit) into `StarterGui`. Anything dynamic (shop cards, odds tiles, toasts) is built at runtime by the LocalScript.
- **Test loop:** `start_stop_play` → `execute_luau` (Client) to open the screen → `screen_capture` → `get_console_output` → fix. Check a phone-sized and a PC-sized view.
- **Server is truth:** prices, odds, results and balances come from the server. The UI only displays and requests.

## 2. Layout rules
1. Size and position in **Scale**. Use `AnchorPoint = (0.5, 0.5)` for anything centred or tweened.
2. Every panel that must keep its shape gets a **UIAspectRatioConstraint**. It overrides layouts, so don't put one on a layout-controlled child unless you mean to.
3. Text: `TextScaled = true` **plus** `UITextSizeConstraint` (MinTextSize ≥ 9). Never TextScaled and AutomaticSize on the same label.
4. ScreenGuis: `ResetOnSpawn = false`, `ScreenInsets = CoreUISafeInsets` (default). Use `None` only for non-interactive full-screen art (fades, letterbox). Don't use SafeAreaCompatibility. Stack screens with `DisplayOrder` (HUD 1, shops 5, hatch 8, toasts 9, cutscene 10).
5. **Bottom-left and bottom-right are taken by mobile controls.** On touch (`UserInputService.TouchEnabled`), lift the currency block above the thumbstick zone and keep the right-side buttons above the jump button.
6. Layouts override sibling Position/Size. Use UIListLayout for stacks (Padding = gap between items, UIPadding = edges) and UIGridLayout for product grids.
7. **Scrolling grids:** AutomaticCanvasSize breaks with Scale cells. Use **offset CellSize recomputed from AbsoluteSize** (recipe 5d). No UIScale above a ScrollingFrame.
8. Buttons: logic on `Activated` (mouse and touch). Visual hover/press go on the button's own UIScale.

## 3. Style tokens (until STYLE_GUIDE.md is filled)
Font `Font.fromName("FredokaOne")` (titles may use `"LuckiestGuy"`). White text, black UIStroke 2-3 px. Colours: buy green, close/alert red, luck purple/pink, best gold, panels deep night-purple with a UIGradient. UICorner 0.15-0.25 Scale on panels, 0.5 for circles. **Never tween a text UIStroke's Thickness** (it causes flicker and perf cost). Tween Color/Transparency instead.

## 4. UIKit core
```lua
-- ReplicatedStorage.UI.UIKit
local TweenService = game:GetService("TweenService")
local UIKit = {}
UIKit.C = {Buy=Color3.fromRGB(60,200,90), Close=Color3.fromRGB(230,60,60),
  Luck=Color3.fromRGB(170,90,240), Gold=Color3.fromRGB(255,200,40), Panel=Color3.fromRGB(45,25,80)}

function UIKit.make(class, props, children)
  local o = Instance.new(class)
  local parent = props and props.Parent
  for k, v in props or {} do if k ~= "Parent" then o[k] = v end end
  for _, c in children or {} do c.Parent = o end
  o.Parent = parent
  return o
end

function UIKit.text(props) -- chunky outlined label
  local l = UIKit.make("TextLabel", {BackgroundTransparency=1, TextScaled=true,
    FontFace=Font.fromName("FredokaOne"), TextColor3=Color3.new(1,1,1)}, {
    UIKit.make("UIStroke", {Thickness=3, Color=Color3.new(0,0,0)}),
    UIKit.make("UITextSizeConstraint", {MinTextSize=9, MaxTextSize=60})})
  for k, v in props do l[k] = v end
  return l
end

function UIKit.tween(obj, t, goals, style, dir)
  local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad,
    dir or Enum.EasingDirection.Out), goals)
  tw.Completed:Once(function() tw:Destroy() end) -- avoid tween leaks
  tw:Play()
  return tw
end
return UIKit
```

## 5. Recipes
**a. Button pop (hover/press)**
```lua
function UIKit.pop(btn)
  local s = btn:FindFirstChildOfClass("UIScale") or UIKit.make("UIScale", {Parent=btn})
  local back = Enum.EasingStyle.Back
  btn.MouseEnter:Connect(function() UIKit.tween(s, .12, {Scale=1.08}, back) end)
  btn.MouseLeave:Connect(function() UIKit.tween(s, .12, {Scale=1}, back) end)
  btn.MouseButton1Down:Connect(function() UIKit.tween(s, .06, {Scale=.9}) end)
  btn.MouseButton1Up:Connect(function() UIKit.tween(s, .15, {Scale=1}, back) end)
end
```
(Whether MouseButton1Down/Up fire for touch is UNVERIFIED, so test on the device emulator. Game logic stays on `Activated`.)

**b. Red "!" badge**: a red circle (UICorner 0.5) with AnchorPoint (0.5,0.5) at Position (1,0) of the menu button, a "!" text label inside, and an endless pulse:
```lua
local s = UIKit.make("UIScale", {Parent=badge})
TweenService:Create(s, TweenInfo.new(.5, Enum.EasingStyle.Sine,
  Enum.EasingDirection.InOut, -1, true), {Scale=1.15}):Play() -- RepeatCount -1, reverses
```
Show it when the server sets a player attribute (e.g. `NewEgg = true`).

**c. Number suffixes + count-up**
```lua
local SUF = {"", "K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","Dc"}
function UIKit.short(n)
  if n < 1000 then return tostring(math.floor(n)) end
  local i = math.min(math.floor(math.log10(n) / 3), #SUF - 1)
  local v = n / 10 ^ (i * 3)
  local s = v < 100 and (string.format("%.1f", v):gsub("%.0$", "")) or tostring(math.floor(v))
  return s .. SUF[i + 1]
end
local running = {}
function UIKit.countTo(label, from, to)
  if running[label] then running[label]:Cancel() end
  local nv = Instance.new("NumberValue"); nv.Value = from
  nv.Changed:Connect(function(x) label.Text = UIKit.short(x) end)
  local tw = TweenService:Create(nv, TweenInfo.new(.6), {Value = to})
  running[label] = tw
  tw.Completed:Once(function() nv:Destroy(); running[label] = nil end)
  tw:Play()
end
```
Pop the currency icon's UIScale to 1.15 and back on every gain.

**d. Shop frame template + scrolling grid**: one builder, `UIKit.shopFrame(title, color)`, reused by Eggs, Multipliers and Speed-ups. It returns a centred panel (AspectRatio ~1.4) with a bright title bar, a title label, a big red X (Activated → close tween), and a ScrollingFrame with `AutomaticCanvasSize = Y`, `ElasticBehavior = Never`, and a UIGridLayout:
```lua
local function fitGrid(scroll, grid, cols, aspect)
  local function update()
    local w = scroll.AbsoluteSize.X - scroll.ScrollBarThickness
    local pad = grid.CellPadding.X.Offset
    local cw = math.floor((w - pad * (cols - 1)) / cols)
    grid.CellSize = UDim2.fromOffset(cw, math.floor(cw / aspect)) -- offset only!
  end
  scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(update); update()
end
```
Product card: icon (grows with value), amount in outlined text, green price button with `UIKit.pop`.

**e. Open/close panel**: put the panel in a **CanvasGroup**. Open = UIScale 0.8→1 (Back Out, 0.2 s) + GroupTransparency 1→0. Close = reverse, then `Visible=false`. Only one shop open at a time.

**f. Odds tiles**: built from the **same odds table the server rolls with** (`ReplicatedStorage.Config.Eggs`, read-only on the client). One tile per Dreamling: ViewportFrame or icon, name, `string.format("%g%%", pct)`. The best tile is larger and gold, with a slow UIGradient Rotation spin. Assert the odds sum to 100.

**g. Countdown timer**: the server sets an attribute `EndsAt` (Unix seconds). The client shows
```lua
local left = math.max(0, endsAt - workspace:GetServerTimeNow())
label.Text = string.format("%dm %02ds", left // 60, left % 60)
```
and updates once a second (`task.wait(1)` loop).

**h. Toasts**: a top-centre holder with UIListLayout. Each toast is a CanvasGroup that slides in (Position + GroupTransparency), waits 2.5 s, fades out and is destroyed. Keep at most 3.

**i. Floating "+123" (world)**
```lua
function UIKit.floatText(part, text, color)
  local bb = UIKit.make("BillboardGui", {Adornee=part, Size=UDim2.fromScale(4, 1.5),
    StudsOffset=Vector3.new(0, 2, 0), AlwaysOnTop=true, MaxDistance=80,
    Parent=game.Players.LocalPlayer.PlayerGui}) -- BillboardGui Size scale = studs
  local l = UIKit.text({Size=UDim2.fromScale(1, 1), Text=text, TextColor3=color, Parent=bb})
  UIKit.tween(bb, 1, {StudsOffset=Vector3.new(0, 5, 0)})
  UIKit.tween(l:FindFirstChildOfClass("UIStroke"), 1, {Transparency=1})
  UIKit.tween(l, 1, {TextTransparency=1}).Completed:Once(function() bb:Destroy() end)
end
```

**j. Spin wheel (egg open)**
1. The client asks the server to open an egg. The **server decides the result first** and returns the rarity (honest wheel: no fake near-misses).
2. The wheel is a circular Frame (UICorner 0.5) with a `UIGradient` of `Type = Enum.GradientType.Conical` and hard colour stops (two keypoints per slice, 0.001 apart). Six slices = 12 keypoints, above the ~6 stops the docs suggest for performance, which is fine for one wheel. Conical start angle and direction are UNVERIFIED, so calibrate with `screen_capture`.
3. Slices at the true odds would make Mythic (0.01%) invisible. **Proposal for Sharman:** a minimum visual slice width, with the true % printed on each slice. Needs his OK, since the design says slices match the odds.
4. Land: `target = 360*5 + (pointerAngle - sliceCentre(result))`. Tween the wheel's `Rotation` over 4 s with Quart Out. Play a tick sound whenever `math.floor(rotation / sliceDeg)` changes (RenderStepped).
5. Reveal (recipe k).

**k. Hatch reveal**: dim the screen (black Frame, 0.4 transparency). Shake the egg: tween its Rotation ±12° four times. Rarity flash: a full-screen Frame in the rarity colour, transparency 0→1 over 0.4 s. A ViewportFrame shows the Dreamling inside a **WorldModel** (needed to animate it), with a Camera orbiting via RenderStepped. Show the name and rarity in outlined text plus "NEW!" or "+Shards". Legendary and above add screen shake and a server-wide toast. Destroy the WorldModel and tweens afterwards.

## 6. Don'ts
- No Offset-sized HUD panels. No pure-Scale grid cells in auto-canvas scrolls.
- No UI framework installs and no unlicensed code. Vendoring `spr` (MIT, single file) is allowed only with its licence header kept.
- The client never decides money, odds or results.
- Don't leave tweens or WorldModels alive after an effect ends.
