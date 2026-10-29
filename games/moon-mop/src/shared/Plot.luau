--!strict
-- Mop Base plot rules: where a building may go on a plot, footprints, overlap, belt runs, prices
-- and the curve of the Moon under a flat plot. Pure: no services, so both sides and the specs
-- use the same answers. Plot coordinates are studs on the plot's tangent plane: x right, z back
-- (toward -LookVector), origin at the plot centre. Rotation r is 0..3 quarter turns.

local Config = require(script.Parent.Config)
local Economy = require(script.Parent.Economy)

local Plot = {}

export type Building = { uid: number, id: string, x: number, z: number, r: number, paid: number, t: number }

local defs: { [string]: Config.BuildDef } = {}
for _, b in Config.Buildings do
	defs[b.id] = b
end

local A = Config.Automation
local HALF = A.PlotSize / 2
Plot.HALF = HALF
Plot.TILE = 4 -- belt tile size

function Plot.def(id: string): Config.BuildDef?
	return defs[id]
end

-- Footprint (x, z extent) after rotation.
function Plot.footprint(def: Config.BuildDef, r: number): (number, number)
	if r % 2 == 1 then
		return def.size.Z, def.size.X
	end
	return def.size.X, def.size.Z
end

-- Snap a plot position to the build grid.
function Plot.snap(v: number): number
	return math.floor(v / A.GridStep + 0.5) * A.GridStep
end

-- Direction a belt (or machine output) faces, as a plot-space unit step. r = 0 faces -z (away
-- from the plot's back edge), then clockwise seen from above.
local DIRS = { { 0, -1 }, { 1, 0 }, { 0, 1 }, { -1, 0 } }
function Plot.facing(r: number): (number, number)
	local d = DIRS[(r % 4) + 1]
	return d[1], d[2]
end

local function overlaps(
	ax: number,
	az: number,
	aw: number,
	ad: number,
	bx: number,
	bz: number,
	bw: number,
	bd: number
): boolean
	return math.abs(ax - bx) * 2 < aw + bw - 1e-6 and math.abs(az - bz) * 2 < ad + bd - 1e-6
end
Plot.overlaps = overlaps

-- Can this building go here? Returns ok and a reason the player can read.
function Plot.canPlace(existing: { Building }, id: string, x: number, z: number, r: number): (boolean, string?)
	local def = defs[id]
	if not def then
		return false, "Unknown building"
	end
	if r ~= math.floor(r) or r < 0 or r > 3 then
		return false, "Bad rotation"
	end
	if #existing >= A.MaxBuildings then
		return false, string.format("Plots hold %d buildings", A.MaxBuildings)
	end
	local w, d = Plot.footprint(def, r)
	if math.abs(x) + w / 2 > HALF + 1e-6 or math.abs(z) + d / 2 > HALF + 1e-6 then
		return false, "Keep it inside your plot"
	end
	local count = 0
	for _, b in existing do
		local other = defs[b.id]
		if other then
			local ow, od = Plot.footprint(other, b.r)
			if overlaps(x, z, w, d, b.x, b.z, ow, od) then
				return false, "Something is in the way"
			end
		end
		if b.id == id then
			count += 1
		end
	end
	if id == "Garage" and count >= 1 then
		return false, "One Garage per plot"
	end
	if id == "PodCatcher" and count >= 1 then
		return false, "One Pod Catcher per plot"
	end
	return true, nil
end

-- Price of a building given what the plot already has (Cosmic Octos get dearer).
function Plot.price(existing: { Building }, id: string, fx: { [string]: number }?): number
	local def = defs[id]
	if not def then
		return math.huge
	end
	if id == "CosmicOcto" then
		local owned = 0
		for _, b in existing do
			if b.id == id then
				owned += 1
			end
		end
		return Economy.price(Economy.octoPrice(owned), fx)
	end
	if id == "Belt" then
		return Economy.price(Economy.beltPrice(Plot.TILE), fx)
	end
	return Economy.price(def.price, fx)
end

-- The tiles of a straight belt run from (x0, z0) to (x1, z1), snapped to whole tiles along the
-- longer axis. Each tile faces along the run.
export type Tile = { x: number, z: number, r: number }
function Plot.beltRun(x0: number, z0: number, x1: number, z1: number): { Tile }
	local dx, dz = x1 - x0, z1 - z0
	local out: { Tile } = {}
	local alongX = math.abs(dx) >= math.abs(dz)
	local length = if alongX then math.abs(dx) else math.abs(dz)
	local n = math.clamp(math.floor(length / Plot.TILE + 0.5) + 1, 1, A.BeltMaxRun)
	local r
	if alongX then
		r = if dx >= 0 then 1 else 3
	else
		r = if dz >= 0 then 2 else 0
	end
	local sx, sz = Plot.facing(r)
	for k = 0, n - 1 do
		table.insert(out, { x = x0 + sx * Plot.TILE * k, z = z0 + sz * Plot.TILE * k, r = r })
	end
	return out
end

-- How far the Moon's surface drops below a flat plot at plot position (x, z).
function Plot.drop(x: number, z: number): number
	local R = Config.Moon.Radius
	local d2 = x * x + z * z
	return R - math.sqrt(math.max(0, R * R - d2))
end

-- Refund for removing a building placed `age` seconds ago.
function Plot.refund(b: Building, age: number): number
	return Economy.refund(b.paid, age)
end

return table.freeze(Plot)
