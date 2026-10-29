--!strict
-- Builds one Moon Mop station from Parts: the white octagonal tower from the reference frames
-- (p1_10900, p2_19300, p1_004, p1_019), now hollow, with the interior the original shows:
-- hex-tile floor, the dust deposit drum with its orange ring, the supply wall pegboard, the
-- Upgrade Board console, the Moon Map hologram globe, a teleport pad, a kitchenette and posters.
-- A pod cannon sits on the roof. Returns the model and the interior anchor points.
--
-- `base` is the centre of the plinth's underside; its UpVector is the local up, so the same
-- call works anywhere on the round Moon. Started as tools/studio/BuildStation.luau.

local W = 56 -- across flats (about ten player heights)
local C = 14 -- corner chamfer
local H = 44 -- wall height above the plinth
local T = 1.2 -- wall thickness
local PLINTH = 1.4
local BASE = 7
local TOP = 38
local MID = (BASE + TOP) / 2
local WIN_H = TOP - BASE - 6
local DOOR_W, DOOR_H = 7, 10

local WHITE = Color3.fromRGB(236, 238, 243)
local SEAM = Color3.fromRGB(178, 184, 196)
local ORANGE = Color3.fromRGB(240, 110, 30)
local BLUE = Color3.fromRGB(52, 150, 240)
local BLUE_HI = Color3.fromRGB(150, 210, 255)
local FRAME = Color3.fromRGB(28, 31, 38)
local VENT = Color3.fromRGB(20, 22, 27)
local CONCRETE = Color3.fromRGB(150, 153, 162)
local FLOOR = Color3.fromRGB(196, 200, 210)
local FLOOR_LINE = Color3.fromRGB(150, 156, 170)
local TEAL = Color3.fromRGB(60, 220, 210)

export type Anchors = {
	drum: CFrame,
	supply: CFrame,
	board: CFrame,
	globe: CFrame,
	teleport: CFrame,
	cannon: CFrame,
	boss: CFrame,
	door: CFrame,
	spawn: CFrame,
	floor: CFrame,
}

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function deco(p: Part): Part
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	return p
end

local function light(parent: Instance, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = parent
end

-- Solid octagon (flats 2a, chamfer c) from two crossed boxes and four 45-degree corner boxes.
local function octagon(
	parent: Instance,
	name: string,
	cf: CFrame,
	a: number,
	c: number,
	h: number,
	color: Color3,
	mat: Enum.Material?
): Model
	local m = Instance.new("Model")
	m.Name = name
	part(m, "X", Vector3.new(2 * a, h, 2 * (a - c)), cf, color, mat)
	part(m, "Z", Vector3.new(2 * (a - c), h, 2 * a), cf, color, mat)
	local len = c * math.sqrt(2)
	local depth = c / math.sqrt(2)
	local dist = (2 * a - c) / math.sqrt(2) - depth / 2
	for i = 0, 3 do
		local ang = math.rad(45 + 90 * i)
		part(
			m,
			"Corner",
			Vector3.new(len, h, depth),
			cf * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0, -dist),
			color,
			mat
		)
	end
	m.Parent = parent
	return m
end

local function vent(parent: Instance, cf: CFrame, w: number, h: number)
	deco(part(parent, "VentBack", Vector3.new(w, h, 0.3), cf, VENT))
	local n = math.max(3, math.floor(h / 0.45))
	for i = 1, n - 1 do
		local y = -h / 2 + i * h / n
		deco(
			part(
				parent,
				"Slat",
				Vector3.new(w - 0.2, 0.08, 0.25),
				cf * CFrame.new(0, y, -0.18) * CFrame.Angles(math.rad(-25), 0, 0),
				Color3.fromRGB(48, 52, 60)
			)
		)
	end
end

local function window(parent: Instance, cf: CFrame, w: number, h: number)
	deco(part(parent, "WinFrame", Vector3.new(w + 0.5, h + 0.5, 0.3), cf, FRAME))
	deco(part(parent, "Glass", Vector3.new(w, h, 0.3), cf * CFrame.new(0, 0, -0.08), BLUE))
	deco(part(parent, "GlassHi", Vector3.new(w * 0.22, h * 0.92, 0.3), cf * CFrame.new(-w * 0.28, 0, -0.1), BLUE_HI))
end

local function hatch(parent: Instance, cf: CFrame, w: number, h: number)
	deco(part(parent, "HatchRim", Vector3.new(w, h, 0.35), cf, ORANGE))
	vent(parent, cf * CFrame.new(0, 0, -0.12), w - 0.7, h - 0.7)
end

local function textPanel(p: Part, face: Enum.NormalId, pixels: Vector2): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.CanvasSize = pixels
	gui.LightInfluence = 0.6
	gui.Parent = p
	return gui
end

local function label(
	parent: Instance,
	text: string,
	pos: UDim2,
	size: UDim2,
	color: Color3,
	font: Enum.Font?
): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Text = text
	l.TextColor3 = color
	l.Font = font or Enum.Font.GothamBold
	l.TextScaled = true
	l.Parent = parent
	return l
end

-- Door with an open doorway: frame posts, a lintel, open leaves slid aside, lamp and sign.
local function door(parent: Instance, cf: CFrame, sign: string)
	for s = -1, 1, 2 do
		deco(
			part(
				parent,
				"DoorPost",
				Vector3.new(0.6, DOOR_H, 0.6),
				cf * CFrame.new(s * (DOOR_W / 2 + 0.3), DOOR_H / 2, 0),
				FRAME
			)
		)
		local leaf = cf * CFrame.new(s * (DOOR_W / 2 + 1.7), DOOR_H / 2 - 0.4, -0.15)
		deco(part(parent, "DoorLeaf", Vector3.new(2.7, DOOR_H - 1, 0.3), leaf, Color3.fromRGB(205, 210, 220)))
		deco(part(parent, "DoorStripe", Vector3.new(2.7, 0.25, 0.3), leaf * CFrame.new(0, -2.6, -0.05), ORANGE))
	end
	deco(part(parent, "Lintel", Vector3.new(DOOR_W + 1.2, 0.6, 0.6), cf * CFrame.new(0, DOOR_H + 0.3, 0), FRAME))
	local lamp = deco(
		part(
			parent,
			"DoorLamp",
			Vector3.new(0.9, 0.35, 0.35),
			cf * CFrame.new(0, DOOR_H + 0.9, -0.2),
			Color3.fromRGB(255, 190, 120),
			Enum.Material.Neon
		)
	)
	light(lamp, Color3.fromRGB(255, 200, 150), 14, 1.2)
	local signCf = cf * CFrame.new(0, 16.5, -0.05)
	deco(part(parent, "SignBorder", Vector3.new(4.6, 6.4, 0.3), signCf, Color3.fromRGB(200, 60, 40)))
	local card = deco(part(parent, "Sign", Vector3.new(4.1, 5.9, 0.3), signCf * CFrame.new(0, 0, -0.06), WHITE))
	local gui = textPanel(card, Enum.NormalId.Front, Vector2.new(164, 236))
	local badge = Instance.new("Frame")
	badge.Size = UDim2.fromOffset(110, 110)
	badge.Position = UDim2.fromOffset(27, 30)
	badge.BackgroundColor3 = Color3.fromRGB(26, 30, 40)
	badge.Parent = gui
	Instance.new("UICorner", badge).CornerRadius = UDim.new(0.5, 0)
	local earth = Instance.new("Frame")
	earth.Size = UDim2.fromScale(0.42, 0.42)
	earth.Position = UDim2.fromScale(0.29, 0.29)
	earth.BackgroundColor3 = Color3.fromRGB(80, 150, 230)
	earth.Parent = badge
	Instance.new("UICorner", earth).CornerRadius = UDim.new(0.5, 0)
	label(gui, sign, UDim2.fromOffset(6, 160), UDim2.fromOffset(152, 56), Color3.fromRGB(26, 30, 40))
end

-- Outside decoration of one wall face. cf sits on the outer wall surface at floor height,
-- LookVector pointing into the station.
local function face(parent: Instance, cf: CFrame, len: number, kind: string, sign: string)
	local out = cf * CFrame.Angles(0, math.pi, 0)
	local function at(x: number, y: number, z: number?): CFrame
		return out * CFrame.new(x, y, -(z or 0))
	end
	for _, y in { BASE + 0.1, MID, TOP - 0.1 } do
		if not (kind == "door" and y < DOOR_H + 1) then
			deco(part(parent, "SeamH", Vector3.new(len, 0.14, 0.12), at(0, y, 0.02), SEAM))
		end
	end
	local cols = math.max(2, math.floor(len / 5))
	for i = 1, cols - 1 do
		local x = -len / 2 + i * len / cols
		if not (kind == "door" and math.abs(x) < DOOR_W / 2 + 1) then
			deco(part(parent, "SeamV", Vector3.new(0.12, TOP - BASE, 0.12), at(x, (BASE + TOP) / 2, 0.02), SEAM))
		end
	end
	if kind ~= "door" then
		deco(part(parent, "Stripe", Vector3.new(len + 0.05, 0.4, 0.16), at(0, BASE + 0.6, 0.04), ORANGE))
	end
	deco(part(parent, "Stripe", Vector3.new(len + 0.05, 0.4, 0.16), at(0, TOP - 0.7, 0.04), ORANGE))
	vent(parent, at(0, TOP + 2.8, 0.08), len * (if kind == "main" then 0.7 else 0.55), 2.2)
	if kind == "main" then
		window(parent, at(-len * 0.25, MID, 0.1), 3.6, WIN_H)
		window(parent, at(len * 0.25, MID, 0.1), 3.6, WIN_H)
		vent(parent, at(0, 3.2, 0.08), len * 0.22, 2.6)
		hatch(parent, at(-len * 0.3, 3.2, 0.1), 4.2, 5.2)
		hatch(parent, at(len * 0.3, 3.2, 0.1), 4.2, 5.2)
	elseif kind == "door" then
		door(parent, at(0, 0, 0.1), sign)
		window(parent, at(-len * 0.36, MID + 3, 0.1), 1.6, WIN_H - 6)
		window(parent, at(len * 0.36, MID + 3, 0.1), 1.6, WIN_H - 6)
	else
		window(parent, at(0, MID, 0.1), 3.4, WIN_H)
		vent(parent, at(0, 3, 0.08), len * 0.45, 1.5)
	end
end

-- One wall slab, with a doorway cut out of the door face.
local function wall(parent: Instance, cf: CFrame, len: number, hasDoor: boolean)
	local inward = cf * CFrame.new(0, 0, -T / 2) -- cf is on the outer surface, looking in
	if not hasDoor then
		part(parent, "Wall", Vector3.new(len + 1.6, H, T), inward * CFrame.new(0, H / 2, 0), WHITE)
		return
	end
	local side = (len + 1.6 - DOOR_W) / 2
	for s = -1, 1, 2 do
		part(parent, "Wall", Vector3.new(side, H, T), inward * CFrame.new(s * (DOOR_W / 2 + side / 2), H / 2, 0), WHITE)
	end
	part(
		parent,
		"Wall",
		Vector3.new(DOOR_W, H - DOOR_H, T),
		inward * CFrame.new(0, DOOR_H + (H - DOOR_H) / 2, 0),
		WHITE
	)
end

local function hexFloor(parent: Instance, floor: CFrame, radius: number, kit: Instance?)
	local hexMesh = kit
		and kit:FindFirstChild("DustHex")
		and (kit:FindFirstChild("DustHex") :: Instance):FindFirstChild("Hex")
	local tileR = 3.2
	local n = math.ceil(radius / (1.5 * tileR)) + 1
	for col = -n, n do
		for row = -n, n do
			local x = col * 1.5 * tileR
			local z = row * math.sqrt(3) * tileR + (if col % 2 ~= 0 then math.sqrt(3) / 2 * tileR else 0)
			if math.sqrt(x * x + z * z) < radius - tileR then
				local cf = floor * CFrame.new(x, 0.12, z)
				local shade = if (col + row) % 3 == 0 then Color3.fromRGB(176, 181, 194) else FLOOR
				if hexMesh and hexMesh:IsA("MeshPart") then
					local tile = hexMesh:Clone()
					tile.Name = "FloorHex"
					tile.Anchored = true
					tile.CanCollide = false
					tile.CastShadow = false
					tile.Size = Vector3.new(2 * tileR - 0.25, 0.2, math.sqrt(3) * tileR - 0.25)
					tile.CFrame = cf
					tile.Color = shade
					tile.Material = Enum.Material.SmoothPlastic
					tile.Parent = parent
				else
					local tile = deco(
						part(
							parent,
							"FloorHex",
							Vector3.new(0.2, 2 * tileR - 0.4, 2 * tileR - 0.4),
							cf * CFrame.Angles(0, 0, math.rad(90)),
							shade
						)
					)
					tile.Shape = Enum.PartType.Cylinder
				end
			end
		end
	end
end

-- The dust deposit drum: a white drum with an orange ring and a glowing intake.
local function drum(parent: Instance, cf: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "DepositDrum"
	local body =
		part(m, "Body", Vector3.new(7, 8, 8), cf * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, 0, math.rad(90)), WHITE)
	body.Shape = Enum.PartType.Cylinder
	local ring = deco(
		part(
			m,
			"Ring",
			Vector3.new(1.2, 8.6, 8.6),
			cf * CFrame.new(0, 5.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
			ORANGE
		)
	)
	ring.Shape = Enum.PartType.Cylinder
	local lip = deco(
		part(
			m,
			"Lip",
			Vector3.new(0.6, 6.2, 6.2),
			cf * CFrame.new(0, 7.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
			FRAME
		)
	)
	lip.Shape = Enum.PartType.Cylinder
	local glow = deco(
		part(
			m,
			"Glow",
			Vector3.new(0.2, 5.4, 5.4),
			cf * CFrame.new(0, 7.45, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(110, 230, 255),
			Enum.Material.Neon
		)
	)
	glow.Shape = Enum.PartType.Cylinder
	light(glow, Color3.fromRGB(110, 230, 255), 12, 1.4)
	local base = deco(
		part(
			m,
			"Base",
			Vector3.new(0.6, 9.4, 9.4),
			cf * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
			CONCRETE
		)
	)
	base.Shape = Enum.PartType.Cylinder
	-- hazard band label
	local plate =
		deco(part(m, "Plate", Vector3.new(3.4, 1.2, 0.2), cf * CFrame.new(0, 2.6, -4.05), Color3.fromRGB(30, 33, 40)))
	local gui = textPanel(plate, Enum.NormalId.Front, Vector2.new(240, 84))
	label(gui, "DEPOSIT", UDim2.fromScale(0.04, 0.1), UDim2.fromScale(0.92, 0.8), Color3.fromRGB(255, 196, 40))
	m.PrimaryPart = body
	m.Parent = parent
	return m
end

-- Pegboard supply wall with tools hanging on hooks and luggage-tag prices.
local function supplyWall(parent: Instance, cf: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "SupplyWall"
	local board = deco(
		part(
			m,
			"Board",
			Vector3.new(18, 10, 0.4),
			cf * CFrame.new(0, 7, 0),
			Color3.fromRGB(205, 168, 120),
			Enum.Material.Wood
		)
	)
	local gui = textPanel(board, Enum.NormalId.Front, Vector2.new(720, 400))
	gui.LightInfluence = 1
	for x = 0, 17 do
		for y = 0, 9 do
			local hole = Instance.new("Frame")
			hole.Size = UDim2.fromOffset(8, 8)
			hole.Position = UDim2.fromOffset(16 + x * 39, 16 + y * 39)
			hole.BackgroundColor3 = Color3.fromRGB(90, 66, 44)
			hole.BorderSizePixel = 0
			hole.Parent = gui
			Instance.new("UICorner", hole).CornerRadius = UDim.new(0.5, 0)
		end
	end
	deco(part(m, "Header", Vector3.new(18.4, 1.6, 0.5), cf * CFrame.new(0, 12.8, -0.05), ORANGE))
	local header = deco(part(m, "HeaderText", Vector3.new(14, 1.2, 0.1), cf * CFrame.new(0, 12.8, -0.35), ORANGE))
	label(
		textPanel(header, Enum.NormalId.Front, Vector2.new(560, 48)),
		"SUPPLY WALL",
		UDim2.fromScale(0, 0),
		UDim2.fromScale(1, 1),
		Color3.fromRGB(20, 14, 8)
	)
	-- hanging tools: handles, heads and tags
	local looks: { { colour: Color3, w: number } } = {
		{ colour = Color3.fromRGB(120, 200, 230), w = 0.25 },
		{ colour = Color3.fromRGB(150, 110, 70), w = 0.6 },
		{ colour = Color3.fromRGB(150, 156, 170), w = 0.9 },
		{ colour = Color3.fromRGB(160, 160, 170), w = 1.2 },
		{ colour = Color3.fromRGB(230, 190, 80), w = 1.5 },
		{ colour = Color3.fromRGB(70, 140, 230), w = 1.8 },
	}
	for i, look in looks do
		local x = -7.5 + (i - 1) * 3
		local hook = cf * CFrame.new(x, 10.5, -0.4)
		deco(part(m, "Hook", Vector3.new(0.2, 0.6, 0.6), hook, FRAME))
		deco(
			part(m, "Handle", Vector3.new(0.35, 5.5, 0.35), hook * CFrame.new(0, -3, -0.2), Color3.fromRGB(70, 74, 84))
		)
		deco(part(m, "Head", Vector3.new(look.w + 0.4, 1, 0.7), hook * CFrame.new(0, -6.2, -0.2), look.colour))
		local tag = deco(
			part(
				m,
				"Tag",
				Vector3.new(0.9, 1.2, 0.06),
				hook * CFrame.new(0.7, -1.6, -0.5) * CFrame.Angles(0, 0, math.rad(12)),
				Color3.fromRGB(240, 226, 190)
			)
		)
		tag.Material = Enum.Material.Fabric
	end
	m.Parent = parent
	return m
end

-- Upgrade Board console: a desk with a tall teal screen.
local function boardConsole(parent: Instance, cf: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "UpgradeBoard"
	part(m, "Desk", Vector3.new(10, 3.4, 3), cf * CFrame.new(0, 1.7, -1.5), Color3.fromRGB(60, 64, 74))
	deco(part(m, "DeskTrim", Vector3.new(10.2, 0.3, 3.2), cf * CFrame.new(0, 3.5, -1.5), ORANGE))
	local screen = deco(
		part(
			m,
			"Screen",
			Vector3.new(11, 7, 0.4),
			cf * CFrame.new(0, 9, 0),
			Color3.fromRGB(10, 22, 28),
			Enum.Material.Glass
		)
	)
	local gui = textPanel(screen, Enum.NormalId.Front, Vector2.new(550, 350))
	gui.LightInfluence = 0
	gui.Brightness = 2
	label(gui, "UPGRADE BOARD", UDim2.fromScale(0.05, 0.05), UDim2.fromScale(0.9, 0.16), TEAL)
	for r = 0, 3 do
		for c = 0, 6 do
			local node = Instance.new("Frame")
			node.Size = UDim2.fromScale(0.09, 0.12)
			node.Position = UDim2.fromScale(0.07 + c * 0.125, 0.3 + r * 0.17)
			node.BackgroundColor3 = if (r + c) % 3 == 0 then ORANGE else Color3.fromRGB(30, 70, 76)
			node.BorderSizePixel = 0
			node.Parent = gui
			Instance.new("UICorner", node).CornerRadius = UDim.new(0.2, 0)
		end
	end
	light(screen, TEAL, 12, 1)
	m.Parent = parent
	return m
end

-- Moon Map pedestal with an orange hologram globe.
local function globe(parent: Instance, cf: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "MoonMapGlobe"
	local ped = part(
		m,
		"Pedestal",
		Vector3.new(3, 5, 5),
		cf * CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(60, 64, 74)
	)
	ped.Shape = Enum.PartType.Cylinder
	local rim = deco(
		part(
			m,
			"Rim",
			Vector3.new(0.4, 5.6, 5.6),
			cf * CFrame.new(0, 3.1, 0) * CFrame.Angles(0, 0, math.rad(90)),
			ORANGE,
			Enum.Material.Neon
		)
	)
	rim.Shape = Enum.PartType.Cylinder
	local ball = deco(
		part(
			m,
			"Hologram",
			Vector3.new(6.5, 6.5, 6.5),
			cf * CFrame.new(0, 7.6, 0),
			Color3.fromRGB(255, 130, 40),
			Enum.Material.ForceField
		)
	)
	ball.Shape = Enum.PartType.Ball
	local core = deco(
		part(
			m,
			"Core",
			Vector3.new(5.8, 5.8, 5.8),
			cf * CFrame.new(0, 7.6, 0),
			Color3.fromRGB(255, 110, 30),
			Enum.Material.Neon
		)
	)
	core.Shape = Enum.PartType.Ball
	core.Transparency = 0.85
	light(core, Color3.fromRGB(255, 140, 50), 16, 2)
	local beam = deco(
		part(
			m,
			"Beam",
			Vector3.new(4.5, 0.6, 0.6),
			cf * CFrame.new(0, 5.4, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(255, 150, 60),
			Enum.Material.Neon
		)
	)
	beam.Shape = Enum.PartType.Cylinder
	beam.Transparency = 0.6
	m.Parent = parent
	return m
end

local function teleportPad(parent: Instance, cf: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "TeleportPad"
	local pad = deco(
		part(
			m,
			"Pad",
			Vector3.new(0.4, 7, 7),
			cf * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(40, 44, 52)
		)
	)
	pad.Shape = Enum.PartType.Cylinder
	local glow = deco(
		part(
			m,
			"Glow",
			Vector3.new(0.1, 5.6, 5.6),
			cf * CFrame.new(0, 0.52, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(80, 200, 255),
			Enum.Material.Neon
		)
	)
	glow.Shape = Enum.PartType.Cylinder
	glow.Transparency = 0.3
	light(glow, Color3.fromRGB(80, 200, 255), 10, 1.2)
	for k = 0, 2 do
		local post = cf * CFrame.Angles(0, math.rad(120 * k), 0) * CFrame.new(0, 3.5, -3.8)
		deco(part(m, "Post", Vector3.new(0.5, 7, 0.5), post, Color3.fromRGB(200, 204, 214)))
		deco(
			part(
				m,
				"PostLight",
				Vector3.new(0.55, 0.5, 0.55),
				post * CFrame.new(0, 3, 0),
				Color3.fromRGB(80, 200, 255),
				Enum.Material.Neon
			)
		)
	end
	m.Parent = parent
	return m
end

local POSTERS = {
	"DUST IS TEMPORARY.\nDEADLINES ARE FOREVER.",
	"STOP BEING LAZY.\nYOU HAVE A WHOLE MOON TO CLEAN.",
	"BUDGET UPDATE:\nTOOTHBRUSHES ARE NOW SHARED.",
	"EMPLOYEE OF THE MONTH:\nTHE BROOM.",
}

local function kitchenette(parent: Instance, cf: CFrame, posterIndex: number)
	local m = Instance.new("Model")
	m.Name = "Kitchenette"
	part(m, "Counter", Vector3.new(9, 3.4, 3), cf * CFrame.new(0, 1.7, 0), WHITE)
	deco(part(m, "Top", Vector3.new(9.2, 0.3, 3.2), cf * CFrame.new(0, 3.5, 0), Color3.fromRGB(60, 64, 74)))
	deco(part(m, "Coffee", Vector3.new(1.4, 2, 1.4), cf * CFrame.new(-2.8, 4.65, 0), Color3.fromRGB(30, 33, 40)))
	local cup = deco(part(m, "Mug", Vector3.new(0.6, 0.6, 0.6), cf * CFrame.new(-1.6, 3.95, 0.2), ORANGE))
	cup.Shape = Enum.PartType.Cylinder
	part(m, "Fridge", Vector3.new(3, 7, 3), cf * CFrame.new(6.3, 3.5, 0), Color3.fromRGB(220, 224, 232))
	deco(part(m, "FridgeHandle", Vector3.new(0.2, 2, 0.3), cf * CFrame.new(5.2, 4.5, -1.6), FRAME))
	local poster =
		deco(part(m, "Poster", Vector3.new(5, 6.5, 0.1), cf * CFrame.new(0, 9, 1.4), Color3.fromRGB(30, 33, 40)))
	local gui = textPanel(poster, Enum.NormalId.Front, Vector2.new(250, 325))
	local stripe = Instance.new("Frame")
	stripe.Size = UDim2.fromScale(1, 0.1)
	stripe.BackgroundColor3 = ORANGE
	stripe.BorderSizePixel = 0
	stripe.Parent = gui
	label(
		gui,
		POSTERS[(posterIndex - 1) % #POSTERS + 1],
		UDim2.fromScale(0.08, 0.2),
		UDim2.fromScale(0.84, 0.6),
		Color3.fromRGB(240, 242, 245)
	)
	label(gui, "MOON MOP CO.", UDim2.fromScale(0.08, 0.84), UDim2.fromScale(0.84, 0.1), ORANGE)
	m.Parent = parent
end

-- The robot boss who hires you (stands by the supply wall).
local function boss(parent: Instance, cf: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "BossBot"
	local wheel = part(
		m,
		"Wheel",
		Vector3.new(1.4, 2.4, 2.4),
		cf * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		FRAME
	)
	wheel.Shape = Enum.PartType.Cylinder
	part(m, "Body", Vector3.new(2.6, 3.4, 2), cf * CFrame.new(0, 4, 0), WHITE)
	deco(part(m, "Tie", Vector3.new(0.5, 1.8, 0.1), cf * CFrame.new(0, 4.3, -1.05), ORANGE))
	local head = part(m, "Head", Vector3.new(3, 2.2, 2.2), cf * CFrame.new(0, 6.9, 0), WHITE)
	local screen = deco(
		part(
			m,
			"Face",
			Vector3.new(2.5, 1.6, 0.1),
			cf * CFrame.new(0, 6.9, -1.12),
			Color3.fromRGB(12, 16, 22),
			Enum.Material.Glass
		)
	)
	local gui = textPanel(screen, Enum.NormalId.Front, Vector2.new(200, 128))
	gui.LightInfluence = 0
	gui.Brightness = 2
	label(gui, "- _ -", UDim2.fromScale(0.1, 0.15), UDim2.fromScale(0.8, 0.7), TEAL).Name = "Eyes"
	deco(part(m, "Antenna", Vector3.new(0.15, 1.2, 0.15), cf * CFrame.new(0.8, 8.5, 0), FRAME))
	local bulb =
		deco(part(m, "Bulb", Vector3.new(0.4, 0.4, 0.4), cf * CFrame.new(0.8, 9.2, 0), ORANGE, Enum.Material.Neon))
	bulb.Shape = Enum.PartType.Ball
	for s = -1, 1, 2 do
		deco(
			part(
				m,
				"Arm",
				Vector3.new(0.4, 2.6, 0.4),
				cf * CFrame.new(s * 1.6, 4.3, 0) * CFrame.Angles(0, 0, math.rad(s * 12)),
				Color3.fromRGB(150, 156, 170)
			)
		)
	end
	m.PrimaryPart = head
	m.Parent = parent
	return m
end

-- The pod cannon on the roof.
local function cannon(parent: Instance, roof: CFrame): CFrame
	local m = Instance.new("Model")
	m.Name = "PodCannon"
	local mount = roof * CFrame.new(12, 0, 8)
	local ring = part(
		m,
		"Turret",
		Vector3.new(2, 7, 7),
		mount * CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(60, 64, 74)
	)
	ring.Shape = Enum.PartType.Cylinder
	local barrelCf = mount * CFrame.new(0, 5.5, 0) * CFrame.Angles(math.rad(-25), 0, 0)
	local barrel = part(m, "Barrel", Vector3.new(10, 3.4, 3.4), barrelCf * CFrame.Angles(0, 0, math.rad(90)), WHITE)
	barrel.Shape = Enum.PartType.Cylinder
	for k = -1, 1 do
		local band = deco(
			part(
				m,
				"Band",
				Vector3.new(0.5, 3.8, 3.8),
				barrelCf * CFrame.new(0, k * 3, 0) * CFrame.Angles(0, 0, math.rad(90)),
				ORANGE
			)
		)
		band.Shape = Enum.PartType.Cylinder
	end
	local muzzle = deco(
		part(
			m,
			"Muzzle",
			Vector3.new(0.3, 2.6, 2.6),
			barrelCf * CFrame.new(0, 5.1, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(110, 230, 255),
			Enum.Material.Neon
		)
	)
	muzzle.Shape = Enum.PartType.Cylinder
	m.Parent = parent
	return barrelCf * CFrame.new(0, 5.4, 0)
end

local function build(base: CFrame, sign: string, index: number, kit: Instance?): (Model, Anchors)
	local model = Instance.new("Model")
	model.Name = "Station_" .. sign
	local a = W / 2
	octagon(
		model,
		"Plinth",
		base * CFrame.new(0, PLINTH / 2, 0),
		a + 6,
		C + 3,
		PLINTH,
		CONCRETE,
		Enum.Material.Concrete
	)
	local floor = base * CFrame.new(0, PLINTH, 0)
	-- inner floor, ceiling and roof
	octagon(model, "Floor", floor * CFrame.new(0, 0.05, 0), a - 0.2, C - 0.1, 0.1, FLOOR_LINE)
	octagon(model, "Ceiling", floor * CFrame.new(0, H - 0.4, 0), a, C, 0.8, Color3.fromRGB(214, 218, 226))
	octagon(model, "RoofRim", floor * CFrame.new(0, H + 0.4, 0), a - 0.6, C - 0.3, 0.8, Color3.fromRGB(210, 214, 222))
	octagon(model, "RoofCap", floor * CFrame.new(0, H + 1.1, 0), a - 3, C - 1, 0.8, WHITE)
	vent(model, floor * CFrame.new(0, H + 1.6, 0) * CFrame.Angles(math.rad(-90), 0, 0), 10, 6)
	local decor = Instance.new("Model")
	decor.Name = "Decor"
	decor.Parent = model
	local walls = Instance.new("Model")
	walls.Name = "Walls"
	walls.Parent = model
	local mainLen = W - 2 * C
	local cornerLen = C * math.sqrt(2)
	local cornerDist = (2 * a - C) / math.sqrt(2)
	for i = 0, 7 do
		local ang = math.rad(45 * i)
		local isCorner = i % 2 == 1
		local dist = if isCorner then cornerDist else a
		local cf = floor * CFrame.Angles(0, -ang, 0) * CFrame.new(0, 0, -dist) * CFrame.Angles(0, math.pi, 0)
		local kind = if not isCorner then "main" elseif i == 1 then "door" else "corner"
		face(decor, cf, if isCorner then cornerLen else mainLen, kind, sign)
		wall(walls, cf, if isCorner then cornerLen else mainLen, kind == "door")
	end
	local doorCf = floor * CFrame.Angles(0, -math.rad(45), 0) * CFrame.new(0, 0, -cornerDist)
	for s = 1, 2 do
		local h = PLINTH * (3 - s) / 3
		part(
			model,
			"Step",
			Vector3.new(9, h, 2),
			doorCf * CFrame.new(0, -PLINTH + h / 2, -5 - 2 * s),
			CONCRETE,
			Enum.Material.Concrete
		)
	end

	-- interior (faces: index 0 = -Z main, 2 = +X main, 4 = +Z main, 6 = -X main; door at 1)
	local inside = Instance.new("Model")
	inside.Name = "Interior"
	inside.Parent = model
	hexFloor(inside, floor, a - T - 0.5, kit)
	local function wallAnchor(i: number, inset: number): CFrame
		return floor
			* CFrame.Angles(0, -math.rad(45 * i), 0)
			* CFrame.new(0, 0, -(a - T - inset))
			* CFrame.Angles(0, math.pi, 0)
	end
	local supplyCf = wallAnchor(4, 0.3)
	supplyWall(inside, supplyCf)
	local boardCf = wallAnchor(6, 0.3)
	boardConsole(inside, boardCf)
	local drumCf = wallAnchor(2, 7)
	drum(inside, drumCf)
	local globeCf = floor * CFrame.new(-4, 0, 4)
	globe(inside, globeCf)
	local teleCf = wallAnchor(0, 6)
	teleportPad(inside, teleCf)
	kitchenette(inside, wallAnchor(5, 1.8), index)
	local bossCf = supplyCf * CFrame.new(11.5, 0, -3) * CFrame.Angles(0, math.rad(-30), 0)
	boss(inside, bossCf)
	-- ceiling lights
	for k = 0, 3 do
		local lamp = deco(
			part(
				inside,
				"CeilingLight",
				Vector3.new(6, 0.3, 1.2),
				floor * CFrame.Angles(0, math.rad(45 + 90 * k), 0) * CFrame.new(0, H - 0.95, -12),
				Color3.fromRGB(240, 246, 255),
				Enum.Material.Neon
			)
		)
		light(lamp, Color3.fromRGB(235, 242, 255), 30, 1.1)
	end
	local cannonMuzzle = cannon(model, floor * CFrame.new(0, H + 1.5, 0))

	model.PrimaryPart = (model:FindFirstChild("Plinth") :: Model):FindFirstChild("X") :: Part
	local anchors: Anchors = {
		drum = drumCf,
		supply = supplyCf,
		board = boardCf,
		globe = globeCf,
		teleport = teleCf,
		cannon = cannonMuzzle,
		boss = bossCf,
		door = doorCf,
		spawn = doorCf * CFrame.new(0, 0.5, 8),
		floor = floor,
	}
	return model, anchors
end

return build
