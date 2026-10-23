--!nocheck
return function(t, load)
	local Config = load("src/shared/Config")
	local ShaftLayout = load("src/shared/ShaftLayout")
	local IntroPath = load("src/shared/IntroPath")
	local describe, it, expect = t.describe, t.it, t.expect
	local shaft = Config.Shaft
	local labels = { "Repair the slime pipes", "Reconnect the power wires", "Crack the door code", "Flip the fuses" }

	-- Every problem with one sampled camera frame, or nil when it is clean.
	local function problem(layout, pos, look)
		local x, y, z = pos[1], pos[2], pos[3]
		local r = math.sqrt(x * x + z * z)
		if y < 2.5 then
			return "below the bottom floor"
		end
		if r < shaft.CoreRadius + 3 then
			return "inside the core"
		end
		if r > shaft.Radius - 3 then
			return "in the wall"
		end
		local h = shaft.HatchSize / 2 - 1.5
		for _, tier in layout.tiers do
			local ceil = tier.ceilingY
			if y > ceil - shaft.BulkheadThickness - 0.6 and y < ceil + 0.6 then
				local hx, hz = ShaftLayout.polar(tier.hatchAngle, tier.hatchRadius)
				if math.abs(x - hx) > h or math.abs(z - hz) > h then
					return string.format("through the tier %d floor at y=%.1f", tier.index, y)
				end
			end
		end
		local dx, dy, dz = look[1] - x, look[2] - y, look[3] - z
		local flat = math.sqrt(dx * dx + dz * dz)
		if flat < 0.2 * math.sqrt(flat * flat + dy * dy) then
			return "looking straight up or down"
		end
		return nil
	end

	describe("IntroPath", function()
		it("never passes through a floor, the core or the walls (60 seeds)", function()
			local bad = {}
			for seed = 1, 60 do
				local layout = ShaftLayout.build(seed * 7919)
				local path = IntroPath.build(layout, labels, "SECTOR 7")
				local step = 1 / 60
				local time = 0
				while time <= path.seconds do
					local pos, look = IntroPath.sample(path.keys, time)
					local issue = problem(layout, pos, look)
					if issue then
						table.insert(bad, string.format("seed %d t=%.2f %s", seed, time, issue))
						break
					end
					time += step
				end
			end
			expect(table.concat(bad, " | ", 1, math.min(#bad, 12))).toBe("")
			if #bad > 0 then
				print(table.concat(bad, "\n"))
			end
		end)

		it("is calm: fits the time cap and never rushes", function()
			for seed = 1, 60 do
				local layout = ShaftLayout.build(seed * 104729)
				local path = IntroPath.build(layout, labels, "SECTOR 7")
				expect(path.seconds <= Config.Intro.MaxSeconds + 1e-6).toBe(true)
				expect(path.seconds >= 15).toBe(true)
				local fastest = 0
				local prev = IntroPath.sample(path.keys, 0)
				local step = 1 / 30
				local time = step
				while time <= path.seconds do
					local pos = IntroPath.sample(path.keys, time)
					local d = math.sqrt((pos[1] - prev[1]) ^ 2 + (pos[2] - prev[2]) ^ 2 + (pos[3] - prev[3]) ^ 2)
					fastest = math.max(fastest, d / step)
					prev = pos
					time += step
				end
				-- Peak speed stays near the glide speed (no whip pans or jumps).
				expect(fastest < Config.Intro.Speed * 2.2).toBe(true)
			end
		end)

		it("crosses every hatch in order and captions every tier", function()
			local layout = ShaftLayout.build(42)
			local path = IntroPath.build(layout, labels, "SECTOR 7")
			expect(#path.hatches).toBe(shaft.Tiers)
			for i, h in path.hatches do
				expect(h.tier).toBe(i)
				local pos = IntroPath.sample(path.keys, h.t)
				-- At the crossing time the camera is right at that floor.
				expect(math.abs(pos[2] - layout.tiers[i].ceilingY) < 4).toBe(true)
			end
			expect(#path.captions).toBe(shaft.Tiers + 2)
			expect(path.captions[2].sub).toBe(labels[1])
			for i = 2, #path.captions do
				expect(path.captions[i].t >= path.captions[i - 1].t).toBe(true)
			end
		end)
	end)
end
