--!strict
-- Pure parser for the fruit preview meshes in Shared/FruitMeshes (format in
-- assets/fruits/README.md). No `game` access; tests/FruitMeshData.spec.luau.

export type Vertex = { x: number, y: number, z: number, r: number, g: number, b: number, glow: number }
export type Mesh = { verts: { Vertex }, tris: { { number } } }

local FruitMeshData = {}

-- Parse into studs, 0..1 colours and a 0..1 glow mask; triangle indices are
-- 1-based. Malformed entries are skipped, and triangles pointing past the
-- vertex list are dropped.
function FruitMeshData.parse(v: string, t: string): Mesh
	local verts: { Vertex } = {}
	for entry in string.gmatch(v, "[^;]+") do
		local x, y, z, hex, gg = string.match(entry, "^(%-?%d+),(%-?%d+),(%-?%d+),(%x%x%x%x%x%x),(%x%x)$")
		if x and y and z and hex and gg then
			table.insert(verts, {
				x = (tonumber(x) :: number) / 1000,
				y = (tonumber(y) :: number) / 1000,
				z = (tonumber(z) :: number) / 1000,
				r = (tonumber(string.sub(hex, 1, 2), 16) :: number) / 255,
				g = (tonumber(string.sub(hex, 3, 4), 16) :: number) / 255,
				b = (tonumber(string.sub(hex, 5, 6), 16) :: number) / 255,
				glow = (tonumber(gg, 16) :: number) / 255,
			})
		end
	end
	local tris: { { number } } = {}
	local n = #verts
	for entry in string.gmatch(t, "[^;]+") do
		local a, b, c = string.match(entry, "^(%d+),(%d+),(%d+)$")
		if a and b and c then
			local ia, ib, ic = (tonumber(a) :: number) + 1, (tonumber(b) :: number) + 1, (tonumber(c) :: number) + 1
			if ia <= n and ib <= n and ic <= n then
				table.insert(tris, { ia, ib, ic })
			end
		end
	end
	return { verts = verts, tris = tris }
end

-- Triangles whose average glow mask is at least `threshold` (0..1): the
-- crevices the glow shell is built from.
function FruitMeshData.glowTris(mesh: Mesh, threshold: number): { { number } }
	local out = {}
	for _, tri in mesh.tris do
		local g = (mesh.verts[tri[1]].glow + mesh.verts[tri[2]].glow + mesh.verts[tri[3]].glow) / 3
		if g >= threshold then
			table.insert(out, tri)
		end
	end
	return out
end

-- Largest extent across X/Y/Z in studs.
function FruitMeshData.size(mesh: Mesh): number
	local lo = { math.huge, math.huge, math.huge }
	local hi = { -math.huge, -math.huge, -math.huge }
	for _, p in mesh.verts do
		lo[1], hi[1] = math.min(lo[1], p.x), math.max(hi[1], p.x)
		lo[2], hi[2] = math.min(lo[2], p.y), math.max(hi[2], p.y)
		lo[3], hi[3] = math.min(lo[3], p.z), math.max(hi[3], p.z)
	end
	if #mesh.verts == 0 then
		return 0
	end
	return math.max(hi[1] - lo[1], hi[2] - lo[2], hi[3] - lo[3])
end

return FruitMeshData
