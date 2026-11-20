--!strict
-- Builds the dock map from DockLayout's pure plan (map rulebook M1-M44).
-- Runs at server start, or at edit time via Studio MCP `execute_luau`
-- (require this module and call build) so Scenic can bake and then polish.
--
-- Every piece here is a PART PLACEHOLDER (rule M18: parts are greybox only).
-- Each carries the attribute PlaceholderFor = <kit piece> so the mesh pass can
-- swap it for a Blender kit mesh at the same CFrame and size.
--
-- Engine APIs used (all on https://create.roblox.com/docs/reference/engine):
-- Terrain:FillBlock(CFrame, Vector3, Material), Terrain:FillCylinder(CFrame,
-- height, radius, Material) (axis = Y), Terrain:FillBall(Vector3, radius,
-- Material); Part.Shape Cylinder (axis = X, rule M19); PointLight, SpotLight,
-- SurfaceGui + TextLabel, TweenService:Create.
-- NOT yet run in Studio (Mac offline 2026-11-19): verify with a playtest and
-- the fixed-station screenshots in docs/VISUAL_QA.md before calling it done.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local DockLayout = require(Shared:WaitForChild("DockLayout"))

local DockBuilder = {}

type Placement = DockLayout.Placement
type Rope = DockLayout.Rope

local PALETTE = {
	Wood = Color3.fromRGB(122, 86, 56),
	WoodDark = Color3.fromRGB(78, 56, 40),
	WoodPale = Color3.fromRGB(168, 132, 92),
	Iron = Color3.fromRGB(58, 60, 66),
	Rope = Color3.fromRGB(196, 170, 120),
	Canvas = Color3.fromRGB(226, 214, 188),
	Accent = Color3.fromRGB(255, 96, 31), -- M33: the one saturated colour (theme orange)
	LanternGlow = Color3.fromRGB(255, 176, 92),
	Stone = Color3.fromRGB(150, 146, 140),
	Whitewash = Color3.fromRGB(236, 232, 224),
	Red = Color3.fromRGB(176, 44, 38),
	Fruit = Color3.fromRGB(122, 52, 168),
}

local function cf(p: Placement): CFrame
	return CFrame.new(p.pos.x, p.pos.y, p.pos.z)
		* CFrame.Angles(0, math.rad(p.yaw), 0)
		* CFrame.Angles(math.rad(p.tilt), 0, 0)
end

local function new(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	micro: boolean
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if micro then
		-- M22: micro props never block, never get queried, cast no shadow
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
	end
	part.Parent = parent
	return part
end

-- Cylinder whose round axis is world-up. Part cylinders run along X (M19),
-- so roll by 90 degrees about Z.
local function upright(cframe: CFrame): CFrame
	return cframe * CFrame.Angles(0, 0, math.rad(90))
end

local function vec(s: DockLayout.Vec3): Vector3
	return Vector3.new(s.x, s.y, s.z)
end

local function lightOn(part: BasePart, color: Color3, range: number, brightness: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = part
end

-- Kit: one builder per piece kind. Each returns the model it made.
local Kit: { [string]: (Placement, Instance) -> Instance } = {}

local function model(p: Placement, parent: Instance): Model
	local m = Instance.new("Model")
	m.Name = p.kind
	m:SetAttribute("PlaceholderFor", p.kind)
	m:SetAttribute("Why", p.why)
	if p.group then
		m:SetAttribute("StoryGroup", p.group)
	end
	m.Parent = parent
	return m
end

Kit.Deck = function(p, parent)
	local m = model(p, parent)
	local s = vec(p.size)
	-- planks as strips so the floor is a canvas, not one slab (M37)
	local plankW = 2
	local count = math.floor(s.X / plankW)
	for i = 0, count - 1 do
		local x = p.pos.x - s.X / 2 + plankW * (i + 0.5)
		local shade = if i % 3 == 0 then PALETTE.WoodDark elseif i % 3 == 1 then PALETTE.Wood else PALETTE.WoodPale
		local plank = new(
			m,
			"Plank",
			Vector3.new(plankW - 0.12, s.Y, s.Z),
			CFrame.new(x, p.pos.y, p.pos.z),
			shade,
			Enum.Material.WoodPlanks,
			false
		)
		plank.CastShadow = true
	end
	-- cross beams underneath, seen from the water
	for z = p.pos.z - s.Z / 2 + 4, p.pos.z + s.Z / 2, 8 do
		new(
			m,
			"Joist",
			Vector3.new(s.X + 1, 0.8, 0.8),
			CFrame.new(p.pos.x, p.pos.y - s.Y / 2 - 0.4, z),
			PALETTE.WoodDark,
			Enum.Material.Wood,
			true
		)
	end
	return m
end

Kit.EdgeTrim = function(p, parent)
	local m = model(p, parent)
	new(m, "Trim", vec(p.size), cf(p), PALETTE.WoodDark, Enum.Material.Wood, true)
	return m
end

Kit.ThrowLine = function(p, parent)
	local m = model(p, parent)
	new(m, "Paint", vec(p.size), cf(p), PALETTE.Accent, Enum.Material.SmoothPlastic, true)
	return m
end

Kit.Piling = function(p, parent)
	local m = model(p, parent)
	local s = vec(p.size)
	new(m, "Post", Vector3.new(s.Y, s.X, s.X), upright(cf(p)), PALETTE.WoodDark, Enum.Material.Wood, false)
	-- M35 trim: iron band near the top and a cap
	local top = cf(p) * CFrame.new(0, s.Y / 2 - 1.2, 0)
	new(m, "Band", Vector3.new(0.35, s.X + 0.2, s.X + 0.2), upright(top), PALETTE.Iron, Enum.Material.Metal, true)
	new(
		m,
		"Cap",
		Vector3.new(0.4, s.X + 0.4, s.X + 0.4),
		upright(cf(p) * CFrame.new(0, s.Y / 2, 0)),
		PALETTE.Wood,
		Enum.Material.Wood,
		true
	)
	return m
end

Kit.Lantern = function(p, parent)
	local m = model(p, parent)
	local base = cf(p)
	new(m, "Frame", Vector3.new(1, 0.25, 1), base * CFrame.new(0, -0.8, 0), PALETTE.Iron, Enum.Material.Metal, true)
	local glass = new(m, "Glow", Vector3.new(0.8, 1.2, 0.8), base, PALETTE.LanternGlow, Enum.Material.Neon, true)
	new(m, "Roof", Vector3.new(1.1, 0.3, 1.1), base * CFrame.new(0, 0.75, 0), PALETTE.Iron, Enum.Material.Metal, true)
	lightOn(glass, PALETTE.LanternGlow, 14, 1.4)
	return m
end

Kit.HangingLantern = function(p, parent)
	local m = Kit.Lantern(p, parent)
	local s = vec(p.size)
	local cord = DockLayout.LanternCord
	new(
		m,
		"Cord",
		Vector3.new(0.08, cord, 0.08),
		cf(p) * CFrame.new(0, s.Y / 2 + cord / 2, 0),
		PALETTE.Rope,
		Enum.Material.Fabric,
		true
	)
	return m
end

Kit.BuntingPole = function(p, parent)
	local m = model(p, parent)
	local s = vec(p.size)
	new(m, "Pole", Vector3.new(s.Y, s.X, s.X), upright(cf(p)), PALETTE.Wood, Enum.Material.Wood, false)
	return m
end

local function box(p: Placement, parent: Instance, color: Color3, material: Enum.Material): Model
	local m = model(p, parent)
	new(m, p.kind, vec(p.size), cf(p), color, material, true)
	return m
end

Kit.Crate = function(p, parent)
	local m = box(p, parent, PALETTE.WoodPale, Enum.Material.WoodPlanks)
	local s = vec(p.size)
	-- M35 edge battens so a crate is not a bare cube
	for _, y in { -1, 1 } do
		new(
			m,
			"Batten",
			Vector3.new(s.X + 0.1, 0.3, s.Z + 0.1),
			cf(p) * CFrame.new(0, y * (s.Y / 2 - 0.3), 0),
			PALETTE.WoodDark,
			Enum.Material.Wood,
			true
		)
	end
	return m
end

Kit.FruitCrateOpen = function(p, parent)
	local m = box(p, parent, PALETTE.WoodPale, Enum.Material.WoodPlanks)
	local s = vec(p.size)
	-- lid knocked askew + spilled fruit: "caught mid-task" (M38)
	new(
		m,
		"Lid",
		Vector3.new(s.X, 0.25, s.Z),
		cf(p) * CFrame.new(s.X * 0.4, s.Y / 2 + 0.6, 0) * CFrame.Angles(0, 0, math.rad(28)),
		PALETTE.WoodPale,
		Enum.Material.WoodPlanks,
		true
	)
	for i = 1, 4 do
		local ball = new(
			m,
			"Fruit",
			Vector3.new(0.9, 0.9, 0.9),
			cf(p) * CFrame.new(-s.X / 2 - 0.4 * i, -s.Y / 2 + 0.45, (i - 2) * 0.7),
			PALETTE.Fruit,
			Enum.Material.SmoothPlastic,
			true
		)
		ball.Shape = Enum.PartType.Ball
	end
	return m
end

local function cylinderProp(p: Placement, parent: Instance, color: Color3, material: Enum.Material): Model
	local m = model(p, parent)
	local s = vec(p.size)
	new(m, p.kind, Vector3.new(s.Y, s.X, s.Z), upright(cf(p)), color, material, true)
	return m
end

Kit.Barrel = function(p, parent)
	local m = cylinderProp(p, parent, PALETTE.Wood, Enum.Material.Wood)
	local s = vec(p.size)
	for _, y in { -0.3, 0.3 } do
		new(
			m,
			"Hoop",
			Vector3.new(0.2, s.X + 0.08, s.X + 0.08),
			upright(cf(p) * CFrame.new(0, y * s.Y, 0)),
			PALETTE.Iron,
			Enum.Material.Metal,
			true
		)
	end
	return m
end

Kit.Bucket = function(p, parent)
	return cylinderProp(p, parent, PALETTE.WoodDark, Enum.Material.Wood)
end
Kit.Stool = function(p, parent)
	return cylinderProp(p, parent, PALETTE.Wood, Enum.Material.Wood)
end
Kit.RopeCoil = function(p, parent)
	return cylinderProp(p, parent, PALETTE.Rope, Enum.Material.Fabric)
end
Kit.Basket = function(p, parent)
	return cylinderProp(p, parent, PALETTE.WoodPale, Enum.Material.Fabric)
end
Kit.NetPile = function(p, parent)
	return box(p, parent, Color3.fromRGB(92, 110, 96), Enum.Material.Fabric)
end
Kit.LanternDown = function(p, parent)
	local m = box(p, parent, PALETTE.Iron, Enum.Material.Metal)
	return m
end

Kit.Handcart = function(p, parent)
	local m = model(p, parent)
	local s = vec(p.size)
	new(
		m,
		"Bed",
		Vector3.new(s.X, 0.5, s.Z),
		cf(p) * CFrame.new(0, -s.Y / 2 + 1.4, 0),
		PALETTE.Wood,
		Enum.Material.WoodPlanks,
		true
	)
	for _, side in { -1, 1 } do
		local wheel = new(
			m,
			"Wheel",
			Vector3.new(0.4, 2.2, 2.2),
			cf(p) * CFrame.new(side * (s.X / 2 + 0.2), -s.Y / 2 + 1.1, 0),
			PALETTE.WoodDark,
			Enum.Material.Wood,
			true
		)
		wheel.Shape = Enum.PartType.Cylinder
	end
	return m
end

Kit.ShipHull = function(p, parent)
	local m = model(p, parent)
	local s = vec(p.size)
	new(m, "Hull", s, cf(p), PALETTE.WoodDark, Enum.Material.WoodPlanks, false)
	new(
		m,
		"Rail",
		Vector3.new(s.X + 0.6, 1, s.Z + 0.6),
		cf(p) * CFrame.new(0, s.Y / 2 + 0.5, 0),
		PALETTE.Wood,
		Enum.Material.Wood,
		true
	)
	new(m, "Stripe", Vector3.new(s.X + 0.2, 0.8, s.Z + 0.2), cf(p), PALETTE.Red, Enum.Material.Wood, true)
	return m
end

Kit.Mast = function(p, parent)
	local m = model(p, parent)
	local s = vec(p.size)
	new(m, "Mast", Vector3.new(s.Y, s.X, s.X), upright(cf(p)), PALETTE.Wood, Enum.Material.Wood, false)
	return m
end

Kit.Sail = function(p, parent)
	local m = model(p, parent)
	new(m, "Sail", vec(p.size), cf(p), PALETTE.Accent, Enum.Material.Fabric, true)
	return m
end

Kit.Hut = function(p, parent)
	local m = model(p, parent)
	local s = vec(p.size)
	new(m, "Walls", s, cf(p), PALETTE.Whitewash, Enum.Material.Plaster, false)
	local roof = new(
		m,
		"Roof",
		Vector3.new(s.X + 1.5, s.Y * 0.5, s.Z + 1.5),
		cf(p) * CFrame.new(0, s.Y * 0.75, 0),
		PALETTE.Red,
		Enum.Material.Slate,
		false
	)
	roof.Shape = Enum.PartType.Wedge
	local window = new(
		m,
		"Window",
		Vector3.new(2, 2, 0.2),
		cf(p) * CFrame.new(0, 0.5, -s.Z / 2 - 0.1),
		PALETTE.LanternGlow,
		Enum.Material.Neon,
		true
	)
	window.Transparency = 0.2
	return m
end

Kit.Buoy = function(p, parent)
	local m = model(p, parent)
	local s = vec(p.size)
	local body =
		new(m, "Body", Vector3.new(s.Y * 0.6, s.X, s.X), upright(cf(p)), PALETTE.Red, Enum.Material.SmoothPlastic, true)
	body.CanQuery = true -- fruit can bonk it
	local lamp = new(
		m,
		"Lamp",
		Vector3.new(0.8, 0.8, 0.8),
		cf(p) * CFrame.new(0, s.Y / 2, 0),
		PALETTE.LanternGlow,
		Enum.Material.Neon,
		true
	)
	lightOn(lamp, PALETTE.LanternGlow, 10, 1)
	return m
end

Kit.DistanceBoard = function(p, parent)
	local m = model(p, parent)
	local s = vec(p.size)
	local board = new(m, "Board", s, cf(p), PALETTE.WoodPale, Enum.Material.WoodPlanks, true)
	new(
		m,
		"Post",
		Vector3.new(0.6, p.pos.y - Config.Dock.SeabedY, 0.6),
		CFrame.new(p.pos.x, (p.pos.y + Config.Dock.SeabedY) / 2 - s.Y / 2, p.pos.z),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		true
	)
	-- painted number facing the thrower (+Z side)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(400, 200)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(40, 28, 20)
	label.Text = p.why .. " m"
	label.Parent = gui
	gui.Parent = board
	return m
end

Kit.SeaStack = function(p, parent)
	local m = model(p, parent)
	-- terrain rock, so it blends into the water line like a real stack
	local s = vec(p.size)
	workspace.Terrain:FillBlock(cf(p), s, Enum.Material.Rock)
	workspace.Terrain:FillBall(
		Vector3.new(p.pos.x, p.pos.y + s.Y / 2 - 2, p.pos.z),
		math.min(s.X, s.Z) * 0.55,
		Enum.Material.Grass
	)
	return m
end

Kit.Lighthouse = function(p, parent)
	local m = model(p, parent)
	local s = vec(p.size)
	-- tapered tower in drums, red and white bands (M8: unique colour)
	local drums = 6
	for i = 0, drums - 1 do
		local h = s.Y / drums
		local w = s.X * (1 - 0.06 * i)
		new(
			m,
			"Drum" .. i,
			Vector3.new(h, w, w),
			upright(CFrame.new(p.pos.x, p.pos.y - s.Y / 2 + h * (i + 0.5), p.pos.z)),
			if i % 2 == 0 then PALETTE.Whitewash else PALETTE.Red,
			Enum.Material.Plaster,
			false
		)
	end
	new(
		m,
		"Gallery",
		Vector3.new(1, s.X * 0.95, s.X * 0.95),
		upright(CFrame.new(p.pos.x, p.pos.y + s.Y / 2, p.pos.z)),
		PALETTE.Iron,
		Enum.Material.Metal,
		false
	)
	return m
end

Kit.LighthouseLamp = function(p, parent)
	local m = model(p, parent)
	local s = vec(p.size)
	local lamp = new(m, "Lamp", s * 0.6, cf(p), PALETTE.LanternGlow, Enum.Material.Neon, true)
	lamp.Shape = Enum.PartType.Ball
	lightOn(lamp, PALETTE.LanternGlow, 60, 3)
	new(
		m,
		"Cupola",
		Vector3.new(s.X, 1.2, s.Z),
		cf(p) * CFrame.new(0, s.Y * 0.45, 0),
		PALETTE.Red,
		Enum.Material.Metal,
		true
	)
	-- M8: motion pulls hardest. A turning beam (SpotLight on a spinning hub).
	local hub = new(m, "BeamHub", Vector3.new(1, 1, 1), cf(p), PALETTE.LanternGlow, Enum.Material.Neon, true)
	hub.Transparency = 1
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Front
	spot.Angle = 18
	spot.Range = 60
	spot.Brightness = 6
	spot.Color = PALETTE.LanternGlow
	spot.Parent = hub
	local spin = TweenService:Create(
		hub,
		TweenInfo.new(Config.Dock.LighthouseSpinSeconds, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{ CFrame = hub.CFrame * CFrame.Angles(0, math.rad(-359.9), 0) }
	)
	spin:Play()
	return m
end

-- Ropes, bunting, rigging: short cylinder segments along the sag curve (M40).
local function buildRope(r: Rope, parent: Instance)
	local folder = Instance.new("Model")
	folder.Name = r.kind
	folder:SetAttribute("PlaceholderFor", r.kind)
	folder:SetAttribute("Why", r.why)
	folder.Parent = parent
	for i = 2, #r.points do
		local a, b = vec(r.points[i - 1]), vec(r.points[i])
		local len = (b - a).Magnitude
		if len < 0.01 then
			continue
		end
		-- cylinder axis is X, so look along the segment then turn X onto it
		local segment = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
		local part = new(
			folder,
			"Segment",
			Vector3.new(len + r.thickness * 0.5, r.thickness, r.thickness),
			segment,
			PALETTE.Rope,
			Enum.Material.Fabric,
			true
		)
		part.Shape = Enum.PartType.Cylinder
		if r.kind == "Bunting" and i % 2 == 0 then
			local flag = new(
				folder,
				"Flag",
				Vector3.new(0.1, 1.2, 1),
				CFrame.new(a.X, a.Y - 0.7, a.Z) * CFrame.Angles(0, math.rad(90), 0),
				if i % 4 == 0 then PALETTE.Accent else PALETTE.Canvas,
				Enum.Material.Fabric,
				true
			)
			flag.Shape = Enum.PartType.Wedge
		end
	end
end

local function terrainOp(op: DockLayout.TerrainOp)
	local terrain = workspace.Terrain
	-- any: Enum.Material indexed by a name from the plan; pcall guards typos.
	local ok, mat = pcall(function()
		return (Enum.Material :: any)[op.material]
	end)
	local material: Enum.Material = if ok and mat then mat else Enum.Material.Rock
	local centre = CFrame.new(op.pos.x, op.pos.y, op.pos.z) * CFrame.Angles(0, math.rad(op.yaw), 0)
	if op.shape == "Block" then
		terrain:FillBlock(centre, vec(op.size), material)
	elseif op.shape == "Cylinder" then
		terrain:FillCylinder(centre, op.size.y, op.size.x / 2, material)
	else
		terrain:FillBall(centre.Position, op.size.x / 2, material)
	end
end

-- Builds the whole map under workspace.Map/<Area>/<Tier> (M22) and returns
-- the throw origin CFrame (looking down the lane, -Z).
function DockBuilder.build(): CFrame
	local cfg = Config.Dock
	local plan = DockLayout.plan(cfg)

	local old = workspace:FindFirstChild("Map")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = "Map"
	root.Parent = workspace

	local folders: { [string]: Folder } = {}
	local function folderFor(area: string, tier: string): Folder
		local key = area .. "/" .. tier
		local existing = folders[key]
		if existing then
			return existing
		end
		local found = root:FindFirstChild(area)
		local areaFolder: Instance
		if found then
			areaFolder = found
		else
			local made = Instance.new("Folder")
			made.Name = area
			made.Parent = root
			areaFolder = made
		end
		local f = Instance.new("Folder")
		f.Name = tier
		f.Parent = areaFolder
		folders[key] = f
		return f
	end

	for _, op in plan.terrain do
		terrainOp(op)
	end
	for _, p in plan.placements do
		local make = Kit[p.kind]
		if make then
			make(p, folderFor(p.area, p.tier))
		else
			warn(`DockBuilder: no kit piece for {p.kind}`)
		end
	end
	for _, r in plan.ropes do
		buildRope(r, folderFor(r.area, r.tier))
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = CFrame.new(0, cfg.DeckHeight + 0.5, cfg.ThrowEdgeZ + 18)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Parent = folderFor("Pier", "Gameplay")

	local o = plan.throwOrigin
	return CFrame.lookAt(Vector3.new(o.x, o.y, o.z), Vector3.new(o.x, o.y, o.z - 100))
end

return DockBuilder
