--!strict
-- Pure crown rewards. Crowns are earned only, never sold.

local Config = require(script.Parent.Config)

local Crowns = {}

-- Crowns for escaping `seconds` after the slime started, finishing in `place`.
function Crowns.forEscape(seconds: number, place: number): number
	local c = Config.Crowns
	local total = c.Escape
	if seconds <= c.SpeedySeconds then
		total += c.Speedy
	end
	if place >= 1 and place <= c.PodiumSize then
		total += c.PodiumBonus
	end
	return total
end

return Crowns
