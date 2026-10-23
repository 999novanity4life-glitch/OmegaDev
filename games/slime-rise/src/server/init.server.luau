--!strict
-- Slime Rise server entry: detail kit, mood, saved data, matches, the lobby, then powers.

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
