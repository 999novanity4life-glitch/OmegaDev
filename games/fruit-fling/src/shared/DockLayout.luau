--!strict
-- Dock map plan for the throw lane (docs/rulebooks/MAP_RULEBOOK.md, plan in
-- games/fruit-fling/MAP_PLAN.md). Pure: turns Config.Dock + a seed into a list
-- of placements, ropes and terrain ops. DockBuilder (server) turns the plan
-- into Instances. Keeping the plan pure lets Lune specs prove the rules
-- (rhythm, keep-clear lane, story groups, weenie, no y = 0) without Studio.
--
-- Axes: the player throws along -Z from the pier edge at z = Config.Dock.ThrowEdgeZ.
-- +Z is the harbour behind the player. Water surface is Config.Dock.WaterY.

local Catenary = require(script.Parent.Catenary)
local PoissonDisc = require(script.Parent.PoissonDisc)
local Rng = require(script.Parent.Rng)

export type Vec3 = { x: number, y: number, z: number }
export type Tier = "Macro" | "Meso" | "Micro" | "Lighting" | "Gameplay"

export type Placement = {
	kind: string, -- kit piece name, e.g. "Piling", "Crate", "Lighthouse"
	area: string, -- "Pier" | "Harbour" | "Lane" | "LaneEnd"
	tier: Tier,
	pos: Vec3, -- centre of the piece's bounding box
	size: Vec3,
	yaw: number, -- degrees about +Y
	tilt: number, -- degrees about the piece's local X
	why: string, -- rule M6: every placed thing has a reason
	group: number?, -- story group id for props
}

export type Rope = {
	kind: string, -- "Rope" | "Bunting" | "Rigging"
	area: string,
	tier: Tier,
	points: { Vec3 },
	thickness: number,
	why: string,
}

export type TerrainOp = {
	material: string, -- Enum.Material name
	shape: "Block" | "Cylinder" | "Ball",
	pos: Vec3,
	size: Vec3, -- Block: full size. Cylinder: (radius*2, height, radius*2). Ball: (r*2, r*2, r*2)
	yaw: number,
	why: string,
}

export type StoryGroup = { id: number, story: string, centre: Vec3, count: number }

export type Plan = {
	placements: { Placement },
	ropes: { Rope },
	terrain: { TerrainOp },
	groups: { StoryGroup },
	throwOrigin: Vec3,
}

export type DockConfig = {
	Seed: number,
	DeckHeight: number,
	WaterY: number,
	SeabedY: number,
	PierHalfWidth: number,
	ThrowEdgeZ: number,
	ShoreZ: number,
	PilingSpacing: number,
	PilingDiameter: number,
	PilingAboveDeck: number,
	LanternEvery: number,
	RopeSlack: number,
	LaneKeepClearHalfWidth: number,
	GroupSpacing: number,
	GroupSize: { number },
	BuntingEvery: number,
	BuntingPoleHeight: number,
	LaneLength: number,
	BuoyEvery: number,
	SeaStackEvery: number,
	LighthouseHeight: number,
	CoveRadius: number,
	CoveTerraces: number,
	TerraceStep: number,
}

local DockLayout = {}

local function v(x: number, y: number, z: number): Vec3
	return { x = x, y = y, z = z }
end

-- Stories for prop groups (M11 / M38): one cause-and-effect pair or one
-- trace of routine, and at least one object caught mid-task.
local STORIES = {
	{
		story = "Fruit just unloaded from the ship; one crate fell and split open",
		pieces = { "Crate", "Crate", "FruitCrateOpen", "Barrel", "Crate" },
	},
	{ story = "Fisher mending nets between throws", pieces = { "NetPile", "Barrel", "Stool", "RopeCoil", "Bucket" } },
	{
		story = "Powder barrels waiting to be loaded on the handcart",
		pieces = { "Handcart", "Barrel", "Barrel", "Barrel", "Crate" },
	},
	{ story = "Throwers' warm-up corner: fruit basket and chalk", pieces = { "Basket", "Crate", "Barrel", "Bucket" } },
	{
		story = "Lantern oil restock, one lantern down for repair",
		pieces = { "Crate", "LanternDown", "Barrel", "Crate", "RopeCoil" },
	},
}

local PIECE_SIZE: { [string]: Vec3 } = {
	Crate = v(3, 3, 3),
	FruitCrateOpen = v(3.2, 2, 3.2),
	Barrel = v(2.4, 3.2, 2.4),
	NetPile = v(4, 1.2, 3),
	Stool = v(1.4, 1.8, 1.4),
	RopeCoil = v(2.2, 0.8, 2.2),
	Bucket = v(1.2, 1.4, 1.2),
	Handcart = v(3.5, 3, 6),
	Basket = v(2, 1.4, 2),
	LanternDown = v(1, 1.6, 1),
}

-- Half-width along world X of a box of `size` turned `yaw` degrees about Y.
function DockLayout.halfWidthX(size: Vec3, yaw: number): number
	local r = math.rad(yaw)
	return (math.abs(math.cos(r)) * size.x + math.abs(math.sin(r)) * size.z) / 2
end

local function addPlacement(plan: Plan, p: Placement)
	table.insert(plan.placements, p)
end

-- Pier: deck, edge trim, pilings in rhythm (M34), ropes sagging between
-- piling tops (M40), lanterns leading to the throw edge (M41).
local function pier(plan: Plan, cfg: DockConfig, rng: Rng.Rng)
	local length = cfg.ShoreZ - cfg.ThrowEdgeZ
	local midZ = (cfg.ShoreZ + cfg.ThrowEdgeZ) / 2
	addPlacement(plan, {
		kind = "Deck",
		area = "Pier",
		tier = "Meso",
		pos = v(0, cfg.DeckHeight - 0.5, midZ),
		size = v(cfg.PierHalfWidth * 2, 1, length),
		yaw = 0,
		tilt = 0,
		why = "Walkable pier the player throws from",
	})
	for _, side in { -1, 1 } do
		addPlacement(plan, {
			kind = "EdgeTrim",
			area = "Pier",
			tier = "Micro",
			pos = v(side * (cfg.PierHalfWidth - 0.3), cfg.DeckHeight + 0.15, midZ),
			size = v(0.6, 0.5, length),
			yaw = 0,
			tilt = 0,
			why = "M35 trim on the deck edge so it is not a razor box",
		})
	end
	addPlacement(plan, {
		kind = "ThrowLine",
		area = "Pier",
		tier = "Gameplay",
		pos = v(0, cfg.DeckHeight + 0.05, cfg.ThrowEdgeZ + 1.5),
		size = v(cfg.PierHalfWidth * 2 - 2, 0.1, 0.8),
		yaw = 0,
		tilt = 0,
		why = "M37 painted line: where you stand to throw",
	})

	local pilingTop = cfg.DeckHeight + cfg.PilingAboveDeck
	local pilingBottom = cfg.SeabedY
	local index = 0
	for _, side in { -1, 1 } do
		local tops: { Vec3 } = {}
		index = 0
		local z = cfg.ThrowEdgeZ
		while z <= cfg.ShoreZ + 0.001 do
			index += 1
			local x = side * (cfg.PierHalfWidth + cfg.PilingDiameter / 2)
			local height = pilingTop - pilingBottom + rng:range(-0.4, 0.4)
			addPlacement(plan, {
				kind = "Piling",
				area = "Pier",
				tier = "Meso",
				pos = v(x, pilingBottom + height / 2, z),
				size = v(cfg.PilingDiameter, height, cfg.PilingDiameter),
				yaw = rng:range(0, 360),
				tilt = rng:range(-2, 2),
				why = "M34 rhythm: pilings at a fixed interval run to the vanishing point",
			})
			local top = v(x, pilingBottom + height - 0.4, z)
			table.insert(tops, top)
			if (index - 1) % cfg.LanternEvery == 0 then
				addPlacement(plan, {
					kind = "Lantern",
					area = "Pier",
					tier = "Lighting",
					pos = v(x, pilingBottom + height + 0.9, z),
					size = v(1, 1.8, 1),
					yaw = rng:range(0, 360),
					tilt = 0,
					why = "M41 warm emissive line leading to the throw edge (M16 light the path)",
				})
			end
			z += cfg.PilingSpacing
		end
		for i = 2, #tops do
			local a, b = tops[i - 1], tops[i]
			local span = math.abs(b.z - a.z)
			table.insert(plan.ropes, {
				kind = "Rope",
				area = "Pier",
				tier = "Micro",
				points = Catenary.points(a, b, Catenary.sagFor(span, cfg.RopeSlack), 8),
				thickness = 0.25,
				why = "M40 sagging rope between pilings breaks straight lines",
			})
		end
	end
end

-- Overhead layer (M36): bunting across the pier between pole pairs.
local function overhead(plan: Plan, cfg: DockConfig)
	local z = cfg.ThrowEdgeZ + cfg.BuntingEvery
	while z < cfg.ShoreZ - 4 do
		local tops: { Vec3 } = {}
		for _, side in { -1, 1 } do
			local x = side * (cfg.PierHalfWidth - 1.2)
			addPlacement(plan, {
				kind = "BuntingPole",
				area = "Pier",
				tier = "Meso",
				pos = v(x, cfg.DeckHeight + cfg.BuntingPoleHeight / 2, z),
				size = v(0.8, cfg.BuntingPoleHeight, 0.8),
				yaw = 0,
				tilt = 0,
				why = "M36 carries the overhead bunting",
			})
			table.insert(tops, v(x, cfg.DeckHeight + cfg.BuntingPoleHeight - 0.5, z))
		end
		table.insert(plan.ropes, {
			kind = "Bunting",
			area = "Pier",
			tier = "Micro",
			points = Catenary.points(tops[1], tops[2], Catenary.sagFor(cfg.PierHalfWidth * 2, 0.12), 12),
			thickness = 0.15,
			why = "M36 overhead layer in every shot; M40 sag",
		})
		z += cfg.BuntingEvery
	end
end

-- Props in story groups along the pier edges (M38, M10 Poisson + keep-clear).
local function storyGroups(plan: Plan, cfg: DockConfig, rng: Rng.Rng)
	local keep = cfg.LaneKeepClearHalfWidth
	local area = {
		minX = -cfg.PierHalfWidth + 2.5,
		maxX = cfg.PierHalfWidth - 2.5,
		minZ = cfg.ThrowEdgeZ + 14,
		maxZ = cfg.ShoreZ - 4,
	}
	local centres = PoissonDisc.sample(area, cfg.GroupSpacing, cfg.Seed + 7, {
		{ minX = -keep, maxX = keep, minZ = -math.huge, maxZ = math.huge },
	}, 10)
	for gi, c in centres do
		local recipe = STORIES[(gi - 1) % #STORIES + 1]
		local count = math.clamp(#recipe.pieces, cfg.GroupSize[1], cfg.GroupSize[2])
		local side = if c.x < 0 then -1 else 1
		local centre = v(c.x, cfg.DeckHeight, c.z)
		table.insert(plan.groups, { id = gi, story = recipe.story, centre = centre, count = count })
		local stackBase: Placement? = nil
		for pi = 1, count do
			local kind = recipe.pieces[(pi - 1) % #recipe.pieces + 1]
			local size = PIECE_SIZE[kind]
			local scale = rng:range(0.88, 1.15) -- M7 scale +-10-25%
			local sz = v(size.x * scale, size.y * scale, size.z * scale)
			-- pack toward the pier edge, never into the lane
			local angle = rng:range(0, 2 * math.pi)
			local r = rng:range(0.5, 3.2)
			local px = c.x + math.cos(angle) * r
			local pz = c.z + math.sin(angle) * r * 1.4
			local y = cfg.DeckHeight + sz.y / 2
			-- height variation (M38): stack one crate on the first crate
			if kind == "Crate" and stackBase and pi > 2 and rng:next() < 0.6 then
				local base = stackBase :: Placement
				px, pz = base.pos.x + rng:range(-0.3, 0.3), base.pos.z + rng:range(-0.3, 0.3)
				y = base.pos.y + base.size.y / 2 + sz.y / 2
				stackBase = nil
			end
			-- long pieces park along the pier; the rest get any yaw (M7)
			local yaw = if kind == "Handcart" or kind == "NetPile" then rng:range(-12, 12) else rng:range(0, 360)
			-- pack toward the pier edge, never into the lane: clamp by the
			-- rotated footprint's half-width along X
			local half = DockLayout.halfWidthX(sz, yaw)
			local inner = keep + half + 0.2
			local outer = cfg.PierHalfWidth - half - 0.3
			if side > 0 then
				px = math.clamp(px, inner, math.max(inner, outer))
			else
				px = math.clamp(px, -math.max(inner, outer), -inner)
			end
			local placement: Placement = {
				kind = kind,
				area = "Pier",
				tier = "Micro",
				pos = v(px, y, pz),
				size = sz,
				yaw = yaw,
				tilt = if kind == "LanternDown" then 90 else rng:range(-4, 4),
				why = recipe.story,
				group = gi,
			}
			addPlacement(plan, placement)
			if kind == "Crate" and stackBase == nil and pi <= 2 then
				stackBase = placement
			end
		end
	end
end

-- Hero accent (M33): moored ship with a saturated sail beside the pier.
local function ship(plan: Plan, cfg: DockConfig)
	local x = cfg.PierHalfWidth + 22
	local z = (cfg.ThrowEdgeZ + cfg.ShoreZ) / 2 + 6
	addPlacement(plan, {
		kind = "ShipHull",
		area = "Harbour",
		tier = "Macro",
		pos = v(x, cfg.WaterY + 3, z),
		size = v(16, 12, 64),
		yaw = 4,
		tilt = 0,
		why = "M33 hero accent; frames the right side of the throw view (M9)",
	})
	for i, h in { 46, 38 } do
		local mz = z + (if i == 1 then -10 else 16)
		addPlacement(plan, {
			kind = "Mast",
			area = "Harbour",
			tier = "Macro",
			pos = v(x, cfg.WaterY + 9 + h / 2, mz),
			size = v(1.4, h, 1.4),
			yaw = 0,
			tilt = 0,
			why = "Ship silhouette reads from far (M3 macro)",
		})
		addPlacement(plan, {
			kind = "Sail",
			area = "Harbour",
			tier = "Macro",
			pos = v(x, cfg.WaterY + 9 + h * 0.62, mz),
			size = v(22, h * 0.5, 0.4),
			yaw = 90,
			tilt = 0,
			why = "M33 the one saturated accent colour in the shot",
		})
		-- rigging from mast top down to the nearest pier piling tops (M36)
		table.insert(plan.ropes, {
			kind = "Rigging",
			area = "Harbour",
			tier = "Micro",
			points = Catenary.points(
				v(x, cfg.WaterY + 9 + h - 1, mz),
				v(cfg.PierHalfWidth + 1, cfg.DeckHeight + cfg.PilingAboveDeck, mz + 6),
				2,
				10
			),
			thickness = 0.2,
			why = "M36 rigging overhead from ship to pier",
		})
	end
	table.insert(plan.ropes, {
		kind = "Rope",
		area = "Harbour",
		tier = "Micro",
		points = Catenary.points(
			v(x - 7, cfg.WaterY + 7, z - 24),
			v(cfg.PierHalfWidth + 1, cfg.DeckHeight + 1, z - 26),
			1.2,
			8
		),
		thickness = 0.35,
		why = "Mooring line: says the ship is tied up here (M11)",
	})
end

-- Lane: open water with buoys + distance boards (M37) and sea stacks that
-- frame the lane (M9), landmark at least every ~50 studs.
local function lane(plan: Plan, cfg: DockConfig, rng: Rng.Rng)
	local d = cfg.BuoyEvery
	while d <= cfg.LaneLength do
		local z = cfg.ThrowEdgeZ - d
		for _, side in { -1, 1 } do
			addPlacement(plan, {
				kind = "Buoy",
				area = "Lane",
				tier = "Gameplay",
				pos = v(side * 18, cfg.WaterY + 1.5, z),
				size = v(3, 4, 3),
				yaw = rng:range(0, 360),
				tilt = rng:range(-6, 6),
				why = "Reads distance in the world, not only as text (rulebook 4)",
			})
		end
		addPlacement(plan, {
			kind = "DistanceBoard",
			area = "Lane",
			tier = "Gameplay",
			pos = v(-18, cfg.WaterY + 6, z),
			size = v(8, 4, 0.4),
			yaw = 0,
			tilt = 0,
			why = tostring(d), -- the board's label; DockBuilder writes it on the board
		})
		d += cfg.BuoyEvery
	end
	local s = cfg.SeaStackEvery
	local side = 1
	while s < cfg.LaneLength - 40 do
		local h = rng:range(36, 70)
		local w = rng:range(18, 30)
		addPlacement(plan, {
			kind = "SeaStack",
			area = "Lane",
			tier = "Macro",
			pos = v(side * rng:range(70, 110), cfg.WaterY + h / 2 - 6, cfg.ThrowEdgeZ - s),
			size = v(w, h, w * rng:range(0.8, 1.2)),
			yaw = rng:range(0, 360),
			tilt = rng:range(-6, 6),
			why = "M9 frames the lane and marks distance from far (M3 macro)",
		})
		side = -side
		s += cfg.SeaStackEvery
	end
end

-- Weenie (M8) at the lane end: lighthouse on a rock island.
local function laneEnd(plan: Plan, cfg: DockConfig)
	local z = cfg.ThrowEdgeZ - cfg.LaneLength - 80
	table.insert(plan.terrain, {
		material = "Rock",
		shape = "Cylinder",
		pos = v(0, cfg.WaterY + 4, z),
		size = v(110, 40, 110),
		yaw = 0,
		why = "Island the lighthouse stands on",
	})
	local base = cfg.WaterY + 24
	addPlacement(plan, {
		kind = "Lighthouse",
		area = "LaneEnd",
		tier = "Macro",
		pos = v(0, base + cfg.LighthouseHeight / 2, z),
		size = v(16, cfg.LighthouseHeight, 16),
		yaw = 0,
		tilt = 0,
		why = "M8 weenie: tallest, brightest, moving light at the end of the lane",
	})
	addPlacement(plan, {
		kind = "LighthouseLamp",
		area = "LaneEnd",
		tier = "Lighting",
		pos = v(0, base + cfg.LighthouseHeight + 4, z),
		size = v(8, 8, 8),
		yaw = 0,
		tilt = 0,
		why = "M17 glow for focus: Neon + Bloom on the landmark only",
	})
end

-- Harbour cove (M44): terraced cliff bowl around the harbour, open toward the lane.
local function cove(plan: Plan, cfg: DockConfig, rng: Rng.Rng)
	local centre = v(0, 0, cfg.ShoreZ - 40)
	-- arc from -25 deg to 205 deg, where 90 deg points +Z (behind the player);
	-- the gap (205..335) faces -Z, the lane.
	for t = 1, cfg.CoveTerraces do
		local radius = cfg.CoveRadius + (t - 1) * 26
		local top = cfg.WaterY + t * cfg.TerraceStep
		local a = -25
		while a <= 205 do
			local rad = math.rad(a)
			local x = centre.x + math.cos(rad) * radius
			local z = centre.z + math.sin(rad) * radius
			local h = top - cfg.SeabedY + rng:range(-4, 6)
			table.insert(plan.terrain, {
				material = if t == 1 then "Rock" else "Slate",
				shape = "Block",
				pos = v(x, cfg.SeabedY + h / 2, z),
				size = v(radius * math.rad(14) * 1.3, h, 30),
				yaw = -a + 90,
				why = "M44 terraced bowl encloses the harbour (M13 boundary scenery)",
			})
			a += 12
		end
	end
	-- beach at the back of the cove: the pier starts on it and it runs up to
	-- the first terrace (M37 material band between deck, water and rock)
	table.insert(plan.terrain, {
		material = "Sand",
		shape = "Cylinder",
		pos = v(0, cfg.WaterY - 2, cfg.ShoreZ + 70),
		size = v(160, 8, 160),
		yaw = 0,
		why = "M37 sand beach where the pier meets the shore",
	})
	-- huts cluster on the first ledge (M44), not spread evenly
	for i = 1, 4 do
		local a = math.rad(70 + i * 9 + rng:range(-3, 3))
		local r = cfg.CoveRadius + 8
		addPlacement(plan, {
			kind = "Hut",
			area = "Harbour",
			tier = "Meso",
			pos = v(math.cos(a) * r, cfg.WaterY + cfg.TerraceStep + 5, centre.z + math.sin(a) * r),
			size = v(rng:range(10, 14), 10, rng:range(9, 12)),
			yaw = -math.deg(a) + 90 + rng:range(-8, 8),
			tilt = 0,
			why = "M44 buildings cluster on a ledge; a village lives here (M11)",
		})
	end
end

-- Sea: basin first, then water (M21), as overlapping cylinders (no square edges).
local function sea(plan: Plan, cfg: DockConfig)
	local depth = cfg.WaterY - cfg.SeabedY
	local z = cfg.ShoreZ
	local last = cfg.ThrowEdgeZ - cfg.LaneLength - 200
	while z > last do
		table.insert(plan.terrain, {
			material = "Sand",
			shape = "Cylinder",
			pos = v(0, cfg.SeabedY - 4, z),
			size = v(520, 8, 520),
			yaw = 0,
			why = "M21 sea bed under the water",
		})
		table.insert(plan.terrain, {
			material = "Water",
			shape = "Cylinder",
			pos = v(0, cfg.SeabedY + depth / 2, z),
			size = v(560, depth, 560),
			yaw = 0,
			why = "M21 water as overlapping lobes, no square sea edge",
		})
		z -= 200
	end
end

function DockLayout.plan(cfg: DockConfig): Plan
	local rng = Rng.new(cfg.Seed)
	local plan: Plan = {
		placements = {},
		ropes = {},
		terrain = {},
		groups = {},
		throwOrigin = v(0, cfg.DeckHeight + 3, cfg.ThrowEdgeZ),
	}
	sea(plan, cfg) -- basin + water first so later rock/sand ops win
	cove(plan, cfg, rng)
	pier(plan, cfg, rng)
	overhead(plan, cfg)
	storyGroups(plan, cfg, rng)
	ship(plan, cfg)
	lane(plan, cfg, rng)
	laneEnd(plan, cfg)
	return plan
end

DockLayout.STORIES = STORIES

return table.freeze(DockLayout)
