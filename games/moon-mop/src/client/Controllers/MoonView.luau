--!strict
-- What cleaning looks like. Keeps a copy of the Moon's dust (snapshot on join, deltas after).
-- The dust is the Moon's own surface (terrain Ground with the regolith look); cleaning takes it
-- off and shows the darker bare ground underneath (reference p1_0140, d_0032: the brush cuts a
-- dark trail into pale dust, nothing is raised). So, around the camera only:
-- * clean patches repaint the terrain under them from Ground to bare Basalt, same height,
-- * finished sectors are fully repainted and get thin light edge lines (reference p1_1320),
-- * fresh trails right behind every brush uncover the ground the same way, as you go,
-- * a gold outline round the sector you stand in, and a mint flash and ripple when one finishes.
-- Everything here is cosmetic; the server decides what is clean.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local MoonGrid = require(Shared:WaitForChild("MoonGrid"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local MoonView = {}

local patch = MoonGrid.new(Config.Grid.PatchFrequency)
local sector = MoonGrid.new(Config.Grid.SectorFrequency)
MoonView.patch, MoonView.sector = patch, sector

local R = Config.Moon.Radius
local CENTRE = Config.Moon.Centre
local FULL = 255
local VIEW = 300 -- studs round the camera that get tiles
local DROP = 380

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end
local CLEAN = rgb(Config.Look.CleanColour)
local EDGE = rgb(Config.Look.EdgeColour)
local GOLD = rgb(Config.Look.Gold)
local MINT = rgb(Config.Look.Mint)

local dust = buffer.create(patch.count)
buffer.fill(dust, 0, FULL)
local done = buffer.create(sector.count)
local doneCount, yardCount = 0, 0
local touched: { [number]: boolean } = {} -- unfinished sectors with some clean patches
local ready = false

local folder = Instance.new("Folder")
folder.Name = "MoonView"
folder.Parent = Workspace

local Terrain = Workspace.Terrain
local DUSTY = Enum.Material.Ground
local BARE = Enum.Material.Basalt
-- Local only: bare ground wears the same regolith texture as the dust (a copy of the Ground
-- variant moved onto Basalt), just darker, so cleaning reveals Moon rather than flat paint.
do
	local MaterialService = game:GetService("MaterialService")
	local regolith = MaterialService:FindFirstChild("MoonRegolith", true)
	if regolith and regolith:IsA("MaterialVariant") and not MaterialService:FindFirstChild("MoonBedrock") then
		local bedrock = regolith:Clone()
		bedrock.Name = "MoonBedrock"
		bedrock.BaseMaterial = BARE
		bedrock.Parent = MaterialService
		MaterialService:SetBaseMaterialOverride(BARE, "MoonBedrock")
	end
	Terrain:SetMaterialColor(BARE, CLEAN)
end

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { Workspace.Terrain }

local hexTemplate: MeshPart? = nil
task.spawn(function()
	local assets = ReplicatedStorage:WaitForChild("Assets", 30)
	local hex = assets and assets:WaitForChild("Hex", 10)
	if hex and hex:IsA("MeshPart") then
		hexTemplate = hex
	end
end)

local function ground(dir: Vector3): RaycastResult?
	return Workspace:Raycast(CENTRE + dir * (R + 300), -dir * 420, terrainOnly)
end

-- A flat hexagon: the kit's hex mesh when it has arrived, else three crossed boxes.
local function hexTile(name: string, cf: CFrame, flat: number, thick: number, color: Color3, parent: Instance): Instance
	if hexTemplate then
		local t = hexTemplate:Clone()
		t.Name = name
		t.Anchored = true
		t.CanCollide = false
		t.CanQuery = false
		t.CanTouch = false
		t.CastShadow = false
		t.Material = Enum.Material.SmoothPlastic
		t.Color = color
		t.Size = Vector3.new(flat * 2 / math.sqrt(3), thick, flat)
		t.CFrame = cf
		t.Parent = parent
		return t
	end
	local m = Instance.new("Model")
	m.Name = name
	local side = flat / math.sqrt(3)
	for k = 0, 2 do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = color
		p.Size = Vector3.new(side, thick, flat)
		p.CFrame = cf * CFrame.Angles(0, math.rad(60 * k), 0)
		p.Parent = m
	end
	m.Parent = parent
	return m
end

-- Frame for a cell: on the ground, tilted to the ground under it, a flat side facing `tangent`.
local function cellFrame(dir: Vector3, tangent: Vector3, spread: number): CFrame?
	local hit = ground(dir)
	if not hit then
		return nil
	end
	local up = dir
	local normal = hit.Normal
	local pos = hit.Position
	if spread > 0 then
		-- average a few samples so a sector tile sits on the mean ground plane
		local right = tangent:Cross(up).Unit
		local sum, n = pos, 1
		for k = 0, 5 do
			local a = math.rad(60 * k)
			local off = (tangent * math.cos(a) + right * math.sin(a)) * spread
			local h = ground((CENTRE + dir * R + off - CENTRE).Unit)
			if h then
				sum += h.Position
				n += 1
			end
		end
		pos = sum / n
	end
	local tiltUp = normal:Lerp(up, 0.6).Unit
	local look = (tangent - tiltUp * tangent:Dot(tiltUp)).Unit
	return CFrame.lookAlong(pos + tiltUp * 0.08, look, tiltUp)
end

local function sectorSpacing(id: number): number
	local p = sector:position(id)
	local nb = sector:neighbours(id)
	local sum = 0
	for _, n in nb do
		sum += (sector:position(n) - p).Magnitude
	end
	return sum / #nb * R
end

local PATCH_SPACING = 0
do
	local p = patch:position(500000)
	local nb = patch:neighbours(500000)
	PATCH_SPACING = (patch:position(nb[1]) - p).Magnitude * R
end

-- Patches of a sector, found by sampling round its centre (cached).
local patchCache: { [number]: { number } } = {}
local cacheOrder: { number } = {}
local function patchesOf(s: number): { number }
	local cached = patchCache[s]
	if cached then
		return cached
	end
	local centre = sector:position(s)
	local tangent = sector:tangent(s)
	local right = tangent:Cross(centre).Unit
	local found: { [number]: boolean } = {}
	local list: { number } = {}
	local reach = sectorSpacing(s) * 0.75
	local step = PATCH_SPACING * 0.4
	for x = -reach, reach, step do
		for z = -reach, reach, step do
			local dir = (centre * R + tangent * x + right * z).Unit
			local id = patch:locate(dir)
			if not found[id] then
				found[id] = true
				if MoonGrid.parentOf(patch, sector, id) == s then
					table.insert(list, id)
				end
			end
		end
	end
	patchCache[s] = list
	table.insert(cacheOrder, s)
	if #cacheOrder > 400 then
		patchCache[table.remove(cacheOrder, 1) :: number] = nil
	end
	return list
end
MoonView.patchesOf = patchesOf

function MoonView.isDone(s: number): boolean
	return buffer.readu8(done, s) == 1
end

function MoonView.progress(s: number): number
	if buffer.readu8(done, s) == 1 then
		return 1
	end
	if not touched[s] then
		return 0
	end
	local list = patchesOf(s)
	local left = 0
	for _, id in list do
		left += buffer.readu8(dust, id)
	end
	return 1 - left / (#list * FULL)
end

function MoonView.state(s: number): number
	if buffer.readu8(done, s) == 1 then
		return 2
	end
	return if touched[s] then 1 else 0
end

function MoonView.cleanPct(): number
	return (doneCount - yardCount) / sector.count * 100
end

function MoonView.doneList(): buffer
	return done
end

function MoonView.touchedSet(): { [number]: boolean }
	return touched
end

-- Rendering state.
type SectorVis = { edges: { Instance }, kind: number }
local shown: { [number]: SectorVis } = {}

local function clearVis(s: number)
	local v = shown[s]
	if not v then
		return
	end
	for _, e in v.edges do
		e:Destroy()
	end
	shown[s] = nil
end

local function edgeLines(cf: CFrame, flat: number, parent: Instance): { Instance }
	local out: { Instance } = {}
	local rC = flat / math.sqrt(3)
	for k = 0, 5 do
		local a0, a1 = math.rad(60 * k + 30), math.rad(60 * k + 90)
		local p0 = cf:PointToWorldSpace(Vector3.new(rC * math.sin(a0), 0.07, rC * math.cos(a0)))
		local p1 = cf:PointToWorldSpace(Vector3.new(rC * math.sin(a1), 0.07, rC * math.cos(a1)))
		local line = Instance.new("Part")
		line.Name = "Edge"
		line.Anchored = true
		line.CanCollide = false
		line.CanQuery = false
		line.CanTouch = false
		line.CastShadow = false
		line.Material = Enum.Material.SmoothPlastic
		line.Color = EDGE
		line.Size = Vector3.new(0.22, 0.06, (p1 - p0).Magnitude + 0.2)
		line.CFrame = CFrame.lookAt((p0 + p1) / 2, p1, cf.UpVector)
		line.Parent = parent
		table.insert(out, line)
	end
	return out
end

-- Terrain repaint for one patch: a small grid-aligned box round the ground point. Only the
-- material changes, never the height. Paint stays when the sector scrolls out of view.
local painted: { [number]: boolean } = {}
local function paint(id: number, bare: boolean)
	if (painted[id] == true) == bare then
		return
	end
	local hit = ground(patch:position(id))
	if not hit then
		return
	end
	local h = PATCH_SPACING * 0.42
	local region = Region3.new(hit.Position - Vector3.one * h, hit.Position + Vector3.one * h):ExpandToGrid(4)
	if bare then
		Terrain:ReplaceMaterial(region, 4, DUSTY, BARE)
		painted[id] = true
	else
		Terrain:ReplaceMaterial(region, 4, BARE, DUSTY)
		painted[id] = nil
	end
end

local function showDone(s: number)
	local v = shown[s]
	if v and v.kind == 2 then
		return
	end
	clearVis(s)
	local dir = sector:position(s)
	local flat = sectorSpacing(s)
	local cf = cellFrame(dir, sector:tangent(s), flat * 0.3)
	if not cf then
		return
	end
	for _, id in patchesOf(s) do
		paint(id, true)
	end
	shown[s] = { edges = edgeLines(cf, flat, folder), kind = 2 }
end

local function showPartial(s: number)
	local existing = shown[s]
	if not (existing and existing.kind == 1) then
		clearVis(s)
		shown[s] = { edges = {}, kind = 1 }
	end
	for _, id in patchesOf(s) do
		paint(id, buffer.readu8(dust, id) == 0)
	end
end

local function refreshSector(s: number)
	if buffer.readu8(done, s) == 1 then
		showDone(s)
	elseif touched[s] then
		showPartial(s)
	else
		-- dust came back everywhere (a meteor shower): cover the bare ground again, brush
		-- trails included
		for _, id in patchesOf(s) do
			paint(id, false)
		end
		local hit = ground(sector:position(s))
		if hit then
			local h = sectorSpacing(s) * 0.5
			Terrain:ReplaceMaterial(
				Region3.new(hit.Position - Vector3.one * h, hit.Position + Vector3.one * h):ExpandToGrid(4),
				4,
				BARE,
				DUSTY
			)
		end
		clearVis(s)
	end
end

local focusDir = Vector3.yAxis
local function inView(s: number, range: number): boolean
	return (sector:position(s) - focusDir).Magnitude * R < range
end

-- Walk the sectors round the focus and draw what is clean.
local sweeping = false
local function sweepView()
	if sweeping then
		return
	end
	sweeping = true
	local start = sector:locate(focusDir)
	local seen = { [start] = true }
	local queue = { start }
	local head = 1
	local budget = 0
	while head <= #queue do
		local s = queue[head]
		head += 1
		if buffer.readu8(done, s) == 1 or touched[s] then
			if not shown[s] or (shown[s] :: SectorVis).kind ~= MoonView.state(s) then
				refreshSector(s)
				budget += 1
				if budget % 12 == 0 then
					task.wait()
				end
			end
		end
		for _, nb in sector:neighbours(s) do
			if not seen[nb] and inView(nb, VIEW) then
				seen[nb] = true
				table.insert(queue, nb)
			end
		end
	end
	for s in shown do
		if not inView(s, DROP) then
			clearVis(s)
		end
	end
	sweeping = false
end

-- Gold outline round the sector the player stands in, and the current-sector query for the HUD.
local outline: { BasePart } = {}
local outlined = -1
local current = -1
MoonView.current = function(): number
	return current
end

local function drawOutline(s: number)
	for _, p in outline do
		p:Destroy()
	end
	table.clear(outline)
	outlined = s
	if s < 0 or buffer.readu8(done, s) == 1 then
		return
	end
	local dir = sector:position(s)
	local flat = sectorSpacing(s)
	local cf = cellFrame(dir, sector:tangent(s), flat * 0.3)
	if not cf then
		return
	end
	local rC = flat / math.sqrt(3)
	for k = 0, 5 do
		local a0, a1 = math.rad(60 * k + 30), math.rad(60 * k + 90)
		local p0 = cf:PointToWorldSpace(Vector3.new(rC * math.sin(a0), 0.3, rC * math.cos(a0)))
		local p1 = cf:PointToWorldSpace(Vector3.new(rC * math.sin(a1), 0.3, rC * math.cos(a1)))
		local line = Instance.new("Part")
		line.Name = "Gold"
		line.Anchored = true
		line.CanCollide = false
		line.CanQuery = false
		line.CanTouch = false
		line.CastShadow = false
		line.Material = Enum.Material.Neon
		line.Color = GOLD
		line.Size = Vector3.new(0.35, 0.12, (p1 - p0).Magnitude + 0.35)
		line.CFrame = CFrame.lookAt((p0 + p1) / 2, p1, cf.UpVector)
		line.Parent = folder
		table.insert(outline, line)
	end
end

-- Mint flash and ripple when a sector finishes.
local function flash(s: number)
	if not inView(s, VIEW) then
		return
	end
	local dir = sector:position(s)
	local flat = sectorSpacing(s)
	local cf = cellFrame(dir, sector:tangent(s), flat * 0.3)
	if not cf then
		return
	end
	local glow = hexTile("Flash", cf * CFrame.new(0, 0.35, 0), flat, 0.2, MINT, folder)
	local ring = Instance.new("Part")
	ring.Name = "Ripple"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = MINT
	ring.Transparency = 0.3
	ring.Size = Vector3.new(0.2, flat * 0.9, flat * 0.9)
	ring.CFrame = cf * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = folder
	local reduced = GuiService.ReducedMotionEnabled
	local info = TweenInfo.new(if reduced then 0.01 else 0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local parts: { BasePart } = {}
	if glow:IsA("BasePart") then
		table.insert(parts, glow)
	else
		for _, c in glow:GetChildren() do
			if c:IsA("BasePart") then
				c.Material = Enum.Material.Neon
				table.insert(parts, c)
			end
		end
	end
	for _, p in parts do
		p.Material = Enum.Material.Neon
		p.Transparency = 0.35
		TweenService:Create(p, info, { Transparency = 1 }):Play()
	end
	if not reduced then
		TweenService:Create(ring, info, { Size = Vector3.new(0.2, flat * 2.6, flat * 2.6), Transparency = 1 }):Play()
	end
	task.delay(1, function()
		glow:Destroy()
		ring:Destroy()
	end)
end
MoonView.flash = flash

-- Lanes behind brushes (every brushing character nearby, read from character attributes).
local laneState: { [Model]: Vector3 } = {}
local laneParams = RaycastParams.new()
laneParams.FilterType = Enum.RaycastFilterType.Include
laneParams.FilterDescendantsInstances = { Workspace.Terrain }

local function laneTick()
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not char or not root or not char:GetAttribute("Brushing") or char:GetAttribute("JarFull") then
			if char then
				laneState[char] = nil
			end
			continue
		end
		local up = (root.Position - CENTRE).Unit
		if (up - focusDir).Magnitude * R > VIEW then
			continue
		end
		local width = (char:GetAttribute("ToolWidth") :: number?) or 2
		local reach = (char:GetAttribute("ToolReach") :: number?) or 2
		local fwd = root.CFrame.LookVector
		fwd -= up * fwd:Dot(up)
		if fwd.Magnitude < 1e-3 then
			continue
		end
		local probe = root.Position + fwd.Unit * reach
		local hit = Workspace:Raycast(probe + up * 2, -up * 9, laneParams)
		if not hit then
			laneState[char] = nil
			continue
		end
		local p = hit.Position
		local last = laneState[char]
		if not last then
			laneState[char] = p
			continue
		end
		local seg = p - last
		seg -= up * seg:Dot(up)
		local len = seg.Magnitude
		if len < 1.4 then
			continue
		end
		if len > 12 then
			laneState[char] = p
			continue
		end
		local s = sector:locate(up)
		if buffer.readu8(done, s) == 1 then
			laneState[char] = p
			continue
		end
		-- uncover the ground along the stroke: same terrain repaint as clean patches, so the
		-- trail is the bare Moon under the dust, flush, never a strip laid on top
		local dir = seg.Unit
		local half = math.max(width * 0.5, 1.2)
		local steps = math.max(1, math.ceil(len / 2))
		for k = 0, steps do
			local c = last + dir * (len * k / steps)
			Terrain:ReplaceMaterial(
				Region3.new(c - Vector3.one * half, c + Vector3.one * half):ExpandToGrid(4),
				4,
				DUSTY,
				BARE
			)
		end
		laneState[char] = p
	end
end

local function applyDelta(pb: buffer, db: buffer, rb: buffer)
	local dirty: { [number]: boolean } = {}
	for k = 0, buffer.len(pb) // 5 - 1 do
		local id = buffer.readu32(pb, k * 5)
		local level = buffer.readu8(pb, k * 5 + 4)
		buffer.writeu8(dust, id, level)
		local s = MoonGrid.parentOf(patch, sector, id)
		if buffer.readu8(done, s) == 0 then
			touched[s] = true
			dirty[s] = true
		end
	end
	for k = 0, buffer.len(db) // 4 - 1 do
		local s = buffer.readu32(db, k * 4)
		if buffer.readu8(done, s) == 0 then
			buffer.writeu8(done, s, 1)
			doneCount += 1
		end
		touched[s] = nil
		dirty[s] = true
		if ready then
			flash(s)
		end
	end
	for k = 0, buffer.len(rb) // 4 - 1 do
		local s = buffer.readu32(rb, k * 4)
		if buffer.readu8(done, s) == 1 then
			buffer.writeu8(done, s, 0)
			doneCount -= 1
		end
		touched[s] = nil
		for _, id in patchesOf(s) do
			buffer.writeu8(dust, id, FULL)
		end
		dirty[s] = true
	end
	for s in dirty do
		if inView(s, VIEW) then
			refreshSector(s)
		end
	end
	if outlined >= 0 and dirty[outlined] and buffer.readu8(done, outlined) == 1 then
		drawOutline(-1)
	end
end

local changedCallbacks: { () -> () } = {}
function MoonView.onChanged(fn: () -> ())
	table.insert(changedCallbacks, fn)
end

function MoonView.start()
	Remotes.get("MoonSnapshot").OnClientEvent:Connect(function(db: buffer, pb: buffer, yards: number)
		yardCount = yards
		for k = 0, buffer.len(db) // 4 - 1 do
			local s = buffer.readu32(db, k * 4)
			if buffer.readu8(done, s) == 0 then
				buffer.writeu8(done, s, 1)
				doneCount += 1
			end
		end
		applyDelta(pb, buffer.create(0), buffer.create(0))
		ready = true
		task.spawn(sweepView)
		for _, fn in changedCallbacks do
			task.spawn(fn)
		end
	end)
	Remotes.get("MoonDelta").OnClientEvent:Connect(function(pb: buffer, db: buffer, rb: buffer)
		applyDelta(pb, db, rb)
		for _, fn in changedCallbacks do
			task.spawn(fn)
		end
	end)

	local camera = Workspace.CurrentCamera
	local accum = 0
	RunService.Heartbeat:Connect(function(dt)
		local char = Players.LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local focus = if root then root.Position else camera.Focus.Position
		focusDir = (focus - CENTRE).Unit
		current = sector:locate(focusDir)
		if current ~= outlined then
			drawOutline(current)
		end
		laneTick()
		accum += dt
		if accum > 0.8 and ready then
			accum = 0
			task.spawn(sweepView)
		end
	end)
end

return MoonView
