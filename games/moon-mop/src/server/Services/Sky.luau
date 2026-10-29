--!strict
-- Lighting and the day/night cycle. The Moon is round, so Roblox's single sun lights one half of
-- it at a time and day and night move round the Moon as ClockTime turns, like the real thing.
-- The clock runs fast through the North Station's night (Config.DayNight.NightFraction) so the
-- home area is dark only briefly; ambient light follows the sun's height over the North Station.
-- Solar machines ask Sky.sunlightAt(their up).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Factory = require(Shared:WaitForChild("Factory"))

local Sky = {}

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local look = Config.Look
Lighting.Brightness = look.Brightness
Lighting.GeographicLatitude = look.Latitude
Lighting.Ambient = rgb(look.Ambient)
Lighting.OutdoorAmbient = rgb(look.OutdoorAmbient)

local light, night = 1, false
local _ = Factory

function Sky.sunlight(): number
	return light
end

-- Sunlight 0..1 for a spot on the Moon, from the sun's height above its horizon.
function Sky.sunlightAt(up: Vector3): number
	return math.clamp(Lighting:GetSunDirection():Dot(up) * 2.5 + 0.1, 0, 1)
end

function Sky.isNight(): boolean
	return night
end

task.spawn(function()
	while true do
		local _, _, clock = Factory.sun(Workspace:GetServerTimeNow())
		Lighting.ClockTime = clock
		light = Sky.sunlightAt(Vector3.yAxis)
		night = light < 0.15
		local n = night
		local t = light
		Lighting.Ambient = rgb(look.NightAmbient):Lerp(rgb(look.Ambient), t)
		Lighting.OutdoorAmbient = rgb(look.NightOutdoor):Lerp(rgb(look.OutdoorAmbient), t)
		Lighting.Brightness = 0.6 + (look.Brightness - 0.6) * t
		Workspace:SetAttribute("Night", n)
		Workspace:SetAttribute("Sunlight", light)
		task.wait(1)
	end
end)

return Sky
