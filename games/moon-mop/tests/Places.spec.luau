--!nocheck
return function(t, load)
	local Places = load("src/shared/Places")
	local Config = load("src/shared/Config")
	local describe, it, expect = t.describe, t.it, t.expect

	describe("Places", function()
		it("puts 12 stations on the icosahedron corners, North on top", function()
			expect(#Places.stations).toBe(12)
			expect(Places.stations[1].name).toBe("North")
			expect(Places.stations[1].dir.Y).toBeNear(1, 1e-5)
		end)
		it("makes 16 Mop Base plots round the North Station", function()
			expect(#Places.plots).toBe(16)
			for _, p in Places.plots do
				local d = Places.arc(p.dir, Places.stations[1].dir)
				expect(d > 200 and d < 520).toBeTruthy()
			end
		end)
		it("scatters every flag and probe clear of the pads", function()
			expect(#Places.flags).toBe(Config.Flags.Count)
			expect(#Places.probes).toBe(Config.Probes.Count)
			for _, f in Places.flags do
				for _, s in Places.stations do
					expect(Places.arc(f, s.dir) > Config.Stations.PadRadius).toBeTruthy()
				end
			end
		end)
		it("is deterministic", function()
			local next1, next2 = Places.rng(7), Places.rng(7)
			for _ = 1, 10 do
				expect(next1()).toBe(next2())
			end
		end)
		it("builds surface frames whose up points away from the centre", function()
			local cf = Places.surfaceFrame(Places.stations[5].dir, 3)
			expect(cf.UpVector:Dot(Places.stations[5].dir)).toBeNear(1, 1e-4)
			expect((cf.Position - Config.Moon.Centre).Magnitude).toBeNear(Config.Moon.Radius + 3, 1e-2)
		end)
	end)
end
