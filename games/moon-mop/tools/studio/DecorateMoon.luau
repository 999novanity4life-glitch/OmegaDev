--!strict
-- Moon Mop: dresses the round Moon after MoonSphere has written the terrain.
-- * hexPad(dir, radius): a cleaned patch of hex sectors around a station pad, like the area
--   round the station in the reference (p1_10900): flat grey-lavender hexes with thin light edge
--   lines, sitting on the dusty white ground.
-- * scatterRocks(count, seed): boulders from ServerStorage.MoonMopKit (RockA..RockE) all over the
--   sphere, each stood on the terrain along the local up, randomly turned and half buried.
-- Everything is placed by raycasting toward the Moon's centre, so it hugs the real surface.
-- Usage (Studio command bar or MCP execute_luau):
--   local deco = require(game.ServerStorage.DecorateMoon)
--   deco.hexPad(Vector3.yAxis, 95)
--   deco.scatterRocks(700, 7)

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local data = ServerStorage:WaitForChild("MoonMapData")
local R: number = data:GetAttribute("Radius")
local CENTRE = Vector3.new(0, -R, 0)
local KIT = ServerStorage:WaitForChild("MoonMopKit")

local HEX_R = 20 -- circumradius; matches the DustHex mesh (40 x 34.64, flat sides on +-Z)
local CLEAN = Color3.fromRGB(142, 144, 164)
local LINE = Color3.fromRGB(226, 240, 246)

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { Workspace.Terrain }

-- Orientation whose UpVector is `up`, turned `yaw` about it.
local function upFrame(pos: Vector3, up: Vector3, yaw: number): CFrame
	local ref = if math.abs(up.Y) < 0.95 then Vector3.yAxis else Vector3.xAxis
	local right = ref:Cross(up).Unit
	local back = right:Cross(up)
	return CFrame.fromMatrix(pos, right, up, back) * CFrame.Angles(0, yaw, 0)
end

local function ground(dir: Vector3): RaycastResult?
	local from = CENTRE + dir.Unit * (R + 400)
	return Workspace:Raycast(from, -dir.Unit * 600, terrainOnly)
end

local function folder(name: string): Folder
	local f = Workspace:FindFirstChild(name)
	if f then
		f:Destroy()
	end
	local nf = Instance.new("Folder")
	nf.Name = name
	return nf
end

local function hexPad(dir: Vector3, radius: number, name: string?): Folder
	local out = folder(name or "CleanHexes")
	local up0 = dir.Unit
	local base = upFrame(CENTRE + up0 * R, up0, 0)
	local hexMesh = (KIT:WaitForChild("DustHex") :: Model):FindFirstChild("Hex") :: MeshPart
	local seen: { [string]: boolean } = {}
	local n = math.ceil(radius / (1.5 * HEX_R)) + 1
	for col = -n, n do
		for row = -n, n do
			local x = col * 1.5 * HEX_R
			local z = row * math.sqrt(3) * HEX_R + (if col % 2 == 1 then math.sqrt(3) / 2 * HEX_R else 0)
			if math.sqrt(x * x + z * z) <= radius then
				local world = base:PointToWorldSpace(Vector3.new(x, 0, z))
				local hit = ground(world - CENTRE)
				if hit then
					local up = (hit.Position - CENTRE).Unit
					local cf = upFrame(hit.Position + up * 0.12, up, 0)
					-- keep every hex aligned with the pad's own axes
					cf = CFrame.lookAlong(cf.Position, (base.LookVector - up * base.LookVector:Dot(up)).Unit, up)
					local tile = hexMesh:Clone()
					tile.Name = "Hex"
					tile.Anchored = true
					tile.Color = CLEAN
					tile.Material = Enum.Material.SmoothPlastic
					tile.CFrame = cf
					tile.Parent = out
					for k = 0, 5 do
						local a0, a1 = math.rad(60 * k), math.rad(60 * (k + 1))
						local p0 = Vector3.new(x + HEX_R * math.cos(a0), 0, z + HEX_R * math.sin(a0))
						local p1 = Vector3.new(x + HEX_R * math.cos(a1), 0, z + HEX_R * math.sin(a1))
						local mid = (p0 + p1) / 2
						local key = string.format("%d_%d", math.round(mid.X * 2), math.round(mid.Z * 2))
						if not seen[key] then
							seen[key] = true
							local w0 = cf:PointToWorldSpace(p0 - Vector3.new(x, 0, z))
							local w1 = cf:PointToWorldSpace(p1 - Vector3.new(x, 0, z))
							local line = Instance.new("Part")
							line.Name = "Edge"
							line.Anchored = true
							line.CanCollide = false
							line.CastShadow = false
							line.Material = Enum.Material.SmoothPlastic
							line.Color = LINE
							line.Size = Vector3.new(0.22, 0.06, (w1 - w0).Magnitude + 0.2)
							line.CFrame = CFrame.lookAt((w0 + w1) / 2 + up * 0.22, w1, up)
							line.Parent = out
						end
					end
				end
			end
		end
	end
	out.Parent = Workspace
	return out
end

-- Avoid the station pads and the cleaned hex patches.
local function nearPad(dir: Vector3, pads: { any }): boolean
	for _, p in pads do
		if (Vector3.new(p[1], p[2], p[3]).Unit - dir).Magnitude * R < p[4] + 25 then
			return true
		end
	end
	return false
end

local function scatterRocks(count: number, seed: number): Folder
	local out = folder("Boulders")
	local pads = game:GetService("HttpService"):JSONDecode(data:GetAttribute("Pads"))
	local rng = Random.new(seed)
	local kinds = { "RockA", "RockA", "RockA", "RockB", "RockB", "RockC", "RockD", "RockD", "RockD", "RockE" }
	local placed = 0
	local tries = 0
	while placed < count and tries < count * 4 do
		tries += 1
		local dir = rng:NextUnitVector()
		if not nearPad(dir, pads) then
			local hit = ground(dir)
			if hit then
				local kind = KIT:FindFirstChild(kinds[rng:NextInteger(1, #kinds)]) :: Model
				local m = kind:Clone()
				local scale = rng:NextNumber(0.7, 1.6)
				m:ScaleTo(scale)
				local up = hit.Normal:Lerp((hit.Position - CENTRE).Unit, 0.5).Unit
				local cf = upFrame(hit.Position, up, rng:NextNumber(0, 2 * math.pi))
				m:PivotTo(cf * CFrame.Angles(rng:NextNumber(-0.25, 0.25), 0, rng:NextNumber(-0.25, 0.25)))
				-- sink it so about a quarter of its height is under the dust
				local box, size = m:GetBoundingBox()
				local lift = (hit.Position - box.Position):Dot(up) + size.Y * 0.25
				m:PivotTo(m:GetPivot() + up * lift)
				for _, d in m:GetDescendants() do
					if d:IsA("BasePart") then
						d.Anchored = true
					end
				end
				m.Parent = out
				placed += 1
				if placed % 50 == 0 then
					task.wait()
				end
			end
		end
	end
	out.Parent = Workspace
	return out
end

return {
	hexPad = hexPad,
	scatterRocks = scatterRocks,
}
