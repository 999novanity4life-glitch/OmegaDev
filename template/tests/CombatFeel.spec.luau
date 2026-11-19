--!nocheck
return function(t, load)
	local CombatFeel = load("src/shared/CombatFeel")
	local Config = load("src/shared/Config")
	local describe, it, expect = t.describe, t.it, t.expect
	local feel = Config.Feel

	describe("CombatFeel", function()
		it("the shipped Config.Feel escalates tier by tier", function()
			local ok, err = CombatFeel.validateConfig(feel)
			if not ok then
				print(err)
			end
			expect(ok).toBe(true)
		end)
		it("rejects a tier weaker than the one below", function()
			local broken = table.clone(feel)
			broken.Tiers = table.clone(feel.Tiers)
			broken.Tiers.Ultimate = table.clone(feel.Tiers.Ultimate)
			broken.Tiers.Ultimate.shake = 0
			expect((CombatFeel.validateConfig(broken))).toBe(false)
		end)
		it("combo raises pitch and shake, capped", function()
			local first = CombatFeel.forHit(feel, "Light", 1, false)
			local fifth = CombatFeel.forHit(feel, "Light", 5, false)
			local hundredth = CombatFeel.forHit(feel, "Light", 100, false)
			expect(fifth.pitch > first.pitch).toBeTruthy()
			expect(fifth.shake > first.shake).toBeTruthy()
			expect(hundredth.pitch).toBeNear(feel.Tiers.Light.pitch + feel.ComboPitchMax, 1e-9)
			expect(hundredth.shake).toBeNear(feel.Tiers.Light.shake * (1 + feel.ComboShakeMax), 1e-9)
		end)
		it("hit-stop never exceeds the cap", function()
			for _, tier in CombatFeel.TIERS do
				expect(CombatFeel.forHit(feel, tier, 1, false).hitStop <= feel.MaxHitStop).toBeTruthy()
			end
		end)
		it("reduced motion keeps hit-stop but drops camera effects", function()
			local r = CombatFeel.forHit(feel, "Ultimate", 3, true)
			expect(r.hitStop > 0).toBeTruthy()
			expect(r.shake).toBe(0)
			expect(r.fovKick).toBe(0)
			expect(r.impactFrames).toBe(0)
			expect(r.slowMo).toBe(0)
			expect(r.slowMoScale).toBe(1)
		end)
		it("unknown tiers error", function()
			expect(pcall(CombatFeel.forHit, feel, "Mega", 1, false)).toBe(false)
		end)
		it("beats converts frame data to seconds", function()
			local b = CombatFeel.beats(feel, { name = "Jab", tier = "Light", windup = 6, active = 3, recovery = 9 })
			expect(b.windupEnd).toBeNear(0.1, 1e-9)
			expect(b.activeEnd).toBeNear(0.15, 1e-9)
			expect(b.total).toBeNear(0.3, 1e-9)
			expect(b.hits[1]).toBeNear(0.1, 1e-9)
			expect(b.cancelFrom).toBeNear(0.15, 1e-9)
		end)
		it("validateMove catches hits outside the active window", function()
			local good = { name = "Kick", tier = "Heavy", windup = 12, active = 4, recovery = 14, hits = { 12, 14 } }
			expect((CombatFeel.validateMove(good))).toBe(true)
			local late = { name = "Kick", tier = "Heavy", windup = 12, active = 4, recovery = 14, hits = { 16 } }
			expect((CombatFeel.validateMove(late))).toBe(false)
			local noActive = { name = "X", tier = "Light", windup = 2, active = 0, recovery = 2 }
			expect((CombatFeel.validateMove(noActive))).toBe(false)
			local fractional = { name = "X", tier = "Light", windup = 2.5, active = 1, recovery = 2 }
			expect((CombatFeel.validateMove(fractional))).toBe(false)
		end)
	end)
end
