--!strict
-- Premium throw HUD builders (2026-11-20 UI pass, mockups in project files
-- fruit-throw/ui-mockups-2026-11-20, references on the round-2 board).
-- Layered "3D" look out of stock GuiObjects only - no image assets yet:
--   * 3D buttons: a darker base under a gradient face with a gloss strip;
--     pressing sinks the face (Brawl Stars / Clash Royale).
--   * chrome = UIGradient banding on a frame or a UIStroke.
--   * extruded text = stacked TextLabels (deepest first) + red/cyan ghost
--     copies for the RGB split, face coloured by a UIGradient.
--   * blur = Lighting BlurEffect ramp (blurs the 3D world, never the UI).
-- Names match the first HUD (ThrowButton, Rings/Target/Shrinking,
-- PowerMeter/Marker/Plus) so ThrowController and tests keep working.
-- Everything respects GuiService.ReducedMotionEnabled.
-- Studio check still needed: proportions on phone, the extrude depth at
-- small sizes, and the Mythical rim animation cost.

local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Motion = require(Shared:WaitForChild("Motion"))
local RarityStyle = require(Shared:WaitForChild("RarityStyle"))
local Juice = require(script.Parent.Juice)

local ui = Config.UI

local PremiumHUD = {}

local FONT = Enum.Font.LuckiestGuy
local BODY_FONT = Enum.Font.GothamBlack

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function reduced(): boolean
	return GuiService.ReducedMotionEnabled
end

local function corner(parent: GuiObject, scale: number, px: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale, px or 0)
	c.Parent = parent
end

local function frame(name: string, parent: Instance, color: Color3, size: UDim2, pos: UDim2?, anchor: Vector2?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.Size = size
	f.AnchorPoint = anchor or Vector2.new(0.5, 0.5)
	f.Position = pos or UDim2.fromScale(0.5, 0.5)
	f.Parent = parent
	return f
end

local function gradient(parent: Instance, keys: { { number } }, rotation: number): UIGradient
	local points = {}
	for _, k in keys do
		table.insert(points, ColorSequenceKeypoint.new(k[1], Color3.fromRGB(k[2], k[3], k[4])))
	end
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(points)
	g.Rotation = rotation
	g.Parent = parent
	return g
end

local function fade(parent: Instance, from: number, to: number, rotation: number): UIGradient
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new(from, to)
	g.Rotation = rotation
	g.Parent = parent
	return g
end

local function text(name: string, parent: Instance, value: string, color: Color3, font: Enum.Font?): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = name
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.5, 0.5)
	t.Font = font or FONT
	t.Text = value
	t.TextColor3 = color
	t.TextScaled = true
	t.Parent = parent
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 9 -- CLAUDE.md rule 5 floor
	limit.MaxTextSize = 200
	limit.Parent = t
	return t
end

local function outline(label: TextLabel, color: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Parent = label
end

-- Chrome: light/dark banding like polished metal.
local CHROME = {
	{ 0, 250, 251, 255 },
	{ 0.22, 125, 130, 143 },
	{ 0.45, 29, 31, 37 },
	{ 0.55, 201, 204, 214 },
	{ 0.75, 255, 255, 255 },
	{ 1, 92, 96, 107 },
}

-- Detail layers (2026-11-20 pass 2: "add detail everywhere") -------------------

-- Light rays fanning from the centre of `parent`: each ray is a bar inside a
-- full-size holder rotated about the centre (GuiObject rotation pivots on its
-- own centre). Returns the container so callers can spin or scale it.
local function rays(parent: Instance, count: number, color: Color3, width: number, alpha: number): Frame
	local box = frame("Rays", parent, Color3.new(0, 0, 0), UDim2.fromScale(1, 1))
	box.BackgroundTransparency = 1
	box.ZIndex = 0
	for i = 1, count do
		local holder = frame("Ray", box, Color3.new(0, 0, 0), UDim2.fromScale(1, 1))
		holder.BackgroundTransparency = 1
		holder.Rotation = (i - 1) * 360 / count
		holder.ZIndex = 0
		local bar = frame(
			"Bar",
			holder,
			color,
			UDim2.fromScale(if i % 2 == 0 then width * 0.6 else width, 0.5),
			UDim2.fromScale(0.5, 0.5),
			Vector2.new(0.5, 1)
		)
		bar.ZIndex = 0
		bar.BackgroundTransparency = alpha
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.55, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		g.Parent = bar
	end
	return box
end

-- Four-point twinkles (two crossed diamonds). Returns them for animation.
local function twinkles(parent: Instance, spots: { { number } }, color: Color3): { Frame }
	local out = {}
	for _, s in spots do
		local t = frame("Twinkle", parent, color, UDim2.fromScale(s[3], s[3]), UDim2.fromScale(s[1], s[2]))
		t.SizeConstraint = Enum.SizeConstraint.RelativeYY
		t.BackgroundTransparency = 1
		for _, r in { 0, 90 } do
			local spike = frame("Spike", t, color, UDim2.fromScale(0.16, 1))
			spike.Rotation = r
			corner(spike, 0.5)
			local g = Instance.new("UIGradient")
			g.Rotation = 90
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1),
			})
			g.Parent = spike
		end
		local core = frame("Core", t, Color3.new(1, 1, 1), UDim2.fromScale(0.22, 0.22))
		core.Rotation = 45
		table.insert(out, t)
	end
	return out
end

-- Chrome screw heads in the corners of a panel.
local function bolts(parent: Instance, inset: number, size: number, constraint: Enum.SizeConstraint)
	for _, p in { { inset, inset }, { 1 - inset, inset }, { inset, 1 - inset }, { 1 - inset, 1 - inset } } do
		local b = frame("Bolt", parent, Color3.new(1, 1, 1), UDim2.fromScale(size, size), UDim2.fromScale(p[1], p[2]))
		b.SizeConstraint = constraint
		b.ZIndex = 4
		corner(b, 0.5)
		gradient(b, CHROME, 45)
		local slot = frame("Slot", b, Color3.fromRGB(30, 32, 38), UDim2.fromScale(0.7, 0.16))
		slot.Rotation = 35
		slot.ZIndex = 4
	end
end

-- Carbon-fibre weave: alternating diagonal strands under a soft top sheen.
local function carbon(parent: Instance)
	local clip = frame("Carbon", parent, Color3.fromRGB(16, 17, 21), UDim2.fromScale(1, 1))
	clip.ClipsDescendants = true
	local c = parent:FindFirstChildOfClass("UICorner")
	if c then
		c:Clone().Parent = clip
	end
	for i = -10, 60 do
		local strand = frame(
			"Strand",
			clip,
			if i % 2 == 0 then Color3.fromRGB(38, 40, 47) else Color3.fromRGB(22, 23, 28),
			UDim2.new(0, 7, 3, 0),
			UDim2.new(0, i * 10, 0.5, 0)
		)
		strand.Rotation = 45
		strand.BackgroundTransparency = 0.15
	end
	local sheen =
		frame("Sheen", clip, Color3.new(1, 1, 1), UDim2.fromScale(1, 0.5), UDim2.fromScale(0.5, 0), Vector2.new(0.5, 0))
	fade(sheen, 0.82, 1, 90)
	return clip
end

-- Notches round a circular bezel (like a watch or a dial).
local function notches(parent: Instance, count: number, color: Color3)
	for i = 1, count do
		local holder = frame("Notch", parent, Color3.new(0, 0, 0), UDim2.fromScale(1, 1))
		holder.BackgroundTransparency = 1
		holder.Rotation = (i - 1) * 360 / count
		local mark = frame(
			"Mark",
			holder,
			color,
			UDim2.fromScale(if i % 4 == 1 then 0.025 else 0.014, if i % 4 == 1 then 0.05 else 0.03),
			UDim2.fromScale(0.5, 0.012),
			Vector2.new(0.5, 0)
		)
		mark.BackgroundTransparency = 0.25
	end
end

-- Throw button ---------------------------------------------------------------

export type Button = {
	root: TextButton,
	label: TextLabel,
	target: Frame,
	shrinking: Frame,
	setText: (string) -> (),
}

local function circle(name: string, parent: Instance, color: Color3, size: number, pos: UDim2?): Frame
	local f = frame(name, parent, color, UDim2.fromScale(size, size), pos)
	corner(f, 0.5)
	return f
end

local function ring(name: string, parent: Instance, color: Color3, thickness: number): Frame
	local f = circle(name, parent, color, 1)
	f.BackgroundTransparency = 1
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Parent = f
	return f
end

-- The round THROW button: halo, chrome bezel, a deep-orange base and the
-- gradient face that sinks on press. `size` is in Scale of the screen height.
function PremiumHUD.button(parent: Instance, label: string, size: number): Button
	local root = Instance.new("TextButton")
	root.Name = "ThrowButton"
	root.Text = ""
	root.AutoButtonColor = false
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(size, size)
	root.SizeConstraint = Enum.SizeConstraint.RelativeYY
	root.AnchorPoint = Vector2.new(1, 0.5)
	root.Parent = parent
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = root

	-- Slow-turning light rays and twinkles behind the button.
	local buttonRays = rays(root, 14, Color3.fromRGB(255, 190, 90), 0.05, 0.35)
	buttonRays.Size = UDim2.fromScale(1.7, 1.7)
	local buttonTwinkles = twinkles(root, {
		{ 0.08, 0.12, 0.16 },
		{ 0.95, 0.2, 0.11 },
		{ 0.02, 0.85, 0.1 },
		{ 0.88, 0.95, 0.14 },
	}, Color3.fromRGB(255, 226, 150))
	-- Halo: a soft orange glow ring just outside the bezel.
	local halo = ring("Halo", root, Color3.fromRGB(255, 138, 31), 6)
	halo.Size = UDim2.fromScale(1.06, 1.06)
	local haloStroke = halo:FindFirstChildOfClass("UIStroke") :: UIStroke
	haloStroke.Transparency = 0.35
	local bezel = circle("Bezel", root, Color3.new(1, 1, 1), 1)
	local chrome = gradient(bezel, CHROME, 35)
	notches(bezel, 32, Color3.fromRGB(40, 42, 50))
	local gap = circle("Gap", bezel, Color3.fromRGB(12, 13, 17), 0.9)
	local depth = ui.ButtonDepth
	local _base = circle("Base", gap, Color3.fromRGB(196, 82, 0), 0.86, UDim2.fromScale(0.5, 0.5 + depth))
	local face = circle("Face", gap, Color3.new(1, 1, 1), 0.86, UDim2.fromScale(0.5, 0.5 - depth))
	gradient(face, {
		{ 0, 255, 214, 150 },
		{ 0.35, 255, 162, 61 },
		{ 0.75, 255, 122, 18 },
		{ 1, 224, 94, 0 },
	}, 90)
	local gloss = frame(
		"Gloss",
		face,
		Color3.new(1, 1, 1),
		UDim2.fromScale(0.72, 0.4),
		UDim2.fromScale(0.5, 0.06),
		Vector2.new(0.5, 0)
	)
	corner(gloss, 0.5)
	fade(gloss, 0.25, 1, 90)
	-- Etched inner ring + a lower rim shadow: the face reads as a domed cap.
	local etch = circle("Etch", face, Color3.new(1, 1, 1), 0.8)
	etch.BackgroundTransparency = 1
	local etchStroke = Instance.new("UIStroke")
	etchStroke.Color = Color3.fromRGB(255, 226, 170)
	etchStroke.Transparency = 0.45
	etchStroke.Thickness = 2
	etchStroke.Parent = etch
	local lowRim = circle("LowRim", face, Color3.fromRGB(150, 50, 0), 1)
	lowRim.BackgroundTransparency = 0
	local lowGrad = Instance.new("UIGradient")
	lowGrad.Rotation = 90
	lowGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.7, 1),
		NumberSequenceKeypoint.new(1, 0.25),
	})
	lowGrad.Parent = lowRim
	-- A small fruit glyph above the word.
	local glyph = circle("Glyph", face, Color3.fromRGB(255, 244, 220), 0.17, UDim2.fromScale(0.5, 0.27))
	gradient(glyph, { { 0, 255, 255, 255 }, { 1, 255, 196, 120 } }, 90)
	local leaf =
		frame("Leaf", glyph, Color3.fromRGB(120, 210, 90), UDim2.fromScale(0.5, 0.28), UDim2.fromScale(0.72, -0.02))
	leaf.Rotation = -30
	corner(leaf, 0.5)
	local t = text("Label", face, label, Color3.new(1, 1, 1))
	t.Size = UDim2.fromScale(0.68, 0.34)
	t.Position = UDim2.fromScale(0.5, 0.6)
	outline(t, Color3.fromRGB(106, 36, 0), 2.5)

	-- Timing rings (same names/roles as the first HUD).
	local rings = Instance.new("Frame")
	rings.Name = "Rings"
	rings.BackgroundTransparency = 1
	rings.Size = UDim2.fromScale(1, 1)
	rings.Parent = root
	local target = ring("Target", rings, Color3.new(1, 1, 1), 4)
	target.Size = UDim2.fromScale(1.12, 1.12)
	target.Visible = false
	local shrinking = ring("Shrinking", rings, Color3.new(1, 1, 1), 7)
	shrinking.Visible = false
	local sweep = shrinking:FindFirstChildOfClass("UIStroke")
	if sweep then
		gradient(sweep, { { 0, 255, 255, 255 }, { 0.3, 255, 214, 64 }, { 0.7, 255, 138, 31 }, { 1, 255, 255, 255 } }, 0)
	end

	-- Press: the face sinks onto the base (same frame as the input).
	local up = UDim2.fromScale(0.5, 0.5 - depth)
	local down = UDim2.fromScale(0.5, 0.5 + depth * 0.4)
	local info = TweenInfo.new(if reduced() then 0 else ui.ButtonPressSeconds, Enum.EasingStyle.Quad)
	root.InputBegan:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			TweenService:Create(face, info, { Position = down }):Play()
		end
	end)
	root.InputEnded:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			TweenService:Create(face, info, { Position = up }):Play()
		end
	end)

	-- Slow chrome shimmer + halo breathing while visible.
	RunService.RenderStepped:Connect(function()
		if not root.Visible or reduced() then
			return
		end
		local now = os.clock()
		chrome.Rotation = 35 + math.sin(now * 1.3) * 25
		haloStroke.Transparency = 0.35 + math.sin(now * 3) * 0.2
		buttonRays.Rotation = (now * 12) % 360
		for i, tw in buttonTwinkles do
			local k = 0.5 + 0.5 * math.sin(now * 2.6 + i * 1.7)
			tw.Size = UDim2.fromScale(0.06 + 0.1 * k, 0.06 + 0.1 * k)
			tw.Rotation = now * 40 + i * 20
		end
		if shrinking.Visible then
			local g = sweep and sweep:FindFirstChildOfClass("UIGradient")
			if g then
				g.Rotation = (now * 360) % 360
			end
		end
	end)

	return {
		root = root,
		label = t,
		target = target,
		shrinking = shrinking,
		setText = function(s: string)
			t.Text = s
		end,
	}
end

-- Power meter (TFFA layout, glass + chrome finish) -----------------------------

export type Meter = {
	root: Frame,
	marker: Frame,
	plus: TextLabel,
	setValue: (number) -> (), -- 0..1 up the bar
}

function PremiumHUD.meter(parent: Instance): Meter
	local root = frame("PowerMeter", parent, Color3.new(1, 1, 1), UDim2.fromScale(0.05, 0.56))
	root.BackgroundTransparency = 1
	root.Visible = false
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 0.17
	aspect.Parent = root

	-- Carbon backplate with chrome rim and screws, wider than the tube.
	local plate = frame("Backplate", root, Color3.new(1, 1, 1), UDim2.fromScale(2.6, 1.08))
	plate.ZIndex = 0
	corner(plate, 0.18)
	carbon(plate)
	local plateRim = Instance.new("UIStroke")
	plateRim.Thickness = 3
	plateRim.Color = Color3.new(1, 1, 1)
	plateRim.Parent = plate
	gradient(plateRim, CHROME, 90)
	bolts(plate, 0.1, 0.11, Enum.SizeConstraint.RelativeXX)
	-- Power scale numbers down the left of the plate.
	for i = 0, 4 do
		local v = 20 - i * 5
		local n = text("Scale" .. v, plate, tostring(v), Color3.fromRGB(200, 204, 216), BODY_FONT)
		n.Size = UDim2.fromScale(0.28, 0.04)
		n.Position = UDim2.fromScale(0.16, 0.08 + i * 0.21)
		n.TextXAlignment = Enum.TextXAlignment.Center
	end
	local bezel = frame("Bezel", root, Color3.new(1, 1, 1), UDim2.fromScale(1, 1))
	corner(bezel, 0.5)
	gradient(bezel, CHROME, 0)
	local glass = frame("Glass", bezel, Color3.fromRGB(10, 12, 18), UDim2.new(1, -8, 1, -8))
	corner(glass, 0.5)
	glass.ClipsDescendants = true
	-- The colour ramp (TFFA: green top -> red bottom), slightly see-through.
	local fill = frame("Fill", glass, Color3.new(1, 1, 1), UDim2.fromScale(1, 1))
	fill.BackgroundTransparency = 0.06
	gradient(fill, {
		{ 0, 98, 227, 107 },
		{ 0.35, 190, 230, 60 },
		{ 0.6, 255, 214, 64 },
		{ 0.8, 255, 122, 18 },
		{ 1, 214, 45, 45 },
	}, 90)
	-- PERFECT band at the top: brighter gold with a glow stroke.
	local band = frame(
		"PerfectBand",
		glass,
		Color3.fromRGB(255, 236, 140),
		UDim2.fromScale(1, 0.1),
		UDim2.fromScale(0.5, 0),
		Vector2.new(0.5, 0)
	)
	local bandGlow = Instance.new("UIStroke")
	bandGlow.Color = Color3.fromRGB(255, 214, 64)
	bandGlow.Thickness = 3
	bandGlow.Transparency = 0.2
	bandGlow.Parent = band
	for i = 1, 7 do
		local tick = frame("Tick", glass, Color3.new(0, 0, 0), UDim2.new(0.62, 0, 0, 2), UDim2.fromScale(0.5, i / 8))
		tick.BackgroundTransparency = 0.65
	end
	-- Energy shimmer that runs up the fill.
	local scan = frame("Scan", glass, Color3.new(1, 1, 1), UDim2.fromScale(1, 0.18), UDim2.fromScale(0.5, 1))
	local scanGrad = Instance.new("UIGradient")
	scanGrad.Rotation = 90
	scanGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	scanGrad.Parent = scan
	local shine = frame("Shine", glass, Color3.new(1, 1, 1), UDim2.fromScale(0.16, 0.9), UDim2.fromScale(0.22, 0.5))
	corner(shine, 0.5)
	fade(shine, 0.35, 0.9, 90)

	local perfect = text("PerfectTag", root, "PERFECT", Color3.fromRGB(255, 246, 194))
	perfect.Size = UDim2.fromScale(3, 0.06)
	perfect.AnchorPoint = Vector2.new(0.5, 1)
	perfect.Position = UDim2.fromScale(0.5, -0.02)
	outline(perfect, Color3.fromRGB(106, 58, 0), 2)

	local marker = frame("Marker", root, Color3.new(1, 1, 1), UDim2.fromScale(1.5, 0.03), UDim2.fromScale(0.5, 0.5))
	marker.ZIndex = 3
	corner(marker, 0.5)
	local markerGlow = Instance.new("UIStroke")
	markerGlow.Color = Color3.new(1, 1, 1)
	markerGlow.Thickness = 3
	markerGlow.Transparency = 0.4
	markerGlow.Parent = marker
	-- Chevron pointing in at the tube from the left.
	local chevron =
		frame("Chevron", marker, Color3.new(1, 1, 1), UDim2.fromScale(0.3, 1.6), UDim2.fromScale(-0.08, 0.5))
	chevron.SizeConstraint = Enum.SizeConstraint.RelativeYY
	chevron.Size = UDim2.fromScale(1.5, 1.5)
	chevron.Rotation = 45
	chevron.ZIndex = 3
	gradient(chevron, { { 0, 255, 255, 255 }, { 1, 255, 179, 71 } }, 0)
	-- "+N" bubble riding the marker.
	local bubble = frame(
		"Bubble",
		marker,
		Color3.new(1, 1, 1),
		UDim2.fromScale(1.9, 3.4),
		UDim2.fromScale(1.15, 0.5),
		Vector2.new(0, 0.5)
	)
	bubble.ZIndex = 3
	bubble.SizeConstraint = Enum.SizeConstraint.RelativeXX
	bubble.Size = UDim2.fromScale(1.1, 0.62)
	corner(bubble, 0.3)
	gradient(bubble, { { 0, 255, 255, 255 }, { 1, 223, 227, 236 } }, 90)
	local plus = text("Plus", bubble, "+5", Color3.fromRGB(255, 122, 18))
	plus.ZIndex = 4
	plus.Size = UDim2.fromScale(0.86, 0.86)
	outline(plus, Color3.fromRGB(122, 44, 0), 1.5)

	RunService.RenderStepped:Connect(function()
		if not root.Visible or reduced() then
			return
		end
		local now = os.clock()
		scan.Position = UDim2.fromScale(0.5, 1.1 - ((now * 0.6) % 1.3))
		bandGlow.Transparency = 0.1 + 0.35 * (0.5 + 0.5 * math.sin(now * 6))
	end)

	return {
		root = root,
		marker = marker,
		plus = plus,
		setValue = function(v: number)
			marker.Position = UDim2.fromScale(0.5, 1 - math.clamp(v, 0, 1))
		end,
	}
end

-- Extruded grade text ---------------------------------------------------------

export type GradeText = {
	root: Frame,
	show: (string, Color3, boolean?) -> (),
}

-- Face colours: gold for PERFECT, chrome for MASTERWORK, the grade colour else.
local GOLD =
	{ { 0, 255, 251, 230 }, { 0.3, 255, 230, 128 }, { 0.52, 255, 194, 26 }, { 0.53, 255, 157, 0 }, { 1, 255, 216, 77 } }
local CHROME_FACE = {
	{ 0, 255, 255, 255 },
	{ 0.4, 233, 236, 245 },
	{ 0.5, 143, 149, 165 },
	{ 0.56, 255, 255, 255 },
	{ 1, 207, 211, 222 },
}

function PremiumHUD.gradeText(parent: Instance): GradeText
	local root = frame(
		"Grade",
		parent,
		Color3.new(0, 0, 0),
		UDim2.fromScale(0.62, 0.11),
		UDim2.fromScale(0.5, 0.27),
		Vector2.new(0.5, 0)
	)
	root.BackgroundTransparency = 1
	root.Visible = false

	-- Burst behind the word: rays that punch out and spin, plus twinkles.
	local burst = rays(root, 18, Color3.fromRGB(255, 236, 160), 0.035, 0.15)
	burst.SizeConstraint = Enum.SizeConstraint.RelativeYY
	burst.Size = UDim2.fromScale(3.2, 3.2)
	local burstScale = Instance.new("UIScale")
	burstScale.Parent = burst
	local gradeTwinkles = twinkles(root, {
		{ 0.12, 0.1, 0.5 },
		{ 0.9, 0.05, 0.42 },
		{ 0.05, 0.9, 0.36 },
		{ 0.94, 0.88, 0.5 },
		{ 0.5, -0.15, 0.3 },
	}, Color3.fromRGB(255, 240, 190))
	-- Swoosh underline.
	local swoosh =
		frame("Swoosh", root, Color3.fromRGB(255, 179, 71), UDim2.fromScale(0.7, 0.07), UDim2.fromScale(0.5, 1.02))
	swoosh.Rotation = -2
	corner(swoosh, 0.5)
	local swooshGrad = Instance.new("UIGradient")
	swooshGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	swooshGrad.Parent = swoosh

	local layers: { TextLabel } = {}
	for _, l in Motion.extrude(ui.ExtrudeLayers, ui.ExtrudeStepPx) do
		local t = text("Extrude", root, "", Color3.new(l.shade * 0.4, l.shade * 0.2, 0))
		t.Position = UDim2.new(0.5, 0, 0.5, l.offset)
		table.insert(layers, t)
	end
	local red = text("SplitRed", root, "", Color3.fromRGB(255, 45, 85))
	red.TextTransparency = 0.45
	local cyan = text("SplitCyan", root, "", Color3.fromRGB(37, 230, 255))
	cyan.TextTransparency = 0.45
	local face = text("Face", root, "", Color3.new(1, 1, 1))
	outline(face, Color3.fromRGB(26, 11, 0), 3)
	local faceGradient = Instance.new("UIGradient")
	faceGradient.Rotation = 90
	faceGradient.Parent = face

	local shownAt = 0
	local split = 0
	RunService.RenderStepped:Connect(function()
		if not root.Visible then
			return
		end
		local age = os.clock() - shownAt
		local w = Motion.splitWidth(age, split, ui.RgbSplitSeconds)
		red.Position = UDim2.new(0.5, -w, 0.5, 0)
		cyan.Position = UDim2.new(0.5, w, 0.5, 0)
		-- burst punches out fast then drifts; twinkles flicker
		burstScale.Scale = if reduced() then 1 else 0.4 + 0.6 * Motion.backOut(math.min(1, age / 0.25))
		burst.Rotation = age * 25
		for i, tw in gradeTwinkles do
			local k = 0.5 + 0.5 * math.sin(age * 9 + i * 1.3)
			tw.Size = UDim2.fromScale(0.15 + 0.35 * k, 0.15 + 0.35 * k)
		end
	end)

	local function keys(list: { { number } }): ColorSequence
		local pts = {}
		for _, k in list do
			table.insert(pts, ColorSequenceKeypoint.new(k[1], Color3.fromRGB(k[2], k[3], k[4])))
		end
		return ColorSequence.new(pts)
	end

	return {
		root = root,
		show = function(value: string, color: Color3, big: boolean?)
			for _, l in layers do
				l.Text = value
			end
			red.Text, cyan.Text, face.Text = value, value, value
			local isPerfect = value:find("PERFECT") ~= nil
			local isMaster = value:find("MASTERWORK") ~= nil
			if isMaster then
				faceGradient.Color = keys(CHROME_FACE)
			elseif isPerfect then
				faceGradient.Color = keys(GOLD)
			else
				-- grade colour with a light top so it still reads as a lit face
				local top = color:Lerp(Color3.new(1, 1, 1), 0.55)
				faceGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, top),
					ColorSequenceKeypoint.new(0.5, color),
					ColorSequenceKeypoint.new(1, color:Lerp(Color3.new(0, 0, 0), 0.15)),
				})
			end
			local glow = if isMaster
				then Color3.fromRGB(220, 235, 255)
				elseif isPerfect then Color3.fromRGB(255, 226, 120)
				else color:Lerp(Color3.new(1, 1, 1), 0.4)
			for _, ray in burst:GetDescendants() do
				if ray:IsA("Frame") and ray.Name == "Bar" then
					ray.BackgroundColor3 = glow
				end
			end
			burst.Visible = isPerfect or isMaster or big == true
			swoosh.BackgroundColor3 = color
			split = if (isPerfect or isMaster) and not reduced() then ui.RgbSplitPx * (if big then 1.6 else 1) else 0
			red.Visible, cyan.Visible = split > 0, split > 0
			shownAt = os.clock()
			Juice.popIn(root)
		end,
	}
end

-- Distance plate --------------------------------------------------------------

export type Plate = {
	root: Frame,
	setTarget: (number, boolean?) -> (), -- metres; true snaps instead of rolling
	setSub: (string, Color3) -> (),
}

function PremiumHUD.distancePlate(parent: Instance): Plate
	local root = frame(
		"FlightBanner",
		parent,
		Color3.fromRGB(22, 24, 30),
		UDim2.fromScale(0.3, 0.12),
		UDim2.fromScale(0.5, 0.02),
		Vector2.new(0.5, 0)
	)
	root.Visible = false
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 3.4
	aspect.Parent = root
	corner(root, 0.18)
	gradient(root, { { 0, 58, 61, 70 }, { 0.48, 22, 24, 30 }, { 0.52, 11, 12, 16 }, { 1, 34, 37, 45 } }, 90)
	carbon(root)
	bolts(root, 0.05, 0.12, Enum.SizeConstraint.RelativeYY)
	-- "DISTANCE" tab on top of the plate.
	local tab = frame(
		"Tab",
		root,
		Color3.fromRGB(255, 138, 31),
		UDim2.fromScale(0.34, 0.24),
		UDim2.fromScale(0.5, 0),
		Vector2.new(0.5, 0.75)
	)
	corner(tab, 0.4)
	gradient(tab, { { 0, 255, 196, 120 }, { 1, 230, 100, 10 } }, 90)
	local tabText = text("TabText", tab, "DISTANCE", Color3.new(1, 1, 1), BODY_FONT)
	tabText.Size = UDim2.fromScale(0.86, 0.7)
	outline(tabText, Color3.fromRGB(110, 40, 0), 1)
	-- LED segments along the bottom edge that chase while the fruit flies.
	local leds: { Frame } = {}
	for i = 1, 10 do
		local led = frame(
			"Led",
			root,
			Color3.fromRGB(255, 138, 31),
			UDim2.fromScale(0.06, 0.05),
			UDim2.fromScale(0.14 + (i - 1) * 0.08, 0.95)
		)
		corner(led, 0.5)
		led.BackgroundTransparency = 0.7
		table.insert(leds, led)
	end
	local rim = Instance.new("UIStroke")
	rim.Thickness = 3
	rim.Color = Color3.new(1, 1, 1)
	rim.Parent = root
	gradient(rim, CHROME, 0)
	local glow = frame("Glow", root, Color3.fromRGB(255, 138, 31), UDim2.new(0.8, 0, 0, 3), UDim2.new(0.5, 0, 1, 2))
	glow.BackgroundTransparency = 0.1

	local whole = text("Distance", root, "0", Color3.new(1, 1, 1))
	whole.Size = UDim2.fromScale(0.5, 0.62)
	whole.Position = UDim2.fromScale(0.48, 0.38)
	whole.AnchorPoint = Vector2.new(1, 0.5)
	whole.TextXAlignment = Enum.TextXAlignment.Right
	gradient(
		whole,
		{ { 0, 255, 255, 255 }, { 0.45, 255, 255, 255 }, { 0.55, 200, 204, 216 }, { 1, 243, 244, 248 } },
		90
	)
	outline(whole, Color3.new(0, 0, 0), 2)
	local tenths = text("Tenths", root, ".0", Color3.fromRGB(200, 204, 216))
	tenths.Size = UDim2.fromScale(0.16, 0.36)
	tenths.Position = UDim2.fromScale(0.49, 0.47)
	tenths.AnchorPoint = Vector2.new(0, 0.5)
	tenths.TextXAlignment = Enum.TextXAlignment.Left
	outline(tenths, Color3.new(0, 0, 0), 1.5)
	local unit = text("Unit", root, "m", Color3.fromRGB(255, 179, 71))
	unit.Size = UDim2.fromScale(0.12, 0.36)
	unit.Position = UDim2.fromScale(0.66, 0.44)
	unit.AnchorPoint = Vector2.new(0, 0.5)
	unit.TextXAlignment = Enum.TextXAlignment.Left
	outline(unit, Color3.new(0, 0, 0), 1.5)
	local sub = text("Fruit", root, "", Color3.new(1, 1, 1), BODY_FONT)
	sub.Size = UDim2.fromScale(0.92, 0.22)
	sub.Position = UDim2.fromScale(0.5, 0.82)
	outline(sub, Color3.new(0, 0, 0), 1.5)

	local shown = 0
	local target = 0
	local rainbow = false
	RunService.RenderStepped:Connect(function(dt: number)
		if not root.Visible then
			return
		end
		shown = Motion.roll(shown, target, dt, ui.DigitRollRate, ui.DigitMinStep)
		local a, b = Motion.splitDistance(shown)
		whole.Text, tenths.Text = a, b
		if rainbow then
			sub.TextColor3 = rgb(Motion.rainbow(os.clock(), ui.RainbowSpeed))
		end
		local head = if reduced() then -1 else math.floor(os.clock() * 14) % (#leds + 4)
		for i, led in leds do
			local d = head - i
			led.BackgroundTransparency = if d >= 0 and d < 3 then 0.05 + d * 0.25 else 0.75
		end
	end)

	return {
		root = root,
		setTarget = function(metres: number, snap: boolean?)
			target = math.max(0, metres)
			if snap or reduced() then
				shown = target
			end
		end,
		setSub = function(value: string, color: Color3)
			sub.Text = value
			sub.TextColor3 = color
			rainbow = value:upper():find("MYTHICAL") ~= nil
		end,
	}
end

-- Fruit reveal (after landing) -------------------------------------------------

export type Reveal = {
	root: Frame,
	play: (string, string, Instance?) -> number, -- returns how long it shows
}

local function rarityColor(rarity: string): Color3
	return rgb(Config.Rarity.Color[rarity] or { 255, 255, 255 })
end

function PremiumHUD.reveal(parent: Instance): Reveal
	local root = frame("Reveal", parent, Color3.new(0, 0, 0), UDim2.fromScale(1, 1))
	root.BackgroundTransparency = 1
	root.Visible = false
	root.ZIndex = 5

	-- Rarity ladder, left.
	local ladder = frame(
		"Ladder",
		root,
		Color3.new(0, 0, 0),
		UDim2.fromScale(0.2, 0.36),
		UDim2.fromScale(0.04, 0.5),
		Vector2.new(0, 0.5)
	)
	ladder.BackgroundTransparency = 1
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0.03, 0)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = ladder
	local rungs: { [string]: Frame } = {}
	for i, name in Config.Rarity.Order do
		local r = frame(name, ladder, Color3.fromRGB(10, 10, 16), UDim2.fromScale(1, 0.22))
		r.LayoutOrder = -i -- rarest on top
		r.BackgroundTransparency = 0.35
		corner(r, 0.25)
		local s = Instance.new("UIStroke")
		s.Color = rarityColor(name)
		s.Transparency = 0.8
		s.Parent = r
		local t = text("Name", r, string.upper(name), Color3.fromRGB(150, 150, 160), BODY_FONT)
		t.Size = UDim2.fromScale(0.8, 0.5)
		rungs[name] = r
	end

	-- God rays behind the card in the tier colour.
	local cardRays = rays(root, 20, Color3.new(1, 1, 1), 0.03, 0.2)
	cardRays.SizeConstraint = Enum.SizeConstraint.RelativeYY
	cardRays.Size = UDim2.fromScale(1.15, 1.15)
	cardRays.Position = UDim2.fromScale(0.5, 0.48)
	cardRays.Visible = false

	-- The card.
	local card = frame("Card", root, Color3.new(1, 1, 1), UDim2.fromScale(0.26, 0.62), UDim2.fromScale(0.5, 0.48))
	card.Rotation = -3 -- the SurfaceGui version tilts in real 3D (Studio follow-up)
	local cardAspect = Instance.new("UIAspectRatioConstraint")
	cardAspect.AspectRatio = 0.7
	cardAspect.Parent = card
	corner(card, 0.08)
	local rimGradient = gradient(card, { { 0, 255, 255, 255 }, { 1, 255, 255, 255 } }, 45)
	local body = frame("Body", card, Color3.new(1, 1, 1), UDim2.new(1, -10, 1, -10))
	corner(body, 0.07)
	gradient(body, { { 0, 34, 24, 58 }, { 0.6, 14, 10, 26 }, { 1, 7, 6, 12 } }, 90)
	-- Art window: a tier-tinted backdrop with the real fruit in a ViewportFrame
	-- on top (a UIGradient on the ViewportFrame itself would tint the fruit).
	local artBack = frame(
		"ArtBack",
		body,
		Color3.new(1, 1, 1),
		UDim2.fromScale(0.9, 0.56),
		UDim2.fromScale(0.5, 0.04),
		Vector2.new(0.5, 0)
	)
	corner(artBack, 0.08)
	local artGradient = gradient(artBack, { { 0, 255, 255, 255 }, { 1, 40, 20, 70 } }, 90)
	local art = Instance.new("ViewportFrame")
	art.Name = "Art"
	art.BackgroundTransparency = 1
	art.Size = UDim2.fromScale(1, 1)
	art.Ambient = Color3.fromRGB(210, 210, 210)
	art.LightColor = Color3.new(1, 1, 1)
	art.LightDirection = Vector3.new(-1, -1, -1)
	art.Parent = artBack
	local tier = text("Tier", body, "", Color3.new(1, 1, 1))
	tier.Size = UDim2.fromScale(0.9, 0.11)
	tier.Position = UDim2.fromScale(0.5, 0.68)
	outline(tier, Color3.new(0, 0, 0), 2.5)
	local name = text("FruitName", body, "", Color3.new(1, 1, 1))
	name.Size = UDim2.fromScale(0.9, 0.08)
	name.Position = UDim2.fromScale(0.5, 0.79)
	outline(name, Color3.new(0, 0, 0), 2)
	-- Gem in the top corner + chrome corner caps.
	local gem = frame("Gem", body, Color3.new(1, 1, 1), UDim2.fromScale(0.12, 0.12), UDim2.fromScale(0.88, 0.07))
	gem.SizeConstraint = Enum.SizeConstraint.RelativeXX
	gem.Rotation = 45
	gem.ZIndex = 3
	local gemGrad = gradient(gem, { { 0, 255, 255, 255 }, { 1, 255, 255, 255 } }, 0)
	local gemStroke = Instance.new("UIStroke")
	gemStroke.Thickness = 2
	gemStroke.Color = Color3.new(1, 1, 1)
	gemStroke.Parent = gem
	for _, p in { { 0, 0, 0 }, { 1, 0, 90 }, { 0, 1, -90 }, { 1, 1, 180 } } do
		local cap = frame("Cap", card, Color3.new(1, 1, 1), UDim2.fromScale(0.16, 0.16), UDim2.fromScale(p[1], p[2]))
		cap.SizeConstraint = Enum.SizeConstraint.RelativeXX
		cap.Rotation = p[3] + 45
		cap.ZIndex = 3
		gradient(cap, CHROME, 0)
		corner(cap, 0.2)
	end
	local divider = frame("Divider", body, Color3.new(1, 1, 1), UDim2.fromScale(0.7, 0.006), UDim2.fromScale(0.5, 0.86))
	fade(divider, 0, 0, 0).Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	local odds = text("Odds", body, "", Color3.fromRGB(230, 232, 240), BODY_FONT)
	odds.Size = UDim2.fromScale(0.5, 0.06)
	odds.Position = UDim2.fromScale(0.5, 0.9)

	local blur = Instance.new("BlurEffect")
	blur.Name = "RevealBlur"
	blur.Size = 0
	blur.Parent = Lighting

	local playing = false
	local mythical = false
	local spin: Instance? = nil -- the fruit copy turning slowly on the card
	RunService.RenderStepped:Connect(function(dt: number)
		local f = spin
		if not root.Visible or not f or reduced() then
			return
		end
		local turn = CFrame.Angles(0, dt * 1.2, 0)
		if f:IsA("Model") then
			local pivot = f:GetPivot()
			f:PivotTo(CFrame.new(pivot.Position) * turn * pivot.Rotation)
		elseif f:IsA("BasePart") then
			f.CFrame = CFrame.new(f.Position) * turn * f.CFrame.Rotation
		end
	end)
	RunService.RenderStepped:Connect(function()
		if root.Visible and not reduced() then
			cardRays.Rotation = (os.clock() * 15) % 360
		end
	end)
	RunService.RenderStepped:Connect(function()
		if not root.Visible or not mythical or reduced() then
			return
		end
		local now = os.clock()
		local pts = {}
		for i = 0, 4 do
			table.insert(pts, ColorSequenceKeypoint.new(i / 4, rgb(Motion.rainbow(now, ui.RainbowSpeed, i / 5))))
		end
		rimGradient.Color = ColorSequence.new(pts)
		rimGradient.Rotation = (now * 90) % 360
		tier.TextColor3 = rgb(Motion.rainbow(now, ui.RainbowSpeed))
	end)

	local function blurTo(size: number, seconds: number)
		TweenService:Create(blur, TweenInfo.new(if reduced() then 0 else seconds), { Size = size }):Play()
	end

	return {
		root = root,
		play = function(fruitName: string, rarity: string, model: Instance?): number
			if playing then
				return 0
			end
			playing = true
			local beats = RarityStyle.reveal(
				rarity,
				Config.Rarity,
				ui.RevealClimbStep,
				ui.RevealBloomFrom,
				ui.RevealBloomSeconds,
				ui.RevealHoldSeconds
			)
			local color = rarityColor(rarity)
			mythical = rarity == "Mythical"
			rimGradient.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.4), color)
			artGradient.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.5), Color3.fromRGB(18, 11, 34))
			tier.Text = string.upper(rarity)
			tier.TextColor3 = color
			gemGrad.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.6), color)
			for _, bar in cardRays:GetDescendants() do
				if bar:IsA("Frame") and bar.Name == "Bar" then
					bar.BackgroundColor3 = color:Lerp(Color3.new(1, 1, 1), 0.3)
				end
			end
			cardRays.Visible = false
			name.Text = string.upper(fruitName)
			odds.Text = RarityStyle.oddsText(RarityStyle.chance(rarity, Config.Rarity))
			for _, r in rungs do
				r.BackgroundTransparency = 0.35
				r.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
				local label = r:FindFirstChild("Name")
				if label and label:IsA("TextLabel") then
					label.TextColor3 = Color3.fromRGB(150, 150, 160)
				end
				local s = r:FindFirstChildOfClass("UIStroke")
				if s then
					s.Transparency = 0.8
				end
			end
			for _, child in art:GetChildren() do
				if not child:IsA("UIGradient") then
					child:Destroy()
				end
			end
			if model and (model:IsA("BasePart") or model:IsA("Model")) then
				local copy: Instance = (model :: Instance):Clone()
				copy.Parent = art
				local cam = Instance.new("Camera")
				cam.Parent = art
				art.CurrentCamera = cam
				local center, size = Vector3.zero, 2
				if copy:IsA("Model") then
					center = copy:GetPivot().Position
					local e = copy:GetExtentsSize()
					size = math.max(e.X, e.Y, e.Z)
				elseif copy:IsA("BasePart") then
					center = copy.Position
					size = math.max(copy.Size.X, copy.Size.Y, copy.Size.Z)
				end
				-- frame the fruit to fill ~70% of the window
				cam.FieldOfView = 40
				cam.CFrame = CFrame.lookAt(center + Vector3.new(0, size * 0.25, size * 2.1), center)
				spin = copy
			end
			card.Visible = false
			root.Visible = true
			blurTo(ui.RevealBlurSize, 0.25)
			-- climb the ladder, one rung per step
			local step = if reduced() then 0 else ui.RevealClimbStep
			for i, tierName in beats.climb do
				task.delay(step * (i - 1), function()
					local r = rungs[tierName]
					if r then
						r.BackgroundTransparency = 0.05
						r.BackgroundColor3 = rarityColor(tierName):Lerp(Color3.new(0, 0, 0), 0.45)
						local s = r:FindFirstChildOfClass("UIStroke")
						if s then
							s.Transparency = 0
						end
						local label = r:FindFirstChild("Name")
						if label and label:IsA("TextLabel") then
							label.TextColor3 = Color3.new(1, 1, 1)
						end
						Juice.popIn(r)
					end
				end)
			end
			local cardAt = step * #beats.climb + (if beats.bloom then ui.RevealBloomSeconds else 0)
			task.delay(cardAt, function()
				cardRays.Visible = true
				Juice.popIn(card)
				if beats.bloom then
					Juice.shakeCamera(Config.Throw.PerfectShake)
				end
			end)
			local total = cardAt + ui.RevealHoldSeconds
			task.delay(total, function()
				root.Visible = false
				blurTo(0, 0.3)
				playing = false
			end)
			return total
		end,
	}
end

return PremiumHUD
