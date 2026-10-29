--!strict
-- The Moon Map: a globe you spin with a drag (pinch or scroll to zoom). Regions fill in green as
-- their sectors are swept, orange while work is under way, blue round the stations and plots.
-- Pins mark the 12 stations, your waypoints (tap the globe in pin mode), flags you have found or
-- can see with Flag Finder, the probes, and you. The side panel counts cleaned %, flags /195,
-- probes /26 and waypoints, with buttons to pin, clear and teleport. Opened at a station globe
-- or with M / the Map button. Purely a view; waypoints and teleports go to the server.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local MoonGrid = require(Shared:WaitForChild("MoonGrid"))
local Places = require(Shared:WaitForChild("Places"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Juice = require(script.Parent.Juice)
local Menus = require(script.Parent.Menus)
local MoonView = require(script.Parent.MoonView)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Theme)

local MoonMap = {}

local player = Players.LocalPlayer
local GLOBE = 10 -- globe radius in viewport studs
local sector = MoonView.sector
local region = MoonGrid.new(Config.Grid.RegionFrequency)

local function commas(n: number): string
	local str = tostring(math.floor(n))
	local out = string.reverse((string.gsub(string.reverse(str), "(%d%d%d)", "%1,")))
	if string.sub(out, 1, 1) == "," then
		out = string.sub(out, 2)
	end
	return out
end

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end
local GREEN = rgb(Config.Look.MapGreen)
local BLUE = rgb(Config.Look.MapBlue)
-- the original's hologram (P1 f_182): an orange globe with brighter grid lines
local HOLO = Color3.fromRGB(255, 150, 28)
local HOLO_LINE = Color3.fromRGB(255, 214, 120)

-- sector -> region, and sectors per region (computed once, about 41k cheap lookups)
local regionOf = buffer.create(sector.count * 2)
local kids = buffer.create(region.count * 2)
local mapsReady = false
local function buildMaps()
	sector:forEach(function(id, f, i, j)
		local r = MoonGrid.parentAt(sector, region, f, i, j)
		buffer.writeu16(regionOf, id * 2, r)
		buffer.writeu16(kids, r * 2, buffer.readu16(kids, r * 2) + 1)
	end)
	mapsReady = true
end

local function surfaceCF(dir: Vector3, lift: number): CFrame
	local up = dir.Unit
	local ref = if math.abs(up.Y) < 0.95 then Vector3.yAxis else Vector3.xAxis
	local right = ref:Cross(up).Unit
	local back = right:Cross(up).Unit
	return CFrame.fromMatrix(up * (GLOBE + lift), right, up, back)
end

local function bit(
	model: Instance,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Block
	p.Parent = model
	return p
end

function MoonMap.start()
	local gui = Theme.screen("MoonMap", player:WaitForChild("PlayerGui"), 6)
	-- laid out like P1 f_182: the globe floats in the room (the scene shows through, blurred),
	-- a title card and a stats card on the left, waypoints on the right, key hints below
	local card = Theme.frame(UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), Theme.PANEL, 1)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Name = "Moon Map"
	card.Visible = false
	card.Parent = gui
	local canvas = Theme.canvas(card)

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Globe"
	viewport.Size = UDim2.fromOffset(600, 600)
	viewport.Position = UDim2.fromOffset(340, 40)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(255, 200, 150)
	viewport.LightColor = Color3.fromRGB(255, 240, 220)
	viewport.LightDirection = Vector3.new(-0.4, -0.8, -0.6)
	viewport.Parent = canvas
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	cam.Parent = viewport
	viewport.CurrentCamera = cam
	local world = Instance.new("WorldModel")
	world.Parent = viewport

	local ball = bit(world, Vector3.one * GLOBE * 2, CFrame.new(), HOLO, Enum.Material.Neon, Enum.PartType.Ball)
	ball.Name = "Moon"
	ball.Transparency = 0.08
	-- holographic latitude rings and meridians
	local grid = Instance.new("Folder")
	grid.Name = "Grid"
	grid.Parent = world
	local function ring(cf: CFrame, radius: number)
		local n = 72
		for k = 0, n - 1 do
			local a = k / n * math.pi * 2
			local p = Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
			local seg = bit(
				grid,
				Vector3.new(0.05, 0.05, radius * math.pi * 2 / n + 0.02),
				cf * CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a))),
				HOLO_LINE,
				Enum.Material.Neon
			)
			seg.Transparency = 0.15
		end
	end
	for _, lat in { -60, -30, 0, 30, 60 } do
		local y = math.sin(math.rad(lat)) * (GLOBE + 0.03)
		ring(CFrame.new(0, y, 0), math.cos(math.rad(lat)) * (GLOBE + 0.03))
	end
	for k = 0, 5 do
		ring(CFrame.Angles(0, k * math.pi / 6, math.pi / 2), GLOBE + 0.03)
	end
	local regionLayer = Instance.new("Folder")
	regionLayer.Name = "Regions"
	regionLayer.Parent = world
	local pinLayer = Instance.new("Folder")
	pinLayer.Name = "Pins"
	pinLayer.Parent = world

	-- one disc per region, coloured by progress
	local discs: { [number]: Part } = {}
	local discSize = GLOBE * 2 * math.pi / (region.n * 5.2) * 0.86
	for r = 0, region.count - 1 do
		local d = bit(
			regionLayer,
			Vector3.new(0.06, discSize, discSize),
			surfaceCF(region:position(r), 0.01) * CFrame.Angles(0, 0, math.rad(90)),
			HOLO,
			Enum.Material.Neon,
			Enum.PartType.Cylinder
		)
		d.Transparency = 1
		discs[r] = d
	end

	-- title card
	local titleCard = Theme.panel(canvas, 44, 26, 262, 72)
	local stationName =
		Theme.label("NORTH STATION", 10, Theme.TEAL, Theme.F.bold, UDim2.fromOffset(220, 14), UDim2.fromOffset(18, 18))
	stationName.Parent = titleCard
	local mapTitle =
		Theme.label("MOON MAP", 22, Theme.WHITE, Theme.F.heavy, UDim2.fromOffset(220, 28), UDim2.fromOffset(18, 32))
	mapTitle.Parent = titleCard
	-- stats card
	local stats = Theme.panel(canvas, 44, 114, 262, 318)
	local pct = Theme.label("0.00", 36, Theme.WHITE, Theme.F.heavy, UDim2.fromOffset(170, 44), UDim2.fromOffset(18, 20))
	pct.AutomaticSize = Enum.AutomaticSize.X
	pct.Parent = stats
	local pctSign = Theme.label("%", 16, Theme.MUTED, Theme.F.bold, UDim2.fromOffset(30, 20), UDim2.fromOffset(110, 38))
	pctSign.Parent = stats
	local of = Theme.label(
		"of the Moon cleaned",
		11,
		Theme.WHITE,
		Theme.F.semi,
		UDim2.fromOffset(220, 14),
		UDim2.fromOffset(18, 66)
	)
	of.Parent = stats
	local sectorsLine =
		Theme.label("", 11, Theme.MUTED, Theme.F.semi, UDim2.fromOffset(220, 14), UDim2.fromOffset(18, 81))
	sectorsLine.Parent = stats
	local track = Theme.frame(UDim2.fromOffset(226, 6), UDim2.fromOffset(18, 104), Theme.INNER)
	Theme.corner(track, 3)
	track.Parent = stats
	local fill = Theme.frame(UDim2.fromScale(0, 1), nil, Theme.MINT)
	Theme.corner(fill, 3)
	fill.Parent = track
	local counters: { [string]: TextLabel } = {}
	local legendRows: { { key: string, text: string, color: Color3?, glyph: string? } } = {
		{ key = "NotClean", text = "Not cleaned yet", color = HOLO },
		{ key = "Partly", text = "Partly cleaned", color = BLUE },
		{ key = "Cleaned", text = "Cleaned", color = GREEN },
		{ key = "Stations", text = "Stations", color = Theme.WHITE },
		{ key = "Regions", text = "Regions finished", glyph = "⬡" },
		{ key = "Flags", text = "Flags untangled", glyph = "⚑" },
		{ key = "Probes", text = "Sites surveyed", glyph = "⌖" },
	}
	for i, row in legendRows do
		local r = Theme.frame(UDim2.fromOffset(226, 26), UDim2.fromOffset(18, 120 + (i - 1) * 27), Theme.INNER)
		Theme.corner(r, 3)
		if row.color then
			local dot = Theme.frame(UDim2.fromOffset(9, 9), UDim2.fromOffset(9, 9), row.color)
			Theme.corner(dot, 5)
			dot.Parent = r
		else
			local g = Theme.label(
				row.glyph or "",
				12,
				Theme.WHITE,
				Theme.F.bold,
				UDim2.fromOffset(16, 26),
				UDim2.fromOffset(6, 0)
			)
			g.Parent = r
		end
		local l =
			Theme.label(row.text, 11, Theme.WHITE, Theme.F.bold, UDim2.fromOffset(150, 26), UDim2.fromOffset(26, 0))
		l.Parent = r
		local v = Theme.label("0", 11, Theme.WHITE, Theme.F.bold, UDim2.fromOffset(90, 26), UDim2.fromOffset(128, 0))
		v.TextXAlignment = Enum.TextXAlignment.Right
		v.Parent = r
		counters[row.key] = v
		r.Parent = stats
	end
	-- waypoints card
	local wp = Theme.panel(canvas, 972, 26, 264, 220)
	local wpTitle =
		Theme.label("WAYPOINTS", 15, Theme.WHITE, Theme.F.heavy, UDim2.fromOffset(150, 20), UDim2.fromOffset(18, 22))
	wpTitle.Parent = wp
	local wpCount =
		Theme.label("0 / 4", 15, Theme.WHITE, Theme.F.bold, UDim2.fromOffset(80, 20), UDim2.fromOffset(166, 22))
	wpCount.TextXAlignment = Enum.TextXAlignment.Right
	wpCount.Parent = wp
	local wpList = Theme.list(wp, UDim2.fromOffset(228, 112), UDim2.fromOffset(18, 52), 4)
	local pinButton = Theme.button("+  PIN A WAYPOINT", UDim2.fromOffset(110, 34), "Dark")
	pinButton.Position = UDim2.fromOffset(18, 172)
	pinButton.Parent = wp
	local tpButton = Theme.button("TELEPORT", UDim2.fromOffset(110, 34), "Orange")
	tpButton.Position = UDim2.fromOffset(136, 172)
	tpButton.Parent = wp
	for _, b in { pinButton, tpButton } do
		local lim = b:FindFirstChildOfClass("UITextSizeConstraint")
		if lim then
			lim.MaxTextSize = 11
		end
	end
	local closeButton = Theme.button("×", UDim2.fromOffset(44, 44), "Dark")
	closeButton.Name = "Close"
	closeButton.Position = UDim2.fromOffset(1192, 262)
	closeButton.Parent = canvas
	Theme.hints(canvas, {
		{ "LMB", "Drag to rotate" },
		{ "RMB", "Place waypoint" },
		{ "MMB", "Zoom" },
		{ "F", "Find me" },
		{ "M", "Esc", "Leave" },
	})

	-- camera orbit
	local view = Vector3.yAxis
	local spinUp = Vector3.zAxis
	local distance = 38
	local function placeCamera()
		local pos = view.Unit * distance
		local right = spinUp:Cross(view).Unit
		local up = view:Cross(right).Unit
		cam.CFrame = CFrame.lookAt(pos, Vector3.zero, up)
	end
	local function myDir(): Vector3
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		return if root then Places.dirOf(root.Position) else Vector3.yAxis
	end
	local function lookAt(dir: Vector3)
		view = dir.Unit
		spinUp = if math.abs(view.Y) < 0.98 then Vector3.yAxis else Vector3.zAxis
		spinUp = (spinUp - view * spinUp:Dot(view)).Unit
		placeCamera()
	end

	-- pins
	local function redrawPins()
		pinLayer:ClearAllChildren()
		local s = State.get()
		for _, st in Places.stations do
			local cf = surfaceCF(st.dir, 0)
			-- stations: a white mast with an orange cap, so they read apart from the yellow probes
			bit(pinLayer, Vector3.new(0.16, 1.2, 0.16), cf * CFrame.new(0, 0.6, 0), Theme.WHITE)
			bit(pinLayer, Vector3.new(0.7, 0.4, 0.7), cf * CFrame.new(0, 1.3, 0), Theme.WHITE, Enum.Material.Neon)
		end
		local seeFlags = s.fx and (s.fx.flagPct or 0) > 0
		for i, dir in Places.flags do
			local found = s.flags and s.flags[tostring(i)]
			if found or seeFlags then
				bit(
					pinLayer,
					Vector3.one * 0.22,
					surfaceCF(dir, 0.12),
					if found then GREEN else Theme.WHITE,
					Enum.Material.Neon,
					Enum.PartType.Ball
				)
			end
		end
		for i, dir in Places.probes do
			local found = s.probes and s.probes[tostring(i)]
			bit(
				pinLayer,
				Vector3.new(0.3, 0.3, 0.3),
				surfaceCF(dir, 0.15) * CFrame.Angles(0, math.rad(45), 0),
				if found then GREEN else Theme.YELLOW,
				Enum.Material.Neon
			)
		end
		for _, w in s.waypoints or {} do
			local dir = Vector3.new(w[1], w[2], w[3])
			local cf = surfaceCF(dir, 0)
			bit(pinLayer, Vector3.new(0.12, 0.9, 0.12), cf * CFrame.new(0, 0.45, 0), Theme.RED, Enum.Material.Neon)
			bit(
				pinLayer,
				Vector3.one * 0.36,
				cf * CFrame.new(0, 0.95, 0),
				Theme.RED,
				Enum.Material.Neon,
				Enum.PartType.Ball
			)
		end
		local me = bit(
			pinLayer,
			Vector3.one * 0.55,
			surfaceCF(myDir(), 0.2),
			Theme.WHITE,
			Enum.Material.Neon,
			Enum.PartType.Ball
		)
		me.Name = "Me"
	end

	-- region colours from the client's copy of the Moon
	local function recolour()
		if not mapsReady then
			return
		end
		local doneIn = buffer.create(region.count * 2)
		local doneList = MoonView.doneList()
		local regionsDone = 0
		for sId = 0, sector.count - 1 do
			if buffer.readu8(doneList, sId) == 1 then
				local r = buffer.readu16(regionOf, sId * 2)
				buffer.writeu16(doneIn, r * 2, buffer.readu16(doneIn, r * 2) + 1)
			end
		end
		local busy: { [number]: boolean } = {}
		for sId in MoonView.touchedSet() do
			busy[buffer.readu16(regionOf, sId * 2)] = true
		end
		local yard: { [number]: boolean } = {}
		for _, pad in Places.pads() do
			yard[region:locate(pad.dir)] = true
		end
		for r, d in discs do
			local frac = buffer.readu16(doneIn, r * 2) / math.max(1, buffer.readu16(kids, r * 2))
			if frac >= 1 then
				regionsDone += 1
			end
			if yard[r] and frac < 1 then
				d.Color = Color3.fromRGB(236, 238, 246):Lerp(GREEN, frac)
				d.Transparency = 0
			elseif frac > 0 then
				d.Color = BLUE:Lerp(GREEN, frac)
				d.Transparency = 0
			elseif busy[r] then
				d.Color = BLUE
				d.Transparency = 0
			else
				d.Transparency = 1
			end
		end
		local s = State.get()
		local done, partly = 0, 0
		for sId = 0, sector.count - 1 do
			if buffer.readu8(doneList, sId) == 1 then
				done += 1
			end
		end
		for sId in MoonView.touchedSet() do
			if buffer.readu8(doneList, sId) ~= 1 then
				partly += 1
			end
		end
		local cleanPct = math.max(0, MoonView.cleanPct())
		pct.Text = string.format("%.2f", cleanPct)
		pctSign.Position = UDim2.fromOffset(18 + pct.TextBounds.X + 4, 38)
		fill.Size = UDim2.fromScale(math.clamp(cleanPct / 100, 0.01, 1), 1)
		sectorsLine.Text = string.format("%s of %s sectors", commas(done), commas(sector.count))
		counters.NotClean.Text = commas(sector.count - done - partly)
		counters.Partly.Text = commas(partly)
		counters.Cleaned.Text = commas(done)
		counters.Stations.Text = tostring(#Places.stations)
		counters.Regions.Text = string.format("%d of %d", regionsDone, region.count)
		local nf, np = 0, 0
		for _ in s.flags or {} do
			nf += 1
		end
		for _ in s.probes or {} do
			np += 1
		end
		counters.Flags.Text = string.format("%d of %d", nf, #Places.flags)
		counters.Probes.Text = string.format("%d of %d", np, #Places.probes)
		local limit = math.min(12, 4 + (if s.fx then s.fx.waypoints or 0 else 0))
		wpCount.Text = string.format("%d / %d", #(s.waypoints or {}), limit)
		Theme.clear(wpList)
		local wps = s.waypoints or {}
		if #wps == 0 then
			local none = Theme.frame(UDim2.new(1, 0, 0, 38), nil, Theme.INNER)
			Theme.corner(none, 4)
			local l = Theme.label("No waypoints yet.", 11, Theme.WHITE, Theme.F.semi, UDim2.fromScale(1, 1))
			l.TextXAlignment = Enum.TextXAlignment.Center
			l.Parent = none
			none.Parent = wpList
		end
		for i, w in wps do
			local row = Theme.frame(UDim2.new(1, -4, 0, 26), nil, Theme.INNER)
			row.LayoutOrder = i
			Theme.corner(row, 3)
			local dot = Theme.frame(UDim2.fromOffset(9, 9), UDim2.fromOffset(9, 9), Theme.RED)
			Theme.corner(dot, 5)
			dot.Parent = row
			local dist = Places.arc(myDir(), Vector3.new(w[1], w[2], w[3]))
			local l = Theme.label(
				string.format("Waypoint %d   ·   %s", i, Theme.metres(dist)),
				11,
				Theme.WHITE,
				Theme.F.semi,
				UDim2.new(1, -60, 1, 0),
				UDim2.fromOffset(26, 0)
			)
			l.Parent = row
			local x = Theme.cell(UDim2.fromOffset(26, 26), Theme.INNER)
			x.Position = UDim2.new(1, -26, 0, 0)
			local xl = Theme.label("×", 14, Theme.MUTED, Theme.F.bold, UDim2.fromScale(1, 1))
			xl.TextXAlignment = Enum.TextXAlignment.Center
			xl.Parent = x
			x.Activated:Connect(function()
				Remotes.get("Waypoint"):FireServer("clear", i)
			end)
			x.Parent = row
			row.Parent = wpList
		end
		local st = Places.nearestStation(myDir())
		stationName.Text = string.upper(st.name) .. " STATION"
	end

	local pinMode = false
	local function setPinMode(on: boolean)
		pinMode = on
		pinButton.BackgroundColor3 = if on then Theme.TEAL else Theme.ROW
		pinButton.TextColor3 = if on then Theme.BLACK else Theme.WHITE
		pinButton.Text = if on then "TAP THE GLOBE" else "+  PIN A WAYPOINT"
	end

	-- the ray under a point of the viewport, hit against the globe
	local function globeDirAt(screen: Vector2): Vector3?
		local size = viewport.AbsoluteSize
		local rel = screen - viewport.AbsolutePosition
		local u, v = rel.X / size.X, rel.Y / size.Y
		local t = math.tan(math.rad(cam.FieldOfView) / 2)
		local dir =
			cam.CFrame:VectorToWorldSpace(Vector3.new((2 * u - 1) * t * size.X / size.Y, (1 - 2 * v) * t, -1)).Unit
		local o = cam.CFrame.Position
		local b = o:Dot(dir)
		local c = o:Dot(o) - GLOBE * GLOBE
		local disc = b * b - c
		if disc < 0 then
			return nil
		end
		local hit = o + dir * (-b - math.sqrt(disc))
		return hit.Unit
	end

	local dragging: InputObject? = nil
	local moved = 0
	local last = Vector2.zero
	viewport.InputBegan:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = input
			moved = 0
			last = Vector2.new(input.Position.X, input.Position.Y)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			local dir = globeDirAt(Vector2.new(input.Position.X, input.Position.Y))
			if dir then
				Remotes.get("Waypoint"):FireServer("add", dir)
				Juice.playSound("rbxasset://sounds/electronicpingshort.wav", 0.3)
			end
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			distance = math.clamp(distance - input.Position.Z * 3, 16, 60)
			placeCamera()
		end
	end)
	UserInputService.InputChanged:Connect(function(input: InputObject)
		if not dragging or not card.Visible then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or (input.UserInputType == Enum.UserInputType.Touch and input == dragging)
		then
			local p = Vector2.new(input.Position.X, input.Position.Y)
			local d = p - last
			last = p
			moved += d.Magnitude
			local right = spinUp:Cross(view).Unit
			local k = 0.006 * distance / 38
			local turn = CFrame.fromAxisAngle(spinUp, -d.X * k) * CFrame.fromAxisAngle(right, -d.Y * k)
			view = turn:VectorToWorldSpace(view).Unit
			spinUp = turn:VectorToWorldSpace(spinUp)
			spinUp = (spinUp - view * spinUp:Dot(view)).Unit
			placeCamera()
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if dragging and (input == dragging or input.UserInputType == Enum.UserInputType.MouseButton1) then
			dragging = nil
			if moved < 8 and pinMode and card.Visible then
				local dir = globeDirAt(Vector2.new(input.Position.X, input.Position.Y))
				if dir then
					Remotes.get("Waypoint"):FireServer("add", dir)
					Juice.popIn(pinButton)
					setPinMode(false)
				end
			end
		end
	end)
	UserInputService.TouchPinch:Connect(function(_positions, scale, _velocity, state)
		if card.Visible and state == Enum.UserInputState.Change then
			distance = math.clamp(distance / math.clamp(scale, 0.9, 1.1), 16, 60)
			placeCamera()
		end
	end)

	pinButton.Activated:Connect(function()
		setPinMode(not pinMode)
	end)
	tpButton.Activated:Connect(function()
		Menus.open("teleport")
	end)

	-- gentle spin while idle, unless reduced motion is on
	RunService.RenderStepped:Connect(function(dt: number)
		if card.Visible and not dragging and not pinMode and not GuiService.ReducedMotionEnabled then
			local turn = CFrame.fromAxisAngle(spinUp, dt * 0.05)
			view = turn:VectorToWorldSpace(view).Unit
			placeCamera()
		end
	end)

	local dirtyAt = 0
	MoonView.onChanged(function()
		dirtyAt = os.clock()
	end)
	State.changed(function()
		if card.Visible then
			redrawPins()
			recolour()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			if card.Visible and dirtyAt > 0 then
				dirtyAt = 0
				recolour()
			end
		end
	end)

	Menus.register("map", card, function()
		lookAt(myDir())
		setPinMode(false)
		local s = State.get()
		tpButton.Visible = (s.fx and (s.fx.teleportAnywhere or 0) > 0) == true
		redrawPins()
		recolour()
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.F and card.Visible then
			lookAt(myDir())
		elseif not processed and input.KeyCode == Enum.KeyCode.M then
			if card.Visible then
				Menus.close()
			else
				Menus.open("map")
			end
		end
	end)

	task.spawn(buildMaps)
end

return MoonMap
