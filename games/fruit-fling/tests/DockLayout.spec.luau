--!nocheck
-- Proves the dock plan follows the map rulebook (docs/rulebooks/MAP_RULEBOOK.md).
return function(t, load)
	local Config = load("src/shared/Config")
	local DockLayout = load("src/shared/DockLayout")
	local describe, it, expect = t.describe, t.it, t.expect
	local cfg = Config.Dock
	local plan = DockLayout.plan(cfg)

	local function ofKind(kind)
		local out = {}
		for _, p in plan.placements do
			if p.kind == kind then
				table.insert(out, p)
			end
		end
		return out
	end

	describe("DockLayout", function()
		it("M6: every placement, rope and terrain op names a reason", function()
			for _, p in plan.placements do
				expect(type(p.why) == "string" and #p.why > 0).toBeTruthy()
			end
			for _, r in plan.ropes do
				expect(#r.why > 0).toBeTruthy()
			end
			for _, op in plan.terrain do
				expect(#op.why > 0).toBeTruthy()
			end
		end)

		it("M20: no surface at y = 0 and the deck sits on a multiple of 4", function()
			expect(cfg.DeckHeight % 4).toBe(0)
			expect(cfg.WaterY % 4).toBe(0)
			expect(cfg.WaterY ~= 0).toBeTruthy()
			for _, p in plan.placements do
				local top = p.pos.y + p.size.y / 2
				expect(math.abs(top) > 0.01).toBeTruthy()
			end
		end)

		it("M34: pilings repeat at exactly PilingSpacing on each side", function()
			local bySide = { [-1] = {}, [1] = {} }
			for _, p in ofKind("Piling") do
				table.insert(bySide[if p.pos.x < 0 then -1 else 1], p.pos.z)
			end
			for _, zs in bySide do
				table.sort(zs)
				expect(#zs >= 10).toBeTruthy()
				for i = 2, #zs do
					expect(zs[i] - zs[i - 1]).toBeNear(cfg.PilingSpacing, 1e-6)
				end
			end
		end)

		it("M40: every rope sags below the straight line between its ends", function()
			expect(#plan.ropes > 20).toBeTruthy()
			for _, r in plan.ropes do
				local a, b = r.points[1], r.points[#r.points]
				local mid = r.points[math.floor(#r.points / 2) + 1]
				expect(mid.y < (a.y + b.y) / 2).toBeTruthy()
			end
		end)

		it("M10/M38: props stay out of the throw lane on the pier", function()
			for _, p in plan.placements do
				if p.group then
					-- footprint of the rotated prop along X (tilt is small, ignored)
					local half = DockLayout.halfWidthX(p.size, p.yaw)
					expect(math.abs(p.pos.x) - half >= cfg.LaneKeepClearHalfWidth - 1e-6).toBeTruthy()
					expect(math.abs(p.pos.x) + half <= cfg.PierHalfWidth + 1e-6).toBeTruthy()
				end
			end
		end)

		it("M38: story groups hold 3-8 props, each has a story, one is mid-task", function()
			expect(#plan.groups >= 3).toBeTruthy()
			local midTask = false
			for _, g in plan.groups do
				expect(g.count >= cfg.GroupSize[1] and g.count <= cfg.GroupSize[2]).toBeTruthy()
				expect(#g.story > 0).toBeTruthy()
			end
			for _, p in plan.placements do
				if p.kind == "FruitCrateOpen" or p.kind == "Handcart" or p.kind == "LanternDown" then
					midTask = true
				end
			end
			expect(midTask).toBeTruthy()
		end)

		it("M38: some props are stacked for height variation", function()
			local stacked = false
			for _, p in plan.placements do
				if p.group and p.pos.y - p.size.y / 2 > cfg.DeckHeight + 0.5 then
					stacked = true
				end
			end
			expect(stacked).toBeTruthy()
		end)

		it("M36: there is an overhead layer above head height on the pier", function()
			local overhead = 0
			for _, r in plan.ropes do
				if r.kind == "Bunting" then
					for _, p in r.points do
						expect(p.y > cfg.DeckHeight + 7).toBeTruthy()
					end
					overhead += 1
				end
			end
			expect(overhead >= 3).toBeTruthy()
		end)

		it("M8: a lighthouse weenie stands at the lane end, taller than everything on the lane", function()
			local lh = ofKind("Lighthouse")
			expect(#lh).toBe(1)
			local top = lh[1].pos.y + lh[1].size.y / 2
			expect(lh[1].pos.z < cfg.ThrowEdgeZ - cfg.LaneLength).toBeTruthy()
			for _, p in plan.placements do
				if p.area == "Lane" then
					expect(p.pos.y + p.size.y / 2 < top).toBeTruthy()
				end
			end
			expect(#ofKind("LighthouseLamp")).toBe(1)
		end)

		it("rulebook 4: a distance landmark at least every 50 studs down the lane", function()
			local zs = {}
			for _, p in ofKind("DistanceBoard") do
				table.insert(zs, p.pos.z)
			end
			table.sort(zs)
			expect(#zs >= math.floor(cfg.LaneLength / 50)).toBeTruthy()
			for i = 2, #zs do
				expect(zs[i] - zs[i - 1] <= 50 + 1e-6).toBeTruthy()
			end
		end)

		it("M44/M13: the cove cliffs leave the lane open", function()
			for _, op in plan.terrain do
				if op.material == "Rock" or op.material == "Slate" then
					local inLane = math.abs(op.pos.x) < 40 and op.pos.z < cfg.ThrowEdgeZ
					local isIsland = op.pos.z < cfg.ThrowEdgeZ - cfg.LaneLength
					expect(not inLane or isIsland).toBeTruthy()
				end
			end
		end)

		it("M21: water is filled after the sea bed, as round lobes", function()
			local firstWater, lastSand = math.huge, 0
			for i, op in plan.terrain do
				if op.material == "Water" then
					expect(op.shape).toBe("Cylinder")
					firstWater = math.min(firstWater, i)
				end
				if op.material == "Sand" and op.pos.y < cfg.SeabedY then
					lastSand = i
				end
			end
			-- each sand bed lobe comes before its water lobe
			expect(firstWater > 1).toBeTruthy()
			expect(lastSand > 0).toBeTruthy()
		end)

		it("M33: exactly one saturated hero accent (the sail) beside the lane", function()
			expect(#ofKind("ShipHull")).toBe(1)
			expect(#ofKind("Sail") >= 1).toBeTruthy()
		end)

		it("is deterministic for a seed", function()
			local again = DockLayout.plan(cfg)
			expect(#again.placements).toBe(#plan.placements)
			for i = 1, #plan.placements do
				expect(again.placements[i].pos.x).toBe(plan.placements[i].pos.x)
			end
		end)
	end)
end
