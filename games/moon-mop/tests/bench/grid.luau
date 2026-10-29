--!nocheck
local loader = require("../lib/loader")
local MoonGrid = loader.load("src/shared/MoonGrid")
local V = require("@lune/roblox").Vector3
local t0 = os.clock()
local fine, coarse, region = MoonGrid.new(320), MoonGrid.new(64), MoonGrid.new(8)
local c = MoonGrid.childCounts(fine, coarse)
print("childCounts", os.clock() - t0)
local lo, hi = 1e9, 0
for id = 12, coarse.count - 1 do
	local x = buffer.readu16(c, id * 2)
	lo = math.min(lo, x)
	hi = math.max(hi, x)
end
print("fine per sector", lo, hi)
local rc = MoonGrid.childCounts(coarse, region)
lo, hi = 1e9, 0
for id = 0, region.count - 1 do
	local x = buffer.readu16(rc, id * 2)
	lo = math.min(lo, x)
	hi = math.max(hi, x)
end
print("sectors per region", lo, hi, region.count)
t0 = os.clock()
local rng = {
	NextNumber = function(_, a, b)
		return a + (b - a) * math.random()
	end,
	NextInteger = function(_, a, b)
		return math.random(a, b)
	end,
}
for k = 1, 100000 do
	local d = V.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit
	local id = fine:locate(d)
end
print("100k locate", os.clock() - t0)
for k = 1, 2000 do
	local id = rng:NextInteger(0, fine.count - 1)
	local f, i, j = fine:decode(id)
	assert(fine:idAt(f, i, j) == id)
	assert(fine:locate(fine:position(id)) == id)
end
-- spacing in studs
local p = coarse:position(5000)
local nb = coarse:neighbours(5000)
print("sector spacing", (coarse:position(nb[1]) - p).Magnitude * 2000, #nb)
p = fine:position(500000)
nb = fine:neighbours(500000)
print("patch spacing", (fine:position(nb[1]) - p).Magnitude * 2000)
