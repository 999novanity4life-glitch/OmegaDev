--!nocheck
return function(t, load)
	local TerrainGen = load("src/shared/TerrainGen")
	local describe, it, expect = t.describe, t.it, t.expect

	local params = {
		seed = 42,
		baseHeight = 40,
		amplitude = 12,
		frequency = 1 / 128,
		octaves = 4,
		persistence = 0.5,
		craters = { { x = 100, z = 100, radius = 30, depth = 8 } },
	}

	describe("TerrainGen", function()
		it("rng is deterministic per seed and stays in [0, 1)", function()
			local a, b, c = TerrainGen.rng(7), TerrainGen.rng(7), TerrainGen.rng(8)
			local same, differs = true, false
			for _ = 1, 500 do
				local x, y, z = TerrainGen.nextFloat(a), TerrainGen.nextFloat(b), TerrainGen.nextFloat(c)
				same = same and x == y
				differs = differs or x ~= z
				expect(x >= 0 and x < 1).toBeTruthy()
			end
			expect(same).toBeTruthy()
			expect(differs).toBeTruthy()
		end)
		it("heightAt is deterministic and bounded", function()
			for i = 0, 50 do
				local x, z = i * 13.7, i * 7.1
				local h = TerrainGen.heightAt(params, x, z)
				expect(h).toBe(TerrainGen.heightAt(params, x, z))
				expect(h > 40 - 12 - 8 - 1 and h < 40 + 12 + 2 + 1).toBeTruthy()
			end
		end)
		it("crater is lowest at its center and has a rim", function()
			local c = { x = 0, z = 0, radius = 20, depth = 10 }
			expect(TerrainGen.craterOffset(c, 0, 0, 0.25)).toBe(-10)
			expect(TerrainGen.craterOffset(c, 20, 0, 0.25)).toBeNear(2.5, 1e-9)
			expect(TerrainGen.craterOffset(c, 30, 0, 0.25)).toBe(0)
		end)
		it("scatter keeps the minimum distance and stays in bounds", function()
			local points = TerrainGen.scatter(3, 200, 150, 10, 400)
			expect(#points > 50).toBeTruthy()
			for i, p in points do
				expect(p.x >= 0 and p.x <= 200 and p.z >= 0 and p.z <= 150).toBeTruthy()
				for j = i + 1, #points do
					local q = points[j]
					expect((p.x - q.x) ^ 2 + (p.z - q.z) ^ 2 >= 100).toBeTruthy()
				end
			end
		end)
		it("scatter is deterministic per seed", function()
			local a, b = TerrainGen.scatter(9, 100, 100, 8, 50), TerrainGen.scatter(9, 100, 100, 8, 50)
			expect(#a).toBe(#b)
			expect(a[#a].x).toBe(b[#b].x)
		end)
		it("occupancy is 0..1 with a partial surface cell", function()
			expect(TerrainGen.occupancy(10, 0)).toBe(1)
			expect(TerrainGen.occupancy(10, 8)).toBeNear(0.5, 1e-9)
			expect(TerrainGen.occupancy(10, 12)).toBe(0)
		end)
		it("materialFor picks the first matching rule", function()
			local rules = {
				{ material = "Rock", minSlope = 0.8 },
				{ material = "Snow", minHeight = 100 },
				{ material = "Grass", maxHeight = 100 },
			}
			expect(TerrainGen.materialFor(rules, 50, 1.2, "Ground")).toBe("Rock")
			expect(TerrainGen.materialFor(rules, 120, 0.1, "Ground")).toBe("Snow")
			expect(TerrainGen.materialFor(rules, 20, 0.1, "Ground")).toBe("Grass")
		end)
		it("planChunks covers the box, aligned, within the voxel cap", function()
			local chunks = TerrainGen.planChunks(1030, 200, 513)
			local total = 0
			for _, c in chunks do
				local n = TerrainGen.voxelCount(c)
				total += n
				expect(n <= TerrainGen.MAX_VOXELS_PER_CALL).toBeTruthy()
				for _, v in { c.minX, c.minY, c.minZ, c.maxX, c.maxY, c.maxZ } do
					expect(v % 4).toBe(0)
				end
			end
			expect(total).toBe((1032 / 4) * (200 / 4) * (516 / 4))
		end)
		it("planChunks splits tall boxes to respect the cap", function()
			for _, c in TerrainGen.planChunks(512, 4096, 512, 256) do
				expect(TerrainGen.voxelCount(c) <= TerrainGen.MAX_VOXELS_PER_CALL).toBeTruthy()
			end
		end)
	end)
end
