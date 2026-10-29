--!strict
--!native
-- The shared Moon: how much dust is left on every patch, which sectors and regions are done.
-- The server owns this state; clients get a snapshot on join and batched deltas after that.
-- Sizes (Config.Grid): about 1M patches, 41k sectors, 642 regions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local MoonGrid = require(Shared:WaitForChild("MoonGrid"))
local Places = require(Shared:WaitForChild("Places"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sweep = require(Shared:WaitForChild("Sweep"))

local Moon = {}

local patch = MoonGrid.new(Config.Grid.PatchFrequency)
local sector = MoonGrid.new(Config.Grid.SectorFrequency)
local region = MoonGrid.new(Config.Grid.RegionFrequency)
Moon.patch, Moon.sector, Moon.region = patch, sector, region

local R = Config.Moon.Radius
local CENTRE = Config.Moon.Centre
local FULL = Sweep.FULL

local dust = buffer.create(patch.count)
buffer.fill(dust, 0, FULL)
local steep = buffer.create(patch.count) -- 0 unknown, 1 flat, 2 steep (Stardust)
local sectorOf = buffer.create(patch.count * 4) -- u32 parent sector of each patch
local sectorStart = buffer.create((sector.count + 1) * 4) -- CSR offsets into sectorPatches
local sectorPatches = buffer.create(patch.count * 4)
local sectorClean = buffer.create(sector.count * 2) -- u16 clean patches
local sectorDone = buffer.create(sector.count) -- u8 0/1
local regionOf = buffer.create(sector.count * 2) -- u16 parent region of each sector
local regionKids = buffer.create(region.count * 2)
local regionClean = buffer.create(region.count * 2)
local doneCount = 0

-- Build the patch -> sector map and the sector -> patches lists (two passes over every patch).
do
	local counts = buffer.create(sector.count * 4)
	patch:forEach(function(id, f, i, j)
		local s = MoonGrid.parentAt(patch, sector, f, i, j)
		buffer.writeu32(sectorOf, id * 4, s)
		buffer.writeu32(counts, s * 4, buffer.readu32(counts, s * 4) + 1)
	end)
	local run = 0
	for s = 0, sector.count - 1 do
		buffer.writeu32(sectorStart, s * 4, run)
		run += buffer.readu32(counts, s * 4)
	end
	buffer.writeu32(sectorStart, sector.count * 4, run)
	buffer.fill(counts, 0, 0)
	for id = 0, patch.count - 1 do
		local s = buffer.readu32(sectorOf, id * 4)
		local at = buffer.readu32(sectorStart, s * 4) + buffer.readu32(counts, s * 4)
		buffer.writeu32(sectorPatches, at * 4, id)
		buffer.writeu32(counts, s * 4, buffer.readu32(counts, s * 4) + 1)
	end
	sector:forEach(function(id, f, i, j)
		local r = MoonGrid.parentAt(sector, region, f, i, j)
		buffer.writeu16(regionOf, id * 2, r)
		buffer.writeu16(regionKids, r * 2, buffer.readu16(regionKids, r * 2) + 1)
	end)
end

-- Replication batches. changedEver lists every patch touched outside the yards, so a joining
-- client's snapshot skips the untouched million.
local changed: { [number]: boolean } = {}
local changedEver: { [number]: boolean } = {}
local doneNow: { number } = {}
local redusted: { number } = {}

local sectorDoneCallbacks: { (sectorId: number, by: Player?) -> () } = {}
local regionDoneCallbacks: { (regionId: number, by: Player?) -> () } = {}

function Moon.onSectorDone(fn: (sectorId: number, by: Player?) -> ())
	table.insert(sectorDoneCallbacks, fn)
end

function Moon.onRegionDone(fn: (regionId: number, by: Player?) -> ())
	table.insert(regionDoneCallbacks, fn)
end

function Moon.sectorOfPatch(id: number): number
	return buffer.readu32(sectorOf, id * 4)
end

function Moon.regionOfSector(id: number): number
	return buffer.readu16(regionOf, id * 2)
end

function Moon.patchesOf(sectorId: number): (number, number)
	return buffer.readu32(sectorStart, sectorId * 4), buffer.readu32(sectorStart, (sectorId + 1) * 4)
end

function Moon.patchAt(index: number): number
	return buffer.readu32(sectorPatches, index * 4)
end

function Moon.dustOf(patchId: number): number
	return buffer.readu8(dust, patchId)
end

-- 0 untouched, 1 started, 2 done
function Moon.sectorState(id: number): number
	if buffer.readu8(sectorDone, id) == 1 then
		return 2
	end
	local a, b = Moon.patchesOf(id)
	for k = a, b - 1 do
		if buffer.readu8(dust, Moon.patchAt(k)) < FULL then
			return 1
		end
	end
	return 0
end

function Moon.sectorProgress(id: number): number
	local a, b = Moon.patchesOf(id)
	if buffer.readu8(sectorDone, id) == 1 then
		return 1
	end
	local left = 0
	for k = a, b - 1 do
		left += buffer.readu8(dust, Moon.patchAt(k))
	end
	return 1 - left / ((b - a) * FULL)
end

function Moon.isSectorDone(id: number): boolean
	return buffer.readu8(sectorDone, id) == 1
end

function Moon.regionProgress(id: number): number
	return buffer.readu16(regionClean, id * 2) / math.max(1, buffer.readu16(regionKids, id * 2))
end

function Moon.cleanFraction(): number
	return doneCount / sector.count
end

function Moon.doneCount(): number
	return doneCount
end

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { Workspace.Terrain }

-- Steep patches hold Stardust. Checked once per patch with a ray at its centre.
function Moon.isSteep(patchId: number): boolean
	local s = buffer.readu8(steep, patchId)
	if s == 0 then
		local dir = patch:position(patchId)
		local hit = Workspace:Raycast(CENTRE + dir * (R + 300), -dir * 400, terrainOnly)
		s = if hit and Sweep.isSteep(dir, hit.Normal) then 2 else 1
		buffer.writeu8(steep, patchId, s)
	end
	return s == 2
end

local function markSectorDone(s: number, by: Player?)
	if buffer.readu8(sectorDone, s) == 1 then
		return
	end
	buffer.writeu8(sectorDone, s, 1)
	doneCount += 1
	table.insert(doneNow, s)
	for _, fn in sectorDoneCallbacks do
		task.spawn(fn, s, by)
	end
	local r = buffer.readu16(regionOf, s * 2)
	local c = buffer.readu16(regionClean, r * 2) + 1
	buffer.writeu16(regionClean, r * 2, c)
	if c == buffer.readu16(regionKids, r * 2) then
		for _, fn in regionDoneCallbacks do
			task.spawn(fn, r, by)
		end
	end
end

local function setPatch(id: number, level: number, by: Player?)
	local before = buffer.readu8(dust, id)
	if before == level then
		return
	end
	buffer.writeu8(dust, id, level)
	changed[id] = true
	local s = buffer.readu32(sectorOf, id * 4)
	if before > 0 and level == 0 then
		local c = buffer.readu16(sectorClean, s * 2) + 1
		buffer.writeu16(sectorClean, s * 2, c)
		local a, b = Moon.patchesOf(s)
		if c >= b - a then
			markSectorDone(s, by)
		end
	elseif before == 0 and level > 0 then
		buffer.writeu16(sectorClean, s * 2, math.max(0, buffer.readu16(sectorClean, s * 2) - 1))
	end
end

-- Scrub the patch under `dir` with a sample of `area` studs^2. Returns kg removed and how much
-- of it was Stardust. `allowSteep` is false for vehicles and bots (only brooms reach Stardust).
function Moon.scrubDir(dir: Vector3, area: number, clean: number, by: Player?, allowSteep: boolean?): (number, number)
	local id = patch:locate(dir)
	local level = buffer.readu8(dust, id)
	if level == 0 then
		return 0, 0
	end
	local isSteep = Moon.isSteep(id)
	if isSteep and allowSteep == false then
		return 0, 0
	end
	local left, frac = Sweep.scrub(level, area, clean)
	setPatch(id, left, by)
	local kg = frac * Sweep.PATCH_KG
	return kg, if isSteep then kg else 0
end

-- Clean one whole patch (bots and the Octo). Returns kg removed.
function Moon.clearPatch(id: number, by: Player?, allowSteep: boolean?): number
	local level = buffer.readu8(dust, id)
	if level == 0 or (allowSteep == false and Moon.isSteep(id)) then
		return 0
	end
	setPatch(id, 0, by)
	return level / FULL * Sweep.PATCH_KG
end

-- Clean a sector outright (station yards at startup).
function Moon.clearSector(s: number)
	local a, b = Moon.patchesOf(s)
	for k = a, b - 1 do
		setPatch(Moon.patchAt(k), 0, nil)
	end
end

-- Put the dust back on a sector (meteor showers).
function Moon.redustSector(s: number)
	local a, b = Moon.patchesOf(s)
	for k = a, b - 1 do
		local id = Moon.patchAt(k)
		buffer.writeu8(dust, id, FULL)
		changed[id] = nil
		changedEver[id] = nil
	end
	buffer.writeu16(sectorClean, s * 2, 0)
	if buffer.readu8(sectorDone, s) == 1 then
		buffer.writeu8(sectorDone, s, 0)
		doneCount -= 1
		local r = buffer.readu16(regionOf, s * 2)
		buffer.writeu16(regionClean, r * 2, math.max(0, buffer.readu16(regionClean, r * 2) - 1))
	end
	table.insert(redusted, s)
end

-- Sectors within `rings` steps of a sector, nearest first (bots, meteors, probe sites).
function Moon.ring(centre: number, rings: number): { number }
	local out, seen = { centre }, { [centre] = true }
	local frontier = { centre }
	for _ = 1, rings do
		local nextFrontier = {}
		for _, s in frontier do
			for _, nb in sector:neighbours(s) do
				if not seen[nb] then
					seen[nb] = true
					table.insert(out, nb)
					table.insert(nextFrontier, nb)
				end
			end
		end
		frontier = nextFrontier
	end
	return out
end

-- The yards round every station and Mop Base plot start clean.
for _, pad in Places.pads() do
	local dir, radius = pad.dir, pad.radius
	for _, s in Moon.ring(sector:locate(dir), math.ceil(radius / 40) + 1) do
		if Places.arc(sector:position(s), dir) <= radius then
			Moon.clearSector(s)
		end
	end
end
-- yards do not count as anyone's work, and clients get them in the snapshot
table.clear(doneNow)
table.clear(changed)
local yardDone = doneCount
Moon.yardSectors = yardDone

-- Snapshot for a joining client: every done sector, plus every patch that is part cleaned or
-- clean inside an unfinished sector.
local deltaRemote = Remotes.get("MoonDelta")
local snapshotRemote = Remotes.get("MoonSnapshot")

function Moon.sendSnapshot(player: Player)
	local done = buffer.create(doneCount * 4)
	local n = 0
	local partial: { number } = {}
	for s = 0, sector.count - 1 do
		if buffer.readu8(sectorDone, s) == 1 then
			buffer.writeu32(done, n * 4, s)
			n += 1
		end
	end
	for id in changedEver do
		local s = buffer.readu32(sectorOf, id * 4)
		if buffer.readu8(sectorDone, s) == 0 then
			table.insert(partial, id)
		end
	end
	local pb = buffer.create(#partial * 5)
	for k, id in partial do
		buffer.writeu32(pb, (k - 1) * 5, id)
		buffer.writeu8(pb, (k - 1) * 5 + 4, buffer.readu8(dust, id))
	end
	snapshotRemote:FireClient(player, done, pb, Moon.yardSectors)
end

function Moon.flush()
	if next(changed) == nil and #doneNow == 0 and #redusted == 0 then
		return
	end
	local count = 0
	for _ in changed do
		count += 1
	end
	local pb = buffer.create(count * 5)
	local k = 0
	for id in changed do
		buffer.writeu32(pb, k * 5, id)
		buffer.writeu8(pb, k * 5 + 4, buffer.readu8(dust, id))
		changedEver[id] = true
		k += 1
	end
	local db = buffer.create(#doneNow * 4)
	for i, s in doneNow do
		buffer.writeu32(db, (i - 1) * 4, s)
	end
	local rb = buffer.create(#redusted * 4)
	for i, s in redusted do
		buffer.writeu32(rb, (i - 1) * 4, s)
	end
	table.clear(changed)
	table.clear(doneNow)
	table.clear(redusted)
	deltaRemote:FireAllClients(pb, db, rb)
end

task.spawn(function()
	while true do
		task.wait(0.25)
		Moon.flush()
	end
end)

Players.PlayerAdded:Connect(function(player)
	task.wait(1)
	Moon.flush()
	Moon.sendSnapshot(player)
end)

return Moon
