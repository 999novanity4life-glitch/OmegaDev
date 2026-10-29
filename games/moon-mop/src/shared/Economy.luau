--!strict
-- Money rules: prices after discounts, sector and region rewards, pod payouts, away earnings.
-- Pure module. `fx` is the summed Upgrade Board effects (Upgrades.effects).

local Config = require(script.Parent.Config)

type Effects = { [string]: number }

local Economy = {}

local function pct(fx: Effects?, key: string): number
	return if fx then (fx[key] or 0) / 100 else 0
end

local function money(x: number): number
	-- cents are kept so small payouts still add up; the HUD rounds for display
	return math.floor(x * 100 + 0.5) / 100
end
Economy.round = money

-- Price after Supplier Network (and the Market capstone). Never below a cent.
function Economy.price(base: number, fx: Effects?): number
	local off = math.clamp(pct(fx, "discountPct"), 0, 0.5)
	return math.max(0.01, money(base * (1 - off)))
end

-- Reward for finishing one sector, rising from SectorNear by the station to SectorFar.
function Economy.sectorReward(angleFromNorthDeg: number, fx: Effects?): number
	local r = Config.Rewards
	local t = math.clamp(angleFromNorthDeg / r.SectorFarAngle, 0, 1)
	local base = r.SectorNear + (r.SectorFar - r.SectorNear) * t
	base = math.floor(base / 5 + 0.5) * 5
	return money(base * (1 + pct(fx, "sectorPct")))
end

function Economy.regionReward(fx: Effects?): number
	local base = Config.Rewards.Region * (1 + pct(fx, "regionPct"))
	return money(base + (if fx then fx.regionBounty or 0 else 0))
end

function Economy.flagReward(fx: Effects?): number
	return money(Config.Rewards.Flag * (1 + pct(fx, "flagPct")))
end

function Economy.probeReward(fx: Effects?): number
	return money(Config.Rewards.Probe * (1 + pct(fx, "probePct")))
end

export type Product = "Dust" | "Stardust" | "Glass" | "Gem"

function Economy.valuePerKg(product: Product, fx: Effects?): number
	local base = Config.Dust.PricePerKg
	if product == "Stardust" then
		return base * Config.Dust.StardustMultiplier * (1 + pct(fx, "stardustPct"))
	elseif product == "Glass" then
		return base * Config.Automation.GlassValue * (1 + pct(fx, "productPct"))
	elseif product == "Gem" then
		return base * Config.Automation.GemValue * (1 + pct(fx, "productPct"))
	end
	return base
end

export type Pod = { kg: number, stardust: number? }

-- Payout for depositing pods at once: dust value, Market Contracts and the Bulk Launch bonus.
-- `fee` is a fraction taken off (the Pocket Drop Pad charges 10%).
function Economy.depositPayout(pods: { Pod }, fx: Effects?, fee: number?): number
	local total = 0
	for _, pod in pods do
		local star = math.clamp(pod.stardust or 0, 0, pod.kg)
		total += (pod.kg - star) * Economy.valuePerKg("Dust", fx) + star * Economy.valuePerKg("Stardust", fx)
	end
	local bulk = pct(fx, "bulkPct") * math.min(math.max(#pods - 1, 0), 5)
	total *= 1 + pct(fx, "launchPct") + bulk
	return money(total * (1 - (fee or 0)))
end

-- Payout for machine pods arriving at a Pod Cannon or Pod Catcher.
function Economy.productPayout(product: Product, kg: number, fx: Effects?): number
	return money(kg * Economy.valuePerKg(product, fx) * (1 + pct(fx, "launchPct")))
end

function Economy.teleportPrice(fx: Effects?): number
	local off = if fx then fx.teleportOff or 0 else 0
	return math.max(0, Config.Stations.TeleportPrice - off)
end

function Economy.packUpgradeCost(tool: Config.ToolDef): number
	local s = Config.Supply
	return math.max(s.PackUpgradeMinCost, math.floor(tool.price * s.PackUpgradeCostFactor + 0.5))
end

function Economy.slotPrice(slot: number): number?
	return Config.Supply.BeltSlotPrices[slot]
end

-- Price of the next carry slot after `bought` purchases (nil when maxed).
function Economy.carryPrice(bought: number): number?
	return Config.Supply.PodCarryPrices[bought + 1]
end

function Economy.octoPrice(owned: number): number
	local base = 20000
	for _, b in Config.Buildings do
		if b.id == "CosmicOcto" then
			base = b.price
		end
	end
	return math.floor(base * Config.Automation.OctoPriceGrowth ^ owned + 0.5)
end

function Economy.beltPrice(length: number): number
	local per = 0.15
	for _, b in Config.Buildings do
		if b.id == "Belt" then
			per = b.price
		end
	end
	return money(math.max(1, length) * per)
end

function Economy.vehicleUpgradeCost(vehiclePrice: number, level: number): number
	local u = Config.VehicleUpgrades
	return math.floor(vehiclePrice * u.CostFactor * u.Growth ^ (level - 1) + 0.5)
end

-- "While you were away": a share of the automation rate ($/min), capped in hours.
function Economy.awayEarnings(ratePerMinute: number, secondsAway: number, fx: Effects?): number
	local a = Config.Away
	if secondsAway < a.MinMinutes * 60 or ratePerMinute <= 0 then
		return 0
	end
	local hours = a.MaxHours + (if fx then fx.awayHours or 0 else 0)
	local minutes = math.min(secondsAway / 60, hours * 60)
	return money(ratePerMinute * minutes * (a.Fraction + pct(fx, "awayPct")))
end

-- Refund for removing a building: full inside the grace window, then LateRefund.
function Economy.refund(paid: number, secondsSincePlaced: number): number
	local a = Config.Automation
	return money(paid * (if secondsSincePlaced <= a.RefundSeconds then 1 else a.LateRefund))
end

return table.freeze(Economy)
