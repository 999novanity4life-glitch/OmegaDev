--!strict
-- The lab atrium and its elevator pods. Walk into a pod to join its party;
-- the first one in is the host and picks Solo or Public and the max size.
-- GO (or a full public pod) closes the doors, plays the ride and starts a match.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Validate = require(Shared:WaitForChild("Validate"))
local PartyRules = require(Shared:WaitForChild("PartyRules"))
local RemoteGuard = require(script.Parent.RemoteGuard)
local MatchService = require(script.Parent.MatchService)
local LabKit = require(script.Parent.LabKit)

local LobbyService = {}

type Pod = {
	name: string,
	model: Model,
	center: Vector3, -- interior floor centre
	doorL: BasePart,
	doorR: BasePart,
	doorClosed: { CFrame },
	doorOpen: { CFrame },
	sign: TextLabel,
	host: Player?,
	mode: string,
	max: number,
	members: { Player },
	startAt: number?,
	launching: boolean,
}

local C = {
	Floor = Color3.fromRGB(52, 48, 70),
	Wall = Color3.fromRGB(44, 38, 64),
	WallLight = Color3.fromRGB(70, 62, 98),
	Trim = Config.Colors.Trim,
	Hazard = Color3.fromRGB(255, 196, 40),
	Dark = Color3.fromRGB(26, 22, 36),
	Glass = Color3.fromRGB(150, 255, 190),
	Steel = Color3.fromRGB(150, 156, 176),
	White = Color3.fromRGB(235, 240, 255),
}
local POD_W, POD_D, POD_H = 12, 12, 14

local notify = Remotes.get("Notify")
local pods: { Pod } = {}
local lobbyFolder: Folder
local spawnCFrame = CFrame.new()

-- Structural parts get a PBR kit material picked from their role.
local function part(props: { [string]: any }, parent: Instance): Part
	if props.Kit == nil and props.Material ~= Enum.Material.Neon and props.Material ~= Enum.Material.Glass then
		local color = props.Color
		if props.Name == "Floor" then
			props.Kit, props.Color = "SR_Tile", Color3.fromRGB(205, 210, 222)
		elseif props.Material == Enum.Material.DiamondPlate then
			props.Kit, props.Color = "SR_Grate", Color3.fromRGB(160, 160, 178)
		elseif color == C.Wall or color == C.WallLight then
			props.Kit = "SR_WallPlain"
		elseif color == C.Steel then
			props.Kit = "SR_Steel"
		elseif color == C.Dark then
			props.Kit, props.Color = "SR_Steel", Color3.fromRGB(64, 60, 82)
		elseif color == C.Hazard then
			props.Kit, props.Color = "SR_Hazard", Color3.new(1, 1, 1)
		end
		if props.Kit then
			props.Material = nil
		end
	end
	return LabKit.part(props, parent)
end

local function deco(props: { [string]: any }, parent: Instance): Part
	props.CanCollide = false
	props.CanQuery = false
	props.CastShadow = false
	return part(props, parent)
end

local function surfaceText(target: BasePart, face: Enum.NormalId, text: string, color: Color3, ppm: number?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.PixelsPerStud = ppm or 30
	gui.LightInfluence = 0
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.FontFace = Font.fromName("FredokaOne")
	label.TextColor3 = color
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = C.Dark
	stroke.Parent = label
	label.Parent = gui
	return label
end

local function slimeTank(parent: Instance, pos: Vector3, height: number, radius: number)
	local mesh = LabKit.prop("Tank", CFrame.new(pos), height, parent, true)
	if mesh then
		local glow = Instance.new("PointLight")
		glow.Color = Config.Colors.Slime
		glow.Range = 24
		glow.Brightness = 1.8
		glow.Parent = mesh
		local bubbles = Instance.new("ParticleEmitter")
		bubbles.Color = ColorSequence.new(Color3.fromRGB(220, 255, 200))
		bubbles.LightEmission = 0.6
		bubbles.Size = NumberSequence.new(0.2, 0.5)
		bubbles.Lifetime = NumberRange.new(1.5, 2.5)
		bubbles.Speed = NumberRange.new(2, 4)
		bubbles.Rate = 10
		bubbles.Parent = mesh
		return
	end
	part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.5, radius * 2 + 2, radius * 2 + 2),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.75, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.Steel,
	}, parent)
	part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.5, radius * 2 + 2, radius * 2 + 2),
		CFrame = CFrame.new(pos + Vector3.new(0, height + 0.75, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.Steel,
	}, parent)
	local glass = part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height - 1.5, radius * 2, radius * 2),
		CFrame = CFrame.new(pos + Vector3.new(0, height / 2 + 0.75, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.Glass,
		Material = Enum.Material.Glass,
		Transparency = 0.5,
	}, parent)
	local slime = deco({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height * 0.7, radius * 2 - 0.8, radius * 2 - 0.8),
		CFrame = CFrame.new(pos + Vector3.new(0, height * 0.35 + 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Config.Colors.Slime,
		Material = Enum.Material.Neon,
		Transparency = 0.25,
	}, parent)
	local light = Instance.new("PointLight")
	light.Color = Config.Colors.Slime
	light.Range = 22
	light.Brightness = 1.6
	light.Parent = slime
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Color = ColorSequence.new(Color3.fromRGB(220, 255, 200))
	bubbles.LightEmission = 0.6
	bubbles.Size = NumberSequence.new(0.25, 0.6)
	bubbles.Lifetime = NumberRange.new(1.5, 3)
	bubbles.Speed = NumberRange.new(2, 4)
	bubbles.EmissionDirection = Enum.NormalId.Right
	bubbles.Rate = 12
	bubbles.Parent = slime
	local _ = glass
end

local function buildPod(parent: Instance, index: number, x: number, wallZ: number): Pod
	local name = string.char(64 + index) -- A, B, C
	local model = Instance.new("Model")
	model.Name = "Elevator" .. name
	model.Parent = parent
	local back = wallZ - POD_D
	local cz = wallZ - POD_D / 2
	part({
		Size = Vector3.new(POD_W + 2, 1, POD_D),
		Position = Vector3.new(x, 0.5 - 1, cz),
		Color = C.Dark,
		Material = Enum.Material.DiamondPlate,
	}, model)
	part({ Size = Vector3.new(POD_W + 2, 1, POD_D), Position = Vector3.new(x, POD_H + 0.5, cz), Color = C.Dark }, model)
	part({
		Size = Vector3.new(1, POD_H, POD_D),
		Position = Vector3.new(x - POD_W / 2 - 0.5, POD_H / 2, cz),
		Color = C.WallLight,
	}, model)
	part({
		Size = Vector3.new(1, POD_H, POD_D),
		Position = Vector3.new(x + POD_W / 2 + 0.5, POD_H / 2, cz),
		Color = C.WallLight,
	}, model)
	part({
		Size = Vector3.new(POD_W + 2, POD_H, 1),
		Position = Vector3.new(x, POD_H / 2, back - 0.5),
		Color = C.WallLight,
	}, model)
	-- Ceiling light strip and handrail.
	local strip = deco({
		Size = Vector3.new(POD_W - 2, 0.3, 2),
		Position = Vector3.new(x, POD_H - 0.2, cz),
		Color = C.White,
		Material = Enum.Material.Neon,
	}, model)
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Bottom
	light.Brightness = 2
	light.Range = 14
	light.Color = Color3.fromRGB(220, 255, 230)
	light.Parent = strip
	deco({ Size = Vector3.new(POD_W - 1, 0.4, 0.4), Position = Vector3.new(x, 4, back + 0.6), Color = C.Steel }, model)
	-- Floor-number panel inside.
	local panel = deco(
		{ Size = Vector3.new(3, 2, 0.3), Position = Vector3.new(x + POD_W / 2 - 1, 7, back + 0.3), Color = C.Dark },
		model
	)
	surfaceText(panel, Enum.NormalId.Front, "B7", Config.Colors.Slime)
	-- Door frame with hazard stripes.
	for _, side in { -1, 1 } do
		deco({
			Size = Vector3.new(1.2, POD_H + 1, 1.6),
			Position = Vector3.new(x + side * (POD_W / 2 + 0.6), POD_H / 2, wallZ + 0.3),
			Color = C.Hazard,
			Material = Enum.Material.SmoothPlastic,
		}, model)
	end
	deco({
		Size = Vector3.new(POD_W + 2.4, 1.2, 1.6),
		Position = Vector3.new(x, POD_H + 0.6, wallZ + 0.3),
		Color = C.Hazard,
		Material = Enum.Material.SmoothPlastic,
	}, model)
	-- Sliding doors.
	local half = POD_W / 2
	local closedL = CFrame.new(x - half / 2, POD_H / 2, wallZ)
	local closedR = CFrame.new(x + half / 2, POD_H / 2, wallZ)
	local openL = closedL * CFrame.new(-half + 0.3, 0, -0.6)
	local openR = closedR * CFrame.new(half - 0.3, 0, -0.6)
	local doorL = part({ Name = "DoorL", Size = Vector3.new(half, POD_H, 0.6), CFrame = openL, Color = C.Steel }, model)
	local doorR = part({ Name = "DoorR", Size = Vector3.new(half, POD_H, 0.6), CFrame = openR, Color = C.Steel }, model)
	for _, door in { doorL, doorR } do
		local window = deco({
			Size = Vector3.new(half - 2, 3, 0.7),
			CFrame = door.CFrame * CFrame.new(0, 2.5, 0),
			Color = Config.Colors.Slime,
			Material = Enum.Material.Neon,
			Transparency = 0.4,
		}, model)
		window.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = door
		weld.Part1 = window
		weld.Parent = door
	end
	-- Sign above the door.
	local signPart = deco(
		{ Size = Vector3.new(POD_W, 3.2, 0.4), Position = Vector3.new(x, POD_H + 3, wallZ + 0.4), Color = C.Dark },
		model
	)
	local sign = surfaceText(signPart, Enum.NormalId.Front, "ELEVATOR " .. name, Config.Colors.Slime)
	-- Floor marking in front.
	deco({
		Size = Vector3.new(POD_W, 0.1, 6),
		Position = Vector3.new(x, 0.06, wallZ + 3.5),
		Color = C.Hazard,
		Material = Enum.Material.Neon,
		Transparency = 0.6,
	}, model)
	return {
		name = name,
		model = model,
		center = Vector3.new(x, 0, cz),
		doorL = doorL,
		doorR = doorR,
		doorClosed = { closedL, closedR },
		doorOpen = { openL, openR },
		sign = sign,
		host = nil,
		mode = "Public",
		max = Config.Party.DefaultMax,
		members = {},
		startAt = nil,
		launching = false,
	}
end

-- Dense set dressing for the atrium (detail bar: no bare surfaces).
-- Panel grid over every lobby wall (skipping the pod openings): kick band with a
-- contact shadow at the bottom, weighted specials above, a trim line on top.
local function panelWalls(folder: Folder, o: Vector3, w: number, h: number, d: number)
	local rand = Random.new(7)
	local rowH = 10.5
	local rows = math.floor(h / rowH)
	local podXs = {}
	for p = 1, Config.Party.PodCount do
		table.insert(podXs, (p - (Config.Party.PodCount + 1) / 2) * 36)
	end
	type WallRun = { start: Vector3, dir: Vector3, normal: Vector3, length: number, north: boolean }
	local walls: { WallRun } = {
		{
			start = o + Vector3.new(-w / 2, 0, -d / 2),
			dir = Vector3.xAxis,
			normal = Vector3.zAxis,
			length = w,
			north = true,
		},
		{
			start = o + Vector3.new(w / 2, 0, d / 2),
			dir = -Vector3.xAxis,
			normal = -Vector3.zAxis,
			length = w,
			north = false,
		},
		{
			start = o + Vector3.new(-w / 2, 0, d / 2),
			dir = -Vector3.zAxis,
			normal = Vector3.xAxis,
			length = d,
			north = false,
		},
		{
			start = o + Vector3.new(w / 2, 0, -d / 2),
			dir = Vector3.zAxis,
			normal = -Vector3.xAxis,
			length = d,
			north = false,
		},
	}
	local below: { [string]: string } = {}
	for wi, wall in walls do
		local start, dir, normal = wall.start, wall.dir, wall.normal
		local length, isNorth = wall.length, wall.north
		local cols = math.floor(length / 10)
		local cellW = length / cols
		local left: string? = nil
		for col = 0, cols - 1 do
			local along = (col + 0.5) * cellW
			local base = start + dir * along + normal * 0.16
			local blocked = false
			if isNorth then
				local x = base.X - o.X
				for _, px in podXs do
					if math.abs(x - px) < 9 then
						blocked = true
					end
				end
			end
			for row = 1, rows do
				local y = (row - 0.5) * rowH
				if blocked and y < 16 then
					continue
				end
				local kit = if row == 1
					then "SR_WallBase"
					else LabKit.pickPanel(
						rand,
						if row == 2 then left else nil,
						below[wi .. ":" .. col .. ":" .. (row - 1)]
					)
				below[wi .. ":" .. col .. ":" .. row] = kit
				if row == 2 then
					left = kit
				end
				local pos = base + Vector3.new(0, y, 0)
				local panel = LabKit.part({
					Size = Vector3.new(cellW - 0.1, rowH - 0.1, 0.3),
					CFrame = CFrame.lookAt(pos, pos + normal),
					Kit = kit,
				}, folder)
				if row == 1 then
					LabKit.decal(panel, "Shadow", Enum.NormalId.Front, nil, 0.15)
				end
			end
			local top = base + Vector3.new(0, rows * rowH + 0.9, 0)
			LabKit.deco(
				{ Size = Vector3.new(cellW, 1.6, 0.4), CFrame = CFrame.lookAt(top, top + normal), Kit = "SR_Trim" },
				folder
			)
		end
	end
end

local function dressLobby(folder: Folder, o: Vector3, w: number, h: number, d: number)
	panelWalls(folder, o, w, h, d)
	-- Floor story: the lab emblem in the middle, walkways to every elevator.
	LabKit.deco(
		{ Size = Vector3.new(22, 0.06, 22), CFrame = CFrame.new(o + Vector3.new(0, 0.03, -10)), Kit = "SR_Emblem" },
		folder
	)
	for p = 1, Config.Party.PodCount do
		local px = (p - (Config.Party.PodCount + 1) / 2) * 36
		for k = 0, 3 do
			local z = -24 - k * 5.5
			local pos = o + Vector3.new(px * (0.35 + k * 0.2), 0.04, z)
			LabKit.deco({ Size = Vector3.new(5, 0.06, 5.5), CFrame = CFrame.new(pos), Kit = "SR_Walkway" }, folder)
		end
	end
	-- A cracked tank leaking onto the floor (environmental story).
	for k, spec in { { -58, 18, 8 }, { -52, 14, 5 }, { -55, 9, 4 } } do
		local pos = o + Vector3.new(spec[1], 0.05 + k * 0.01, spec[2])
		LabKit.decalPlate(
			folder,
			CFrame.new(pos) * CFrame.Angles(0, math.rad(k * 60), 0) * CFrame.Angles(math.rad(90), 0, 0),
			Vector2.new(spec[3], spec[3] * 0.75),
			"Puddle"
		)
	end
	-- Warning plates beside each elevator door.
	for p = 1, Config.Party.PodCount do
		local px = (p - (Config.Party.PodCount + 1) / 2) * 36
		local pos = o + Vector3.new(px + 10, 9, -d / 2 + 0.4)
		LabKit.decalPlate(folder, CFrame.lookAt(pos, pos + Vector3.new(0, 0, 1)), Vector2.new(3, 3), "Warning")
	end
	-- Wall lights along both side walls, two heights.
	for _, side in { -1, 1 } do
		local x = side * (w / 2 - 0.6)
		for _, z in { -36, -12, 12, 36 } do
			local cf = CFrame.lookAt(o + Vector3.new(x, 12, z), o + Vector3.new(0, 12, z))
			LabKit.lightFixture(folder, cf, Color3.fromRGB(220, 240, 255), 30)
		end
		-- Server racks between the tanks.
		for _, z in { -12, 12 } do
			LabKit.serverRack(
				folder,
				CFrame.lookAt(o + Vector3.new(side * (w / 2 - 2.5), 0, z), o + Vector3.new(0, 0, z))
			)
		end
		-- Vents high up and a pipe cluster with gauges.
		for _, z in { -36, 36 } do
			LabKit.vent(
				folder,
				CFrame.lookAt(o + Vector3.new(side * (w / 2 - 0.2), 26, z), o + Vector3.new(0, 26, z)),
				6
			)
		end
		local pipeCf = CFrame.lookAt(o + Vector3.new(side * (w / 2 - 2), 0, 44), o + Vector3.new(0, 0, 44))
		if not LabKit.prop("Pipes", pipeCf, 8, folder) then
			LabKit.deco(
				{ Size = Vector3.new(1.5, 8, 6), CFrame = pipeCf * CFrame.new(0, 4, 0), Kit = "SR_Steel" },
				folder
			)
		end
		LabKit.gauge(folder, CFrame.lookAt(o + Vector3.new(side * (w / 2 - 0.5), 6, 38), o + Vector3.new(0, 6, 38)))
		LabKit.gauge(folder, CFrame.lookAt(o + Vector3.new(side * (w / 2 - 0.5), 4.5, 40), o + Vector3.new(0, 4.5, 40)))
	end
	-- Crate stacks in the corners.
	for _, c in { { -60, 40 }, { -56, 42 }, { 60, 40 }, { 56, 42 }, { -62, -30 }, { 62, -30 } } do
		local cf = CFrame.new(o + Vector3.new(c[1], 0, c[2])) * CFrame.Angles(0, math.rad(c[1] + c[2]), 0)
		LabKit.prop("Crates", cf, 5, folder, true)
	end
	-- Consoles on the reception desk and two standing ones by the pods.
	for _, x in { -5, 5 } do
		LabKit.prop("Console", CFrame.lookAt(o + Vector3.new(x, 4.5, 18.5), o + Vector3.new(x, 4.5, 30)), 2.6, folder)
	end
	for _, x in { -18, 18 } do
		LabKit.prop("Console", CFrame.lookAt(o + Vector3.new(x, 0, -42), o + Vector3.new(x, 0, 0)), 4.4, folder, true)
	end
	-- Ceiling cables between the light rows.
	for k = -2, 2 do
		local a = o + Vector3.new(k * 26 - 6, h - 1, -40)
		local b = o + Vector3.new(k * 26 + 6, h - 1, 40)
		LabKit.cable(folder, a, b, 4, if k % 2 == 0 then Config.Colors.SlimeDeep else nil)
	end
	-- Signs.
	LabKit.sign(
		folder,
		CFrame.lookAt(o + Vector3.new(0, 24, -d / 2 + 0.2), o + Vector3.new(0, 24, 0)),
		Vector2.new(30, 4),
		"ELEVATORS TO CONTAINMENT LEVEL B7"
	)
	LabKit.sign(
		folder,
		CFrame.lookAt(o + Vector3.new(0, 7.5, 20.9), o + Vector3.new(0, 7.5, 40)),
		Vector2.new(10, 2),
		"RECEPTION",
		Color3.new(1, 1, 1)
	)
	LabKit.sign(
		folder,
		CFrame.lookAt(o + Vector3.new(-w / 2 + 0.2, 8, -24), o + Vector3.new(0, 8, -24)),
		Vector2.new(9, 3),
		"AUTHORIZED PERSONNEL ONLY",
		Color3.fromRGB(255, 210, 60)
	)
	LabKit.sign(
		folder,
		CFrame.lookAt(o + Vector3.new(w / 2 - 0.2, 8, -24), o + Vector3.new(0, 8, -24)),
		Vector2.new(9, 3),
		"! SLIME LEVEL: CRITICAL !",
		Color3.fromRGB(255, 90, 90)
	)
	-- Benches facing the elevators.
	for _, x in { -30, 30 } do
		local cf = CFrame.new(o + Vector3.new(x, 0, 6))
		LabKit.part({
			Size = Vector3.new(10, 0.6, 2.4),
			CFrame = cf * CFrame.new(0, 1.8, 0),
			Kit = "SR_Steel",
			Color = Color3.fromRGB(90, 86, 110),
		}, folder)
		for _, lx in { -4, 4 } do
			LabKit.part({
				Size = Vector3.new(0.5, 1.6, 2),
				CFrame = cf * CFrame.new(lx, 0.8, 0),
				Kit = "SR_Steel",
				Color = Color3.fromRGB(60, 56, 76),
			}, folder)
		end
	end
end

local function buildAtrium(): Folder
	local size = Config.Lobby.Size
	local o = Config.Lobby.Origin
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	local w, h, d = size.X, size.Y, size.Z
	part({
		Name = "Floor",
		Size = Vector3.new(w, 2, d),
		Position = o + Vector3.new(0, -1, 0),
		Color = C.Floor,
		Material = Enum.Material.DiamondPlate,
	}, folder)
	part(
		{ Size = Vector3.new(w, 2, d), Position = o + Vector3.new(0, h + 1, 0), Color = C.Dark, Kit = "SR_Ceiling" },
		folder
	)
	local walls = {
		{ Vector3.new(0, h / 2, -d / 2 - 1), Vector3.new(w, h, 2) },
		{ Vector3.new(0, h / 2, d / 2 + 1), Vector3.new(w, h, 2) },
		{ Vector3.new(-w / 2 - 1, h / 2, 0), Vector3.new(2, h, d) },
		{ Vector3.new(w / 2 + 1, h / 2, 0), Vector3.new(2, h, d) },
	}
	for i, wall in walls do
		if i == 1 then
			-- North wall has holes for the pods: build it in strips around them.
			local xs = { -w / 2 }
			for p = 1, Config.Party.PodCount do
				local px = (p - (Config.Party.PodCount + 1) / 2) * 36
				table.insert(xs, px - POD_W / 2 - 1)
				table.insert(xs, px + POD_W / 2 + 1)
			end
			table.insert(xs, w / 2)
			for s = 1, #xs, 2 do
				local x0, x1 = xs[s], xs[s + 1]
				part({
					Size = Vector3.new(x1 - x0, h, 2),
					Position = o + Vector3.new((x0 + x1) / 2, h / 2, -d / 2 - 1),
					Color = C.Wall,
				}, folder)
			end
			for p = 1, Config.Party.PodCount do
				local px = (p - (Config.Party.PodCount + 1) / 2) * 36
				part({
					Size = Vector3.new(POD_W + 2, h - POD_H - 1, 2),
					Position = o + Vector3.new(px, POD_H + 1 + (h - POD_H - 1) / 2, -d / 2 - 1),
					Color = C.Wall,
				}, folder)
			end
		else
			part({ Size = wall[2], Position = o + wall[1], Color = C.Wall }, folder)
		end
	end
	-- Hazard skirting and ceiling light rows.
	for _, z in { -d / 2 + 0.2, d / 2 - 0.2 } do
		deco({
			Size = Vector3.new(w, 1.2, 0.2),
			Position = o + Vector3.new(0, 0.6, z),
			Color = C.Hazard,
			Material = Enum.Material.SmoothPlastic,
		}, folder)
	end
	for row = -1, 1 do
		for col = -2, 2 do
			local lamp = deco({
				Size = Vector3.new(14, 0.4, 3),
				Position = o + Vector3.new(col * 26, h - 0.3, row * 28),
				Color = C.White,
				Material = Enum.Material.Neon,
			}, folder)
			local light = Instance.new("SurfaceLight")
			light.Face = Enum.NormalId.Bottom
			light.Range = 60
			light.Brightness = 2.6
			light.Color = Color3.fromRGB(200, 230, 255)
			light.Parent = lamp
		end
	end
	-- Slime tanks along the side walls.
	for _, x in { -w / 2 + 10, w / 2 - 10 } do
		for _, z in { -24, 0, 24 } do
			slimeTank(folder, o + Vector3.new(x, 0, z), 22, 4.5)
		end
	end
	-- Ceiling pipes.
	for _, x in { -30, 30 } do
		deco({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(d, 1.6, 1.6),
			CFrame = CFrame.new(o + Vector3.new(x, h - 3, 0)) * CFrame.Angles(0, math.rad(90), 0),
			Color = Config.Colors.Slime,
			Material = Enum.Material.Neon,
			Transparency = 0.2,
		}, folder)
	end
	-- Reception desk and a big monitor wall.
	part({ Size = Vector3.new(20, 4, 5), Position = o + Vector3.new(0, 2, 18), Color = C.WallLight }, folder)
	part({ Size = Vector3.new(20.6, 0.5, 5.6), Position = o + Vector3.new(0, 4.25, 18), Color = C.Dark }, folder)
	deco({
		Size = Vector3.new(20.6, 0.3, 0.3),
		Position = o + Vector3.new(0, 3.6, 20.8),
		Color = Config.Colors.Slime,
		Material = Enum.Material.Neon,
	}, folder)
	local monitor = deco(
		{ Size = Vector3.new(40, 12, 0.6), Position = o + Vector3.new(0, h - 12, d / 2 - 0.4), Color = C.Dark },
		folder
	)
	surfaceText(monitor, Enum.NormalId.Back, "SLIME RISE LABS", Config.Colors.Slime, 20)
	local alert = deco(
		{ Size = Vector3.new(30, 4, 0.6), Position = o + Vector3.new(0, h - 21, d / 2 - 0.4), Color = C.Dark },
		folder
	)
	surfaceText(alert, Enum.NormalId.Back, "! CONTAINMENT BREACH: SECTOR 7 !", Color3.fromRGB(255, 80, 90), 20)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = o + Vector3.new(0, 0.5, 30)
	spawn.Color = C.Dark
	spawn.Material = Enum.Material.DiamondPlate
	spawn.Parent = folder
	spawnCFrame = CFrame.lookAt(o + Vector3.new(0, 4, 26), o + Vector3.new(0, 4, -40))
	dressLobby(folder, o, w, h, d)
	folder.Parent = workspace
	return folder
end

local function memberIds(pod: Pod): string
	local ids = {}
	for _, p in pod.members do
		table.insert(ids, tostring(p.UserId))
	end
	return table.concat(ids, ",")
end

local function publish(pod: Pod)
	pod.model:SetAttribute("Host", if pod.host then pod.host.UserId else 0)
	pod.model:SetAttribute("Mode", pod.mode)
	pod.model:SetAttribute("Max", pod.max)
	pod.model:SetAttribute("Count", #pod.members)
	pod.model:SetAttribute("Members", memberIds(pod))
	pod.model:SetAttribute("StartAt", pod.startAt or 0)
	pod.model:SetAttribute("Launching", pod.launching)
	if #pod.members == 0 then
		pod.sign.Text = "ELEVATOR " .. pod.name .. "  ·  OPEN"
	elseif pod.mode == "Solo" then
		pod.sign.Text = "ELEVATOR " .. pod.name .. "  ·  SOLO"
	else
		pod.sign.Text = string.format("ELEVATOR %s  ·  %d/%d", pod.name, #pod.members, pod.max)
	end
end

local function inside(pod: Pod, player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	local d = root.Position - pod.center
	return math.abs(d.X) <= POD_W / 2 and d.Z >= -POD_D / 2 and d.Z <= POD_D / 2 - 0.5 and d.Y > -1 and d.Y < POD_H
end

local function pushOut(pod: Pod, player: Player)
	local character = player.Character
	if character then
		character:PivotTo(
			CFrame.lookAt(pod.center + Vector3.new(0, 4, POD_D / 2 + 6), pod.center + Vector3.new(0, 4, 40))
		)
	end
end

local function setDoors(pod: Pod, closed: boolean)
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	TweenService:Create(pod.doorL, info, { CFrame = if closed then pod.doorClosed[1] else pod.doorOpen[1] }):Play()
	TweenService:Create(pod.doorR, info, { CFrame = if closed then pod.doorClosed[2] else pod.doorOpen[2] }):Play()
end

local function launch(pod: Pod)
	if pod.launching or #pod.members == 0 then
		return
	end
	pod.launching = true
	pod.startAt = nil
	local party = table.clone(pod.members)
	publish(pod)
	setDoors(pod, true)
	for _, player in party do
		notify:FireClient(player, "ElevatorRide", {
			pod = pod.model.Name,
			seconds = Config.Party.RideSeconds,
			camFrom = pod.center + Vector3.new(POD_W / 2 - 1.5, 8.5, -POD_D / 2 + 1),
			camTo = pod.center + Vector3.new(-1, 3.5, POD_D / 2),
		})
	end
	task.wait(Config.Party.RideSeconds)
	task.spawn(MatchService.create, party)
	task.wait(1)
	pod.members = {}
	pod.host = nil
	pod.mode = "Public"
	pod.max = Config.Party.DefaultMax
	pod.launching = false
	setDoors(pod, false)
	publish(pod)
end

local function updatePod(pod: Pod)
	if pod.launching then
		return
	end
	-- Drop members who walked out (or left the game).
	for i = #pod.members, 1, -1 do
		local p = pod.members[i]
		if p.Parent ~= Players or not inside(pod, p) then
			table.remove(pod.members, i)
		end
	end
	if pod.host and not table.find(pod.members, pod.host) then
		pod.host = pod.members[1]
		if not pod.host then
			pod.mode = "Public"
			pod.max = Config.Party.DefaultMax
		end
	end
	-- New arrivals.
	for _, player in Players:GetPlayers() do
		if not table.find(pod.members, player) and not MatchService.inMatch(player) and inside(pod, player) then
			if PartyRules.canJoin(pod.mode, #pod.members, pod.max) then
				table.insert(pod.members, player)
				if not pod.host then
					pod.host = player
				end
			else
				pushOut(pod, player)
				notify:FireClient(player, "PodLocked", { mode = pod.mode })
			end
		end
	end
	-- A full public pod starts by itself.
	if pod.mode == "Public" and #pod.members >= pod.max and #pod.members > 0 then
		pod.startAt = pod.startAt or (workspace:GetServerTimeNow() + Config.Party.AutoStartSeconds)
	else
		pod.startAt = nil
	end
	if pod.startAt and workspace:GetServerTimeNow() >= pod.startAt then
		task.spawn(launch, pod)
	end
	publish(pod)
end

local function podOf(player: Player): Pod?
	for _, pod in pods do
		if table.find(pod.members, player) then
			return pod
		end
	end
	return nil
end

function LobbyService.returnToLobby(player: Player)
	local character = player.Character
	if character then
		local offset = Vector3.new((math.random() - 0.5) * 16, 0, (math.random() - 0.5) * 8)
		character:PivotTo(spawnCFrame + offset)
	end
end

function LobbyService.start()
	lobbyFolder = buildAtrium()
	for i = 1, Config.Party.PodCount do
		local x = (i - (Config.Party.PodCount + 1) / 2) * 36
		table.insert(pods, buildPod(lobbyFolder, i, x, -Config.Lobby.Size.Z / 2))
	end
	for _, pod in pods do
		publish(pod)
	end
	MatchService.setLobbyReturn(LobbyService.returnToLobby)

	RemoteGuard.connect(Remotes.get("PartyAction"), function(action: any, value: any)
		if action == "mode" then
			return value == "Solo" or value == "Public"
		elseif action == "max" then
			return Validate.finiteNumber(value) and value >= 1 and value <= Config.Party.MaxPlayers
		end
		return action == "go"
	end, function(player: Player, action: string, value: any)
		local pod = podOf(player)
		if not pod or pod.host ~= player or pod.launching then
			return
		end
		if action == "mode" then
			pod.mode = value
			if value == "Solo" then
				-- Everyone but the host steps out.
				for i = #pod.members, 1, -1 do
					local p = pod.members[i]
					if p ~= player then
						table.remove(pod.members, i)
						pushOut(pod, p)
						notify:FireClient(p, "PodLocked", { mode = "Solo" })
					end
				end
			end
		elseif action == "max" then
			pod.max = PartyRules.clampMax(value, #pod.members, Config.Party.MaxPlayers)
		elseif action == "go" then
			task.spawn(launch, pod)
			return
		end
		publish(pod)
	end)

	task.spawn(function()
		while true do
			for _, pod in pods do
				updatePod(pod)
			end
			task.wait(0.25)
		end
	end)
end

return LobbyService
