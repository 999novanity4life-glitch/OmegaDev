--!strict
-- Big moments: pod launches from the cannons, meteor showers (warning beacons, falling
-- fireballs, impacts that re-dust the ground) and the short cutscenes for firsts (first launch,
-- the Build Tool, a finished region, a Cosmic Octo coming online). Cutscenes use letterbox bars
-- and a skip button; with Reduced Motion on they show the caption card without moving the camera.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Juice = require(script.Parent.Juice)
local Menus = require(script.Parent.Menus)
local Movement = require(script.Parent.Movement)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Theme)

local Events = {}

local player = Players.LocalPlayer
local CENTRE = Config.Moon.Centre
local fx = Instance.new("Folder")
fx.Name = "EventFx"

local function upAt(p: Vector3): Vector3
	return (p - CENTRE).Unit
end

local function sideOf(up: Vector3): Vector3
	local side = up:Cross(Vector3.xAxis)
	if side.Magnitude < 0.1 then
		side = up:Cross(Vector3.zAxis)
	end
	return side.Unit
end

local function glow(size: number, color: Color3): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.one * size
	p.Color = color
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	return p
end

local function trail(parent: BasePart, color: Color3, size: number, texture: string?)
	local e = Instance.new("ParticleEmitter")
	if texture then
		e.Texture = texture
	end
	e.Color = ColorSequence.new(color, Color3.fromRGB(80, 80, 90))
	e.Size = NumberSequence.new(size, size * 0.2)
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Lifetime = NumberRange.new(0.4, 0.9)
	e.Speed = NumberRange.new(0)
	e.LightEmission = 0.8
	e.Rate = 60
	e.Parent = parent
end

-- Move a part along a path function over `seconds`, then clean it up.
local function animate(part: BasePart, seconds: number, at: (t: number) -> Vector3, done: (() -> ())?)
	local t = 0
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function(dt: number)
		t = math.min(1, t + dt / seconds)
		part.CFrame = CFrame.new(at(t))
		if t >= 1 then
			conn:Disconnect()
			if done then
				done()
			end
			task.delay(1, function()
				part:Destroy()
			end)
		end
	end)
end

---------------------------------------------------------------------------- launches

local function launch(at: Vector3, pods: number)
	local up = upAt(at)
	for k = 1, math.clamp(pods, 1, 6) do
		task.delay((k - 1) * 0.15, function()
			local pod = glow(1.8, Theme.AMBER)
			trail(pod, Theme.ORANGE, 1.4)
			pod.Parent = fx
			local wobble = sideOf(up) * (math.random() - 0.5) * 6
			animate(pod, 2, function(t)
				return at + up * (t * t * 420) + wobble * t
			end, function()
				pod.Transparency = 1
				local e = pod:FindFirstChildOfClass("ParticleEmitter")
				if e then
					e.Enabled = false
				end
			end)
		end)
	end
end

---------------------------------------------------------------------------- meteors

local function warn(points: { Vector3 }, seconds: number)
	State.emit("Toast", { text = "METEOR SHOWER INCOMING! Clean ground nearby will be re-dusted", color = Theme.RED })
	Juice.playSound("rbxasset://sounds/electronicpingshort.wav", 0.8)
	for _, at in points do
		local up = upAt(at)
		local beacon = Instance.new("Part")
		beacon.Name = "MeteorBeacon"
		beacon.Anchored = true
		beacon.CanCollide = false
		beacon.CanQuery = false
		beacon.CastShadow = false
		beacon.Material = Enum.Material.Neon
		beacon.Color = Theme.RED
		beacon.Size = Vector3.new(2, 240, 2)
		beacon.CFrame = CFrame.lookAt(at + up * 120, at + up * 121) * CFrame.Angles(math.pi / 2, 0, 0)
		beacon.Transparency = 0.4
		beacon.Parent = fx
		if not GuiService.ReducedMotionEnabled then
			TweenService:Create(
				beacon,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Transparency = 0.85 }
			):Play()
		end
		task.delay(seconds + 3, function()
			beacon:Destroy()
		end)
	end
end

local function impact(at: Vector3)
	local up = upAt(at)
	local flash = glow(4, Color3.fromRGB(255, 170, 60))
	flash.CFrame = CFrame.new(at)
	flash.Parent = fx
	TweenService:Create(flash, TweenInfo.new(0.6), { Size = Vector3.one * 40, Transparency = 1 }):Play()
	local burst = Instance.new("Attachment")
	burst.Parent = Workspace.Terrain
	burst.WorldPosition = at + up * 2
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(Color3.fromRGB(205, 205, 212))
	dust.Size = NumberSequence.new(4, 10)
	dust.Transparency = NumberSequence.new(0.2, 1)
	dust.Lifetime = NumberRange.new(1.5, 3)
	dust.Speed = NumberRange.new(20, 45)
	dust.SpreadAngle = Vector2.new(80, 80)
	dust.Rate = 0
	dust.Parent = burst
	dust:Emit(90)
	task.delay(4, function()
		burst:Destroy()
		flash:Destroy()
	end)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		local d = (root.Position - at).Magnitude
		if d < 500 then
			Juice.shakeCamera(math.clamp((500 - d) / 500, 0.1, 1) * 1.2)
		end
	end
end

local function meteor(at: Vector3, fall: number)
	local up = upAt(at)
	local from = at + up * 600 + sideOf(up) * 260
	local rock = glow(7, Color3.fromRGB(255, 120, 30))
	trail(rock, Color3.fromRGB(255, 200, 80), 6, "rbxasset://textures/particles/fire_main.dds")
	rock.Parent = fx
	animate(rock, fall, function(t)
		return from:Lerp(at, t * t)
	end, function()
		rock.Transparency = 1
		local e = rock:FindFirstChildOfClass("ParticleEmitter")
		if e then
			e.Enabled = false
		end
		impact(at)
	end)
end

---------------------------------------------------------------------------- cutscenes

type Shot = { eye: Vector3, look: Vector3, toEye: Vector3?, toLook: Vector3?, seconds: number }

local playing = false

local function cutscene(caption: string, sub: string, shots: { Shot })
	if playing then
		return
	end
	playing = true
	Menus.close()
	-- the HUD steps aside while the scene plays
	local hidden: { ScreenGui } = {}
	for _, g in player:WaitForChild("PlayerGui"):GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled then
			g.Enabled = false
			table.insert(hidden, g)
		end
	end
	local gui = Theme.screen("Cutscene", player:WaitForChild("PlayerGui"), 50)
	gui.ScreenInsets = Enum.ScreenInsets.None
	local top = Theme.frame(UDim2.fromScale(1, 0.12), UDim2.fromScale(0, -0.12), Theme.BLACK)
	top.Parent = gui
	local bottom = Theme.frame(UDim2.fromScale(1, 0.16), UDim2.fromScale(0, 1), Theme.BLACK)
	bottom.Parent = gui
	local title = Theme.text(string.upper(caption), UDim2.new(1, -40, 0.5, 0), Theme.ORANGE, Enum.Font.GothamBlack, 34)
	title.Position = UDim2.new(0, 20, 0.08, 0)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = bottom
	local line = Theme.text(sub, UDim2.new(1, -40, 0.35, 0), Theme.WHITE, Enum.Font.GothamBold, 20)
	line.Position = UDim2.new(0, 20, 0.55, 0)
	line.TextXAlignment = Enum.TextXAlignment.Center
	line.Parent = bottom
	local safe = Theme.screen("CutsceneSkip", player:WaitForChild("PlayerGui"), 51)
	local skip = Theme.button("SKIP", UDim2.fromOffset(110, 44), "Dark")
	skip.AnchorPoint = Vector2.new(1, 0)
	skip.Position = UDim2.new(1, -16, 0, 16)
	skip.Parent = safe
	local skipped = false
	skip.Activated:Connect(function()
		skipped = true
	end)
	TweenService:Create(top, TweenInfo.new(0.35), { Position = UDim2.fromScale(0, 0) }):Play()
	TweenService:Create(bottom, TweenInfo.new(0.35), { Position = UDim2.fromScale(0, 0.84) }):Play()
	local still = GuiService.ReducedMotionEnabled
	if not still then
		for _, shot in shots do
			local t = 0
			Movement.setCameraOverride(function(dt: number): CFrame?
				t = math.min(1, t + dt / shot.seconds)
				local k = t * t * (3 - 2 * t)
				local eye = if shot.toEye then shot.eye:Lerp(shot.toEye, k) else shot.eye
				local look = if shot.toLook then shot.look:Lerp(shot.toLook, k) else shot.look
				return CFrame.lookAt(eye, look, upAt(eye))
			end)
			local waited = 0
			while waited < shot.seconds and not skipped do
				waited += task.wait()
			end
			if skipped then
				break
			end
		end
	else
		local waited = 0
		while waited < 3 and not skipped do
			waited += task.wait()
		end
	end
	Movement.setCameraOverride(nil)
	TweenService:Create(top, TweenInfo.new(0.3), { Position = UDim2.fromScale(0, -0.12) }):Play()
	TweenService:Create(bottom, TweenInfo.new(0.3), { Position = UDim2.fromScale(0, 1) }):Play()
	task.delay(0.35, function()
		gui:Destroy()
		safe:Destroy()
		for _, g in hidden do
			g.Enabled = true
		end
	end)
	playing = false
end

local function orbit(at: Vector3, radius: number, height: number, seconds: number): Shot
	local up = upAt(at)
	local side = sideOf(up)
	local other = up:Cross(side)
	return {
		eye = at + up * height + side * radius,
		toEye = at + up * height + other * radius,
		look = at + up * 2,
		seconds = seconds,
	}
end

local function myRoot(): Vector3?
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return if root then root.Position else nil
end

local SCENES: { [string]: (data: any) -> () } = {}

SCENES.PodCannon = function(data)
	local at = if typeof(data.at) == "Vector3" then data.at else myRoot()
	if not at then
		return
	end
	local up = upAt(at)
	local side = sideOf(up)
	launch(at, 3)
	cutscene("First launch!", "Every pod you deposit is fired home to Earth for cash", {
		{ eye = at + up * 10 + side * 26, look = at + up * 6, toLook = at + up * 60, seconds = 1.4 },
		{ eye = at + up * 10 + side * 26, look = at + up * 60, toLook = at + up * 300, seconds = 1.8 },
	})
end

SCENES.Octo = function(data)
	local at = if typeof(data.at) == "Vector3" then data.at else myRoot()
	if not at then
		return
	end
	cutscene(
		"Cosmic Octo online",
		"It roams the regions round your base and fires pods to your Pod Catcher",
		{ orbit(at, 46, 22, 3.5) }
	)
end

SCENES.Region = function()
	local at = myRoot()
	if at then
		cutscene("Region complete", "The whole region is spotless. Head for the next one!", { orbit(at, 30, 14, 3) })
	end
end

function Events.start()
	fx.Parent = Workspace
	Remotes.get("WorldEvent").OnClientEvent:Connect(function(kind: any, data: any)
		if typeof(data) ~= "table" then
			return
		end
		if kind == "Launch" and typeof(data.at) == "Vector3" then
			launch(data.at, if typeof(data.pods) == "number" then data.pods else 1)
		elseif kind == "MeteorWarning" and typeof(data.at) == "table" then
			local points: { Vector3 } = {}
			for _, p in data.at do
				if typeof(p) == "Vector3" then
					table.insert(points, p)
				end
			end
			warn(points, if typeof(data.seconds) == "number" then data.seconds else 10)
		elseif kind == "Meteor" and typeof(data.at) == "Vector3" then
			meteor(data.at, if typeof(data.fall) == "number" then math.clamp(data.fall, 0.5, 4) else 1.6)
		end
	end)
	State.onFeedback(function(kind: string, data: any)
		if kind == "Cutscene" and typeof(data) == "table" then
			local scene = SCENES[data.name]
			if scene then
				task.spawn(scene, data)
			end
		elseif kind == "Earned" and typeof(data) == "table" and data.reason == "Region" then
			task.spawn(SCENES.Region, data)
		elseif kind == "Reveal" and typeof(data) == "table" and data.kind == "buildTool" then
			task.spawn(cutscene, "Build Tool unlocked", "Claim a plot by the North Station, then press B to build", {})
		end
	end)
end

return Events
