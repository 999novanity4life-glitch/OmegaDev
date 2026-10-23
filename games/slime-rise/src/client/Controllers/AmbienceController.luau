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

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
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

function AmbienceController.start()
	local hum = loop(SOUNDS.LabHum, "LabHum")
	local lobbyMusic = loop(SOUNDS.LobbyMusic, "LobbyMusic")
	local matchMusic = loop(SOUNDS.MatchMusic, "MatchMusic")
	local alarm = loop(SOUNDS.Alarm, "Alarm")
	local elevatorHum: Sound? = nil

	local last = ""
	task.spawn(function()
		while true do
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
