--!strict
-- Slime Rise server entry: mood, saved data, matches, the lobby, then powers.

local LightingService = require(script.Services.LightingService)
local DataService = require(script.Services.DataService)
local MatchService = require(script.Services.MatchService)
local LobbyService = require(script.Services.LobbyService)
local PowerService = require(script.Services.PowerService)

LightingService.start()
DataService.start()
MatchService.start()
LobbyService.start()
PowerService.start()
