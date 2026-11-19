--!strict
local LookController = require(script.Controllers.LookController)
local ThrowController = require(script.Controllers.ThrowController)

-- Lighting, Atmosphere and post effects from Config.Look (see vault/15).
LookController.start()
ThrowController.start()
