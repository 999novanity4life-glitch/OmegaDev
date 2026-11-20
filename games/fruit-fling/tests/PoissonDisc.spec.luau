--!nocheck
return function(t, load)
	local PoissonDisc = load("src/shared/PoissonDisc")
	local describe, it, expect = t.describe, t.it, t.expect
	local area = { minX = 0, maxX = 100, minZ = 0, maxZ = 100 }

	describe("PoissonDisc", function()
		it("keeps every pair at least `spacing` apart", function()
			local pts = PoissonDisc.sample(area, 8, 1)
			expect(#pts > 40).toBeTruthy()
			for i = 1, #pts do
				for j = i + 1, #pts do
					local d = math.sqrt((pts[i].x - pts[j].x) ^ 2 + (pts[i].z - pts[j].z) ^ 2)
					expect(d >= 8 - 1e-9).toBeTruthy()
				end
			end
		end)
		it("never puts a point in a keep-clear zone", function()
			local clear = { minX = 40, maxX = 60, minZ = -1000, maxZ = 1000 }
			for _, p in PoissonDisc.sample(area, 6, 2, { clear }) do
				expect(p.x < 40 or p.x > 60).toBeTruthy()
			end
		end)
		it("is deterministic per seed and respects maxPoints", function()
			local a = PoissonDisc.sample(area, 10, 3, nil, 12)
			local b = PoissonDisc.sample(area, 10, 3, nil, 12)
			expect(#a).toBe(12)
			for i = 1, #a do
				expect(a[i].x).toBe(b[i].x)
			end
		end)
	end)
end
