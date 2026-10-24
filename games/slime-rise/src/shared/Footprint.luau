--!strict
-- Room shapes for the maps (pure numbers, x/z plane, centred on the map
-- origin). The rest of the game still places things by angle and radius as if
-- the room were the round reference shaft (radius REF); polar() warps that
-- onto this shape: things near the wall follow this room's wall at the same
-- inset, things near the middle stay where they are. Walls are built per
-- polygon edge so panels sit flat on straight walls.
-- Angles in degrees: angle 0 is +X, 90 is +Z.

local Footprint = {}

Footprint.REF = 36 -- reference shaft radius every layout is authored against

export type Def = {
	shape: string, -- "circle" | "rect" | "hex" | "cross"
	radius: number?, -- circle, hex (centre to corner)
	width: number?, -- rect (along X)
	depth: number?, -- rect (along Z)
	round: number?, -- rect corner radius
	arm: number?, -- cross: half-width of each arm
	extent: number?, -- cross: centre to the end of each arm
}

export type Segment = { x: number, z: number, nx: number, nz: number, width: number }

export type Footprint = {
	shape: string,
	verts: { { number } },
	boundary: { number }, -- distance to the wall every 0.5 degrees
	normals: { { number } }, -- inward wall normal every 0.5 degrees
	minX: number,
	maxX: number,
	minZ: number,
	maxZ: number,
}

local STEPS = 720

-- 24 flat walls like the original shaft; corners pushed out so each wall's
-- middle sits exactly at the radius.
local function circleVerts(r: number): { { number } }
	local out = {}
	local corner = r / math.cos(math.rad(7.5))
	for i = 0, 23 do
		local a = math.rad(i * 15 - 7.5)
		table.insert(out, { math.cos(a) * corner, math.sin(a) * corner })
	end
	return out
end

local function rectVerts(w: number, d: number, round: number): { { number } }
	local hx, hz = w / 2, d / 2
	local r = math.clamp(round, 0, math.min(hx, hz) - 0.1)
	local out = {}
	local corners =
		{ { hx - r, hz - r, 0 }, { -hx + r, hz - r, 90 }, { -hx + r, -hz + r, 180 }, { hx - r, -hz + r, 270 } }
	for _, c in corners do
		for k = 0, 6 do
			local a = math.rad(c[3] + k * 15)
			table.insert(out, { c[1] + math.cos(a) * r, c[2] + math.sin(a) * r })
		end
	end
	return out
end

local function hexVerts(r: number): { { number } }
	local out = {}
	for i = 0, 5 do
		-- Small chamfer at each corner so no wall meets at a knife edge.
		for _, off in { -4, 4 } do
			local a = math.rad(i * 60 + 30 + off)
			local rr = r * (1 - 0.035)
			table.insert(out, { math.cos(a) * rr, math.sin(a) * rr })
		end
	end
	return out
end

local function crossVerts(arm: number, extent: number): { { number } }
	-- Plus shape, counter-clockwise starting on the +X arm.
	local a, e = arm, extent
	return {
		{ e, -a },
		{ e, a },
		{ a, a },
		{ a, e },
		{ -a, e },
		{ -a, a },
		{ -e, a },
		{ -e, -a },
		{ -a, -a },
		{ -a, -e },
		{ a, -e },
		{ a, -a },
	}
end

-- Ray from the centre at angle `deg` against every edge: distance and edge.
local function cast(verts: { { number } }, deg: number): (number, number, number)
	local dx, dz = math.cos(math.rad(deg)), math.sin(math.rad(deg))
	local best, bnx, bnz = math.huge, -dx, -dz
	local n = #verts
	for i = 1, n do
		local p, q = verts[i], verts[i % n + 1]
		local ex, ez = q[1] - p[1], q[2] - p[2]
		local denom = dx * ez - dz * ex
		if math.abs(denom) > 1e-9 then
			local t = (p[1] * ez - p[2] * ex) / denom
			local s = (p[1] * dz - p[2] * dx) / denom
			if t > 0 and s >= -1e-6 and s <= 1 + 1e-6 and t < best then
				best = t
				local len = math.sqrt(ex * ex + ez * ez)
				-- Counter-clockwise polygon: inward normal is the edge turned left.
				bnx, bnz = -ez / len, ex / len
			end
		end
	end
	return best, bnx, bnz
end

function Footprint.new(def: Def): Footprint
	local verts: { { number } }
	if def.shape == "rect" then
		verts = rectVerts(def.width or 72, def.depth or 72, def.round or 0)
	elseif def.shape == "hex" then
		verts = hexVerts(def.radius or 40)
	elseif def.shape == "cross" then
		verts = crossVerts(def.arm or 14, def.extent or 40)
	else
		verts = circleVerts(def.radius or Footprint.REF)
	end
	local boundary, normals = {}, {}
	for i = 0, STEPS do
		local d, nx, nz = cast(verts, i * 360 / STEPS)
		boundary[i + 1] = d
		normals[i + 1] = { nx, nz }
	end
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, v in verts do
		minX, maxX = math.min(minX, v[1]), math.max(maxX, v[1])
		minZ, maxZ = math.min(minZ, v[2]), math.max(maxZ, v[2])
	end
	return {
		shape = def.shape,
		verts = verts,
		boundary = boundary,
		normals = normals,
		minX = minX,
		maxX = maxX,
		minZ = minZ,
		maxZ = maxZ,
	}
end

-- Distance from the centre to the wall at an angle.
function Footprint.wall(fp: Footprint, angle: number): number
	local f = (angle % 360) / 360 * STEPS
	local i = math.floor(f)
	local t = f - i
	return fp.boundary[i + 1] * (1 - t) + fp.boundary[math.min(i + 2, STEPS + 1)] * t
end

-- Inward wall normal (x, z) for things mounted on the wall at an angle.
function Footprint.inward(fp: Footprint, angle: number): (number, number)
	local i = math.floor((angle % 360) / 360 * STEPS + 0.5)
	local n = fp.normals[i + 1]
	return n[1], n[2]
end

-- How much an authored radius follows this room's wall (0 = stays put, 1 =
-- keeps its inset from the wall).
function Footprint.weight(t: number): number
	local u = math.clamp((t - 0.25) / 0.35, 0, 1)
	return u * u * (3 - 2 * u)
end

-- Where an (angle, radius) authored for the reference shaft lands in this room.
function Footprint.polar(fp: Footprint, angle: number, radius: number): (number, number)
	local shift = (Footprint.wall(fp, angle) - Footprint.REF) * Footprint.weight(radius / Footprint.REF)
	local r = math.rad(angle)
	return math.cos(r) * (radius + shift), math.sin(r) * (radius + shift)
end

-- Wall panels: each polygon edge cut into pieces no wider than maxWidth.
function Footprint.segments(fp: Footprint, maxWidth: number): { Segment }
	local out: { Segment } = {}
	local verts = fp.verts
	local n = #verts
	for i = 1, n do
		local p, q = verts[i], verts[i % n + 1]
		local ex, ez = q[1] - p[1], q[2] - p[2]
		local len = math.sqrt(ex * ex + ez * ez)
		if len > 0.05 then
			local pieces = math.max(1, math.ceil(len / maxWidth))
			for k = 0, pieces - 1 do
				local f = (k + 0.5) / pieces
				table.insert(out, {
					x = p[1] + ex * f,
					z = p[2] + ez * f,
					nx = -ez / len,
					nz = ex / len,
					width = len / pieces,
				})
			end
		end
	end
	return out
end

-- True when (x, z) is inside the room with at least `margin` studs to any wall.
function Footprint.contains(fp: Footprint, x: number, z: number, margin: number?): boolean
	local verts = fp.verts
	local n = #verts
	local inside = false
	local m = margin or 0
	for i = 1, n do
		local p, q = verts[i], verts[i % n + 1]
		if (p[2] > z) ~= (q[2] > z) then
			local xi = p[1] + (z - p[2]) / (q[2] - p[2]) * (q[1] - p[1])
			if x < xi then
				inside = not inside
			end
		end
		if m > 0 then
			local ex, ez = q[1] - p[1], q[2] - p[2]
			local len2 = ex * ex + ez * ez
			local t = if len2 > 0 then math.clamp(((x - p[1]) * ex + (z - p[2]) * ez) / len2, 0, 1) else 0
			local cx, cz = p[1] + ex * t, p[2] + ez * t
			if (x - cx) ^ 2 + (z - cz) ^ 2 < m * m then
				return false
			end
		end
	end
	return inside
end

return Footprint
