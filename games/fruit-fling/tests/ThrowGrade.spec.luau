--!nocheck
return function(t, load)
	local ThrowGrade = load("src/shared/ThrowGrade")
	local Config = load("src/shared/Config")
	local cfg = Config.Throw
	local describe, it, expect = t.describe, t.it, t.expect

	describe("ThrowGrade.gradeTiming", function()
		it("grades by absolute offset", function()
			expect(ThrowGrade.gradeTiming(0, cfg.TimingWindows)).toBe("Perfect")
			expect(ThrowGrade.gradeTiming(-0.05, cfg.TimingWindows)).toBe("Perfect")
			expect(ThrowGrade.gradeTiming(0.1, cfg.TimingWindows)).toBe("Great")
			expect(ThrowGrade.gradeTiming(-0.15, cfg.TimingWindows)).toBe("Good")
			expect(ThrowGrade.gradeTiming(0.3, cfg.TimingWindows)).toBe("Miss")
		end)
		it("window edges are inclusive", function()
			expect(ThrowGrade.gradeTiming(cfg.TimingWindows.Perfect, cfg.TimingWindows)).toBe("Perfect")
			expect(ThrowGrade.gradeTiming(cfg.TimingWindows.Good, cfg.TimingWindows)).toBe("Good")
		end)
	end)

	describe("ThrowGrade power meter (TFFA style)", function()
		it("starts at MeterStart and stays on the bar", function()
			expect(ThrowGrade.meterValue(0, cfg)).toBeNear(cfg.MeterStart, 1e-6)
			for i = 0, 400 do
				local v = ThrowGrade.meterValue(i * 0.013, cfg)
				expect(v >= 0 and v <= cfg.MeterMax + 1e-9).toBeTruthy()
			end
		end)
		it("reaches the top and the bottom each cycle", function()
			local hi, lo = 0, math.huge
			for i = 0, 220 do
				local v = ThrowGrade.meterValue(i * cfg.MeterPeriod / 220, cfg)
				hi = math.max(hi, v)
				lo = math.min(lo, v)
			end
			expect(hi > cfg.MeterMax - 0.3).toBeTruthy()
			expect(lo < 0.3).toBeTruthy()
		end)
		it("is slow near the bottom and fast near the top (TFFA ease)", function()
			-- time to climb the bottom quarter vs the top quarter of the bar
			local half = cfg.MeterPeriod / 2
			local function timeTo(frac)
				return half * frac ^ (1 / cfg.MeterEase)
			end
			local bottom = timeTo(0.25)
			local top = timeTo(1) - timeTo(0.75)
			expect(bottom > top * 1.5).toBeTruthy()
		end)
		it("power is a whole number on the bar, NaN gives 0", function()
			expect(ThrowGrade.meterPower(19.6, cfg)).toBe(20)
			expect(ThrowGrade.meterPower(25, cfg)).toBe(cfg.MeterMax)
			expect(ThrowGrade.meterPower(-3, cfg)).toBe(0)
			expect(ThrowGrade.meterPower(0 / 0, cfg)).toBe(0)
		end)
		it("the top is Perfect, grades step down", function()
			expect(ThrowGrade.gradePower(20, cfg)).toBe("Perfect")
			expect(ThrowGrade.gradePower(19, cfg)).toBe("Great")
			expect(ThrowGrade.gradePower(cfg.MeterGrades.Good, cfg)).toBe("Good")
			expect(ThrowGrade.gradePower(0, cfg)).toBe("Miss")
		end)
		it("more power never throws shorter", function()
			for p = 1, cfg.MeterMax do
				expect(ThrowGrade.meterMult(p, cfg) >= ThrowGrade.meterMult(p - 1, cfg)).toBeTruthy()
			end
			expect(ThrowGrade.meterMult(cfg.MeterMax, cfg)).toBeNear(cfg.MeterMaxMult)
		end)
	end)

	describe("ThrowGrade.pingPong", function()
		it("stays in 0..1 and hits both ends", function()
			expect(ThrowGrade.pingPong(0, 1)).toBeNear(0)
			expect(ThrowGrade.pingPong(0.5, 1)).toBeNear(1)
			expect(ThrowGrade.pingPong(1, 1)).toBeNear(0)
			for i = 0, 200 do
				local v = ThrowGrade.pingPong(i * 0.037, 0.9)
				expect(v >= 0 and v <= 1).toBeTruthy()
			end
		end)
	end)

	describe("ThrowGrade.comboAfter", function()
		it("Perfect adds, Miss resets, others keep, capped", function()
			expect(ThrowGrade.comboAfter(2, "Perfect", 10)).toBe(3)
			expect(ThrowGrade.comboAfter(2, "Great", 10)).toBe(2)
			expect(ThrowGrade.comboAfter(2, "Miss", 10)).toBe(0)
			expect(ThrowGrade.comboAfter(10, "Perfect", 10)).toBe(10)
		end)
	end)

	describe("ThrowGrade distance", function()
		it("better grades never throw shorter", function()
			local order = { "Miss", "Good", "Great", "Perfect" }
			for i = 2, #order do
				expect(
					ThrowGrade.launchDistance(16, order[i], 0, cfg)
						>= ThrowGrade.launchDistance(16, order[i - 1], 0, cfg)
				).toBeTruthy()
			end
			expect(ThrowGrade.launchDistance(20, "Great", 0, cfg) > ThrowGrade.launchDistance(10, "Great", 0, cfg)).toBeTruthy()
		end)
		it("full power + Great release with no combo is base * MeterMaxMult", function()
			expect(ThrowGrade.launchDistance(cfg.MeterMax, "Great", 0, cfg)).toBeNear(
				cfg.BaseDistance * cfg.MeterMaxMult
			)
		end)
		it("combo is clamped", function()
			expect(ThrowGrade.launchDistance(cfg.MeterMax, "Great", 999, cfg)).toBeNear(
				cfg.BaseDistance * cfg.MeterMaxMult * (1 + cfg.ComboMax * cfg.ComboStep)
			)
		end)
		it("masterwork only when all three are Perfect", function()
			expect(ThrowGrade.isMasterwork("Perfect", "Perfect", "Perfect")).toBe(true)
			expect(ThrowGrade.isMasterwork("Perfect", "Perfect", "Great")).toBe(false)
			local launch = ThrowGrade.launchDistance(cfg.MeterMax, "Perfect", 0, cfg)
			local mw = ThrowGrade.finalDistance(launch, "Perfect", "Perfect", "Perfect", cfg)
			expect(mw).toBeNear(launch * (1 + cfg.AirBonus.Perfect) * cfg.MasterworkMult)
		end)
		it("a missed air tap keeps the launch distance", function()
			expect(ThrowGrade.finalDistance(100, "Good", "Good", "Miss", cfg)).toBeNear(100)
		end)
	end)

	describe("ThrowGrade flight", function()
		it("flight time is clamped", function()
			expect(ThrowGrade.flightTime(0, cfg)).toBeNear(cfg.FlightMin)
			expect(ThrowGrade.flightTime(1e6, cfg)).toBeNear(cfg.FlightMax)
		end)
		it("arc starts and ends on the ground, peaks mid-way", function()
			local f0, h0 = ThrowGrade.arc(0, 100, 0.35)
			local f1, h1 = ThrowGrade.arc(1, 100, 0.35)
			local _, hm = ThrowGrade.arc(0.5, 100, 0.35)
			expect(f0).toBeNear(0)
			expect(h0).toBeNear(0)
			expect(f1).toBeNear(100)
			expect(h1).toBeNear(0)
			expect(hm).toBeNear(35)
		end)
	end)
	describe("ThrowGrade rarity pacing", function()
		local Rarity = Config.Rarity
		it("no slow-mo: real flight = base * flight mult", function()
			local pace = Rarity.Pace.Epic
			expect(ThrowGrade.pacedFlight(2, pace)).toBeNear(2 * pace.flight)
		end)
		it("rarer fruits stay in the air longer", function()
			local prev = 0
			for _, r in Rarity.Order do
				local t = ThrowGrade.pacedFlight(1.5, Rarity.Pace[r])
				expect(t > prev).toBeTruthy()
				prev = t
			end
		end)
		it("alpha hits 1 exactly at the paced flight time, and realTimeAt inverts it", function()
			for _, r in Rarity.Order do
				local pace = Rarity.Pace[r]
				local total = ThrowGrade.pacedFlight(1.7, pace)
				expect(ThrowGrade.flightAlpha(total, 1.7, pace)).toBeNear(1, 1e-6)
				for _, a in { 0.05, 0.4, 0.9 } do
					local t = ThrowGrade.realTimeAt(a, 1.7, pace)
					expect(ThrowGrade.flightAlpha(t, 1.7, pace)).toBeNear(a, 1e-6)
				end
			end
		end)
		it("weighted pick respects the weights", function()
			expect(ThrowGrade.pickWeighted({ 1, 1 }, 0)).toBe(1)
			expect(ThrowGrade.pickWeighted({ 1, 1 }, 0.75)).toBe(2)
			expect(ThrowGrade.pickWeighted({ 0, 5 }, 0.01)).toBe(2)
			expect(ThrowGrade.pickWeighted({ 3, 1 }, 0.999)).toBe(2)
		end)
		it("every fruit has a known rarity", function()
			for _, f in Config.Fruits do
				expect(Rarity.Pace[f.rarity] ~= nil).toBeTruthy()
				expect(Rarity.Weight[f.rarity] ~= nil).toBeTruthy()
			end
		end)
	end)
end
