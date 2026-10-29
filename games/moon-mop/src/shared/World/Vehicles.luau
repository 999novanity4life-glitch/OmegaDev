--!strict
-- Part-built vehicles. One builder per vehicle id, sized from Config: a chassis, wheels or hover
-- skirts, a cab with a seat, a dust tank, and for cleaners a brush roller across the front as
-- wide as the vehicle cleans. Everything is welded to an unanchored "Body" part (the assembly
-- root) that the driver's client moves; visual parts are massless and don't collide.
-- Pivot = Body, at the vehicle's centre, rest height above the ground; facing -Z.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local WHITE = Color3.fromRGB(226, 230, 236)
local DARK = Color3.fromRGB(40, 44, 52)
local STEEL = Color3.fromRGB(150, 156, 168)
local ORANGE = Color3.fromRGB(255, 132, 28)
local YELLOW = Color3.fromRGB(255, 205, 50)
local TEAL = Color3.fromRGB(64, 224, 208)
local RUST = Color3.fromRGB(150, 92, 52)

local function def(id: string): Config.VehicleDef
	for _, v in Config.Vehicles do
		if v.id == id then
			return v
		end
	end
	error("unknown vehicle " .. id)
end

type Kit = {
	m: Model,
	body: Part,
	box: (name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?) -> Part,
	cyl: (name: string, length: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?) -> Part,
	ball: (name: string, d: number, cf: CFrame, color: Color3, material: Enum.Material?) -> Part,
}

local function kit(m: Model, body: Part): Kit
	local function attach(p: Part)
		p.Anchored = false
		p.Massless = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		local w = Instance.new("WeldConstraint")
		w.Part0 = body
		w.Part1 = p
		w.Parent = p
		p.Parent = m
	end
	local k = {} :: Kit
	k.m = m
	k.body = body
	k.box = function(name, size, cf, color, material)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		attach(p)
		return p
	end
	k.cyl = function(name, length, diameter, cf, color, material)
		-- cylinder axis along the frame's X (wheels, rollers)
		local p = k.box(name, Vector3.new(length, diameter, diameter), cf, color, material)
		p.Shape = Enum.PartType.Cylinder
		return p
	end
	k.ball = function(name, d, cf, color, material)
		local p = k.box(name, Vector3.one * d, cf, color, material)
		p.Shape = Enum.PartType.Ball
		return p
	end
	return k
end

local function headlights(k: Kit, x: number, y: number, z: number)
	for side = -1, 1, 2 do
		local lamp = k.box(
			"Headlight",
			Vector3.new(0.8, 0.6, 0.3),
			CFrame.new(side * x, y, z),
			Color3.fromRGB(255, 244, 214),
			Enum.Material.Neon
		)
		local spot = Instance.new("SpotLight")
		spot.Name = "Beam"
		spot.Face = Enum.NormalId.Front
		spot.Range = 50
		spot.Angle = 60
		spot.Brightness = 3
		spot.Enabled = false
		spot.Parent = lamp
	end
end

local function brush(k: Kit, width: number, y: number, z: number, d: number)
	if width <= 0 then
		return
	end
	k.cyl("Roller", width, d, CFrame.new(0, y, z), ORANGE, Enum.Material.Fabric)
	k.box("RollerHood", Vector3.new(width + 0.4, 0.4, d * 0.8), CFrame.new(0, y + d * 0.55, z), DARK)
	for side = -1, 1, 2 do
		k.box(
			"RollerArm",
			Vector3.new(0.4, d * 0.9, 1.6),
			CFrame.new(side * (width / 2 + 0.2), y + 0.2, z + 0.6),
			STEEL,
			Enum.Material.Metal
		)
	end
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "Dust"
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(Color3.fromRGB(200, 200, 205))
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.4) })
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	dust.Lifetime = NumberRange.new(0.6, 1.2)
	dust.Speed = NumberRange.new(2, 5)
	dust.SpreadAngle = Vector2.new(40, 40)
	dust.Rate = 0
	dust.Parent = k.m:FindFirstChild("Roller")
end

local function wheels(k: Kit, w: number, l: number, d: number, color: Color3)
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			local cf = CFrame.new(x * (w / 2 + 0.1), -0.2, z * (l / 2 - d / 2))
			k.cyl("Wheel", d * 0.45, d, cf, DARK, Enum.Material.Rubber)
			k.cyl("Hub", d * 0.47, d * 0.45, cf, color, Enum.Material.Metal)
		end
	end
end

local builders: { [string]: (k: Kit, v: Config.VehicleDef) -> () } = {}

-- A rusty push cart: a bin on four little wheels with a handle bar and a broom head out front.
builders.PushCart = function(k, v)
	local s = v.size
	k.box(
		"Bin",
		Vector3.new(s.X * 0.8, s.Y * 0.45, s.Z * 0.6),
		CFrame.new(0, 0.6, 0.6),
		RUST,
		Enum.Material.CorrodedMetal
	)
	k.box(
		"Rim",
		Vector3.new(s.X * 0.84, 0.25, s.Z * 0.64),
		CFrame.new(0, 0.6 + s.Y * 0.23, 0.6),
		STEEL,
		Enum.Material.Metal
	)
	k.box("Handle", Vector3.new(s.X * 0.7, 0.25, 0.25), CFrame.new(0, 2.4, s.Z / 2), STEEL, Enum.Material.Metal)
	for side = -1, 1, 2 do
		k.box(
			"HandleBar",
			Vector3.new(0.25, 2, 0.25),
			CFrame.new(side * s.X * 0.35, 1.5, s.Z / 2 - 0.4),
			STEEL,
			Enum.Material.Metal
		)
	end
	wheels(k, s.X * 0.75, s.Z * 0.75, 1.2, STEEL)
	brush(k, v.width, -0.6, -s.Z / 2 + 0.2, 1)
	k.box("Seat", Vector3.new(1.6, 0.3, 1.4), CFrame.new(0, 1.4, 1.8), DARK).Name = "Seat"
end

-- Ride-on sweeper: a rounded white body, an orange stripe, a seat under a roll bar, a big roller.
local function rideOn(k: Kit, v: Config.VehicleDef, roof: boolean)
	local s = v.size
	k.box("Chassis", Vector3.new(s.X * 0.8, s.Y * 0.3, s.Z * 0.85), CFrame.new(0, -0.2, 0), WHITE)
	k.box("Stripe", Vector3.new(s.X * 0.82, s.Y * 0.08, s.Z * 0.86), CFrame.new(0, 0.1, 0), ORANGE)
	k.box("Hood", Vector3.new(s.X * 0.7, s.Y * 0.22, s.Z * 0.3), CFrame.new(0, s.Y * 0.2, -s.Z * 0.24), WHITE)
	local tank = k.ball(
		"Tank",
		s.X * 0.55,
		CFrame.new(0, s.Y * 0.32, s.Z * 0.28),
		Color3.fromRGB(170, 190, 210),
		Enum.Material.Glass
	)
	tank.Transparency = 0.3
	k.cyl("TankBand", s.X * 0.56, s.X * 0.3, CFrame.new(0, s.Y * 0.32, s.Z * 0.28), ORANGE)
	k.box("Seat", Vector3.new(1.8, 0.4, 1.8), CFrame.new(0, s.Y * 0.18, 0), DARK)
	k.box("SeatBack", Vector3.new(1.8, 1.6, 0.4), CFrame.new(0, s.Y * 0.35, 0.9), DARK)
	k.box(
		"Wheel",
		Vector3.new(0.3, 1.6, 0.3),
		CFrame.new(0, s.Y * 0.36, -1.4) * CFrame.Angles(math.rad(-30), 0, 0),
		STEEL
	)
	for side = -1, 1, 2 do
		k.box(
			"RollBar",
			Vector3.new(0.3, s.Y * 0.7, 0.3),
			CFrame.new(side * s.X * 0.32, s.Y * 0.45, 0.6),
			STEEL,
			Enum.Material.Metal
		)
	end
	k.box("RollTop", Vector3.new(s.X * 0.66, 0.3, 0.3), CFrame.new(0, s.Y * 0.8, 0.6), STEEL, Enum.Material.Metal)
	if roof then
		k.box("Roof", Vector3.new(s.X * 0.7, 0.3, s.Z * 0.3), CFrame.new(0, s.Y * 0.82, 0.2), WHITE)
	end
	local beacon =
		k.box("Beacon", Vector3.new(0.6, 0.5, 0.6), CFrame.new(0, s.Y * 0.88, 0.6), ORANGE, Enum.Material.Neon)
	beacon:SetAttribute("Blink", true)
	wheels(k, s.X * 0.82, s.Z * 0.8, s.Y * 0.32, ORANGE)
	brush(k, v.width, -s.Y * 0.18, -s.Z / 2, s.Y * 0.28)
	headlights(k, s.X * 0.25, s.Y * 0.2, -s.Z * 0.4)
end

builders.SitSweeper = function(k, v)
	rideOn(k, v, false)
end

-- Crew shuttle: a long hover van with windows and six seats, no brush.
builders.CrewShuttle = function(k, v)
	local s = v.size
	k.box("Hull", Vector3.new(s.X * 0.9, s.Y * 0.55, s.Z * 0.9), CFrame.new(0, s.Y * 0.05, 0), WHITE)
	k.box("Nose", Vector3.new(s.X * 0.86, s.Y * 0.35, s.Z * 0.2), CFrame.new(0, -s.Y * 0.05, -s.Z * 0.5), WHITE)
	k.box("Stripe", Vector3.new(s.X * 0.92, s.Y * 0.08, s.Z * 0.92), CFrame.new(0, -s.Y * 0.08, 0), ORANGE)
	for side = -1, 1, 2 do
		k.box(
			"Windows",
			Vector3.new(0.1, s.Y * 0.18, s.Z * 0.7),
			CFrame.new(side * s.X * 0.45, s.Y * 0.2, 0),
			Color3.fromRGB(40, 70, 130),
			Enum.Material.Glass
		)
		local skirt = k.box(
			"Skirt",
			Vector3.new(0.6, 0.6, s.Z * 0.85),
			CFrame.new(side * s.X * 0.4, -s.Y * 0.25, 0),
			TEAL,
			Enum.Material.Neon
		)
		skirt.Transparency = 0.2
	end
	k.box(
		"Windscreen",
		Vector3.new(s.X * 0.8, s.Y * 0.2, 0.2),
		CFrame.new(0, s.Y * 0.2, -s.Z * 0.45),
		Color3.fromRGB(40, 70, 130),
		Enum.Material.Glass
	)
	k.box("Seat", Vector3.new(1.8, 0.4, 1.8), CFrame.new(0, -s.Y * 0.05, -s.Z * 0.3), DARK)
	headlights(k, s.X * 0.32, -s.Y * 0.05, -s.Z * 0.6)
end

-- Big tracked sweepers: a cab up front, a huge tank behind, a full-width roller.
local function giant(k: Kit, v: Config.VehicleDef, twinTank: boolean)
	local s = v.size
	k.box(
		"Deck",
		Vector3.new(s.X * 0.8, s.Y * 0.2, s.Z * 0.9),
		CFrame.new(0, -s.Y * 0.1, 0),
		DARK,
		Enum.Material.DiamondPlate
	)
	for side = -1, 1, 2 do
		k.box(
			"Track",
			Vector3.new(s.X * 0.14, s.Y * 0.28, s.Z * 0.9),
			CFrame.new(side * s.X * 0.43, -s.Y * 0.18, 0),
			Color3.fromRGB(28, 30, 34),
			Enum.Material.Rubber
		)
		k.box(
			"TrackGuard",
			Vector3.new(s.X * 0.15, 0.4, s.Z * 0.92),
			CFrame.new(side * s.X * 0.43, -s.Y * 0.02, 0),
			ORANGE
		)
	end
	k.box("Cab", Vector3.new(s.X * 0.5, s.Y * 0.4, s.Z * 0.28), CFrame.new(0, s.Y * 0.2, -s.Z * 0.25), WHITE)
	k.box(
		"CabGlass",
		Vector3.new(s.X * 0.46, s.Y * 0.2, 0.2),
		CFrame.new(0, s.Y * 0.26, -s.Z * 0.39),
		Color3.fromRGB(40, 70, 130),
		Enum.Material.Glass
	)
	k.box("Seat", Vector3.new(2, 0.4, 2), CFrame.new(0, s.Y * 0.05, -s.Z * 0.22), DARK)
	local tanks: { number } = if twinTank then { -s.X * 0.2, s.X * 0.2 } else { 0 }
	for _, x in tanks do
		local tank = k.cyl(
			"Tank",
			s.Z * 0.45,
			s.X * (if twinTank then 0.36 else 0.6),
			CFrame.new(x, s.Y * 0.25, s.Z * 0.2) * CFrame.Angles(0, math.rad(90), 0),
			Color3.fromRGB(190, 196, 206),
			Enum.Material.Metal
		)
		tank.Name = "Tank"
		k.cyl(
			"TankBand",
			0.8,
			s.X * (if twinTank then 0.38 else 0.62),
			CFrame.new(x, s.Y * 0.25, s.Z * 0.05) * CFrame.Angles(0, math.rad(90), 0),
			ORANGE
		)
	end
	k.cyl(
		"Exhaust",
		s.Y * 0.4,
		0.8,
		CFrame.new(s.X * 0.3, s.Y * 0.45, -s.Z * 0.08) * CFrame.Angles(0, 0, math.rad(90)),
		STEEL,
		Enum.Material.Metal
	)
	local beacon =
		k.box("Beacon", Vector3.new(0.8, 0.6, 0.8), CFrame.new(0, s.Y * 0.43, -s.Z * 0.25), ORANGE, Enum.Material.Neon)
	beacon:SetAttribute("Blink", true)
	brush(k, v.width, -s.Y * 0.2, -s.Z / 2 - 0.4, s.Y * 0.3)
	headlights(k, s.X * 0.18, s.Y * 0.1, -s.Z * 0.4)
end

builders.CraterSweeper = function(k, v)
	giant(k, v, false)
end
builders.BigSuckRover = function(k, v)
	giant(k, v, true)
end

-- Build vehicle `id`. Returns the model; its PrimaryPart is the unanchored Body.
local function build(id: string): Model
	local v = def(id)
	local m = Instance.new("Model")
	m.Name = v.id
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(v.size.X * 0.7, 1, v.size.Z * 0.7)
	body.Transparency = 1
	body.CanCollide = false
	body.CanTouch = false
	body.CanQuery = true
	body.Anchored = false
	body.CFrame = CFrame.identity
	body.Parent = m
	m.PrimaryPart = body
	local k = kit(m, body)
	local fn = builders[v.id]
	if fn then
		fn(k, v)
	else
		rideOn(k, v, true)
	end
	local seat = m:FindFirstChild("Seat") :: BasePart?
	m:SetAttribute("SeatOffset", if seat then seat.CFrame.Position + Vector3.new(0, 2.6, 0) else Vector3.new(0, 3, 0))
	m:SetAttribute("Vehicle", v.id)
	return m
end

return build
