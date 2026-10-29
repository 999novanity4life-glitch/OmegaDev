--!strict
--!native
-- The Moon's hex grid: a geodesic (icosahedral Goldberg) grid over the whole sphere, the same
-- shape as the honeycomb on the original's Moon Map. Pure module: no game or service access.
--
-- How it works. An icosahedron with one corner at +Y (the North Station) is split into 20
-- triangles. Each triangle is cut into an n-by-n triangular lattice; every lattice point, pushed
-- out to the sphere, is the centre of one cell. Cells are hexagons, except the 12 icosahedron
-- corners, which are pentagons (the stations stand on them). A grid of frequency n has
-- 10 * n^2 + 2 cells.
--
-- Two grids nest when one frequency divides the other: every lattice point of the coarse grid is
-- also a point of the fine grid. Moon Mop uses three levels (Config.Grid):
--   patches  (fine)   the small cells that get cleaned one by one
--   sectors  (hexes)  what the HUD ring, the reward and the Moon Map count
--   regions           groups of sectors with their own completion bonus
-- `parentOf` says which coarse cell a fine cell belongs to (its nearest coarse lattice point,
-- ties to the lower id), using exact integer maths so the server and every client agree.
--
-- Cell ids are 0-based integers: 12 corners, then the points on the 30 edges, then the points
-- inside the 20 faces. Positions are unit vectors from the Moon's centre.

export type Grid = {
	n: number,
	count: number,
	locate: (self: Grid, dir: Vector3) -> number,
	locateFace: (self: Grid, dir: Vector3) -> (number, number, number),
	decode: (self: Grid, id: number) -> (number, number, number),
	idAt: (self: Grid, face: number, i: number, j: number) -> number,
	position: (self: Grid, id: number) -> Vector3,
	tangent: (self: Grid, id: number) -> Vector3,
	neighbours: (self: Grid, id: number) -> { number },
	forEach: (self: Grid, fn: (id: number, face: number, i: number, j: number) -> ()) -> (),
}

type Face = {
	a: number,
	b: number,
	c: number,
	A: Vector3,
	e1: Vector3,
	e2: Vector3,
	normal: Vector3,
	planeD: number,
	d00: number,
	d01: number,
	d11: number,
	invDen: number,
}

local MoonGrid = {}

-- Icosahedron with corner 1 at +Y and corner 12 at -Y. The upper ring sits at latitude
-- atan(1/2), longitudes 0, 72, ...; the lower ring is turned 36 degrees.
local CORNERS: { Vector3 } = {}
do
	local lat = math.atan(0.5)
	table.insert(CORNERS, Vector3.new(0, 1, 0))
	for k = 0, 4 do
		local lon = math.rad(72 * k)
		table.insert(CORNERS, Vector3.new(math.cos(lat) * math.cos(lon), math.sin(lat), math.cos(lat) * math.sin(lon)))
	end
	for k = 0, 4 do
		local lon = math.rad(36 + 72 * k)
		table.insert(CORNERS, Vector3.new(math.cos(lat) * math.cos(lon), -math.sin(lat), math.cos(lat) * math.sin(lon)))
	end
	table.insert(CORNERS, Vector3.new(0, -1, 0))
end
MoonGrid.CORNERS = CORNERS

-- Faces as corner triples. U(k) is upper-ring corner k, L(k) lower-ring corner k.
local FACE_CORNERS: { { number } } = {}
do
	local function U(k: number): number
		return 2 + (k % 5)
	end
	local function L(k: number): number
		return 7 + (k % 5)
	end
	for k = 0, 4 do
		table.insert(FACE_CORNERS, { 1, U(k), U(k + 1) })
		table.insert(FACE_CORNERS, { U(k), L(k), U(k + 1) })
		table.insert(FACE_CORNERS, { U(k + 1), L(k), L(k + 1) })
		table.insert(FACE_CORNERS, { 12, L(k + 1), L(k) })
	end
end

local FACES: { Face } = {}
for _, fc in FACE_CORNERS do
	local A, B, C = CORNERS[fc[1]], CORNERS[fc[2]], CORNERS[fc[3]]
	local e1, e2 = B - A, C - A
	local normal = (A + B + C).Unit
	local d00, d01, d11 = e1:Dot(e1), e1:Dot(e2), e2:Dot(e2)
	table.insert(FACES, {
		a = fc[1],
		b = fc[2],
		c = fc[3],
		A = A,
		e1 = e1,
		e2 = e2,
		normal = normal,
		planeD = A:Dot(normal),
		d00 = d00,
		d01 = d01,
		d11 = d11,
		invDen = 1 / (d00 * d11 - d01 * d01),
	})
end

-- The 30 edges, each with one face that "owns" it for decoding and iteration.
local EDGE_INDEX: { [number]: number } = {} -- lo * 16 + hi -> 0-based edge index
local EDGE_FACE: { { number } } = {} -- [edge + 1] = { face, lo, hi }, the owning face
local EDGE_OTHER: { number } = {} -- [edge + 1] = the second face on the edge
local CORNER_FACE: { { number } } = {} -- [corner] = { face, role }, the owning face
local CORNER_FACES: { { { number } } } = {} -- [corner] = every { face, role } round it
for f, face in FACES do
	local trio = { face.a, face.b, face.c }
	for x = 1, 3 do
		local y = x % 3 + 1
		local lo, hi = math.min(trio[x], trio[y]), math.max(trio[x], trio[y])
		local key = lo * 16 + hi
		if EDGE_INDEX[key] == nil then
			EDGE_INDEX[key] = #EDGE_FACE
			table.insert(EDGE_FACE, { f, lo, hi })
		else
			EDGE_OTHER[EDGE_INDEX[key] + 1] = f
		end
	end
	for role, corner in trio do
		if CORNER_FACE[corner] == nil then
			CORNER_FACE[corner] = { f, role }
			CORNER_FACES[corner] = {}
		end
		table.insert(CORNER_FACES[corner], { f, role })
	end
end
assert(#EDGE_FACE == 30, "icosahedron should have 30 edges")

MoonGrid.FACE_COUNT = #FACES

-- Lattice coordinates of a face's corner roles: A = (0, 0), B = (n, 0), C = (0, n).
local function roleCoords(role: number, n: number): (number, number)
	if role == 1 then
		return 0, 0
	elseif role == 2 then
		return n, 0
	end
	return 0, n
end

local function roleOf(face: Face, corner: number): number
	return if corner == face.a then 1 elseif corner == face.b then 2 else 3
end

-- Squared distance in a 60-degree lattice, in lattice units.
local function dist2(dx: number, dy: number): number
	return dx * dx + dy * dy + dx * dy
end

function MoonGrid.new(n: number): Grid
	assert(n >= 2 and n % 1 == 0, "frequency must be a whole number of at least 2")
	local edgeBase = 12
	local faceBase = 12 + 30 * (n - 1)
	local perFace = (n - 1) * (n - 2) // 2
	local count = 10 * n * n + 2
	local posCache: { [number]: Vector3 } = {}

	local grid = {} :: Grid
	grid.n = n
	grid.count = count

	local function rowOffset(i: number): number
		return (i - 1) * (n - 1) - ((i - 1) * i) // 2
	end

	local function edgeId(x: number, y: number, t: number): number
		local lo, hi = math.min(x, y), math.max(x, y)
		local e = EDGE_INDEX[lo * 16 + hi]
		local tt = if x == lo then t else n - t
		return edgeBase + e * (n - 1) + (tt - 1)
	end

	function grid.idAt(_self: Grid, f: number, i: number, j: number): number
		local face = FACES[f]
		if i == 0 and j == 0 then
			return face.a - 1
		elseif i == n then
			return face.b - 1
		elseif j == n then
			return face.c - 1
		elseif j == 0 then
			return edgeId(face.a, face.b, i)
		elseif i == 0 then
			return edgeId(face.a, face.c, j)
		elseif i + j == n then
			return edgeId(face.b, face.c, j)
		end
		return faceBase + (f - 1) * perFace + rowOffset(i) + (j - 1)
	end

	function grid.decode(_self: Grid, id: number): (number, number, number)
		if id < 12 then
			local cf = CORNER_FACE[id + 1]
			local i, j = roleCoords(cf[2], n)
			return cf[1], i, j
		elseif id < faceBase then
			local k = id - edgeBase
			local e = k // (n - 1)
			local tt = k % (n - 1) + 1
			local ef = EDGE_FACE[e + 1]
			local face = FACES[ef[1]]
			local iLo, jLo = roleCoords(roleOf(face, ef[2]), n)
			local iHi, jHi = roleCoords(roleOf(face, ef[3]), n)
			return ef[1], (iLo * (n - tt) + iHi * tt) // n, (jLo * (n - tt) + jHi * tt) // n
		end
		local k = id - faceBase
		local f = k // perFace + 1
		local r = k % perFace
		local b = 2 * n - 3
		local x = math.floor((b - math.sqrt(math.max(0, b * b - 8 * r))) / 2)
		local i = x + 1
		while i > 1 and rowOffset(i) > r do
			i -= 1
		end
		while rowOffset(i + 1) <= r and i < n - 2 do
			i += 1
		end
		return f, i, r - rowOffset(i) + 1
	end

	local function planar(f: number, i: number, j: number): Vector3
		local face = FACES[f]
		return face.A + face.e1 * (i / n) + face.e2 * (j / n)
	end

	function grid.position(self: Grid, id: number): Vector3
		local cached = posCache[id]
		if cached then
			return cached
		end
		local f, i, j = self:decode(id)
		local p = planar(f, i, j).Unit
		if n <= 160 then
			posCache[id] = p
		end
		return p
	end

	-- A tangent direction at the cell that runs along its face's first lattice axis. A hex tile
	-- turned so its flat side faces this way lines up with its neighbours.
	function grid.tangent(self: Grid, id: number): Vector3
		local f = self:decode(id)
		local up = self:position(id)
		local e1 = FACES[f].e1
		return (e1 - up * e1:Dot(up)).Unit
	end

	-- Fractional lattice coordinates of a direction in its face.
	local function project(dir: Vector3): (number, number, number)
		local best, bestDot = 1, -math.huge
		for f, face in FACES do
			local d = dir:Dot(face.normal)
			if d > bestDot then
				best, bestDot = f, d
			end
		end
		local face = FACES[best]
		local q = dir * (face.planeD / bestDot)
		local w = q - face.A
		local d20, d21 = w:Dot(face.e1), w:Dot(face.e2)
		local u = (face.d11 * d20 - face.d01 * d21) * face.invDen
		local v = (face.d00 * d21 - face.d01 * d20) * face.invDen
		return best, u * n, v * n
	end

	function grid.locateFace(_self: Grid, dir: Vector3): (number, number, number)
		local f, x, y = project(dir)
		local a, b = math.floor(x), math.floor(y)
		local r, s = x - a, y - b
		local bi, bj, bd = -1, -1, math.huge
		local function try(ci: number, cj: number)
			if ci >= 0 and cj >= 0 and ci + cj <= n then
				local d = dist2(x - ci, y - cj)
				if d < bd then
					bi, bj, bd = ci, cj, d
				end
			end
		end
		if r + s < 1 then
			try(a, b)
			try(a + 1, b)
			try(a, b + 1)
		else
			try(a + 1, b)
			try(a, b + 1)
			try(a + 1, b + 1)
		end
		if bi < 0 then
			-- only reachable through rounding right on the face border
			bi = math.clamp(math.round(x), 0, n)
			bj = math.clamp(math.round(y), 0, n - bi)
		end
		return f, bi, bj
	end

	function grid.locate(self: Grid, dir: Vector3): number
		local f, i, j = self:locateFace(dir)
		return self:idAt(f, i, j)
	end

	local OFFSETS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, -1 }, { -1, 1 } }

	-- Every (face, i, j) that names this cell: one for inner points, two on an edge, five at a
	-- corner. Neighbours are the in-face lattice steps from each of them.
	local function names(self: Grid, id: number): { { number } }
		local f, i, j = self:decode(id)
		local out = { { f, i, j } }
		if id < 12 then
			for _, fr in CORNER_FACES[id + 1] do
				if fr[1] ~= f then
					local ci, cj = roleCoords(fr[2], n)
					table.insert(out, { fr[1], ci, cj })
				end
			end
		elseif id < faceBase then
			local e = (id - edgeBase) // (n - 1)
			local tt = (id - edgeBase) % (n - 1) + 1
			local ef = EDGE_FACE[e + 1]
			local g = EDGE_OTHER[e + 1]
			local face = FACES[g]
			local iLo, jLo = roleCoords(roleOf(face, ef[2]), n)
			local iHi, jHi = roleCoords(roleOf(face, ef[3]), n)
			table.insert(out, { g, (iLo * (n - tt) + iHi * tt) // n, (jLo * (n - tt) + jHi * tt) // n })
		end
		return out
	end

	function grid.neighbours(self: Grid, id: number): { number }
		local out: { number } = {}
		for _, nm in names(self, id) do
			local f, i, j = nm[1], nm[2], nm[3]
			for _, o in OFFSETS do
				local ni, nj = i + o[1], j + o[2]
				if ni >= 0 and nj >= 0 and ni + nj <= n then
					local nid = self:idAt(f, ni, nj)
					if nid ~= id and not table.find(out, nid) then
						table.insert(out, nid)
					end
				end
			end
		end
		return out
	end

	-- Visits every cell exactly once (edge and corner points from their owning face).
	function grid.forEach(_self: Grid, fn: (id: number, face: number, i: number, j: number) -> ())
		for f, face in FACES do
			for i = 0, n do
				for j = 0, n - i do
					local onEdge = i == 0 or j == 0 or i + j == n
					if not onEdge then
						fn(faceBase + (f - 1) * perFace + rowOffset(i) + (j - 1), f, i, j)
					else
						local id = grid:idAt(f, i, j)
						local df = grid:decode(id)
						if df == f then
							fn(id, f, i, j)
						end
					end
				end
			end
		end
	end

	return grid
end

-- The coarse cell a fine cell belongs to: its nearest coarse lattice point in the same face,
-- ties going to the lower id. Exact integer maths.
function MoonGrid.parentAt(fine: Grid, coarse: Grid, f: number, i: number, j: number): number
	local k = fine.n // coarse.n
	local a, b = i // k, j // k
	local r, s = i - a * k, j - b * k
	local nc = coarse.n
	local bestId, bestD = -1, math.huge
	local function try(ci: number, cj: number)
		if ci >= 0 and cj >= 0 and ci + cj <= nc then
			local d = dist2(i - ci * k, j - cj * k)
			if d <= bestD then
				local id = coarse:idAt(f, ci, cj)
				if d < bestD or id < bestId then
					bestId, bestD = id, d
				end
			end
		end
	end
	if r + s < k then
		try(a, b)
		try(a + 1, b)
		try(a, b + 1)
	else
		try(a + 1, b)
		try(a, b + 1)
		try(a + 1, b + 1)
	end
	if r + s == k then
		-- on the diagonal of the lattice square, both triangles touch the point
		try(a, b)
	end
	return bestId
end

function MoonGrid.parentOf(fine: Grid, coarse: Grid, id: number): number
	assert(fine.n % coarse.n == 0, "grids must nest")
	local f, i, j = fine:decode(id)
	return MoonGrid.parentAt(fine, coarse, f, i, j)
end

-- Children per coarse cell, as a buffer of u16 (index = coarse id).
function MoonGrid.childCounts(fine: Grid, coarse: Grid): buffer
	local counts = buffer.create(coarse.count * 2)
	fine:forEach(function(_id, f, i, j)
		local p = MoonGrid.parentAt(fine, coarse, f, i, j)
		buffer.writeu16(counts, p * 2, buffer.readu16(counts, p * 2) + 1)
	end)
	return counts
end

return table.freeze(MoonGrid)
