--!strict
-- Moon Mop Co. client. Controllers only show things and send intent; the server decides.
local Controllers = script.Controllers

local State = require(Controllers.State)
local Movement = require(Controllers.Movement)
local MoonView = require(Controllers.MoonView)
local Brooms = require(Controllers.Brooms)
local Hud = require(Controllers.Hud)
local Menus = require(Controllers.Menus)
local Lamp = require(Controllers.Lamp)

State.start()
Movement.start()
MoonView.start()
Brooms.start()
Hud.start()
Menus.start()
Lamp.start()
