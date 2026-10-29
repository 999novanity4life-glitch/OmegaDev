--!strict
-- The Moon Mop look, matched to the reference frames (P1 f_003 supply wall, f_145 upgrades,
-- f_181 build, f_182 Moon Map, f_403 garage, f_006 HUD):
--   * Montserrat everywhere: heavy white titles, small uppercase labels, bold numbers.
--   * Station menus are two rows of slate panels on a blurred scene: a title panel and a money
--     panel on top, a big list panel and a detail panel below. Every panel has rounded corners,
--     corner screws and a thin orange and black hazard stripe on its top edge.
--   * Teal category labels, green luggage tags for affordable prices and red for too expensive,
--     an orange selected row, a big orange button, key hints centred under the panels.
-- Menus are laid out on a 1280 x 720 design canvas (the size of the reference frames) and
-- scaled to fit the screen with a UIScale, so positions copy straight from the frames.
-- Mobile (CLAUDE.md rule 5): the canvas always fits inside the safe area; tap targets stay at
-- least 44 design px.

local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UITokens = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UITokens"))
local Juice = require(script.Parent.Juice)

local Theme = {}

---------------------------------------------------------------------------- colours
-- Sampled from the reference frames.
Theme.PANEL = Color3.fromRGB(44, 50, 57)
Theme.INNER = Color3.fromRGB(31, 36, 41)
Theme.ROW = Color3.fromRGB(52, 58, 66)
Theme.EDGE = Color3.fromRGB(66, 73, 82)
Theme.SCREW = Color3.fromRGB(128, 136, 146)
Theme.KEYCAP = Color3.fromRGB(22, 25, 29)
-- older names, kept for the controllers that use them
Theme.SLATE = Theme.PANEL
Theme.SLATE_HI = Theme.ROW
Theme.SLATE_LO = Theme.INNER
Theme.ORANGE = Color3.fromRGB(240, 102, 12)
Theme.ORANGE_HI = Color3.fromRGB(255, 132, 34)
Theme.AMBER = Color3.fromRGB(255, 196, 40)
Theme.YELLOW = Color3.fromRGB(245, 180, 0)
Theme.TEAL = Color3.fromRGB(56, 222, 200)
Theme.GREEN = Color3.fromRGB(38, 170, 72)
Theme.MINT = Color3.fromRGB(120, 236, 170)
Theme.RED = Color3.fromRGB(214, 40, 32)
Theme.WHITE = Color3.fromRGB(244, 246, 248)
Theme.MUTED = Color3.fromRGB(150, 158, 168)
Theme.DIM = Color3.fromRGB(104, 112, 122)
Theme.BLACK = Color3.fromRGB(14, 14, 16)
Theme.CREAM = Color3.fromRGB(241, 235, 221)

---------------------------------------------------------------------------- fonts
-- Montserrat ships with Roblox (checked in Studio with TextService:GetTextBoundsAsync).
local function mont(weight: Enum.FontWeight): Font
	return Font.fromName("Montserrat", weight)
end
Theme.F = {
	regular = mont(Enum.FontWeight.Medium),
	semi = mont(Enum.FontWeight.SemiBold),
	bold = mont(Enum.FontWeight.Bold),
	heavy = mont(Enum.FontWeight.ExtraBold),
	black = mont(Enum.FontWeight.Heavy),
	serif = Font.fromName("Merriweather", Enum.FontWeight.Regular),
	serifBold = Font.fromName("Merriweather", Enum.FontWeight.Bold),
	hand = Font.fromName("Kalam", Enum.FontWeight.Regular),
}

-- Old Enum.Font arguments map onto the new faces.
local function faceFor(font: Enum.Font?): Font
	if font == Enum.Font.GothamBlack then
		return Theme.F.heavy
	elseif font == Enum.Font.GothamBold then
		return Theme.F.semi
	end
	return Theme.F.regular
end

---------------------------------------------------------------------------- basics
function Theme.corner(parent: GuiObject, px: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px)
	c.Parent = parent
end

function Theme.stroke(parent: GuiObject, color: Color3, thickness: number, transparency: number?)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

-- A soft dark outline behind text that floats over the 3D scene (the HUD has no panels).
function Theme.shadow(label: TextLabel, transparency: number?)
	local s = Instance.new("UIStroke")
	s.Color = Color3.new(0, 0, 0)
	s.Thickness = 1
	s.Transparency = transparency or 0.55
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = label
end

function Theme.pad(parent: GuiObject, px: number)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.Parent = parent
end

function Theme.screen(name: string, parent: Instance, order: number?): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = order or 0
	gui.Parent = parent
	return gui
end

function Theme.frame(size: UDim2, pos: UDim2?, color: Color3?, transparency: number?): Frame
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos or UDim2.new()
	f.BackgroundColor3 = color or Theme.PANEL
	f.BackgroundTransparency = transparency or 0
	f.BorderSizePixel = 0
	return f
end

-- Fixed-size text for the design canvas (the canvas UIScale does the scaling).
function Theme.label(text: string, px: number, color: Color3?, face: Font?, size: UDim2?, pos: UDim2?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size or UDim2.new(1, 0, 0, px + 4)
	l.Position = pos or UDim2.new()
	l.Text = text
	l.TextColor3 = color or Theme.WHITE
	l.FontFace = face or Theme.F.semi
	l.TextSize = math.max(px, UITokens.MIN_TEXT)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	return l
end

-- Text that scales to its box (older controllers).
function Theme.text(text: string, size: UDim2, color: Color3?, font: Enum.Font?, maxSize: number?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Text = text
	l.TextColor3 = color or Theme.WHITE
	l.FontFace = faceFor(font)
	l.TextScaled = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = math.max(UITokens.MIN_TEXT, 10)
	limit.MaxTextSize = maxSize or 28
	limit.Parent = l
	return l
end

local function clear(parent: Instance)
	for _, c in parent:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end
Theme.clear = clear

---------------------------------------------------------------------------- panel parts
-- Orange and black hazard stripe. A CanvasGroup clips the rotated stripes cleanly.
function Theme.stripe(parent: GuiObject, height: number, pos: UDim2?, size: UDim2?): CanvasGroup
	local bar = Instance.new("CanvasGroup")
	bar.Name = "Hazard"
	bar.Size = size or UDim2.new(1, 0, 0, height)
	bar.Position = pos or UDim2.new()
	bar.BackgroundColor3 = Color3.fromRGB(26, 26, 28)
	bar.BorderSizePixel = 0
	for i = -2, 110 do
		local s = Theme.frame(
			UDim2.new(0, height * 0.75, 0, height * 3),
			UDim2.new(0, i * height * 1.6, 0.5, 0),
			Theme.ORANGE
		)
		s.AnchorPoint = Vector2.new(0.5, 0.5)
		s.Rotation = 40
		s.Parent = bar
	end
	bar.Parent = parent
	return bar
end

local function screw(parent: GuiObject, x: number, y: number, ax: number, ay: number)
	local s = Theme.frame(UDim2.fromOffset(7, 7), UDim2.new(ax, x, ay, y), Theme.SCREW)
	s.AnchorPoint = Vector2.new(0.5, 0.5)
	Theme.corner(s, 4)
	local slot = Theme.frame(UDim2.fromOffset(5, 1), UDim2.fromScale(0.5, 0.5), Theme.INNER)
	slot.AnchorPoint = Vector2.new(0.5, 0.5)
	slot.Rotation = 35
	slot.Parent = s
	s.Parent = parent
end

-- A slate station panel at design-canvas pixels.
function Theme.panel(parent: Instance, x: number, y: number, w: number, h: number): Frame
	local p = Theme.frame(UDim2.fromOffset(w, h), UDim2.fromOffset(x, y), Theme.PANEL)
	Theme.corner(p, 6)
	Theme.stroke(p, Theme.EDGE, 1)
	Theme.stripe(p, 6, UDim2.fromOffset(18, 0), UDim2.new(1, -36, 0, 6))
	screw(p, 10, 10, 0, 0)
	screw(p, -10, 10, 1, 0)
	screw(p, 10, -10, 0, 1)
	screw(p, -10, -10, 1, 1)
	p.Parent = parent
	return p
end

-- A darker inset area inside a panel.
function Theme.inset(parent: Instance, size: UDim2, pos: UDim2?): Frame
	local f = Theme.frame(size, pos, Theme.INNER)
	Theme.corner(f, 5)
	f.Parent = parent
	return f
end

-- The gold coin with a white dollar sign.
function Theme.coin(parent: Instance, px: number, pos: UDim2): Frame
	local c = Theme.frame(UDim2.fromOffset(px, px), pos, Theme.AMBER)
	Theme.corner(c, px)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.fromRGB(255, 214, 70), Color3.fromRGB(240, 140, 10))
	g.Rotation = 90
	g.Parent = c
	Theme.stroke(c, Color3.fromRGB(255, 226, 120), math.max(1, px / 16), 0.2)
	local inner = Theme.frame(UDim2.fromScale(0.72, 0.72), UDim2.fromScale(0.5, 0.5), Color3.fromRGB(252, 170, 26))
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	Theme.corner(inner, px)
	inner.Parent = c
	local d = Theme.label("$", math.floor(px * 0.6), Theme.WHITE, Theme.F.black, UDim2.fromScale(1, 1))
	d.TextXAlignment = Enum.TextXAlignment.Center
	Theme.shadow(d, 0.7)
	d.Parent = c
	c.Parent = parent
	return c
end

-- Amber number with an orange gradient, as on the money readouts.
function Theme.amber(label: TextLabel)
	label.TextColor3 = Color3.new(1, 1, 1)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.fromRGB(255, 222, 70), Color3.fromRGB(250, 150, 24))
	g.Rotation = 90
	g.Parent = label
end

-- Luggage price tag: a hole dot on the left, white bold price. Kinds: Good (green),
-- Bad (red), Cream (build menu: cream with dark text), Slot (teal text, no tag).
export type TagKind = "Good" | "Bad" | "Cream" | "Info" | "Owned"
function Theme.luggage(text: string, kind: TagKind, tilt: number?): Frame
	local cream = kind == "Cream"
	local color = if kind == "Good"
		then Theme.GREEN
		elseif kind == "Bad" then Theme.RED
		elseif cream then Theme.CREAM
		elseif kind == "Owned" then Theme.TEAL
		else Theme.ROW
	local w = 34 + #text * 9
	local t = Theme.frame(UDim2.fromOffset(w, 24), UDim2.new(), color)
	t.Rotation = tilt or 0
	Theme.corner(t, 3)
	local point = Theme.frame(UDim2.fromOffset(14, 14), UDim2.new(0, 0, 0.5, 0), color)
	point.AnchorPoint = Vector2.new(0.5, 0.5)
	point.Rotation = 45
	Theme.corner(point, 2)
	point.ZIndex = 0
	point.Parent = t
	local hole = Theme.frame(UDim2.fromOffset(7, 7), UDim2.new(0, 9, 0.5, 0), Theme.WHITE)
	hole.AnchorPoint = Vector2.new(0.5, 0.5)
	Theme.corner(hole, 4)
	hole.Parent = t
	local holeIn = Theme.frame(UDim2.fromOffset(3, 3), UDim2.fromScale(0.5, 0.5), if cream then Theme.RED else color)
	holeIn.AnchorPoint = Vector2.new(0.5, 0.5)
	Theme.corner(holeIn, 2)
	holeIn.Parent = hole
	local l = Theme.label(
		text,
		14,
		if cream then Theme.BLACK else Theme.WHITE,
		Theme.F.bold,
		UDim2.new(1, -18, 1, 0),
		UDim2.fromOffset(16, 0)
	)
	l.TextXAlignment = Enum.TextXAlignment.Center
	l.Parent = t
	return t
end

-- Small price/status tag (older controllers). Same colours as the luggage tags.
function Theme.tag(text: string, kind: "Good" | "Bad" | "Info" | "Owned"): TextLabel
	local t = Theme.text(text, UDim2.new(0, 96, 0, 24), Theme.WHITE, Enum.Font.GothamBlack, 15)
	t.BackgroundTransparency = 0
	t.BackgroundColor3 = if kind == "Good"
		then Theme.GREEN
		elseif kind == "Bad" then Theme.RED
		elseif kind == "Owned" then Theme.INNER
		else Theme.ROW
	if kind == "Owned" then
		t.TextColor3 = Theme.TEAL
	end
	t.TextXAlignment = Enum.TextXAlignment.Center
	Theme.corner(t, 3)
	return t
end

-- Row of level pips: small squares, orange for each level owned.
function Theme.pips(parent: Instance, max: number, level: number, pos: UDim2, onOrange: boolean?): Frame
	local f = Theme.frame(UDim2.fromOffset(max * 11, 8), pos, Theme.PANEL, 1)
	f.AnchorPoint = Vector2.new(0, 0.5)
	for i = 1, max do
		local p = Theme.frame(
			UDim2.fromOffset(8, 8),
			UDim2.fromOffset((i - 1) * 11, 0),
			if i <= level then (if onOrange then Theme.WHITE else Theme.ORANGE) else Color3.fromRGB(70, 76, 86)
		)
		p.BackgroundTransparency = if onOrange and i > level then 0.6 else 0
		Theme.corner(p, 1)
		p.Parent = f
	end
	f.Parent = parent
	return f
end

-- A stat row in a detail card: dark strip, small grey label left, bold value right.
function Theme.statRow(parent: Instance, y: number, label: string, value: string, valueColor: Color3?): Frame
	local r = Theme.frame(UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, y), Theme.INNER)
	Theme.corner(r, 4)
	local l = Theme.label(
		string.upper(label),
		10,
		Theme.MUTED,
		Theme.F.bold,
		UDim2.new(0.5, 0, 1, 0),
		UDim2.fromOffset(12, 0)
	)
	l.Parent = r
	local v = Theme.label(
		value,
		14,
		valueColor or Theme.WHITE,
		Theme.F.bold,
		UDim2.new(0.6, -12, 1, 0),
		UDim2.new(0.4, 0, 0, 0)
	)
	v.TextXAlignment = Enum.TextXAlignment.Right
	v.Name = "Value"
	v.Parent = r
	r.Parent = parent
	return r
end

export type ButtonStyle = "Orange" | "Dark" | "Green" | "Red" | "Gray"

-- Buttons. Orange is the big action button; Gray is a disabled action.
function Theme.button(text: string, size: UDim2, style: ButtonStyle?): TextButton
	local b = Instance.new("TextButton")
	b.Size = size
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	local fill = if style == "Dark"
		then Theme.ROW
		elseif style == "Green" then Theme.GREEN
		elseif style == "Red" then Theme.RED
		elseif style == "Gray" then Color3.fromRGB(72, 79, 89)
		else Theme.ORANGE
	b.BackgroundColor3 = fill
	b.TextColor3 = if style == "Gray" then Color3.fromRGB(140, 148, 158) else Theme.WHITE
	b.FontFace = Theme.F.heavy
	b.Text = text
	b.TextScaled = true
	Theme.corner(b, 6)
	Theme.pad(b, 7)
	if style == nil or style == "Orange" then
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(Theme.ORANGE_HI, Theme.ORANGE)
		g.Rotation = 90
		g.Parent = b
	end
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 11
	limit.MaxTextSize = 22
	limit.Parent = b
	local min = Instance.new("UISizeConstraint")
	min.MinSize = Vector2.new(UITokens.MIN_TOUCH, math.min(UITokens.MIN_TOUCH, 30))
	min.Parent = b
	Juice.bindButton(b)
	return b
end

-- Big detail-card action: "BUY $25", "INSTALL LEVEL I  $120", grey when not possible.
function Theme.action(parent: Instance, text: string, enabled: boolean, y: number, h: number?): TextButton
	local b = Theme.button(text, UDim2.new(1, 0, 0, h or 50), if enabled then "Orange" else "Gray")
	b.Position = UDim2.fromOffset(0, y)
	local limit = b:FindFirstChildOfClass("UITextSizeConstraint")
	if limit then
		limit.MaxTextSize = 20
	end
	b.Parent = parent
	return b
end

-- A clickable list/grid cell with no default look.
function Theme.cell(size: UDim2, color: Color3?): TextButton
	local b = Instance.new("TextButton")
	b.Size = size
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.Text = ""
	b.BackgroundColor3 = color or Theme.ROW
	b.BackgroundTransparency = if color then 0 else 0
	return b
end

---------------------------------------------------------------------------- key hints
-- A key cap ("E", "Esc", "Enter") or a mouse glyph ("LMB", "RMB", "MMB").
function Theme.keycap(key: string): Frame
	local mouse = key == "LMB" or key == "RMB" or key == "MMB"
	if mouse then
		local m = Theme.frame(UDim2.fromOffset(14, 20), UDim2.new(), Theme.WHITE)
		Theme.corner(m, 7)
		local half = Theme.frame(
			UDim2.new(if key == "MMB" then 0.3 else 0.5, 0, 0.45, 0),
			UDim2.fromScale(if key == "LMB" then 0 elseif key == "RMB" then 0.5 else 0.35, 0),
			Theme.KEYCAP
		)
		Theme.corner(half, 4)
		half.Parent = m
		return m
	end
	local w = math.max(22, 10 + #key * 8)
	local c = Theme.frame(UDim2.fromOffset(w, 22), UDim2.new(), Theme.KEYCAP)
	Theme.corner(c, 4)
	Theme.stroke(c, Color3.fromRGB(70, 76, 86), 1, 0.4)
	local l = Theme.label(key, if #key > 2 then 10 else 12, Theme.WHITE, Theme.F.bold, UDim2.fromScale(1, 1))
	l.TextXAlignment = Enum.TextXAlignment.Center
	l.Parent = c
	return c
end

-- A centred row of key hints: { {"W","S","Choose"}, {"E","Esc","Leave"} }. The last entry of
-- each hint is its label, the rest are keys.
function Theme.hints(parent: Instance, list: { { string } }, y: number?, xCentre: number?): Frame
	local row = Theme.frame(UDim2.fromOffset(1100, 26), UDim2.fromOffset(xCentre or 640, y or 677), Theme.PANEL, 1)
	row.Name = "Hints"
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 22)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row
	Theme.setHints(row, list)
	row.Parent = parent
	return row
end

function Theme.setHints(row: Frame, list: { { string } })
	clear(row)
	for i, hint in list do
		local item = Theme.frame(UDim2.fromOffset(0, 24), UDim2.new(), Theme.PANEL, 1)
		item.AutomaticSize = Enum.AutomaticSize.X
		item.LayoutOrder = i
		local il = Instance.new("UIListLayout")
		il.FillDirection = Enum.FillDirection.Horizontal
		il.VerticalAlignment = Enum.VerticalAlignment.Center
		il.Padding = UDim.new(0, 6)
		il.SortOrder = Enum.SortOrder.LayoutOrder
		il.Parent = item
		for k = 1, #hint - 1 do
			local cap = Theme.keycap(hint[k])
			cap.LayoutOrder = k
			cap.Parent = item
		end
		local l = Theme.label(hint[#hint], 13, Theme.WHITE, Theme.F.semi, UDim2.fromOffset(0, 24))
		l.AutomaticSize = Enum.AutomaticSize.X
		l.LayoutOrder = #hint + 1
		Theme.shadow(l, 0.6)
		l.Parent = item
		item.Parent = row
	end
end

---------------------------------------------------------------------------- 3D icons
-- A ViewportFrame showing a copy of `model` from a three-quarter angle, lit like the store
-- renders in the reference (white, soft shadows).
function Theme.icon3d(model: Model, size: UDim2, pos: UDim2?, yaw: number?, pitch: number?): ViewportFrame
	local vp = Instance.new("ViewportFrame")
	vp.Size = size
	vp.Position = pos or UDim2.new()
	vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(170, 170, 178)
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.LightDirection = Vector3.new(-0.6, -1, -0.4)
	local copy = model:Clone()
	for _, d in copy:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ProximityPrompt") or d:IsA("BillboardGui") then
			d:Destroy()
		end
	end
	copy:PivotTo(CFrame.identity)
	copy.Parent = vp
	local cf, ext = copy:GetBoundingBox()
	local radius = ext.Magnitude / 2
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	local dir = (CFrame.Angles(0, math.rad(yaw or 35), 0) * CFrame.Angles(math.rad(-(pitch or 25)), 0, 0)).LookVector
	local dist = radius / math.sin(math.rad(cam.FieldOfView / 2)) * 1.02
	cam.CFrame = CFrame.lookAt(cf.Position - dir * dist, cf.Position)
	cam.Parent = vp
	vp.CurrentCamera = cam
	return vp
end

---------------------------------------------------------------------------- station menus
-- Fit a 1280 x 720 canvas inside its parent with a UIScale.
function Theme.canvas(parent: Instance): Frame
	local holder = Theme.frame(UDim2.fromScale(1, 1), UDim2.new(), Theme.PANEL, 1)
	holder.Name = "Holder"
	local c = Theme.frame(UDim2.fromOffset(1280, 720), UDim2.fromScale(0.5, 0.5), Theme.PANEL, 1)
	c.Name = "Canvas"
	c.AnchorPoint = Vector2.new(0.5, 0.5)
	local scale = Instance.new("UIScale")
	scale.Parent = c
	c.Parent = holder
	local function fit()
		local s = holder.AbsoluteSize
		if s.X > 0 and s.Y > 0 then
			scale.Scale = math.min(s.X / 1280, s.Y / 720)
		end
	end
	holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	task.defer(fit)
	holder.Parent = parent
	return c
end

-- Blur the world behind an open menu (P1 f_145: the scene blurs, the HUD hides).
local blur: BlurEffect? = nil
function Theme.setBlur(on: boolean)
	if not blur then
		local b = Instance.new("BlurEffect")
		b.Name = "MenuBlur"
		b.Size = 0
		b.Parent = Lighting
		blur = b
	end
	local b = blur :: BlurEffect
	TweenService:Create(b, TweenInfo.new(if GuiService.ReducedMotionEnabled then 0 else 0.2), {
		Size = if on then 14 else 0,
	}):Play()
end

export type StationMenu = {
	root: Frame, -- full-screen holder: toggle Visible / pass to Menus.register
	canvas: Frame,
	header: Frame,
	title: TextLabel,
	counter: TextLabel, -- right side of the title panel ("INSTALLED 0 / 56")
	counterLabel: TextLabel,
	money: TextLabel,
	main: Frame,
	tabs: Frame,
	body: Frame, -- the dark inset inside the main panel
	detail: Frame, -- inside the detail panel, padded
	hints: Frame,
}

-- The standard station menu (supply wall, upgrades, build, garage).
function Theme.stationMenu(gui: ScreenGui, title: string): StationMenu
	local root = Theme.frame(UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), Theme.PANEL, 1)
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Name = title
	root.Visible = false
	root.Parent = gui
	local canvas = Theme.canvas(root)
	local header = Theme.panel(canvas, 44, 26, 777, 72)
	local t = Theme.label(
		string.upper(title),
		26,
		Theme.WHITE,
		Theme.F.heavy,
		UDim2.new(0.7, 0, 0, 34),
		UDim2.fromOffset(21, 20)
	)
	t.Parent = header
	local counterLabel =
		Theme.label("", 9, Theme.MUTED, Theme.F.bold, UDim2.fromOffset(200, 12), UDim2.new(1, -221, 0, 21))
	counterLabel.TextXAlignment = Enum.TextXAlignment.Right
	counterLabel.Parent = header
	local counter = Theme.label("", 20, Theme.WHITE, Theme.F.bold, UDim2.fromOffset(200, 24), UDim2.new(1, -221, 0, 32))
	counter.TextXAlignment = Enum.TextXAlignment.Right
	counter.Parent = header
	local moneyPanel = Theme.panel(canvas, 849, 26, 388, 72)
	Theme.coin(moneyPanel, 30, UDim2.fromOffset(21, 21))
	local money = Theme.label("0.00", 26, Theme.AMBER, Theme.F.bold, UDim2.new(1, -80, 0, 34), UDim2.fromOffset(64, 19))
	Theme.amber(money)
	money.Parent = moneyPanel
	local main = Theme.panel(canvas, 44, 114, 777, 524)
	local tabs = Theme.frame(UDim2.new(1, -48, 0, 22), UDim2.fromOffset(24, 14), Theme.PANEL, 1)
	tabs.Name = "Tabs"
	local tl = Instance.new("UIListLayout")
	tl.FillDirection = Enum.FillDirection.Horizontal
	tl.Padding = UDim.new(0, 4)
	tl.SortOrder = Enum.SortOrder.LayoutOrder
	tl.Parent = tabs
	tabs.Parent = main
	local body = Theme.inset(main, UDim2.new(1, -32, 1, -52), UDim2.fromOffset(16, 36))
	body.Name = "Body"
	local detailPanel = Theme.panel(canvas, 849, 114, 388, 524)
	local detail = Theme.frame(UDim2.new(1, -40, 1, -44), UDim2.fromOffset(20, 26), Theme.PANEL, 1)
	detail.Name = "Detail"
	detail.Parent = detailPanel
	local hints = Theme.hints(canvas, {})
	return {
		root = root,
		canvas = canvas,
		header = header,
		title = t,
		counter = counter,
		counterLabel = counterLabel,
		money = money,
		main = main,
		tabs = tabs,
		body = body,
		detail = detail,
		hints = hints,
	}
end

-- Tab strip: small caps; the current tab sits on a dark pill.
function Theme.setTabs(tabs: Frame, names: { string }, current: string, onPick: (string) -> ())
	clear(tabs)
	for i, name in names do
		local on = name == current
		local b = Theme.cell(UDim2.fromOffset(0, 22), if on then Theme.INNER else Theme.PANEL)
		b.AutomaticSize = Enum.AutomaticSize.X
		b.LayoutOrder = i
		Theme.corner(b, 4)
		local l = Theme.label(
			string.upper(name),
			10,
			if on then Theme.WHITE else Theme.MUTED,
			Theme.F.bold,
			UDim2.fromOffset(0, 22)
		)
		l.AutomaticSize = Enum.AutomaticSize.X
		l.Parent = b
		local p = Instance.new("UIPadding")
		p.PaddingLeft = UDim.new(0, 11)
		p.PaddingRight = UDim.new(0, 11)
		p.Parent = b
		b.Activated:Connect(function()
			onPick(name)
		end)
		b.Parent = tabs
	end
end

-- Detail-card heading: teal category, big name, grey description, optional thumbnail.
function Theme.detailHead(detail: Frame, category: string, name: string, text: string, thumb: GuiObject?): number
	local hasThumb = thumb ~= nil
	local w = if hasThumb then -104 else 0
	local cat = Theme.label(
		string.upper(category),
		10,
		Theme.TEAL,
		Theme.F.bold,
		UDim2.new(1, w, 0, 14),
		UDim2.fromOffset(0, 2)
	)
	cat.Parent = detail
	local n = Theme.label(name, 22, Theme.WHITE, Theme.F.heavy, UDim2.new(1, w, 0, 30), UDim2.fromOffset(0, 16))
	n.TextWrapped = true
	n.TextScaled = #name > 22
	n.Parent = detail
	local d = Theme.label(
		text,
		13,
		Color3.fromRGB(214, 218, 224),
		Theme.F.regular,
		UDim2.new(1, w, 0, 56),
		UDim2.fromOffset(0, 50)
	)
	d.TextWrapped = true
	d.TextYAlignment = Enum.TextYAlignment.Top
	d.Parent = detail
	if thumb then
		local box = Theme.inset(detail, UDim2.fromOffset(92, 92), UDim2.new(1, -92, 0, 0))
		thumb.Size = UDim2.fromScale(1, 1)
		thumb.Position = UDim2.new()
		thumb.Parent = box
	end
	return 140
end

---------------------------------------------------------------------------- legacy single card
-- A single centred panel with a title (Field Manual pages, teleport list, suit locker).
function Theme.card(gui: ScreenGui, title: string, category: string, size: UDim2): (Frame, Frame, TextButton)
	local root = Theme.frame(UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), Theme.PANEL, 1)
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Name = title
	root.Visible = false
	root.Parent = gui
	local canvas = Theme.canvas(root)
	local w, h = math.floor(1280 * size.X.Scale), math.floor(720 * size.Y.Scale)
	local card = Theme.panel(canvas, 640 - w / 2, 344 - h / 2, w, h)
	card.Name = "Card"
	local cat = Theme.label(
		string.upper(category),
		10,
		Theme.TEAL,
		Theme.F.bold,
		UDim2.new(0.7, 0, 0, 14),
		UDim2.fromOffset(22, 18)
	)
	cat.Parent = card
	local head = Theme.label(
		string.upper(title),
		24,
		Theme.WHITE,
		Theme.F.heavy,
		UDim2.new(0.75, 0, 0, 30),
		UDim2.fromOffset(22, 32)
	)
	head.Parent = card
	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Size = UDim2.fromOffset(44, 44)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -16, 0, 18)
	close.BackgroundColor3 = Theme.INNER
	close.Text = "×"
	close.TextColor3 = Theme.WHITE
	close.FontFace = Theme.F.bold
	close.TextSize = 26
	close.AutoButtonColor = false
	Theme.corner(close, 6)
	close.Parent = card
	Juice.bindButton(close)
	local body = Theme.frame(UDim2.new(1, -44, 1, -92), UDim2.fromOffset(22, 74), Theme.PANEL, 1)
	body.Name = "Body"
	body.Parent = card
	Theme.hints(canvas, { { "E", "Esc", "Leave" } })
	return root, body, close
end

---------------------------------------------------------------------------- numbers
-- Money like the original: "51.92", "1.07K", "2.40M" (the coin says it's dollars).
function Theme.cash(n: number): string
	if n >= 1e6 then
		return string.format("%.2fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.2fK", n / 1e3)
	end
	return string.format("%.2f", n)
end

-- Prices on tags and buttons: "$5", "$1,500", "$0.50".
function Theme.money(n: number): string
	if n >= 1e6 then
		return string.format("$%.2fM", n / 1e6)
	elseif n >= 1e5 then
		return string.format("$%.1fK", n / 1e3)
	elseif n >= 1000 then
		local whole = math.floor(n + 0.5)
		return string.format("$%d,%03d", whole // 1000, whole % 1000)
	elseif n == math.floor(n) then
		return string.format("$%d", n)
	end
	return string.format("$%.2f", n)
end

function Theme.kg(n: number): string
	if n >= 1000 then
		return string.format("%.2f T", n / 1000)
	elseif n >= 10 then
		return string.format("%.1f", n)
	end
	return string.format("%.2f", n)
end

-- A mass with its unit, switching to tonnes from 1000 kg ("40.0 kg", "1.20 t").
function Theme.mass(n: number): string
	if n >= 1000 then
		return string.format("%.2f t", n / 1000)
	end
	return Theme.kg(n) .. " kg"
end

-- Studs to metres for the UI (0.28 m per stud, as everywhere else in the game).
function Theme.metres(studs: number): string
	local m = studs * 0.28
	if m >= 1000 then
		return string.format("%.1f km", m / 1000)
	elseif m >= 10 then
		return string.format("%d m", math.floor(m + 0.5))
	end
	return string.format("%.1f m", m)
end

-- A scrolling list body with a vertical layout.
function Theme.list(parent: Instance, size: UDim2, pos: UDim2?, gap: number?): ScrollingFrame
	local s = Instance.new("ScrollingFrame")
	s.Size = size
	s.Position = pos or UDim2.new()
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 4
	s.ScrollBarImageColor3 = Theme.ORANGE
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.CanvasSize = UDim2.new()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, gap or 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = s
	s.Parent = parent
	return s
end

return Theme
