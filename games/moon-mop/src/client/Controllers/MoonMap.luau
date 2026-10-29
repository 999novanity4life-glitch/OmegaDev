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

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end
local GREEN = rgb(Config.Look.MapGreen)
local ORANGE = rgb(Config.Look.MapOrange)
local BLUE = rgb(Config.Look.MapBlue)
local DUSTY = Color3.fromRGB(150, 152, 160)

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
	local card, body = Theme.card(gui, "Moon Map", "Moon Mop Co. survey", UDim2.fromScale(0.94, 0.9))

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Globe"
	viewport.Size = UDim2.fromScale(0.64, 1)
	viewport.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
	viewport.BorderSizePixel = 0
	viewport.Ambient = Color3.fromRGB(150, 155, 170)
	viewport.LightColor = Color3.fromRGB(255, 250, 240)
	viewport.LightDirection = Vector3.new(-1, -0.6, -0.8)
	Theme.corner(viewport, 8)
	viewport.Parent = body
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	cam.Parent = viewport
	viewport.CurrentCamera = cam
	local world = Instance.new("WorldModel")
	world.Parent = viewport

	local ball = bit(world, Vector3.one * GLOBE * 2, CFrame.new(), DUSTY, Enum.Material.Slate, Enum.PartType.Ball)
	ball.Name = "Moon"
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
			DUSTY,
			Enum.Material.SmoothPlastic,
			Enum.PartType.Cylinder
		)
		d.Transparency = 1
		discs[r] = d
	end

	-- legend + counters panel
	local panel = Theme.frame(UDim2.new(0.34, -12, 1, 0), UDim2.new(0.66, 12, 0, 0), Theme.SLATE, 1)
	panel.Parent = body
	local pct = Theme.text("0.00%", UDim2.new(1, 0, 0, 54), Theme.WHITE, Enum.Font.GothamBlack, 52)
	pct.Parent = panel
	local pctLabel = Theme.text("OF THE MOON CLEANED", UDim2.new(1, 0, 0, 18), Theme.TEAL, Enum.Font.GothamBold, 16)
	pctLabel.Position = UDim2.fromOffset(0, 56)
	pctLabel.Parent = panel
	local rows = Theme.frame(UDim2.new(1, 0, 0, 150), UDim2.fromOffset(0, 84), Theme.SLATE, 1)
	rows.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = rows
	local counters: { [string]: TextLabel } = {}
	for i, key in { "Regions", "Flags", "Probes", "Waypoints" } do
		local row = Theme.frame(UDim2.new(1, 0, 0, 32), nil, Theme.SLATE_HI)
		row.LayoutOrder = i
		Theme.corner(row, 6)
		local l = Theme.text(string.upper(key), UDim2.new(0.55, 0, 1, 0), Theme.MUTED, Enum.Font.GothamBold, 16)
		l.Position = UDim2.fromOffset(10, 0)
		l.Parent = row
		local v = Theme.text("0", UDim2.new(0.4, 0, 1, 0), Theme.WHITE, Enum.Font.GothamBlack, 18)
		v.Position = UDim2.new(0.58, 0, 0, 0)
		v.TextXAlignment = Enum.TextXAlignment.Right
		v.Parent = row
		counters[key] = v
		row.Parent = rows
	end
	local legend = Theme.frame(UDim2.new(1, 0, 0, 60), UDim2.fromOffset(0, 240), Theme.SLATE, 1)
	legend.Parent = panel
	local legendItems: { { color: Color3, text: string } } = {
		{ color = GREEN, text = "Swept clean" },
		{ color = ORANGE, text = "Being swept" },
		{ color = BLUE, text = "Station yards" },
	}
	for i, item in legendItems do
		local sw = Theme.frame(UDim2.fromOffset(14, 14), UDim2.fromOffset(0, (i - 1) * 20 + 2), item.color)
		Theme.corner(sw, 7)
		sw.Parent = legend
		local t = Theme.text(item.text, UDim2.new(1, -22, 0, 18), Theme.MUTED, Enum.Font.GothamBold, 14)
		t.Position = UDim2.fromOffset(22, (i - 1) * 20)
		t.Parent = legend
	end
	local pinButton = Theme.button("PIN WAYPOINT", UDim2.new(1, 0, 0, 44), "Dark")
	pinButton.Position = UDim2.new(0, 0, 1, -150)
	pinButton.Parent = panel
	local clearButton = Theme.button("CLEAR PINS", UDim2.new(0.48, 0, 0, 44), "Dark")
	clearButton.Position = UDim2.new(0, 0, 1, -100)
	clearButton.Parent = panel
	local homeButton = Theme.button("ME", UDim2.new(0.48, 0, 0, 44), "Dark")
	homeButton.Position = UDim2.new(0.52, 0, 1, -100)
	homeButton.Parent = panel
	local tpButton = Theme.button("TELEPORT", UDim2.new(1, 0, 0, 44), "Orange")
	tpButton.Position = UDim2.new(0, 0, 1, -50)
	tpButton.Parent = panel
	local hint = Theme.text(
		"Drag to spin, scroll or pinch to zoom",
		UDim2.new(0.64, 0, 0, 16),
		Theme.MUTED,
		Enum.Font.Gotham,
		13
	)
	hint.AnchorPoint = Vector2.new(0, 1)
	hint.Position = UDim2.new(0, 10, 1, -8)
	hint.Parent = body

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
			bit(pinLayer, Vector3.new(0.7, 0.4, 0.7), cf * CFrame.new(0, 1.3, 0), Theme.ORANGE)
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
			bit(pinLayer, Vector3.new(0.12, 0.9, 0.12), cf * CFrame.new(0, 0.45, 0), Theme.TEAL, Enum.Material.Neon)
			bit(
				pinLayer,
				Vector3.one * 0.36,
				cf * CFrame.new(0, 0.95, 0),
				Theme.TEAL,
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
				d.Color = BLUE:Lerp(GREEN, frac)
				d.Transparency = 0
			elseif frac > 0 then
				d.Color = (if busy[r] and frac < 1 then ORANGE else DUSTY):Lerp(GREEN, math.max(frac, 0.25))
				d.Transparency = 0
			elseif busy[r] then
				d.Color = ORANGE
				d.Transparency = 0
			else
				d.Transparency = 1
			end
		end
		local s = State.get()
		pct.Text = string.format("%.2f%%", math.max(0, MoonView.cleanPct()))
		counters.Regions.Text = string.format("%d / %d", regionsDone, region.count)
		local nf, np = 0, 0
		for _ in s.flags or {} do
			nf += 1
		end
		for _ in s.probes or {} do
			np += 1
		end
		counters.Flags.Text = string.format("%d / %d", nf, #Places.flags)
		counters.Probes.Text = string.format("%d / %d", np, #Places.probes)
		local limit = math.min(12, 4 + (if s.fx then s.fx.waypoints or 0 else 0))
		counters.Waypoints.Text = string.format("%d / %d", #(s.waypoints or {}), limit)
	end

	local pinMode = false
	local function setPinMode(on: boolean)
		pinMode = on
		pinButton.BackgroundColor3 = if on then Theme.TEAL else Theme.SLATE_HI
		pinButton.TextColor3 = if on then Theme.BLACK else Theme.WHITE
		pinButton.Text = if on then "TAP THE GLOBE" else "PIN WAYPOINT"
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
	clearButton.Activated:Connect(function()
		local n = #(State.get().waypoints or {})
		for _ = 1, n do
			Remotes.get("Waypoint"):FireServer("clear", 1)
		end
	end)
	homeButton.Activated:Connect(function()
		lookAt(myDir())
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
		if not processed and input.KeyCode == Enum.KeyCode.M then
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
