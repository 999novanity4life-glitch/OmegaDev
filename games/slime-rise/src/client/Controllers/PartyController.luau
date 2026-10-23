--!strict
-- Elevator party panel. Shows while I'm inside a pod: the host picks Solo or
-- Public, the max party size, and presses GO. Everyone else sees the status.
-- Only sends intent; the server (LobbyService) decides everything.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
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
