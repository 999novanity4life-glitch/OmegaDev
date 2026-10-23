--!strict
-- Pure slime math. The server and every client compute the same height from
-- the same numbers, so nothing has to replicate every frame.

local SlimeCurve = {}

-- Height of the slime surface at `now` for a rise from baseY to topY that
-- starts at `start` and lasts `duration` seconds. exponent > 1 starts slow.
function SlimeCurve.height(
	now: number,
	start: number,
	duration: number,
	baseY: number,
	topY: number,
	exponent: number
): number
	if duration <= 0 then
		return topY
	end
	local t = math.clamp((now - start) / duration, 0, 1)
	return baseY + (topY - baseY) * t ^ exponent
end

-- True when a point at height y counts as touching the slime.
function SlimeCurve.isTouching(y: number, slimeY: number, margin: number): boolean
	return y < slimeY + margin
end

-- 0..1 progress of a height between the bottom and the exit, for HUD meters.
function SlimeCurve.progress(y: number, bottomY: number, exitY: number): number
	if exitY <= bottomY then
		return 1
	end
	return math.clamp((y - bottomY) / (exitY - bottomY), 0, 1)
end

return SlimeCurve
