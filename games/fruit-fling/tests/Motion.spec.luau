--!nocheck
return function(t, load)
	local Motion = load("src/shared/Motion")
	local describe, it, expect = t.describe, t.it, t.expect

	describe("Motion.spring", function()
		it("critically damped spring settles on the target without overshoot", function()
			local x, v = 0, 0
			local peak = 0
			for _ = 1, 240 do
				x, v = Motion.spring(x, v, 1, 3, 1, 1 / 60)
				peak = math.max(peak, x)
			end
			expect(x).toBeNear(1, 1e-3)
			expect(peak <= 1.001).toBeTruthy()
		end)
		it("bouncy spring overshoots", function()
			local x, v = 0, 0
			local peak = 0
			for _ = 1, 120 do
				x, v = Motion.spring(x, v, 1, 3, 0.3, 1 / 60)
				peak = math.max(peak, x)
			end
			expect(peak > 1.2).toBeTruthy()
		end)
	end)

	describe("Motion.roll", function()
		it("reaches the target and never passes it", function()
			local shown = 0
			for _ = 1, 600 do
				shown = Motion.roll(shown, 142.6, 1 / 60, 14, 0.4)
				expect(shown <= 142.6).toBeTruthy()
			end
			expect(shown).toBe(142.6)
		end)
		it("rolls down too and respects the minimum speed", function()
			expect(Motion.roll(10, 0, 1, 0.000001, 4)).toBeNear(6, 1e-6)
			expect(Motion.roll(5, 5, 1, 14, 1)).toBe(5)
		end)
	end)

	describe("Motion.splitDistance", function()
		it("splits whole and tenths", function()
			local a, b = Motion.splitDistance(142.63)
			expect(a).toBe("142")
			expect(b).toBe(".6")
			a, b = Motion.splitDistance(9.96)
			expect(a).toBe("10")
			expect(b).toBe(".0")
		end)
		it("clamps bad input to zero", function()
			local a, b = Motion.splitDistance(0 / 0)
			expect(a .. b).toBe("0.0")
			a, b = Motion.splitDistance(-5)
			expect(a .. b).toBe("0.0")
		end)
	end)

	describe("Motion.hsv / rainbow", function()
		it("primary hues", function()
			local r = Motion.hsv(0, 1, 1)
			expect(r[1]).toBe(255)
			expect(r[2]).toBe(0)
			local g = Motion.hsv(1 / 3, 1, 1)
			expect(g[2]).toBe(255)
			expect(g[1]).toBe(0)
		end)
		it("rainbow stays in 0..255 and cycles", function()
			for i = 0, 100 do
				local c = Motion.rainbow(i * 0.1, 0.35)
				for _, ch in c do
					expect(ch >= 0 and ch <= 255).toBeTruthy()
				end
			end
			local a, b = Motion.rainbow(0, 0.5), Motion.rainbow(2, 0.5)
			expect(a[1]).toBe(b[1])
		end)
	end)

	describe("Motion.extrude / splitWidth / backOut", function()
		it("extrude goes deepest-first and gets lighter toward the face", function()
			local layers = Motion.extrude(3, 4)
			expect(#layers).toBe(3)
			expect(layers[1].offset).toBe(12)
			expect(layers[3].offset).toBe(4)
			expect(layers[1].shade < layers[3].shade).toBeTruthy()
		end)
		it("split closes to zero", function()
			expect(Motion.splitWidth(0, 5, 0.25)).toBe(5)
			expect(Motion.splitWidth(0.25, 5, 0.25)).toBe(0)
			expect(Motion.splitWidth(0.1, 5, 0.25) < 5).toBeTruthy()
		end)
		it("backOut overshoots and ends at 1", function()
			expect(Motion.backOut(0)).toBeNear(0, 1e-9)
			expect(Motion.backOut(1)).toBeNear(1, 1e-9)
			local peak = 0
			for i = 0, 100 do
				peak = math.max(peak, Motion.backOut(i / 100))
			end
			expect(peak > 1).toBeTruthy()
		end)
	end)
	describe("Motion.zoneAt", function()
		it("names the last zone passed", function()
			local zones = { { from = 0, name = "A" }, { from = 50, name = "B" }, { from = 160, name = "C" } }
			expect(Motion.zoneAt(-1, zones)).toBe(nil)
			expect(Motion.zoneAt(0, zones)).toBe("A")
			expect(Motion.zoneAt(49.9, zones)).toBe("A")
			expect(Motion.zoneAt(50, zones)).toBe("B")
			expect(Motion.zoneAt(999, zones)).toBe("C")
		end)
	end)
end
