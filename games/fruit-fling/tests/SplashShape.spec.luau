--!nocheck
return function(t, load)
	local SplashShape = load("src/shared/SplashShape")
	local Config = load("src/shared/Config")
	local cfg = Config.Splash
	local describe, it, expect = t.describe, t.it, t.expect

	describe("SplashShape.tier", function()
		it("rarer fruits make a bigger splash", function()
			for r = 2, #cfg.Tiers do
				local a = SplashShape.tier(r - 1, cfg.Tiers, false, cfg.MasterworkScale)
				local b = SplashShape.tier(r, cfg.Tiers, false, cfg.MasterworkScale)
				expect(b.column > a.column).toBeTruthy()
				expect(b.crown > a.crown).toBeTruthy()
				expect(b.reach > a.reach).toBeTruthy()
				expect(b.light > a.light).toBeTruthy()
			end
		end)
		it("there is one row per rarity", function()
			expect(#cfg.Tiers).toBe(#Config.Rarity.Order)
		end)
		it("clamps bad ranks", function()
			expect(SplashShape.tier(0, cfg.Tiers, false, 1).column).toBe(cfg.Tiers[1].column)
			expect(SplashShape.tier(99, cfg.Tiers, false, 1).column).toBe(cfg.Tiers[#cfg.Tiers].column)
			expect(SplashShape.tier(0 / 0, cfg.Tiers, false, 1).column).toBe(cfg.Tiers[1].column)
		end)
		it("masterwork scales sizes up", function()
			local m = SplashShape.tier(1, cfg.Tiers, true, cfg.MasterworkScale)
			expect(m.column).toBeNear(cfg.Tiers[1].column * cfg.MasterworkScale)
			expect(m.crown >= cfg.Tiers[1].crown).toBeTruthy()
		end)
	end)

	describe("SplashShape crown", function()
		it("droplets go up and spread all the way round", function()
			local n = 12
			local sx, sz = 0, 0
			for i = 1, n do
				local vx, vy, vz = SplashShape.crownVelocity(i, n, 10, cfg.Gravity, cfg.CrownUp, cfg.CrownOut)
				expect(vy > 0).toBeTruthy()
				sx += vx
				sz += vz
			end
			-- alternating sizes cancel out over an even count
			expect(math.abs(sx) < 1e-6).toBeTruthy()
			expect(math.abs(sz) < 1e-6).toBeTruthy()
		end)
		it("the tallest droplet stays under the column height", function()
			local peak = 0
			for i = 1, 10 do
				local _, vy = SplashShape.crownVelocity(i, 10, 10, cfg.Gravity, cfg.CrownUp, cfg.CrownOut)
				peak = math.max(peak, vy * vy / (2 * cfg.Gravity))
			end
			expect(peak <= 10 + 1e-6).toBeTruthy()
		end)
		it("a droplet lands back at water level after its air time", function()
			local vx, vy, vz = SplashShape.crownVelocity(2, 8, 12, cfg.Gravity, cfg.CrownUp, cfg.CrownOut)
			local T = SplashShape.airTime(vy, cfg.Gravity)
			local _, y = SplashShape.ballistic(T, vx, vy, vz, cfg.Gravity)
			expect(y).toBeNear(0, 1e-6)
			local _, ymid = SplashShape.ballistic(T / 2, vx, vy, vz, cfg.Gravity)
			expect(ymid > 0).toBeTruthy()
		end)
		it("air time is never negative", function()
			expect(SplashShape.airTime(-5, 70)).toBe(0)
			expect(SplashShape.airTime(5, 0)).toBe(0)
		end)
	end)
end
