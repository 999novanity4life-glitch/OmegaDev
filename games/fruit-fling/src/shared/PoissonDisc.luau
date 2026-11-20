--!strict
-- Poisson-disc scatter (map rulebook M10: never pure random; clumps and gaps
-- look fake). Bridson's algorithm on a 2D rectangle, with keep-clear zones.
-- Pure: takes a seed and uses Rng, no Roblox services.

local Rng = require(script.Parent.Rng)

export type Vec2 = { x: number, z: number }
export type Rect = { minX: number, maxX: number, minZ: number, maxZ: number }

local PoissonDisc = {}

local function inRect(p: Vec2, r: Rect): boolean
	return p.x >= r.minX and p.x <= r.maxX and p.z >= r.minZ and p.z <= r.maxZ
end

-- area: where points may go. spacing: minimum distance between points.
-- keepClear: rectangles where no point may land (lane, spawn, doors).
-- maxPoints caps the result. k = candidates per active point (30 is standard).
function PoissonDisc.sample(
	area: Rect,
	spacing: number,
	seed: number,
	keepClear: { Rect }?,
	maxPoints: number?,
	k: number?
): { Vec2 }
	assert(spacing > 0, "spacing must be > 0")
	local rng = Rng.new(seed)
	local tries = k or 30
	local cap = maxPoints or math.huge
	local cell = spacing / math.sqrt(2)
	local cols = math.max(1, math.ceil((area.maxX - area.minX) / cell))
	local rows = math.max(1, math.ceil((area.maxZ - area.minZ) / cell))
	local grid: { [number]: Vec2 } = {}
	local points: { Vec2 } = {}
	local active: { Vec2 } = {}

	local function cellIndex(p: Vec2): (number, number)
		return math.floor((p.x - area.minX) / cell), math.floor((p.z - area.minZ) / cell)
	end

	local function blocked(p: Vec2): boolean
		if keepClear then
			for _, r in keepClear do
				if inRect(p, r) then
					return true
				end
			end
		end
		return false
	end

	local function farEnough(p: Vec2): boolean
		local cx, cz = cellIndex(p)
		for gx = math.max(0, cx - 2), math.min(cols - 1, cx + 2) do
			for gz = math.max(0, cz - 2), math.min(rows - 1, cz + 2) do
				local q = grid[gz * cols + gx]
				if q and (q.x - p.x) ^ 2 + (q.z - p.z) ^ 2 < spacing * spacing then
					return false
				end
			end
		end
		return true
	end

	local function add(p: Vec2)
		table.insert(points, p)
		table.insert(active, p)
		local cx, cz = cellIndex(p)
		grid[cz * cols + cx] = p
	end

	-- seed point: first random point not in a keep-clear zone
	for _ = 1, 200 do
		local p = {
			x = rng:range(area.minX, area.maxX),
			z = rng:range(area.minZ, area.maxZ),
		}
		if not blocked(p) then
			add(p)
			break
		end
	end

	while #active > 0 and #points < cap do
		local idx = rng:int(1, #active)
		local base = active[idx]
		local found = false
		for _ = 1, tries do
			local angle = rng:range(0, 2 * math.pi)
			local dist = rng:range(spacing, 2 * spacing)
			local p = { x = base.x + math.cos(angle) * dist, z = base.z + math.sin(angle) * dist }
			if inRect(p, area) and not blocked(p) and farEnough(p) then
				add(p)
				found = true
				break
			end
		end
		if not found then
			active[idx] = active[#active]
			active[#active] = nil
		end
	end
	return points
end

return table.freeze(PoissonDisc)
