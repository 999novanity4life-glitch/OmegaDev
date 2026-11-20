--!strict
-- Smart purchase offers: pick the ONE shop item that solves what just happened
-- to the player, or nothing. Pure module (no game/services), tested in
-- tests/SmartOffer.spec.luau. The server feeds it "moments" after an outcome
-- (jump landed short, fight lost, vault full...) and shows what it returns.
--
-- Why: Sharman's "Smart Offer Method" video (2026-11-20, @momentumcash):
-- shop spam on join gets closed by everyone; an offer at the moment of need
-- ("inventory is full", "just lost a fight") is the one players buy.
-- vault/09 says the same: offer at the moment of need, never on join.
--
-- Kid-safety guardrails (all numbers in Config.Shop.Offers):
--   * never in the first GraceSeconds of a session, never while busy
--   * one global cooldown, a per-session cap, and per-item snooze on "Not now"
--   * an item dismissed DismissLimit times is never offered again this session
--   * the player can turn offers off completely (muted)
--   * never offer something already owned, and never a random item
--   * the reason line states the real situation; no fake timers or scarcity

export type ItemKind = "GamePass" | "Product"

export type Item = {
	Id: string,
	Kind: ItemKind,
	Name: string,
	Price: number, -- Robux, shown on every offer
	Berries: number?, -- Berry packs only: how many Berries the pack grants
}

export type Rules = {
	GraceSeconds: number,
	CooldownSeconds: number,
	MaxPerSession: number,
	SnoozeSeconds: number,
	DismissLimit: number,
	AfterPurchaseQuietSeconds: number,
	NearMissFraction: number, -- jump short by at most this fraction of the gate
	ShortStreakForTraining: number, -- this many short jumps in a row -> 2x Training
	LongTrainingSeconds: number, -- this long hitting dummies -> Auto Train
	CelebrationItems: { string }, -- cosmetic offered after a new arc, first unowned wins
}

export type State = {
	sessionStart: number,
	lastOfferAt: number?,
	lastPurchaseAt: number?,
	offersShown: number,
	owned: { [string]: boolean },
	snoozedUntil: { [string]: number },
	dismissals: { [string]: number },
	muted: boolean,
	busy: boolean, -- mid-jump, in a cutscene, mid-fight: never interrupt
}

export type Moment =
	{
		kind: "JumpShort",
		shortBy: number, -- distance still missing to the next arc
		gate: number, -- distance of that arc gate
		arcName: string,
		shortStreak: number, -- consecutive jumps that fell short
	}
	| {
		kind: "FightLost",
		opponent: string,
	}
	| {
		kind: "BerriesShort",
		need: number, -- Berries still missing for what they tried to buy
		wanted: string, -- e.g. "Iron Dummy"
	}
	| {
		kind: "VaultFull",
	}
	| {
		kind: "ArcUnlocked",
		arcName: string,
	}
	| {
		kind: "LongTraining",
		seconds: number,
	}

export type Offer = {
	itemId: string,
	reason: string, -- one honest line about why we're suggesting it
	moment: string,
}

local SmartOffer = {}

function SmartOffer.newState(now: number): State
	return {
		sessionStart = now,
		lastOfferAt = nil,
		lastPurchaseAt = nil,
		offersShown = 0,
		owned = {},
		snoozedUntil = {},
		dismissals = {},
		muted = false,
		busy = false,
	}
end

local function formatNumber(n: number): string
	local s = tostring(math.floor(n + 0.5))
	local out = s
	while true do
		local replaced, count = string.gsub(out, "^(-?%d+)(%d%d%d)", "%1,%2")
		out = replaced
		if count == 0 then
			break
		end
	end
	return out
end
SmartOffer.formatNumber = formatNumber

-- Can this specific item be offered right now?
function SmartOffer.itemAllowed(item: Item, state: State, rules: Rules, now: number): boolean
	if item.Kind == "GamePass" and state.owned[item.Id] then
		return false
	end
	if (state.dismissals[item.Id] or 0) >= rules.DismissLimit then
		return false
	end
	local snooze = state.snoozedUntil[item.Id]
	if snooze and now < snooze then
		return false
	end
	return true
end

-- Session-wide gate: is the player open to any offer at all right now?
function SmartOffer.sessionAllowed(state: State, rules: Rules, now: number): boolean
	if state.muted or state.busy then
		return false
	end
	if now - state.sessionStart < rules.GraceSeconds then
		return false
	end
	if state.offersShown >= rules.MaxPerSession then
		return false
	end
	if state.lastOfferAt and now - state.lastOfferAt < rules.CooldownSeconds then
		return false
	end
	if state.lastPurchaseAt and now - state.lastPurchaseAt < rules.AfterPurchaseQuietSeconds then
		return false
	end
	return true
end

-- Smallest Berry pack that covers `need`, so we never upsell a bigger pack
-- than the gap. nil if no single pack covers it (we don't push a stack).
function SmartOffer.smallestPackFor(need: number, catalog: { [string]: Item }): Item?
	local best: Item? = nil
	for _, item in catalog do
		local berries = item.Berries
		if berries and berries >= need then
			if best == nil or berries < (best.Berries :: number) then
				best = item
			end
		end
	end
	return best
end

-- The one rule table: moment -> candidate item ids (best first) + reason.
local function candidates(moment: Moment, catalog: { [string]: Item }, rules: Rules): ({ string }, string)
	if moment.kind == "JumpShort" then
		if moment.gate <= 0 or moment.shortBy <= 0 then
			return {}, ""
		end
		local list = {}
		if moment.shortBy / moment.gate <= rules.NearMissFraction then
			table.insert(list, "JumpSurge")
		end
		if moment.shortStreak >= rules.ShortStreakForTraining then
			table.insert(list, "DoubleTraining")
		end
		return list, string.format("So close! Only %s m short of %s.", formatNumber(moment.shortBy), moment.arcName)
	elseif moment.kind == "FightLost" then
		return { "DoubleTraining" }, string.format("%s was too strong this time. Train twice as fast.", moment.opponent)
	elseif moment.kind == "BerriesShort" then
		local pack = SmartOffer.smallestPackFor(moment.need, catalog)
		if not pack then
			return {}, ""
		end
		return { pack.Id },
			string.format("You need %s more Berries for the %s.", formatNumber(moment.need), moment.wanted)
	elseif moment.kind == "VaultFull" then
		return { "FruitVault" }, "Your Fruit Vault is full. Keep every fruit you find."
	elseif moment.kind == "ArcUnlocked" then
		return table.clone(rules.CelebrationItems), string.format("You reached %s! Dive in style.", moment.arcName)
	elseif moment.kind == "LongTraining" then
		if moment.seconds < rules.LongTrainingSeconds then
			return {}, ""
		end
		return { "AutoTrain" }, "Long training session! Let your fighter keep swinging for you."
	end
	return {}, ""
end

-- Decide what (if anything) to offer for this moment. Does not change state;
-- call recordShown when the offer actually appears on screen.
function SmartOffer.decide(moment: Moment, state: State, catalog: { [string]: Item }, rules: Rules, now: number): Offer?
	if not SmartOffer.sessionAllowed(state, rules, now) then
		return nil
	end
	local list, reason = candidates(moment, catalog, rules)
	for _, id in list do
		local item = catalog[id]
		if item and SmartOffer.itemAllowed(item, state, rules, now) then
			local kind: string = moment.kind
			return { itemId = id, reason = reason, moment = kind }
		end
	end
	return nil
end

function SmartOffer.recordShown(state: State, now: number)
	state.offersShown += 1
	state.lastOfferAt = now
end

function SmartOffer.recordDismiss(state: State, itemId: string, rules: Rules, now: number)
	state.dismissals[itemId] = (state.dismissals[itemId] or 0) + 1
	state.snoozedUntil[itemId] = now + rules.SnoozeSeconds
end

function SmartOffer.recordPurchase(state: State, item: Item, now: number)
	state.lastPurchaseAt = now
	if item.Kind == "GamePass" then
		state.owned[item.Id] = true
	end
end

return SmartOffer
