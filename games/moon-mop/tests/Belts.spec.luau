--!nocheck
return function(t, load)
	local Belts = load("src/shared/Belts")
	local describe, it, expect = t.describe, t.it, t.expect

	local function b(uid, id, x, z, r)
		return { uid = uid, id = id, x = x, z = z, r = r or 0, paid = 0, t = 0 }
	end

	local function run(net, seconds, satisfied)
		local sold = {}
		for _ = 1, math.floor(seconds / 0.1) do
			for _, s in Belts.tick(net, 0.1, satisfied or 1) do
				table.insert(sold, s)
			end
		end
		return sold
	end

	-- Collector Pad (24 x 24, front -z) -> three belts -> Pod Cannon
	local line = {
		b(1, "CollectorPad", 0, 0),
		b(2, "Belt", 0, -14),
		b(3, "Belt", 0, -18),
		b(4, "Belt", 0, -22),
		b(5, "PodCannon", 0, -29),
	}

	describe("Belts", function()
		it("carries a dumped tank to the cannon in 10 kg pods", function()
			local net = Belts.build(line)
			expect(Belts.connected(net, 1)).toBe(true)
			expect(Belts.feed(net, 1, "Dust", 25)).toBe(25)
			local sold = run(net, 10)
			expect(#sold).toBe(3)
			local kg = 0
			for _, s in sold do
				kg += s.kg
				expect(s.kind).toBe("Dust")
			end
			expect(math.abs(kg - 25) < 1e-6).toBe(true)
		end)
		it("refuses dust when the pad has no belt", function()
			local net = Belts.build({ b(1, "CollectorPad", 0, 0) })
			expect(Belts.connected(net, 1)).toBe(false)
			expect(Belts.feed(net, 1, "Dust", 10)).toBe(0)
		end)
		it("does not link belts that face each other", function()
			local net = Belts.build({ b(1, "Belt", 0, 0, 0), b(2, "Belt", 0, -4, 2) })
			expect(#net.nodes[1].outs).toBe(0)
			expect(#net.nodes[2].outs).toBe(0)
		end)
		it("splits pods left and right in turn", function()
			local net = Belts.build({
				b(1, "CollectorPad", 0, 0),
				b(2, "Belt", 0, -14),
				b(3, "Splitter", 0, -18),
				b(4, "Belt", -4, -18, 3),
				b(5, "Belt", 4, -18, 1),
			})
			expect(#net.nodes[3].outs).toBe(2)
			Belts.feed(net, 1, "Dust", 20)
			run(net, 6)
			expect(net.nodes[4].item ~= nil).toBe(true)
			expect(net.nodes[5].item ~= nil).toBe(true)
		end)
		it("reaches a Pod Packer across the one-stud grid gap", function()
			local net = Belts.build({ b(1, "PodPacker", 0, 30), b(2, "Belt", 0, 24, 0) })
			expect(Belts.connected(net, 1)).toBe(true)
		end)
		it("lifts a belt over the next tile", function()
			local net = Belts.build({ b(1, "Lift", 0, 0, 1), b(2, "Belt", 4, 0, 0), b(3, "Belt", 8, 0, 1) })
			expect(#net.nodes[1].outs).toBe(1)
			expect(net.nodes[1].outs[1].uid).toBe(3)
		end)
		it("turns dust into Moon Glass in a powered oven", function()
			local net = Belts.build({
				b(1, "CollectorPad", 0, 0),
				b(2, "Belt", 0, -14),
				b(3, "GlassOven", 0, -23), -- 10 x 14
				b(4, "Belt", 0, -32),
				b(5, "PodCannon", 0, -39),
			})
			Belts.feed(net, 1, "Dust", 20)
			expect(#run(net, 120, 0)).toBe(0) -- no power, no glass
			local sold = run(net, 120, 1)
			local kg = 0
			for _, s in sold do
				expect(s.kind).toBe("Glass")
				kg += s.kg
			end
			expect(math.abs(kg - 20) < 1e-6).toBe(true)
		end)
		it("keeps pods when the base is rebuilt", function()
			local net = Belts.build(line)
			Belts.feed(net, 1, "Dust", 10)
			run(net, 0.3)
			local again = Belts.build(line, net)
			expect(#Belts.pods(again)).toBe(#Belts.pods(net))
		end)
	end)
end
