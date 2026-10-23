--!strict
-- Slime Rise client entry: draw the slime, then the HUD, then the power controls.

local SlimeController = require(script.Controllers.SlimeController)
local HudController = require(script.Controllers.HudController)
local PowerController = require(script.Controllers.PowerController)

SlimeController.start()
HudController.start()
PowerController.start()
