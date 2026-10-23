--!strict
-- Slime Rise server entry: detail kit, mood, saved data, matches, the lobby, then powers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create every remote first so clients never wait while the map builds.
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
for _, name in { "UsePower", "PowerFx", "Notify", "PartyAction" } do
	Remotes.get(name)
end

local LabKit = require(script.Services.LabKit)
local LightingService = require(script.Services.LightingService)
local DataService = require(script.Services.DataService)
local MatchService = require(script.Services.MatchService)
local LobbyService = require(script.Services.LobbyService)
local PowerService = require(script.Services.PowerService)

LabKit.start()
LightingService.start()
DataService.start()
MatchService.start()
LobbyService.start()
PowerService.start()
