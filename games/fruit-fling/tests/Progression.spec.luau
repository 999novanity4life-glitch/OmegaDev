--!nocheck
return function(t, load)
	local Progression = load("src/shared/Progression")
	local describe, it, expect = t.describe, t.it, t.expect

	describe("Progression", function()
		it("starts at level 1 with 0 xp", function()
			expect(Progression.levelForXp(0)).toBe(1)
		end)
		it("xpForLevel is strictly increasing", function()
			for level = 2, 50 do
				expect(Progression.xpForLevel(level) > Progression.xpForLevel(level - 1)).toBeTruthy()
			end
		end)
		it("levelForXp inverts xpForLevel", function()
			for level = 1, 50 do
				expect(Progression.levelForXp(Progression.xpForLevel(level))).toBe(level)
			end
		end)
		it("progressToNext stays within 0..1", function()
			for xp = 0, 5000, 37 do
				local p = Progression.progressToNext(xp)
				expect(p >= 0 and p <= 1).toBeTruthy()
			end
		end)
		it("caps at max level", function()
			expect(Progression.levelForXp(1e12)).toBe(100)
			expect(Progression.progressToNext(1e12)).toBe(1)
		end)
	end)
end
