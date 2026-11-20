--!nocheck
return function(t, load)
	local RarityStyle = load("src/shared/RarityStyle")
	local Config = load("src/shared/Config")
	local describe, it, expect = t.describe, t.it, t.expect
	local cfg = Config.Rarity

	describe("RarityStyle odds", function()
		it("chances sum to 1 and come from the weights", function()
			local sum = 0
			for _, name in cfg.Order do
				sum += RarityStyle.chance(name, cfg)
			end
			expect(sum).toBeNear(1, 1e-9)
			local w = cfg.Weight.Mythical
				/ (cfg.Weight.Rare + cfg.Weight.Epic + cfg.Weight.Legendary + cfg.Weight.Mythical)
			expect(RarityStyle.chance("Mythical", cfg)).toBeNear(w, 1e-9)
		end)
		it("unknown tier is impossible", function()
			expect(RarityStyle.chance("Godly", cfg)).toBe(0)
			expect(RarityStyle.oddsText(0)).toBe("never")
		end)
		it("formats 1 in X with thousands separators", function()
			expect(RarityStyle.oddsText(0.05)).toBe("1 in 20")
			expect(RarityStyle.oddsText(1 / 2500)).toBe("1 in 2,500")
			expect(RarityStyle.oddsText(1 / 1234567)).toBe("1 in 1,234,567")
			expect(RarityStyle.oddsText(1)).toBe("1 in 1")
			expect(RarityStyle.thousands(999)).toBe("999")
			expect(RarityStyle.thousands(1000)).toBe("1,000")
		end)
		it("odds table lists every tier in order", function()
			local rows = RarityStyle.oddsTable(cfg)
			expect(#rows).toBe(#cfg.Order)
			for i, row in rows do
				expect(row.rarity).toBe(cfg.Order[i])
				expect(row.odds ~= "never").toBeTruthy()
			end
		end)
	end)

	describe("RarityStyle.reveal", function()
		it("climbs to the rolled tier and blooms from Legendary", function()
			local ui = Config.UI
			local myth = RarityStyle.reveal(
				"Mythical",
				cfg,
				ui.RevealClimbStep,
				ui.RevealBloomFrom,
				ui.RevealBloomSeconds,
				ui.RevealHoldSeconds
			)
			expect(#myth.climb).toBe(#cfg.Order)
			expect(myth.climb[#myth.climb]).toBe("Mythical")
			expect(myth.bloom).toBeTruthy()
			local rare = RarityStyle.reveal(
				"Rare",
				cfg,
				ui.RevealClimbStep,
				ui.RevealBloomFrom,
				ui.RevealBloomSeconds,
				ui.RevealHoldSeconds
			)
			expect(#rare.climb).toBe(1)
			expect(rare.bloom).toBe(false)
			expect(myth.total > rare.total).toBeTruthy()
		end)
		it("an unknown tier lights nothing and never blooms", function()
			local r = RarityStyle.reveal("Godly", cfg, 0.1, "Legendary", 0.3, 1)
			expect(#r.climb).toBe(0)
			expect(r.bloom).toBe(false)
		end)
	end)
end
