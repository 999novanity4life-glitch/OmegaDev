--!strict
-- Runs the round loop on the server: lobby -> intermission -> round -> results.
-- Owns who is in the round, slime contact, escapes and crown rewards.
-- Clients only read the RoundState attributes and draw them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local SlimeCurve = require(Shared:WaitForChild("SlimeCurve"))
local Crowns = require(Shared:WaitForChild("Crowns"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local MapService = require(script.Parent.MapService)

type Entry = { status: "climbing" | "escaped" | "slimed", escapedAt: number? }

local RoundService = {}

local notify = Remotes.get("Notify")
local state = Instance.new("Folder")
state.Name = "RoundState"
state.Parent = ReplicatedStorage

local entries: { [Player]: Entry } = {}
local layout: MapService.Layout? = nil
local escapedCount = 0

local function now(): number
	return workspace:GetServerTimeNow()
end

local function setState(name: string, duration: number?)
	state:SetAttribute("State", name)
	state:SetAttribute("EndsAt", if duration then now() + duration else 0)
end

local function rootOf(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return root, humanoid
end

local function crownsOf(player: Player): number
	local value = player:GetAttribute("Crowns")
	return if type(value) == "number" then value else 0
end

local function addCrowns(player: Player, amount: number)
	local total = crownsOf(player) + amount
	player:SetAttribute("Crowns", total)
	local stats = player:FindFirstChild("leaderstats")
	local crownValue = stats and stats:FindFirstChild("Crowns") :: IntValue?
	if crownValue then
		crownValue.Value = total
	end
end

local function sendToLobby(player: Player)
	local root = rootOf(player)
	if root and layout then
		root.AssemblyLinearVelocity = Vector3.zero
		local character = player.Character :: Model
		character:PivotTo(layout.lobbySpawn)
	end
end

function RoundService.isClimbing(player: Player): boolean
	local entry = entries[player]
	return entry ~= nil and entry.status == "climbing" and state:GetAttribute("State") == "Round"
end

local function slimeHeight(): number
	local start = state:GetAttribute("SlimeStart")
	local duration = state:GetAttribute("SlimeDuration")
	local topY = state:GetAttribute("SlimeTopY")
	if type(start) ~= "number" or type(duration) ~= "number" or type(topY) ~= "number" then
		return Config.Slime.BaseY
	end
	return SlimeCurve.height(now(), start, duration, Config.Slime.BaseY, topY, Config.Slime.Exponent)
end

local function climbersLeft(): number
	local n = 0
	for _, entry in entries do
		if entry.status == "climbing" then
			n += 1
		end
	end
	return n
end

local function tickRound(dt: number)
	if not layout then
		return
	end
	local slimeY = slimeHeight()
	local slimeStart = state:GetAttribute("SlimeStart") :: number
	for player, entry in entries do
		if entry.status ~= "climbing" then
			continue
		end
		local root, humanoid = rootOf(player)
		if not root or not humanoid or humanoid.Health <= 0 then
			continue
		end
		-- Escape: close enough to the Exit Pad (checked on the server, never by Touched).
		if (root.Position - layout.exitPosition).Magnitude <= Config.Tower.ExitRadius then
			escapedCount += 1
			entry.status = "escaped"
			local seconds = math.max(0, now() - slimeStart)
			entry.escapedAt = seconds
			local earned = Crowns.forEscape(seconds, escapedCount)
			addCrowns(player, earned)
			notify:FireClient(player, "Escaped", { crowns = earned, place = escapedCount, seconds = seconds })
			task.delay(1.2, sendToLobby, player)
			continue
		end
		-- Slime contact drains health unless a Bubble Shield is up.
		local character = player.Character :: Model
		local shieldUntil = character:GetAttribute("ShieldUntil")
		local shielded = type(shieldUntil) == "number" and shieldUntil > now()
		if not shielded and SlimeCurve.isTouching(root.Position.Y - 2.5, slimeY, Config.Slime.ContactMargin) then
			humanoid:TakeDamage(Config.Slime.DamagePerSecond * dt)
		end
	end
end

local function onDied(player: Player)
	local entry = entries[player]
	if entry and entry.status == "climbing" then
		entry.status = "slimed"
		notify:FireClient(player, "Slimed", {})
	end
end

local function runRound(seed: number)
	layout = MapService.build(seed)
	local current = layout :: MapService.Layout
	entries = {}
	escapedCount = 0
	local players = Players:GetPlayers()
	for i, player in players do
		local root = rootOf(player)
		if root then
			entries[player] = { status = "climbing" }
			root.AssemblyLinearVelocity = Vector3.zero
			local spawnCFrame = current.spawnPoints[(i - 1) % #current.spawnPoints + 1];
			(player.Character :: Model):PivotTo(spawnCFrame)
		end
	end
	local roundCfg = Config.Round
	local slimeStart = now() + roundCfg.HeadStartSeconds
	state:SetAttribute("SlimeStart", slimeStart)
	state:SetAttribute("SlimeDuration", roundCfg.RoundSeconds - roundCfg.HeadStartSeconds)
	state:SetAttribute("SlimeTopY", current.exitY + Config.Slime.TopMargin)
	state:SetAttribute("ExitY", current.exitY)
	state:SetAttribute("BottomY", current.bottomY)
	setState("Round", roundCfg.RoundSeconds)

	local endsAt = now() + roundCfg.RoundSeconds
	while now() < endsAt and climbersLeft() > 0 do
		tickRound(task.wait(Config.Slime.CheckInterval))
	end

	-- Results: everyone still climbing when time runs out is slimed.
	local results = {}
	for player, entry in entries do
		if entry.status == "climbing" then
			entry.status = "slimed"
		end
		table.insert(results, { name = player.DisplayName, status = entry.status, seconds = entry.escapedAt })
	end
	table.sort(results, function(a, b)
		return (a.seconds or math.huge) < (b.seconds or math.huge)
	end)
	setState("Results", roundCfg.ResultsSeconds)
	notify:FireAllClients("Results", { results = results })
	task.wait(roundCfg.ResultsSeconds)
	for player in entries do
		sendToLobby(player)
	end
	entries = {}
	state:SetAttribute("SlimeStart", nil)
end

local function onPlayerAdded(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local crownValue = Instance.new("IntValue")
	crownValue.Name = "Crowns"
	crownValue.Parent = stats
	stats.Parent = player
	-- Prototype: crowns are not saved yet (ProfileStore comes before launch).
	addCrowns(player, if RunService:IsStudio() then Config.Crowns.StudioStartingCrowns else 0)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			onDied(player)
		end)
		task.defer(function()
			if not RoundService.isClimbing(player) then
				sendToLobby(player)
			end
		end)
	end)
end

function RoundService.start()
	Players.RespawnTime = Config.Round.RespawnSeconds
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		entries[player] = nil
	end)
	layout = MapService.build(os.time())
	task.spawn(function()
		while true do
			setState("Lobby")
			while #Players:GetPlayers() < Config.Round.MinPlayers do
				task.wait(1)
			end
			setState("Intermission", Config.Round.IntermissionSeconds)
			task.wait(Config.Round.IntermissionSeconds)
			local result = { pcall(runRound, os.time()) }
			if not result[1] then
				warn("[RoundService] round failed: " .. tostring(result[2]))
				task.wait(3)
			end
		end
	end)
end

return RoundService
