--!nocheck
return function(t, load)
	local MoonGrid = load("src/shared/MoonGrid")
	local Vector3 = require("@lune/roblox").Vector3
	local describe, it, expect = t.describe, t.it, t.expect

	describe("MoonGrid", function()
		local g = MoonGrid.new(6)

		it("has 10 n^2 + 2 cells", function()
			expect(g.count).toBe(362)
			expect(MoonGrid.new(64).count).toBe(40962)
		end)

		it("visits every cell exactly once", function()
			local seen, visits = {}, 0
			g:forEach(function(id)
				visits += 1
				expect(seen[id]).toBe(nil)
				seen[id] = true
				expect(id >= 0 and id < g.count).toBeTruthy()
			end)
			expect(visits).toBe(g.count)
		end)

		it("decodes what it encodes", function()
			for id = 0, g.count - 1 do
				local f, i, j = g:decode(id)
				expect(g:idAt(f, i, j)).toBe(id)
			end
		end)

		it("locates every cell centre to itself", function()
			for id = 0, g.count - 1 do
				expect(g:locate(g:position(id))).toBe(id)
			end
		end)

		it("puts corner 1 at the north pole", function()
			expect(g:position(0).Y).toBeNear(1, 1e-5)
			expect(g:locate(Vector3.new(0, 1, 0))).toBe(0)
		end)

		it("gives hexagons six neighbours and the 12 corners five", function()
			local five, six = 0, 0
			for id = 0, g.count - 1 do
				local nb = #g:neighbours(id)
				if nb == 5 then
					five += 1
				elseif nb == 6 then
					six += 1
				end
			end
			expect(five).toBe(12)
			expect(six).toBe(g.count - 12)
		end)

		it("keeps neighbours symmetric", function()
			for id = 0, g.count - 1, 7 do
				for _, nb in g:neighbours(id) do
					expect(table.find(g:neighbours(nb), id) ~= nil).toBeTruthy()
				end
			end
		end)

		it("nests: every fine cell has one parent and the counts add up", function()
			local fine = MoonGrid.new(30) -- 5 patches per sector edge
			local counts = MoonGrid.childCounts(fine, g)
			local total, lo, hi = 0, math.huge, 0
			for id = 0, g.count - 1 do
				local c = buffer.readu16(counts, id * 2)
				total += c
				if id >= 12 then
					lo, hi = math.min(lo, c), math.max(hi, c)
				end
			end
			expect(total).toBe(fine.count)
			expect(lo >= 19 and hi <= 31).toBeTruthy()
		end)

		it("agrees on parents for points shared by two faces", function()
			local fine = MoonGrid.new(30)
			for id = 0, fine.count - 1, 3 do
				local p = MoonGrid.parentOf(fine, g, id)
				-- the parent is never further than one sector spacing away
				expect((fine:position(id) - g:position(p)).Magnitude < 1.2 / 6).toBeTruthy()
			end
		end)
	end)
end
