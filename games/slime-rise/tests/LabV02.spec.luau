--!nocheck
return function(t, load)
	local PlayerData = load("src/shared/PlayerData")
	local ShaftLayout = load("src/shared/ShaftLayout")
	local PuzzleRules = load("src/shared/PuzzleRules")
	local PartyRules = load("src/shared/PartyRules")
	local Config = load("src/shared/Config")
	local describe, it, expect = t.describe, t.it, t.expect

	describe("PlayerData", function()
		it("template starts empty", function()
			local d = PlayerData.template()
			expect(d.Crowns).toBe(0)
			expect(d.Escapes).toBe(0)
			expect(d.BestTime).toBe(0)
		end)
		it("sanitize fixes NaN, infinity, negatives and wrong types", function()
			local d = { Version = 0, Crowns = 0 / 0, Escapes = -3, BestTime = math.huge }
			PlayerData.sanitize(d)
			expect(d.Crowns).toBe(0)
			expect(d.Escapes).toBe(0)
			expect(d.BestTime).toBe(0)
			expect(d.Version).toBe(PlayerData.VERSION)
			local e = { Version = 1, Crowns = "lots", Escapes = 2.7, BestTime = 12.345 }
			PlayerData.sanitize(e)
			expect(e.Crowns).toBe(0)
			expect(e.Escapes).toBe(2)
			expect(e.BestTime).toBeNear(12.35, 1e-9)
		end)
		it("addCrowns never goes negative", function()
			local d = PlayerData.template()
			expect(PlayerData.addCrowns(d, 3)).toBe(3)
			expect(PlayerData.addCrowns(d, -10)).toBe(3)
		end)
		it("best times are kept per map, and bad ones are cleaned", function()
			local d = PlayerData.template()
			expect(PlayerData.recordEscape(d, 90, "Shaft")).toBeTruthy()
			expect(PlayerData.recordEscape(d, 120, "Cryo")).toBeTruthy()
			expect(PlayerData.recordEscape(d, 130, "Cryo")).toBeFalsy()
			expect(d.BestTimes.Shaft).toBeNear(90, 1e-9)
			expect(d.BestTimes.Cryo).toBeNear(120, 1e-9)
			expect(d.BestTime).toBeNear(90, 1e-9)
			local bad = {
				Version = 1,
				Crowns = 0,
				Escapes = 0,
				BestTime = 0,
				BestTimes = { Cryo = -5, [3] = 9, Shaft = 61.234 },
			}
			PlayerData.sanitize(bad)
			expect(bad.BestTimes.Cryo).toBe(nil)
			expect(bad.BestTimes.Shaft).toBeNear(61.23, 1e-9)
			local old = { Version = 1, Crowns = 4, Escapes = 1, BestTime = 50 }
			PlayerData.sanitize(old)
			expect(type(old.BestTimes)).toBe("table")
		end)
		it("recordEscape counts and keeps the best time", function()
			local d = PlayerData.template()
			expect(PlayerData.recordEscape(d, 90)).toBeTruthy()
			expect(PlayerData.recordEscape(d, 100)).toBeFalsy()
			expect(PlayerData.recordEscape(d, 80.5)).toBeTruthy()
			expect(d.Escapes).toBe(3)
			expect(d.BestTime).toBeNear(80.5, 1e-9)
		end)
	end)

	describe("ShaftLayout", function()
		it("is deterministic for a seed", function()
			local a = ShaftLayout.build(1234)
			local b = ShaftLayout.build(1234)
			expect(a.tiers[2].hatchAngle).toBeNear(b.tiers[2].hatchAngle, 1e-9)
			expect(a.tiers[3].puzzle).toBe(b.tiers[3].puzzle)
		end)
		it("has every tier and a different puzzle on each", function()
			local layout = ShaftLayout.build(42)
			expect(#layout.tiers).toBe(Config.Shaft.Tiers)
			local seen = {}
			for _, tier in layout.tiers do
				expect(seen[tier.puzzle]).toBe(nil)
				seen[tier.puzzle] = true
			end
		end)
		it("every lab-equipment route is makeable, landing included", function()
			local CourseLayout = load("src/shared/CourseLayout")
			for seed = 1, 60 do
				local layout = ShaftLayout.build(seed * 97)
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
					expect(CourseLayout.valid(route)).toBeTruthy()
				end
			end
		end)
		it("each route fits around the shaft before the landing", function()
			local layout = ShaftLayout.build(5)
			for _, tier in layout.tiers do
				local first = tier.course[1].angle
				local span = (tier.hatchAngle - first) % 360
				expect(span < 300).toBeTruthy()
			end
		end)
		it("the last bridge step reaches the next floor", function()
			local layout = ShaftLayout.build(7)
			for _, tier in layout.tiers do
				local last = tier.bridge[#tier.bridge]
				expect(tier.ceilingY - last.y <= 4).toBeTruthy()
			end
		end)
	end)

	describe("PuzzleRules", function()
		it("solo runs still get a real puzzle", function()
			expect(PuzzleRules.valveCount(1)).toBe(2)
			expect(PuzzleRules.plateCount(1)).toBe(2)
			expect(PuzzleRules.plateWeights(1)).toBe(1)
			expect(PuzzleRules.fuseCount(1)).toBe(1)
		end)
		it("every plate can be held at once (players + ballast), capped at 3", function()
			for n = 1, 8 do
				local plates = PuzzleRules.plateCount(n)
				expect(plates <= n + PuzzleRules.plateWeights(n)).toBeTruthy()
				expect(plates <= 3).toBeTruthy()
				expect(plates >= 2).toBeTruthy()
			end
			expect(PuzzleRules.plateWeights(2)).toBe(0)
		end)
		it("color code is deterministic and in range", function()
			local a = PuzzleRules.colorCode(99, 3, 4)
			local b = PuzzleRules.colorCode(99, 3, 4)
			for i = 1, 3 do
				expect(a[i]).toBe(b[i])
				expect(a[i] >= 1 and a[i] <= 4).toBeTruthy()
			end
			expect(PuzzleRules.codeMatches(a, b)).toBeTruthy()
			expect(PuzzleRules.codeMatches({ 1, 1 }, a)).toBeFalsy()
		end)
	end)

	describe("PartyRules", function()
		it("solo pods take only the host", function()
			expect(PartyRules.canJoin("Solo", 0, 1)).toBeTruthy()
			expect(PartyRules.canJoin("Solo", 1, 8)).toBeFalsy()
		end)
		it("public pods fill up to max", function()
			expect(PartyRules.canJoin("Public", 3, 4)).toBeTruthy()
			expect(PartyRules.canJoin("Public", 4, 4)).toBeFalsy()
		end)
		it("max stays between party size and the cap", function()
			expect(PartyRules.clampMax(1, 3, 8)).toBe(3)
			expect(PartyRules.clampMax(12, 1, 8)).toBe(8)
			expect(PartyRules.clampMax(5.9, 1, 8)).toBe(5)
		end)
	end)
end
