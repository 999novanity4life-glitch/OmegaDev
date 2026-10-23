--!strict
-- Pure power rules: what is unlocked, what can be pressed, cooldowns.

local Config = require(script.Parent.Config)

local Powers = {}

function Powers.def(id: string): Config.PowerDef?
	return Config.Powers[id]
end

function Powers.isUnlocked(id: string, crowns: number): boolean
	local def = Config.Powers[id]
	return def ~= nil and crowns >= def.Cost
end

-- Powers that go on the button (not passive), in display order.
function Powers.activeIds(): { string }
	local list = {}
	for _, id in Config.PowerOrder do
		local def = Config.Powers[id]
		if def and not def.Passive then
			table.insert(list, id)
		end
	end
	return list
end

function Powers.cooldownReady(lastUsed: number?, cooldown: number, now: number): boolean
	return lastUsed == nil or now - lastUsed >= cooldown
end

-- Crowns still needed to unlock a power (0 when unlocked).
function Powers.crownsNeeded(id: string, crowns: number): number
	local def = Config.Powers[id]
	if not def then
		return 0
	end
	return math.max(0, def.Cost - crowns)
end

return Powers
