--!nocheck
return function(t, load)
	local ThrowPose = load("src/shared/ThrowPose")
	local Config = load("src/shared/Config")
	local describe, it, expect = t.describe, t.it, t.expect
	local cfg = Config.Throw

	-- Angle difference modulo 2pi (-2pi is the same pose as 0).
	local function adiff(x, y)
		local d = (x - y) % (2 * math.pi)
		return math.min(d, 2 * math.pi - d)
	end
	local function maxJump(a, b)
		local m = 0
		for _, j in ThrowPose.JOINTS do
			for i = 1, 3 do
				m = math.max(m, adiff(a[j][i], b[j][i]))
			end
			m = math.max(m, math.abs((a[j][4] or 0) - (b[j][4] or 0)))
		end
		return m
	end

	describe("ThrowPose", function()
		it("starts and ends at rest", function()
			local keys = ThrowPose.keys(cfg)
			expect(maxJump(ThrowPose.sample(keys, 0), ThrowPose.REST)).toBe(0)
			expect(maxJump(ThrowPose.sample(keys, ThrowPose.totalTime(cfg) + 1), ThrowPose.REST) < 1e-9).toBeTruthy()
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
		it("whips: the arm turns forward fastest at release and the elbow snaps straight", function()
			local keys = ThrowPose.keys(cfg, ThrowPose.charge(1, Config.UI))
			local r = ThrowPose.releaseTime(cfg)
			local function rot(tt)
				return ThrowPose.sample(keys, tt).rightShoulder[1]
			end
			local whip = rot(r - 0.02) - rot(r)
			local windup = math.abs(rot(0.06) - rot(0.04))
			expect(whip > 0).toBeTruthy()
			expect(whip > windup * 3).toBeTruthy()
			expect(ThrowPose.sample(keys, r).rightElbow[1] < 0.3).toBeTruthy()
			expect(ThrowPose.sample(keys, cfg.SwingWindup).rightElbow[1] > 1.4).toBeTruthy()
		end)
		it("full body: stride drops the body and the back foot kicks up in the follow-through", function()
			local keys = ThrowPose.keys(cfg, ThrowPose.charge(1, Config.UI))
			local r = ThrowPose.releaseTime(cfg)
			expect(ThrowPose.sample(keys, r).root[4] < -0.3).toBeTruthy()
			local follow = ThrowPose.sample(keys, cfg.SwingWindup + cfg.SwingFollow)
			expect(follow.rightKnee[1] < -1).toBeTruthy()
			expect(follow.waist[1] < -0.3).toBeTruthy() -- chest over the front leg
		end)
		it("the head stays on the lane: neck undoes the waist turn", function()
			local keys = ThrowPose.keys(cfg, ThrowPose.charge(1, Config.UI))
			for i = 0, 20 do
				local p = ThrowPose.sample(keys, i * ThrowPose.totalTime(cfg) / 20)
				expect(math.abs(p.waist[2] + p.neck[2]) <= math.abs(p.waist[2]) * 0.2 + 1e-9).toBeTruthy()
			end
		end)
		it("charge grows with the meter and is rest when empty", function()
			expect(maxJump(ThrowPose.charge(0, Config.UI), ThrowPose.REST)).toBe(0)
			local half = ThrowPose.charge(0.5, Config.UI).rightShoulder[1]
			local full = ThrowPose.charge(1, Config.UI).rightShoulder[1]
			expect(full).toBeNear(Config.UI.ChargeLayback, 1e-9)
			expect(ThrowPose.charge(1, Config.UI).leftHip[1]).toBeNear(Config.UI.ChargeLegLift, 1e-9)
			expect(math.abs(half) > 0 and math.abs(half) < math.abs(full)).toBeTruthy()
			expect(maxJump(ThrowPose.charge(5, Config.UI), ThrowPose.charge(1, Config.UI))).toBe(0)
		end)
	end)
end
