--!nocheck
return function(t, load)
	local SmartOffer = load("src/shared/SmartOffer")
	local Config = load("src/shared/Config")
	local describe, it, expect = t.describe, t.it, t.expect

	local catalog = {}
	for id, item in Config.Shop.Items do
		catalog[id] = {
			Id = id,
			Kind = item.Kind,
			Name = item.Name,
			Price = item.Price,
			Berries = item.Berries,
		}
	end
	local rules = Config.Shop.Offers

	-- A state well past the grace period with nothing shown yet.
	local function ready()
		return SmartOffer.newState(0), rules.GraceSeconds + 1
	end

	local nearMiss = { kind = "JumpShort", shortBy = 40, gate = 700, arcName = "Syrup Village", shortStreak = 1 }

	describe("SmartOffer guardrails", function()
		it("never offers in the grace period (no offers on join)", function()
			local state = SmartOffer.newState(0)
			expect(SmartOffer.decide(nearMiss, state, catalog, rules, 5)).toBeFalsy()
			expect(SmartOffer.decide(nearMiss, state, catalog, rules, rules.GraceSeconds - 1)).toBeFalsy()
		end)
		it("never offers while busy or muted", function()
			local state, now = ready()
			state.busy = true
			expect(SmartOffer.decide(nearMiss, state, catalog, rules, now)).toBeFalsy()
			state.busy = false
			state.muted = true
			expect(SmartOffer.decide(nearMiss, state, catalog, rules, now)).toBeFalsy()
		end)
		it("respects the global cooldown and the session cap", function()
			local state, now = ready()
			expect(SmartOffer.decide(nearMiss, state, catalog, rules, now)).toBeTruthy()
			SmartOffer.recordShown(state, now)
			expect(SmartOffer.decide({ kind = "VaultFull" }, state, catalog, rules, now + 10)).toBeFalsy()
			local later = now + rules.CooldownSeconds
			expect(SmartOffer.decide({ kind = "VaultFull" }, state, catalog, rules, later)).toBeTruthy()
			state.offersShown = rules.MaxPerSession
			expect(SmartOffer.decide({ kind = "VaultFull" }, state, catalog, rules, later + 9999)).toBeFalsy()
		end)
		it("snoozes an item after Not now and drops it after the dismiss limit", function()
			local state, now = ready()
			SmartOffer.recordDismiss(state, "FruitVault", rules, now)
			expect(SmartOffer.decide({ kind = "VaultFull" }, state, catalog, rules, now + 1)).toBeFalsy()
			local after = now + rules.SnoozeSeconds + 1
			expect(SmartOffer.decide({ kind = "VaultFull" }, state, catalog, rules, after)).toBeTruthy()
			SmartOffer.recordDismiss(state, "FruitVault", rules, after)
			expect(SmartOffer.decide({ kind = "VaultFull" }, state, catalog, rules, after + 99999)).toBeFalsy()
		end)
		it("never offers an owned gamepass, and stays quiet after a purchase", function()
			local state, now = ready()
			SmartOffer.recordPurchase(state, catalog.FruitVault, now)
			expect(state.owned.FruitVault).toBe(true)
			expect(SmartOffer.decide(nearMiss, state, catalog, rules, now + 1)).toBeFalsy()
			local later = now + rules.AfterPurchaseQuietSeconds + 1
			expect(SmartOffer.decide({ kind = "VaultFull" }, state, catalog, rules, later)).toBeFalsy()
		end)
	end)

	describe("SmartOffer moments", function()
		it("near miss offers Jump Surge with the real gap and arc", function()
			local state, now = ready()
			local offer = SmartOffer.decide(nearMiss, state, catalog, rules, now)
			expect(offer.itemId).toBe("JumpSurge")
			expect(offer.reason).toBe("So close! Only 40 m short of Syrup Village.")
		end)
		it("a far miss offers nothing, unless the player keeps falling short", function()
			local state, now = ready()
			local far = { kind = "JumpShort", shortBy = 500, gate = 700, arcName = "Syrup Village", shortStreak = 1 }
			expect(SmartOffer.decide(far, state, catalog, rules, now)).toBeFalsy()
			far.shortStreak = rules.ShortStreakForTraining
			expect(SmartOffer.decide(far, state, catalog, rules, now).itemId).toBe("DoubleTraining")
		end)
		it("rejects nonsense jump numbers", function()
			local state, now = ready()
			local bad = { kind = "JumpShort", shortBy = 10, gate = 0, arcName = "X", shortStreak = 9 }
			expect(SmartOffer.decide(bad, state, catalog, rules, now)).toBeFalsy()
		end)
		it("lost fight offers 2x Training, falls through to nothing once owned", function()
			local state, now = ready()
			local lost = { kind = "FightLost", opponent = "Iron Dummy" }
			expect(SmartOffer.decide(lost, state, catalog, rules, now).itemId).toBe("DoubleTraining")
			state.owned.DoubleTraining = true
			expect(SmartOffer.decide(lost, state, catalog, rules, now)).toBeFalsy()
		end)
		it("berries short offers the smallest pack that covers the gap", function()
			local state, now = ready()
			local short = { kind = "BerriesShort", need = 12500, wanted = "Iron Dummy" }
			local offer = SmartOffer.decide(short, state, catalog, rules, now)
			expect(offer.itemId).toBe("BerryChest")
			expect(offer.reason).toBe("You need 12,500 more Berries for the Iron Dummy.")
			short.need = 5000
			expect(SmartOffer.decide(short, state, catalog, rules, now).itemId).toBe("BerryPouch")
			short.need = 10000000
			expect(SmartOffer.decide(short, state, catalog, rules, now)).toBeFalsy()
		end)
		it("arc unlock offers the first unowned cosmetic", function()
			local state, now = ready()
			local unlocked = { kind = "ArcUnlocked", arcName = "Baratie" }
			expect(SmartOffer.decide(unlocked, state, catalog, rules, now).itemId).toBe(rules.CelebrationItems[1])
			state.owned[rules.CelebrationItems[1]] = true
			expect(SmartOffer.decide(unlocked, state, catalog, rules, now).itemId).toBe(rules.CelebrationItems[2])
		end)
		it("long training only after the threshold", function()
			local state, now = ready()
			local short = { kind = "LongTraining", seconds = rules.LongTrainingSeconds - 1 }
			expect(SmartOffer.decide(short, state, catalog, rules, now)).toBeFalsy()
			short.seconds = rules.LongTrainingSeconds
			expect(SmartOffer.decide(short, state, catalog, rules, now).itemId).toBe("AutoTrain")
		end)
	end)

	describe("Shop catalog", function()
		it("every item has a positive whole Robux price, a name and a cover", function()
			for id, item in Config.Shop.Items do
				expect(item.Price > 0 and item.Price % 1 == 0).toBe(true)
				expect(#item.Name > 0).toBe(true)
				expect(item.Cover ~= nil).toBe(true)
				expect(table.find(Config.Shop.Tabs, item.Tab) ~= nil).toBe(true)
				expect(item.Kind == "GamePass" or item.Kind == "Product").toBe(true)
				expect(id ~= "").toBe(true)
			end
		end)
		it("every offer target exists in the catalog", function()
			for _, id in { "JumpSurge", "DoubleTraining", "FruitVault", "AutoTrain" } do
				expect(Config.Shop.Items[id] ~= nil).toBe(true)
			end
			for _, id in rules.CelebrationItems do
				expect(Config.Shop.Items[id].Kind).toBe("GamePass")
			end
		end)
		it("formats big numbers with commas", function()
			expect(SmartOffer.formatNumber(400000)).toBe("400,000")
			expect(SmartOffer.formatNumber(999)).toBe("999")
		end)
	end)
end
