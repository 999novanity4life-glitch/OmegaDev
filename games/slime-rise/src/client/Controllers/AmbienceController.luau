--!strict
-- Sound and ambience: lobby hum + music, match alarm + music (crossfaded by
-- where I am), one-shot effects for every game event, and the spinning red
-- alarm lights in the shaft.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ParticleArt = require(Shared:WaitForChild("ParticleArt"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local MatchState = require(script.Parent.MatchState)

local AmbienceController = {}

local player = Players.LocalPlayer
-- any: frozen Config tables are sealed types, so view the sound list as a plain map.
local SOUNDS = (Config.Sounds :: any) :: { [string]: string }

local function loop(id: string, name: string): Sound
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Looped = true
	sound.Volume = 0
	sound.Parent = SoundService
	sound:Play()
	return sound
end

-- One-shot sound; 3D at a position when one is given.
function AmbienceController.play(name: string, volume: number?, position: Vector3?)
	local id = SOUNDS[name]
	if not id then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume or 0.6
	if position then
		local holder = Instance.new("Part")
		holder.Anchored = true
		holder.CanCollide = false
		holder.CanQuery = false
		holder.CanTouch = false
		holder.Transparency = 1
		holder.Size = Vector3.one * 0.2
		holder.Position = position
		holder.Parent = workspace
		sound.RollOffMaxDistance = 140
		sound.Parent = holder
		sound.Ended:Once(function()
			holder:Destroy()
		end)
		task.delay(15, function()
			holder:Destroy()
		end)
	else
		sound.Parent = SoundService
		sound.Ended:Once(function()
			sound:Destroy()
		end)
		task.delay(15, function()
			sound:Destroy()
		end)
	end
	sound:Play()
end

local function crossfade(sound: Sound, target: number)
	if math.abs(sound.Volume - target) > 0.01 then
		TweenService:Create(sound, TweenInfo.new(1.2), { Volume = target }):Play()
	end
end

-- The reward moment on reaching the lift: a burst of goo, bubbles and light
-- motes, a ring of light sweeping out over the bay, and the player floating
-- up into the daylight before the trip back to the lobby.
function AmbienceController.escapeBurst()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.Position = root.Position - Vector3.new(0, 2.5, 0)
	holder.Parent = workspace
	local function burst(kind: ParticleArt.Kind, count: number, color: Color3, size: number, speed: number)
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(color)
		e.Size = NumberSequence.new(size, size * 0.4)
		e.Lifetime = NumberRange.new(0.8, 1.4)
		e.Speed = NumberRange.new(speed * 0.6, speed)
		e.SpreadAngle = Vector2.new(70, 70)
		e.EmissionDirection = Enum.NormalId.Top
		e.Acceleration = Vector3.new(0, -18, 0)
		e.Rate = 0
		ParticleArt.style(e, kind)
		e.Parent = holder
		e:Emit(count)
	end
	burst("Goo", 16, Config.Colors.Slime, 1.1, 26)
	burst("Bubble", 14, Config.Colors.Slime, 1.2, 18)
	burst("Mote", 40, Color3.fromRGB(255, 236, 200), 0.6, 22)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 240, 210)
	ring.Transparency = 0.2
	ring.Size = Vector3.new(0.2, 2, 2)
	ring.CFrame = CFrame.new(holder.Position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.2, 34, 34),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 1)
	Debris:AddItem(holder, 2)
	if GuiService.ReducedMotionEnabled then
		return
	end
	-- Float up into the light (our own character, so the client may move it).
	local attach = Instance.new("Attachment")
	attach.Parent = root
	local lift = Instance.new("LinearVelocity")
	lift.Attachment0 = attach
	lift.VectorVelocity = Vector3.new(0, 10, 0)
	lift.MaxForce = math.huge
	lift.RelativeTo = Enum.ActuatorRelativeTo.World
	lift.Parent = root
	Debris:AddItem(lift, 1.6)
	Debris:AddItem(attach, 1.6)
	local camera = workspace.CurrentCamera
	TweenService:Create(camera, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { FieldOfView = 80 }):Play()
	task.delay(0.5, function()
		TweenService:Create(camera, TweenInfo.new(0.9, Enum.EasingStyle.Sine), { FieldOfView = 70 }):Play()
	end)
end

function AmbienceController.start()
	local hum = loop(SOUNDS.LabHum, "LabHum")
	local lobbyMusic = loop(SOUNDS.LobbyMusic, "LobbyMusic")
	local matchMusic = loop(SOUNDS.MatchMusic, "MatchMusic")
	local alarm = loop(SOUNDS.Alarm, "Alarm")
	local elevatorHum: Sound? = nil

	local last = ""
	-- Each map's room gets its own colour grade on top of the lab look
	-- (local only; the cryo vault reads cold and blue).
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "ThemeGrade"
	grade.Parent = game:GetService("Lighting")
	local GRADES: { [string]: { tint: Color3, saturation: number, contrast: number, softBloom: boolean } } = {
		Lab = { tint = Color3.new(1, 1, 1), saturation = 0, contrast = 0, softBloom = false },
		-- White rooms trip the place's strong default Bloom, so it is turned off.
		Cryo = { tint = Color3.fromRGB(214, 234, 255), saturation = -0.08, contrast = 0.06, softBloom = true },
	}
	local defaultBloom = game:GetService("Lighting"):FindFirstChild("Bloom")
	local lastTheme = ""
	task.spawn(function()
		while true do
			local folder = MatchState.folder()
			local themeAttr = folder and folder:GetAttribute("Theme")
			local themeId = if type(themeAttr) == "string" and GRADES[themeAttr] then themeAttr else "Lab"
			if themeId ~= lastTheme then
				lastTheme = themeId
				local g = GRADES[themeId]
				TweenService:Create(grade, TweenInfo.new(1.5), {
					TintColor = g.tint,
					Saturation = g.saturation,
					Contrast = g.contrast,
				}):Play()
				if defaultBloom and defaultBloom:IsA("BloomEffect") then
					defaultBloom.Enabled = not g.softBloom
				end
			end
			local context = if player:GetAttribute("Cutscene") == true
				then "cutscene"
				elseif MatchState.folder() then "match"
				else "lobby"
			if context ~= last then
				last = context
				crossfade(hum, if context == "lobby" then 0.3 else 0.12)
				crossfade(lobbyMusic, if context == "lobby" then 0.22 else 0)
				crossfade(matchMusic, if context == "match" then 0.3 else 0)
				crossfade(alarm, if context == "match" then 0.12 else 0)
			end
			task.wait(0.5)
		end
	end)

	Remotes.get("Notify").OnClientEvent:Connect(function(kind: string, data: any)
		if kind == "Escaped" then
			AmbienceController.play("Escape", 0.7)
			AmbienceController.escapeBurst()
		elseif kind == "Slimed" then
			AmbienceController.play("Slimed", 0.8)
		elseif kind == "PuzzleProgress" and type(data) == "table" then
			AmbienceController.play(tostring(data.sound), 0.7, data.position)
		elseif kind == "PuzzleSolved" and type(data) == "table" then
			AmbienceController.play("Solve", 0.7)
			AmbienceController.play("Hydraulic", 0.9, data.position)
		elseif kind == "ElevatorRide" then
			AmbienceController.play("DoorSeal", 0.8)
			local rumble = Instance.new("Sound")
			rumble.SoundId = SOUNDS.ElevatorHum
			rumble.Volume = 0.5
			rumble.Looped = true
			rumble.Parent = SoundService
			rumble:Play()
			elevatorHum = rumble
			task.delay(Config.Party.RideSeconds - 0.4, function()
				AmbienceController.play("ElevatorDing", 0.8)
				if elevatorHum then
					elevatorHum:Destroy()
					elevatorHum = nil
				end
			end)
		end
	end)

	Remotes.get("PowerFx").OnClientEvent:Connect(function(userId: number, id: string)
		local who = Players:GetPlayerByUserId(userId)
		local character = who and who.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			AmbienceController.play(id, 0.6, root.Position)
		end
	end)

	-- Local-only motion so the lab feels alive with no network cost:
	-- alarm lamps spin, vent fans turn, rack LEDs blink, gauge needles twitch.
	local blinkClock = 0
	RunService.RenderStepped:Connect(function(dt: number)
		for _, lamp in CollectionService:GetTagged("AlarmLight") do
			if lamp:IsA("BasePart") then
				lamp.CFrame *= CFrame.Angles(0, dt * 5, 0)
			end
		end
		-- Slime flowing through the floor drains.
		for _, flow in CollectionService:GetTagged("SlimeFlow") do
			if flow:IsA("Texture") then
				local speed = flow:GetAttribute("FlowSpeed")
				local rate = if type(speed) == "number" then speed else 2.5
				flow.OffsetStudsV = (flow.OffsetStudsV + dt * rate) % flow.StudsPerTileV
			end
		end
		-- Exit bay: rings of light rise from the lift; runway chevrons pulse
		-- in a wave toward it.
		local now = os.clock()
		for _, ring in CollectionService:GetTagged("RiseRing") do
			if ring:IsA("BasePart") then
				local baseY = ring:GetAttribute("BaseY")
				local height = ring:GetAttribute("Height")
				local phase = ring:GetAttribute("Phase")
				if type(baseY) == "number" and type(height) == "number" and type(phase) == "number" then
					local f = (now * 0.22 + phase) % 1
					local p = ring.Position
					ring.CFrame = CFrame.new(p.X, baseY + f * height, p.Z) * CFrame.Angles(0, 0, math.rad(90))
					ring.Transparency = 0.25 + 0.75 * f
				end
			end
		end
		for _, chevron in CollectionService:GetTagged("Chevron") do
			if chevron:IsA("BasePart") then
				local index = chevron:GetAttribute("Index")
				if type(index) == "number" then
					local wave = math.sin(now * 5 - index * 0.7)
					chevron.Transparency = 0.15 + 0.55 * (1 - math.max(0, wave))
				end
			end
		end
		for _, fan in CollectionService:GetTagged("Fan") do
			if fan:IsA("BasePart") then
				fan.CFrame *= CFrame.Angles(0, 0, dt * 6)
			end
		end
		blinkClock += dt
		if blinkClock > 0.35 then
			blinkClock = 0
			for _, led in CollectionService:GetTagged("Blink") do
				if led:IsA("BasePart") and math.random() < 0.3 then
					led.Transparency = if led.Transparency > 0 then 0 else 0.85
				end
			end
			for _, needle in CollectionService:GetTagged("Needle") do
				if needle:IsA("BasePart") then
					needle.CFrame *= CFrame.Angles(0, 0, (math.random() - 0.5) * 0.25)
				end
			end
		end
	end)
end

return AmbienceController
