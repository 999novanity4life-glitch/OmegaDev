--!nocheck
return function(t, load)
	local Config = load("src/shared/Config")
	local ShaftLayout = load("src/shared/ShaftLayout")
	local IntroPath = load("src/shared/IntroPath")
	local Footprint = load("src/shared/Footprint")
	local MAPS = { "Shaft", "Cryo" }
	local describe, it, expect = t.describe, t.it, t.expect
	local shaft = Config.Shaft

	-- Puzzle focus points where PuzzleService/MiniGames really put them.
	local function tierInfo(layout)
		local out = {}
		for i, tier in layout.tiers do
			local kind = (i - 1) % 4
			local focus
			if kind == 0 then -- mini-game console
				focus = { angle = tier.hatchAngle + 38, radius = shaft.Radius - 4, y = tier.floorY + 2.5 }
			elseif kind == 1 then -- pressure plates on the floor
				focus = { angle = tier.hatchAngle + 180, radius = 15, y = tier.floorY + 0.2 }
			elseif kind == 2 then -- valve on the wall by a course pad
				local pad = tier.pads[#tier.pads]
				focus = { angle = pad.angle + 9, radius = shaft.Radius - 1.2, y = pad.y + 3.2 }
			else -- fuse shelf
				focus = { angle = tier.hatchAngle + 70, radius = shaft.Radius - 3, y = tier.floorY + 1.5 }
			end
			local x, z = Footprint.polar(layout.footprint, focus.angle, focus.radius)
			out[i] = { title = "PUZZLE", label = "Do the thing", focus = { x = x, y = focus.y, z = z } }
		end
		return out
	end

	local function problem(layout, pos, look)
		local x, y, z = pos[1], pos[2], pos[3]
		local r = math.sqrt(x * x + z * z)
		if y < 2 then
			return "below the bottom floor"
		end
		if r < shaft.CoreRadius + 3 then
			return "inside the core"
		end
		if not Footprint.contains(layout.footprint, x, z, 2.5) then
			return "in the wall"
		end
		for _, tier in layout.tiers do
			local ceil = tier.ceilingY
			if y > ceil - shaft.BulkheadThickness - 1 and y < ceil + 1 then
				return string.format("in the tier %d floor slab at y=%.1f", tier.index, y)
			end
		end
		local dx, dy, dz = look[1] - x, look[2] - y, look[3] - z
		local flat = math.sqrt(dx * dx + dz * dz)
		if flat < 0.25 * math.sqrt(flat * flat + dy * dy) then
			return "looking straight up or down"
		end
		return nil
	end

	local function yaw(pos, look)
		return math.deg(math.atan2(look[3] - pos[3], look[1] - pos[1]))
	end

	describe("IntroPath", function()
		it("never passes through a floor, the core or the walls (60 seeds)", function()
			local bad = {}
			for seed = 1, 60 do
				local layout = ShaftLayout.build(seed * 7919, MAPS[seed % 2 + 1])
				local path = IntroPath.build(layout, tierInfo(layout), "SECTOR 7")
				local time = 0
				while time <= path.seconds do
					local pos, look = IntroPath.sample(path, time)
					local issue = problem(layout, pos, look)
					if issue then
						table.insert(bad, string.format("seed %d t=%.2f %s", seed, time, issue))
						break
					end
					time += 1 / 60
				end
			end
			expect(table.concat(bad, " | ", 1, math.min(#bad, 12))).toBe("")
		end)

		it("never spins: each shot turns the view only a little, and slowly", function()
			local bad = {}
			for seed = 1, 60 do
				local layout = ShaftLayout.build(seed * 104729, MAPS[seed % 2 + 1])
				local path = IntroPath.build(layout, tierInfo(layout), "SECTOR 7")
				for index, s in path.shots do
					local t0, t1 = s.t, s.keys[#s.keys].t
					local p0, l0 = IntroPath.sample(path, t0 + 1e-3)
					local startYaw = yaw(p0, l0)
					local prevYaw = startYaw
					local time = t0 + 1 / 30
					while time < t1 do
						local p, l = IntroPath.sample(path, time)
						local a = yaw(p, l)
						local step = math.abs((a - prevYaw + 180) % 360 - 180)
						local total = math.abs((a - startYaw + 180) % 360 - 180)
						if step * 30 > 30 or total > 35 then
							table.insert(bad, string.format("seed %d shot %d turns %.0f deg", seed, index, total))
							break
						end
						prevYaw = a
						time += 1 / 30
					end
				end
			end
			expect(table.concat(bad, " | ", 1, math.min(#bad, 12))).toBe("")
		end)

		it("shows every tier wide, then settles on its puzzle (both maps)", function()
			for _, mapId in MAPS do
				local layout = ShaftLayout.build(42, mapId)
				local tiers = #layout.tiers
				local info = tierInfo(layout)
				local path = IntroPath.build(layout, info, "SECTOR 7")
				expect(#path.shots).toBe(tiers * 2 + 1)
				for i = 1, tiers do
					local push = path.shots[i * 2]
					expect(push.tier).toBe(i)
					local last = push.keys[#push.keys]
					local f = info[i].focus
					local d = math.sqrt((last.pos[1] - f.x) ^ 2 + (last.pos[2] - f.y) ^ 2 + (last.pos[3] - f.z) ^ 2)
					expect(d < 12).toBe(true)
				end
				-- One dip to black per floor change (into every later floor and the roof).
				expect(#path.cuts).toBe(tiers)
				expect(path.seconds <= Config.Intro.MaxSeconds + 0.01).toBe(true)
				expect(#path.captions).toBe(tiers * 2 + 1)
				for i = 2, #path.captions do
					expect(path.captions[i].t > path.captions[i - 1].t).toBe(true)
				end
			end
		end)
	end)
end
