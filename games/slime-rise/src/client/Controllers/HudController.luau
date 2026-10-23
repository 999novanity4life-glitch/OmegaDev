--!strict
-- The HUD: round state and timer (top), slime meter (left), crowns (top right),
-- the 3-2-1 countdown and result banners. Reads server state, never decides it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local SlimeCurve = require(Shared:WaitForChild("SlimeCurve"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Juice = require(script.Parent.Juice)
local SlimeController = require(script.Parent.SlimeController)

local HudController = {}

local player = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("RoundState")
local FONT = Font.fromName("FredokaOne")
local DARK = Color3.fromRGB(24, 18, 38)

local function label(props: { [string]: any }, parent: Instance): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.FontFace = FONT
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextScaled = true
	for key, value in props do
		(l :: any)[key] = value
	end
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = DARK
	stroke.Parent = l
	local size = Instance.new("UITextSizeConstraint")
	size.MinTextSize = 9
	size.MaxTextSize = 64
	size.Parent = l
	l.Parent = parent
	return l
end

local function panel(props: { [string]: any }, parent: Instance): Frame
	local f = Instance.new("Frame")
	f.BackgroundColor3 = DARK
	f.BackgroundTransparency = 0.1
	for key, value in props do
		(f :: any)[key] = value
	end
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = f
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Config.Colors.Slime
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = f
	f.Parent = parent
	return f
end

local function formatTime(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
end

function HudController.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "SlimeHud"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Top: state + timer pill.
	local top = panel({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromScale(0.26, 0.075),
	}, gui)
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 5
	ratio.Parent = top
	local stateText = label({ Size = UDim2.fromScale(0.62, 0.8), Position = UDim2.fromScale(0.04, 0.1) }, top)
	local timerText = label({
		Size = UDim2.fromScale(0.3, 0.8),
		Position = UDim2.fromScale(0.66, 0.1),
		TextColor3 = Config.Colors.Slime,
	}, top)

	-- Top right: crowns.
	local crownPanel = panel({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 60),
		Size = UDim2.fromScale(0.14, 0.07),
	}, gui)
	local crownRatio = Instance.new("UIAspectRatioConstraint")
	crownRatio.AspectRatio = 3.2
	crownRatio.Parent = crownPanel
	local crownText = label({
		Size = UDim2.fromScale(0.9, 0.8),
		Position = UDim2.fromScale(0.05, 0.1),
		TextColor3 = Config.Colors.Exit,
	}, crownPanel)
	local function refreshCrowns()
		local value = player:GetAttribute("Crowns")
		crownText.Text = "CROWNS " .. tostring(if type(value) == "number" then value else 0)
	end
	player:GetAttributeChangedSignal("Crowns"):Connect(function()
		refreshCrowns()
		Juice.popIn(crownPanel)
	end)
	refreshCrowns()

	-- Left: slime meter (bottom = floor, top = exit).
	local meter = panel({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromScale(0.025, 0.42),
		Visible = false,
	}, gui)
	local fill = Instance.new("Frame")
	fill.AnchorPoint = Vector2.new(0, 1)
	fill.Position = UDim2.fromScale(0, 1)
	fill.Size = UDim2.fromScale(1, 0)
	fill.BackgroundColor3 = Config.Colors.Slime
	fill.BorderSizePixel = 0
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.3, 0)
	fillCorner.Parent = fill
	fill.Parent = meter
	local me = Instance.new("Frame")
	me.AnchorPoint = Vector2.new(0.5, 0.5)
	me.Size = UDim2.new(1.8, 0, 0, 10)
	me.BackgroundColor3 = Color3.new(1, 1, 1)
	me.BorderSizePixel = 0
	local meCorner = Instance.new("UICorner")
	meCorner.CornerRadius = UDim.new(1, 0)
	meCorner.Parent = me
	me.Parent = meter
	local exitMark = label({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1.3, 0, 0, 0),
		Size = UDim2.fromOffset(60, 18),
		Text = "EXIT",
		TextColor3 = Config.Colors.Exit,
	}, meter)
	exitMark.TextXAlignment = Enum.TextXAlignment.Left

	-- Center: countdown and banners.
	local banner = label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.32),
		Size = UDim2.fromScale(0.6, 0.12),
		Visible = false,
	}, gui)
	local sub = label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromScale(0.45, 0.06),
		Visible = false,
	}, gui)
	local function showBanner(text: string, color: Color3, subText: string?, hold: number?)
		banner.Text = text
		banner.TextColor3 = color
		Juice.popIn(banner)
		sub.Visible = subText ~= nil
		sub.Text = subText or ""
		local token = {}
		banner:SetAttribute("Token", tostring(token))
		task.delay(hold or 2, function()
			if banner:GetAttribute("Token") == tostring(token) then
				banner.Visible = false
				sub.Visible = false
			end
		end)
	end

	local lastCount = -1
	RunService.RenderStepped:Connect(function()
		local name = state:GetAttribute("State")
		local endsAt = state:GetAttribute("EndsAt")
		local left = if type(endsAt) == "number" and endsAt > 0 then endsAt - workspace:GetServerTimeNow() else 0
		local labels = {
			Lobby = "WAITING FOR PLAYERS",
			Intermission = "NEXT ROUND",
			Round = "ESCAPE!",
			Results = "RESULTS",
		}
		stateText.Text = if type(name) == "string" then labels[name] or name else ""
		timerText.Text = if left > 0 then formatTime(left) else ""

		-- 3-2-1 countdown during the head start.
		local slimeStart = state:GetAttribute("SlimeStart")
		if name == "Round" and type(slimeStart) == "number" then
			local untilSlime = slimeStart - workspace:GetServerTimeNow()
			local count = math.ceil(untilSlime)
			if count ~= lastCount and count >= 0 and count <= 3 then
				lastCount = count
				if count > 0 then
					showBanner(tostring(count), Color3.new(1, 1, 1), nil, 0.9)
				else
					showBanner("CLIMB!", Config.Colors.Slime, "The slime is rising", 1.2)
				end
			end
		else
			lastCount = -1
		end

		-- Slime meter.
		local exitY = state:GetAttribute("ExitY")
		local bottomY = state:GetAttribute("BottomY")
		local slimeY = SlimeController.height()
		meter.Visible = name == "Round" and slimeY ~= nil and type(exitY) == "number"
		if meter.Visible and slimeY and type(exitY) == "number" and type(bottomY) == "number" then
			fill.Size = UDim2.fromScale(1, SlimeCurve.progress(slimeY, bottomY, exitY))
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				me.Position = UDim2.fromScale(0.5, 1 - SlimeCurve.progress(root.Position.Y - 2.5, bottomY, exitY))
			end
		end
	end)

	Remotes.get("Notify").OnClientEvent:Connect(function(kind: string, data: any)
		if kind == "Escaped" then
			showBanner(
				"ESCAPED!",
				Config.Colors.Exit,
				string.format("+%d crowns  ·  #%d  ·  %.1fs", data.crowns, data.place, data.seconds),
				3
			)
			Juice.shakeCamera(0.6)
		elseif kind == "Slimed" then
			showBanner("SLIMED!", Config.Colors.Slime, "Watch from the lobby until next round", 3)
		elseif kind == "Results" then
			local escaped = 0
			for _, r in data.results do
				if r.status == "escaped" then
					escaped += 1
				end
			end
			showBanner("ROUND OVER", Color3.new(1, 1, 1), string.format("%d escaped the slime", escaped), 4)
		end
	end)
end

return HudController
