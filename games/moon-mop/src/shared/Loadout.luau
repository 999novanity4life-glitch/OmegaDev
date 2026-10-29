--!strict
-- What a player's gear actually does once upgrades are counted: tool width and pack, vehicle
-- speed and tank, walk speed, pods carried. Pure module; the server uses these numbers for every
-- outcome and the client only shows them.

local Config = require(script.Parent.Config)

type Effects = { [string]: number }

local Loadout = {}

local toolIndex: { [string]: number } = {}
for i, t in Config.Tools do
	toolIndex[t.id] = i
end
local vehicleIndex: { [string]: number } = {}
for i, v in Config.Vehicles do
	vehicleIndex[v.id] = i
end

function Loadout.tool(id: string): (Config.ToolDef?, number)
	local i = toolIndex[id]
	return if i then Config.Tools[i] else nil, i or 0
end

function Loadout.vehicle(id: string): Config.VehicleDef?
	local i = vehicleIndex[id]
	return if i then Config.Vehicles[i] else nil
end

local function pct(fx: Effects?, key: string): number
	return if fx then (fx[key] or 0) / 100 else 0
end

export type ToolStats = { width: number, pack: number, reach: number, clean: number }

function Loadout.toolStats(def: Config.ToolDef, packUpgraded: boolean, fx: Effects?): ToolStats
	local pack = def.pack * (if packUpgraded then Config.Supply.PackUpgradeMultiplier else 1)
	return {
		width = def.width * (1 + pct(fx, "widthPct")),
		pack = pack * (1 + pct(fx, "packPct")),
		reach = def.reach * (1 + pct(fx, "reachPct")),
		clean = 1 + pct(fx, "cleanPct"),
	}
end

export type VehicleStats = {
	width: number,
	tank: number,
	speed: number,
	accel: number,
	turn: number,
	turbo: number,
	dump: number,
	lights: boolean,
}

-- `ups` are this vehicle's own upgrade levels. `dial` is the Suction Dial mode, 0 = off:
-- each step takes 15% width for 12% speed.
function Loadout.vehicleStats(
	def: Config.VehicleDef,
	ups: { [string]: number }?,
	fx: Effects?,
	dial: number?
): VehicleStats
	local function up(id: string, key: string): number
		local lvl = if ups then ups[id] or 0 else 0
		for _, u in Config.VehicleUpgrades.List do
			if u.id == id then
				return (u.effect[key] or 0) * math.min(lvl, u.max) / 100
			end
		end
		return 0
	end
	local d = math.clamp(dial or 0, 0, if ups then ups.SuctionDial or 0 else 0)
	return {
		width = def.width * (1 + pct(fx, "vehicleWidthPct")) * (1 - 0.15 * d),
		tank = def.tank * (1 + up("BigTank", "tankPct") + pct(fx, "tankPct")),
		speed = def.speed * (1 + up("TunedMotor", "speedPct") + pct(fx, "vehicleSpeedPct")) * (1 + 0.12 * d),
		accel = def.accel,
		turn = def.turn * (1 + up("GripTyres", "gripPct")),
		turbo = 1.35 + up("Turbo", "turboPct"),
		dump = 1 + up("QuickDump", "dumpPct"),
		lights = (if ups then ups.Headlights or 0 else 0) > 0,
	}
end

-- The Big Suck Rover reaches 5,700 kg fully upgraded, like the original's Mega Vacuum Rover.
function Loadout.maxTank(def: Config.VehicleDef): number
	return Loadout.vehicleStats(def, { BigTank = 5 }).tank
end

function Loadout.walkSpeed(fx: Effects?, bootsOn: boolean?): number
	local boots = if bootsOn then Config.Gear.GravityBoots.speedPct / 100 else 0
	return Config.Moon.WalkSpeed * (1 + pct(fx, "walkPct") + boots)
end

function Loadout.brushFactor(fx: Effects?): number
	local loss = 1 - Config.Moon.BrushSpeedFactor
	return 1 - loss * math.max(0, 1 - pct(fx, "brushSpeedPct"))
end

function Loadout.jumpSpeed(fx: Effects?): number
	-- jump height scales with speed squared, so +15% height is sqrt(1.15) speed
	return Config.Moon.JumpSpeed * math.sqrt(1 + pct(fx, "jumpPct"))
end

function Loadout.carryLimit(bought: number, fx: Effects?): number
	return Config.Supply.PodCarryStart + bought + (if fx then fx.carry or 0 else 0)
end

function Loadout.lampRange(fx: Effects?): number
	return Config.DayNight.LampRange * (1 + pct(fx, "lampPct"))
end

function Loadout.packSeconds(fx: Effects?): number
	return Config.Timings.PackSeconds * math.max(0.2, 1 + pct(fx, "packTimePct"))
end

function Loadout.depositSeconds(fx: Effects?): number
	return Config.Timings.DepositSeconds * math.max(0.2, 1 + pct(fx, "depositTimePct"))
end

-- Dust (kg/min) a Dot Bot or Octo cleans.
function Loadout.botRate(kind: "DotBotMk1" | "DotBotMk2" | "CosmicOcto", fx: Effects?): number
	local a = Config.Automation
	if kind == "CosmicOcto" then
		return a.OctoKgPerMin * (1 + pct(fx, "octoRatePct"))
	end
	local base = if kind == "DotBotMk2" then a.BotMk2.kgPerMin else a.BotMk1.kgPerMin
	return base * (1 + pct(fx, "botRatePct"))
end

function Loadout.botRings(kind: "DotBotMk1" | "DotBotMk2", fx: Effects?): number
	local a = Config.Automation
	return (if kind == "DotBotMk2" then a.BotMk2.rings else a.BotMk1.rings) + (if fx then fx.botRings or 0 else 0)
end

return table.freeze(Loadout)
