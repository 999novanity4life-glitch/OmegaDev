--!strict
-- Small feedback helpers. Every player action should get at least one of these
-- (visual, audio, or camera) within the same frame it happens.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Juice = {}

-- Respect the player's Reduced Motion setting: snap instead of animating.
local function motionTime(seconds: number): number
	return if GuiService.ReducedMotionEnabled then 0 else seconds
end

-- Squash a button on press and spring back on release.
function Juice.bindButton(button: GuiButton)
	local scale = button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = button
	local info =
		TweenInfo.new(motionTime(Config.Juice.ButtonPressTime), Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, info, { Scale = Config.Juice.ButtonPressScale }):Play()
	end)
	local function release()
		TweenService:Create(scale, info, { Scale = 1 }):Play()
	end
	button.MouseButton1Up:Connect(release)
	button.MouseLeave:Connect(release)
end

-- Grow a GuiObject in from zero with a slight overshoot.
function Juice.popIn(gui: GuiObject)
	local scale = gui:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = gui
	scale.Scale = 0
	gui.Visible = true
	TweenService
		:Create(
			scale,
			TweenInfo.new(motionTime(Config.Juice.PopInTime), Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{
				Scale = 1,
			}
		)
		:Play()
end

-- One-shot sound without leaking Sound instances.
function Juice.playSound(soundId: string, volume: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.Parent = SoundService
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
end

-- Decaying camera shake. Intensity is in studs of offset.
function Juice.shakeCamera(intensity: number)
	local camera = workspace.CurrentCamera
	if not camera or GuiService.ReducedMotionEnabled then
		return
	end
	local strength = intensity
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(dt: number)
		strength = math.max(0, strength - strength * Config.Juice.CameraShakeDecay * dt)
		if strength < 0.01 then
			connection:Disconnect()
			return
		end
		local offset = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * strength
		camera.CFrame *= CFrame.new(offset)
	end)
end

return Juice
