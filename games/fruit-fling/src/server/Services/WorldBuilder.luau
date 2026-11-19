--!strict
-- Writes procedural terrain from TerrainGen into Workspace.Terrain and
-- scatters prop models on it. Works at runtime, or at edit time through the
-- Studio MCP `execute_luau` tool (require this module and call build), which
-- is how a Scenic agent bakes a map into the place and then hand-polishes it.
--
-- Engine facts (Terrain API reference,
-- https://create.roblox.com/docs/reference/engine/classes/Terrain):
-- WriteVoxels takes a Region3 aligned to the 4-stud grid, resolution 4, and
-- 3D arrays indexed [x][y][z] of Enum.Material and occupancy (0..1); at most
-- 4,194,304 voxels per call. TerrainGen.planChunks keeps us under that.
-- Not yet run in Studio: verify with docs/VISUAL_QA.md before relying on it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local TerrainGen = require(Shared:WaitForChild("TerrainGen"))

local WorldBuilder = {}

local VOXEL = TerrainGen.VOXEL

function WorldBuilder.heightParams(): TerrainGen.HeightParams
	local cfg = Config.Terrain
	local craters = nil
	if cfg.CraterCount > 0 then
		craters = TerrainGen.craters(cfg.Seed, cfg.CraterCount, cfg.Size, cfg.CraterRadius[1], cfg.CraterRadius[2])
	end
	return {
		seed = cfg.Seed,
		baseHeight = cfg.BaseHeight,
		amplitude = cfg.Amplitude,
		frequency = cfg.Frequency,
		octaves = cfg.Octaves,
		persistence = cfg.Persistence,
		craters = craters,
	}
end

local function materialEnum(name: string): Enum.Material
	-- any: Enum.Material indexed by a name from Config; pcall guards typos.
	local ok, value = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	return if ok and value then value else Enum.Material.Ground
end

-- Fill one chunk's arrays and write it.
local function writeChunk(chunk: TerrainGen.Chunk, params: TerrainGen.HeightParams)
	local cfg = Config.Terrain
	local materials: { { { Enum.Material } } } = {}
	local occupancy: { { { number } } } = {}
	local air = Enum.Material.Air
	for ix = 1, (chunk.maxX - chunk.minX) / VOXEL do
		local x = chunk.minX + (ix - 0.5) * VOXEL
		materials[ix], occupancy[ix] = {}, {}
		for iy = 1, (chunk.maxY - chunk.minY) / VOXEL do
			materials[ix][iy], occupancy[ix][iy] = {}, {}
		end
		for iz = 1, (chunk.maxZ - chunk.minZ) / VOXEL do
			local z = chunk.minZ + (iz - 0.5) * VOXEL
			local surface = TerrainGen.heightAt(params, x, z)
			local slope = TerrainGen.slopeAt(params, x, z)
			local mat = materialEnum(TerrainGen.materialFor(cfg.Materials, surface, slope, cfg.FallbackMaterial))
			for iy = 1, (chunk.maxY - chunk.minY) / VOXEL do
				local occ = TerrainGen.occupancy(surface, chunk.minY + (iy - 1) * VOXEL)
				occupancy[ix][iy][iz] = occ
				materials[ix][iy][iz] = if occ > 0 then mat else air
			end
		end
	end
	local region =
		Region3.new(Vector3.new(chunk.minX, chunk.minY, chunk.minZ), Vector3.new(chunk.maxX, chunk.maxY, chunk.maxZ))
			:ExpandToGrid(VOXEL)
	workspace.Terrain:WriteVoxels(region, VOXEL, materials, occupancy)
end

-- Generate the whole area described by Config.Terrain. Yields between chunks
-- so Studio stays responsive.
function WorldBuilder.build()
	local cfg = Config.Terrain
	local params = WorldBuilder.heightParams()
	local chunks = TerrainGen.planChunks(cfg.Size, cfg.Depth, cfg.Size, cfg.ChunkVoxels)
	for i, chunk in chunks do
		writeChunk(chunk, params)
		if i % 4 == 0 then
			task.wait()
		end
	end
end

-- Drop copies of the given models onto the terrain at scatter points. Each
-- copy gets a random yaw so neighbours never share a facing (BONES env-art
-- video: rotate neighbouring props 90 degrees or more).
function WorldBuilder.scatterProps(templates: { Model }, parent: Instance): { Model }
	local cfg = Config.Terrain
	local placed: { Model } = {}
	if #templates == 0 then
		return placed
	end
	local rng = TerrainGen.rng(cfg.Seed + 31337)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	for _, point in TerrainGen.scatter(cfg.Seed, cfg.Size, cfg.Size, cfg.PropSpacing, cfg.MaxProps) do
		local origin = Vector3.new(point.x, cfg.Depth + 50, point.z)
		local hit = workspace:Raycast(origin, Vector3.new(0, -(cfg.Depth + 100), 0), params)
		if hit and hit.Material ~= Enum.Material.Water then
			local index = 1 + math.floor(TerrainGen.nextFloat(rng) * #templates)
			local copy = templates[index]:Clone()
			local yaw = math.rad(TerrainGen.nextRange(rng, 0, 360))
			copy:PivotTo(CFrame.new(hit.Position) * CFrame.Angles(0, yaw, 0))
			copy.Parent = parent
			table.insert(placed, copy)
		end
	end
	return placed
end

return WorldBuilder
