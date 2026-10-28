--!strict
-- Pure terrain math: seeded randomness, height fields, craters, scatter and
-- chunk planning. No services, so every rule is unit-tested under Lune.
-- WorldBuilder (server) turns these numbers into Terrain:WriteVoxels calls.
--
-- Engine facts used here (Terrain API reference,
-- https://create.roblox.com/docs/reference/engine/classes/Terrain):
--   WriteVoxels/ReadVoxels take resolution 4 and a grid-aligned region of at
--   most 4,194,304 voxels per call.
-- Everything else (noise shape, crater profile, material rules) is our own
-- design choice [INFERRED], tuned through Config.Terrain.

local TerrainGen = {}

TerrainGen.VOXEL = 4
TerrainGen.MAX_VOXELS_PER_CALL = 4194304

-- Park-Miller "minimal standard" generator. Products stay below 2^53, so the
-- sequence is exact in doubles and identical on every machine.
export type Rng = { state: number }

local MODULUS = 2147483647
local MULTIPLIER = 48271

function TerrainGen.rng(seed: number): Rng
	local s = math.floor(math.abs(seed)) % MODULUS
	if s == 0 then
		s = 1
	end
	return { state = s }
end

-- Uniform number in [0, 1).
function TerrainGen.nextFloat(r: Rng): number
	r.state = (r.state * MULTIPLIER) % MODULUS
	return (r.state - 1) / (MODULUS - 1)
end

function TerrainGen.nextRange(r: Rng, min: number, max: number): number
	return min + (max - min) * TerrainGen.nextFloat(r)
end

export type Crater = { x: number, z: number, radius: number, depth: number }

export type HeightParams = {
	seed: number,
	baseHeight: number, -- studs
	amplitude: number, -- studs, peak deviation of the noise
	frequency: number, -- 1 / studs for the first octave
	octaves: number,
	persistence: number, -- amplitude multiplier per octave (0..1)
	craters: { Crater }?,
	rimHeight: number?, -- crater rim as a fraction of depth
}

-- Fractal noise (fBm) in roughly [-1, 1]. math.noise is Luau's Perlin noise.
function TerrainGen.fbm(x: number, z: number, p: HeightParams): number
	local total, amp, freq, norm = 0, 1, p.frequency, 0
	local offset = (p.seed % 1000) * 17.31
	for _ = 1, math.max(1, p.octaves) do
		total += math.noise(x * freq + offset, z * freq - offset, offset * 0.5) * amp
		norm += amp
		amp *= p.persistence
		freq *= 2
	end
	return total / norm
end

-- Bowl with a raised rim: -depth at the center, rising to the rim at the
-- edge, fading back to 0 by 1.5 radii.
function TerrainGen.craterOffset(c: Crater, x: number, z: number, rimHeight: number): number
	local d = math.sqrt((x - c.x) ^ 2 + (z - c.z) ^ 2) / c.radius
	if d >= 1.5 then
		return 0
	end
	local rim = c.depth * rimHeight
	if d < 1 then
		return -c.depth * (1 - d * d) + rim * d * d * d
	end
	local fade = (1.5 - d) / 0.5
	return rim * fade * fade
end

function TerrainGen.heightAt(p: HeightParams, x: number, z: number): number
	local h = p.baseHeight + TerrainGen.fbm(x, z, p) * p.amplitude
	if p.craters then
		local rimHeight = p.rimHeight or 0.25
		for _, c in p.craters do
			h += TerrainGen.craterOffset(c, x, z, rimHeight)
		end
	end
	return h
end

-- Slope as rise over run (0 = flat, 1 = 45 degrees) by central differences.
function TerrainGen.slopeAt(p: HeightParams, x: number, z: number, step: number?): number
	local s = step or TerrainGen.VOXEL
	local dx = (TerrainGen.heightAt(p, x + s, z) - TerrainGen.heightAt(p, x - s, z)) / (2 * s)
	local dz = (TerrainGen.heightAt(p, x, z + s) - TerrainGen.heightAt(p, x, z - s)) / (2 * s)
	return math.sqrt(dx * dx + dz * dz)
end

-- Random craters inside a square area, biggest first, not overlapping centers.
function TerrainGen.craters(seed: number, count: number, size: number, minR: number, maxR: number): { Crater }
	local r = TerrainGen.rng(seed + 7919)
	local list: { Crater } = {}
	for _ = 1, count do
		local radius = TerrainGen.nextRange(r, minR, maxR)
		table.insert(list, {
			x = TerrainGen.nextRange(r, radius, size - radius),
			z = TerrainGen.nextRange(r, radius, size - radius),
			radius = radius,
			depth = radius * TerrainGen.nextRange(r, 0.15, 0.3),
		})
	end
	table.sort(list, function(a, b)
		return a.radius > b.radius
	end)
	return list
end

-- Material rules are checked in order; the first match wins.
export type MaterialRule = {
	material: string,
	minHeight: number?,
	maxHeight: number?,
	minSlope: number?,
	maxSlope: number?,
}

function TerrainGen.materialFor(rules: { MaterialRule }, height: number, slope: number, fallback: string): string
	for _, rule in rules do
		if
			(rule.minHeight == nil or height >= rule.minHeight)
			and (rule.maxHeight == nil or height < rule.maxHeight)
			and (rule.minSlope == nil or slope >= rule.minSlope)
			and (rule.maxSlope == nil or slope < rule.maxSlope)
		then
			return rule.material
		end
	end
	return fallback
end

-- How full a voxel cell is, given the column's surface height. Cells wholly
-- below the surface are 1, wholly above are 0, the surface cell is partial,
-- which is what gives smooth terrain its soft top.
function TerrainGen.occupancy(surface: number, cellMinY: number, resolution: number?): number
	local res = resolution or TerrainGen.VOXEL
	return math.clamp((surface - cellMinY) / res, 0, 1)
end

-- Poisson-disk style scatter (dart throwing on a grid): points inside a
-- width x depth area, no two closer than minDistance. Deterministic per seed.
export type Point = { x: number, z: number }

function TerrainGen.scatter(
	seed: number,
	width: number,
	depth: number,
	minDistance: number,
	maxPoints: number
): { Point }
	local r = TerrainGen.rng(seed + 104729)
	local cell = minDistance / math.sqrt(2)
	local cols = math.max(1, math.ceil(width / cell))
	local grid: { [number]: Point } = {}
	local points: { Point } = {}
	local attempts = maxPoints * 30
	local minSq = minDistance * minDistance
	for _ = 1, attempts do
		if #points >= maxPoints then
			break
		end
		local x = TerrainGen.nextFloat(r) * width
		local z = TerrainGen.nextFloat(r) * depth
		local gx, gz = math.floor(x / cell), math.floor(z / cell)
		local ok = true
		for ix = gx - 2, gx + 2 do
			for iz = gz - 2, gz + 2 do
				local other = grid[iz * cols + ix]
				if other and ix >= 0 and ix < cols and (other.x - x) ^ 2 + (other.z - z) ^ 2 < minSq then
					ok = false
					break
				end
			end
			if not ok then
				break
			end
		end
		if ok then
			local point = { x = x, z = z }
			grid[gz * cols + gx] = point
			table.insert(points, point)
		end
	end
	return points
end

-- Split a box (in studs, from origin) into grid-aligned chunks that each fit
-- one WriteVoxels call. chunkVoxels is the edge length in voxels per axis.
export type Chunk = { minX: number, minY: number, minZ: number, maxX: number, maxY: number, maxZ: number }

function TerrainGen.planChunks(sizeX: number, sizeY: number, sizeZ: number, chunkVoxels: number?): { Chunk }
	local v = TerrainGen.VOXEL
	local edge = math.max(1, math.floor(chunkVoxels or 64)) * v
	local function snap(n: number): number
		return math.ceil(n / v) * v
	end
	local sx, sy, sz = snap(sizeX), snap(sizeY), snap(sizeZ)
	-- Shrink the vertical extent if a full-height chunk would pass the cap.
	local maxColumns = TerrainGen.MAX_VOXELS_PER_CALL / ((edge / v) * (edge / v))
	local stepY = math.min(sy, math.max(v, math.floor(maxColumns) * v))
	local chunks: { Chunk } = {}
	for x = 0, sx - 1, edge do
		for z = 0, sz - 1, edge do
			for y = 0, sy - 1, stepY do
				table.insert(chunks, {
					minX = x,
					minY = y,
					minZ = z,
					maxX = math.min(x + edge, sx),
					maxY = math.min(y + stepY, sy),
					maxZ = math.min(z + edge, sz),
				})
			end
		end
	end
	return chunks
end

function TerrainGen.voxelCount(c: Chunk): number
	local v = TerrainGen.VOXEL
	return ((c.maxX - c.minX) / v) * ((c.maxY - c.minY) / v) * ((c.maxZ - c.minZ) / v)
end

return table.freeze(TerrainGen)
