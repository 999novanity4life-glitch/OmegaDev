--!strict
-- Automation maths: day and night, solar power and batteries, the Glass Oven and Gem Press,
-- vehicle stunts. Pure module; the server ticks it.

local Config = require(script.Parent.Config)

type Effects = { [string]: number }

local Factory = {}

local function pct(fx: Effects?, key: string): number
	return if fx then (fx[key] or 0) / 100 else 0
end

-- Day/night. `t` is server time in seconds. Returns sunlight 0..1, whether it is night, and
-- the Lighting.ClockTime to show. Night is a short window around midnight.
function Factory.sun(t: number): (number, boolean, number)
	local d = Config.DayNight
	local phase = (t % d.CycleSeconds) / d.CycleSeconds -- 0 = sunrise
	local dayLen = 1 - d.NightFraction
	if phase < dayLen then
		local x = phase / dayLen
		local light = math.clamp(math.sin(x * math.pi) * 1.6, 0, 1)
		return light, false, 6 + 12 * x
	end
	local x = (phase - dayLen) / d.NightFraction
	return 0, true, (18 + 12 * x) % 24
end

export type PowerState = { produced: number, demand: number, satisfied: number, battery: number, capacity: number }

-- One power tick for a base. Solar first, then the battery covers the gap; spare solar charges it.
function Factory.power(
	solarRated: number,
	sunlight: number,
	demand: number,
	battery: number,
	capacity: number,
	dt: number,
	fx: Effects?
): PowerState
	local produced = solarRated * sunlight * (1 + pct(fx, "solarPct"))
	local cap = capacity * (1 + pct(fx, "batteryPct"))
	local hours = dt / 3600
	local satisfied = 1
	if demand <= 0 then
		battery = math.min(cap, battery + produced * hours)
	elseif produced >= demand then
		battery = math.min(cap, battery + (produced - demand) * hours)
	else
		local gap = (demand - produced) * hours
		if battery >= gap then
			battery -= gap
		else
			satisfied = (produced + battery / math.max(hours, 1e-9)) / demand
			battery = 0
		end
	end
	return {
		produced = produced,
		demand = demand,
		satisfied = math.clamp(satisfied, 0, 1),
		battery = battery,
		capacity = cap,
	}
end

-- Glass Oven: dust in, Moon Glass out (same mass), up to its rate when fully powered.
function Factory.oven(dustKg: number, dt: number, satisfied: number, fx: Effects?): (number, number)
	local rate = Config.Automation.GlassKgPerMin * (1 + pct(fx, "factoryRatePct")) * satisfied
	local made = math.min(dustKg, rate * dt / 60)
	return made, dustKg - made
end

-- Gem Press: 1 kg dust + 1 kg glass makes 2 kg Moon Gem.
function Factory.press(
	dustKg: number,
	glassKg: number,
	dt: number,
	satisfied: number,
	fx: Effects?
): (number, number, number)
	local rate = Config.Automation.GemKgPerMin * (1 + pct(fx, "factoryRatePct")) * satisfied
	local made = math.min(dustKg, glassKg, rate * dt / 60 / 2)
	return made * 2, dustKg - made, glassKg - made
end

-- Cash for a stunt: full flips, spins and time in the air.
function Factory.stunt(flips: number, spins: number, airTime: number, fx: Effects?): number
	local s = Config.Stunts
	if airTime < s.MinAirTime and flips == 0 and spins == 0 then
		return 0
	end
	local mult = 1 + pct(fx, "stuntPct") + (if fx and fx.stuntFrames then 0.5 else 0)
	local cash = flips * s.Flip + spins * s.Spin + math.max(0, airTime - s.MinAirTime) * s.AirPerSecond
	return math.floor(cash * mult * 100 + 0.5) / 100
end

-- Which achievements a stats table has newly reached.
function Factory.newAchievements(stats: { [string]: number }, done: { [string]: boolean }): { Config.Achievement }
	local out = {}
	for _, a in Config.Achievements do
		if not done[a.id] and (stats[a.stat] or 0) >= a.goal then
			table.insert(out, a)
		end
	end
	return out
end

return table.freeze(Factory)
