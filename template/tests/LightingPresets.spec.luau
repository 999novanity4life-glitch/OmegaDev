--!nocheck
return function(t, load)
	local LightingPresets = load("src/shared/LightingPresets")
	local describe, it, expect = t.describe, t.it, t.expect

	describe("LightingPresets", function()
		it("every preset validates clean", function()
			for _, name in LightingPresets.names() do
				local problems = LightingPresets.validate(LightingPresets.get(name))
				if #problems > 0 then
					print(name .. ": " .. table.concat(problems, "; "))
				end
				expect(#problems).toBe(0)
			end
		end)
		it("every preset names its source tag", function()
			for _, name in LightingPresets.names() do
				local source = LightingPresets.get(name).source
				expect(string.match(source, "^%[DOC%]") ~= nil or string.match(source, "^%[INFERRED%]") ~= nil).toBeTruthy()
			end
		end)
		it("catches out-of-range and NaN values", function()
			local bad = {
				name = "bad",
				source = "test",
				lightingStyle = "Future",
				lighting = { ExposureCompensation = 9, ShadowSoftness = 0 / 0, Ambient = { 300, 0, 0 } },
				atmosphere = { Glare = 1, Haze = 0 },
			}
			expect(#LightingPresets.validate(bad)).toBe(5)
		end)
		it("blend returns the endpoints at t = 0 and t = 1", function()
			local a = LightingPresets.get("RobloxOutdoorSunset")
			local b = LightingPresets.get("RobloxSciFiArena")
			expect(LightingPresets.blend(a, b, 0).lighting.Ambient[1]).toBe(156)
			expect(LightingPresets.blend(a, b, 1).lighting.Ambient[1]).toBe(26)
			expect(LightingPresets.blend(a, b, 1).atmosphere.Density).toBeNear(0.285, 1e-9)
		end)
		it("blend midpoint is halfway and keeps one-sided fields", function()
			local a = LightingPresets.get("RobloxOutdoorSunset")
			local b = LightingPresets.get("RobloxSciFiArena")
			local mid = LightingPresets.blend(a, b, 0.5)
			expect(mid.lighting.Ambient[2]).toBeNear((136 + 34) / 2, 1e-9)
			expect(mid.lighting.ClockTime).toBe(17)
			expect(mid.bloom.Size).toBe(56)
		end)
		it("blend clamps t and survives NaN", function()
			local a = LightingPresets.get("RobloxOutdoorSunset")
			local b = LightingPresets.get("AirlessMoon")
			expect(LightingPresets.blend(a, b, 5).lighting.ClockTime).toBe(9)
			expect(LightingPresets.blend(a, b, 0 / 0).lighting.ClockTime).toBe(17)
			expect(#LightingPresets.validate(LightingPresets.blend(a, b, 0.37))).toBe(0)
		end)
	end)
end
