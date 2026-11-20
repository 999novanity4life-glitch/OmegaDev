--!nocheck
return function(t, load)
	local ThrowPose = load("src/shared/ThrowPose")
	local Config = load("src/shared/Config")
	local describe, it, expect = t.describe, t.it, t.expect
	local cfg = Config.Throw

	local function maxJump(a, b)
		local m = 0
		for _, j in ThrowPose.JOINTS do
			for i = 1, 3 do
				m = math.max(m, math.abs(a[j][i] - b[j][i]))
			end
		end
		return m
	end

	describe("ThrowPose", function()
		it("starts and ends at rest", function()
			local keys = ThrowPose.keys(cfg)
			expect(maxJump(ThrowPose.sample(keys, 0), ThrowPose.REST)).toBe(0)
			expect(maxJump(ThrowPose.sample(keys, ThrowPose.totalTime(cfg) + 1), ThrowPose.REST)).toBe(0)
		end)
		it("keys are in time order and release sits inside the swing", function()
			local keys = ThrowPose.keys(cfg)
			for i = 2, #keys do
				expect(keys[i].time > keys[i - 1].time).toBeTruthy()
			end
			local r = ThrowPose.releaseTime(cfg)
			expect(r > cfg.SwingWindup and r < ThrowPose.totalTime(cfg)).toBeTruthy()
		end)
		it("is continuous: no pop above 0.6 rad per 60 fps frame (the whip may reach 1.3)", function()
			local keys = ThrowPose.keys(cfg, ThrowPose.charge(1, Config.UI))
			local prev = ThrowPose.sample(keys, 0)
			local step = 1 / 60
			local tt = step
			while tt <= ThrowPose.totalTime(cfg) + step do
				local p = ThrowPose.sample(keys, tt)
				local inWhip = tt > cfg.SwingWindup and tt <= ThrowPose.releaseTime(cfg) + step
				expect(maxJump(prev, p) < (if inWhip then 1.3 else 0.6)).toBeTruthy()
				prev = p
				tt += step
			end
		end)
		it("the whip is the fastest part (release reads as a snap)", function()
			local keys = ThrowPose.keys(cfg)
			local r = ThrowPose.releaseTime(cfg)
			local whip =
				math.abs(ThrowPose.sample(keys, r).rightShoulder[1] - ThrowPose.sample(keys, r - 0.02).rightShoulder[1])
			local windup =
				math.abs(ThrowPose.sample(keys, 0.06).rightShoulder[1] - ThrowPose.sample(keys, 0.04).rightShoulder[1])
			expect(whip > windup).toBeTruthy()
		end)
		it("charge grows with the meter and is rest when empty", function()
			expect(maxJump(ThrowPose.charge(0, Config.UI), ThrowPose.REST)).toBe(0)
			local half = ThrowPose.charge(0.5, Config.UI).rightShoulder[1]
			local full = ThrowPose.charge(1, Config.UI).rightShoulder[1]
			expect(full).toBeNear(Config.UI.ChargeArmPitch, 1e-9)
			expect(half > 0 and half < full).toBeTruthy()
			expect(maxJump(ThrowPose.charge(5, Config.UI), ThrowPose.charge(1, Config.UI))).toBe(0)
		end)
	end)
end
