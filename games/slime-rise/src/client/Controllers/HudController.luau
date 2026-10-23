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
local MatchState = require(script.Parent.MatchState)

local HudController = {}

local player = Players.LocalPlayer
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

local function icon(image: string, props: { [string]: any }, parent: Instance): ImageLabel
	local i = Instance.new("ImageLabel")
	i.BackgroundTransparency = 1
	i.Image = image
	i.ScaleType = Enum.ScaleType.Fit
	for key, value in props do
		(i :: any)[key] = value
	end
	i.Parent = parent
	return i
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
	local stateText = label({ Size = UDim2.fromScale(0.54, 0.76), Position = UDim2.fromScale(0.04, 0.12) }, top)
	local timerIcon = icon(Config.Icons.Timer, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.59, 0.5),
		Size = UDim2.fromScale(0.13, 0.86),
	}, top)
	local timerText = label({
		Size = UDim2.fromScale(0.26, 0.8),
		Position = UDim2.fromScale(0.72, 0.1),
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
	icon(Config.Icons.Crown, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -10, 0.5, -2),
		Size = UDim2.fromScale(0.42, 1.35),
		Rotation = -12,
		ZIndex = 2,
	}, crownPanel)
	local crownText = label({
		Size = UDim2.fromScale(0.58, 0.78),
		Position = UDim2.fromScale(0.36, 0.11),
		TextColor3 = Config.Colors.Exit,
	}, crownPanel)
	local function refreshCrowns()
		local value = player:GetAttribute("Crowns")
		crownText.Text = tostring(if type(value) == "number" then value else 0)
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
	-- Exit flag on top, slime mascot riding the fill.
	icon(Config.Icons.Exit, {
		AnchorPoint = Vector2.new(0.3, 1),
		Position = UDim2.new(0.5, 0, 0, -4),
		Size = UDim2.fromOffset(40, 40),
	}, meter)
	local mascot = icon(Config.Icons.Slime, {
		AnchorPoint = Vector2.new(0.5, 0.75),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(34, 34),
		ZIndex = 3,
	}, meter)

	-- Game logo between rounds.
	local logo = Instance.new("Frame")
	logo.BackgroundTransparency = 1
	logo.AnchorPoint = Vector2.new(0.5, 0)
	logo.Position = UDim2.fromScale(0.5, 0.15)
	logo.Size = UDim2.fromScale(0.42, 0.13)
	logo.Parent = gui
	local logoRatio = Instance.new("UIAspectRatioConstraint")
	logoRatio.AspectRatio = 4.4
	logoRatio.Parent = logo
	icon(Config.Icons.Slime, { Size = UDim2.fromScale(0.24, 1.1), Position = UDim2.fromScale(0, -0.05) }, logo)
	local logoText = label({
		Size = UDim2.fromScale(0.76, 1),
		Position = UDim2.fromScale(0.24, 0),
		Text = "SLIME RISE",
		TextColor3 = Config.Colors.Slime,
	}, logo)
	local logoStroke = logoText:FindFirstChildOfClass("UIStroke") :: UIStroke
	logoStroke.Thickness = 5
	local logoGradient = Instance.new("UIGradient")
	logoGradient.Color = ColorSequence.new(Color3.fromRGB(214, 255, 170), Config.Colors.SlimeDeep)
	logoGradient.Rotation = 90
	logoGradient.Parent = logoText

	-- Lobby tip under the logo.
	local tip = label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.29),
		Size = UDim2.fromScale(0.4, 0.045),
		Text = "Step into an ELEVATOR to start a run",
	}, gui)

	-- Objective panel under the top pill (match only).
	local objective = panel({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 62),
		Size = UDim2.fromScale(0.3, 0.06),
		Visible = false,
	}, gui)
	local objectiveRatio = Instance.new("UIAspectRatioConstraint")
	objectiveRatio.AspectRatio = 7
	objectiveRatio.Parent = objective
	local tierText = label({
		Size = UDim2.fromScale(0.22, 0.62),
		Position = UDim2.fromScale(0.03, 0.08),
		TextColor3 = Config.Colors.Slime,
	}, objective)
	local taskText = label({ Size = UDim2.fromScale(0.72, 0.62), Position = UDim2.fromScale(0.26, 0.08) }, objective)
	taskText.TextXAlignment = Enum.TextXAlignment.Left
	local barBack = Instance.new("Frame")
	barBack.AnchorPoint = Vector2.new(0.5, 1)
	barBack.Position = UDim2.fromScale(0.5, 0.9)
	barBack.Size = UDim2.fromScale(0.92, 0.16)
	barBack.BackgroundColor3 = Color3.fromRGB(60, 52, 84)
	barBack.BorderSizePixel = 0
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = barBack
	barBack.Parent = objective
	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromScale(0, 1)
	bar.BackgroundColor3 = Config.Colors.Slime
	bar.BorderSizePixel = 0
	local barFillCorner = Instance.new("UICorner")
	barFillCorner.CornerRadius = UDim.new(1, 0)
	barFillCorner.Parent = bar
	bar.Parent = barBack

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
	local labels = {
		Intro = "SECTOR BRIEFING",
		Round = "ESCAPE!",
		Results = "RESULTS",
	}
	RunService.RenderStepped:Connect(function()
		gui.Enabled = player:GetAttribute("Cutscene") ~= true
		local folder = MatchState.folder()
		local name = MatchState.state()
		local endsAt = MatchState.number("EndsAt")
		local left = if endsAt then endsAt - workspace:GetServerTimeNow() else 0
		stateText.Text = if folder then (if name then labels[name] or name else "") else "SLIME LAB"
		timerText.Text = if left > 0 then formatTime(left) else (if folder then "" else "LOBBY")
		timerIcon.Visible = left > 0
		local inPod = player:GetAttribute("InPod") == true
		logo.Visible = folder == nil and not inPod
		tip.Visible = folder == nil and not inPod

		-- Objective.
		local tier = MatchState.number("Tier")
		local total = MatchState.number("ObjectiveTotal") or 0
		local done = MatchState.number("ObjectiveDone") or 0
		local objectiveText = folder and folder:GetAttribute("Objective")
		objective.Visible = name == "Round" and type(objectiveText) == "string"
		if objective.Visible then
			local tiers = Config.Shaft.Tiers
			tierText.Text = if tier and tier <= tiers then string.format("TIER %d/%d", tier, tiers) else "EXIT"
			taskText.Text = if total > 0
				then string.format("%s  %d/%d", objectiveText :: string, done, total)
				else objectiveText :: string
			bar.Size = UDim2.fromScale(if total > 0 then done / total else 1, 1)
		end

		-- 3-2-1 countdown during the head start.
		local slimeStart = MatchState.number("SlimeStart")
		if name == "Round" and slimeStart then
			local count = math.ceil(slimeStart - workspace:GetServerTimeNow())
			if count ~= lastCount and count >= 0 and count <= 3 then
				lastCount = count
				if count > 0 then
					showBanner(tostring(count), Color3.new(1, 1, 1), nil, 0.9)
				else
					showBanner("CLIMB!", Config.Colors.Slime, "Fix the leak and get out!", 1.4)
				end
			end
		else
			lastCount = -1
		end

		-- Slime meter.
		local exitY = MatchState.number("ExitY")
		local bottomY = MatchState.number("BottomY")
		local slimeY = SlimeController.height()
		meter.Visible = name == "Round" and slimeY ~= nil and exitY ~= nil
		if meter.Visible and slimeY and exitY and bottomY then
			local slimeProgress = SlimeCurve.progress(slimeY, bottomY, exitY)
			fill.Size = UDim2.fromScale(1, slimeProgress)
			mascot.Position = UDim2.fromScale(0.5, 1 - slimeProgress)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				me.Position = UDim2.fromScale(0.5, 1 - SlimeCurve.progress(root.Position.Y - 2.5, bottomY, exitY))
			end
		end
	end)

	Remotes.get("Notify").OnClientEvent:Connect(function(kind: string, data: any)
		if kind == "Escaped" then
			local subText = string.format("+%d crowns  ·  #%d  ·  %.1fs", data.crowns, data.place, data.seconds)
			if data.best then
				subText ..= "  ·  NEW BEST!"
			end
			showBanner("ESCAPED!", Config.Colors.Exit, subText, 3)
			Juice.shakeCamera(0.6)
		elseif kind == "Slimed" then
			showBanner("SLIMED!", Config.Colors.Slime, "Back to the lab. Try again!", 3)
		elseif kind == "Results" then
			local escaped = 0
			for _, r in data.results do
				if r.status == "escaped" then
					escaped += 1
				end
			end
			showBanner("RUN OVER", Color3.new(1, 1, 1), string.format("%d escaped the slime", escaped), 4)
		elseif kind == "PuzzleSolved" then
			showBanner(
				"LEAK SEALED!",
				Config.Colors.Slime,
				string.format("Bridge extended  ·  +%d crown team bonus", data.crowns),
				2.5
			)
			Juice.shakeCamera(0.4)
		elseif kind == "PodLocked" then
			showBanner(
				"ELEVATOR LOCKED",
				Color3.fromRGB(255, 120, 120),
				if data.mode == "Solo" then "That run is solo" else "That elevator is full",
				2
			)
		end
	end)
end

return HudController
