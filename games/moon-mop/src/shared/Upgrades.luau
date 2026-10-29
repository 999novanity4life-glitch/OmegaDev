--!strict
-- Upgrade Board rules: costs, requirements and the summed effect of everything a player owns.
-- Pure module. Levels are stored as { [upgradeId] = level }.

local Config = require(script.Parent.Config)

export type Owned = { [string]: number }
export type Effects = { [string]: number }
export type Context = { packUpgrade: boolean? }

local Upgrades = {}

local byId: { [string]: Config.UpgradeDef } = {}
for _, def in Config.Upgrades do
	assert(byId[def.id] == nil, "duplicate upgrade " .. def.id)
	byId[def.id] = def
end
Upgrades.byId = byId

function Upgrades.get(id: string): Config.UpgradeDef?
	return byId[id]
end

-- Price of buying `level` (1 = the first level).
function Upgrades.cost(def: Config.UpgradeDef, level: number): number
	return math.floor(def.base * def.growth ^ (level - 1) + 0.5)
end

-- Can the player buy the next level of `id`? Returns the price when they can.
function Upgrades.check(owned: Owned, id: string, ctx: Context?): (boolean, string, number)
	local def = byId[id]
	if not def then
		return false, "Unknown upgrade", 0
	end
	local have = owned[id] or 0
	if have >= def.max then
		return false, "Maxed", 0
	end
	local needs: { [string]: number } = def.needs or {}
	for needId, needLevel in needs do
		if needId == "@packUpgrade" then
			if not (ctx and ctx.packUpgrade) then
				return false, "Needs a Bigger Pack first", 0
			end
		elseif (owned[needId] or 0) < needLevel then
			local other = byId[needId]
			return false, string.format("Needs %s %d", if other then other.name else needId, needLevel), 0
		end
	end
	return true, "Ready", Upgrades.cost(def, have + 1)
end

-- A node is shown as "?" until one of its requirements has at least one level.
function Upgrades.visible(owned: Owned, id: string): boolean
	local def = byId[id]
	if not def or not def.needs then
		return def ~= nil
	end
	for needId in def.needs do
		if needId == "@packUpgrade" or (owned[needId] or 0) > 0 then
			return true
		end
	end
	return false
end

function Upgrades.effects(owned: Owned): Effects
	local out: Effects = {}
	for id, level in owned do
		local def = byId[id]
		if def and level > 0 then
			for key, per in def.effect do
				out[key] = (out[key] or 0) + per * math.min(level, def.max)
			end
		end
	end
	return out
end

-- Total levels owned (for the "56 of 56" counter and the achievement).
function Upgrades.levelsOwned(owned: Owned): (number, number)
	local have, total = 0, 0
	for _, def in Config.Upgrades do
		have += math.min(owned[def.id] or 0, def.max)
		total += def.max
	end
	return have, total
end

-- Upgrades fully bought, out of the 56 nodes.
function Upgrades.nodesDone(owned: Owned): number
	local n = 0
	for _, def in Config.Upgrades do
		if (owned[def.id] or 0) >= def.max then
			n += 1
		end
	end
	return n
end

return table.freeze(Upgrades)
