--!strict
-- 3D tilting settings panel (style reference: BuiltByBit "3d Dynamic Settings System", rebuilt from scratch).
-- Lives at StarterPlayerScripts.Settings3D; needs ReplicatedStorage.Screen3D. Open with M or the gear.
-- Tested in Studio 2026-10-23: renders sharp, tilts toward the cursor, dims the world, zero Output errors.
-- Clicks on toggles/sliders/tabs verified by Sharman by hand, 2026-10-23. v2: 2x canvas, no CanvasGroup (sharper).
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Screen3D = require(ReplicatedStorage:WaitForChild("Screen3D", 10) :: ModuleScript)
local player = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- Tokens --------------------------------------------------------------
local C = {
	panel = Color3.fromHex("#202126"),
	row = Color3.fromHex("#2A2B31"),
	track = Color3.fromHex("#3A3B42"),
	off = Color3.fromHex("#4A4B53"),
	accent = Color3.fromHex("#5AB8FF"),
	text = Color3.fromHex("#EDEDED"),
	dim = Color3.fromHex("#A9AAB2"),
	stroke = Color3.new(1, 1, 1),
}
local BOLD = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
local REG = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular)
local DESIGN_H = 900 -- layout is drawn at 900 px tall, then scaled to the screen

local function make(class: string, props: { [string]: any }, children: { Instance }?): any
	local o = Instance.new(class)
	for k, v in props do
		if k ~= "Parent" then
			(o :: any)[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = o
	end
	if props.Parent then
		o.Parent = props.Parent
	end
	return o
end
local function corner(r: number) return make("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function stroke(t: number, th: number?)
	return make("UIStroke", { Color = C.stroke, Transparency = t, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function tween(o: Instance, t: number, goals: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), goals)
	tw:Play()
	return tw
end
local function shadow(parent: Instance)
	-- UIShadow (full release 2026-06-23). Guarded so older clients just skip it.
	pcall(function()
		local s = Instance.new("UIShadow") :: any
		pcall(function() s.Color = Color3.new(0, 0, 0) end)
		pcall(function() s.Transparency = 0.45 end)
		pcall(function() s.BlurRadius = 30 end)
		pcall(function() s.Offset = Vector2.new(0, 10) end)
		s.Parent = parent
	end)
end

-- Settings state --------------------------------------------------------
local settings = {
	FOV = 70, TiltPower = 3, UITilt = true, CamSensitivity = 50, CamShake = true,
	Shadows = true, Potato = false, BlurBackground = true,
	Music = 60, SFX = 80,
	Colorblind = "Normal", FlashReduction = false, MotionReduction = false,
}
local DEFAULTS = table.clone(settings)

-- Surface ---------------------------------------------------------------
local screen = Screen3D.new("SettingsUI", settings.TiltPower)
local gui = screen.gui
gui.Enabled = false

local root = make("Frame", { Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = gui })
-- One UIScale on the window (scales around its centre anchor) = screen fit x open-pop.
local fitScale, popScale = 1, 0.92
local scaler: UIScale
local function applyScale() if scaler then scaler.Scale = fitScale * popScale end end
local function refit() fitScale = math.max(cam.ViewportSize.Y * Screen3D.RES, 1) / DESIGN_H; applyScale() end
local popValue = Instance.new("NumberValue")
popValue.Value = popScale
popValue.Changed:Connect(function(v) popScale = v; applyScale() end)

-- Background blur: DepthOfField focused on the panel distance, on the camera so only
-- this player sees it. The world blurs, the panel (a 3D surface) stays sharp.
local blur = make("DepthOfFieldEffect", {
	FocusDistance = Screen3D.DIST, InFocusRadius = 1, NearIntensity = 0, FarIntensity = 0, Enabled = true, Parent = cam,
})
-- DepthOfField is quality-gated (no blur on low graphics), so a dim plane just behind the
-- panel guarantees the world recedes on every device.
local dim = make("Part", {
	Name = "SettingsDim", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
	Material = Enum.Material.SmoothPlastic, Color = Color3.fromHex("#0B0C10"), Transparency = 1, Size = Vector3.new(200, 200, 0.05), Parent = cam,
})
game:GetService("RunService").RenderStepped:Connect(function()
	if dim.Transparency < 1 then dim.CFrame = cam.CFrame * CFrame.new(0, 0, -(Screen3D.DIST + 0.6)) end
end)

-- Window = title tab + panel. A plain Frame, not a CanvasGroup: CanvasGroups render to a
-- lower-res texture and looked soft (Sharman, 2026-10-23). Fading is done per element below.
local window = make("Frame", {
	Name = "Window", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(580, 450), Visible = false, Parent = root,
})
scaler = make("UIScale", { Parent = window })
applyScale()

local titleTab = make("Frame", {
	Name = "TitleTab", BackgroundColor3 = C.panel, Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(132, 40), Parent = window,
}, { corner(12), stroke(0.88) })
make("TextLabel", {
	BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -6), FontFace = REG, Text = "Settings", TextSize = 24,
	TextColor3 = C.text, Parent = titleTab,
})

local panel = make("Frame", {
	Name = "Panel", BackgroundColor3 = C.panel, BackgroundTransparency = 0.03, Position = UDim2.fromOffset(0, 32),
	Size = UDim2.new(1, 0, 1, -32), Parent = window,
}, { corner(20), stroke(0.86, 1.5) })
shadow(panel)
make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), Parent = panel })

-- Tabs --------------------------------------------------------------------
local TABS = { "Gameplay", "Graphics", "Sound", "Accessibility", "Info" }
local tabBar = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), Parent = panel }, {
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})
make("Frame", {
	BackgroundColor3 = C.stroke, BackgroundTransparency = 0.55, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 0, 1), Parent = panel,
}, { make("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.7, 0.6), NumberSequenceKeypoint.new(1, 1) }) }) })

local pages: { [string]: Frame } = {}
local tabButtons: { [string]: TextButton } = {}
local current = ""

local content = make("Frame", {
	Name = "Content", BackgroundTransparency = 1, ClipsDescendants = true, Position = UDim2.fromOffset(0, 48),
	Size = UDim2.new(1, 0, 1, -98), Parent = panel,
})

local function selectTab(name: string)
	if name == current then return end
	for n, b in tabButtons do
		local on = n == name
		tween(b, 0.18, { BackgroundTransparency = on and 0.86 or 1, TextColor3 = on and C.text or C.dim })
		tween(b:FindFirstChildOfClass("UIStroke") :: Instance, 0.18, { Transparency = on and 0.7 or 0.88 })
	end
	for n, p in pages do
		if n == name then
			p.Visible = true
			p.Position = UDim2.fromOffset(18, 0)
			tween(p, 0.24, { Position = UDim2.fromOffset(0, 0) })
		else
			p.Visible = false
		end
	end
	current = name
end

for i, name in TABS do
	local b = make("TextButton", {
		Name = name, LayoutOrder = i, AutoButtonColor = false, BackgroundColor3 = C.stroke, BackgroundTransparency = 1,
		Size = UDim2.fromOffset(name == "Accessibility" and 118 or 92, 32), FontFace = REG, Text = name, TextSize = name == "Accessibility" and 17 or 20,
		TextColor3 = C.dim, Parent = tabBar,
	}, { corner(10), stroke(0.88) })
	tabButtons[name] = b
	pages[name] = make("ScrollingFrame", {
		Name = name, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Visible = false,
		ScrollBarThickness = 3, ScrollBarImageColor3 = C.dim, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
		Parent = content,
	}, { make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }), make("UIPadding", { PaddingRight = UDim.new(0, 6) }) })
	b.Activated:Connect(function() selectTab(name) end)
end

-- Rows and controls -------------------------------------------------------
local applyFns: { [string]: (any) -> () } = {}
local refreshFns: { () -> () } = {}

local function row(page: string, label: string, order: number): Frame
	local r = make("Frame", {
		Name = label, LayoutOrder = order, BackgroundColor3 = C.row, Size = UDim2.new(1, 0, 0, 50), Parent = pages[page],
	}, { corner(12), stroke(0.9) })
	make("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 0), Size = UDim2.new(0.5, 0, 1, 0), FontFace = BOLD, Text = label,
		TextSize = 17, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, Parent = r,
	})
	local s = r:FindFirstChildOfClass("UIStroke") :: UIStroke
	r.MouseEnter:Connect(function() tween(s, 0.15, { Transparency = 0.78 }) end)
	r.MouseLeave:Connect(function() tween(s, 0.15, { Transparency = 0.9 }) end)
	return r
end

local function toggle(page: string, label: string, key: string, order: number)
	local r = row(page, label, order)
	local pill = make("TextButton", {
		AutoButtonColor = false, Text = "", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(52, 28), BackgroundColor3 = C.off, Parent = r,
	}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local knob = make("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = Color3.new(1, 1, 1), Parent = pill,
	}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local function draw(animate: boolean)
		local on = settings[key] == true
		local goals = { Position = on and UDim2.new(1, -25, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }
		local pg = { BackgroundColor3 = on and C.accent or C.off }
		if animate then tween(knob, 0.2, goals); tween(pill, 0.2, pg) else knob.Position = goals.Position; pill.BackgroundColor3 = pg.BackgroundColor3 end
	end
	pill.Activated:Connect(function()
		settings[key] = not settings[key]
		draw(true)
		local f = applyFns[key]; if f then f(settings[key]) end
	end)
	table.insert(refreshFns, function() draw(true) end)
	draw(false)
end

local function slider(page: string, label: string, key: string, minV: number, maxV: number, suffix: string, order: number)
	local r = row(page, label, order)
	local track = make("TextButton", {
		AutoButtonColor = false, Text = "", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(170, 28), BackgroundColor3 = C.track, Parent = r,
	}, { corner(8) })
	local fill = make("Frame", { BackgroundColor3 = C.accent, Size = UDim2.fromScale(0.5, 1), Parent = track }, { corner(8) })
	local knob = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 22),
		BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = track,
	}, { corner(6) })
	local value = make("TextLabel", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(46, 22),
		FontFace = BOLD, TextSize = 17, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4, Parent = track,
	})
	local span = 0.62 -- the fill uses the left 62% so the value text stays readable, like the reference
	local function draw(animate: boolean)
		local f = (settings[key] - minV) / (maxV - minV)
		local x = 0.06 + f * (span - 0.06)
		value.Text = tostring(math.floor(settings[key] + 0.5)) .. suffix
		if animate then
			tween(fill, 0.12, { Size = UDim2.fromScale(x, 1) }); tween(knob, 0.12, { Position = UDim2.fromScale(x, 0.5) })
		else
			fill.Size = UDim2.fromScale(x, 1); knob.Position = UDim2.fromScale(x, 0.5)
		end
	end
	local dragging = false
	local function setFrom(screenPos: Vector2)
		local p = screen:screenToCanvas(screenPos)
		if not p then return end
		local a = track.AbsolutePosition
		local sz = track.AbsoluteSize
		local x = math.clamp((p.X - a.X) / sz.X, 0.06, span)
		local f = (x - 0.06) / (span - 0.06)
		settings[key] = math.floor(minV + f * (maxV - minV) + 0.5)
		draw(true)
		local fn = applyFns[key]; if fn then fn(settings[key]) end
	end
	track.InputBegan:Connect(function(io)
		if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFrom(UserInputService:GetMouseLocation())
			tween(knob, 0.12, { Size = UDim2.fromOffset(20, 26) }, Enum.EasingStyle.Back)
		end
	end)
	UserInputService.InputChanged:Connect(function(io)
		if dragging and (io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch) then
			setFrom(UserInputService:GetMouseLocation())
		end
	end)
	UserInputService.InputEnded:Connect(function(io)
		if dragging and (io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			tween(knob, 0.15, { Size = UDim2.fromOffset(18, 22) })
		end
	end)
	table.insert(refreshFns, function() draw(true) end)
	draw(false)
end

local function choice(page: string, label: string, key: string, options: { string }, order: number)
	local r = row(page, label, order)
	local holder = make("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(300, 30),
		BackgroundTransparency = 1, Parent = r,
	}, { make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }) })
	local btns: { [string]: TextButton } = {}
	local function draw()
		for o, b in btns do
			local on = settings[key] == o
			tween(b, 0.18, { BackgroundTransparency = on and 0 or 1, TextColor3 = on and C.text or C.dim })
		end
	end
	for i, o in options do
		local b = make("TextButton", {
			LayoutOrder = i, AutoButtonColor = false, BackgroundColor3 = Color3.fromHex("#3E6F95"), BackgroundTransparency = 1,
			Size = UDim2.fromOffset(72, 30), FontFace = BOLD, Text = o, TextSize = 12, TextColor3 = C.dim, Parent = holder,
		}, { corner(8) })
		btns[o] = b
		b.Activated:Connect(function()
			settings[key] = o; draw()
			local fn = applyFns[key]; if fn then fn(o) end
		end)
	end
	table.insert(refreshFns, draw)
	draw()
end

local function card(page: string, title: string, body: string, order: number)
	local r = make("Frame", { LayoutOrder = order, BackgroundColor3 = C.row, Size = UDim2.new(1, 0, 0, 76), Parent = pages[page] }, { corner(12), stroke(0.9) })
	make("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 20), FontFace = BOLD, Text = title, TextSize = 17, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, Parent = r })
	make("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 34), Size = UDim2.new(1, -32, 0, 34), FontFace = REG, Text = body, TextSize = 15, TextColor3 = C.dim, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = r })
end

-- Build pages ------------------------------------------------------------
slider("Gameplay", "Field of View", "FOV", 50, 110, "°", 1)
slider("Gameplay", "Tilt Power", "TiltPower", 0, 6, "°", 2)
toggle("Gameplay", "UI Tilt", "UITilt", 3)
slider("Gameplay", "Camera Sensitivity", "CamSensitivity", 0, 100, "", 4)
toggle("Gameplay", "Camera Shake", "CamShake", 5)
toggle("Graphics", "Shadows", "Shadows", 1)
toggle("Graphics", "Potato Mode", "Potato", 2)
toggle("Graphics", "Blur Behind Menus", "BlurBackground", 3)
slider("Sound", "Music", "Music", 0, 100, "%", 1)
slider("Sound", "Sound Effects", "SFX", 0, 100, "%", 2)
choice("Accessibility", "Colorblind Mode", "Colorblind", { "Normal", "Deutan", "Protan", "Tritan" }, 1)
toggle("Accessibility", "Flash Reduction", "FlashReduction", 2)
toggle("Accessibility", "Motion Reduction", "MotionReduction", 3)
card("Info", "Credits", "Settings system: in-house. Style reference: 3D tilt panel pattern.", 1)
card("Info", "Version 1.0.0", "Settings apply instantly. Saving to the profile is wired on the server.", 2)

-- Apply ---------------------------------------------------------------------
local function effectiveTilt() return (settings.UITilt and not settings.MotionReduction) and settings.TiltPower or 0 end
applyFns.FOV = function(v) cam.FieldOfView = v end
applyFns.TiltPower = function() screen.tiltPower = effectiveTilt() end
applyFns.UITilt = applyFns.TiltPower
applyFns.MotionReduction = applyFns.TiltPower
applyFns.Shadows = function(v) Lighting.GlobalShadows = v end

-- Restore default ----------------------------------------------------------
local restore = make("TextButton", {
	AutoButtonColor = false, AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(150, 34),
	BackgroundColor3 = C.stroke, BackgroundTransparency = 0.88, FontFace = REG, Text = "Restore Default", TextSize = 17, TextColor3 = C.dim, Parent = panel,
}, { corner(10), stroke(0.8) })
restore.MouseEnter:Connect(function() tween(restore, 0.15, { BackgroundTransparency = 0.8, TextColor3 = C.text }) end)
restore.MouseLeave:Connect(function() tween(restore, 0.15, { BackgroundTransparency = 0.88, TextColor3 = C.dim }) end)
restore.Activated:Connect(function()
	for k, v in DEFAULTS do settings[k] = v end
	for _, f in refreshFns do f() end
	for k, f in applyFns do f(settings[k]) end
end)

-- Per-element fade (replaces CanvasGroup.GroupTransparency) -----------------
local fadeValue = Instance.new("NumberValue")
fadeValue.Value = 1
local function snapshot()
	local list = {}
	for _, d in window:GetDescendants() do
		local e: { [string]: number } = {}
		if d:IsA("GuiObject") then e.BackgroundTransparency = d.BackgroundTransparency end
		if d:IsA("TextLabel") or d:IsA("TextButton") then e.TextTransparency = d.TextTransparency end
		if d:IsA("ImageLabel") or d:IsA("ImageButton") then e.ImageTransparency = d.ImageTransparency end
		if d:IsA("UIStroke") then e.Transparency = d.Transparency end
		if next(e) then table.insert(list, { inst = d, base = e }) end
	end
	return list
end
local faders = {}
fadeValue.Changed:Connect(function(a)
	for _, f in faders do
		for prop, base in f.base do
			(f.inst :: any)[prop] = base + (1 - base) * a
		end
	end
end)

-- Open / close ----------------------------------------------------------------
local isOpen = false
local function setOpen(open: boolean)
	if open == isOpen then return end
	isOpen = open
	if open then
		refit()
		gui.Enabled = true
		if #faders == 0 then faders = snapshot() end -- first open: designed values; later opens reuse values saved at close
		window.Visible = true
		popValue.Value = 0.92
		tween(fadeValue, 0.25, { Value = 0 }, Enum.EasingStyle.Quad)
		tween(popValue, 0.38, { Value = 1 }, Enum.EasingStyle.Back)
		if settings.BlurBackground then
			tween(blur, 0.3, { FarIntensity = 0.85 }, Enum.EasingStyle.Quad)
			dim.CFrame = cam.CFrame * CFrame.new(0, 0, -(Screen3D.DIST + 0.6))
			tween(dim, 0.3, { Transparency = 0.5 }, Enum.EasingStyle.Quad)
		end
	else
		tween(blur, 0.22, { FarIntensity = 0 }, Enum.EasingStyle.Quad)
		tween(dim, 0.22, { Transparency = 1 }, Enum.EasingStyle.Quad)
		tween(popValue, 0.2, { Value = 0.94 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		faders = snapshot() -- current look (tabs, toggles) becomes the base to fade from
		for _, f in faders do
			for prop, v in f.base do
				if v >= 0.999 then f.base[prop] = 1 end
			end
		end
		fadeValue.Value = 0
		local t = tween(fadeValue, 0.2, { Value = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		t.Completed:Once(function() if not isOpen then window.Visible = false; gui.Enabled = false end end)
	end
end

-- Gear button (flat 2D, top-left under the Roblox buttons)
local hud = make("ScreenGui", { Name = "SettingsButton", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
local gear = make("ImageButton", {
	Name = "Gear", AutoButtonColor = false, Position = UDim2.fromOffset(16, 60), Size = UDim2.fromOffset(44, 44),
	BackgroundColor3 = C.panel, BackgroundTransparency = 0.15, Image = "rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab.png",
	ScaleType = Enum.ScaleType.Fit, Parent = hud,
}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(0.85), make("UIPadding", { PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9), PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }) })
gear.Activated:Connect(function() setOpen(not isOpen) end)
UserInputService.InputBegan:Connect(function(io, processed)
	if processed then return end
	if io.KeyCode == Enum.KeyCode.M then setOpen(not isOpen) end
	if io.KeyCode == Enum.KeyCode.Escape and isOpen then setOpen(false) end
end)
cam:GetPropertyChangedSignal("ViewportSize"):Connect(refit)

refit()
selectTab("Gameplay")
screen.tiltPower = effectiveTilt()
