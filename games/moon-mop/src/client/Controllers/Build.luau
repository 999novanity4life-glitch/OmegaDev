--!strict
-- The Build Tool (B): a catalog of the Mop Base buildings in six tabs, and a ghost of the chosen
-- building that follows the pointer over your plot, blue where it fits and red where it doesn't
-- (Shared/Plot decides, the same rules the server uses). R rotates, click places. Belts take two
-- clicks: start and end of a straight run. Remove mode (X) picks a building to sell back
-- (full refund for a minute after placing). Touch: tap to aim, then PLACE.

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

local Hud = require(script.Parent.Hud)
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
	local m = Instance.new("Model")
	m.Name = "BuildGhost"
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Size = def.size
	p.CFrame = CFrame.new(0, def.size.Y / 2, 0)
	p.Material = Enum.Material.ForceField
	p.Color = Theme.TEAL
	p.Parent = m
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
		for _, p in ghost:GetChildren() do
			if p:IsA("BasePart") and p.Name ~= "Arrow" then
				p.Color = if ok then Color3.fromRGB(80, 170, 255) else Theme.RED
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
local gui: ScreenGui
local panel: Frame
local itemsFrame: ScrollingFrame
local tabRow: Frame
local status: TextLabel
local placeButton: TextButton
local currentTab = Config.BuildTabs[1]

local function priceOf(id: string): number
	local s = State.get()
	return Plot.price(s.buildings or {}, id, s.fx)
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

function refreshItems()
	for _, c in itemsFrame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local s = State.get()
	local money = s.money or 0
	local order = 0
	for _, def in Config.Buildings do
		if def.tab ~= currentTab then
			continue
		end
		order += 1
		local price = priceOf(def.id)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(150, 96)
		b.LayoutOrder = order
		b.AutoButtonColor = false
		b.Text = ""
		b.BackgroundColor3 = if chosen == def.id then Theme.ORANGE else Theme.SLATE_HI
		Theme.corner(b, 8)
		local n = Theme.text(
			def.name,
			UDim2.new(1, -12, 0, 22),
			if chosen == def.id then Theme.BLACK else Theme.WHITE,
			Enum.Font.GothamBlack,
			17
		)
		n.Position = UDim2.fromOffset(8, 6)
		n.Parent = b
		local t = Theme.text(
			def.text,
			UDim2.new(1, -12, 0, 34),
			if chosen == def.id then Theme.SLATE else Theme.MUTED,
			Enum.Font.GothamBold,
			11
		)
		t.TextYAlignment = Enum.TextYAlignment.Top
		t.TextWrapped = true
		t.Position = UDim2.fromOffset(8, 30)
		t.Parent = b
		local tag = if Plot.atLimit(s.buildings or {}, def.id)
			then Theme.tag("BUILT", "Owned")
			else Theme.tag(
				if def.id == "Belt" then Theme.money(price) .. "/tile" else Theme.money(price),
				if money >= price then "Good" else "Bad"
			)
		tag.Position = UDim2.new(0, 8, 1, -30)
		tag.Parent = b
		b.Activated:Connect(function()
			select(if chosen == def.id then nil else def.id)
		end)
		b.Parent = itemsFrame
	end
	for _, c in tabRow:GetChildren() do
		if c:IsA("TextButton") then
			c.BackgroundColor3 = if c.Name == currentTab then Theme.TEAL else Theme.SLATE_HI
			c.TextColor3 = if c.Name == currentTab then Theme.BLACK else Theme.WHITE
		end
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
	panel.Visible = on
	Hud.setBuildMode(on)
	if on then
		Juice.popIn(panel)
		refreshItems()
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
	panel = Theme.frame(UDim2.new(0.86, 0, 0, 200), UDim2.new(0.5, 0, 1, -12), Theme.SLATE, 0.05)
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Visible = false
	Theme.corner(panel, 10)
	Theme.stripe(panel, 8)
	panel.Parent = gui
	local size = Instance.new("UISizeConstraint")
	size.MaxSize = Vector2.new(1000, 200)
	size.Parent = panel
	tabRow = Theme.frame(UDim2.new(1, -24, 0, 34), UDim2.fromOffset(12, 14), Theme.SLATE, 1)
	local tl = Instance.new("UIListLayout")
	tl.FillDirection = Enum.FillDirection.Horizontal
	tl.Padding = UDim.new(0, 6)
	tl.Parent = tabRow
	tabRow.Parent = panel
	for _, tab in Config.BuildTabs do
		local b = Theme.button(string.upper(tab), UDim2.fromOffset(112, 32), "Dark")
		b.Name = tab
		b.Activated:Connect(function()
			currentTab = tab
			refreshItems()
		end)
		b.Parent = tabRow
	end
	itemsFrame = Instance.new("ScrollingFrame")
	itemsFrame.Size = UDim2.new(1, -24, 0, 106)
	itemsFrame.Position = UDim2.fromOffset(12, 54)
	itemsFrame.BackgroundTransparency = 1
	itemsFrame.BorderSizePixel = 0
	itemsFrame.ScrollBarThickness = 4
	itemsFrame.ScrollingDirection = Enum.ScrollingDirection.X
	itemsFrame.AutomaticCanvasSize = Enum.AutomaticSize.X
	itemsFrame.CanvasSize = UDim2.new()
	local il = Instance.new("UIListLayout")
	il.FillDirection = Enum.FillDirection.Horizontal
	il.Padding = UDim.new(0, 8)
	il.SortOrder = Enum.SortOrder.LayoutOrder
	il.Parent = itemsFrame
	itemsFrame.Parent = panel
	status = Theme.text("", UDim2.new(0.6, 0, 0, 20), Theme.MUTED, Enum.Font.GothamBold, 14)
	status.Position = UDim2.new(0, 14, 1, -28)
	status.Parent = panel
	local buttons = Theme.frame(UDim2.new(0.4, 0, 0, 34), UDim2.new(0.6, -12, 1, -40), Theme.SLATE, 1)
	local bl = Instance.new("UIListLayout")
	bl.FillDirection = Enum.FillDirection.Horizontal
	bl.HorizontalAlignment = Enum.HorizontalAlignment.Right
	bl.Padding = UDim.new(0, 6)
	bl.Parent = buttons
	buttons.Parent = panel
	local rotate = Theme.button("ROTATE (R)", UDim2.fromOffset(110, 32), "Dark")
	rotate.Activated:Connect(function()
		rot = (rot + 1) % 4
	end)
	rotate.Parent = buttons
	local remove = Theme.button("REMOVE (X)", UDim2.fromOffset(110, 32), "Red")
	remove.Activated:Connect(function()
		select(nil)
		removing = true
	end)
	remove.Parent = buttons
	placeButton = Theme.button("PLACE", UDim2.fromOffset(90, 32), "Orange")
	placeButton.Visible = Hud.touch
	placeButton.Activated:Connect(function()
		confirm(aim)
	end)
	placeButton.Parent = buttons

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if input.KeyCode == Enum.KeyCode.B and not processed then
			setActive(not active)
			return
		end
		if not active or processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.R then
			rot = (rot + 1) % 4
		elseif input.KeyCode == Enum.KeyCode.X then
			select(nil)
			removing = true
		elseif input.KeyCode == Enum.KeyCode.Escape then
			setActive(false)
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
		if active then
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
