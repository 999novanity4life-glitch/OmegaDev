--!strict
-- Slime Rise client entry: slime, HUD, powers, elevator party panel,
-- cutscenes, then sound and ambience.

local SlimeController = require(script.Controllers.SlimeController)
local HudController = require(script.Controllers.HudController)
local PowerController = require(script.Controllers.PowerController)
local PartyController = require(script.Controllers.PartyController)
local CutsceneController = require(script.Controllers.CutsceneController)
local AmbienceController = require(script.Controllers.AmbienceController)
local MiniGameController = require(script.Controllers.MiniGameController)
local ParkourController = require(script.Controllers.ParkourController)
local MarkerController = require(script.Controllers.MarkerController)
local PromptController = require(script.Controllers.PromptController)

CutsceneController.start()
SlimeController.start()
HudController.start()
PowerController.start()
PartyController.start()
AmbienceController.start()
MiniGameController.start()
ParkourController.start()
MarkerController.start()
PromptController.start()
