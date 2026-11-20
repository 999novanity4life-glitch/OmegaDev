--!strict
-- Pure rules for the throw (design doc section 3, reworked 2026-11-20 after
-- Throw Food For Animals):
-- 1 power meter (tap once while a marker bounces up a 0..20 bar; top = Perfect),
-- 2 release ring (tap when a shrinking ring meets the target),
-- 3 air tap (the same ring, mid-flight).
-- Plus rarity pacing: rarer fruits fly longer and open with slow motion.
-- No `game` access: the server and the client both use this, and
-- tests/ThrowGrade.spec.luau covers it under Lune. Numbers come from Config.Throw.

export type Grade = "Miss" | "Good" | "Great" | "Perfect"

export type GradeCutoffs = { Perfect: number, Great: number, Good: number }

export type Pace = { flight: number, camSpeed: number, slowmo: number, slowmoSpeed: number }

export type ThrowConfig = {
	MeterMax: number,
	MeterPeriod: number,
	MeterEase: number,
	MeterStart: number,
	MeterGrades: GradeCutoffs,
	MeterMinMult: number,
	MeterMaxMult: number,
	TimingWindows: GradeCutoffs,
	BaseDistance: number,
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

-- Beat 1, power meter. Marker value (0..MeterMax, not rounded) at time t
-- since the meter appeared. Ping-pong with an ease (> 1) so it crawls near the
-- bottom and races near the top, as measured in TFFA. Starts at MeterStart,
-- moving up.
function ThrowGrade.meterValue(t: number, cfg: ThrowConfig): number
	local startPhase = (math.clamp(cfg.MeterStart / cfg.MeterMax, 0, 1)) ^ (1 / cfg.MeterEase)
	local p = ThrowGrade.pingPong(t + startPhase * cfg.MeterPeriod * 0.5, cfg.MeterPeriod)
	return cfg.MeterMax * p ^ cfg.MeterEase
end

-- The "+N" shown next to the marker: whole numbers, clamped to the bar.
function ThrowGrade.meterPower(value: number, cfg: ThrowConfig): number
	if value ~= value then
		return 0
	end
	return math.clamp(math.floor(value + 0.5), 0, cfg.MeterMax)
end

-- Grade for a locked power: at least MeterGrades.X gives grade X.
function ThrowGrade.gradePower(power: number, cfg: ThrowConfig): Grade
	local g = cfg.MeterGrades
	if power >= g.Perfect then
		return "Perfect" :: Grade
	elseif power >= g.Great then
		return "Great" :: Grade
	elseif power >= g.Good then
		return "Good" :: Grade
	end
	return "Miss" :: Grade
end

-- Distance multiplier from the meter: linear from MeterMinMult to MeterMaxMult.
function ThrowGrade.meterMult(power: number, cfg: ThrowConfig): number
	local f = math.clamp(power / cfg.MeterMax, 0, 1)
	return cfg.MeterMinMult + (cfg.MeterMaxMult - cfg.MeterMinMult) * f
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

function ThrowGrade.isMasterwork(meter: Grade, release: Grade, air: Grade): boolean
	return meter == "Perfect" and release == "Perfect" and air == "Perfect"
end

-- Distance from beats 1 and 2 plus the combo carried in (before the air tap).
function ThrowGrade.launchDistance(power: number, release: Grade, combo: number, cfg: ThrowConfig): number
	local comboMult = 1 + math.clamp(combo, 0, cfg.ComboMax) * cfg.ComboStep
	return cfg.BaseDistance * ThrowGrade.meterMult(power, cfg) * cfg.ReleaseMult[release] * comboMult
end

-- Final distance once the air tap is judged.
function ThrowGrade.finalDistance(launch: number, meter: Grade, release: Grade, air: Grade, cfg: ThrowConfig): number
	local d = launch * (1 + cfg.AirBonus[air])
	if ThrowGrade.isMasterwork(meter, release, air) then
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

-- Rarity pacing. A flight of `base` seconds at normal speed becomes
-- base * pace.flight of "fruit time"; the first pace.slowmo real seconds run
-- at pace.slowmoSpeed. pacedFlight = total real seconds in the air.
function ThrowGrade.pacedFlight(base: number, pace: Pace): number
	local fruitTime = base * pace.flight
	local slowFruit = math.min(pace.slowmo * pace.slowmoSpeed, fruitTime)
	local slowReal = if pace.slowmoSpeed > 0 then slowFruit / pace.slowmoSpeed else 0
	return slowReal + (fruitTime - slowFruit)
end

-- Fraction of the flight (0..1) reached after `elapsed` real seconds.
function ThrowGrade.flightAlpha(elapsed: number, base: number, pace: Pace): number
	local fruitTime = base * pace.flight
	if fruitTime <= 0 then
		return 1
	end
	local slowReal = pace.slowmo
	local fruit
	if elapsed <= slowReal then
		fruit = elapsed * pace.slowmoSpeed
	else
		fruit = slowReal * pace.slowmoSpeed + (elapsed - slowReal)
	end
	return fruit / fruitTime
end

-- Real seconds after release when the flight reaches `alpha`.
function ThrowGrade.realTimeAt(alpha: number, base: number, pace: Pace): number
	local fruit = alpha * base * pace.flight
	local slowFruit = pace.slowmo * pace.slowmoSpeed
	if fruit <= slowFruit and pace.slowmoSpeed > 0 then
		return fruit / pace.slowmoSpeed
	end
	return pace.slowmo + (fruit - slowFruit)
end

-- Weighted pick. `r` is a uniform number in [0, 1).
function ThrowGrade.pickWeighted(weights: { number }, r: number): number
	local total = 0
	for _, w in weights do
		total += math.max(w, 0)
	end
	local x = math.clamp(r, 0, 0.999999) * total
	for i, w in weights do
		x -= math.max(w, 0)
		if x < 0 then
			return i
		end
	end
	return #weights
end

return ThrowGrade
