--!strict
-- Helmet lamps: every astronaut's lamp switches on when the sun is low where they stand (the
-- round Moon has day on one side and night on the other) and throws a pool of light ahead
-- (reference P3 f_219). L toggles your own. Night Vision tints your view when it is on.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Lamp = {}

local CENTRE = Config.Moon.Centre
local forcedOff = false
local lamps: { [Model]: SpotLight } = {}

local nv = Instance.new("ColorCorrectionEffect")
nv.Name = "NightVision"
nv.Enabled = false
nv.TintColor = Color3.fromRGB(170, 255, 180)
nv.Brightness = 0.25
nv.Contrast = 0.1
nv.Saturation = -0.6
nv.Parent = Lighting

local function lampFor(char: Model): SpotLight?
	local head = char:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return nil
	end
	local l = lamps[char]
	if l and l.Parent then
		return l
	end
	local s = Instance.new("SpotLight")
	s.Name = "HelmetLamp"
	s.Face = Enum.NormalId.Front
	s.Angle = 70
	s.Brightness = Config.DayNight.LampBrightness
	s.Color = Color3.fromRGB(255, 244, 220)
	s.Shadows = true
	s.Parent = head
	lamps[char] = s
	return s
end

function Lamp.start()
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.L then
			forcedOff = not forcedOff
		end
	end)
	RunService.Heartbeat:Connect(function()
		local sun = Lighting:GetSunDirection()
		for _, plr in Players:GetPlayers() do
			local char = plr.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not char or not root then
				continue
			end
			local up = (root.Position - CENTRE).Unit
			local dark = sun:Dot(up) < 0.08
			local l = lampFor(char)
			if l then
				l.Enabled = dark and not (plr == Players.LocalPlayer and forcedOff)
				l.Range = (char:GetAttribute("Lamp") :: number?) or Config.DayNight.LampRange
			end
			if plr == Players.LocalPlayer then
				nv.Enabled = dark and char:GetAttribute("NightVision") == true
			end
		end
		for char in lamps do
			if not char.Parent then
				lamps[char] = nil
			end
		end
	end)
end

return Lamp
