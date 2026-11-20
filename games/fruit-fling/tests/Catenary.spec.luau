--!nocheck
return function(t, load)
	local Catenary = load("src/shared/Catenary")
	local describe, it, expect = t.describe, t.it, t.expect

	describe("Catenary", function()
		local a, b = { x = 0, y = 10, z = 0 }, { x = 0, y = 10, z = 8 }
		it("starts and ends on the anchors", function()
			local pts = Catenary.points(a, b, 1, 8)
			expect(#pts).toBe(9)
			expect(pts[1].y).toBeNear(10)
			expect(pts[9].z).toBeNear(8)
			expect(pts[9].y).toBeNear(10)
		end)
		it("sags by exactly `sag` at the middle and never rises above the chord", function()
			local pts = Catenary.points(a, b, 1.5, 8)
			expect(pts[5].y).toBeNear(8.5)
			for _, p in pts do
				expect(p.y <= 10 + 1e-9).toBeTruthy()
			end
		end)
		it("scales sag with span", function()
			expect(Catenary.sagFor(10, 0.1)).toBeNear(1)
			expect(Catenary.sagFor(-5, 0.1)).toBe(0)
		end)
		it("a sagging rope is longer than the straight span", function()
			expect(Catenary.length(Catenary.points(a, b, 1, 16)) > 8).toBeTruthy()
		end)
	end)
end
