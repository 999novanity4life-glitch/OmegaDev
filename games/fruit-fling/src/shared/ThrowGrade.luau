--!strict
-- Pure rules for the 3-beat throw (design doc section 3, Option A):
-- 1 wind-up (release a ping-pong marker inside a drifting zone),
-- 2 release ring (tap when a shrinking ring meets the target),
-- 3 air tap (the same ring, mid-flight).
-- No `game` access: the server and the client both use this, and
-- tests/ThrowGrade.spec.luau covers it under Lune. Numbers come from Config.Throw.

export type Grade = "Miss" | "Good" | "Great" | "Perfect"

export type GradeCutoffs = { Perfect: number, Great: number, Good: number }

export type ThrowConfig = {
	ZoneGrades: GradeCutoffs,
	TimingWindows: GradeCutoffs,
	BaseDistance: number,
	WindupMult: { [string]: number },
	ReleaseMult: { [string]: number },
	AirBonus: { [string]: number },
	MasterworkMult: number,
	ComboStep: number,
	ComboMax: number,
	FlightBase: number,
	FlightPerStud: number,
	FlightMin: number,
	FlightMax: number,
}

local ThrowGrade = {}

local function grade(value: number, cutoffs: GradeCutoffs): Grade
	if value <= cutoffs.Perfect then
		return "Perfect" :: Grade
	elseif value <= cutoffs.Great then
		return "Great" :: Grade
	elseif value <= cutoffs.Good then
		return "Good" :: Grade
	end
	return "Miss" :: Grade
end

-- Beat 1. `ratio` = distance from the zone centre / zone half-width
-- (0 = dead centre, 1 = zone edge). Anything outside the zone misses.
function ThrowGrade.gradeZone(ratio: number, cutoffs: GradeCutoffs): Grade
	return grade(math.abs(ratio), cutoffs)
end

-- Beats 2 and 3. `offset` = tap time minus the moment the ring meets the
-- target, in seconds. Early and late are judged the same.
function ThrowGrade.gradeTiming(offset: number, windows: GradeCutoffs): Grade
	return grade(math.abs(offset), windows)
end

-- Ping-pong in 0..1 with the given full period (up and back down).
function ThrowGrade.pingPong(t: number, period: number): number
	local phase = (t / period) % 1
	return if phase < 0.5 then phase * 2 else 2 - phase * 2
end

-- Centre of the gold zone at time t: drifts back and forth, never past the bar ends.
function ThrowGrade.zoneCenter(t: number, driftSpeed: number, halfWidth: number): number
	local span = 1 - 2 * halfWidth
	if span <= 0 then
		return 0.5
	end
	local period = 2 * span / driftSpeed
	return halfWidth + ThrowGrade.pingPong(t + period * 0.25, period) * span
end

-- Perfect releases build the combo; a Miss resets it; anything else keeps it.
function ThrowGrade.comboAfter(combo: number, release: Grade, max: number): number
	if release == "Perfect" then
		return math.min(combo + 1, max)
	elseif release == "Miss" then
		return 0
	end
	return combo
end

function ThrowGrade.isMasterwork(windup: Grade, release: Grade, air: Grade): boolean
	return windup == "Perfect" and release == "Perfect" and air == "Perfect"
end

-- Distance from beats 1 and 2 plus the combo carried in (before the air tap).
function ThrowGrade.launchDistance(windup: Grade, release: Grade, combo: number, cfg: ThrowConfig): number
	local comboMult = 1 + math.clamp(combo, 0, cfg.ComboMax) * cfg.ComboStep
	return cfg.BaseDistance * cfg.WindupMult[windup] * cfg.ReleaseMult[release] * comboMult
end

-- Final distance once the air tap is judged.
function ThrowGrade.finalDistance(launch: number, windup: Grade, release: Grade, air: Grade, cfg: ThrowConfig): number
	local d = launch * (1 + cfg.AirBonus[air])
	if ThrowGrade.isMasterwork(windup, release, air) then
		d *= cfg.MasterworkMult
	end
	return d
end

-- Seconds in the air for a throw of `distance` studs.
function ThrowGrade.flightTime(distance: number, cfg: ThrowConfig): number
	return math.clamp(cfg.FlightBase + distance * cfg.FlightPerStud, cfg.FlightMin, cfg.FlightMax)
end

-- Parabolic arc. Returns (forward studs, height studs) at alpha in 0..1.
function ThrowGrade.arc(alpha: number, distance: number, heightFraction: number): (number, number)
	local a = math.clamp(alpha, 0, 1)
	return distance * a, 4 * distance * heightFraction * a * (1 - a)
end

return ThrowGrade
