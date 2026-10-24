--!strict
-- Pure geometry for the containment shaft, in numbers only (heights, angles,
-- radii) relative to the match origin. MapService turns it into parts;
-- tests check it is climbable. Angles are in degrees.

local Config = require(script.Parent.Config)
local CourseLayout = require(script.Parent.CourseLayout)
local Footprint = require(script.Parent.Footprint)
local MapDefs = require(script.Parent.MapDefs)

local ShaftLayout = {}

export type Pad = { angle: number, radius: number, y: number }
export type Tier = {
	index: number,
	floorY: number, -- top of this tier's floor
	ceilingY: number, -- top of the bulkhead above (= next floor)
	hatchAngle: number, -- where the hatch, landing and bridge are
	hatchRadius: number,
	pads: { Pad }, -- floor up to the landing (one per course element)
	course: { CourseLayout.Element }, -- the lab-equipment parkour route
	landing: Pad,
	bridge: { Pad }, -- landing up through the hatch (only after the solve)
	puzzle: string,
	footprint: Footprint.Footprint, -- this map's room shape (same for every tier)
}
export type Layout = {
	map: MapDefs.MapDef,
	footprint: Footprint.Footprint,
	tiers: { Tier },
	exitY: number,
	exitAngle: number,
	exitRadius: number,
	topY: number,
}

-- Small deterministic generator so the same seed builds the same shaft
-- on every machine (and in tests) without Random.
local function lcg(seed: number): () -> number
	local state = math.abs(math.floor(seed)) % 2147483647
	if state == 0 then
		state = 1
	end
	return function()
		state = (state * 48271) % 2147483647
		return state / 2147483647
	end
end

local function shuffled(list: { string }, rand: () -> number): { string }
	local out = table.clone(list)
	for i = #out, 2, -1 do
		local j = math.floor(rand() * i) + 1
		out[i], out[j] = out[j], out[i]
	end
	return out
end

function ShaftLayout.build(seed: number, mapId: string?): Layout
	local cfg = Config.Shaft
	local map = MapDefs.get(mapId)
	local fp = Footprint.new(map.footprint)
	local rand = lcg(seed)
	-- Every run gets the three mini-games plus physical puzzles to fill the
	-- floors (no repeats until every puzzle has been used), shuffled.
	local order = Config.Puzzles.Order
	local pool = { order[1], order[2], order[3] }
	local physical = {}
	for i = 4, #order do
		table.insert(physical, order[i])
	end
	physical = shuffled(physical, rand)
	for i = 1, math.max(1, map.tiers - 3) do
		table.insert(pool, physical[(i - 1) % math.max(1, #physical) + 1])
	end
	local puzzles = shuffled(pool, rand)
	local tiers: { Tier } = {}
	local hatchAngle = rand() * 360
	for index = 1, map.tiers do
		local floorY = (index - 1) * cfg.TierHeight
		local course =
			CourseLayout.build(index, hatchAngle, rand, { footprint = fp, gaps = map.gaps, theme = map.theme })
		local pads: { Pad } = {}
		for _, e in course do
			table.insert(pads, { angle = e.angle % 360, radius = e.radius, y = floorY + e.y })
			e.angle %= 360
		end
		local hatchRadius = 20
		local landing = { angle = hatchAngle, radius = hatchRadius, y = floorY + cfg.LandingHeight }
		local bridge: { Pad } = {}
		local rise = (cfg.TierHeight - cfg.LandingHeight) / (cfg.BridgePads + 1)
		for i = 1, cfg.BridgePads do
			-- Steps sweep across the hatch footprint so the last one sits at its edge.
			local sweep = (i - (cfg.BridgePads + 1) / 2) * 9
			table.insert(bridge, { angle = (hatchAngle + sweep) % 360, radius = hatchRadius, y = landing.y + i * rise })
		end
		table.insert(tiers, {
			index = index,
			floorY = floorY,
			ceilingY = floorY + cfg.TierHeight,
			hatchAngle = hatchAngle,
			hatchRadius = hatchRadius,
			pads = pads,
			course = course,
			landing = landing,
			bridge = bridge,
			puzzle = puzzles[(index - 1) % #puzzles + 1],
			footprint = fp,
		})
		-- Next tier's hatch is around the shaft, so every tier is a new climb.
		hatchAngle = (hatchAngle + 120 + rand() * 120) % 360
	end
	local topY = map.tiers * cfg.TierHeight
	local last = tiers[#tiers]
	return {
		map = map,
		footprint = fp,
		tiers = tiers,
		exitY = topY + 1,
		exitAngle = (last.hatchAngle + 180) % 360,
		exitRadius = 12,
		topY = topY,
	}
end

-- Position on the ground plane for an angle and radius (x, z), in this map's
-- room when a footprint is given (round reference shaft otherwise).
function ShaftLayout.polar(angle: number, radius: number, fp: Footprint.Footprint?): (number, number)
	if fp then
		return Footprint.polar(fp, angle, radius)
	end
	local r = math.rad(angle)
	return math.cos(r) * radius, math.sin(r) * radius
end

-- Straight-line distance between two pads (for climbability tests).
function ShaftLayout.distance(a: Pad, b: Pad, fp: Footprint.Footprint?): (number, number)
	local ax, az = ShaftLayout.polar(a.angle, a.radius, fp)
	local bx, bz = ShaftLayout.polar(b.angle, b.radius, fp)
	return math.sqrt((ax - bx) ^ 2 + (az - bz) ^ 2), b.y - a.y
end

return ShaftLayout
