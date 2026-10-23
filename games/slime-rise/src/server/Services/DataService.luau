--!strict
-- Saved player data through ProfileStore (session-locked). Studio uses the
-- Mock store, so playtests never touch live data. Mirrors Crowns to a player
-- attribute (HUD) and leaderstats (player list).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local PlayerData = require(Shared:WaitForChild("PlayerData"))
local ProfileStore = require(ServerStorage:WaitForChild("Vendor"):WaitForChild("ProfileStore"))

local DataService = {}

local STORE_NAME = "SlimeRise_PlayerData_v1"
local liveStore = ProfileStore.New(STORE_NAME, PlayerData.template())
-- `any`: ProfileStore's own types don't list the Cancel param or Mock's shape cleanly.
local store: any = if RunService:IsStudio() then liveStore.Mock else liveStore
local profiles: { [Player]: any } = {}
local loadedSignal = Instance.new("BindableEvent")

local function mirror(player: Player, data: PlayerData.Data)
	player:SetAttribute("Crowns", data.Crowns)
	player:SetAttribute("Escapes", data.Escapes)
	player:SetAttribute("BestTime", data.BestTime)
	local stats = player:FindFirstChild("leaderstats")
	local crownValue = stats and stats:FindFirstChild("Crowns") :: IntValue?
	if crownValue then
		crownValue.Value = data.Crowns
	end
end

local function makeLeaderstats(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local crownValue = Instance.new("IntValue")
	crownValue.Name = "Crowns"
	crownValue.Parent = stats
	stats.Parent = player
end

local function onPlayerAdded(player: Player)
	makeLeaderstats(player)
	local profile = store:StartSessionAsync(`Player_{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if profile == nil then
		-- Never treat a failed load as a new player.
		player:Kick("Your data failed to load. Please rejoin.")
		return
	end
	profile:AddUserId(player.UserId)
	profile:Reconcile()
	PlayerData.sanitize(profile.Data)
	if RunService:IsStudio() and profile.Data.Crowns == 0 then
		profile.Data.Crowns = Config.Crowns.StudioStartingCrowns
	end
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("Your data session ended. Please rejoin.")
	end)
	if player.Parent ~= Players then
		profile:EndSession()
		return
	end
	profiles[player] = profile
	mirror(player, profile.Data)
	loadedSignal:Fire(player)
end

-- True once the player's saved data is loaded.
function DataService.isLoaded(player: Player): boolean
	return profiles[player] ~= nil
end

function DataService.crowns(player: Player): number
	local profile = profiles[player]
	return if profile then profile.Data.Crowns else 0
end

function DataService.addCrowns(player: Player, amount: number): number
	local profile = profiles[player]
	if not profile or not profile:IsActive() then
		return 0
	end
	local total = PlayerData.addCrowns(profile.Data, amount)
	mirror(player, profile.Data)
	return total
end

-- Returns true when the escape set a new best time.
function DataService.recordEscape(player: Player, seconds: number): boolean
	local profile = profiles[player]
	if not profile or not profile:IsActive() then
		return false
	end
	local best = PlayerData.recordEscape(profile.Data, seconds)
	mirror(player, profile.Data)
	return best
end

DataService.Loaded = loadedSignal.Event

function DataService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		profiles[player] = nil
		if profile then
			profile:EndSession()
		end
	end)
end

return DataService
