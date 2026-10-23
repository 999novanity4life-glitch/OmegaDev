--!strict
-- Roblox jump physics (this place: JumpHeight 7.2, WalkSpeed 16, Gravity 196.2;
-- air control is "absolute": full walk speed in the air).
--   launch speed v0 = sqrt(2 g H)
--   time to land dh studs higher: t = (v0 + sqrt(v0^2 - 2 g dh)) / g
--   horizontal travel = WalkSpeed * t
-- Edge-to-edge gaps can be ~1.5 studs longer than travel (feet overhang the
-- ledge at take-off and landing). We design with a safety margin on top.

local JumpMath = {}

JumpMath.GRAVITY = 196.2
JumpMath.JUMP_HEIGHT = 7.2
JumpMath.WALK_SPEED = 16
JumpMath.OVERHANG = 1.5

function JumpMath.launchSpeed(jumpHeight: number?, gravity: number?): number
	return math.sqrt(2 * (gravity or JumpMath.GRAVITY) * (jumpHeight or JumpMath.JUMP_HEIGHT))
end

-- Seconds in the air when landing `dh` studs above take-off (negative = below).
-- Returns nil when the height can't be reached.
function JumpMath.airtime(dh: number, jumpHeight: number?, gravity: number?): number?
	local g = gravity or JumpMath.GRAVITY
	local v0 = JumpMath.launchSpeed(jumpHeight, g)
	local disc = v0 * v0 - 2 * g * dh
	if disc < 0 then
		return nil
	end
	return (v0 + math.sqrt(disc)) / g
end

-- Longest edge-to-edge gap (studs) for a jump that lands dh studs higher.
function JumpMath.maxGap(dh: number, speed: number?, jumpHeight: number?): number
	local t = JumpMath.airtime(dh, jumpHeight)
	if not t then
		return 0
	end
	return (speed or JumpMath.WALK_SPEED) * t + JumpMath.OVERHANG
end

export type Difficulty = "Easy" | "Medium" | "Hard"

-- Rates a jump by how much of the max gap it uses (kids: keep most Easy).
function JumpMath.rate(gap: number, dh: number): Difficulty?
	local max = JumpMath.maxGap(dh)
	if max <= 0 or gap > max then
		return nil
	end
	local use = gap / max
	if use <= 0.55 then
		return "Easy"
	elseif use <= 0.75 then
		return "Medium"
	end
	return "Hard"
end

return JumpMath
