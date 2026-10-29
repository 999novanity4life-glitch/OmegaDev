--!strict
-- Player saves through ProfileStore (session-locked, CLAUDE.md rule 6). One profile per player,
-- keyed by UserId. Everything the game keeps between sessions is in TEMPLATE.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local ProfileStore = require(ServerStorage:WaitForChild("Vendor"):WaitForChild("ProfileStore")) :: any
local Plot = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Plot"))

-- A building on the player's plot, in plot coordinates (see Shared/Plot).
export type Building = Plot.Building

export type SaveData = {
	money: number,
	stats: { [string]: number },
	hired: boolean,
	tools: { [string]: boolean },
	packUps: { [string]: boolean },
	belt: { string },
	slots: number,
	equipped: number,
	carryBought: number,
	upgrades: { [string]: number },
	flags: { [string]: boolean }, -- flag index (as text) -> untangled
	probes: { [string]: boolean },
	waypoints: { { number } },
	garage: boolean,
	vehicles: { [string]: { [string]: number } },
	buildTool: boolean,
	plot: number,
	buildings: { Building },
	gear: { [string]: boolean },
	suit: { visor: number, colour: number },
	achievements: { [string]: boolean },
	lastOnline: number,
	awayRate: number, -- $/min of automation when the player left
	purchases: { [string]: boolean },
	dropPads: { { number } },
	nextUid: number,
	battery: number, -- kWh left in the base's batteries
}

local TEMPLATE: SaveData = {
	money = 0,
	stats = {},
	hired = false,
	tools = { Toothbrush = true },
	packUps = {},
	belt = { "Toothbrush" },
	slots = 1,
	equipped = 1,
	carryBought = 0,
	upgrades = {},
	flags = {},
	probes = {},
	waypoints = {},
	garage = false,
	vehicles = {},
	buildTool = false,
	plot = 0,
	buildings = {},
	gear = {},
	suit = { visor = 1, colour = 1 },
	achievements = {},
	lastOnline = 0,
	awayRate = 0,
	purchases = {},
	dropPads = {},
	nextUid = 1,
	battery = 0,
}

local Data = {}

local store = ProfileStore.New("MoonMop_v1", TEMPLATE)
local profiles: { [Player]: any } = {}
local loadedCallbacks: { (Player, SaveData) -> () } = {}
local leavingCallbacks: { (Player, SaveData) -> () } = {}

function Data.onLoaded(fn: (Player, SaveData) -> ())
	table.insert(loadedCallbacks, fn)
	for player, profile in profiles do
		task.spawn(fn, player, profile.Data)
	end
end

-- Runs just before a player's profile is released (to stamp lastOnline, awayRate...).
function Data.onLeaving(fn: (Player, SaveData) -> ())
	table.insert(leavingCallbacks, fn)
end

function Data.get(player: Player): SaveData?
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

function Data.isLoaded(player: Player): boolean
	return profiles[player] ~= nil
end

local function load(player: Player)
	local profile = store:StartSessionAsync(tostring(player.UserId), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if profile == nil then
		player:Kick("Your save could not be loaded. Please rejoin.")
		return
	end
	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("Your save was opened on another server. Please rejoin.")
	end)
	if player.Parent ~= Players then
		profile:EndSession()
		return
	end
	profiles[player] = profile
	for _, fn in loadedCallbacks do
		task.spawn(fn, player, profile.Data)
	end
end

Players.PlayerAdded:Connect(load)
for _, player in Players:GetPlayers() do
	task.spawn(load, player)
end

Players.PlayerRemoving:Connect(function(player)
	local profile = profiles[player]
	if profile then
		for _, fn in leavingCallbacks do
			pcall(fn, player, profile.Data)
		end
		profiles[player] = nil
		profile:EndSession()
	end
end)

return Data
