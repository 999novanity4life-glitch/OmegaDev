--!strict
-- Draws the rising slime locally from my match folder's numbers, so it
-- moves smoothly at full frame rate with nothing replicated per frame.
-- Also tints the screen edges green when the slime is close.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ParticleArt = require(Shared:WaitForChild("ParticleArt"))
local MatchState = require(script.Parent.MatchState)

local SlimeController = {}

local player = Players.LocalPlayer
local SIZE = 76 -- fills the shaft (radius 36) with a little overlap into the walls

local function makeSlime(): (Model, BasePart, BasePart, ParticleEmitter)
	local model = Instance.new("Model")
	model.Name = "ClientSlime"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.CanCollide = false
	body.CanQuery = false
	body.CanTouch = false
	body.CastShadow = false
	body.Material = Enum.Material.SmoothPlastic
	body.Color = Config.Colors.SlimeDeep
	body.Transparency = 0.05
	body.Size = Vector3.new(SIZE, 60, SIZE)
	body.Parent = model
	-- Glossy glowing skin on top, slightly above the body to avoid z-fighting.
	local skin = Instance.new("Part")
	skin.Name = "Skin"
	skin.Anchored = true
	skin.CanCollide = false
	skin.CanQuery = false
	skin.CanTouch = false
	skin.CastShadow = false
	skin.Material = Enum.Material.Glass
	skin.Color = Config.Colors.Slime
	skin.Transparency = 0.25
	skin.Reflectance = 0.15
	skin.Size = Vector3.new(SIZE, 0.6, SIZE)
	skin.Parent = model
	local glow = Instance.new("SurfaceLight")
	glow.Face = Enum.NormalId.Top
	glow.Color = Config.Colors.Slime
	glow.Range = 16
	glow.Brightness = 1.2
	glow.Parent = skin
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Color = ColorSequence.new(Config.Colors.Slime, Config.Colors.SlimeDeep)
	bubbles.LightEmission = 0.6
	bubbles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1.6) })
	bubbles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	bubbles.Lifetime = NumberRange.new(0.8, 1.4)
	bubbles.Speed = NumberRange.new(2, 5)
	bubbles.SpreadAngle = Vector2.new(25, 25)
	bubbles.EmissionDirection = Enum.NormalId.Top
	bubbles.Rate = 60
	ParticleArt.style(bubbles, "Bubble")
	bubbles.Parent = skin
	model.Parent = workspace
	return model, body, skin, bubbles
end

local function makeVignette(): Frame
	local gui = Instance.new("ScreenGui")
	gui.Name = "SlimeVignette"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 0
	gui.ScreenInsets = Enum.ScreenInsets.None
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Config.Colors.Slime
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.25, 1),
		NumberSequenceKeypoint.new(0.75, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	gradient.Rotation = 90
	gradient.Parent = frame
	frame.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	return frame
end

-- Current slime height: rising in a round, resting at its base during the
-- intro, nil in the lobby.
function SlimeController.height(): number?
	return MatchState.slimeHeight() or MatchState.number("SlimeBaseY")
end

function SlimeController.start()
	local model, body, skin, bubbles = makeSlime()
	local vignette = makeVignette()
	local gurgle = Instance.new("Sound")
	gurgle.SoundId = Config.Sounds.SlimeBubbles
	gurgle.Looped = true
	gurgle.Volume = 0.6
	gurgle.RollOffMaxDistance = 90
	gurgle.Parent = skin
	RunService.RenderStepped:Connect(function()
		local y = SlimeController.height()
		local origin = MatchState.origin()
		if not y or not origin then
			if gurgle.IsPlaying then
				gurgle:Stop()
			end
			model.Parent = nil
			vignette.BackgroundTransparency = 1
			return
		end
		model.Parent = workspace
		if not gurgle.IsPlaying then
			gurgle:Play()
		end
		local t = os.clock()
		local wobble = math.sin(t * 2.2) * 0.15
		body.CFrame = CFrame.new(origin.X, y - 30 + wobble, origin.Z)
		skin.CFrame = CFrame.new(origin.X, y + 0.25 + wobble, origin.Z)
		bubbles.Rate = 40 + 20 * (1 + math.sin(t))
		-- Green screen edges when the rising slime is within 8 studs below you.
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local gap = if root then root.Position.Y - 2.5 - y else math.huge
		local rising = MatchState.inRound()
			and workspace:GetServerTimeNow() >= (MatchState.number("SlimeStart") or math.huge)
		local danger = if rising then math.clamp(1 - gap / 8, 0, 1) else 0
		vignette.BackgroundTransparency = 1 - danger * 0.55
	end)
end

return SlimeController
