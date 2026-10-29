--!strict
-- Part-built models for every Mop Base building, in the station style: white panels, dark
-- trim, orange hazard accents, small neon lights. Each model's pivot is the centre of its
-- footprint on the ground, facing -Z (rotation 0), so Base can drop it straight onto a plot.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local WHITE = Color3.fromRGB(226, 230, 236)
local DARK = Color3.fromRGB(44, 48, 56)
local STEEL = Color3.fromRGB(150, 156, 168)
local ORANGE = Color3.fromRGB(255, 132, 28)
local YELLOW = Color3.fromRGB(255, 205, 50)
local TEAL = Color3.fromRGB(64, 224, 208)
local GLASS = Color3.fromRGB(40, 70, 130)

local function box(m: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = m
	return p
end

local function cyl(
	m: Model,
	name: string,
	height: number,
	diameter: number,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local p =
		box(m, name, Vector3.new(height, diameter, diameter), cf * CFrame.Angles(0, 0, math.rad(90)), color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function lamp(parent: BasePart, color: Color3, range: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = 1.2
	l.Shadows = false
	l.Parent = parent
end

local function label(parent: BasePart, text: string, face: Enum.NormalId)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.PixelsPerStud = 30
	g.LightInfluence = 0.5
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.GothamBlack
	t.TextColor3 = DARK
	t.Parent = g
	g.Parent = parent
end

-- Orange and black chevrons along an edge.
local function hazard(m: Model, length: number, cf: CFrame)
	box(m, "Hazard", Vector3.new(length, 0.12, 0.8), cf, Color3.fromRGB(20, 20, 22))
	local n = math.floor(length / 1.6)
	for k = 0, n - 1 do
		local x = -length / 2 + 0.8 + k * 1.6
		local s = box(
			m,
			"Stripe",
			Vector3.new(0.55, 0.14, 0.9),
			cf * CFrame.new(x, 0.01, 0) * CFrame.Angles(0, math.rad(40), 0),
			ORANGE
		)
		s.CanCollide = false
	end
end

local builders: { [string]: (m: Model, size: Vector3) -> () } = {}

builders.Garage = function(m, s)
	local w, h, d = s.X, s.Y, s.Z
	box(m, "Floor", Vector3.new(w, 0.4, d), CFrame.new(0, 0.2, 0), DARK, Enum.Material.Concrete)
	box(m, "Back", Vector3.new(w, h, 1), CFrame.new(0, h / 2, d / 2 - 0.5), WHITE)
	box(m, "Left", Vector3.new(1, h, d), CFrame.new(-w / 2 + 0.5, h / 2, 0), WHITE)
	box(m, "Right", Vector3.new(1, h, d), CFrame.new(w / 2 - 0.5, h / 2, 0), WHITE)
	box(m, "Roof", Vector3.new(w + 1, 1, d + 1), CFrame.new(0, h + 0.5, 0), WHITE)
	box(m, "RoofTrim", Vector3.new(w + 1.2, 0.5, 1.2), CFrame.new(0, h + 0.2, -d / 2), ORANGE)
	box(m, "Header", Vector3.new(w, h * 0.28, 1), CFrame.new(0, h - h * 0.14, -d / 2 + 0.5), WHITE)
	local door = box(
		m,
		"Door",
		Vector3.new(w - 4, 2, 0.6),
		CFrame.new(0, h * 0.72 - 1, -d / 2 + 0.6),
		STEEL,
		Enum.Material.DiamondPlate
	)
	door.CanCollide = false
	local sign = box(m, "Sign", Vector3.new(w * 0.6, 2.6, 0.3), CFrame.new(0, h - h * 0.14, -d / 2 - 0.1), WHITE)
	label(sign, "GARAGE", Enum.NormalId.Front)
	hazard(m, w - 2, CFrame.new(0, 0.42, -d / 2 + 1))
	for k = -1, 1, 2 do
		local light = box(
			m,
			"Light",
			Vector3.new(0.8, 0.5, 0.5),
			CFrame.new(k * (w / 2 - 2), h - 1, -d / 2),
			YELLOW,
			Enum.Material.Neon
		)
		lamp(light, Color3.fromRGB(255, 220, 160), 24)
	end
	-- the console where vehicles are bought and upgraded
	local console = box(m, "Console", Vector3.new(3, 4, 2), CFrame.new(w / 2 - 4, 2, -d / 2 + 4), DARK)
	box(m, "Screen", Vector3.new(2.6, 1.8, 0.2), CFrame.new(w / 2 - 4, 3.4, -d / 2 + 2.95), TEAL, Enum.Material.Neon)
	console:SetAttribute("Anchor", "garage")
end

builders.DropPad = function(m, s)
	cyl(m, "Pad", 0.6, s.X, CFrame.new(0, 0.3, 0), DARK, Enum.Material.DiamondPlate)
	cyl(m, "Ring", 0.7, s.X * 0.75, CFrame.new(0, 0.32, 0), ORANGE, Enum.Material.Neon).Transparency = 0.2
	cyl(m, "Inner", 0.75, s.X * 0.6, CFrame.new(0, 0.33, 0), DARK, Enum.Material.DiamondPlate)
	local chute = box(m, "Chute", Vector3.new(2, 5, 2), CFrame.new(s.X / 2 - 1, 2.5, 0), WHITE)
	chute:SetAttribute("Anchor", "droppad")
	box(m, "ChuteLight", Vector3.new(2.1, 0.4, 2.1), CFrame.new(s.X / 2 - 1, 4.6, 0), ORANGE, Enum.Material.Neon)
end

builders.CollectorPad = function(m, s)
	box(m, "Pad", Vector3.new(s.X, 0.5, s.Z), CFrame.new(0, 0.25, 0), DARK, Enum.Material.DiamondPlate)
	for _, e in { { 0, -1 }, { 0, 1 } } do
		hazard(m, s.X - 1, CFrame.new(0, 0.52, e[2] * (s.Z / 2 - 0.6)))
	end
	local hopper = box(m, "Hopper", Vector3.new(4, 4, 4), CFrame.new(0, 2, s.Z / 2 + 2), WHITE)
	hopper:SetAttribute("Anchor", "collector")
	box(m, "HopperTop", Vector3.new(4.4, 0.6, 4.4), CFrame.new(0, 4.3, s.Z / 2 + 2), ORANGE)
end

builders.PodCannon = function(m, s)
	cyl(m, "Base", 2, s.X, CFrame.new(0, 1, 0), WHITE)
	cyl(m, "Ring", 0.6, s.X + 0.4, CFrame.new(0, 2, 0), ORANGE)
	cyl(m, "Barrel", s.Y - 2, 3.2, CFrame.new(0, 2 + (s.Y - 2) / 2, 0), STEEL, Enum.Material.Metal)
	local muzzle = cyl(m, "Muzzle", 0.6, 3.6, CFrame.new(0, s.Y, 0), ORANGE, Enum.Material.Neon)
	muzzle:SetAttribute("Anchor", "muzzle")
	box(m, "Intake", Vector3.new(4, 2, 2), CFrame.new(0, 1, s.Z / 2), DARK):SetAttribute("Anchor", "input")
end

builders.Belt = function(m, s)
	box(m, "Frame", Vector3.new(s.X, 0.6, s.Z), CFrame.new(0, 0.3, 0), DARK, Enum.Material.Metal)
	box(
		m,
		"Surface",
		Vector3.new(s.X - 0.8, 0.1, s.Z),
		CFrame.new(0, 0.65, 0),
		Color3.fromRGB(30, 32, 36),
		Enum.Material.Fabric
	)
	local arrow = box(
		m,
		"Arrow",
		Vector3.new(1, 0.05, 1),
		CFrame.new(0, 0.71, -0.4) * CFrame.Angles(0, math.rad(45), 0),
		YELLOW,
		Enum.Material.Neon
	)
	arrow.CanCollide = false
	box(m, "RailL", Vector3.new(0.3, 0.4, s.Z), CFrame.new(-s.X / 2 + 0.15, 0.8, 0), ORANGE)
	box(m, "RailR", Vector3.new(0.3, 0.4, s.Z), CFrame.new(s.X / 2 - 0.15, 0.8, 0), ORANGE)
end

local function junction(m: Model, s: Vector3, text: string)
	box(m, "Body", Vector3.new(s.X, s.Y, s.Z), CFrame.new(0, s.Y / 2, 0), WHITE)
	box(m, "Top", Vector3.new(s.X + 0.2, 0.3, s.Z + 0.2), CFrame.new(0, s.Y, 0), ORANGE)
	local face = box(m, "Face", Vector3.new(s.X - 0.6, s.Y - 0.6, 0.1), CFrame.new(0, s.Y / 2, -s.Z / 2 - 0.05), DARK)
	label(face, text, Enum.NormalId.Front)
end
builders.Splitter = function(m, s)
	junction(m, s, "SPLIT")
end
builders.Merger = function(m, s)
	junction(m, s, "MERGE")
end
builders.Lift = function(m, s)
	box(m, "Tower", Vector3.new(s.X, s.Y, s.Z), CFrame.new(0, s.Y / 2, 0), WHITE)
	box(
		m,
		"Ramp",
		Vector3.new(s.X - 0.6, 0.4, s.Z * 1.4),
		CFrame.new(0, s.Y * 0.5, 0) * CFrame.Angles(math.rad(-40), 0, 0),
		DARK
	)
	box(m, "Cap", Vector3.new(s.X + 0.2, 0.4, s.Z + 0.2), CFrame.new(0, s.Y, 0), ORANGE)
end

builders.PodPacker = function(m, s)
	box(m, "Body", Vector3.new(s.X, s.Y - 1, s.Z), CFrame.new(0, (s.Y - 1) / 2, 0), WHITE)
	box(m, "Funnel", Vector3.new(s.X - 1, 1.6, s.Z - 1), CFrame.new(0, s.Y - 0.2, 0), STEEL, Enum.Material.Metal)
	box(m, "Stripe", Vector3.new(s.X + 0.1, 0.6, s.Z + 0.1), CFrame.new(0, s.Y * 0.55, 0), ORANGE)
	box(m, "Out", Vector3.new(2.4, 2, 0.4), CFrame.new(0, 1.2, -s.Z / 2 - 0.1), DARK):SetAttribute("Anchor", "output")
	local intake = box(m, "Intake", Vector3.new(3, 0.5, 3), CFrame.new(0, s.Y + 0.6, 0), YELLOW, Enum.Material.Neon)
	intake:SetAttribute("Anchor", "intake")
end

builders.GlassOven = function(m, s)
	box(m, "Body", Vector3.new(s.X, s.Y, s.Z), CFrame.new(0, s.Y / 2, 0), WHITE)
	local window = box(
		m,
		"Window",
		Vector3.new(s.X * 0.6, s.Y * 0.35, 0.2),
		CFrame.new(0, s.Y * 0.5, -s.Z / 2 - 0.05),
		ORANGE,
		Enum.Material.Neon
	)
	window.Transparency = 0.15
	lamp(window, Color3.fromRGB(255, 140, 60), 14)
	cyl(m, "Chimney", 3, 1.6, CFrame.new(s.X / 2 - 1.6, s.Y + 1.5, s.Z / 2 - 1.6), STEEL, Enum.Material.Metal)
	box(m, "In", Vector3.new(2.4, 2, 0.4), CFrame.new(0, 1.2, s.Z / 2 + 0.1), DARK):SetAttribute("Anchor", "input")
	box(m, "Out", Vector3.new(2.4, 2, 0.4), CFrame.new(0, 1.2, -s.Z / 2 - 0.1), DARK):SetAttribute("Anchor", "output")
	label(
		box(m, "Plate", Vector3.new(s.X * 0.6, 1.2, 0.1), CFrame.new(0, s.Y * 0.85, -s.Z / 2 - 0.05), WHITE),
		"GLASS OVEN",
		Enum.NormalId.Front
	)
end

builders.GemPress = function(m, s)
	box(m, "Base", Vector3.new(s.X, s.Y * 0.35, s.Z), CFrame.new(0, s.Y * 0.175, 0), WHITE)
	box(m, "PostL", Vector3.new(1.2, s.Y, 1.2), CFrame.new(-s.X / 2 + 1, s.Y / 2, 0), DARK)
	box(m, "PostR", Vector3.new(1.2, s.Y, 1.2), CFrame.new(s.X / 2 - 1, s.Y / 2, 0), DARK)
	box(m, "Head", Vector3.new(s.X, 2, s.Z * 0.7), CFrame.new(0, s.Y - 1, 0), ORANGE)
	local ram = box(
		m,
		"Ram",
		Vector3.new(s.X * 0.5, s.Y * 0.35, s.Z * 0.4),
		CFrame.new(0, s.Y * 0.6, 0),
		STEEL,
		Enum.Material.Metal
	)
	ram:SetAttribute("Anchor", "ram")
	local gem = box(
		m,
		"Gem",
		Vector3.new(1.2, 1.2, 1.2),
		CFrame.new(0, s.Y * 0.38, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)),
		Color3.fromRGB(150, 110, 255),
		Enum.Material.Neon
	)
	gem.CanCollide = false
	box(m, "In", Vector3.new(2.4, 2, 0.4), CFrame.new(0, 1.2, s.Z / 2 + 0.1), DARK):SetAttribute("Anchor", "input")
	box(m, "Out", Vector3.new(2.4, 2, 0.4), CFrame.new(0, 1.2, -s.Z / 2 - 0.1), DARK):SetAttribute("Anchor", "output")
end

local function solar(m: Model, s: Vector3, panels: number)
	cyl(m, "Pole", s.Y - 2, 0.6, CFrame.new(0, (s.Y - 2) / 2, 0), STEEL, Enum.Material.Metal)
	for k = 1, panels do
		local x = if panels == 1 then 0 else (k - 1.5) * (s.X / 2)
		local panel = box(
			m,
			"Panel",
			Vector3.new(s.X / panels - 0.2, 0.2, s.Z),
			CFrame.new(x, s.Y - 1, 0) * CFrame.Angles(math.rad(-25), 0, 0),
			GLASS,
			Enum.Material.Glass
		)
		panel:SetAttribute("Anchor", "panel")
		box(
			m,
			"Rim",
			Vector3.new(s.X / panels, 0.15, 0.3),
			CFrame.new(x, s.Y - 1, 0) * CFrame.Angles(math.rad(-25), 0, 0) * CFrame.new(0, 0, -s.Z / 2),
			WHITE
		)
	end
	local led = box(m, "Led", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, s.Y - 2.6, -0.35), TEAL, Enum.Material.Neon)
	led:SetAttribute("Anchor", "power")
end
builders.SolarPost = function(m, s)
	solar(m, s, 1)
end
builders.TwinSolar = function(m, s)
	solar(m, s, 2)
end

builders.Battery = function(m, s)
	box(m, "Body", Vector3.new(s.X, s.Y, s.Z), CFrame.new(0, s.Y / 2, 0), WHITE)
	box(m, "Cap", Vector3.new(s.X * 0.5, 0.6, s.Z * 0.5), CFrame.new(0, s.Y + 0.3, 0), DARK)
	for k = 0, 3 do
		local bar = box(
			m,
			"Charge",
			Vector3.new(s.X * 0.6, 0.7, 0.1),
			CFrame.new(0, 1 + k * 1.1, -s.Z / 2 - 0.05),
			TEAL,
			Enum.Material.Neon
		)
		bar:SetAttribute("Level", k + 1)
	end
	local led = box(m, "Led", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, s.Y + 0.8, 0), TEAL, Enum.Material.Neon)
	led:SetAttribute("Anchor", "power")
end

local function dock(m: Model, s: Vector3, color: Color3, text: string)
	cyl(m, "Dock", 0.8, s.X, CFrame.new(0, 0.4, 0), DARK, Enum.Material.DiamondPlate)
	cyl(m, "Ring", 0.85, s.X * 0.8, CFrame.new(0, 0.42, 0), color, Enum.Material.Neon).Transparency = 0.3
	local mast = box(m, "Mast", Vector3.new(0.6, 3, 0.6), CFrame.new(s.X / 2 - 0.8, 1.9, 0), WHITE)
	mast:SetAttribute("Anchor", "dock")
	label(
		box(m, "Tag", Vector3.new(2.4, 0.8, 0.1), CFrame.new(s.X / 2 - 0.8, 3, -0.35), WHITE),
		text,
		Enum.NormalId.Front
	)
end
builders.DotBotMk1 = function(m, s)
	dock(m, s, TEAL, "MK1")
end
builders.DotBotMk2 = function(m, s)
	dock(m, s, YELLOW, "MK2")
end
builders.CosmicOcto = function(m, s)
	dock(m, s, Color3.fromRGB(150, 110, 255), "OCTO")
end

builders.PodCatcher = function(m, s)
	cyl(m, "Base", 1, s.X, CFrame.new(0, 0.5, 0), WHITE)
	local net =
		cyl(m, "Net", 0.3, s.X * 0.9, CFrame.new(0, s.Y, 0), Color3.fromRGB(80, 200, 255), Enum.Material.ForceField)
	net:SetAttribute("Anchor", "catch")
	for k = 0, 3 do
		local a = math.rad(45 + 90 * k)
		box(
			m,
			"Arm",
			Vector3.new(0.6, s.Y, 0.6),
			CFrame.new(math.cos(a) * s.X * 0.4, s.Y / 2, math.sin(a) * s.X * 0.4),
			STEEL,
			Enum.Material.Metal
		)
	end
	box(m, "Out", Vector3.new(2.4, 2, 0.4), CFrame.new(0, 1.2, -s.Z / 2 - 0.1), DARK):SetAttribute("Anchor", "output")
end

builders.Lamp = function(m, s)
	box(m, "Pole", Vector3.new(0.4, s.Y, 0.4), CFrame.new(0, s.Y / 2, 0), STEEL, Enum.Material.Metal)
	local head = box(m, "Head", Vector3.new(1.6, 0.8, 1.6), CFrame.new(0, s.Y, 0), WHITE)
	local bulb = box(
		m,
		"Bulb",
		Vector3.new(1.2, 0.2, 1.2),
		CFrame.new(0, s.Y - 0.5, 0),
		Color3.fromRGB(255, 240, 210),
		Enum.Material.Neon
	)
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Bottom
	spot.Angle = 100
	spot.Range = 40
	spot.Brightness = 2
	spot.Parent = bulb
	head:SetAttribute("Anchor", "lamp")
end

builders.Flagpole = function(m, s)
	box(m, "Pole", Vector3.new(0.3, s.Y, 0.3), CFrame.new(0, s.Y / 2, 0), STEEL, Enum.Material.Metal)
	box(m, "Cloth", Vector3.new(4, 2.4, 0.1), CFrame.new(2.1, s.Y - 1.4, 0), ORANGE, Enum.Material.Fabric)
	box(m, "Band", Vector3.new(4, 0.6, 0.12), CFrame.new(2.1, s.Y - 1.4, 0), WHITE, Enum.Material.Fabric)
end

-- Build a building model. Rotation and placement are up to the caller (PivotTo).
local function build(id: string): Model
	local def: Config.BuildDef? = nil
	for _, b in Config.Buildings do
		if b.id == id then
			def = b
		end
	end
	assert(def, "unknown building " .. id)
	local m = Instance.new("Model")
	m.Name = id
	local fn = builders[id]
	if fn then
		fn(m, def.size)
	else
		box(m, "Body", def.size, CFrame.new(0, def.size.Y / 2, 0), WHITE)
	end
	m.WorldPivot = CFrame.identity
	return m
end

return build
