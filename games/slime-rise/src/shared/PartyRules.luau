--!strict
-- Pure elevator-party rules: who may join and what max sizes are allowed.

local PartyRules = {}

-- Solo pods take only the host; public pods take anyone until full.
function PartyRules.canJoin(mode: string, count: number, max: number): boolean
	if count == 0 then
		return true
	end
	if mode == "Solo" then
		return false
	end
	return count < max
end

-- The host's chosen max, kept between the current party size and the cap.
function PartyRules.clampMax(value: number, count: number, cap: number): number
	return math.clamp(math.floor(value), math.max(1, count), cap)
end

return PartyRules
