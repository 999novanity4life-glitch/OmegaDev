--!strict
-- Pure helpers for showing rarity: real "1 in X" odds from Config.Rarity
-- weights, the rarity-climb ladder and the reveal timing.
-- CLAUDE.md rule 7: any paid random item must show every outcome with numeric
-- odds; oddsTable gives exactly that list from the same weights the server uses.
-- No `game` access; tests/RarityStyle.spec.luau covers it under Lune.

export type RarityConfig = {
	Order: { string },
	Weight: { [string]: number },
}

export type RevealBeats = {
	climb: { string }, -- rungs lit in order, ending on the rolled tier
	climbSeconds: number,
	bloom: boolean, -- star flare before the card
	total: number, -- climb + bloom + hold
}

local RarityStyle = {}

local function totalWeight(cfg: RarityConfig): number
	local sum = 0
	for _, name in cfg.Order do
		sum += math.max(0, cfg.Weight[name] or 0)
	end
	return sum
end

-- Chance (0..1) of rolling `rarity`. Unknown tier or zero weight -> 0.
function RarityStyle.chance(rarity: string, cfg: RarityConfig): number
	local sum = totalWeight(cfg)
	local w = cfg.Weight[rarity]
	if sum <= 0 or w == nil or w <= 0 then
		return 0
	end
	return w / sum
end

-- 1234567 -> "1,234,567"
function RarityStyle.thousands(n: number): string
	local s = tostring(math.floor(math.abs(n) + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return if n < 0 then "-" .. out else out
end

-- "1 in 20". Rounds to the nearest whole X; impossible rolls say "never".
function RarityStyle.oddsText(chance: number): string
	if chance ~= chance or chance <= 0 then
		return "never"
	end
	if chance >= 1 then
		return "1 in 1"
	end
	return "1 in " .. RarityStyle.thousands(1 / chance)
end

-- Every tier with its chance and percent text, in Order (rarest last).
function RarityStyle.oddsTable(cfg: RarityConfig): { { rarity: string, chance: number, percent: string, odds: string } }
	local rows = {}
	for _, name in cfg.Order do
		local c = RarityStyle.chance(name, cfg)
		table.insert(rows, {
			rarity = name,
			chance = c,
			percent = string.format("%g%%", math.floor(c * 1000 + 0.5) / 10),
			odds = RarityStyle.oddsText(c),
		})
	end
	return rows
end

-- Index of a tier in Order (1 = most common), 0 if unknown.
function RarityStyle.rank(rarity: string, cfg: RarityConfig): number
	for i, name in cfg.Order do
		if name == rarity then
			return i
		end
	end
	return 0
end

-- The reveal: light each rung from the bottom up to the rolled tier, flare
-- from `bloomFrom` up, then hold the card.
function RarityStyle.reveal(
	rarity: string,
	cfg: RarityConfig,
	step: number,
	bloomFrom: string,
	bloomSeconds: number,
	hold: number
): RevealBeats
	local rank = RarityStyle.rank(rarity, cfg)
	local climb = {}
	for i = 1, rank do
		table.insert(climb, cfg.Order[i])
	end
	local bloom = rank > 0 and rank >= RarityStyle.rank(bloomFrom, cfg) and RarityStyle.rank(bloomFrom, cfg) > 0
	local climbSeconds = #climb * step
	return {
		climb = climb,
		climbSeconds = climbSeconds,
		bloom = bloom,
		total = climbSeconds + (if bloom then bloomSeconds else 0) + hold,
	}
end

return RarityStyle
