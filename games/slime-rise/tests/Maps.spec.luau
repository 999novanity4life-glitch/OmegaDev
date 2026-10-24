--!nocheck
return function(t, load)
	local Footprint = load("src/shared/Footprint")
	local MapDefs = load("src/shared/MapDefs")
	local ShaftLayout = load("src/shared/ShaftLayout")
	local CourseLayout = load("src/shared/CourseLayout")
	local describe, it, expect = t.describe, t.it, t.expect

	describe("Footprint", function()
		it("a circle matches the old round shaft exactly", function()
			local fp = Footprint.new({ shape = "circle", radius = 36 })
			for _, a in { 0, 37, 145, 290 } do
				for _, r in { 5, 20, 27, 36 } do
					local x, z = Footprint.polar(fp, a, r)
					expect(x).toBeNear(math.cos(math.rad(a)) * r, 0.35)
					expect(z).toBeNear(math.sin(math.rad(a)) * r, 0.35)
				end
			end
		end)
		it("a rectangle's walls are where they should be", function()
			local fp = Footprint.new({ shape = "rect", width = 92, depth = 64, round = 7 })
			expect(Footprint.wall(fp, 0)).toBeNear(46, 0.01)
			expect(Footprint.wall(fp, 90)).toBeNear(32, 0.01)
			local nx, nz = Footprint.inward(fp, 0)
			expect(nx).toBeNear(-1, 1e-6)
			expect(nz).toBeNear(0, 1e-6)
		end)
		it("wall-mounted things keep their inset; the middle stays put", function()
			for _, def in
				{
					{ shape = "rect", width = 92, depth = 64, round = 7 },
					{ shape = "hex", radius = 50 },
					{ shape = "cross", arm = 18, extent = 52 },
				}
			do
				local fp = Footprint.new(def)
				for a = 0, 355, 5 do
					local x, z = Footprint.polar(fp, a, 33) -- 3 studs off the reference wall
					local d = math.sqrt(x * x + z * z)
					expect(Footprint.wall(fp, a) - d).toBeNear(3, 0.05)
					local cx, cz = Footprint.polar(fp, a, 7)
					expect(math.sqrt(cx * cx + cz * cz)).toBeNear(7, 1e-6)
					expect(Footprint.contains(fp, x, z, 0.5)).toBeTruthy()
				end
			end
		end)
		it("wall segments wrap the whole perimeter", function()
			local fp = Footprint.new({ shape = "rect", width = 92, depth = 64, round = 7 })
			local total = 0
			for _, s in Footprint.segments(fp, 10) do
				expect(s.width <= 10 + 1e-6).toBeTruthy()
				total += s.width
			end
			-- 2*(92+64) minus the corner cut, plus the rounded arcs.
			expect(total > 290 and total < 312).toBeTruthy()
		end)
	end)

	describe("MapDefs", function()
		it("maps get harder, bigger and longer in order", function()
			local prev
			for _, def in MapDefs.list do
				if prev then
					expect(def.difficulty > prev.difficulty).toBeTruthy()
					expect(def.tiers >= prev.tiers).toBeTruthy()
					expect(def.gaps[1] >= prev.gaps[1]).toBeTruthy()
					expect(def.matchSeconds >= prev.matchSeconds).toBeTruthy()
				end
				expect(#def.gaps).toBe(def.tiers)
				prev = def
			end
		end)
		it("unknown or locked maps fall back to the first map", function()
			expect(MapDefs.get("Nope").id).toBe("Shaft")
			expect(MapDefs.get("Reactor").id).toBe("Shaft")
			expect(MapDefs.get("Cryo").id).toBe("Cryo")
			expect(MapDefs.isPlayable("Cryo")).toBe(true)
			expect(MapDefs.isPlayable("Reactor")).toBe(false)
			expect(MapDefs.isPlayable(5)).toBe(false)
		end)
	end)

	describe("Cryo Vault layout", function()
		it("has 5 floors, each with a different puzzle", function()
			for seed = 1, 20 do
				local layout = ShaftLayout.build(seed * 31, "Cryo")
				expect(#layout.tiers).toBe(5)
				local seen = {}
				for _, tier in layout.tiers do
					expect(seen[tier.puzzle]).toBe(nil)
					seen[tier.puzzle] = true
				end
			end
		end)
		it("every route is makeable in the rectangular hall, landing included", function()
			local bad = {}
			for seed = 1, 60 do
				local layout = ShaftLayout.build(seed * 97, "Cryo")
				for _, tier in layout.tiers do
					local route = table.clone(tier.course)
					table.insert(route, {
						kind = "Landing",
						angle = tier.landing.angle,
						radius = tier.landing.radius,
						y = tier.landing.y - tier.floorY,
						half = 7,
						base = 0,
						assisted = false,
					})
					if not CourseLayout.valid(route, true, layout.footprint) then
						table.insert(bad, string.format("seed %d tier %d", seed, tier.index))
					end
					for _, e in tier.course do
						if not Footprint.contains(layout.footprint, e.x, e.z, 1.5) then
							table.insert(bad, string.format("seed %d tier %d %s outside", seed, tier.index, e.kind))
						end
					end
				end
			end
			expect(table.concat(bad, " | ", 1, math.min(#bad, 10))).toBe("")
		end)
	end)
end
