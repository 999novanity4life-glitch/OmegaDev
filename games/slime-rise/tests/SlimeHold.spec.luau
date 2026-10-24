--!nocheck
return function(t, load)
	local SlimeCurve = load("src/shared/SlimeCurve")
	local MapDefs = load("src/shared/MapDefs")
	local Config = load("src/shared/Config")
	local describe, it, expect = t.describe, t.it, t.expect

	describe("Slime hold (freeze on solve)", function()
		it("the clock stands still during a hold, then carries on", function()
			local held, hs, hu = SlimeCurve.addHold(100, 6, 0, nil, nil)
			expect(SlimeCurve.clock(99, held, hs, hu)).toBeNear(99, 1e-9)
			expect(SlimeCurve.clock(103, held, hs, hu)).toBeNear(100, 1e-9) -- frozen
			expect(SlimeCurve.clock(106, held, hs, hu)).toBeNear(100, 1e-9) -- end of hold
			expect(SlimeCurve.clock(110, held, hs, hu)).toBeNear(104, 1e-9) -- 6 s behind
		end)
		it("a second solve during a hold extends it; after it, holds bank up", function()
			local held, hs, hu = SlimeCurve.addHold(100, 6, 0, nil, nil)
			held, hs, hu = SlimeCurve.addHold(103, 6, held, hs, hu)
			expect(hu).toBeNear(112, 1e-9)
			expect(SlimeCurve.clock(112, held, hs, hu)).toBeNear(100, 1e-9)
			held, hs, hu = SlimeCurve.addHold(150, 6, held, hs, hu)
			expect(held).toBeNear(12, 1e-9)
			expect(SlimeCurve.clock(153, held, hs, hu)).toBeNear(138, 1e-9)
		end)
		it("the slime height never jumps across a hold", function()
			local held, hs, hu = SlimeCurve.addHold(50, 6, 0, nil, nil)
			local prev = SlimeCurve.height(SlimeCurve.clock(0, held, hs, hu), 0, 100, -15, 180, 1.25)
			for step = 0, 2000 do
				local now = step * 0.05
				local h = SlimeCurve.height(SlimeCurve.clock(now, held, hs, hu), 0, 100, -15, 180, 1.25)
				expect(h >= prev - 1e-9).toBeTruthy()
				expect(h - prev < 2).toBeTruthy()
				prev = h
			end
		end)
	end)

	describe("Round length per floor", function()
		it("every map gives at least 55 s a floor, easier maps more", function()
			local prevPerFloor = math.huge
			for _, def in MapDefs.list do
				local perFloor = (def.matchSeconds - Config.Match.HeadStartSeconds) / def.tiers
				expect(perFloor >= 55).toBeTruthy()
				expect(perFloor <= prevPerFloor + 1e-9).toBeTruthy()
				prevPerFloor = perFloor
			end
		end)
	end)
end
