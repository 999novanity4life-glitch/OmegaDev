--!strict
-- Slime Rise server entry: detail kit, mood, saved data, matches, the lobby, then powers.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- No characters until the lobby exists: loading the kit and building the lab
-- takes a moment, and anyone spawned before then falls into the void.
Players.CharacterAutoLoads = false

-- Create every remote first so clients never wait while the map builds.
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
for _, name in { "UsePower", "PowerFx", "Notify", "PartyAction", "MiniGame", "SkipIntro" } do
	Remotes.get(name)
end

local LabKit = require(script.Services.LabKit)
local LightingService = require(script.Services.LightingService)
local DataService = require(script.Services.DataService)
local MatchService = require(script.Services.MatchService)
local LobbyService = require(script.Services.LobbyService)
local PowerService = require(script.Services.PowerService)
local MiniGames = require(script.Services.MiniGames)

LabKit.start()
LabKit.warmKit()
LightingService.start()
DataService.start()
MatchService.start()
LobbyService.start()
PowerService.start()
MiniGames.start()

-- The lobby (and its spawn) is ready: anyone who joined while it was building
-- gets their character now; from here on Roblox auto-loads (and respawns) as usual.
for _, player in Players:GetPlayers() do
	task.spawn(LobbyService.spawnPlayer, player)
end
Players.CharacterAutoLoads = true
