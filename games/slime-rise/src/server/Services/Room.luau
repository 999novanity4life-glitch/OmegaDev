--!strict
-- The room shape the server is currently building (a map's Footprint), with
-- the placement helpers every builder uses: positions by angle and radius
-- (authored for the round reference shaft, warped onto this room) and CFrames
-- that face into the room. Builders call Room.use() at their entry point (and
-- after any yield), so maps of different shapes can build side by side.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Footprint = require(Shared:WaitForChild("Footprint"))

local Room = {}

local active: Footprint.Footprint = Footprint.new({ shape = "circle", radius = Footprint.REF })

function Room.use(fp: Footprint.Footprint)
	active = fp
end

function Room.current(): Footprint.Footprint
	return active
end

function Room.at(origin: Vector3, angle: number, radius: number, y: number): Vector3
	local x, z = Footprint.polar(active, angle, radius)
	return origin + Vector3.new(x, y, z)
end

-- On the ring at an angle, facing into the room: toward the centre for things
-- in the middle, straight off the wall for things mounted on it.
function Room.ring(origin: Vector3, angle: number, radius: number, y: number): CFrame
	local pos = Room.at(origin, angle, radius, y)
	local toCentre = Vector3.new(origin.X - pos.X, 0, origin.Z - pos.Z)
	toCentre = if toCentre.Magnitude > 1e-3 then toCentre.Unit else Vector3.new(-1, 0, 0)
	local nx, nz = Footprint.inward(active, angle)
	local w = Footprint.weight(radius / Footprint.REF)
	local dir = toCentre * (1 - w) + Vector3.new(nx, 0, nz) * w
	if dir.Magnitude < 1e-3 then
		dir = toCentre
	end
	return CFrame.lookAt(pos, pos + dir.Unit)
end

-- Wall panels along the room's edges (centre on the wall line, facing in).
function Room.segments(origin: Vector3, maxWidth: number, y: number): { { cf: CFrame, width: number } }
	local out = {}
	for _, s in Footprint.segments(active, maxWidth) do
		local pos = origin + Vector3.new(s.x, y, s.z)
		table.insert(out, { cf = CFrame.lookAt(pos, pos + Vector3.new(s.nx, 0, s.nz)), width = s.width })
	end
	return out
end

-- Floor slab extents around the room (relative to the origin).
function Room.bounds(margin: number): (number, number, number, number)
	return active.minX - margin, active.maxX + margin, active.minZ - margin, active.maxZ + margin
end

return Room
