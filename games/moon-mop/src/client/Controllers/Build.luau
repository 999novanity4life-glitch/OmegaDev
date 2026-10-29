--!strict
-- The Build Tool (B). V opens the BUILD catalogue (six tabs of 3D renders with cream price
-- tags, P1 f_181); the chosen building follows the centre of your view as a see-through blue
-- ghost over your plot, red where it doesn't fit (Shared/Plot decides, the same rules the
-- server uses). R rotates, click places. Belts take two clicks: start and end of a straight run.
-- Remove mode (X) picks a building to sell back (full refund for a minute after placing).
-- Touch: tap to aim, then PLACE.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Places = require(Shared:WaitForChild("Places"))
local Plot = require(Shared:WaitForChild("Plot"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local buildModel = require(Shared:WaitForChild("World"):WaitForChild("Buildings"))

local Hud = require(script.Parent.Hud)
local Menus = require(script.Parent.Menus)
local Juice = require(script.Parent.Juice)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Theme)

local Build = {}

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local intent = Remotes.get("BuildIntent")
local CENTRE = Config.Moon.Centre
local R = Config.Moon.Radius

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { Workspace.Terrain }

local active = false
local removing = false
local chosen: string? = nil
local rot = 0
local beltStart: Vector2? = nil
local aim: Vector2? = nil -- plot coordinates under the pointer
local ghost: Model? = nil
local hovered: Model? = nil

-- The same plot frame the server builds from.
local function plotFrame(index: number): CFrame?
	local info = Places.plots[index]
	if not info then
		return nil
	end
	local hit = Workspace:Raycast(CENTRE + info.dir * (R + 400), -info.dir * 700, terrainOnly)
	local ground = if hit then hit.Position else CENTRE + info.dir * R
	return Places.frameAt(ground)
end

local frameCache: { [number]: CFrame } = {}
local function myFrame(): CFrame?
	local idx = State.get().plot or 0
	if idx == 0 then
		return nil
	end
	local cached = frameCache[idx]
	if cached then
		return cached
	end
	local cf = plotFrame(idx)
	if cf then
		frameCache[idx] = cf
	end
	return cf
end

local function worldFrame(frame: CFrame, x: number, z: number, r: number): CFrame
	local flat = frame:PointToWorldSpace(Vector3.new(x, 0, z))
	local dir = (flat - CENTRE).Unit
	local hit = Workspace:Raycast(CENTRE + dir * (R + 400), -dir * 700, terrainOnly)
	local ground = if hit then hit.Position else CENTRE + dir * R
	local right = frame.LookVector:Cross(dir).Unit
	return CFrame.fromMatrix(ground, right, dir) * CFrame.Angles(0, -r * math.pi / 2, 0)
end

local function makeGhost(id: string): Model
	local def = Plot.def(id) :: Config.BuildDef
	-- a see-through blue copy of the real building (P1 f_149, f_251)
	local ok, built = pcall(buildModel, id)
	local m: Model
	if ok then
		m = built
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
				d.CastShadow = false
				d.Material = Enum.Material.SmoothPlastic
				d.Transparency = math.max(d.Transparency, 0.55)
			elseif d:IsA("Light") or d:IsA("SurfaceGui") or d:IsA("BillboardGui") or d:IsA("ParticleEmitter") then
				d:Destroy()
			end
		end
	else
		m = Instance.new("Model")
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Size = def.size
		p.CFrame = CFrame.new(0, def.size.Y / 2, 0)
		p.Transparency = 0.55
		p.Parent = m
	end
	m.Name = "BuildGhost"
	local arrow = Instance.new("Part")
	arrow.Name = "Arrow"
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.CanQuery = false
	arrow.Size = Vector3.new(1.2, 0.3, 2.4)
	arrow.CFrame = CFrame.new(0, 0.3, -def.size.Z / 2 - 1.6)
	arrow.Material = Enum.Material.Neon
	arrow.Color = Theme.YELLOW
	arrow.Parent = m
	m.WorldPivot = CFrame.identity
	m.Parent = Workspace
	return m
end

local function setGhostColour(ok: boolean)
	if ghost then
		for _, p in ghost:GetDescendants() do
			if p:IsA("BasePart") and p.Name ~= "Arrow" then
				p.Color = if ok then Color3.fromRGB(80, 190, 255) else Theme.RED
			end
		end
	end
end

local function pointer(): Vector2
	return UserInputService:GetMouseLocation()
end

-- Plot coordinates under a screen point, or nil off the plot.
local function plotPointAt(screen: Vector2): Vector2?
	local frame = myFrame()
	if not frame then
		return nil
	end
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 600, terrainOnly)
	if not hit then
		return nil
	end
	local rel = frame:PointToObjectSpace(hit.Position)
	return Vector2.new(Plot.snap(rel.X), Plot.snap(rel.Z))
end

---------------------------------------------------------------------------- UI
-- Build mode HUD (P1 f_149): a round orange-ringed icon, the item name, a yellow PLACE tag with
-- the price (red NOT ENOUGH MONEY), grey specs, and key hints along the bottom. V opens the
-- BUILD catalogue (P1 f_181), a station menu with tabs, 3D renders and cream price tags.
local gui: ScreenGui
local hud: Frame
local hudIcon: Frame
local hudName: TextLabel
local hudTag: TextLabel
local status: TextLabel
local hudHints: Frame
local placeButton: TextButton
local menu: Theme.StationMenu
local currentTab = Config.BuildTabs[1]
local menuPick = Config.Buildings[1].id

local function priceOf(id: string): number
	local s = State.get()
	return Plot.price(s.buildings or {}, id, s.fx)
end

local iconModels: { [string]: Model } = {}
local function iconModel(id: string): Model?
	if not iconModels[id] then
		local ok, m = pcall(buildModel, id)
		if ok then
			iconModels[id] = m
		end
	end
	return iconModels[id]
end

local function priceText(id: string): string
	local p = priceOf(id)
	return if id == "Belt" then Theme.money(p) .. " / tile" else Theme.money(p)
end

local refreshItems: () -> ()

local function select(id: string?)
	chosen = id
	removing = false
	beltStart = nil
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	if id then
		ghost = makeGhost(id)
	end
	refreshItems()
end

local function sizeText(def: Config.BuildDef): string
	return string.format("%s x %s", Theme.metres(def.size.X), Theme.metres(def.size.Z))
end

-- the HUD while building
local function refreshHud()
	if not hud then
		return
	end
	local s = State.get()
	local money = s.money or 0
	Theme.clear(hudIcon)
	if removing then
		hudName.Text = "REMOVE MODE"
		hudTag.Text = if hovered
			then string.format("LMB  REMOVE %s", string.upper(tostring(hovered.Name)))
			else "POINT AT A BUILDING"
		hudTag.BackgroundColor3 = Theme.RED
		hudTag.TextColor3 = Theme.WHITE
	elseif chosen then
		local def = Plot.def(chosen) :: Config.BuildDef
		local mdl = iconModel(chosen)
		if mdl then
			Theme.icon3d(mdl, UDim2.fromScale(1, 1), nil, 35, 25).Parent = hudIcon
		end
		hudName.Text = string.upper(def.name)
		local price = priceOf(chosen)
		local afford = money >= price
		hudTag.Text = if afford then "PLACE  " .. priceText(chosen) else "NOT ENOUGH MONEY"
		hudTag.BackgroundColor3 = if afford then Theme.YELLOW else Theme.RED
		hudTag.TextColor3 = if afford then Theme.BLACK else Theme.WHITE
	else
		hudName.Text = "BUILD TOOL"
		hudTag.Text = "PRESS V TO CHOOSE"
		hudTag.BackgroundColor3 = Theme.YELLOW
		hudTag.TextColor3 = Theme.BLACK
	end
	Theme.setHints(hudHints, {
		{ "LMB", if removing then "Remove" elseif chosen == "Belt" and beltStart then "Place end" else "Place" },
		{ "R", "Rotate" },
		{ "V", "Build menu" },
		{ "X", "Remove mode" },
		{ "B", "Put away" },
	})
end

-- the BUILD catalogue
local function refreshMenu()
	if not menu then
		return
	end
	local s = State.get()
	local money = s.money or 0
	menu.money.Text = Theme.cash(money)
	Theme.setTabs(menu.tabs, Config.BuildTabs, currentTab, function(name: string)
		currentTab = name
		for _, def in Config.Buildings do
			if def.tab == name then
				menuPick = def.id
				break
			end
		end
		refreshMenu()
	end)
	local grid = menu.body:FindFirstChild("Grid") :: ScrollingFrame
	Theme.clear(grid)
	local order = 0
	for _, def in Config.Buildings do
		if def.tab ~= currentTab then
			continue
		end
		order += 1
		local sel = def.id == menuPick
		local price = priceOf(def.id)
		local cell = Theme.cell(UDim2.fromOffset(176, 196), Theme.INNER)
		cell.BackgroundTransparency = 1
		cell.LayoutOrder = order
		local mdl = iconModel(def.id)
		if mdl then
			Theme.icon3d(mdl, UDim2.fromOffset(176, 150), UDim2.fromOffset(0, 16), 35, 25).Parent = cell
		end
		local chip =
			Theme.frame(UDim2.fromOffset(172, 24), UDim2.fromOffset(2, 168), if sel then Theme.ORANGE else Theme.ROW)
		Theme.corner(chip, 3)
		local n = Theme.label(def.name, 11, Theme.WHITE, Theme.F.bold, UDim2.fromScale(1, 1))
		n.TextXAlignment = Enum.TextXAlignment.Center
		n.Parent = chip
		chip.Parent = cell
		if Plot.atLimit(s.buildings or {}, def.id) then
			local t =
				Theme.label("BUILT", 9, Theme.TEAL, Theme.F.bold, UDim2.fromOffset(60, 18), UDim2.new(1, -66, 0, 8))
			t.BackgroundColor3 = Theme.ROW
			t.BackgroundTransparency = 0
			t.TextXAlignment = Enum.TextXAlignment.Center
			Theme.corner(t, 3)
			t.Parent = cell
		else
			local tag = Theme.luggage(priceText(def.id), "Cream", 6)
			tag.AnchorPoint = Vector2.new(1, 0)
			tag.Position = UDim2.new(1, -4, 0, 6)
			if money < price then
				local l = tag:FindFirstChildOfClass("TextLabel")
				if l then
					l.TextColor3 = Theme.RED
				end
			end
			tag.Parent = cell
		end
		cell.Activated:Connect(function()
			if menuPick == def.id then
				-- second click builds it
				select(def.id)
				Menus.close()
				return
			end
			menuPick = def.id
			refreshMenu()
		end)
		cell.Parent = grid
	end
	-- detail card
	Theme.clear(menu.detail)
	local def = Plot.def(menuPick) :: Config.BuildDef
	local cat =
		Theme.label(string.upper(def.tab), 10, Theme.TEAL, Theme.F.bold, UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, 2))
	cat.Parent = menu.detail
	local nm = Theme.label(def.name, 22, Theme.WHITE, Theme.F.heavy, UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 16))
	nm.Parent = menu.detail
	local box = Theme.inset(menu.detail, UDim2.new(1, 0, 0, 160), UDim2.fromOffset(0, 56))
	local mdl = iconModel(def.id)
	if mdl then
		Theme.icon3d(mdl, UDim2.fromScale(1, 1), nil, 35, 25).Parent = box
	end
	local tag = Theme.luggage(priceText(def.id), "Cream", 6)
	tag.AnchorPoint = Vector2.new(1, 0)
	tag.Position = UDim2.new(1, -8, 0, 10)
	tag.Parent = box
	local d = Theme.label(
		def.text,
		13,
		Color3.fromRGB(214, 218, 224),
		Theme.F.regular,
		UDim2.new(1, 0, 0, 40),
		UDim2.fromOffset(0, 226)
	)
	d.TextWrapped = true
	d.TextYAlignment = Enum.TextYAlignment.Top
	d.Parent = menu.detail
	local price = priceOf(def.id)
	Theme.statRow(menu.detail, 300, "Footprint", if def.id == "Belt" then "Any straight run" else sizeText(def))
	Theme.statRow(menu.detail, 336, "Height", Theme.metres(def.size.Y))
	Theme.statRow(
		menu.detail,
		372,
		"Power",
		if def.power == nil
			then "None"
			elseif def.power < 0 then string.format("Makes %g kW", -def.power)
			else string.format("Uses %g kW", def.power)
	)
	Theme.statRow(menu.detail, 408, "Price", priceText(def.id), if money >= price then nil else Theme.RED)
	if money < price then
		local n = Theme.label(
			string.format("You need %s more to build this. You can still preview it.", Theme.money(price - money)),
			11,
			Theme.RED,
			Theme.F.semi,
			UDim2.new(1, 0, 0, 30),
			UDim2.fromOffset(0, 446)
		)
		n.TextWrapped = true
		n.Parent = menu.detail
	end
end

function refreshItems()
	refreshHud()
	if menu and menu.root.Visible then
		refreshMenu()
	end
end

local function setActive(on: boolean)
	local s = State.get()
	if on and not s.buildTool then
		State.emit("Toast", { text = "Buy the Build Tool at a station supply wall", color = Theme.ORANGE })
		return
	end
	if on and (s.plot or 0) == 0 then
		State.emit(
			"Toast",
			{ text = "Claim a Mop Base plot at one of the signs round the North Station", color = Theme.ORANGE }
		)
		return
	end
	active = on
	hud.Visible = on
	Hud.setBuildMode(on)
	if on then
		Juice.popIn(hud)
		refreshItems()
		if not chosen then
			Menus.open("build")
		end
	else
		select(nil)
		removing = false
		if hovered then
			local h = hovered:FindFirstChild("RemoveHighlight")
			if h then
				h:Destroy()
			end
			hovered = nil
		end
	end
end

local function confirm(at: Vector2?)
	if not at then
		return
	end
	if removing then
		if hovered then
			intent:FireServer("remove", hovered:GetAttribute("Uid"))
			Juice.shakeCamera(0.05)
		end
		return
	end
	local id = chosen
	if not id then
		return
	end
	if id == "Belt" then
		if not beltStart then
			beltStart = at
			status.Text = "Click where the belt run ends"
			return
		end
		intent:FireServer("belt", beltStart.X, beltStart.Y, at.X, at.Y)
		beltStart = nil
		return
	end
	local ok, why = Plot.canPlace(State.get().buildings or {}, id, at.X, at.Y, rot)
	if not ok then
		State.emit("Toast", { text = why or "Can't build there", color = Theme.RED })
		return
	end
	intent:FireServer("place", id, at.X, at.Y, rot)
end

local function updateHover()
	if not removing then
		return
	end
	local ray = camera:ViewportPointToRay(pointer().X, pointer().Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { Workspace:FindFirstChild("Plots") or Workspace.Terrain }
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 600, params)
	local model: Model? = nil
	if hit then
		local m = hit.Instance:FindFirstAncestorWhichIsA("Model")
		while m and m:GetAttribute("Uid") == nil do
			m = m.Parent and m.Parent:FindFirstAncestorWhichIsA("Model")
		end
		if m and m:GetAttribute("Owner") == player.UserId then
			model = m
		end
	end
	if model ~= hovered then
		if hovered then
			local h = hovered:FindFirstChild("RemoveHighlight")
			if h then
				h:Destroy()
			end
		end
		hovered = model
		refreshHud()
		if model then
			local h = Instance.new("Highlight")
			h.Name = "RemoveHighlight"
			h.FillColor = Theme.RED
			h.FillTransparency = 0.5
			h.OutlineColor = Theme.RED
			h.Parent = model
		end
	end
	status.Text = if model then "Click to remove (refund shown on the toast)" else "Point at one of your buildings"
end

function Build.start()
	gui = Theme.screen("BuildTool", player:WaitForChild("PlayerGui"), 4)
	hud = Theme.frame(UDim2.fromScale(1, 1), nil, Theme.PANEL, 1)
	hud.Visible = false
	hud.Parent = gui
	local canvas = Theme.canvas(hud)
	local disc = Theme.frame(UDim2.fromOffset(64, 64), UDim2.fromOffset(40, 600), Color3.fromRGB(34, 38, 44))
	Theme.corner(disc, 32)
	Theme.stroke(disc, Theme.ORANGE, 3)
	disc.Parent = canvas
	hudIcon = Theme.frame(UDim2.fromOffset(52, 52), UDim2.fromOffset(6, 6), Theme.PANEL, 1)
	hudIcon.Parent = disc
	hudName = Theme.label("", 26, Theme.WHITE, Theme.F.heavy, UDim2.fromOffset(700, 32), UDim2.fromOffset(116, 596))
	Theme.shadow(hudName)
	hudName.Parent = canvas
	hudTag = Theme.label("", 11, Theme.BLACK, Theme.F.bold, UDim2.fromOffset(0, 20), UDim2.fromOffset(116, 632))
	hudTag.AutomaticSize = Enum.AutomaticSize.X
	hudTag.BackgroundTransparency = 0
	hudTag.BackgroundColor3 = Theme.YELLOW
	Theme.corner(hudTag, 3)
	local tp = Instance.new("UIPadding")
	tp.PaddingLeft = UDim.new(0, 8)
	tp.PaddingRight = UDim.new(0, 8)
	tp.Parent = hudTag
	hudTag.Parent = canvas
	status = Theme.label("", 11, Theme.MUTED, Theme.F.semi, UDim2.fromOffset(600, 16), UDim2.fromOffset(116, 656))
	Theme.shadow(status)
	status.Parent = canvas
	hudHints = Theme.hints(canvas, {}, 700)
	placeButton = Theme.button("PLACE", UDim2.fromOffset(110, 48), "Orange")
	placeButton.Position = UDim2.fromOffset(1130, 560)
	placeButton.Visible = Hud.touch
	placeButton.Activated:Connect(function()
		confirm(aim)
	end)
	placeButton.Parent = canvas
	if Hud.touch then
		local rotate = Theme.button("ROTATE", UDim2.fromOffset(110, 44), "Dark")
		rotate.Position = UDim2.fromOffset(1130, 510)
		rotate.Activated:Connect(function()
			rot = (rot + 1) % 4
		end)
		rotate.Parent = canvas
		local catalogue = Theme.button("BUILD MENU", UDim2.fromOffset(110, 44), "Dark")
		catalogue.Position = UDim2.fromOffset(1130, 460)
		catalogue.Activated:Connect(function()
			Menus.open("build")
		end)
		catalogue.Parent = canvas
		local remove = Theme.button("REMOVE", UDim2.fromOffset(110, 44), "Red")
		remove.Position = UDim2.fromOffset(1130, 410)
		remove.Activated:Connect(function()
			select(nil)
			removing = true
			refreshHud()
		end)
		remove.Parent = canvas
	end

	-- the BUILD catalogue
	local menuGui = Theme.screen("BuildMenu", player:WaitForChild("PlayerGui"), 6)
	menu = Theme.stationMenu(menuGui, "Build")
	local grid = Instance.new("ScrollingFrame")
	grid.Name = "Grid"
	grid.Size = UDim2.new(1, -16, 1, -16)
	grid.Position = UDim2.fromOffset(8, 8)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.ScrollBarThickness = 4
	grid.ScrollBarImageColor3 = Theme.ORANGE
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.CanvasSize = UDim2.new()
	local gl = Instance.new("UIGridLayout")
	gl.CellSize = UDim2.fromOffset(176, 196)
	gl.CellPadding = UDim2.fromOffset(6, 10)
	gl.SortOrder = Enum.SortOrder.LayoutOrder
	gl.Parent = grid
	grid.Parent = menu.body
	Theme.setHints(
		menu.hints,
		{ { "LMB", "Choose, again to build" }, { "MMB", "Scroll" }, { "Enter", "Build" }, { "E", "Close" } }
	)
	Menus.register("build", menu.root, refreshMenu, function()
		select(menuPick)
		Menus.close()
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if input.KeyCode == Enum.KeyCode.B and not processed and not Menus.isOpen("build") then
			setActive(not active)
			return
		end
		if not active or processed or Menus.isOpen("build") then
			return
		end
		if input.KeyCode == Enum.KeyCode.R then
			rot = (rot + 1) % 4
		elseif input.KeyCode == Enum.KeyCode.V then
			Menus.open("build")
		elseif input.KeyCode == Enum.KeyCode.X then
			select(nil)
			removing = true
			refreshHud()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			confirm(plotPointAt(pointer()))
		elseif input.UserInputType == Enum.UserInputType.Touch then
			aim = plotPointAt(Vector2.new(input.Position.X, input.Position.Y))
			if removing then
				confirm(aim)
			end
		end
	end)

	RunService.RenderStepped:Connect(function()
		hud.Visible = active and not Hud.isMenuOpen()
		if not active then
			return
		end
		updateHover()
		local id = chosen
		if not id or not ghost then
			if not removing then
				status.Text = "Pick something to build"
			end
			return
		end
		if not Hud.touch then
			aim = plotPointAt(pointer())
		end
		local frame = myFrame()
		local at = aim
		if not frame or not at then
			ghost.Parent = nil
			status.Text = "Point at your plot"
			return
		end
		ghost.Parent = Workspace
		local r = if id == "Belt" and beltStart then Plot.beltRun(beltStart.X, beltStart.Y, at.X, at.Y)[1].r else rot
		ghost:PivotTo(worldFrame(frame, at.X, at.Y, r))
		local ok, why = Plot.canPlace(State.get().buildings or {}, id, at.X, at.Y, r)
		setGhostColour(ok)
		if id == "Belt" and beltStart then
			local run = Plot.beltRun(beltStart.X, beltStart.Y, at.X, at.Y)
			status.Text = string.format("%d tiles, %s", #run, Theme.money(priceOf("Belt") * #run))
		else
			status.Text = if ok
				then string.format("%s  ·  %s", (Plot.def(id) :: Config.BuildDef).name, Theme.money(priceOf(id)))
				else (why or "")
		end
	end)

	State.changed(function()
		if active or menu.root.Visible then
			refreshItems()
		end
	end)
	State.onFeedback(function(kind: string, data: any)
		if kind == "Built" then
			Juice.shakeCamera(0.06)
			State.emit("Toast", {
				text = if data.count then string.format("Laid %d belt tiles", data.count) else "Built!",
				color = Theme.GREEN,
			})
		elseif kind == "Plot" then
			frameCache = {}
			State.emit(
				"Toast",
				{ text = string.format("Plot %d is yours. Press B to build", data.index), color = Theme.TEAL }
			)
		end
	end)
end

return Build
