--!strict
-- Slime Rise server entry: start the round loop, then accept power requests.

local RoundService = require(script.Services.RoundService)
local PowerService = require(script.Services.PowerService)

RoundService.start()
PowerService.start()
