--!strict
-- Pure progression math. No Roblox APIs here, so it runs under Lune tests.

local Config = require(script.Parent.Config)

local Progression = {}

function Progression.xpForLevel(level: number): number
	if level <= 1 then
		return 0
	end
	local cfg = Config.Progression
	local total = 0
	for n = 1, level - 1 do
		total += math.round(cfg.BaseXp * n ^ cfg.Exponent)
	end
	return total
end

function Progression.levelForXp(xp: number): number
	local maxLevel = Config.Progression.MaxLevel
	local level = 1
	while level < maxLevel and xp >= Progression.xpForLevel(level + 1) do
		level += 1
	end
	return level
end

-- 0..1 progress toward the next level, for XP bars.
function Progression.progressToNext(xp: number): number
	local level = Progression.levelForXp(xp)
	if level >= Config.Progression.MaxLevel then
		return 1
	end
	local floor = Progression.xpForLevel(level)
	local ceiling = Progression.xpForLevel(level + 1)
	return (xp - floor) / (ceiling - floor)
end

return Progression
