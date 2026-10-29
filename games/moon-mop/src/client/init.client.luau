--!strict
-- Moon Mop Co. client. Controllers only show things and send intent; the server decides.
local Controllers = script.Controllers

local State = require(Controllers.State)
local Movement = require(Controllers.Movement)
local MoonView = require(Controllers.MoonView)
local Brooms = require(Controllers.Brooms)
local Hud = require(Controllers.Hud)
local Menus = require(Controllers.Menus)
local MoonMap = require(Controllers.MoonMap)
local Finds = require(Controllers.Finds)
local Garage = require(Controllers.Garage)
local Driving = require(Controllers.Driving)
local Build = require(Controllers.Build)
local Lamp = require(Controllers.Lamp)
local Factory = require(Controllers.Factory)
local Events = require(Controllers.Events)
local Suit = require(Controllers.Suit)
local Intro = require(Controllers.Intro)

State.start()
Movement.start()
MoonView.start()
Brooms.start()
Hud.start()
Menus.start()
MoonMap.start()
Finds.start()
Garage.start()
Driving.start()
Build.start()
Lamp.start()
Factory.start()
Events.start()
Suit.start()
Intro.start()

-- Studio-only test hook so playtests can open screens and turn the view without a mouse:
-- Invoke("open", menuName) or Invoke("look", Vector3 direction). Never created in live games.
if game:GetService("RunService"):IsStudio() then
	local hook = Instance.new("BindableFunction")
	hook.Name = "MoonMopClientDebug"
	hook.OnInvoke = function(kind: string, arg: any): any -- arg is a menu name or a direction
		if kind == "open" and type(arg) == "string" then
			Menus.open(arg)
		elseif kind == "look" and typeof(arg) == "Vector3" then
			Movement.lookAlong(arg)
		elseif kind == "close" then
			Menus.close()
		end
		return true
	end
	hook.Parent = script
end
