--!strict
-- Moon Mop: builds a stylised outpost station from Parts (no meshes, no imports).
-- Look follows the reference frames (p1_10900, p2_19300): a white octagonal tower on a concrete
-- plinth, panel seams, tall bright-blue window strips, black louvred vents, orange pinstripes,
-- orange-rimmed intake hatches at the base, and a door with a station sign on one corner face.
-- Usage (Studio command bar or MCP execute_luau):
--   local build = require(game.ServerStorage.BuildStation)
--   local model = build(CFrame.new(0, groundY, 0), "N STATION")
-- The CFrame is the centre of the plinth's underside; its UpVector is the local up, so the same
-- call works anywhere on the round Moon.

local W = 56 -- across flats (reference: about ten player heights)
local C = 14 -- corner chamfer
local H = 44 -- wall height above the plinth
local PLINTH = 1.4
local BASE = 7 -- height of the lower band
local TOP = 38 -- start of the upper vent band
local MID = (BASE + TOP) / 2
local WIN_H = TOP - BASE - 6

local WHITE = Color3.fromRGB(236, 238, 243)
local SEAM = Color3.fromRGB(178, 184, 196)
local ORANGE = Color3.fromRGB(240, 110, 30)
local BLUE = Color3.fromRGB(52, 150, 240)
local BLUE_HI = Color3.fromRGB(150, 210, 255)
local FRAME = Color3.fromRGB(28, 31, 38)
local VENT = Color3.fromRGB(20, 22, 27)
local CONCRETE = Color3.fromRGB(150, 153, 162)

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

-- Solid octagon (flats 2a, chamfer c) from two crossed boxes and four 45-degree corner boxes.
local function octagon(parent: Instance, name: string, cf: CFrame, a: number, c: number, h: number, color: Color3, mat: Enum.Material?)
	local m = Instance.new("Model")
	m.Name = name
	part(m, "X", Vector3.new(2 * a, h, 2 * (a - c)), cf, color, mat)
	part(m, "Z", Vector3.new(2 * (a - c), h, 2 * a), cf, color, mat)
	local len = c * math.sqrt(2)
	local depth = c / math.sqrt(2)
	local dist = (2 * a - c) / math.sqrt(2) - depth / 2
	for i = 0, 3 do
		local ang = math.rad(45 + 90 * i)
		local corner = cf * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0, -dist)
		part(m, "Corner", Vector3.new(len, h, depth), corner, color, mat)
	end
	m.Parent = parent
	return m
end

-- Black louvred vent: dark backing with thin horizontal slats.
local function vent(parent: Instance, cf: CFrame, w: number, h: number)
	part(parent, "VentBack", Vector3.new(w, h, 0.3), cf, VENT)
	local n = math.max(3, math.floor(h / 0.45))
	for i = 1, n - 1 do
		local y = -h / 2 + i * h / n
		part(parent, "Slat", Vector3.new(w - 0.2, 0.08, 0.25), cf * CFrame.new(0, y, -0.18) * CFrame.Angles(math.rad(-25), 0, 0), Color3.fromRGB(48, 52, 60))
	end
end

-- Tall window strip: dark frame, bright blue glass, a lighter highlight stripe.
local function window(parent: Instance, cf: CFrame, w: number, h: number)
	part(parent, "WinFrame", Vector3.new(w + 0.5, h + 0.5, 0.3), cf, FRAME)
	part(parent, "Glass", Vector3.new(w, h, 0.3), cf * CFrame.new(0, 0, -0.08), BLUE)
	part(parent, "GlassHi", Vector3.new(w * 0.22, h * 0.92, 0.3), cf * CFrame.new(-w * 0.28, 0, -0.1), BLUE_HI)
end

-- Rounded-looking intake hatch: orange rim, dark louvred inset.
local function hatch(parent: Instance, cf: CFrame, w: number, h: number)
	part(parent, "HatchRim", Vector3.new(w, h, 0.35), cf, ORANGE)
	vent(parent, cf * CFrame.new(0, 0, -0.12), w - 0.7, h - 0.7)
end

local function door(parent: Instance, cf: CFrame, sign: string)
	part(parent, "DoorFrame", Vector3.new(6.4, 8.6, 0.4), cf * CFrame.new(0, 4.3, 0), FRAME)
	for s = -1, 1, 2 do
		local leaf = cf * CFrame.new(s * 1.45, 4, -0.1)
		part(parent, "DoorLeaf", Vector3.new(2.7, 7.6, 0.3), leaf, Color3.fromRGB(205, 210, 220))
		part(parent, "DoorWin", Vector3.new(0.7, 4.2, 0.3), leaf * CFrame.new(-s * 0.6, 0.8, -0.05), BLUE)
		part(parent, "DoorStripe", Vector3.new(2.7, 0.25, 0.3), leaf * CFrame.new(0, -2.6, -0.05), ORANGE)
	end
	local lamp = part(parent, "DoorLamp", Vector3.new(0.7, 0.35, 0.35), cf * CFrame.new(0, 8.9, -0.2), Color3.fromRGB(255, 190, 120), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 200, 150)
	light.Range = 12
	light.Brightness = 1.2
	light.Parent = lamp
	-- sign panel: white card with an orange border, an Earth badge and the station name
	local signCf = cf * CFrame.new(0, 15.5, -0.05)
	part(parent, "SignBorder", Vector3.new(4.6, 6.4, 0.3), signCf, Color3.fromRGB(200, 60, 40))
	local card = part(parent, "Sign", Vector3.new(4.1, 5.9, 0.3), signCf * CFrame.new(0, 0, -0.06), WHITE)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(164, 236)
	gui.LightInfluence = 1
	gui.Parent = card
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
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(164, 50)
	label.Position = UDim2.fromOffset(0, 162)
	label.BackgroundTransparency = 1
	label.Text = sign
	label.TextColor3 = Color3.fromRGB(26, 30, 40)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = gui
end

-- Decorate one wall face. cf sits on the wall surface at plinth height, LookVector outward.
local function face(parent: Instance, cf: CFrame, len: number, kind: string, sign: string)
	local out = cf * CFrame.Angles(0, math.pi, 0) -- parts' Front faces outward
	local function at(x: number, y: number, z: number?): CFrame
		return out * CFrame.new(x, y, -(z or 0))
	end
	-- seams: horizontal at band edges, vertical every ~5 studs on the upper body
	for _, y in { BASE + 0.1, MID, TOP - 0.1 } do
		part(parent, "SeamH", Vector3.new(len, 0.14, 0.12), at(0, y, 0.02), SEAM)
	end
	local cols = math.max(2, math.floor(len / 5))
	for i = 1, cols - 1 do
		local x = -len / 2 + i * len / cols
		part(parent, "SeamV", Vector3.new(0.12, TOP - BASE, 0.12), at(x, (BASE + TOP) / 2, 0.02), SEAM)
	end
	-- orange pinstripes above the base band and below the top band
	part(parent, "Stripe", Vector3.new(len + 0.05, 0.4, 0.16), at(0, BASE + 0.6, 0.04), ORANGE)
	part(parent, "Stripe", Vector3.new(len + 0.05, 0.4, 0.16), at(0, TOP - 0.7, 0.04), ORANGE)
	-- upper vent band: a long louvre on main faces, a short one on corners
	vent(parent, at(0, TOP + 2.8, 0.08), len * (kind == "main" and 0.7 or 0.55), 2.2)
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

local function build(base: CFrame, sign: string?): Model
	local signText = sign or "N STATION"
	local model = Instance.new("Model")
	model.Name = "Station"
	local a = W / 2
	-- plinth with a step in front of the door
	octagon(model, "Plinth", base * CFrame.new(0, PLINTH / 2, 0), a + 6, C + 3, PLINTH, CONCRETE, Enum.Material.Concrete)
	local floor = base * CFrame.new(0, PLINTH, 0)
	octagon(model, "Body", floor * CFrame.new(0, H / 2, 0), a, C, H, WHITE)
	octagon(model, "RoofRim", floor * CFrame.new(0, H + 0.4, 0), a - 0.6, C - 0.3, 0.8, Color3.fromRGB(210, 214, 222))
	octagon(model, "RoofCap", floor * CFrame.new(0, H + 1.1, 0), a - 3, C - 1, 0.8, WHITE)
	vent(model, floor * CFrame.new(0, H + 1.6, 0) * CFrame.Angles(math.rad(-90), 0, 0), 10, 6)
	local decor = Instance.new("Model")
	decor.Name = "Decor"
	decor.Parent = model
	-- eight faces: main faces on the axes, corner faces at 45 degrees; the door corner faces +X -Z
	local mainLen = W - 2 * C
	local cornerLen = C * math.sqrt(2)
	local cornerDist = (2 * a - C) / math.sqrt(2)
	for i = 0, 7 do
		local ang = math.rad(45 * i)
		local isCorner = i % 2 == 1
		local dist = isCorner and cornerDist or a
		local cf = floor * CFrame.Angles(0, -ang, 0) * CFrame.new(0, 0, -dist) * CFrame.Angles(0, math.pi, 0)
		local kind = if not isCorner then "main" elseif i == 1 then "door" else "corner"
		face(decor, cf, isCorner and cornerLen or mainLen, kind, signText)
	end
	-- steps down from the door to the plinth edge
	local doorCf = floor * CFrame.Angles(0, -math.rad(45), 0) * CFrame.new(0, 0, -cornerDist)
	for s = 1, 2 do
		local h = PLINTH * (3 - s) / 3
		part(model, "Step", Vector3.new(8, h, 2), doorCf * CFrame.new(0, -PLINTH + h / 2, -5 - 2 * s), CONCRETE, Enum.Material.Concrete)
	end
	model.PrimaryPart = (model:FindFirstChild("Body") :: Model):FindFirstChild("X") :: Part
	return model
end

return build
