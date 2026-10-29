--!strict
-- Cleaning maths. The server samples each player's tool every tick and sweeps the strip between
-- the last and the current position; every sample point scrubs the patch it lands in.
-- Pure module.

local Config = require(script.Parent.Config)

local Sweep = {}

local R = Config.Moon.Radius
-- Average patch area: the sphere's area shared between every patch.
local PATCHES = 10 * Config.Grid.PatchFrequency ^ 2 + 2
Sweep.PATCH_AREA = 4 * math.pi * R * R / PATCHES
Sweep.PATCH_KG = Sweep.PATCH_AREA * Config.Dust.KgPerStud2
Sweep.FULL = 255 -- a dusty patch, as stored in the dust buffer

export type Sample = { point: Vector3, area: number }

-- Points spread over the strip a tool of `width` swept from p0 to p1. `up` is the local up.
-- Standing still sweeps nothing: brushing is done by moving.
function Sweep.samples(p0: Vector3, p1: Vector3, up: Vector3, width: number, step: number?): { Sample }
	local s = step or Config.Dust.SampleStep
	local d = p1 - p0
	d -= up * d:Dot(up)
	local len = d.Magnitude
	if len < 0.05 or width <= 0 then
		return {}
	end
	local dir = d / len
	local side = dir:Cross(up).Unit
	local nAlong = math.max(1, math.ceil(len / s))
	local nAcross = math.max(1, math.ceil(width / s))
	local area = len * width / (nAlong * nAcross)
	local out = table.create(nAlong * nAcross)
	for a = 1, nAlong do
		local along = p0 + dir * (len * (a - 0.5) / nAlong)
		for b = 1, nAcross do
			local off = width * ((b - 0.5) / nAcross - 0.5)
			table.insert(out, { point = along + side * off, area = area })
		end
	end
	return out
end

-- Scrub one patch. `dust` is its stored level (0..FULL). Returns the new level and the share of a
-- full patch removed (multiply by PATCH_KG for kg). A patch that drops under CleanBelow is
-- finished off so it counts as clean.
function Sweep.scrub(dust: number, area: number, cleanFactor: number): (number, number)
	if dust <= 0 then
		return 0, 0
	end
	local take = math.max(1, math.floor(area / Sweep.PATCH_AREA * cleanFactor * Sweep.FULL + 0.5))
	local left = math.max(0, dust - take)
	if left <= Config.Dust.CleanBelow * Sweep.FULL then
		left = 0
	end
	return left, (dust - left) / Sweep.FULL
end

-- Too fast to be brushing (teleport, fling, exploit): ignore the segment.
function Sweep.plausible(distance: number, dt: number, maxSpeed: number): boolean
	if dt <= 0 then
		return false
	end
	return distance / dt <= maxSpeed * Config.Dust.MaxSpeedSlack + 2
end

-- Ground steep enough to hold Stardust (only brooms reach it).
function Sweep.isSteep(up: Vector3, normal: Vector3): boolean
	return 1 - up:Dot(normal) >= Config.Dust.StardustSlope
end

-- Degrees between a direction and the North Station.
function Sweep.angleFromNorth(dir: Vector3): number
	return math.deg(math.acos(math.clamp(dir.Y, -1, 1)))
end

return table.freeze(Sweep)
