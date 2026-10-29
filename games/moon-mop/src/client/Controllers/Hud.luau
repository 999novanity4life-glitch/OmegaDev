--!strict
-- The HUD, laid out like the original (P1 f_006, f_041, f_407; P3 f_195; P4 f_014):
--   top centre    compass ruler with station, waypoint and flag icons and distances
--   top right     sector ring with % cleaned, yellow while working, teal "COMPLETE" at 100%
--   bottom left   dust jar gauge, yellow tool tag, big "x / y KG" that turns red when full
--   bottom right  amber money with a gold coin
--   bottom centre round tool-belt slots (up to 6)
-- plus hold-to-fill prompts that fill yellow left to right, a key list, toasts and "+$" popups.
-- On touch screens the jar and money move clear of the thumbstick and jump button and big
-- Brush / Pack / Map buttons appear (CLAUDE.md rule 5). Also handles brush/pack/slot input.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Loadout = require(Shared:WaitForChild("Loadout"))
local Places = require(Shared:WaitForChild("Places"))
local Remotes = require(Shared:WaitForChild("Remotes"))

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

function Hud.setMenuOpen(open: boolean)
	menuOpen = open
	if open and State.get().toolOn then
		toolIntent:FireServer("off")
		Movement.setBrushing(false)
	end
end

function Hud.isMenuOpen(): boolean
	return menuOpen
end

---------------------------------------------------------------------------- toasts and popups
local toastHolder: Frame
local function toast(text: string, color: Color3?)
	local t = Theme.text(text, UDim2.new(1, 0, 0, 30), color or Theme.WHITE, Enum.Font.GothamBold, 22)
	t.TextXAlignment = Enum.TextXAlignment.Center
	t.BackgroundColor3 = Theme.SLATE
	t.BackgroundTransparency = 0.2
	Theme.corner(t, 6)
	t.Parent = toastHolder
	Juice.popIn(t)
	task.delay(3.2, function()
		TweenService:Create(t, TweenInfo.new(0.3), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		task.wait(0.35)
		t:Destroy()
	end)
end
Hud.toast = toast

local function popup(text: string, color: Color3)
	local l = Theme.text(text, UDim2.new(0.3, 0, 0, 40), color, Enum.Font.GothamBlack, 38)
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.TextXAlignment = Enum.TextXAlignment.Center
	l.Position = UDim2.fromScale(0.5 + (math.random() - 0.5) * 0.1, 0.42)
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = Theme.BLACK
	s.Parent = l
	l.Parent = gui
	Juice.popIn(l)
	local reduced = GuiService.ReducedMotionEnabled
	TweenService:Create(l, TweenInfo.new(if reduced then 0.01 else 1.2, Enum.EasingStyle.Quad), {
		Position = l.Position - UDim2.fromScale(0, 0.12),
	}):Play()
	task.delay(1.1, function()
		TweenService:Create(l, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		TweenService:Create(s, TweenInfo.new(0.3), { Transparency = 1 }):Play()
		task.wait(0.35)
		l:Destroy()
	end)
end
Hud.popup = popup

---------------------------------------------------------------------------- compass
type Mark = { label: TextLabel, dist: TextLabel, holder: Frame }
local compass: Frame
local marks: { [string]: Mark } = {}

local function mark(key: string, glyph: string, color: Color3): Mark
	local existing = marks[key]
	if existing then
		return existing
	end
	local holder = Theme.frame(UDim2.new(0, 46, 1, 0), UDim2.new(), Theme.SLATE, 1)
	holder.AnchorPoint = Vector2.new(0.5, 0)
	local label = Theme.text(glyph, UDim2.new(1, 0, 0.55, 0), color, Enum.Font.GothamBlack, 22)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Parent = holder
	local dist = Theme.text("", UDim2.new(1, 0, 0.4, 0), Theme.MUTED, Enum.Font.GothamBold, 13)
	dist.Position = UDim2.fromScale(0, 0.58)
	dist.TextXAlignment = Enum.TextXAlignment.Center
	dist.Parent = holder
	holder.Parent = compass
	local m: Mark = { label = label, dist = dist, holder = holder }
	marks[key] = m
	return m
end

local HEADINGS: { { name: string, deg: number } } =
	{ { name = "N", deg = 0 }, { name = "E", deg = 90 }, { name = "S", deg = 180 }, { name = "W", deg = 270 } }

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
	local seen: { [string]: boolean } = {}
	local function place(key: string, glyph: string, color: Color3, target: Vector3, showDist: boolean)
		local b = bearingTo(here, target, fwd, right)
		if math.abs(b) > 80 then
			return
		end
		local m = mark(key, glyph, color)
		m.holder.Position = UDim2.new(0.5 + b / 160, 0, 0, 0)
		m.holder.Visible = true
		m.dist.Text = if showDist then string.format("%dm", math.floor(Places.arc(here, target) * 0.28)) else ""
		seen[key] = true
	end
	-- headings: local north is toward the North Station
	local north = Places.stations[1].dir
	local tn = north - here * north:Dot(here)
	if tn.Magnitude > 1e-4 then
		tn = tn.Unit
		local te = tn:Cross(here)
		for _, h in HEADINGS do
			local a = math.rad(h.deg)
			local dir = (here + (tn * math.cos(a) + te * math.sin(a)) * 0.01).Unit
			place("h" .. h.name, h.name, Theme.WHITE, dir, false)
		end
	end
	for _, st in Places.stations do
		if Places.arc(here, st.dir) < 2600 then
			place("s" .. st.index, "▲", Theme.TEAL, st.dir, true)
		end
	end
	local s = State.get()
	for i, w in s.waypoints or {} do
		place("w" .. i, "◆", Theme.ORANGE, Vector3.new(w[1], w[2], w[3]), true)
	end
	if s.fx and s.fx.flagPct then
		local shown = 0
		for i, f in Places.flags do
			if not (s.flags and s.flags[tostring(i)]) and Places.arc(here, f) < 600 and shown < 5 then
				shown += 1
				place("f" .. i, "⚑", Theme.YELLOW, f, true)
			end
		end
	end
	for key, m in marks do
		if not seen[key] then
			m.holder.Visible = false
		end
	end
end

---------------------------------------------------------------------------- sector ring
local ringDots: { Frame } = {}
local ringPct: TextLabel
local ringLabel: TextLabel
local RING_N = 30

local function buildRing(parent: Instance, pos: UDim2)
	local box = Theme.frame(UDim2.new(0, 110, 0, 110), pos, Theme.SLATE, 1)
	box.AnchorPoint = Vector2.new(1, 0)
	box.Parent = parent
	local back = Theme.frame(UDim2.fromScale(0.78, 0.78), UDim2.fromScale(0.5, 0.5), Theme.SLATE_LO, 0.25)
	back.AnchorPoint = Vector2.new(0.5, 0.5)
	Theme.corner(back, 999)
	back.Parent = box
	for i = 1, RING_N do
		local a = math.rad((i - 0.5) / RING_N * 360)
		local d = Theme.frame(
			UDim2.new(0, 8, 0, 8),
			UDim2.fromScale(0.5 + math.sin(a) * 0.45, 0.5 - math.cos(a) * 0.45),
			Theme.SLATE_HI
		)
		d.AnchorPoint = Vector2.new(0.5, 0.5)
		Theme.corner(d, 999)
		d.Parent = box
		table.insert(ringDots, d)
	end
	ringPct = Theme.text("0%", UDim2.fromScale(0.7, 0.32), Theme.YELLOW, Enum.Font.GothamBlack, 28)
	ringPct.AnchorPoint = Vector2.new(0.5, 0.5)
	ringPct.Position = UDim2.fromScale(0.5, 0.45)
	ringPct.TextXAlignment = Enum.TextXAlignment.Center
	ringPct.Parent = box
	ringLabel = Theme.text("SECTOR", UDim2.fromScale(0.7, 0.14), Theme.MUTED, Enum.Font.GothamBold, 14)
	ringLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	ringLabel.Position = UDim2.fromScale(0.5, 0.67)
	ringLabel.TextXAlignment = Enum.TextXAlignment.Center
	ringLabel.Parent = box
end

local function updateRing()
	local s = MoonView.current()
	if s < 0 then
		return
	end
	local prog = MoonView.progress(s)
	local doneNow = MoonView.isDone(s)
	local lit = math.floor(prog * RING_N + 1e-6)
	local color = if doneNow then Theme.TEAL else Theme.YELLOW
	for i, d in ringDots do
		d.BackgroundColor3 = if i <= lit then color else Theme.SLATE_HI
	end
	ringPct.Text = string.format("%d%%", math.floor(prog * 100))
	ringPct.TextColor3 = color
	ringLabel.Text = if doneNow then "COMPLETE" else "SECTOR"
	ringLabel.TextColor3 = if doneNow then Theme.TEAL else Theme.MUTED
end

---------------------------------------------------------------------------- dust jar, money, belt
local jarFill: Frame
local jarText: TextLabel
local toolTag: TextLabel
local podsText: TextLabel
local moneyText: TextLabel
local beltRow: Frame
local packButton: TextButton?
local brushButton: TextButton?
local stardustText: TextLabel
local vehicleBox: Frame
local vehicleSpeed: TextLabel
local vehicleStatus: TextLabel

local function buildJar(parent: Instance, pos: UDim2, anchor: Vector2)
	local box = Theme.frame(UDim2.new(0, 260, 0, 120), pos, Theme.SLATE, 1)
	box.AnchorPoint = anchor
	box.Parent = parent
	local jar = Theme.frame(UDim2.new(0, 52, 0, 96), UDim2.new(0, 0, 0, 18), Theme.SLATE_LO, 0.2)
	Theme.corner(jar, 12)
	Theme.stroke(jar, Theme.MUTED, 2, 0.3)
	jar.ClipsDescendants = true
	jar.Parent = box
	local lid = Theme.frame(UDim2.new(0, 40, 0, 10), UDim2.new(0, 6, 0, 10), Theme.MUTED)
	Theme.corner(lid, 3)
	lid.Parent = box
	jarFill = Theme.frame(UDim2.fromScale(1, 0), UDim2.fromScale(0, 1), Theme.AMBER)
	jarFill.AnchorPoint = Vector2.new(0, 1)
	jarFill.Parent = jar
	toolTag = Theme.text("OLD TOOTHBRUSH", UDim2.new(0, 190, 0, 22), Theme.BLACK, Enum.Font.GothamBlack, 15)
	toolTag.BackgroundTransparency = 0
	toolTag.BackgroundColor3 = Theme.YELLOW
	toolTag.Position = UDim2.new(0, 64, 0, 18)
	Theme.corner(toolTag, 4)
	Theme.pad(toolTag, 3)
	toolTag.Parent = box
	jarText = Theme.text("0.00 / 2.00 KG", UDim2.new(0, 196, 0, 40), Theme.WHITE, Enum.Font.GothamBlack, 34)
	jarText.Position = UDim2.new(0, 64, 0, 44)
	local st = Instance.new("UIStroke")
	st.Thickness = 1.5
	st.Color = Theme.BLACK
	st.Parent = jarText
	jarText.Parent = box
	podsText = Theme.text("PODS 0 / 3", UDim2.new(0, 120, 0, 20), Theme.MUTED, Enum.Font.GothamBold, 15)
	podsText.Position = UDim2.new(0, 64, 0, 88)
	podsText.Parent = box
	stardustText = Theme.text("", UDim2.new(0, 90, 0, 20), Color3.fromRGB(190, 170, 255), Enum.Font.GothamBold, 15)
	stardustText.Position = UDim2.new(0, 168, 0, 88)
	stardustText.Parent = box
end

local function buildMoney(parent: Instance, pos: UDim2, anchor: Vector2)
	local box = Theme.frame(UDim2.new(0, 220, 0, 52), pos, Theme.SLATE, 1)
	box.AnchorPoint = anchor
	box.Parent = parent
	local coin = Theme.frame(UDim2.new(0, 40, 0, 40), UDim2.new(1, -40, 0.5, 0), Theme.AMBER)
	coin.AnchorPoint = Vector2.new(0, 0.5)
	Theme.corner(coin, 999)
	Theme.stroke(coin, Color3.fromRGB(200, 130, 20), 3)
	coin.Parent = box
	local sign = Theme.text("$", UDim2.fromScale(1, 1), Color3.fromRGB(150, 90, 10), Enum.Font.GothamBlack, 26)
	sign.TextXAlignment = Enum.TextXAlignment.Center
	sign.Parent = coin
	moneyText = Theme.text("$0", UDim2.new(1, -50, 1, 0), Theme.AMBER, Enum.Font.GothamBlack, 40)
	moneyText.TextXAlignment = Enum.TextXAlignment.Right
	local st = Instance.new("UIStroke")
	st.Thickness = 1.5
	st.Color = Theme.BLACK
	st.Parent = moneyText
	moneyText.Parent = box
end

local slotButtons: { TextButton } = {}
local function rebuildBelt()
	local s = State.get()
	for _, b in slotButtons do
		b:Destroy()
	end
	table.clear(slotButtons)
	for i = 1, s.slots or 1 do
		local id = (s.belt or {})[i]
		local def = id and Loadout.tool(id)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 58, 0, 58)
		b.BackgroundColor3 = Theme.SLATE_LO
		b.BackgroundTransparency = 0.15
		b.AutoButtonColor = false
		b.Text = ""
		b.LayoutOrder = i
		Theme.corner(b, 999)
		Theme.stroke(b, if i == s.equipped then Theme.ORANGE else Theme.SLATE_HI, if i == s.equipped then 3 else 2)
		local icon = Theme.frame(
			UDim2.fromScale(0.5, 0.5),
			UDim2.fromScale(0.5, 0.5),
			if def
				then (if def.look == "Junk"
					then Theme.MUTED
					elseif def.look == "Planet" then Theme.AMBER
					elseif def.look == "Giant" then Theme.ORANGE
					else Color3.fromRGB(150, 110, 255))
				else Theme.SLATE_HI
		)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		Theme.corner(icon, 999)
		icon.Parent = b
		local short = if def
			then string.upper(
				string.sub(def.name, 1, 1)
					.. string.sub(
						def.name,
						(string.find(def.name, " ") or 0) + 1,
						(string.find(def.name, " ") or 0) + 1
					)
			)
			else ""
		local l = Theme.text(short, UDim2.fromScale(1, 1), Theme.BLACK, Enum.Font.GothamBlack, 16)
		l.TextXAlignment = Enum.TextXAlignment.Center
		l.Parent = icon
		if not touch then
			local key = Theme.text(tostring(i), UDim2.new(0, 18, 0, 18), Theme.WHITE, Enum.Font.GothamBlack, 14)
			key.Position = UDim2.new(0, -2, 0, -2)
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
	toolTag.Text = string.upper(if def then def.name else "Tool")
	local pack, packMax = s.pack or 0, s.packMax or 1
	local frac = math.clamp(pack / math.max(packMax, 1e-6), 0, 1)
	TweenService:Create(jarFill, TweenInfo.new(0.15), { Size = UDim2.fromScale(1, frac) }):Play()
	local full = frac >= 0.999
	jarText.Text = string.format("%s / %s KG", Theme.kg(pack), Theme.kg(packMax))
	jarText.TextColor3 = if full then Theme.RED else Theme.WHITE
	jarFill.BackgroundColor3 = if full then Theme.RED elseif frac > 0.8 then Theme.ORANGE else Theme.AMBER
	podsText.Text = string.format("PODS %d / %d", s.pods or 0, s.carry or 3)
	stardustText.Text = if (s.packStar or 0) > 0.005 then string.format("✦ %s", Theme.kg(s.packStar)) else ""
	moneyText.Text = Theme.money(s.money or 0)
	if (s.money or 0) > lastMoney + 0.001 and State.ready() then
		TweenService:Create(moneyText, TweenInfo.new(0.08), { TextSize = 44 }):Play()
	end
	lastMoney = s.money or 0
	local beltKey = table.concat(s.belt or {}, ",") .. "|" .. tostring(s.slots) .. "|" .. tostring(s.equipped)
	if beltKey ~= lastBeltKey then
		lastBeltKey = beltKey
		rebuildBelt()
	end
	if packButton then
		packButton.Text = if frac > 0.8 then "PACK IT!" else "PACK"
		packButton.BackgroundColor3 = if frac > 0.8 then Theme.ORANGE else Theme.SLATE_HI
		packButton.TextColor3 = if frac > 0.8 then Theme.BLACK else Theme.WHITE
	end
	if brushButton then
		brushButton.BackgroundColor3 = if s.toolOn then Theme.YELLOW else Theme.SLATE_HI
		brushButton.TextColor3 = if s.toolOn then Theme.BLACK else Theme.WHITE
	end
	Movement.setBrushing(s.toolOn == true)
	-- vehicle box
	vehicleBox.Visible = s.vehicle ~= nil
	if s.vehicle then
		local v = Loadout.vehicle(s.vehicle)
		local tank = s.tank or 0
		vehicleStatus.Text = string.format(
			"%s  ·  TANK %s / %s KG%s",
			string.upper(if v then v.name else ""),
			Theme.kg(tank),
			Theme.kg(s.tankMax or 0),
			if (s.dial or 0) > 0 then string.format("  ·  SUCTION %d", s.dial) else ""
		)
	end
end

---------------------------------------------------------------------------- prompts
-- Custom ProximityPrompt look: a dark card with the key, the action, and a yellow hold bar.
local function promptUi(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
	local holderGui = player:WaitForChild("PlayerGui")
	local bb = Instance.new("BillboardGui")
	bb.Name = "Prompt"
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(240, 64)
	bb.StudsOffset = Vector3.new(0, 1.5, 0)
	bb.Adornee = prompt.Parent :: Instance
	bb.Active = true
	bb.Parent = holderGui
	local card = Theme.frame(UDim2.fromScale(1, 1), UDim2.new(), Theme.SLATE, 0.08)
	Theme.corner(card, 8)
	card.Parent = bb
	local key = Instance.new("TextButton")
	key.Size = UDim2.fromOffset(48, 48)
	key.Position = UDim2.fromOffset(8, 8)
	key.BackgroundColor3 = Theme.WHITE
	key.TextColor3 = Theme.BLACK
	key.Font = Enum.Font.GothamBlack
	key.TextSize = 22
	key.AutoButtonColor = false
	key.Text = if inputType == Enum.ProximityPromptInputType.Touch
		then "TAP"
		elseif inputType == Enum.ProximityPromptInputType.Gamepad then "X"
		else prompt.KeyboardKeyCode.Name
	Theme.corner(key, 8)
	key.Parent = card
	local action =
		Theme.text(string.upper(prompt.ActionText), UDim2.new(1, -70, 0, 26), Theme.WHITE, Enum.Font.GothamBlack, 20)
	action.Position = UDim2.fromOffset(64, 8)
	action.Parent = card
	local object = Theme.text(prompt.ObjectText, UDim2.new(1, -70, 0, 18), Theme.TEAL, Enum.Font.GothamBold, 15)
	object.Position = UDim2.fromOffset(64, 34)
	object.Parent = card
	local bar = Theme.frame(UDim2.new(0, 0, 0, 5), UDim2.new(0, 0, 1, -5), Theme.YELLOW)
	bar.Parent = card
	local tween: Tween? = nil
	local c1 = prompt.PromptButtonHoldBegan:Connect(function()
		bar.Size = UDim2.new(0, 0, 0, 5)
		tween = TweenService:Create(
			bar,
			TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear),
			{ Size = UDim2.new(1, 0, 0, 5) }
		);
		(tween :: Tween):Play()
	end)
	local c2 = prompt.PromptButtonHoldEnded:Connect(function()
		if tween then
			tween:Cancel()
		end
		bar.Size = UDim2.new(0, 0, 0, 5)
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
			setBrush(true)
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

	compass = Theme.frame(UDim2.new(0.5, 0, 0, 46), UDim2.new(0.5, 0, 0, 8), Theme.SLATE_LO, 0.35)
	compass.AnchorPoint = Vector2.new(0.5, 0)
	compass.ClipsDescendants = true
	Theme.corner(compass, 6)
	local maxW = Instance.new("UISizeConstraint")
	maxW.MaxSize = Vector2.new(620, 46)
	maxW.Parent = compass
	local tick = Theme.frame(UDim2.new(0, 2, 0, 12), UDim2.new(0.5, -1, 1, -12), Theme.ORANGE)
	tick.Parent = compass
	compass.Parent = gui

	toastHolder = Theme.frame(UDim2.new(0.4, 0, 0, 200), UDim2.new(0.5, 0, 0, 62), Theme.SLATE, 1)
	toastHolder.AnchorPoint = Vector2.new(0.5, 0)
	local tl = Instance.new("UIListLayout")
	tl.Padding = UDim.new(0, 4)
	tl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tl.Parent = toastHolder
	toastHolder.Parent = gui

	buildRing(gui, UDim2.new(1, -8, 0, 8))
	if touch then
		buildJar(gui, UDim2.new(0, 8, 0.38, 0), Vector2.new(0, 0.5))
		buildMoney(gui, UDim2.new(0, 8, 0, 60), Vector2.new(0, 0))
	else
		buildJar(gui, UDim2.new(0, 16, 1, -16), Vector2.new(0, 1))
		buildMoney(gui, UDim2.new(1, -16, 1, -16), Vector2.new(1, 1))
	end

	beltRow = Theme.frame(UDim2.new(0, 400, 0, 62), UDim2.new(0.5, 0, 1, if touch then -96 else -16), Theme.SLATE, 1)
	beltRow.AnchorPoint = Vector2.new(0.5, 1)
	local bl = Instance.new("UIListLayout")
	bl.FillDirection = Enum.FillDirection.Horizontal
	bl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	bl.Padding = UDim.new(0, 8)
	bl.Parent = beltRow
	beltRow.Parent = gui

	-- vehicle speed readout (shown while driving)
	vehicleBox =
		Theme.frame(UDim2.new(0, 360, 0, 90), UDim2.new(0.5, 0, 1, if touch then -170 else -90), Theme.SLATE, 1)
	vehicleBox.AnchorPoint = Vector2.new(0.5, 1)
	vehicleBox.Visible = false
	vehicleBox.Parent = gui
	vehicleSpeed = Theme.text("0 KM/H", UDim2.new(1, 0, 0, 52), Theme.WHITE, Enum.Font.GothamBlack, 50)
	vehicleSpeed.TextXAlignment = Enum.TextXAlignment.Center
	vehicleSpeed.Parent = vehicleBox
	vehicleStatus = Theme.text("", UDim2.new(1, 0, 0, 22), Theme.YELLOW, Enum.Font.GothamBold, 16)
	vehicleStatus.TextXAlignment = Enum.TextXAlignment.Center
	vehicleStatus.Position = UDim2.fromOffset(0, 56)
	vehicleStatus.Parent = vehicleBox
	Hud.vehicleSpeed = vehicleSpeed
	Hud.vehicleStatus = vehicleStatus

	if touch then
		local col = Theme.frame(UDim2.new(0, 90, 0, 220), UDim2.new(1, -12, 1, -170), Theme.SLATE, 1)
		col.AnchorPoint = Vector2.new(1, 1)
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 10)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		layout.Parent = col
		col.Parent = gui
		local b1 = Theme.button("BRUSH", UDim2.new(0, 84, 0, 60), "Dark")
		b1.Activated:Connect(function()
			setBrush(not State.get().toolOn)
		end)
		b1.Parent = col
		brushButton = b1
		local b2 = Theme.button("PACK", UDim2.new(0, 84, 0, 60), "Dark")
		b2.Activated:Connect(pack)
		b2.Parent = col
		packButton = b2
		local b3 = Theme.button("MAP", UDim2.new(0, 84, 0, 48), "Dark")
		b3.Activated:Connect(function()
			State.emit("OpenMenu", "map")
		end)
		b3.Parent = col
	else
		local keys = Theme.text(
			"HOLD LMB  brush\nQ  pack a pod\nE  interact\n1-6  tools\nM  Moon Map\nH  field manual\nV  first person\nB  build\nL  lamp",
			UDim2.new(0, 150, 0, 170),
			Theme.MUTED,
			Enum.Font.GothamBold,
			14
		)
		keys.AnchorPoint = Vector2.new(1, 0.5)
		keys.Position = UDim2.new(1, -12, 0.5, 0)
		keys.TextXAlignment = Enum.TextXAlignment.Right
		keys.TextYAlignment = Enum.TextYAlignment.Center
		keys.TextTransparency = 0.25
		keys.Parent = gui
	end

	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style == Enum.ProximityPromptStyle.Custom then
			promptUi(prompt, inputType)
		end
	end)

	State.changed(onState)
	State.onFeedback(function(kind: string, data: any)
		if kind == "Earned" then
			popup(
				"+" .. Theme.money(data.amount),
				if data.reason == "Sector" then Color3.fromRGB(120, 255, 205) else Theme.AMBER
			)
			if data.reason == "Launch" then
				toast(string.format("Pods launched: +%s", Theme.money(data.amount)), Theme.AMBER)
			elseif data.reason == "Region" then
				toast("REGION COMPLETE  +" .. Theme.money(data.amount), Theme.TEAL)
			end
			Juice.playSound("rbxasset://sounds/electronicpingshort.wav", 0.5)
		elseif kind == "Error" then
			toast(data.text, Theme.RED)
		elseif kind == "PackFull" then
			toast("Dust Pack full! Press Q to pack it into a pod", Theme.ORANGE)
		elseif kind == "Packed" then
			toast(
				string.format("Packed a %s kg pod%s", Theme.kg(data.kg), if data.auto then " (Auto Packer)" else ""),
				Theme.WHITE
			)
		elseif kind == "Bought" then
			Juice.playSound("rbxasset://sounds/electronicpingshort.wav", 0.6)
			toast("Bought!", Theme.GREEN)
		elseif kind == "Achievement" then
			toast("ACHIEVEMENT: " .. string.upper(data.name), Theme.YELLOW)
		elseif kind == "SectorDone" then
			Juice.shakeCamera(0.15)
		elseif kind == "Find" then
			if data.kind == "flag" then
				toast(string.format("FLAG UNTANGLED  %d / %d", data.count, data.total), Theme.ORANGE)
			else
				toast(string.format("PROBE SURVEYED  %d / %d", data.count, data.total), Theme.YELLOW)
			end
		elseif kind == "Toast" then
			toast(data.text, data.color or Theme.WHITE)
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
