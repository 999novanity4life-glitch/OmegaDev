--!strict
local LookController = require(script.Controllers.LookController)
local ShopUI = require(script.Controllers.ShopUI)
local ThrowController = require(script.Controllers.ThrowController)

-- Lighting, Atmosphere and post effects from Config.Look (see vault/15).
LookController.start()
ThrowController.start()
ShopUI.start()
