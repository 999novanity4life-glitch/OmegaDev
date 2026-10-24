--!strict
-- Elevator party panel. Shows while I'm inside a pod: the host picks the map
-- (cards ranked by difficulty), Solo or Public, the max party size, and
-- presses GO. Everyone else sees the choices and the status.
-- Only sends intent; the server (LobbyService) decides everything.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local MapDefs = require(Shared:WaitForChild("MapDefs"))
local Juice = require(script.Parent.Juice)

local PartyController = {}

local player = Players.LocalPlayer
local FONT = Font.fromName("FredokaOne")
local DARK = Color3.fromRGB(24, 18, 38)
local MID = Color3.fromRGB(52, 44, 78)
local PURPLE = Color3.fromRGB(166, 107, 255)

local function stroke(parent: Instance, thickness: number, color: Color3, border: boolean?)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color
	if border then
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end
	s.Parent = parent
end

local function corner(parent: Instance, scale: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale, 0)
	c.Parent = parent
end

local function text(parent: Instance, props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.FontFace = FONT
	l.TextScaled = true
	l.TextColor3 = Color3.new(1, 1, 1)
	for key, value in props do
		(l :: any)[key] = value
	end
	stroke(l, 2, DARK)
	l.Parent = parent
	return l
end

local function button(parent: Instance, label: string, color: Color3, props: { [string]: any }): TextButton
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundColor3 = color
	b.Text = ""
	for key, value in props do
		(b :: any)[key] = value
	end
	corner(b, 0.35)
	stroke(b, 3, DARK, true)
	-- Glossy top half for the cartoon look.
	local gloss = Instance.new("Frame")
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BackgroundTransparency = 0.82
	gloss.Size = UDim2.fromScale(0.92, 0.42)
	gloss.Position = UDim2.fromScale(0.04, 0.06)
	gloss.BorderSizePixel = 0
	corner(gloss, 0.5)
	gloss.Parent = b
	text(b, { Size = UDim2.fromScale(0.9, 0.7), Position = UDim2.fromScale(0.05, 0.15), Text = label, Name = "Label" })
	Juice.bindButton(b)
	b.Parent = parent
	return b
end

-- Difficulty colours: Easy green, Medium ice blue, Hard orange, Extreme red.
local RANK_COLORS = {
	Color3.fromRGB(107, 255, 61),
	Color3.fromRGB(90, 210, 255),
	Color3.fromRGB(255, 150, 40),
	Color3.fromRGB(255, 60, 80),
}
local THEME_TOP: { [string]: Color3 } = {
	Shaft = Color3.fromRGB(96, 70, 150),
	Cryo = Color3.fromRGB(70, 130, 180),
	Greenhouse = Color3.fromRGB(60, 120, 70),
	Reactor = Color3.fromRGB(150, 60, 50),
}

local function formatTime(seconds: number): string
	return string.format("%d:%02d", seconds // 60, math.floor(seconds % 60))
end

-- One map card: themed gradient, name, rank band with stars, floors, best time.
local function mapCard(parent: Instance, def: MapDefs.MapDef, index: number): (TextButton, Frame)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.Text = ""
	b.Size = UDim2.fromScale(0.235, 1)
	b.Position = UDim2.fromScale(0.01 + (index - 1) * 0.247, 0)
	b.BackgroundColor3 = THEME_TOP[def.id] or MID
	corner(b, 0.1)
	stroke(b, 3, DARK, true)
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(70, 70, 90))
	grad.Rotation = 90
	grad.Parent = b
	local gloss = Instance.new("Frame")
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BackgroundTransparency = 0.85
	gloss.Size = UDim2.fromScale(0.9, 0.3)
	gloss.Position = UDim2.fromScale(0.05, 0.04)
	gloss.BorderSizePixel = 0
	corner(gloss, 0.4)
	gloss.Parent = b
	text(
		b,
		{ Size = UDim2.fromScale(0.9, 0.26), Position = UDim2.fromScale(0.05, 0.06), Text = string.upper(def.name) }
	)
	local band = Instance.new("Frame")
	band.Size = UDim2.fromScale(0.9, 0.22)
	band.Position = UDim2.fromScale(0.05, 0.38)
	band.BackgroundColor3 = RANK_COLORS[def.difficulty] or MID
	band.BorderSizePixel = 0
	corner(band, 0.4)
	stroke(band, 2, DARK, true)
	band.Parent = b
	text(band, {
		Size = UDim2.fromScale(0.92, 0.8),
		Position = UDim2.fromScale(0.04, 0.1),
		Text = string.rep("★", def.difficulty) .. "  " .. def.rank,
	})
	text(b, {
		Name = "Info",
		Size = UDim2.fromScale(0.9, 0.15),
		Position = UDim2.fromScale(0.05, 0.64),
		Text = string.format("%d FLOORS", def.tiers),
		TextColor3 = Color3.fromRGB(220, 220, 240),
	})
	text(b, {
		Name = "Best",
		Size = UDim2.fromScale(0.9, 0.14),
		Position = UDim2.fromScale(0.05, 0.81),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 220, 90),
	})
	-- Selection ring (shown on the pod's current map).
	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.BackgroundTransparency = 1
	ring.Size = UDim2.new(1, 8, 1, 8)
	ring.Position = UDim2.fromOffset(-4, -4)
	ring.Visible = false
	corner(ring, 0.12)
	stroke(ring, 4, Config.Colors.Slime, true)
	ring.Parent = b
	-- Lock overlay for maps that aren't built yet.
	local lock = Instance.new("Frame")
	lock.Size = UDim2.fromScale(1, 1)
	lock.BackgroundColor3 = DARK
	lock.BackgroundTransparency = 0.35
	lock.Visible = not def.playable
	corner(lock, 0.1)
	lock.Parent = b
	text(lock, {
		Size = UDim2.fromScale(0.86, 0.2),
		Position = UDim2.fromScale(0.07, 0.62),
		Text = "COMING SOON",
		TextColor3 = Color3.fromRGB(200, 190, 230),
	})
	Juice.bindButton(b)
	b.Parent = parent
	return b, ring
end

local function myPod(): Model?
	local lobby = workspace:FindFirstChild("Lobby")
	if not lobby then
		return nil
	end
	local me = tostring(player.UserId)
	for _, pod in lobby:GetChildren() do
		if pod:IsA("Model") and string.match(pod.Name, "^Elevator") then
			local members = pod:GetAttribute("Members")
			if type(members) == "string" then
				for id in string.gmatch(members, "[^,]+") do
					if id == me then
						return pod
					end
				end
			end
		end
	end
	return nil
end

function PartyController.start()
	local action = Remotes.get("PartyAction")
	local gui = Instance.new("ScreenGui")
	gui.Name = "PartyPanel"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 8
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.Parent = player:WaitForChild("PlayerGui")

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 1)
	card.Position = UDim2.new(0.5, 0, 1, -24)
	card.Size = UDim2.fromScale(0.36, 0.3)
	card.BackgroundColor3 = DARK
	card.BackgroundTransparency = 0.05
	card.Visible = false
	card.Parent = gui
	corner(card, 0.12)
	stroke(card, 4, Config.Colors.Slime, true)
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1.9
	ratio.Parent = card
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromRGB(60, 50, 92), DARK)
	gradient.Rotation = 90
	gradient.Parent = card
	-- Hazard stripe header.
	local header = Instance.new("Frame")
	header.Size = UDim2.fromScale(1, 0.2)
	header.BackgroundColor3 = Color3.fromRGB(255, 196, 40)
	header.BorderSizePixel = 0
	corner(header, 0.4)
	header.Parent = card
	local stripes = Instance.new("UIGradient")
	local keys = {}
	for i = 0, 10 do
		local t = i / 10
		table.insert(keys, ColorSequenceKeypoint.new(t, if i % 2 == 0 then Color3.fromRGB(255, 196, 40) else DARK))
	end
	stripes.Color = ColorSequence.new(keys)
	stripes.Rotation = 20
	stripes.Parent = header
	local title = text(card, {
		Size = UDim2.fromScale(0.7, 0.16),
		Position = UDim2.fromScale(0.15, 0.02),
		Text = "ELEVATOR",
		TextColor3 = Color3.new(1, 1, 1),
	})
	local status = text(card, {
		Size = UDim2.fromScale(0.9, 0.11),
		Position = UDim2.fromScale(0.05, 0.24),
		Text = "",
		TextColor3 = Config.Colors.Slime,
	})

	local solo = button(card, "SOLO", MID, { Size = UDim2.fromScale(0.28, 0.2), Position = UDim2.fromScale(0.05, 0.4) })
	local public =
		button(card, "PUBLIC", MID, { Size = UDim2.fromScale(0.28, 0.2), Position = UDim2.fromScale(0.36, 0.4) })
	local minus = button(card, "-", MID, { Size = UDim2.fromScale(0.08, 0.2), Position = UDim2.fromScale(0.68, 0.4) })
	local count = text(card, { Size = UDim2.fromScale(0.08, 0.2), Position = UDim2.fromScale(0.77, 0.4), Text = "4" })
	local plus = button(card, "+", MID, { Size = UDim2.fromScale(0.08, 0.2), Position = UDim2.fromScale(0.86, 0.4) })
	text(card, {
		Size = UDim2.fromScale(0.3, 0.09),
		Position = UDim2.fromScale(0.66, 0.61),
		Text = "MAX PLAYERS",
		TextColor3 = Color3.fromRGB(200, 190, 230),
	})
	local go = button(
		card,
		"GO!",
		Config.Colors.Slime,
		{ Size = UDim2.fromScale(0.5, 0.22), Position = UDim2.fromScale(0.25, 0.74) }
	)
	local goLabel = go:FindFirstChild("Label") :: TextLabel
	goLabel.TextColor3 = Color3.new(1, 1, 1)
	local pulse = TweenService:Create(
		go,
		TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ BackgroundColor3 = Color3.fromRGB(190, 255, 150) }
	)
	pulse:Play()

	-- Map picker above the panel.
	local picker = Instance.new("Frame")
	picker.BackgroundTransparency = 1
	picker.Size = UDim2.fromScale(1, 0.62)
	picker.Position = UDim2.fromScale(0, -0.68)
	picker.Parent = card
	local cards: { { def: MapDefs.MapDef, button: TextButton, ring: Frame } } = {}
	for i, def in MapDefs.list do
		local b, ring = mapCard(picker, def, i)
		table.insert(cards, { def = def, button = b, ring = ring })
		b.Activated:Connect(function()
			if def.playable then
				action:FireServer("map", def.id)
			end
		end)
	end

	local currentMax = Config.Party.DefaultMax
	solo.Activated:Connect(function()
		action:FireServer("mode", "Solo")
	end)
	public.Activated:Connect(function()
		action:FireServer("mode", "Public")
	end)
	minus.Activated:Connect(function()
		action:FireServer("max", math.max(1, currentMax - 1))
	end)
	plus.Activated:Connect(function()
		action:FireServer("max", math.min(Config.Party.MaxPlayers, currentMax + 1))
	end)
	go.Activated:Connect(function()
		action:FireServer("go")
	end)

	local wasVisible = false
	RunService.RenderStepped:Connect(function()
		local pod = myPod()
		local show = pod ~= nil and pod:GetAttribute("Launching") ~= true and player:GetAttribute("Cutscene") ~= true
		card.Visible = show
		player:SetAttribute("InPod", pod ~= nil)
		if show and not wasVisible then
			Juice.popIn(card)
		end
		wasVisible = show
		if not pod or not show then
			return
		end
		local isHost = pod:GetAttribute("Host") == player.UserId
		local mode = pod:GetAttribute("Mode")
		local max = pod:GetAttribute("Max")
		local members = pod:GetAttribute("Count")
		local startAt = pod:GetAttribute("StartAt")
		currentMax = if type(max) == "number" then max else currentMax
		title.Text = string.gsub(pod.Name, "Elevator", "ELEVATOR ")
		count.Text = tostring(currentMax)
		solo.BackgroundColor3 = if mode == "Solo" then PURPLE else MID
		public.BackgroundColor3 = if mode == "Public" then Color3.fromRGB(61, 200, 230) else MID
		for _, b in { solo, public, minus, plus, go } do
			b.Visible = isHost
		end
		count.Visible = true
		local podMap = pod:GetAttribute("Map")
		for _, c in cards do
			c.ring.Visible = c.def.id == podMap
			c.button.Active = isHost and c.def.playable
			local best = player:GetAttribute("Best_" .. c.def.id)
			local bestLabel = c.button:FindFirstChild("Best") :: TextLabel?
			if bestLabel then
				bestLabel.Text = if c.def.playable
						and type(best) == "number"
						and best > 0
					then "BEST " .. formatTime(best)
					else ""
			end
		end
		local left = if type(startAt) == "number" and startAt > 0 then startAt - workspace:GetServerTimeNow() else 0
		if left > 0 then
			status.Text = string.format("Full! Leaving in %d...", math.ceil(left))
		elseif isHost then
			status.Text = if mode == "Solo"
				then "Solo run. Press GO when ready"
				else string.format("%d/%d aboard. Press GO or wait for more", members :: number, currentMax)
		else
			status.Text = string.format("%d/%d aboard. Waiting for the host...", members :: number, currentMax)
		end
	end)
end

return PartyController
