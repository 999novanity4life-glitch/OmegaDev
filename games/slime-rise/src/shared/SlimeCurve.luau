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

-- The slime's clock: real time minus every second it was held (frozen).
-- heldTotal = seconds from holds that have ended; holdStart/holdUntil = the
-- current or last hold. During a hold the clock stands still, so the slime
-- freezes and then carries on from exactly where it stopped.
function SlimeCurve.clock(now: number, heldTotal: number, holdStart: number?, holdUntil: number?): number
	if holdStart and holdUntil and now >= holdStart then
		return now - heldTotal - (math.min(now, holdUntil) - holdStart)
	end
	return now - heldTotal
end

-- Adds a hold of `seconds` at `now` to (heldTotal, holdStart, holdUntil):
-- a hold that already ended is banked into heldTotal; one still running is
-- extended instead of restarting.
function SlimeCurve.addHold(
	now: number,
	seconds: number,
	heldTotal: number,
	holdStart: number?,
	holdUntil: number?
): (number, number, number)
	if holdStart and holdUntil and now < holdUntil then
		return heldTotal, holdStart, holdUntil + seconds
	end
	if holdStart and holdUntil then
		heldTotal += holdUntil - holdStart
	end
	return heldTotal, now, now + seconds
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
