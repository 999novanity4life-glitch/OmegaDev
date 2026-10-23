--!strict
-- Builds one containment shaft (a match map) at an origin from ShaftLayout.
-- Greybox-plus-dressing in parts; Blender kit pieces replace the dressing later.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ShaftLayout = require(Shared:WaitForChild("ShaftLayout"))
local LabKit = require(script.Parent.LabKit)

local MapService = {}

export type TierParts = {
	info: ShaftLayout.Tier,
	folder: Folder,
	doors: { BasePart },
	doorOpen: { CFrame },
	bridge: { BasePart },
	bridgeTargets: { CFrame },
	landing: BasePart,
	pads: { BasePart },
	opened: boolean,
}
export type Map = {
	model: Model,
	origin: Vector3,
	layout: ShaftLayout.Layout,
	tiers: { TierParts },
	spawnPoints: { CFrame },
	exitPosition: Vector3,
	exitY: number,
	bottomY: number,
	cameraPath: { { Vector3 } }, -- {position, lookAt} pairs for the flyover
}

local C = {
	Wall = Color3.fromRGB(170, 160, 200),
	WallDark = Color3.fromRGB(30, 25, 44),
	Floor = Color3.fromRGB(150, 150, 170),
	Hazard = Color3.fromRGB(255, 196, 40),
	HazardDark = Color3.fromRGB(28, 24, 30),
	Pad = Color3.fromRGB(56, 182, 196),
	PadAlt = Color3.fromRGB(140, 92, 214),
	Trim = Config.Colors.Trim,
	Glass = Color3.fromRGB(150, 255, 190),
	Pipe = Color3.fromRGB(110, 116, 140),
	Alarm = Color3.fromRGB(255, 50, 60),
}

local function part(props: { [string]: any }, parent: Instance): Part
	return LabKit.part(props, parent)
end

local function deco(props: { [string]: any }, parent: Instance): Part
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	props.CastShadow = false
	return part(props, parent)
end

local function polar(origin: Vector3, angle: number, radius: number, y: number): Vector3
	local x, z = ShaftLayout.polar(angle, radius)
	return origin + Vector3.new(x, y, z)
end

-- CFrame on the ring at an angle, facing the shaft centre.
local function ringCFrame(origin: Vector3, angle: number, radius: number, y: number): CFrame
	local pos = polar(origin, angle, radius, y)
	local centre = Vector3.new(origin.X, pos.Y, origin.Z)
	return CFrame.lookAt(pos, centre)
end

-- Walls as a grid of individual panels (4 rows per tier), each picked from the
-- surface-specific variants: kick band at the bottom, weighted specials in the
-- middle (never repeated next to or above each other), control panels and the
-- level stencil beside each landing, a trim line under each ceiling.
local function buildWalls(model: Model, origin: Vector3, height: number, layout: ShaftLayout.Layout, seed: number)
	local cfg = Config.Shaft
	local folder = Instance.new("Folder")
	folder.Name = "Walls"
	folder.Parent = model
	local rand = Random.new(seed)
	local segs = cfg.WallSegments
	local step = 360 / segs
	local width = 2 * math.pi * (cfg.Radius + 1) / segs + 0.4
	local rows = 4
	local rowH = cfg.TierHeight / rows
	-- Filler below the floor and above the roof.
	for i = 0, segs - 1 do
		local angle = i * step
		for _, band in { { -20, 0 }, { height, height + 20 } } do
			local mid = (band[1] + band[2]) / 2
			part({
				Name = "Wall",
				Size = Vector3.new(width, band[2] - band[1], 2),
				CFrame = ringCFrame(origin, angle, cfg.Radius + 1, mid),
				Kit = "SR_WallPlain",
			}, folder)
		end
	end
	local below: { [number]: string } = {}
	for _, tier in layout.tiers do
		-- Segment closest to this tier's landing gets the control panel and stencil.
		local landingSeg = math.floor(((tier.hatchAngle % 360) / step) + 0.5) % segs
		local left: string? = nil
		for i = 0, segs - 1 do
			local angle = i * step
			for row = 1, rows do
				local y = tier.floorY + (row - 0.5) * rowH
				local kit: string
				if row == 1 then
					kit = "SR_WallBase"
				elseif row == 3 and (i == (landingSeg + 1) % segs or i == (landingSeg - 1) % segs) then
					kit = "SR_WallControl"
				elseif row == 4 and i == landingSeg then
					kit = "SR_WallPlain"
				else
					kit = LabKit.pickPanel(rand, if row == 2 then left else nil, below[i * 10 + row - 1])
				end
				below[i * 10 + row] = kit
				if row == 2 then
					left = kit
				end
				local panel = part({
					Name = "Wall",
					Size = Vector3.new(width, rowH, 2),
					CFrame = ringCFrame(origin, angle, cfg.Radius + 1, y),
					Kit = kit,
				}, folder)
				if row == 1 then
					-- Soft contact shadow where wall meets floor.
					LabKit.decal(panel, "Shadow", Enum.NormalId.Front, nil, 0.15)
				elseif kit == "SR_WallWindow" and tier.index == 1 then
					-- Slime oozing out under the windows on the lowest tier.
					LabKit.decalPlate(
						folder,
						ringCFrame(origin, angle, cfg.Radius - 0.06, y - rowH * 0.45),
						Vector2.new(width - 2, 3.5),
						"Drip"
					)
				end
				if row == 4 and i == landingSeg then
					LabKit.decalPlate(
						folder,
						ringCFrame(origin, angle, cfg.Radius - 0.06, y),
						Vector2.new(7, 7),
						"Level" .. tier.index,
						Config.Colors.Slime
					)
				end
			end
			-- Climb arrows on the wall behind each pad, pointing up the route.
			for _, pad in tier.pads do
				local d = math.abs(((pad.angle - angle + 180) % 360) - 180)
				if d < step / 2 then
					LabKit.decalPlate(
						folder,
						ringCFrame(origin, angle, cfg.Radius - 0.07, pad.y + 4.5),
						Vector2.new(2.6, 2.6),
						"Arrow",
						Color3.fromRGB(255, 220, 90)
					)
				end
			end
			-- Ribs between panels and a trim line under the ceiling.
			deco({
				Size = Vector3.new(0.8, cfg.TierHeight, 0.8),
				CFrame = ringCFrame(origin, angle + step / 2, cfg.Radius - 0.2, tier.floorY + cfg.TierHeight / 2),
				Kit = "SR_Steel",
			}, folder)
			deco({
				Size = Vector3.new(width, 1.6, 0.4),
				CFrame = ringCFrame(origin, angle, cfg.Radius - 0.1, tier.ceilingY - 3),
				Kit = "SR_Trim",
			}, folder)
		end
		task.wait()
	end
	-- Vertical pipes on every fourth panel, glowing ones on every eighth.
	for i = 0, segs - 1 do
		if i % 4 == 1 then
			local angle = i * step
			local pipe = ringCFrame(origin, angle + step / 2, cfg.Radius - 1.6, height / 2)
			deco({
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(height, 1.4, 1.4),
				CFrame = pipe * CFrame.Angles(0, 0, math.rad(90)),
				Color = if i % 8 == 1 then Config.Colors.Slime else C.Pipe,
				Material = if i % 8 == 1 then Enum.Material.Neon else Enum.Material.Metal,
			}, folder)
		end
	end
end

local function buildCore(model: Model, origin: Vector3, height: number)
	local cfg = Config.Shaft
	local core = deco({
		Name = "SlimeTank",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, cfg.CoreRadius * 2, cfg.CoreRadius * 2),
		CFrame = CFrame.new(origin + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.Glass,
		Material = Enum.Material.Glass,
		Transparency = 0.45,
	}, model)
	core.CanCollide = true
	local inner = deco({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, cfg.CoreRadius * 2 - 1.2, cfg.CoreRadius * 2 - 1.2),
		CFrame = core.CFrame,
		Color = Config.Colors.Slime,
		Material = Enum.Material.Neon,
		Transparency = 0.55,
	}, model)
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Color = ColorSequence.new(Color3.fromRGB(220, 255, 200))
	bubbles.LightEmission = 0.7
	bubbles.Size = NumberSequence.new(0.3, 0.8)
	bubbles.Transparency = NumberSequence.new(0.2, 1)
	bubbles.Lifetime = NumberRange.new(3, 6)
	bubbles.Speed = NumberRange.new(4, 9)
	bubbles.EmissionDirection = Enum.NormalId.Right -- cylinder axis points along X
	bubbles.Rate = 25
	bubbles.Parent = inner
	-- Steel rings around the tank at every floor.
	for t = 0, Config.Shaft.Tiers do
		deco({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.4, cfg.CoreRadius * 2 + 1.4, cfg.CoreRadius * 2 + 1.4),
			CFrame = CFrame.new(origin + Vector3.new(0, t * cfg.TierHeight + 3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = C.Pipe,
		}, model)
	end
end

-- Square slab with a square hole (the hatch) at a point, plus two sliding doors.
local function buildBulkhead(parent: Instance, origin: Vector3, y: number, hole: Vector3): ({ BasePart }, { CFrame })
	local cfg = Config.Shaft
	local half = cfg.Radius + 2
	local h = cfg.HatchSize / 2
	local t = cfg.BulkheadThickness
	local cy = y - t / 2
	local hx, hz = hole.X - origin.X, hole.Z - origin.Z
	local function slab(x0: number, x1: number, z0: number, z1: number)
		if x1 - x0 < 0.1 or z1 - z0 < 0.1 then
			return
		end
		part({
			Name = "Bulkhead",
			Size = Vector3.new(x1 - x0, t, z1 - z0),
			Position = origin + Vector3.new((x0 + x1) / 2, cy, (z0 + z1) / 2),
			Color = C.Floor,
			Kit = "SR_Grate",
		}, parent)
	end
	slab(-half, hx - h, -half, half)
	slab(hx + h, half, -half, half)
	slab(hx - h, hx + h, -half, hz - h)
	slab(hx - h, hx + h, hz + h, half)
	-- Hazard frame around the hatch.
	for _, side in
		{
			{ 0, -h - 0.5, cfg.HatchSize + 2, 1 },
			{ 0, h + 0.5, cfg.HatchSize + 2, 1 },
			{ -h - 0.5, 0, 1, cfg.HatchSize },
			{ h + 0.5, 0, 1, cfg.HatchSize },
		}
	do
		deco({
			Size = Vector3.new(side[3], 0.2, side[4]),
			Position = origin + Vector3.new(hx + side[1], y + 0.1, hz + side[2]),
			Color = C.Hazard,
			Material = Enum.Material.SmoothPlastic,
		}, parent)
	end
	local doors: { BasePart } = {}
	local open: { CFrame } = {}
	for i, dir in { -1, 1 } do
		local closed = CFrame.new(origin + Vector3.new(hx + dir * h / 2, cy + 0.05, hz))
		local door = part({
			Name = "HatchDoor" .. i,
			Size = Vector3.new(h, t + 0.1, cfg.HatchSize),
			CFrame = closed,
			Color = C.HazardDark,
			Material = Enum.Material.DiamondPlate,
		}, parent)
		local stripe = deco({
			Size = Vector3.new(h - 1, 0.15, 1.2),
			CFrame = closed * CFrame.new(0, t / 2 + 0.05, 0),
			Color = C.Hazard,
			Material = Enum.Material.Neon,
		}, parent)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = door
		weld.Part1 = stripe
		weld.Parent = door
		stripe.Anchored = false
		table.insert(doors, door)
		table.insert(open, closed * CFrame.new(dir * (h - 0.4), 0, 0))
	end
	return doors, open
end

local function padPart(parent: Instance, origin: Vector3, pad: ShaftLayout.Pad, size: Vector3, color: Color3): Part
	local cf = ringCFrame(origin, pad.angle, pad.radius, pad.y - size.Y / 2)
	local p = part({ Name = "Pad", Size = size, CFrame = cf, Color = color, Kit = "SR_Pad" }, parent)
	-- Neon edge trim and a strut back to the wall.
	deco({
		Size = Vector3.new(size.X + 0.3, 0.3, size.Z + 0.3),
		CFrame = cf * CFrame.new(0, -size.Y / 2, 0),
		Color = C.Trim,
		Material = Enum.Material.Neon,
	}, parent)
	local wallPoint = polar(origin, pad.angle, Config.Shaft.Radius, pad.y - size.Y - 2)
	local under = cf.Position - Vector3.new(0, size.Y / 2, 0)
	local length = (wallPoint - under).Magnitude
	deco({
		Size = Vector3.new(0.6, 0.6, length),
		CFrame = CFrame.lookAt((wallPoint + under) / 2, wallPoint),
		Color = C.WallDark,
	}, parent)
	return p
end

-- Dense set dressing for one tier: lights, vents, pipes, racks, crates,
-- console, gauges, cables, signs and a railing on the landing.
local function dressTier(folder: Instance, origin: Vector3, info: ShaftLayout.Tier, landing: BasePart)
	local cfg = Config.Shaft
	local floorY = info.floorY
	local h = info.hatchAngle
	local R = cfg.Radius
	-- Caged lights, two rows, between the pads.
	for i = 0, 5 do
		local angle = h + 15 + i * 60
		local y = floorY + (if i % 2 == 0 then 10 else 24)
		LabKit.lightFixture(folder, ringCFrame(origin, angle, R - 0.6, y), Color3.fromRGB(220, 240, 255), 32)
	end
	-- Vents low on the wall.
	for _, angle in { h + 95, h + 265 } do
		LabKit.vent(folder, ringCFrame(origin, angle, R - 0.2, floorY + 6), 5)
	end
	-- Pipe clusters with gauges beside them.
	for _, angle in { h + 60, h - 120 } do
		local base = ringCFrame(origin, angle, R - 2.2, floorY)
		if not LabKit.prop("Pipes", base, 7, folder) then
			LabKit.deco(
				{ Size = Vector3.new(6, 7, 1.5), CFrame = base * CFrame.new(0, 3.5, 0), Kit = "SR_Steel" },
				folder
			)
		end
		LabKit.gauge(folder, ringCFrame(origin, angle + 7, R - 0.5, floorY + 5))
		LabKit.gauge(folder, ringCFrame(origin, angle - 7, R - 0.5, floorY + 3.5))
	end
	-- Server racks against the wall.
	for _, angle in { h + 138, h + 150 } do
		LabKit.serverRack(folder, ringCFrame(origin, angle, R - 2, floorY))
	end
	-- Crate stacks and a control console on the floor.
	for k, angle in { h + 200, h + 212, h + 224 } do
		local cf = ringCFrame(origin, angle, R - 3.5, floorY) * CFrame.Angles(0, math.rad(k * 23), 0)
		if not LabKit.prop("Crates", cf, 4 + (k % 2) * 1.5, folder, true) then
			LabKit.part({ Size = Vector3.new(3, 3, 3), CFrame = cf * CFrame.new(0, 1.5, 0), Kit = "SR_Steel" }, folder)
		end
	end
	local consoleCf = ringCFrame(origin, h + 25, R - 3, floorY)
	if not LabKit.prop("Console", consoleCf, 4.4, folder, true) then
		LabKit.part(
			{ Size = Vector3.new(6, 3, 3), CFrame = consoleCf * CFrame.new(0, 1.5, 0), Kit = "SR_Steel" },
			folder
		)
	end
	-- Cables sagging between wall points near the ceiling.
	for k = 0, 2 do
		local a1 = h + 40 + k * 110
		local p1 = origin
			+ Vector3.new(0, floorY + 37, 0)
			+ Vector3.new(math.cos(math.rad(a1)) * (R - 0.8), 0, math.sin(math.rad(a1)) * (R - 0.8))
		local a2 = a1 + 45
		local p2 = origin
			+ Vector3.new(0, floorY + 36, 0)
			+ Vector3.new(math.cos(math.rad(a2)) * (R - 0.8), 0, math.sin(math.rad(a2)) * (R - 0.8))
		LabKit.cable(folder, p1, p2, 3 + k, if k == 1 then Config.Colors.SlimeDeep else nil)
	end
	-- Signs.
	LabKit.sign(
		folder,
		ringCFrame(origin, h - 14, R - 0.4, floorY + cfg.LandingHeight + 4),
		Vector2.new(7, 2.4),
		string.format("LEVEL %d", info.index)
	)
	LabKit.sign(
		folder,
		ringCFrame(origin, h + 175, R - 0.4, floorY + 12),
		Vector2.new(8, 2.6),
		"! SLIME HAZARD !",
		Color3.fromRGB(255, 210, 60)
	)
	LabKit.sign(
		folder,
		ringCFrame(origin, h + 115, R - 0.4, floorY + 14),
		Vector2.new(6, 2.2),
		"SECTOR 7",
		Color3.fromRGB(150, 220, 255)
	)
	-- Floor accents: drain plates, a walkway strip toward the first pad.
	local function floorPlate(angle: number, radius: number, size: Vector2, kit: string, yaw: number?)
		local x, z = ShaftLayout.polar(angle, radius)
		local pos = origin + Vector3.new(x, floorY + 0.03, z)
		local facing = CFrame.lookAt(pos, Vector3.new(origin.X, pos.Y, origin.Z))
			* CFrame.Angles(0, math.rad(yaw or 0), 0)
		LabKit.deco({ Size = Vector3.new(size.X, 0.06, size.Y), CFrame = facing, Kit = kit }, folder)
	end
	floorPlate(h + 190, 22, Vector2.new(7, 7), "SR_FloorDrain")
	floorPlate(h + 250, 18, Vector2.new(7, 7), "SR_FloorDrain", 45)
	local firstPad = info.pads[1]
	for k = 0, 2 do
		floorPlate(firstPad.angle - 8, 10 + k * 5.5, Vector2.new(4, 5.5), "SR_Walkway")
	end
	-- The leak tier gets puddles spreading from the broken pipe.
	if info.index == 1 then
		for k, spec in { { 0, 30, 9 }, { 12, 25, 6 }, { -14, 27, 7 }, { 6, 19, 5 } } do
			local x, z = ShaftLayout.polar(h + 180 + spec[1], spec[2])
			local pos = origin + Vector3.new(x, floorY + 0.06 + k * 0.01, z)
			LabKit.decalPlate(
				folder,
				CFrame.new(pos) * CFrame.Angles(0, math.rad(k * 47), 0) * CFrame.Angles(math.rad(90), 0, 0),
				Vector2.new(spec[3], spec[3] * 0.7),
				"Puddle"
			)
		end
	end
	LabKit.mat(landing, "SR_Walkway")
	-- Railing on the landing's inner edge.
	local size = landing.Size
	LabKit.railing(folder, landing.CFrame * CFrame.new(0, size.Y / 2, -size.Z / 2 + 0.3), size.X - 0.6)
end

local function alarmLight(parent: Instance, cf: CFrame)
	local housing = deco({ Size = Vector3.new(1.6, 1.2, 1.6), CFrame = cf, Color = C.WallDark }, parent)
	local lamp = deco({
		Name = "AlarmLamp",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 1.4,
		CFrame = cf * CFrame.new(0, 0.7, 0),
		Color = C.Alarm,
		Material = Enum.Material.Neon,
	}, parent)
	local spot = Instance.new("SpotLight")
	spot.Color = C.Alarm
	spot.Range = 30
	spot.Angle = 50
	spot.Brightness = 4
	spot.Face = Enum.NormalId.Front
	spot.Parent = lamp
	CollectionService:AddTag(lamp, "AlarmLight") -- client spins these
	local _ = housing
end

function MapService.buildShaft(origin: Vector3, seed: number): Map
	local cfg = Config.Shaft
	local layout = ShaftLayout.build(seed)
	local model = Instance.new("Model")
	model.Name = "Shaft"
	local height = layout.topY
	buildWalls(model, origin, height, layout, seed)
	buildCore(model, origin, height)

	-- Bottom floor (tier 1).
	part({
		Name = "Floor",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, cfg.Radius * 2 + 2, cfg.Radius * 2 + 2),
		CFrame = CFrame.new(origin + Vector3.new(0, -1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.Floor,
		Kit = "SR_Grate",
	}, model)
	-- Leak: cracked pipe at the bottom with slime pouring out.
	local leak = deco({
		Name = "Leak",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(10, 3, 3),
		CFrame = ringCFrame(origin, layout.tiers[1].hatchAngle + 180, cfg.Radius - 3, 4)
			* CFrame.Angles(0, math.rad(90), 0),
		Color = C.Pipe,
	}, model)
	local gush = Instance.new("ParticleEmitter")
	gush.Color = ColorSequence.new(Config.Colors.Slime)
	gush.LightEmission = 0.4
	gush.Size = NumberSequence.new(1.2, 0.4)
	gush.Lifetime = NumberRange.new(0.8, 1.2)
	gush.Speed = NumberRange.new(8, 14)
	gush.Acceleration = Vector3.new(0, -40, 0)
	gush.SpreadAngle = Vector2.new(15, 15)
	gush.Rate = 60
	gush.Parent = leak

	local tiers: { TierParts } = {}
	for _, info in layout.tiers do
		local folder = Instance.new("Folder")
		folder.Name = "Tier" .. info.index
		folder.Parent = model
		local pads: { BasePart } = {}
		for i, pad in info.pads do
			table.insert(
				pads,
				padPart(folder, origin, pad, Vector3.new(8, 1.2, 7), if i % 2 == 0 then C.Pad else C.PadAlt)
			)
		end
		local landing = padPart(folder, origin, info.landing, Vector3.new(14, 1.4, 10), C.Floor)
		landing.Name = "Landing"
		alarmLight(folder, ringCFrame(origin, info.hatchAngle, cfg.Radius - 1, info.floorY + cfg.LandingHeight + 6))
		dressTier(folder, origin, info, landing)
		task.wait()
		local hole = polar(origin, info.hatchAngle, info.hatchRadius, 0)
		local doors, doorOpen = buildBulkhead(folder, origin, info.ceilingY, hole)
		-- Bridge pads wait inside the wall until the puzzle is solved.
		local bridge: { BasePart } = {}
		local targets: { CFrame } = {}
		for _, pad in info.bridge do
			local target = ringCFrame(origin, pad.angle, pad.radius, pad.y - 0.6)
			local stowed = ringCFrame(origin, pad.angle, cfg.Radius + 3, pad.y - 0.6)
			local b = part({
				Name = "BridgePad",
				Size = Vector3.new(4, 1.2, 4),
				CFrame = stowed,
				Color = C.Hazard,
				Material = Enum.Material.DiamondPlate,
				CanCollide = false,
				Transparency = 1,
			}, folder)
			table.insert(bridge, b)
			table.insert(targets, target)
		end
		table.insert(tiers, {
			info = info,
			folder = folder,
			doors = doors,
			doorOpen = doorOpen,
			bridge = bridge,
			bridgeTargets = targets,
			landing = landing :: BasePart,
			pads = pads,
			opened = false,
		})
	end

	-- Roof exit above the last bulkhead.
	local exitPos = polar(origin, layout.exitAngle, layout.exitRadius, layout.exitY)
	local exitPad = part({
		Name = "ExitPad",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 10, 10),
		CFrame = CFrame.new(exitPos - Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Config.Colors.Exit,
		Material = Enum.Material.Neon,
	}, model)
	local beacon = Instance.new("PointLight")
	beacon.Color = Config.Colors.Exit
	beacon.Range = 40
	beacon.Brightness = 3
	beacon.Parent = exitPad
	deco({
		Name = "ExitBeam",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(60, 6, 6),
		CFrame = CFrame.new(exitPos + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Config.Colors.Exit,
		Material = Enum.Material.Neon,
		Transparency = 0.8,
	}, model)

	local spawns: { CFrame } = {}
	for i = 0, 11 do
		local angle = layout.tiers[1].hatchAngle + 150 + i * 5
		local pos = polar(origin, angle, 14 + (i % 3) * 4, 3)
		table.insert(spawns, CFrame.lookAt(pos, Vector3.new(origin.X, pos.Y, origin.Z)))
	end

	-- Flyover: start above the exit, spiral down the shaft to the leak.
	local path: { { Vector3 } } = {}
	table.insert(path, { exitPos + Vector3.new(0, 40, 30), exitPos })
	local turns = 6
	for i = 0, turns do
		local f = i / turns
		local y = height * (1 - f) + 6
		local angle = layout.exitAngle + f * 540
		table.insert(path, { polar(origin, angle, cfg.Radius - 8, y), origin + Vector3.new(0, y - 14, 0) })
	end
	table.insert(path, { polar(origin, layout.tiers[1].hatchAngle + 160, 26, 8), leak.Position })

	model.Parent = workspace:FindFirstChild("Matches")
		or (function()
			local f = Instance.new("Folder")
			f.Name = "Matches"
			f.Parent = workspace
			return f
		end)()
	return {
		model = model,
		origin = origin,
		layout = layout,
		tiers = tiers,
		spawnPoints = spawns,
		exitPosition = exitPos,
		exitY = layout.exitY,
		bottomY = origin.Y,
		cameraPath = path,
	}
end

-- Opens a tier: hatch doors slide apart and the bridge pads slide out of the wall.
function MapService.openTier(tier: TierParts)
	if tier.opened then
		return
	end
	tier.opened = true
	local info = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for i, door in tier.doors do
		TweenService:Create(door, info, { CFrame = tier.doorOpen[i] }):Play()
	end
	for i, pad in tier.bridge do
		pad.Transparency = 0
		pad.CanCollide = true
		task.delay((i - 1) * 0.25, function()
			TweenService:Create(pad, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				CFrame = tier.bridgeTargets[i],
			}):Play()
		end)
	end
end

function MapService.destroy(map: Map)
	map.model:Destroy()
end

return MapService
