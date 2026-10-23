# Icon pipeline: pop-out icons for Steal a Dream
Sources/licences: `research\UI_ICON_QUALITY_RESEARCH_2026-10-13.md`. Style "Dream Candy" (research §6). No emoji or flat clip-art in shipped UI.

## 0. Rules
- The outline is **baked into the PNG**. A UIStroke on an ImageLabel only strokes the rectangle.
- Every icon: **512×512 PNG RGBA**, transparent, alpha-bled, object centred, 6-8% padding.
- Files: masters in `game\assets\icons\src\` (1024), finals in `game\assets\icons\out\` (512), the .blend in `game\assets\icons\icons.blend`. Log every icon in `assets\SOURCES.md`.
- Uploading creates assets on **Sharman's account**, so ask him before each batch.

## 1. Model (Blender 5.2 via BlenderMCP)
1. Sharman opens Blender, N panel > BlenderMCP > Connect, and saves the .blend.
2. One collection per icon (`ICON_dust`, `ICON_luck`...), object at the origin, about 2 m across.
3. Shapes are puffy: bevel every hard edge (Bevel modifier, width ≈ 4% of size, 3 segments), Shade Smooth, nothing thinner than 6% of the icon. Add one small 4-point sparkle.
4. Materials, "candy": Principled BSDF Roughness 0.3, **Coat Weight 0.7, Coat Roughness 0.05**, base colours from research §6. Glowing parts get Emission 0.5-2 in their own colour.
5. Optional inner lines (egg spots, book edge) use an inverted hull: Solidify, thickness 2-3% of size, **Flip Normals**, Material Offset 1. The second material is Emission plum (22,10,43) with Backface Culling > Camera on.

## 2. Scene and render
```python
import bpy
s = bpy.context.scene
for e in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):   # id differs across versions
    try: s.render.engine = e; break
    except TypeError: pass
s.render.film_transparent = True
s.render.resolution_x = s.render.resolution_y = 1024
s.render.image_settings.file_format, s.render.image_settings.color_mode = 'PNG', 'RGBA'
s.view_settings.view_transform, s.view_settings.look = 'Standard', 'None'  # AgX dulls colour
s.eevee.taa_render_samples = 64
```
- Camera: orthographic, elevation 20°, yaw 25°. Hero items roll 8°. Frame the object to fill about 80%.
- Lights (all Area, 2 m):
  - Key: upper-left front (-2.5,-3,4), 1000 W, warm white.
  - Rim: back-right, 550 W, pink (1,.55,.85).
  - Fill: front-right, 200 W, blue (.6,.7,1).
- World: colour (.05,.03,.10), strength 0.4. No ground plane, and no shadows on the object if they muddy it.
- Render each icon collection alone to `src\<name>.png`.
- Check `get_viewport_screenshot`, then Read the rendered PNG and compare with `ui_ref_01`/`03`. Re-render until it pops.

## 3. Post-process (outline, alpha bleed, downscale)
`python -I icon_post.py src out` (Pillow, numpy, scipy installed; tested 2026-10-13).
```python
import sys, pathlib, numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage
OUT, LINE, PLUM = 512, 14, (22, 10, 43)
def process(src, dst):
    im = Image.open(src).convert("RGBA").resize((OUT, OUT), Image.LANCZOS)
    solid = np.asarray(im)[..., 3] > 127
    yy, xx = np.ogrid[-LINE:LINE + 1, -LINE:LINE + 1]
    ring = ndimage.binary_dilation(solid, structure=xx * xx + yy * yy <= LINE * LINE)
    ol = Image.new("RGBA", (OUT, OUT), PLUM + (0,))
    ol.putalpha(Image.fromarray((ring * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8)))
    arr = np.asarray(Image.alpha_composite(ol, im)).copy()
    hole = arr[..., 3] == 0                      # alpha bleed: kills white halos in Roblox
    if hole.any() and (~hole).any():
        _, (iy, ix) = ndimage.distance_transform_edt(hole, return_indices=True)
        arr[..., :3] = arr[iy, ix][..., :3]
    Image.fromarray(arr).save(dst, optimize=True)
    # white silhouette for the shine sweep (ImageColor3 can only darken, never whiten)
    m = np.zeros((OUT, OUT, 4), np.uint8); m[..., :3] = 255
    m[..., 3] = ndimage.binary_erosion(solid, iterations=2) * 255
    Image.fromarray(m).save(dst.with_name(dst.stem + "_shine.png"), optimize=True)
for p in pathlib.Path(sys.argv[1]).glob("*.png"):
    process(p, pathlib.Path(sys.argv[2]) / p.name)
```
Optional glow for rare/premium icons: blur a copy of the ring 18 px, key colour at 50%, underneath.

**Placeholder route:** take the Fluent Emoji 3D PNG (MIT, 256 px; get Sharman's OK to download) and run the same script with `OUT = 256` and `LINE = 7`. Replace it with a Blender render later.

## 4. Upload
1. Test once: `python -m http.server 8765 --bind 127.0.0.1 --directory out` in the background. Then call Studio MCP `upload_image` with `http://127.0.0.1:8765/<name>.png`. If localhost fails, try `store_image(path)` and pass its URI to `upload_image`. Both are UNVERIFIED, so record the result in `ROBLOX_STUDIO_NOTES.md`.
2. **Fallback:** Sharman uses Studio > Asset Manager > Import and selects all PNGs in `out\`.
3. Wait for moderation (usually minutes to a few hours). Unapproved images are blank in-game.
4. Put the IDs in `ReplicatedStorage.Config.Icons` (`Dust = {image = "rbxassetid://123", shine = "rbxassetid://124"}`; each icon is 2 uploads). Never hard-code IDs elsewhere. A re-render means a new ID, so change one line.

## 5. Placement recipe (add to UIKit)
```lua
local PLUM = Color3.fromRGB(22, 10, 43)
local function corner(r) return UIKit.make("UICorner", {CornerRadius = UDim.new(r, 0)}) end

function UIKit.iconButton(parent, o) -- o = {image, shine, label, top, bottom, order}
  local holder = UIKit.make("Frame", {Parent = parent, BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1), LayoutOrder = o.order or 0},
    {UIKit.make("UIAspectRatioConstraint", {AspectRatio = 1})})
  local tile = UIKit.make("ImageButton", {Parent = holder, AutoButtonColor = false, ZIndex = 1,
    AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
    Size = UDim2.fromScale(.9, .9), BackgroundColor3 = Color3.new(1, 1, 1)}, {
    corner(.22),
    UIKit.make("UIStroke", {Thickness = 3, Color = PLUM, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}),
    UIKit.make("UIGradient", {Rotation = 90, Color = ColorSequence.new(o.top, o.bottom)}),
    UIKit.make("Frame", {Name = "Gloss", BackgroundColor3 = Color3.new(1, 1, 1),
      BackgroundTransparency = .8, Position = UDim2.fromScale(.06, .05),
      Size = UDim2.fromScale(.88, .4), ZIndex = 2}, {corner(.3)})})
  -- drop shadow: UIShadow if this build has it, otherwise a plum frame behind
  local ok = pcall(UIKit.make, "UIShadow", {Parent = tile, Color = PLUM, Transparency = .45,
    Offset = UDim2.fromScale(0, .07), BlurRadius = UDim.new(.06, 0)})
  if not ok then
    UIKit.make("Frame", {Parent = holder, ZIndex = 0, AnchorPoint = Vector2.new(.5, .5),
      Position = UDim2.fromScale(.5, .57), Size = tile.Size, BackgroundColor3 = PLUM,
      BackgroundTransparency = .45}, {corner(.22)})
  end
  local root = UIKit.make("Frame", {Parent = tile, Name = "IconRoot", BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .38),
    Size = UDim2.fromScale(1.05, 1.05), ZIndex = 3})
  local function img(props)
    props.Parent, props.BackgroundTransparency = root, 1
    props.Image = props.Image or o.image
    props.AnchorPoint, props.Size = Vector2.new(.5, .5), UDim2.fromScale(1, 1)
    return UIKit.make("ImageLabel", props)
  end
  img({ZIndex = 3, Position = UDim2.fromScale(.5, .54), ImageColor3 = PLUM, ImageTransparency = .55})
  img({ZIndex = 4, Position = UDim2.fromScale(.5, .5)})
  local shine = img({ZIndex = 5, Position = UDim2.fromScale(.5, .5), Image = o.shine})
  local g = UIKit.make("UIGradient", {Parent = shine, Rotation = 20, Offset = Vector2.new(-1, 0),
    Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
      NumberSequenceKeypoint.new(.42, 1), NumberSequenceKeypoint.new(.5, .3),
      NumberSequenceKeypoint.new(.58, 1), NumberSequenceKeypoint.new(1, 1)})})
  UIKit.text({Parent = tile, Text = o.label, ZIndex = 6, AnchorPoint = Vector2.new(.5, .5),
    Position = UDim2.fromScale(.5, .93), Size = UDim2.fromScale(1.15, .3)})
  -- idle bob + tilt, desynced so a column of buttons doesn't move in lockstep
  task.delay(math.random() * 1.2, function()
    TweenService:Create(root, TweenInfo.new(1.2, Enum.EasingStyle.Sine,
      Enum.EasingDirection.InOut, -1, true),
      {Position = UDim2.fromScale(.5, .34), Rotation = 4}):Play()
  end)
  -- shine sweep every 3-5 s
  task.spawn(function()
    while holder.Parent do
      task.wait(3 + math.random() * 2)
      g.Offset = Vector2.new(-1, 0)
      UIKit.tween(g, .6, {Offset = Vector2.new(1, 0)}, Enum.EasingStyle.Linear)
    end
  end)
  UIKit.pop(tile)     -- hover/press scale (UI_RULEBOOK 5a); add the "!" badge per 5b
  return tile         -- connect tile.Activated for the action
end
```
Usage: `UIKit.iconButton(leftColumn, {image = Icons.Shop.image, shine = Icons.Shop.shine, label = "Shop", top = Color3.fromRGB(120,70,220), bottom = Color3.fromRGB(60,30,130), order = 1})`. Rarity tiles use the rarity gradients from research §6. On currency gain, tween the IconRoot's UIScale to 1.15 and back.

## 6. Check
`start_stop_play` → `screen_capture` at phone and PC sizes, checked against `UI_CHECKLIST.md`:
- The icon is readable at 48 px.
- No white fringe around icons.
- The outline matches the other icons.
- Shine and bob run, and nothing jitters.
- Odds and prices still come from the server.
