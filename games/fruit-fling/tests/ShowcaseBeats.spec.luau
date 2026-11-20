--!nocheck
return function(t, load)
	local ShowcaseBeats = load("src/shared/ShowcaseBeats")
	local Config = load("src/shared/Config")
	local describe, it, expect = t.describe, t.it, t.expect
	local order = Config.Rarity.Order
	local cfg = Config.UI.Showcase

	describe("ShowcaseBeats", function()
		it("climbs every tier up to the rolled one, in order", function()
			local p = ShowcaseBeats.plan("Legendary", order, cfg)
			expect(#p.steps).toBe(3)
			expect(p.steps[1].tier).toBe("Rare")
			expect(p.steps[3].tier).toBe("Legendary")
			for i = 2, #p.steps do
				expect(p.steps[i].time > p.steps[i - 1].time).toBeTruthy()
			end
			expect(p.slam).toBe(p.steps[3].time)
			expect(p.total > p.slam).toBeTruthy()
		end)
		it("rarer tiers last longer and get more rays and sparks", function()
			local prev = nil
			for _, name in order do
				local p = ShowcaseBeats.plan(name, order, cfg)
				if prev then
					expect(p.total > prev.total).toBeTruthy()
					expect(p.rays > prev.rays).toBeTruthy()
					expect(p.burst > prev.burst).toBeTruthy()
				end
				prev = p
			end
		end)
		it("unknown tier falls back to the first", function()
			local p = ShowcaseBeats.plan("Godly", order, cfg)
			expect(#p.steps).toBe(1)
			expect(p.steps[1].tier).toBe(order[1])
		end)
		it("higher tiers keep every lower layer", function()
			local keys = { "aura", "rings", "lightning", "pillar", "halos", "orbit", "flash" }
			for r = 2, 4 do
				local lo, hi = ShowcaseBeats.layers(r - 1), ShowcaseBeats.layers(r)
				for _, k in keys do
					if lo[k] then
						expect(hi[k]).toBe(true)
					end
				end
			end
			expect(ShowcaseBeats.layers(1).lightning).toBe(false)
			expect(ShowcaseBeats.layers(4).orbit).toBe(true)
		end)
		it("ring eases out from r0 to r1", function()
			expect(ShowcaseBeats.ring(0, 0.5, 1, 9)).toBe(1)
			expect(ShowcaseBeats.ring(0.5, 0.5, 1, 9)).toBe(9)
			expect(ShowcaseBeats.ring(0.25, 0.5, 1, 9) > 5).toBeTruthy()
		end)
		it("star flare and zoom only on the top tiers, flare longer when rarer", function()
			expect(ShowcaseBeats.plan("Rare", order, cfg).flare).toBe(0)
			expect(ShowcaseBeats.plan("Epic", order, cfg).flare).toBe(0)
			local l, m = ShowcaseBeats.plan("Legendary", order, cfg), ShowcaseBeats.plan("Mythical", order, cfg)
			expect(l.flare > 0).toBeTruthy()
			expect(m.flare > l.flare).toBeTruthy()
			expect(l.zoom).toBe(0)
			expect(m.zoom > 0).toBeTruthy()
			expect(l.steps[1].time).toBeNear(cfg.RiseSeconds + l.flare, 1e-9)
		end)
		it("bolt keeps its ends fixed", function()
			local pts = ShowcaseBeats.bolt({ 0, 0, 0 }, { 0, 10, 0 }, 6, 1, function()
				return 0.9
			end)
			expect(#pts).toBe(6)
			expect(pts[1][2]).toBe(0)
			expect(pts[6][2]).toBe(10)
			expect(pts[3][1]).toBeNear(0.8, 1e-9)
		end)
	end)
end
