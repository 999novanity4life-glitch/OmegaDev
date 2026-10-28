--!strict
-- Moon Mop: writes the round Moon into Terrain, one x-slab of 64-stud chunks at a time.
-- Run from Studio (command bar or the MCP execute_luau tool) after MoonFeatures.luau has stored
-- the feature list in ServerStorage.MoonMapData. Each call does slabs until its time budget runs
-- out and stores where it stopped, so it never freezes Studio for long.
--
-- Terrain:WriteVoxels takes resolution 4 only, and FillBall refuses radii near 1000 ("Extents are
-- too large"), which is why the sphere is written voxel by voxel rather than with one FillBall.
-- Shape: Moon centre at (0, -R, 0) so the North Station sits at the origin on top.
-- Surface radius S(dir) = R + gentle noise + hills - craters, flattened round station pads.
-- The shell is SHELL studs thick under the surface; the core is left hollow to save memory.

local HS = game:GetService("HttpService")
local T = workspace.Terrain
local data = game:GetService("ServerStorage"):WaitForChild("MoonMapData")

local R: number = data:GetAttribute("Radius")
local HILLS = HS:JSONDecode(data:GetAttribute("Hills"))
local CRATERS = HS:JSONDecode(data:GetAttribute("Craters"))
local PADS = HS:JSONDecode(data:GetAttribute("Pads"))
local CENTRE = Vector3.new(0, -R, 0)
local CH = 64 -- chunk edge in studs (16 voxels)
local NV = CH // 4
local SHELL = 28
local MAT = Enum.Material.Ground
local AIR = Enum.Material.Air

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- Features near one chunk, so the per-voxel loop only checks a handful.
local function gather(dirC: Vector3, reach: number)
	local hills, craters, pads = {}, {}, {}
	for _, h in HILLS do
		if (Vector3.new(h[1], h[2], h[3]) - dirC).Magnitude * R < h[4] + reach then
			table.insert(hills, h)
		end
	end
	for _, c in CRATERS do
		if (Vector3.new(c[1], c[2], c[3]) - dirC).Magnitude * R < c[4] * 1.8 + reach then
			table.insert(craters, c)
		end
	end
	for _, p in PADS do
		if (Vector3.new(p[1], p[2], p[3]) - dirC).Magnitude * R < p[4] + 70 + reach then
			table.insert(pads, p)
		end
	end
	return hills, craters, pads
end

local function surface(d: Vector3, hills, craters, pads): number
	local p = d * R
	local s = R + 3 * math.noise(p.X / 240, p.Y / 240, p.Z / 240) + 1.2 * math.noise(p.X / 70, p.Y / 70, p.Z / 70)
	for _, h in hills do
		local dist = (Vector3.new(h[1], h[2], h[3]) - d).Magnitude * R
		if dist < h[4] then
			local t = 1 - dist / h[4]
			if h[6] == 1 then
				s += h[5] * t ^ 1.6 * smooth(t * 3) -- steep cone with a rounded foot
			else
				s += h[5] * t * t * (3 - 2 * t) -- soft rolling dome
			end
		end
	end
	for _, c in craters do
		local q = (Vector3.new(c[1], c[2], c[3]) - d).Magnitude * R / c[4]
		if q < 1 then
			s += c[5] * (q * q - 1) + c[5] * 0.28 * math.exp(-((q - 1) / 0.22) ^ 2)
		elseif q < 1.8 then
			s += c[5] * 0.28 * math.exp(-((q - 1) / 0.3) ^ 2)
		end
	end
	for _, pd in pads do
		local dist = (Vector3.new(pd[1], pd[2], pd[3]) - d).Magnitude * R
		local k = smooth((dist - pd[4]) / 70)
		s = R + (s - R) * k
	end
	return s
end

local function writeChunk(origin: Vector3): boolean
	local c = origin + Vector3.new(CH / 2, CH / 2, CH / 2) - CENTRE
	local dc = c.Magnitude
	if dc < 1 then
		return false
	end
	local reach = CH * 0.9
	-- quick reject: outside the band any feature could reach
	if dc - reach > R + 200 or dc + reach < R - 40 - SHELL then
		return false
	end
	local hills, craters, pads = gather(c / dc, reach)
	local mats, occ = table.create(NV), table.create(NV)
	local any = false
	for i = 1, NV do
		local mi, oi = table.create(NV), table.create(NV)
		mats[i], occ[i] = mi, oi
		for j = 1, NV do
			local mj, oj = table.create(NV), table.create(NV)
			mi[j], oi[j] = mj, oj
			for k = 1, NV do
				local v = origin + Vector3.new(i * 4 - 2, j * 4 - 2, k * 4 - 2) - CENTRE
				local r = v.Magnitude
				local o = 0
				if r > R - 60 - SHELL and r < R + 200 then
					local s = surface(v / r, hills, craters, pads)
					o = math.clamp((s - r) / 4 + 0.5, 0, 1)
					if r < s - SHELL then
						o = 0
					end
				end
				oj[k] = o
				mj[k] = o > 0 and MAT or AIR
				if o > 0 then
					any = true
				end
			end
		end
	end
	if any then
		T:WriteVoxels(Region3.new(origin, origin + Vector3.new(CH, CH, CH)), 4, mats, occ)
	end
	return any
end

-- Slabs run along x from -(R+256) to R+256, snapped to the 64-stud grid.
local LO = -math.ceil((R + 256) / CH) * CH
local SLABS = math.ceil((2 * (R + 256)) / CH)

local function run(budget: number): string
	local t0 = os.clock()
	local slab: number = data:GetAttribute("NextSlab") or 0
	local written = 0
	while slab < SLABS and os.clock() - t0 < budget do
		local x = LO + slab * CH
		for y = LO - R, LO - R + SLABS * CH, CH do
			-- only y rows near the sphere at this x
			for z = LO, LO + SLABS * CH, CH do
				if writeChunk(Vector3.new(x, y, z)) then
					written += 1
				end
			end
			task.wait()
		end
		slab += 1
		data:SetAttribute("NextSlab", slab)
	end
	return string.format("slab %d / %d, wrote %d chunks in %.1fs", slab, SLABS, written, os.clock() - t0)
end

return run
