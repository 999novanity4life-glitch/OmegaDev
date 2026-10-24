--!strict
-- Themed interact buttons for every Custom-style ProximityPrompt (all the
-- puzzle stations, valves, levers, fuses...). A chunky slime-lab button pops
-- in over the object: key bubble (E / gamepad button / TAP), the action in
-- big letters, what it is underneath, and a slime fill for hold prompts.
-- Tapping or clicking the button works too, so it is easy on mobile.

local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Juice = require(script.Parent.Juice)

local PromptController = {}

local player = Players.LocalPlayer
local FONT = Font.fromName("FredokaOne")
local DARK = Color3.fromRGB(26, 18, 48)
local PANEL = Color3.fromRGB(52, 40, 86)

local GAMEPAD_LABELS: { [string]: string } = {
	ButtonA = "A",
	ButtonB = "B",
	ButtonX = "X",
	ButtonY = "Y",
}

local function corner(parent: Instance, scale: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale, 0)
	c.Parent = parent
end

local function stroke(parent: Instance, thickness: number, color: Color3, border: boolean?)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color
	if border then
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end
	s.Parent = parent
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

local function keyLabel(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): string
	if inputType == Enum.ProximityPromptInputType.Touch then
		return "TAP"
	elseif inputType == Enum.ProximityPromptInputType.Gamepad then
		return GAMEPAD_LABELS[prompt.GamepadKeyCode.Name] or prompt.GamepadKeyCode.Name
	end
	return UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
end

local function build(
	prompt: ProximityPrompt,
	inputType: Enum.ProximityPromptInputType
): (BillboardGui, { RBXScriptConnection })
	local conns: { RBXScriptConnection } = {}
	local board = Instance.new("BillboardGui")
	board.Name = "SlimePrompt"
	board.Size = UDim2.fromOffset(250, 84)
	board.StudsOffset = Vector3.new(0, 2.2, 0)
	board.AlwaysOnTop = true
	board.LightInfluence = 0
	board.Active = true
	board.ResetOnSpawn = false
	board.Adornee = prompt.Parent :: Instance

	local button = Instance.new("TextButton")
	button.Text = ""
	button.AutoButtonColor = false
	button.Size = UDim2.fromScale(1, 1)
	button.BackgroundColor3 = PANEL
	button.Parent = board
	corner(button, 0.3)
	stroke(button, 3.5, Config.Colors.Slime, true)
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.fromRGB(86, 70, 140), PANEL)
	grad.Rotation = 90
	grad.Parent = button
	local gloss = Instance.new("Frame")
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BackgroundTransparency = 0.88
	gloss.BorderSizePixel = 0
	gloss.Size = UDim2.new(1, -16, 0.38, 0)
	gloss.Position = UDim2.fromOffset(8, 6)
	gloss.Parent = button
	corner(gloss, 0.5)

	-- Key bubble on the left.
	local bubble = Instance.new("Frame")
	bubble.Size = UDim2.fromOffset(62, 62)
	bubble.Position = UDim2.fromOffset(11, 11)
	bubble.BackgroundColor3 = Config.Colors.Slime
	bubble.Parent = button
	corner(bubble, 0.5)
	stroke(bubble, 3, DARK, true)
	local bubbleGrad = Instance.new("UIGradient")
	bubbleGrad.Color = ColorSequence.new(Color3.fromRGB(190, 255, 150), Config.Colors.SlimeDeep)
	bubbleGrad.Rotation = 90
	bubbleGrad.Parent = bubble
	local key = keyLabel(prompt, inputType)
	text(bubble, {
		Size = UDim2.fromScale(if #key > 1 then 0.78 else 0.6, 0.6),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Text = key,
	})

	text(button, {
		Name = "Action",
		Size = UDim2.new(1, -96, 0.48, 0),
		Position = UDim2.new(0, 84, 0.1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(prompt.ActionText),
	})
	text(button, {
		Size = UDim2.new(1, -96, 0.28, 0),
		Position = UDim2.new(0, 84, 0.6, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(200, 240, 180),
		Text = prompt.ObjectText,
	})

	-- Hold progress: slime fills the bar along the bottom.
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -24, 0, 6)
	bar.Position = UDim2.new(0, 12, 1, -10)
	bar.BackgroundColor3 = DARK
	bar.BackgroundTransparency = 0.3
	bar.Visible = prompt.HoldDuration > 0
	bar.Parent = button
	corner(bar, 0.5)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Config.Colors.Slime
	fill.Parent = bar
	corner(fill, 0.5)

	local holding: Tween? = nil
	table.insert(
		conns,
		prompt.PromptButtonHoldBegan:Connect(function()
			holding = TweenService:Create(fill, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), {
				Size = UDim2.fromScale(1, 1),
			});
			(holding :: Tween):Play()
		end)
	)
	table.insert(
		conns,
		prompt.PromptButtonHoldEnded:Connect(function()
			if holding then
				holding:Cancel()
			end
			fill.Size = UDim2.fromScale(0, 1)
		end)
	)
	table.insert(
		conns,
		prompt.Triggered:Connect(function()
			Juice.popIn(button)
		end)
	)
	-- Tap / click the button itself.
	button.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldBegin()
		end
	end)
	button.InputEnded:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldEnd()
		end
	end)

	board.Parent = player:WaitForChild("PlayerGui")
	Juice.popIn(button)
	return board, conns
end

function PromptController.start()
	local open: { [ProximityPrompt]: { board: BillboardGui, conns: { RBXScriptConnection } } } = {}
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom or open[prompt] then
			return
		end
		local board, conns = build(prompt, inputType)
		open[prompt] = { board = board, conns = conns }
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		local entry = open[prompt]
		if entry then
			open[prompt] = nil
			for _, c in entry.conns do
				c:Disconnect()
			end
			entry.board:Destroy()
		end
	end)
end

return PromptController
