--!strict
-- Where things are on the Moon: the 12 stations (on the grid's 12 pentagons), the Mop Base plots
-- round the North Station, the 195 tangled flags and the 26 probe sites. Pure and deterministic,
-- so the server, every client and the Studio map tools all agree without sending positions.

local Config = require(script.Parent.Config)
local MoonGrid = require(script.Parent.MoonGrid)

local Places = {}

local R = Config.Moon.Radius
local CENTRE = Config.Moon.Centre

-- Small deterministic generator (xorshift32) so results match under Lune and in Roblox.
local function rng(seed: number): () -> number
	local s = bit32.bor(seed * 2654435761 % 4294967296, 1)
	return function(): number
		s = bit32.bxor(s, bit32.lshift(s, 13))
		s = bit32.bxor(s, bit32.rshift(s, 17))
		s = bit32.bxor(s, bit32.lshift(s, 5))
		return s / 4294967296
	end
end
Places.rng = rng

local function randomDir(next: () -> number): Vector3
	local z = next() * 2 - 1
	local a = next() * math.pi * 2
	local r = math.sqrt(1 - z * z)
	return Vector3.new(r * math.cos(a), z, r * math.sin(a))
end

-- A frame on the surface: position at radius `lift` above the centre, UpVector = radial up,
-- LookVector turned `yaw` from the local "north" (toward +Y, or +Z at the poles).
function Places.surfaceFrame(dir: Vector3, height: number?, yaw: number?): CFrame
	local up = dir.Unit
	local ref = if math.abs(up.Y) < 0.95 then Vector3.yAxis else Vector3.zAxis
	local north = (ref - up * ref:Dot(up)).Unit
	local right = north:Cross(up)
	local cf = CFrame.fromMatrix(CENTRE + up * (R + (height or 0)), right, up, -north)
	return cf * CFrame.Angles(0, yaw or 0, 0)
end

-- The same kind of frame at a world position (UpVector = radial up there).
function Places.frameAt(position: Vector3, yaw: number?): CFrame
	local up = (position - CENTRE).Unit
	local ref = if math.abs(up.Y) < 0.95 then Vector3.yAxis else Vector3.zAxis
	local north = (ref - up * ref:Dot(up)).Unit
	local right = north:Cross(up)
	return CFrame.fromMatrix(position, right, up, -north) * CFrame.Angles(0, yaw or 0, 0)
end

function Places.up(position: Vector3): Vector3
	return (position - CENTRE).Unit
end

function Places.dirOf(position: Vector3): Vector3
	return (position - CENTRE).Unit
end

-- Great-circle distance in studs between two directions.
function Places.arc(a: Vector3, b: Vector3): number
	return math.acos(math.clamp(a.Unit:Dot(b.Unit), -1, 1)) * R
end

export type Station = { index: number, name: string, dir: Vector3 }
Places.stations = {} :: { Station }
for i, dir in MoonGrid.CORNERS do
	table.insert(Places.stations, { index = i, name = Config.Stations.Names[i], dir = dir })
end

function Places.nearestStation(dir: Vector3): (Station, number)
	local best, bestArc = Places.stations[1], math.huge
	for _, s in Places.stations do
		local d = Places.arc(dir, s.dir)
		if d < bestArc then
			best, bestArc = s, d
		end
	end
	return best, bestArc
end

-- Mop Base plots: two rings round the North Station. Each plot is a square tangent frame whose
-- LookVector points back at the station.
export type Plot = { index: number, dir: Vector3 }
Places.plots = {} :: { Plot }
do
	local north = Places.stations[1].dir
	local a = Config.Automation
	for ring, spec in { a.PlotRing, a.PlotRing2 } do
		for k = 0, spec.Count - 1 do
			local lon = math.rad(360 / spec.Count * (k + (if ring == 2 then 0.5 else 0)) + 15)
			local ang = spec.Distance / R
			local dir = Vector3.new(math.sin(ang) * math.cos(lon), math.cos(ang), math.sin(ang) * math.sin(lon))
			table.insert(Places.plots, { index = #Places.plots + 1, dir = dir })
		end
	end
	assert(north.Y > 0.99, "station 1 should be the North Station")
end

-- Flat pads the map tools carve into the terrain.
export type Pad = { dir: Vector3, radius: number, name: string }
function Places.pads(): { Pad }
	local out: { Pad } = {}
	for _, s in Places.stations do
		table.insert(out, { dir = s.dir, radius = Config.Stations.PadRadius, name = s.name })
	end
	for _, p in Places.plots do
		table.insert(out, { dir = p.dir, radius = Config.Automation.PlotSize * 0.72, name = "Plot" .. p.index })
	end
	return out
end

local function clearOfPads(dir: Vector3, extra: number): boolean
	for _, s in Places.stations do
		if Places.arc(dir, s.dir) < Config.Stations.PadRadius + extra then
			return false
		end
	end
	for _, p in Places.plots do
		if Places.arc(dir, p.dir) < Config.Automation.PlotSize * 0.75 + extra then
			return false
		end
	end
	return true
end

-- 195 flags: a third within reach of the North Station, the rest all over the Moon.
local flagDirs: { Vector3 } = {}
do
	local next = rng(Config.Flags.Seed)
	local tries = 0
	while #flagDirs < Config.Flags.Count and tries < 20000 do
		tries += 1
		local dir = randomDir(next)
		if #flagDirs < Config.Flags.Count // 3 then
			-- bias toward the north cap
			local t = next() * 0.35
			dir = (dir + Vector3.yAxis * (1 / math.max(t, 0.05))).Unit
		end
		if clearOfPads(dir, 20) then
			local ok = true
			for _, other in flagDirs do
				if Places.arc(dir, other) < 60 then
					ok = false
					break
				end
			end
			if ok then
				table.insert(flagDirs, dir)
			end
		end
	end
end
Places.flags = flagDirs

-- 26 probe sites, each a sector (plus one ring round it) holding a buried probe panel.
local probeDirs: { Vector3 } = {}
do
	local next = rng(Config.Probes.Seed)
	local tries = 0
	while #probeDirs < Config.Probes.Count and tries < 20000 do
		tries += 1
		local dir = randomDir(next)
		if #probeDirs < 4 then
			dir = (dir + Vector3.yAxis * 3).Unit -- a few close to home
		end
		if clearOfPads(dir, 60) then
			local ok = true
			for _, other in probeDirs do
				if Places.arc(dir, other) < 400 then
					ok = false
					break
				end
			end
			if ok then
				table.insert(probeDirs, dir)
			end
		end
	end
end
Places.probes = probeDirs

return table.freeze(Places)
