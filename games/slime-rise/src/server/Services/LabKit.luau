--!strict
-- The lab detail kit: PBR materials, generated prop meshes and part-built
-- greebles (railings, lights, vents, racks, cables, gauges, signs). Everything
-- is created from asset ids in code, so the repo holds the whole look.
-- Detail bar: no flat blockout surfaces in anything players see.

local AssetService = game:GetService("AssetService")
local CollectionService = game:GetService("CollectionService")
local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local KitManifest = require(script.Parent.KitManifest)
local KitMeshIds = require(script.Parent.KitMeshIds)

local LabKit = {}

type MaterialDef = { Base: Enum.Material }

-- Hand-designed stylized materials (art/textures.py: one palette, one light, tileable, with normal maps).
-- The variants themselves ship in the place: materials/*.model.json (Rojo).
local MATERIALS: { [string]: MaterialDef } = {
	SR_Panel = { Base = Enum.Material.SmoothPlastic },
	SR_Grate = { Base = Enum.Material.SmoothPlastic },
	SR_Pad = { Base = Enum.Material.SmoothPlastic },
	SR_Steel = { Base = Enum.Material.SmoothPlastic },
	SR_Tile = { Base = Enum.Material.SmoothPlastic },
	-- Surface-specific variants (art/textures2.py), so neighbours never read as copies.
	SR_WallPlain = { Base = Enum.Material.SmoothPlastic },
	SR_WallVent = { Base = Enum.Material.SmoothPlastic },
	SR_WallHatch = { Base = Enum.Material.SmoothPlastic },
	SR_WallPipe = { Base = Enum.Material.SmoothPlastic },
	SR_WallWindow = { Base = Enum.Material.SmoothPlastic },
	SR_WallControl = { Base = Enum.Material.SmoothPlastic },
	SR_WallBase = { Base = Enum.Material.SmoothPlastic },
	SR_FloorDrain = { Base = Enum.Material.SmoothPlastic },
	SR_Walkway = { Base = Enum.Material.SmoothPlastic },
	SR_FloorEdge = { Base = Enum.Material.SmoothPlastic },
	SR_Emblem = { Base = Enum.Material.SmoothPlastic },
	SR_Ceiling = { Base = Enum.Material.SmoothPlastic },
	SR_Trim = { Base = Enum.Material.SmoothPlastic },
}

-- Overlay decals (art/decal_*.png): white stencils tint with Color3.
local DECALS: { [string]: string } = {
	Level1 = "rbxassetid://135849800451238",
	Level2 = "rbxassetid://130341682326182",
	Level3 = "rbxassetid://71220068353244",
	Level4 = "rbxassetid://122666402278670",
	Arrow = "rbxassetid://103669012047389",
	Drip = "rbxassetid://129228210768646",
	Puddle = "rbxassetid://139521380598278",
	Warning = "rbxassetid://107459922647096",
	Shadow = "rbxassetid://117083517407256",
}

-- Wall panel rhythm from the research: mostly calm panels, specials weighted,
-- never the same special twice in a row or stacked.
local PANEL_WEIGHTS: { { name: string, weight: number } } = {
	{ name = "SR_WallPlain", weight = 60 },
	{ name = "SR_WallVent", weight = 15 },
	{ name = "SR_WallPipe", weight = 10 },
	{ name = "SR_WallHatch", weight = 10 },
	{ name = "SR_WallWindow", weight = 5 },
}
-- Crisp tileable hazard stripes (rendered in code, art/hazard.png).
local HAZARD_TEXTURE = "rbxassetid://124914035857571"

type PropDef = { Mesh: string, Texture: string, Size: Vector3 }
-- AI-generated in Studio (generate_mesh); Size is the mesh's native size.
local PROPS: { [string]: PropDef } = {
	Console = {
		Mesh = "rbxassetid://99814870193487",
		Texture = "rbxassetid://100279005196714",
		Size = Vector3.new(5.83, 4.44, 3.5),
	},
	Tank = {
		Mesh = "rbxassetid://88421651009219",
		Texture = "rbxassetid://136847957694319",
		Size = Vector3.new(8, 10.53, 6.61),
	},
	Pipes = {
		Mesh = "rbxassetid://108205937549355",
		Texture = "rbxassetid://75734109668765",
		Size = Vector3.new(3.94, 3.72, 2.5),
	},
	Crates = {
		Mesh = "rbxassetid://124020962317391",
		Texture = "rbxassetid://129841784327388",
		Size = Vector3.new(2.05, 5, 2.04),
	},
	Valve = {
		Mesh = "rbxassetid://92090303569705",
		Texture = "rbxassetid://114024269944874",
		Size = Vector3.new(2.4, 3.4, 2.39),
	},
	Fuse = {
		Mesh = "rbxassetid://118056286073142",
		Texture = "rbxassetid://107723768560570",
		Size = Vector3.new(1.16, 2.6, 0.88),
	},
}

local C = {
	Dark = Color3.fromRGB(26, 22, 36),
	Steel = Color3.fromRGB(170, 176, 196),
	Hazard = Color3.fromRGB(255, 200, 50),
	White = Color3.fromRGB(235, 245, 255),
	Cable = Color3.fromRGB(20, 18, 26),
}
LabKit.Colors = C

local templates: { [string]: MeshPart } = {}
local available: { [string]: boolean } = {}
local started = false

function LabKit.start()
	if started then
		return
	end
	started = true
	-- MaterialVariants can't be created by game scripts at runtime, so they
	-- ship in the place (Rojo: materials/*.model.json -> MaterialService).
	for _, inst in MaterialService:GetDescendants() do
		if inst:IsA("MaterialVariant") and MATERIALS[inst.Name] then
			available[inst.Name] = true
		end
	end
	-- Load prop meshes once; failures just fall back to part builds.
	for name, def in PROPS do
		local ok, mesh = pcall(function()
			return AssetService:CreateMeshPartAsync(def.Mesh)
		end)
		if ok and mesh then
			mesh.TextureID = def.Texture
			mesh.Anchored = true
			mesh.Size = def.Size
			mesh.Name = name
			templates[name] = mesh
		else
			warn("[LabKit] prop failed to load: " .. name)
		end
	end
end

-- Neon glows by colour brightness, and Bloom blows bright neon out. Keep every
-- glow at about 60% brightness and slightly see-through: still glowing, not blinding.
function LabKit.soften(part: BasePart)
	local h, sat, v = part.Color:ToHSV()
	part.Color = Color3.fromHSV(h, math.min(1, sat * 1.05), v * 0.62)
	part.Transparency = math.max(part.Transparency, 0.12)
end

-- Applies a kit material (base + PBR variant) and a tint.
-- Applies a kit material (base + stylized variant) and a tint. Without the
-- variant in the place it falls back to clean SmoothPlastic in the same tint.
function LabKit.mat(part: BasePart, name: string, color: Color3?)
	if name == "SR_Hazard" then
		-- Clean stylized stripes on the visible faces of blocks; solid yellow on round parts.
		part.Material = Enum.Material.SmoothPlastic
		part.Color = Color3.fromRGB(255, 201, 60)
		if part:IsA("Part") and part.Shape == Enum.PartType.Block then
			for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Top } do
				local t = Instance.new("Texture")
				t.Texture = HAZARD_TEXTURE
				t.Face = face
				t.StudsPerTileU = 2.4
				t.StudsPerTileV = 2.4
				t.Parent = part
			end
		end
		return
	end
	local def = MATERIALS[name]
	if def and available[name] then
		part.Material = def.Base
		part.MaterialVariant = name
		-- The textures carry their own designed colours; tint only when asked.
		if name ~= "SR_Pad" then
			part.Color = color or Color3.new(1, 1, 1)
			return
		end
	else
		part.Material = Enum.Material.SmoothPlastic
	end
	if color then
		part.Color = color
	end
end

function LabKit.part(props: { [string]: any }, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.Metal
	local matName = props.Kit
	local tint = props.Tint
	props.Kit = nil
	props.Tint = nil
	for key, value in props do
		(p :: any)[key] = value
	end
	if type(matName) == "string" then
		LabKit.mat(p, matName, if typeof(tint) == "Color3" then tint else nil)
	end
	if p.Material == Enum.Material.Neon then
		LabKit.soften(p)
	end
	p.Parent = parent
	return p
end

function LabKit.deco(props: { [string]: any }, parent: Instance): Part
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	props.CastShadow = if props.CastShadow == nil then false else props.CastShadow
	return LabKit.part(props, parent)
end

-- Themed kit pieces wear their room's palette for the shared groups.
local COLD_PIECES: { [string]: boolean } = { IceCluster = true, FrostPanel = true, IceLedge = true }
local GREEN_PIECES: { [string]: boolean } = {
	MushroomPad = true,
	LeafPad = true,
	VineTruss = true,
	PlantSweeper = true,
	PlantSweeperArm = true,
	MutantPlant = true,
	GrowLight = true,
}
local GREEN_LOOK: { [string]: Color3 } = {
	Frame = Color3.fromRGB(150, 176, 128),
	Inset = Color3.fromRGB(214, 222, 196),
	Dark = Color3.fromRGB(46, 56, 40),
	Glow = Color3.fromRGB(255, 200, 100),
	Glass = Color3.fromRGB(210, 255, 220),
}
local CRYO_LOOK: { [string]: Color3 } = {
	Frame = Color3.fromRGB(150, 182, 212),
	Inset = Color3.fromRGB(206, 222, 236),
	Dark = Color3.fromRGB(44, 60, 82),
	Glow = Color3.fromRGB(110, 220, 255),
	Glass = Color3.fromRGB(190, 238, 255),
}

-- How each Blender material group looks in game (the geometry carries the detail).
local KIT_LOOK: { [string]: (MeshPart) -> () } = {
	Frame = function(m)
		m.Material = Enum.Material.SmoothPlastic
		m.Color = Color3.fromRGB(104, 86, 150)
	end,
	Inset = function(m)
		m.Material = Enum.Material.SmoothPlastic
		m.Color = Color3.fromRGB(66, 52, 102)
	end,
	Steel = function(m)
		LabKit.mat(m, "SR_Steel", Color3.fromRGB(176, 182, 200))
	end,
	Dark = function(m)
		m.Material = Enum.Material.SmoothPlastic
		m.Color = Color3.fromRGB(30, 27, 42)
	end,
	Glass = function(m)
		m.Material = Enum.Material.Glass
		m.Color = Color3.fromRGB(150, 235, 210)
		m.Transparency = 0.55
	end,
	Glow = function(m)
		m.Material = Enum.Material.Neon
		m.Color = Config.Colors.Slime
		LabKit.soften(m)
	end,
	Hazard = function(m)
		m.Material = Enum.Material.SmoothPlastic
		m.Color = Color3.fromRGB(255, 201, 60)
	end,
	-- Standable tops: light, matte and clearly "safe to land on".
	Rubber = function(m)
		LabKit.mat(m, "SR_Pad", Color3.fromRGB(226, 232, 244))
	end,
	Slime = function(m)
		m.Material = Enum.Material.Neon
		m.Color = Config.Colors.SlimeDeep
		LabKit.soften(m)
		m.Transparency = 0.25
	end,
	-- Cryo kit: frost build-up and clear ice.
	Frost = function(m)
		m.Material = Enum.Material.SmoothPlastic
		m.Color = Color3.fromRGB(236, 246, 255)
	end,
	Ice = function(m)
		m.Material = Enum.Material.Glass
		m.Color = Color3.fromRGB(176, 230, 255)
		m.Transparency = 0.3
	end,
	-- Greenhouse kit: foliage, stems, flowers and soil.
	Leaf = function(m)
		m.Material = Enum.Material.SmoothPlastic
		m.Color = Color3.fromRGB(96, 196, 82)
	end,
	Bark = function(m)
		m.Material = Enum.Material.SmoothPlastic
		m.Color = Color3.fromRGB(112, 84, 58)
	end,
	Petal = function(m)
		m.Material = Enum.Material.SmoothPlastic
		m.Color = Color3.fromRGB(240, 96, 150)
	end,
	Soil = function(m)
		m.Material = Enum.Material.SmoothPlastic
		m.Color = Color3.fromRGB(64, 46, 34)
	end,
}

local meshTemplates: { [string]: MeshPart } = {}

-- Collision shape can only be chosen when the mesh is created, so cache one
-- template per (mesh, fidelity).
local function meshTemplate(meshName: string, fidelity: Enum.CollisionFidelity): MeshPart?
	local key = meshName .. ":" .. fidelity.Name
	local cached = meshTemplates[key]
	if cached then
		return cached
	end
	local id = KitMeshIds[meshName]
	if not id then
		return nil
	end
	local ok, mesh = pcall(function()
		return AssetService:CreateMeshPartAsync(id, { CollisionFidelity = fidelity })
	end)
	if not ok or not mesh then
		warn("[LabKit] kit mesh failed: " .. meshName)
		return nil
	end
	mesh.Anchored = true
	meshTemplates[key] = mesh
	return mesh
end

export type KitOptions = { collide: boolean?, fidelity: Enum.CollisionFidelity?, name: string?, scale: Vector3? }

-- Builds a Blender kit piece at cf (piece origin = base centre, front = -Z).
-- Returns the model, or nil when the kit meshes aren't imported yet.
function LabKit.kit(piece: string, cf: CFrame, parent: Instance, opts: KitOptions?): Model?
	local parts = KitManifest[piece]
	if not parts then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = (opts and opts.name) or piece
	local collideAll = opts ~= nil and opts.collide == true
	local fidelity = if collideAll
		then (opts and opts.fidelity) or Enum.CollisionFidelity.Box
		else Enum.CollisionFidelity.Box
	for group, info in parts do
		local template = meshTemplate(info.mesh, fidelity)
		if not template then
			model:Destroy()
			return nil
		end
		local m = template:Clone()
		local scale = (opts and opts.scale) or Vector3.one
		m.Size = info.size * scale
		m.CFrame = cf * CFrame.new(info.offset * scale)
		local look = KIT_LOOK[group]
		if look then
			look(m)
		end
		local cold = if COLD_PIECES[piece] or string.sub(piece, 1, 4) == "Cryo"
			then CRYO_LOOK[group]
			elseif GREEN_PIECES[piece] or string.sub(piece, 1, 5) == "Green" then GREEN_LOOK[group]
			else nil
		if cold then
			m.Color = cold
			if group == "Glow" then
				LabKit.soften(m)
			end
		end
		local collide = collideAll and group ~= "Glow"
		m.CanCollide = collide
		m.CanQuery = collide
		m.CanTouch = collide
		m.CastShadow = group ~= "Glow" and group ~= "Glass"
		m.Name = group
		m.Parent = model
	end
	model.Parent = parent
	return model
end

-- Fetches every kit mesh in the background at server start, so the first
-- match doesn't stall on downloads while players wait in the elevator.
function LabKit.warmKit()
	local wanted: { [string]: Enum.CollisionFidelity } = {}
	for piece, parts in KitManifest do
		for _, info in parts do
			wanted[info.mesh] = Enum.CollisionFidelity.Box
		end
		if piece == "Tank" then
			for _, info in parts do
				wanted[info.mesh .. "|hull"] = Enum.CollisionFidelity.Hull
			end
		end
	end
	for key, fidelity in wanted do
		local meshName = string.split(key, "|")[1]
		task.spawn(meshTemplate, meshName, fidelity)
	end
end

function LabKit.kitReady(): boolean
	return next(KitMeshIds) ~= nil
end

-- Picks a wall panel variant. `left` and `below` are the neighbours' picks.
function LabKit.pickPanel(rand: Random, left: string?, below: string?): string
	local total = 0
	for _, w in PANEL_WEIGHTS do
		total += w.weight
	end
	for _ = 1, 6 do
		local roll = rand:NextNumber() * total
		for _, w in PANEL_WEIGHTS do
			roll -= w.weight
			if roll <= 0 then
				local name = w.name
				local special = name ~= "SR_WallPlain"
				if not special or (name ~= left and name ~= below) then
					return name
				end
				break
			end
		end
	end
	return "SR_WallPlain"
end

-- Puts an overlay decal on one face of a part.
function LabKit.decal(part: BasePart, name: string, face: Enum.NormalId?, color: Color3?, transparency: number?): Decal?
	local id = DECALS[name]
	if not id then
		return nil
	end
	local d = Instance.new("Decal")
	d.Texture = id
	d.Face = face or Enum.NormalId.Front
	d.Color3 = color or Color3.new(1, 1, 1)
	d.Transparency = transparency or 0
	d.Parent = part
	return d
end

-- A thin carrier part flush with a surface, for decals that shouldn't stretch
-- across a whole wall (stencils, puddles, signs).
function LabKit.decalPlate(parent: Instance, cf: CFrame, size: Vector2, name: string, color: Color3?): Part
	local plate = LabKit.deco({ Size = Vector3.new(size.X, size.Y, 0.05), CFrame = cf, Transparency = 1 }, parent)
	LabKit.decal(plate, name, Enum.NormalId.Front, color)
	return plate
end

-- A generated prop scaled to a height (studs), standing on cf (bottom centre).
function LabKit.prop(name: string, cf: CFrame, height: number, parent: Instance, collide: boolean?): MeshPart?
	local template = templates[name]
	if not template then
		return nil
	end
	local mesh = template:Clone()
	local scale = height / template.Size.Y
	mesh.Size = template.Size * scale
	mesh.CFrame = cf * CFrame.new(0, mesh.Size.Y / 2, 0)
	mesh.CanCollide = collide == true
	mesh.CanQuery = collide == true
	mesh.CanTouch = false
	mesh.Parent = parent
	return mesh
end

function LabKit.hasProp(name: string): boolean
	return if templates[name] then true else false
end

-- Railing along the local X axis of cf (cf = centre of the rail base).
function LabKit.railing(parent: Instance, cf: CFrame, length: number, height: number?)
	local h = height or 3.2
	local posts = math.max(2, math.floor(length / 4) + 1)
	for i = 0, posts - 1 do
		local x = -length / 2 + i * (length / (posts - 1))
		LabKit.deco({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(h, 0.35, 0.35),
			CFrame = cf * CFrame.new(x, h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Kit = "SR_Hazard",
			Color = C.Hazard,
		}, parent)
		LabKit.deco({
			Size = Vector3.new(0.7, 0.15, 0.7),
			CFrame = cf * CFrame.new(x, 0.08, 0),
			Kit = "SR_Steel",
			Color = C.Steel,
		}, parent)
	end
	for _, y in { h, h * 0.55 } do
		LabKit.deco({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(length, 0.3, 0.3),
			CFrame = cf * CFrame.new(0, y, 0),
			Kit = "SR_Hazard",
			Color = C.Hazard,
		}, parent)
	end
	LabKit.deco(
		{ Size = Vector3.new(length, 0.5, 0.1), CFrame = cf * CFrame.new(0, 0.3, 0), Kit = "SR_Steel", Color = C.Steel },
		parent
	)
	-- Invisible wall so players don't slip off.
	LabKit.part({
		Size = Vector3.new(length, h, 0.4),
		CFrame = cf * CFrame.new(0, h / 2, 0),
		Transparency = 1,
		CanQuery = false,
	}, parent)
end

-- Caged wall light: housing, glowing tube, cage bars and a real light.
function LabKit.lightFixture(parent: Instance, cf: CFrame, color: Color3?, range: number?)
	local glow = color or C.White
	LabKit.deco({ Size = Vector3.new(4, 1, 0.8), CFrame = cf, Kit = "SR_Steel", Color = C.Dark }, parent)
	local tube = LabKit.deco({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(3.4, 0.5, 0.5),
		CFrame = cf * CFrame.new(0, 0, -0.55),
		Color = glow,
		Material = Enum.Material.Neon,
	}, parent)
	for i = -1, 1 do
		LabKit.deco({
			Size = Vector3.new(0.12, 0.9, 0.12),
			CFrame = cf * CFrame.new(i * 1.3, 0, -0.95),
			Kit = "SR_Steel",
			Color = C.Steel,
		}, parent)
	end
	LabKit.deco({
		Size = Vector3.new(3.8, 0.12, 0.12),
		CFrame = cf * CFrame.new(0, 0.45, -0.95),
		Kit = "SR_Steel",
		Color = C.Steel,
	}, parent)
	LabKit.deco({
		Size = Vector3.new(3.8, 0.12, 0.12),
		CFrame = cf * CFrame.new(0, -0.45, -0.95),
		Kit = "SR_Steel",
		Color = C.Steel,
	}, parent)
	local light = Instance.new("PointLight")
	light.Color = glow
	light.Range = (range or 28) + 4
	light.Brightness = 2.1
	light.Shadows = false
	light.Parent = tube
end

-- Wall vent with slats and a fan behind (client spins parts tagged "Fan").
function LabKit.vent(parent: Instance, cf: CFrame, size: number)
	local s = size
	LabKit.deco(
		{ Size = Vector3.new(s, s, 0.3), CFrame = cf * CFrame.new(0, 0, 0.3), Color = Color3.fromRGB(10, 8, 14) },
		parent
	)
	local fan = LabKit.deco(
		{ Name = "FanHub", Size = Vector3.new(0.5, 0.5, 0.3), CFrame = cf * CFrame.new(0, 0, 0.1), Color = C.Steel },
		parent
	)
	CollectionService:AddTag(fan, "Fan")
	for i = 0, 3 do
		local blade = LabKit.deco({
			Size = Vector3.new(s * 0.42, 0.5, 0.08),
			CFrame = fan.CFrame
				* CFrame.Angles(0, 0, math.rad(i * 90))
				* CFrame.new(s * 0.21, 0, 0)
				* CFrame.Angles(math.rad(25), 0, 0),
			Color = Color3.fromRGB(70, 74, 92),
		}, parent)
		blade.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = fan
		weld.Part1 = blade
		weld.Parent = blade
	end
	for _, side in
		{ { 0, s / 2, s + 0.4, 0.4 }, { 0, -s / 2, s + 0.4, 0.4 }, { s / 2, 0, 0.4, s }, { -s / 2, 0, 0.4, s } }
	do
		LabKit.deco({
			Size = Vector3.new(side[3], side[4], 0.5),
			CFrame = cf * CFrame.new(side[1], side[2], -0.1),
			Kit = "SR_Steel",
			Color = C.Steel,
		}, parent)
	end
	local slats = 5
	for i = 1, slats do
		local y = -s / 2 + i * s / (slats + 1)
		LabKit.deco({
			Size = Vector3.new(s - 0.2, 0.18, 0.5),
			CFrame = cf * CFrame.new(0, y, -0.15) * CFrame.Angles(math.rad(-30), 0, 0),
			Kit = "SR_Steel",
			Color = Color3.fromRGB(120, 126, 146),
		}, parent)
	end
	for _, corner in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
		LabKit.deco({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.15, 0.25, 0.25),
			CFrame = cf
				* CFrame.new(corner[1] * (s / 2), corner[2] * (s / 2), -0.38)
				* CFrame.Angles(0, math.rad(90), 0),
			Color = C.Steel,
		}, parent)
	end
end

-- Server rack with blinking LEDs (client blinks parts tagged "Blink").
function LabKit.serverRack(parent: Instance, cf: CFrame)
	local w, h, d = 3.4, 7, 2.6
	LabKit.part({
		Size = Vector3.new(w, h, d),
		CFrame = cf * CFrame.new(0, h / 2, 0),
		Kit = "SR_Steel",
		Color = Color3.fromRGB(46, 44, 60),
	}, parent)
	LabKit.deco({
		Size = Vector3.new(w - 0.5, h - 0.6, 0.1),
		CFrame = cf * CFrame.new(0, h / 2, -d / 2 - 0.05),
		Color = Color3.fromRGB(16, 14, 22),
	}, parent)
	for row = 0, 8 do
		local y = 0.8 + row * 0.68
		LabKit.deco({
			Size = Vector3.new(w - 0.8, 0.5, 0.12),
			CFrame = cf * CFrame.new(0, y, -d / 2 - 0.1),
			Kit = "SR_Steel",
			Color = Color3.fromRGB(70, 70, 88),
		}, parent)
		for led = 0, 3 do
			local colors =
				{ Config.Colors.Slime, Color3.fromRGB(61, 200, 255), Config.Colors.Slime, Color3.fromRGB(255, 180, 40) }
			local dot = LabKit.deco({
				Size = Vector3.new(0.14, 0.14, 0.06),
				CFrame = cf * CFrame.new(-w / 2 + 0.7 + led * 0.32, y, -d / 2 - 0.18),
				Color = colors[(row + led) % 4 + 1],
				Material = Enum.Material.Neon,
			}, parent)
			if (row + led) % 2 == 0 then
				CollectionService:AddTag(dot, "Blink")
			end
		end
	end
	LabKit.deco({
		Size = Vector3.new(w + 0.2, 0.3, d + 0.2),
		CFrame = cf * CFrame.new(0, h + 0.15, 0),
		Kit = "SR_Hazard",
		Color = C.Hazard,
	}, parent)
end

-- Sagging cable between two points.
function LabKit.cable(parent: Instance, a: Vector3, b: Vector3, sag: number, color: Color3?)
	local segments = 8
	local last = a
	for i = 1, segments do
		local t = i / segments
		local point = a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * sag, 0)
		local length = (point - last).Magnitude
		LabKit.deco({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(length + 0.1, 0.28, 0.28),
			CFrame = CFrame.lookAt((point + last) / 2, point) * CFrame.Angles(0, math.rad(90), 0),
			Color = color or C.Cable,
			Material = Enum.Material.Rubber,
		}, parent)
		last = point
	end
end

-- Round pressure gauge with a needle (client jitters parts tagged "Needle").
function LabKit.gauge(parent: Instance, cf: CFrame)
	LabKit.deco({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 1.6, 1.6),
		CFrame = cf * CFrame.Angles(0, math.rad(90), 0),
		Kit = "SR_Steel",
		Color = C.Steel,
	}, parent)
	LabKit.deco({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.1, 1.3, 1.3),
		CFrame = cf * CFrame.new(0, 0, -0.22) * CFrame.Angles(0, math.rad(90), 0),
		Color = C.White,
		Material = Enum.Material.SmoothPlastic,
	}, parent)
	local needle = LabKit.deco({
		Name = "Needle",
		Size = Vector3.new(0.08, 0.55, 0.05),
		CFrame = cf * CFrame.new(0, 0.2, -0.3),
		Color = Color3.fromRGB(230, 50, 60),
		Material = Enum.Material.SmoothPlastic,
	}, parent)
	CollectionService:AddTag(needle, "Needle")
end

-- Bolted sign plate with text.
function LabKit.sign(parent: Instance, cf: CFrame, size: Vector2, text: string, color: Color3?, plate: Color3?)
	local p = LabKit.deco(
		{ Size = Vector3.new(size.X, size.Y, 0.25), CFrame = cf, Kit = "SR_Steel", Color = plate or C.Dark },
		parent
	)
	for _, corner in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
		LabKit.deco({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.1, 0.22, 0.22),
			CFrame = cf
				* CFrame.new(corner[1] * (size.X / 2 - 0.3), corner[2] * (size.Y / 2 - 0.25), -0.15)
				* CFrame.Angles(0, math.rad(90), 0),
			Color = C.Steel,
		}, parent)
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.2
	gui.Parent = p
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.9, 0.8)
	label.Position = UDim2.fromScale(0.05, 0.1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.FontFace = Font.fromName("FredokaOne")
	label.TextColor3 = color or Config.Colors.Slime
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(10, 8, 14)
	stroke.Parent = label
	label.Parent = gui
end

-- Row of hex bolts along a line (for seams and plates).
function LabKit.bolts(parent: Instance, from: CFrame, count: number, spacing: number)
	for i = 0, count - 1 do
		LabKit.deco({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.14, 0.3, 0.3),
			CFrame = from * CFrame.new(i * spacing, 0, 0) * CFrame.Angles(0, math.rad(90), 0),
			Color = C.Steel,
			Material = Enum.Material.Metal,
		}, parent)
	end
end

return LabKit
