--!strict
-- Moon Mop: round Moon feature list (hills, craters, station pads), stored in
-- ServerStorage.MoonMapData for MoonSphere.luau to write into Terrain. Deterministic (seed 42), so
-- running it again rebuilds the same Moon. Directions are unit vectors from the Moon's centre.
-- Running it clears Terrain and resets NextSlab; then call MoonSphere's run(budget) until done.
local HS = game:GetService("HttpService")
local R = 2000
local rng = Random.new(42)
local function randDir(): Vector3
	local z = rng:NextNumber(-1, 1)
	local a = rng:NextNumber(0, math.pi * 2)
	local s = math.sqrt(1 - z * z)
	return Vector3.new(s * math.cos(a), z, s * math.sin(a))
end
-- Stations: North at the top (+Y), East/South/West round the sides, like the original's named stations.
local pads = {
	{ Vector3.new(0, 1, 0), 90, "North" },
	{ Vector3.new(1, 0.25, 0).Unit, 80, "East" },
	{ Vector3.new(0, -1, 0), 80, "South" },
	{ Vector3.new(-1, 0.25, 0).Unit, 80, "West" },
}
local function nearPad(d: Vector3, extra: number): boolean
	for _, p in pads do
		if (d - (p[1] :: Vector3)).Magnitude * R < (p[2] :: number) + extra then
			return true
		end
	end
	return false
end
local hills, craters = {}, {}
for _ = 1, 520 do
	local d = randDir()
	local w = 60 + 260 * rng:NextNumber() ^ 1.6 -- footprint radius (studs)
	local steep = rng:NextNumber() < 0.18 -- a few steep cone hills
	local h = if steep then w * rng:NextNumber(0.35, 0.55) else w * rng:NextNumber(0.08, 0.22)
	if not nearPad(d, w + 40) then
		table.insert(hills, { d.X, d.Y, d.Z, w, h, if steep then 1 else 0 })
	end
end
for _ = 1, 900 do
	local d = randDir()
	local cr = 10 + 110 * rng:NextNumber() ^ 3
	if not nearPad(d, cr * 1.6 + 30) then
		table.insert(craters, { d.X, d.Y, d.Z, cr, cr * rng:NextNumber(0.16, 0.24) })
	end
end
local f = game:GetService("ServerStorage"):FindFirstChild("MoonMapData") or Instance.new("Folder")
f.Name = "MoonMapData"
f.Parent = game:GetService("ServerStorage")
f:SetAttribute("Radius", R)
f:SetAttribute("Hills", HS:JSONEncode(hills))
f:SetAttribute("Craters", HS:JSONEncode(craters))
local padOut = {}
for _, p in pads do
	local d = p[1] :: Vector3
	table.insert(padOut, { d.X, d.Y, d.Z, p[2], p[3] })
end
f:SetAttribute("Pads", HS:JSONEncode(padOut))
f:SetAttribute("NextSlab", 0)
workspace.Terrain:Clear()
return #hills .. " hills, " .. #craters .. " craters"
