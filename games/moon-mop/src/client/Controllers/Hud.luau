--!strict
-- The HUD, matched to the original's (P1 f_006, f_041, f_072, f_407). It has no panels; it
-- floats over the scene in small groups pinned to the screen edges, each scaled from the
-- 1280 x 720 reference frames:
--   top centre    thin compass ruler with a yellow marker, station / waypoint / flag icons
--   top right     sector ring with a hexagon, "SECTOR n", big "6.5%", "CLEANED" (teal at 100%)
--   right middle  key list with key caps
--   bottom left   dust jar, yellow tool tag, big "0.07 / 0.5 KG" (red FULL tag when full)
--   bottom right  amber money with the gold coin
--   bottom centre round tool-belt slots with 3D tool icons, control hints underneath
-- plus pill prompts that fill as you hold, toasts, "+$" popups and the vehicle speed. The HUD
-- hides while a menu is open. On touch screens the jar and money move clear of the thumbstick
-- and jump button and big Brush / Pack / Map buttons appear (CLAUDE.md rule 5).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Loadout = require(Shared:WaitForChild("Loadout"))
local Places = require(Shared:WaitForChild("Places"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Brooms = require(script.Parent.Brooms)
local Juice = require(script.Parent.Juice)
local MoonView = require(script.Parent.MoonView)
local Movement = require(script.Parent.Movement)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Theme)

local Hud = {}

local player = Players.LocalPlayer
local CENTRE = Config.Moon.Centre
local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
Hud.touch = touch

local toolIntent = Remotes.get("ToolIntent")
local packRemote = Remotes.get("Pack")

local gui: ScreenGui
local menuOpen = false
local buildMode = false
local jarGroup: Frame
local slotsGroup: Frame
local hintsGroup: Frame

local function refreshVisibility()
	if gui then
		gui.Enabled = not menuOpen
	end
	if jarGroup then
		jarGroup.Visible = not buildMode
		slotsGroup.Visible = not buildMode and State.get().vehicle == nil
		hintsGroup.Visible = not buildMode
	end
end

function Hud.setMenuOpen(open: boolean)
	menuOpen = open
	if open and State.get().toolOn then
		toolIntent:FireServer("off")
		Movement.setBrushing(false)
	end
	refreshVisibility()
end

function Hud.isMenuOpen(): boolean
	return menuOpen
end

-- Build mode takes the left mouse button and the touch screen for placing.
function Hud.setBuildMode(on: boolean)
	buildMode = on
	if on and State.get().toolOn then
		toolIntent:FireServer("off")
		Movement.setBrushing(false)
	end
	refreshVisibility()
end

---------------------------------------------------------------------------- scaled groups
local scales: { UIScale } = {}
local function fitScale(): number
	local cam = Workspace.CurrentCamera
	local v = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	return math.clamp(math.min(v.X / 1280, v.Y / 720), 0.56, 2)
end

-- A group of HUD pieces pinned to a screen point, laid out in design pixels.
local function group(name: string, anchor: Vector2, offset: Vector2, w: number, h: number): Frame
	local f = Theme.frame(UDim2.fromOffset(w, h), UDim2.new(anchor.X, offset.X, anchor.Y, offset.Y), Theme.PANEL, 1)
	f.Name = name
	f.AnchorPoint = anchor
	local s = Instance.new("UIScale")
	s.Scale = fitScale()
	s.Parent = f
	table.insert(scales, s)
	f.Parent = gui
	return f
end

local function rescale()
	local k = fitScale()
	for _, s in scales do
		s.Scale = k
	end
end

---------------------------------------------------------------------------- toasts and popups
local toastHolder: Frame
local function toast(text: string, color: Color3?)
	local t = Theme.label(text, 13, color or Theme.WHITE, Theme.F.semi, UDim2.fromOffset(0, 30))
	t.AutomaticSize = Enum.AutomaticSize.X
	t.TextXAlignment = Enum.TextXAlignment.Center
	t.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
	t.BackgroundTransparency = 0.25
	Theme.corner(t, 3)
	Theme.stroke(t, if color and color ~= Theme.WHITE then color else Color3.new(1, 1, 1), 1, 0.35)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, 14)
	p.PaddingRight = UDim.new(0, 14)
	p.Parent = t
	t.Parent = toastHolder
	Juice.popIn(t)
	task.delay(3.2, function()
		TweenService:Create(t, TweenInfo.new(0.3), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		local st = t:FindFirstChildOfClass("UIStroke")
		if st then
			TweenService:Create(st, TweenInfo.new(0.3), { Transparency = 1 }):Play()
		end
		task.wait(0.35)
		t:Destroy()
	end)
end
Hud.toast = toast

local popHolder: Frame
local function popup(text: string, color: Color3)
	local l = Theme.label(text, 34, color, Theme.F.heavy, UDim2.fromOffset(400, 44))
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.TextXAlignment = Enum.TextXAlignment.Center
	l.Position = UDim2.fromOffset(200 + (math.random() - 0.5) * 60, 60)
	local glow = Instance.new("UIStroke")
	glow.Thickness = 3
	glow.Color = color
	glow.Transparency = 0.7
	glow.Parent = l
	l.Parent = popHolder
	Juice.popIn(l)
	local reduced = GuiService.ReducedMotionEnabled
	TweenService:Create(l, TweenInfo.new(if reduced then 0.01 else 1.2, Enum.EasingStyle.Quad), {
		Position = l.Position - UDim2.fromOffset(0, 50),
	}):Play()
	task.delay(1.1, function()
		TweenService:Create(l, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		TweenService:Create(glow, TweenInfo.new(0.3), { Transparency = 1 }):Play()
		task.wait(0.35)
		l:Destroy()
	end)
end
Hud.popup = popup

---------------------------------------------------------------------------- compass
-- A thin ruler: ticks every 5 degrees, taller every 15, letters at N E S W (P1 f_041, f_074).
local COMPASS_W = 540
local COMPASS_DEG = 160 -- degrees shown across the ruler
type Mark = { holder: Frame, icon: Frame, glyph: TextLabel, dist: TextLabel }
local compass: Frame
local ticks: { { frame: Frame, deg: number, letter: TextLabel? } } = {}
local marks: { [string]: Mark } = {}

local function mark(key: string, glyph: string, color: Color3): Mark
	local existing = marks[key]
	if existing then
		return existing
	end
	local holder = Theme.frame(UDim2.fromOffset(40, 44), UDim2.new(), Theme.PANEL, 1)
	holder.AnchorPoint = Vector2.new(0.5, 0)
	local icon = Theme.frame(UDim2.fromOffset(18, 18), UDim2.fromOffset(11, 0), color)
	Theme.corner(icon, 9)
	icon.Parent = holder
	local g = Theme.label(glyph, 10, Theme.BLACK, Theme.F.bold, UDim2.fromScale(1, 1))
	g.TextXAlignment = Enum.TextXAlignment.Center
	g.Parent = icon
	local dist = Theme.label("", 9, Theme.WHITE, Theme.F.bold, UDim2.fromOffset(40, 12), UDim2.fromOffset(0, 20))
	dist.TextXAlignment = Enum.TextXAlignment.Center
	Theme.shadow(dist)
	dist.Parent = holder
	holder.Parent = compass
	local m: Mark = { holder = holder, icon = icon, glyph = g, dist = dist }
	marks[key] = m
	return m
end

local function bearingTo(here: Vector3, target: Vector3, fwd: Vector3, right: Vector3): number
	local t = target - here * target:Dot(here)
	if t.Magnitude < 1e-6 then
		return 0
	end
	return math.deg(math.atan2(t.Unit:Dot(right), t.Unit:Dot(fwd)))
end

local function updateCompass()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local here = (root.Position - CENTRE).Unit
	local view = Movement.viewFrame()
	local fwd = view.LookVector - here * view.LookVector:Dot(here)
	if fwd.Magnitude < 1e-4 then
		return
	end
	fwd = fwd.Unit
	local right = fwd:Cross(here)
	-- heading from local north (toward the North Station)
	local north = Places.stations[1].dir
	local tn = north - here * north:Dot(here)
	local heading = 0
	if tn.Magnitude > 1e-4 then
		tn = tn.Unit
		local te = tn:Cross(here)
		heading = math.deg(math.atan2(fwd:Dot(te), fwd:Dot(tn)))
	end
	for _, t in ticks do
		local d = ((t.deg - heading + 540) % 360) - 180
		local on = math.abs(d) <= COMPASS_DEG / 2
		t.frame.Visible = on
		if t.letter then
			t.letter.Visible = on
		end
		if on then
			local x = COMPASS_W / 2 + d / COMPASS_DEG * COMPASS_W
			t.frame.Position = UDim2.fromOffset(x, t.frame.Position.Y.Offset)
			if t.letter then
				t.letter.Position = UDim2.fromOffset(x - 10, 0)
				t.letter.TextTransparency = math.abs(d) / (COMPASS_DEG / 2) * 0.8
			end
		end
	end
	local seen: { [string]: boolean } = {}
	local function place(key: string, glyph: string, color: Color3, target: Vector3)
		local b = bearingTo(here, target, fwd, right)
		if math.abs(b) > COMPASS_DEG / 2 then
			return
		end
		local m = mark(key, glyph, color)
		m.holder.Position = UDim2.fromOffset(COMPASS_W / 2 + b / COMPASS_DEG * COMPASS_W, 38)
		m.holder.Visible = true
		m.dist.Text = string.format("%d m", math.floor(Places.arc(here, target) * 0.28))
		seen[key] = true
	end
	for _, st in Places.stations do
		if Places.arc(here, st.dir) < 2600 then
			place("s" .. st.index, "⌂", Theme.YELLOW, st.dir)
		end
	end
	local s = State.get()
	for i, w in s.waypoints or {} do
		place("w" .. i, "◆", Theme.RED, Vector3.new(w[1], w[2], w[3]))
	end
	if s.fx and s.fx.flagPct then
		local shown = 0
		for i, f in Places.flags do
			if not (s.flags and s.flags[tostring(i)]) and Places.arc(here, f) < 600 and shown < 5 then
				shown += 1
				place("f" .. i, "⚑", Theme.WHITE, f)
			end
		end
	end
	for key, m in marks do
		if not seen[key] then
			m.holder.Visible = false
		end
	end
end

local function buildCompass()
	compass = group("Compass", Vector2.new(0.5, 0), Vector2.new(0, 12), COMPASS_W, 90)
	compass.ClipsDescendants = false
	local line = Theme.frame(UDim2.fromOffset(COMPASS_W, 1), UDim2.fromOffset(0, 30), Theme.WHITE, 0.35)
	line.Parent = compass
	for deg = 0, 355, 5 do
		local major = deg % 15 == 0
		local t = Theme.frame(
			UDim2.fromOffset(1, if major then 9 else 5),
			UDim2.fromOffset(0, if major then 21 else 25),
			Theme.WHITE,
			if major then 0.1 else 0.45
		)
		t.Parent = compass
		local letter: TextLabel? = nil
		if deg % 90 == 0 then
			local name = if deg == 0 then "N" elseif deg == 90 then "E" elseif deg == 180 then "S" else "W"
			local l = Theme.label(name, 10, Theme.WHITE, Theme.F.bold, UDim2.fromOffset(20, 14), UDim2.new())
			l.TextXAlignment = Enum.TextXAlignment.Center
			Theme.shadow(l)
			l.Parent = compass
			letter = l
		end
		table.insert(ticks, { frame = t, deg = deg, letter = letter })
	end
	local marker = Theme.label(
		"▼",
		10,
		Theme.YELLOW,
		Theme.F.bold,
		UDim2.fromOffset(16, 12),
		UDim2.fromOffset(COMPASS_W / 2 - 8, 8)
	)
	marker.TextXAlignment = Enum.TextXAlignment.Center
	marker.Parent = compass
end

---------------------------------------------------------------------------- sector ring
local RING_N = 40
local ringSegs: { Frame } = {}
local ringId: TextLabel
local ringPct: TextLabel
local ringLabel: TextLabel
local ringHex: TextLabel

local function buildRing()
	local g = group("Sector", Vector2.new(1, 0), Vector2.new(-70, 20), 190, 50)
	local ring = Theme.frame(UDim2.fromOffset(44, 44), UDim2.fromOffset(0, 3), Theme.PANEL, 1)
	ring.Parent = g
	for i = 1, RING_N do
		local a = (i - 0.5) / RING_N * math.pi * 2
		local seg = Theme.frame(
			UDim2.fromOffset(2, 5),
			UDim2.fromOffset(22 + math.sin(a) * 19, 22 - math.cos(a) * 19),
			Color3.fromRGB(150, 156, 166)
		)
		seg.AnchorPoint = Vector2.new(0.5, 0.5)
		seg.Rotation = math.deg(a)
		seg.Parent = ring
		table.insert(ringSegs, seg)
	end
	ringHex = Theme.label("⬡", 17, Theme.WHITE, Theme.F.bold, UDim2.fromScale(1, 1))
	ringHex.TextXAlignment = Enum.TextXAlignment.Center
	Theme.shadow(ringHex)
	ringHex.Parent = ring
	ringId = Theme.label("SECTOR", 8, Theme.MUTED, Theme.F.bold, UDim2.fromOffset(140, 11), UDim2.fromOffset(52, 3))
	Theme.shadow(ringId)
	ringId.Parent = g
	ringPct = Theme.label("0%", 20, Theme.WHITE, Theme.F.heavy, UDim2.fromOffset(140, 24), UDim2.fromOffset(51, 13))
	ringPct.RichText = true
	Theme.shadow(ringPct)
	ringPct.Parent = g
	ringLabel =
		Theme.label("CLEANED", 8, Theme.MUTED, Theme.F.bold, UDim2.fromOffset(140, 11), UDim2.fromOffset(52, 37))
	Theme.shadow(ringLabel)
	ringLabel.Parent = g
end

local function updateRing()
	local s = MoonView.current()
	if s < 0 then
		return
	end
	local prog = MoonView.progress(s)
	local doneNow = MoonView.isDone(s)
	local lit = math.floor(prog * RING_N + 1e-6)
	local color = if doneNow then Theme.TEAL else Color3.fromRGB(255, 170, 30)
	for i, d in ringSegs do
		d.BackgroundColor3 = if i <= lit then color else Color3.fromRGB(150, 156, 166)
		d.BackgroundTransparency = if i <= lit then 0 else 0.35
	end
	local pct = prog * 100
	ringPct.Text = string.format(
		'%s<font size="14">%%</font>',
		if doneNow then "100" elseif pct < 10 then string.format("%.1f", pct) else tostring(math.floor(pct))
	)
	ringPct.TextColor3 = if doneNow then Theme.TEAL else Theme.WHITE
	ringId.Text = string.format("SECTOR %d", s)
	ringLabel.Text = if doneNow then "SECTOR COMPLETE" else "CLEANED"
	ringLabel.TextColor3 = if doneNow then Theme.TEAL else Theme.MUTED
	ringHex.TextColor3 = if doneNow then Theme.TEAL else Theme.WHITE
end

---------------------------------------------------------------------------- key list
local keyList: Frame
local lastKeysKey = ""
local function rebuildKeys(s: { [string]: any })
	if touch then
		return
	end
	local rows = {
		{ "FIELD MANUAL", "H" },
		{ "SUIT", "C" },
	}
	if s.buildTool then
		table.insert(rows, { "BUILD", "B" })
	end
	table.insert(rows, { "MAP", "M" })
	table.insert(rows, { "POD", "Q" })
	table.insert(rows, { "LAMP", "L" })
	local key = ""
	for _, r in rows do
		key ..= r[1]
	end
	if key == lastKeysKey then
		return
	end
	lastKeysKey = key
	Theme.clear(keyList)
	for i, r in rows do
		local y = (i - 1) * 31
		local l = Theme.label(
			r[1],
			9,
			Color3.fromRGB(226, 230, 236),
			Theme.F.bold,
			UDim2.fromOffset(140, 18),
			UDim2.fromOffset(0, y)
		)
		l.TextXAlignment = Enum.TextXAlignment.Right
		Theme.shadow(l)
		l.Parent = keyList
		local cap = Theme.keycap(r[2])
		cap.Size = UDim2.fromOffset(18, 18)
		cap.Position = UDim2.fromOffset(148, y)
		cap.Parent = keyList
	end
end

---------------------------------------------------------------------------- jar, money, belt
local jarFill: Frame
local jarText: TextLabel
local toolTag: TextLabel
local fullTag: TextLabel
local podsText: TextLabel
local moneyText: TextLabel
local beltRow: Frame
local packButton: TextButton?
local brushButton: TextButton?
local vehicleGroup: Frame
local vehicleSpeed: TextLabel
local vehicleStatus: TextLabel
local controlHints: Frame

local function buildJar(anchor: Vector2, offset: Vector2)
	jarGroup = group("Jar", anchor, offset, 330, 82)
	local jar = Theme.frame(UDim2.fromOffset(40, 78), UDim2.fromOffset(0, 2), Color3.fromRGB(20, 22, 26), 0.55)
	Theme.corner(jar, 6)
	Theme.stroke(jar, Color3.fromRGB(214, 218, 224), 2, 0.15)
	jar.ClipsDescendants = true
	jar.Parent = jarGroup
	jarFill = Theme.frame(UDim2.fromScale(1, 0), UDim2.fromScale(0, 1), Color3.fromRGB(226, 228, 234))
	jarFill.AnchorPoint = Vector2.new(0, 1)
	jarFill.Parent = jar
	toolTag =
		Theme.label("TOOTHBRUSH", 10, Theme.BLACK, Theme.F.heavy, UDim2.fromOffset(0, 16), UDim2.fromOffset(56, 6))
	toolTag.AutomaticSize = Enum.AutomaticSize.X
	toolTag.BackgroundTransparency = 0
	toolTag.BackgroundColor3 = Theme.YELLOW
	Theme.corner(toolTag, 3)
	local tp = Instance.new("UIPadding")
	tp.PaddingLeft = UDim.new(0, 6)
	tp.PaddingRight = UDim.new(0, 6)
	tp.Parent = toolTag
	toolTag.Parent = jarGroup
	podsText = Theme.label("", 9, Theme.WHITE, Theme.F.bold, UDim2.fromOffset(160, 16), UDim2.fromOffset(170, 6))
	Theme.shadow(podsText)
	podsText.Parent = jarGroup
	jarText = Theme.label("0.00", 34, Theme.WHITE, Theme.F.bold, UDim2.fromOffset(280, 40), UDim2.fromOffset(54, 24))
	jarText.RichText = true
	Theme.shadow(jarText, 0.5)
	jarText.Parent = jarGroup
	fullTag = Theme.label("FULL", 10, Theme.WHITE, Theme.F.heavy, UDim2.fromOffset(44, 16), UDim2.fromOffset(56, 64))
	fullTag.BackgroundTransparency = 0
	fullTag.BackgroundColor3 = Theme.RED
	fullTag.TextXAlignment = Enum.TextXAlignment.Center
	fullTag.Visible = false
	Theme.corner(fullTag, 3)
	fullTag.Parent = jarGroup
end

local function buildMoney(anchor: Vector2, offset: Vector2)
	local g = group("Money", anchor, offset, 260, 44)
	moneyText = Theme.label("0.00", 34, Theme.AMBER, Theme.F.bold, UDim2.fromOffset(210, 44), UDim2.new())
	moneyText.TextXAlignment = Enum.TextXAlignment.Right
	Theme.amber(moneyText)
	moneyText.Parent = g
	Theme.coin(g, 36, UDim2.fromOffset(220, 4))
end

local slotButtons: { GuiObject } = {}
local function rebuildBelt()
	local s = State.get()
	for _, b in slotButtons do
		b:Destroy()
	end
	table.clear(slotButtons)
	for i = 1, s.slots or 1 do
		local id = (s.belt or {})[i]
		local active = i == (s.equipped or 1)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(60, 60)
		b.BackgroundColor3 = Color3.fromRGB(38, 40, 46)
		b.BackgroundTransparency = 0.25
		b.AutoButtonColor = false
		b.Text = ""
		b.LayoutOrder = i
		Theme.corner(b, 30)
		Theme.stroke(
			b,
			if active then Theme.ORANGE else Theme.WHITE,
			if active then 3 else 2,
			if active then 0 else 0.35
		)
		if id and Loadout.tool(id) then
			local vp = Theme.icon3d(Brooms.model(id), UDim2.fromOffset(48, 48), UDim2.fromOffset(6, 6), 60, 20, -50)
			Theme.corner(vp, 24)
			vp.Parent = b
		end
		if not touch then
			local key = Theme.label(
				tostring(i),
				9,
				Theme.WHITE,
				Theme.F.bold,
				UDim2.fromOffset(14, 14),
				UDim2.fromOffset(-2, -4)
			)
			Theme.shadow(key)
			key.Parent = b
		end
		b.Activated:Connect(function()
			toolIntent:FireServer("equip", i)
		end)
		Juice.bindButton(b)
		b.Parent = beltRow
		table.insert(slotButtons, b)
	end
end

local lastBeltKey = ""
local lastMoney = 0
local function onState(s: { [string]: any })
	local def = Loadout.tool(s.tool or "Toothbrush")
	local inVehicle = s.vehicle ~= nil
	local pack, packMax = s.pack or 0, s.packMax or 1
	if inVehicle then
		pack, packMax = s.tank or 0, math.max(s.tankMax or 1, 1e-6)
	end
	toolTag.Text = if inVehicle then "VEHICLE DUST" else string.upper(if def then def.name else "Tool")
	local frac = math.clamp(pack / math.max(packMax, 1e-6), 0, 1)
	TweenService:Create(jarFill, TweenInfo.new(0.15), { Size = UDim2.fromScale(1, frac) }):Play()
	local full = frac >= 0.999
	jarText.Text = string.format(
		'%s<font size="17"> / %s KG</font>',
		Theme.kg(pack),
		if packMax >= 1000 then string.format("%d", math.floor(packMax)) else Theme.kg(packMax)
	)
	jarText.TextColor3 = if full then Color3.fromRGB(255, 80, 70) else Theme.WHITE
	jarFill.BackgroundColor3 = if full then Theme.RED else Color3.fromRGB(226, 228, 234)
	fullTag.Visible = full
	podsText.Text = string.format(
		"PODS %d / %d%s",
		s.pods or 0,
		s.carry or 3,
		if (s.packStar or 0) > 0.005 then string.format("   ✦ %s", Theme.kg(s.packStar)) else ""
	)
	moneyText.Text = Theme.cash(s.money or 0)
	if (s.money or 0) > lastMoney + 0.001 and State.ready() then
		moneyText.TextSize = 38
		TweenService:Create(moneyText, TweenInfo.new(0.2), { TextSize = 34 }):Play()
	end
	lastMoney = s.money or 0
	local beltKey = table.concat(s.belt or {}, ",") .. "|" .. tostring(s.slots) .. "|" .. tostring(s.equipped)
	if beltKey ~= lastBeltKey then
		lastBeltKey = beltKey
		rebuildBelt()
	end
	rebuildKeys(s)
	if packButton then
		packButton.Text = if frac > 0.8 then "PACK IT!" else "PACK"
		packButton.BackgroundColor3 = if frac > 0.8 then Theme.ORANGE else Theme.ROW
	end
	if brushButton then
		brushButton.BackgroundColor3 = if s.toolOn then Theme.YELLOW else Theme.ROW
		brushButton.TextColor3 = if s.toolOn then Theme.BLACK else Theme.WHITE
	end
	Movement.setBrushing(s.toolOn == true)
	-- vehicle readout (P1 f_407): big speed, small KM/H, yellow status words
	vehicleGroup.Visible = inVehicle
	if inVehicle then
		local v = Loadout.vehicle(s.vehicle)
		local words = { string.upper(if v then v.name else "") }
		if v and v.cleans then
			table.insert(words, if s.toolOn then "SWEEPING" else "SWEEPER OFF")
		end
		if (s.dial or 0) > 0 then
			table.insert(words, string.format("SUCTION %d", s.dial))
		end
		vehicleStatus.Text = table.concat(words, "  ·  ")
	end
	Theme.setHints(
		controlHints,
		if inVehicle
			then { { "Shift", "Boost" }, { "LMB", "Cleaning" }, { "L", "Lights" }, { "F", "Exit" } }
			else { { "LMB", "Clean" }, { "Q", "Pack pod" }, { "E", "Use" }, { "C", "Suit" } }
	)
	for _, item in controlHints:GetChildren() do
		for _, d in item:GetDescendants() do
			if d:IsA("TextLabel") and d.TextSize == 13 then
				d.TextSize = 10
			end
		end
	end
	refreshVisibility()
end

---------------------------------------------------------------------------- prompts
-- A dark pill with the key and the action (P1 f_004, f_019); it fills yellow while you hold.
local function promptUi(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
	local holderGui = player:WaitForChild("PlayerGui")
	local bb = Instance.new("BillboardGui")
	bb.Name = "Prompt"
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(260, 40)
	bb.StudsOffset = Vector3.new(0, 1.2, 0)
	bb.Adornee = prompt.Parent :: Instance
	bb.Active = true
	bb.Parent = holderGui
	local pill = Instance.new("CanvasGroup")
	pill.Size = UDim2.fromOffset(0, 32)
	pill.AutomaticSize = Enum.AutomaticSize.X
	pill.AnchorPoint = Vector2.new(0.5, 0.5)
	pill.Position = UDim2.fromScale(0.5, 0.5)
	pill.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
	pill.BackgroundTransparency = 0.3
	pill.BorderSizePixel = 0
	Theme.corner(pill, 16)
	pill.Parent = bb
	local bar = Theme.frame(UDim2.new(0, 0, 1, 0), UDim2.new(), Theme.YELLOW, 0.2)
	bar.ZIndex = 0
	bar.Parent = pill
	local row = Theme.frame(UDim2.fromOffset(0, 32), UDim2.new(), Theme.PANEL, 1)
	row.AutomaticSize = Enum.AutomaticSize.X
	local rl = Instance.new("UIListLayout")
	rl.FillDirection = Enum.FillDirection.Horizontal
	rl.VerticalAlignment = Enum.VerticalAlignment.Center
	rl.Padding = UDim.new(0, 8)
	rl.Parent = row
	local rp = Instance.new("UIPadding")
	rp.PaddingLeft = UDim.new(0, 6)
	rp.PaddingRight = UDim.new(0, 14)
	rp.Parent = row
	row.Parent = pill
	local keyText = if inputType == Enum.ProximityPromptInputType.Touch
		then "TAP"
		elseif inputType == Enum.ProximityPromptInputType.Gamepad then "X"
		else prompt.KeyboardKeyCode.Name
	local key = Instance.new("TextButton")
	key.Size = UDim2.fromOffset(math.max(22, 10 + #keyText * 8), 22)
	key.BackgroundColor3 = Theme.WHITE
	key.TextColor3 = Theme.BLACK
	key.FontFace = Theme.F.heavy
	key.TextSize = 12
	key.AutoButtonColor = false
	key.Text = keyText
	key.LayoutOrder = 1
	Theme.corner(key, 4)
	key.Parent = row
	local action = Theme.label(
		if prompt.ObjectText ~= "" then prompt.ObjectText .. ": " .. prompt.ActionText else prompt.ActionText,
		13,
		Theme.WHITE,
		Theme.F.semi,
		UDim2.fromOffset(0, 32)
	)
	action.AutomaticSize = Enum.AutomaticSize.X
	action.LayoutOrder = 2
	action.Parent = row
	local tween: Tween? = nil
	local c1 = prompt.PromptButtonHoldBegan:Connect(function()
		bar.Size = UDim2.new(0, 0, 1, 0)
		tween = TweenService:Create(
			bar,
			TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear),
			{ Size = UDim2.new(1, 0, 1, 0) }
		);
		(tween :: Tween):Play()
	end)
	local c2 = prompt.PromptButtonHoldEnded:Connect(function()
		if tween then
			tween:Cancel()
		end
		bar.Size = UDim2.new(0, 0, 1, 0)
	end)
	local c3 = prompt.Triggered:Connect(function()
		pill.BackgroundColor3 = Theme.GREEN
		pill.BackgroundTransparency = 0.05
	end)
	key.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			prompt:InputHoldBegin()
		end
	end)
	key.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			prompt:InputHoldEnd()
		end
	end)
	prompt.PromptHidden:Once(function()
		c1:Disconnect()
		c2:Disconnect()
		c3:Disconnect()
		bb:Destroy()
	end)
end

---------------------------------------------------------------------------- input
local function setBrush(on: boolean)
	if menuOpen and on then
		return
	end
	if (State.get().toolOn == true) ~= on then
		toolIntent:FireServer(if on then "on" else "off")
		Movement.setBrushing(on)
	end
end
Hud.setBrush = setBrush

local function pack()
	packRemote:FireServer()
	Juice.playSound("rbxasset://sounds/electronicpingshort.wav", 0.4)
end

local function bindInput()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or menuOpen then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
			if not buildMode then
				setBrush(true)
			end
		elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonX then
			pack()
		elseif input.KeyCode.Value >= Enum.KeyCode.One.Value and input.KeyCode.Value <= Enum.KeyCode.Six.Value then
			toolIntent:FireServer("equip", input.KeyCode.Value - Enum.KeyCode.One.Value + 1)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
			setBrush(false)
		end
	end)
end

---------------------------------------------------------------------------- build
function Hud.start()
	gui = Theme.screen("Hud", player:WaitForChild("PlayerGui"), 1)

	buildCompass()
	buildRing()

	toastHolder = group("Toasts", Vector2.new(0.5, 0), Vector2.new(0, 0), 600, 200)
	toastHolder.Position = UDim2.new(0.5, 0, 0.6, 0)
	local tl = Instance.new("UIListLayout")
	tl.Padding = UDim.new(0, 6)
	tl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tl.Parent = toastHolder
	popHolder = group("Popups", Vector2.new(0.5, 0.5), Vector2.new(0, 0), 400, 120)
	popHolder.Position = UDim2.new(0.5, 0, 0.4, 0)

	-- a small dot in the middle of the view (first person aiming)
	local dot = Theme.frame(UDim2.fromOffset(4, 4), UDim2.fromScale(0.5, 0.5), Theme.WHITE, 0.3)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	Theme.corner(dot, 2)
	dot.Parent = gui

	if touch then
		buildJar(Vector2.new(0, 0), Vector2.new(16, 120))
		buildMoney(Vector2.new(0, 0), Vector2.new(16, 64))
	else
		buildJar(Vector2.new(0, 1), Vector2.new(38, -40))
		buildMoney(Vector2.new(1, 1), Vector2.new(-38, -44))
	end

	slotsGroup = group("Belt", Vector2.new(0.5, 1), Vector2.new(0, if touch then -110 else -42), 420, 64)
	beltRow = Theme.frame(UDim2.fromScale(1, 1), nil, Theme.PANEL, 1)
	local bl = Instance.new("UIListLayout")
	bl.FillDirection = Enum.FillDirection.Horizontal
	bl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	bl.VerticalAlignment = Enum.VerticalAlignment.Center
	bl.Padding = UDim.new(0, 12)
	bl.Parent = beltRow
	beltRow.Parent = slotsGroup

	hintsGroup = group("Controls", Vector2.new(0.5, 1), Vector2.new(0, -8), 700, 24)
	controlHints = Theme.hints(hintsGroup, {}, 12, 350)
	controlHints.Visible = not touch

	-- vehicle speed readout (shown while driving)
	vehicleGroup = group("Vehicle", Vector2.new(0.5, 1), Vector2.new(0, if touch then -110 else -40), 400, 90)
	vehicleGroup.Visible = false
	vehicleSpeed = Theme.label("0", 54, Theme.WHITE, Theme.F.heavy, UDim2.fromOffset(200, 56), UDim2.fromOffset(100, 0))
	vehicleSpeed.TextXAlignment = Enum.TextXAlignment.Center
	Theme.shadow(vehicleSpeed, 0.5)
	vehicleSpeed.Parent = vehicleGroup
	local kmh = Theme.label("KM/H", 12, Theme.WHITE, Theme.F.bold, UDim2.fromOffset(60, 16), UDim2.fromOffset(260, 32))
	Theme.shadow(kmh)
	kmh.Parent = vehicleGroup
	vehicleStatus = Theme.label("", 11, Theme.YELLOW, Theme.F.bold, UDim2.fromOffset(400, 16), UDim2.fromOffset(0, 58))
	vehicleStatus.TextXAlignment = Enum.TextXAlignment.Center
	Theme.shadow(vehicleStatus)
	vehicleStatus.Parent = vehicleGroup
	Hud.vehicleSpeed = vehicleSpeed
	Hud.vehicleStatus = vehicleStatus

	if touch then
		local col = group("TouchButtons", Vector2.new(1, 1), Vector2.new(-12, -170), 90, 220)
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 10)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		layout.Parent = col
		local b1 = Theme.button("BRUSH", UDim2.fromOffset(84, 60), "Dark")
		b1.Activated:Connect(function()
			setBrush(not State.get().toolOn)
		end)
		b1.Parent = col
		brushButton = b1
		local b2 = Theme.button("PACK", UDim2.fromOffset(84, 60), "Dark")
		b2.Activated:Connect(pack)
		b2.Parent = col
		packButton = b2
		local b3 = Theme.button("MAP", UDim2.fromOffset(84, 48), "Dark")
		b3.Activated:Connect(function()
			State.emit("OpenMenu", "map")
		end)
		b3.Parent = col
	else
		keyList = group("Keys", Vector2.new(1, 0.5), Vector2.new(-84, -40), 166, 200)
	end

	local cam = Workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	end

	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style == Enum.ProximityPromptStyle.Custom then
			promptUi(prompt, inputType)
		end
	end)

	State.changed(onState)
	State.onFeedback(function(kind: string, data: any)
		if kind == "Earned" then
			popup("+$" .. Theme.cash(data.amount), if data.reason == "Sector" then Theme.MINT else Theme.AMBER)
			if data.reason == "Launch" then
				toast(string.format("Pods launched: +%s", Theme.money(data.amount)), Theme.AMBER)
			elseif data.reason == "Region" then
				toast("REGION COMPLETE  +" .. Theme.money(data.amount), Theme.TEAL)
			end
			Juice.playSound("rbxasset://sounds/electronicpingshort.wav", 0.5)
		elseif kind == "Error" then
			toast(data.text, Theme.RED)
		elseif kind == "PackFull" then
			toast("FULL  ·  Q  Pack pod", Theme.RED)
		elseif kind == "Packed" then
			toast(string.format("Packed a %s kg pod%s", Theme.kg(data.kg), if data.auto then " (Auto Packer)" else ""))
		elseif kind == "Bought" then
			Juice.playSound("rbxasset://sounds/electronicpingshort.wav", 0.6)
			toast("Bought", Theme.GREEN)
		elseif kind == "Achievement" then
			toast("ACHIEVEMENT  ·  " .. string.upper(data.name), Theme.YELLOW)
		elseif kind == "SectorDone" then
			Juice.shakeCamera(0.15)
		elseif kind == "Find" then
			if data.kind == "flag" then
				toast(string.format("Flag untangled  %d / %d", data.count, data.total), Theme.ORANGE)
			else
				toast(string.format("Probe surveyed  %d / %d", data.count, data.total), Theme.YELLOW)
			end
		elseif kind == "Toast" then
			toast(data.text, data.color or Theme.WHITE)
		elseif kind == "Away" then
			local hours = math.floor(data.minutes / 60)
			toast(
				string.format(
					"While you were away (%s) your base earned %s",
					if hours > 0 then string.format("%dh %dm", hours, data.minutes % 60) else data.minutes .. "m",
					Theme.money(data.amount)
				),
				Theme.TEAL
			)
		end
	end)
	bindInput()

	local accum = 0
	RunService.Heartbeat:Connect(function(dt)
		accum += dt
		updateCompass()
		if accum > 0.15 then
			accum = 0
			updateRing()
		end
	end)
end

return Hud
