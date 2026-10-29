--!strict
-- Mop Base plots. 16 plots ring the North Station; a player claims one (or gets their saved one
-- back) and builds on it with the Build Tool. Buildings are saved in plot coordinates, so a
-- base can move to any free plot on another server. The server checks every placement against
-- Shared/Plot, charges for it, and refunds removals (full for a minute, then half).
-- Other services ask Base for a player's buildings and where they stand in the world.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Places = require(Shared:WaitForChild("Places"))
local Plot = require(Shared:WaitForChild("Plot"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Validate = require(Shared:WaitForChild("Validate"))

local Crew = require(script.Parent.Crew)
local Dust = require(script.Parent.Dust)
local RemoteGuard = require(script.Parent.RemoteGuard)
local Stations = require(script.Parent.Stations)
local Zones = require(script.Parent.Zones)
local buildModel = require(script.Parent.Parent.World.Buildings)

local Base = {}

local CENTRE = Config.Moon.Centre
local HALF = Plot.HALF

local folder = Instance.new("Folder")
folder.Name = "Plots"
folder.Parent = Workspace

type PlotState = {
	index: number,
	frame: CFrame,
	owner: Player?,
	model: Model,
	buildings: Folder,
	sign: TextLabel,
	prompt: ProximityPrompt,
}

local plots: { PlotState } = {}
local plotOf: { [Player]: PlotState } = {}
local placed: { [Player]: { [number]: Model } } = {}
local changedCallbacks: { (player: Player) -> () } = {}
local claim: (player: Player, p: PlotState) -> ()

-- World frame for a plot position: on the ground, up = radial up there, facing the plot's way
-- turned by r quarter turns.
function Base.worldFrame(p: PlotState, x: number, z: number, r: number): CFrame
	local flat = p.frame:PointToWorldSpace(Vector3.new(x, 0, z))
	local dir = (flat - CENTRE).Unit
	local ground = Stations.groundAt(dir)
	local look = p.frame.LookVector
	local right = look:Cross(dir).Unit
	return CFrame.fromMatrix(ground, right, dir) * CFrame.Angles(0, -r * math.pi / 2, 0)
end

local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

-- Plot markers: corner posts with orange lights, edge lines and a sign with a claim prompt.
for _, info in Places.plots do
	local ground = Stations.groundAt(info.dir)
	local frame = Places.frameAt(ground)
	local model = Instance.new("Model")
	model.Name = "Plot" .. info.index
	model:SetAttribute("PlotIndex", info.index)
	local state: PlotState = {
		index = info.index,
		frame = frame,
		owner = nil,
		model = model,
		buildings = Instance.new("Folder"),
		sign = Instance.new("TextLabel"),
		prompt = Instance.new("ProximityPrompt"),
	}
	state.buildings.Name = "Buildings"
	state.buildings.Parent = model
	for _, c in { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } } do
		local cf = Base.worldFrame(state, c[1] * HALF, c[2] * HALF, 0)
		part(model, Vector3.new(1, 4, 1), cf * CFrame.new(0, 2, 0), Color3.fromRGB(226, 230, 236))
		local light = part(
			model,
			Vector3.new(1.2, 0.6, 1.2),
			cf * CFrame.new(0, 4.2, 0),
			Color3.fromRGB(255, 132, 28),
			Enum.Material.Neon
		)
		light.CanCollide = false
	end
	-- dashed edges every 12 studs
	for k = -HALF + 6, HALF - 6, 12 do
		for _, e in { { k, -HALF, 0 }, { k, HALF, 0 }, { -HALF, k, 1 }, { HALF, k, 1 } } do
			local cf = Base.worldFrame(state, e[1], e[2], e[3])
			local dash = part(
				model,
				Vector3.new(6, 0.15, 0.5),
				cf * CFrame.new(0, 0.1, 0),
				Color3.fromRGB(255, 132, 28),
				Enum.Material.Neon
			)
			dash.CanCollide = false
			dash.CanQuery = false
			dash.Transparency = 0.35
		end
	end
	-- sign at the edge facing the station
	local signCf = Base.worldFrame(state, 0, -HALF + 2, 0)
	part(model, Vector3.new(0.4, 6, 0.4), signCf * CFrame.new(-3, 3, 0), Color3.fromRGB(150, 156, 168))
	part(model, Vector3.new(0.4, 6, 0.4), signCf * CFrame.new(3, 3, 0), Color3.fromRGB(150, 156, 168))
	local board = part(model, Vector3.new(7, 3, 0.3), signCf * CFrame.new(0, 5, 0), Color3.fromRGB(30, 34, 42))
	board.Name = "Sign"
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	local text = state.sign
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBlack
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(255, 190, 60)
	text.Text = string.format("PLOT %d\nFREE", info.index)
	text.Parent = gui
	gui.Parent = board
	local p = state.prompt
	p.ActionText = "Claim plot"
	p.ObjectText = "Mop Base plot " .. info.index
	p.HoldDuration = 1
	p.MaxActivationDistance = 14
	p.RequiresLineOfSight = false
	p.Style = Enum.ProximityPromptStyle.Custom
	p.Parent = board
	-- the pivot is the plot's own frame, so clients can turn plot coordinates into world ones
	model.WorldPivot = frame
	model.Parent = folder
	table.insert(plots, state)
	p.Triggered:Connect(function(player)
		claim(player, state)
	end)
end

function Base.onChanged(fn: (player: Player) -> ())
	table.insert(changedCallbacks, fn)
end

local function changed(player: Player)
	for _, fn in changedCallbacks do
		task.spawn(fn, player)
	end
end

function Base.plotOf(player: Player): PlotState?
	return plotOf[player]
end

function Base.buildings(player: Player): { Plot.Building }
	local s = Crew.get(player)
	return if s then s.data.buildings else {}
end

-- The placed model for a building uid.
function Base.model(player: Player, uid: number): Model?
	local list = placed[player]
	return if list then list[uid] else nil
end

-- Zones a building opens (Garage, Drop Pad, Collector Pad).
local ZONES: { [string]: { kind: string, radius: number } } = {
	Garage = { kind = "garage", radius = 26 },
	DropPad = { kind = "droppad", radius = 9 },
	CollectorPad = { kind = "collector", radius = 16 },
}

local function spawnModel(player: Player, p: PlotState, b: Plot.Building)
	local m = buildModel(b.id)
	m.Name = string.format("%s_%d", b.id, b.uid)
	m:SetAttribute("Uid", b.uid)
	m:SetAttribute("Owner", player.UserId)
	m:SetAttribute("Building", b.id)
	m:PivotTo(Base.worldFrame(p, b.x, b.z, b.r))
	m.Parent = p.buildings
	placed[player] = placed[player] or {}
	placed[player][b.uid] = m
	local z = ZONES[b.id]
	if z then
		Zones.add(z.kind, m:GetPivot().Position, z.radius, player.UserId)
	end
	if b.id == "DropPad" then
		local chute = m:FindFirstChild("Chute") :: BasePart?
		if chute then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Deposit pods"
			prompt.ObjectText = "Drop Pad"
			prompt.HoldDuration = Config.Timings.DepositSeconds
			prompt.MaxActivationDistance = 12
			prompt.RequiresLineOfSight = false
			prompt.Style = Enum.ProximityPromptStyle.Custom
			prompt.Parent = chute
			prompt.Triggered:Connect(function(who)
				local s = Crew.get(who)
				if s and who == player then
					Dust.deposit(s, chute.Position + chute.CFrame.UpVector * 3)
				end
			end)
		end
	end
	if b.id == "Garage" then
		local console = m:FindFirstChild("Console") :: BasePart?
		if console then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Open"
			prompt.ObjectText = "Garage"
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 12
			prompt.RequiresLineOfSight = false
			prompt.Style = Enum.ProximityPromptStyle.Custom
			prompt:SetAttribute("Menu", "garage")
			prompt:SetAttribute("Owner", player.UserId)
			prompt.Parent = console
		end
	end
end

local function clearModels(player: Player)
	local list = placed[player]
	if list then
		for _, m in list do
			m:Destroy()
		end
	end
	placed[player] = nil
	for _, z in ZONES do
		Zones.removeOwned(z.kind, player.UserId)
	end
end

local function refreshSign(p: PlotState)
	p.sign.Text = if p.owner
		then string.format("PLOT %d\n%s", p.index, string.upper(p.owner.DisplayName))
		else string.format("PLOT %d\nFREE", p.index)
	p.prompt.Enabled = p.owner == nil
end

function claim(player: Player, p: PlotState)
	local s = Crew.get(player)
	if not s then
		return
	end
	if p.owner and p.owner ~= player then
		Crew.feedback(player, "Error", { text = "That plot is taken" })
		return
	end
	local old = plotOf[player]
	if old == p then
		return
	end
	if old then
		clearModels(player)
		old.owner = nil
		refreshSign(old)
	end
	p.owner = player
	plotOf[player] = p
	s.data.plot = p.index
	s.dirty = true
	refreshSign(p)
	for _, b in s.data.buildings do
		spawnModel(player, p, b)
	end
	s.data.garage = false
	for _, b in s.data.buildings do
		if b.id == "Garage" then
			s.data.garage = true
		end
	end
	Crew.feedback(player, "Plot", { index = p.index })
	changed(player)
end

Base.claim = claim

-- Saved plot if it is free, else the first free one, once the player has a Build Tool or has
-- built before (new players claim one at a sign).
Crew.onReady(function(s)
	if not s.data.buildTool and #s.data.buildings == 0 and s.data.plot == 0 then
		return
	end
	local want = plots[s.data.plot]
	if want and want.owner == nil then
		claim(s.player, want)
		return
	end
	for _, p in plots do
		if p.owner == nil then
			claim(s.player, p)
			return
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	clearModels(player)
	local p = plotOf[player]
	if p then
		p.owner = nil
		refreshSign(p)
	end
	plotOf[player] = nil
end)

-- Is the player's character standing on their own plot?
local function onOwnPlot(player: Player, p: PlotState): boolean
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	local rel = p.frame:PointToObjectSpace(root.Position)
	return math.abs(rel.X) < HALF + 40 and math.abs(rel.Z) < HALF + 40
end

local function place(s: Crew.Session, p: PlotState, id: string, x: number, z: number, r: number): boolean
	local list = s.data.buildings
	local ok, why = Plot.canPlace(list, id, x, z, r)
	if not ok then
		Crew.feedback(s.player, "Error", { text = why or "Can't build there" })
		return false
	end
	local def = Plot.def(id) :: Config.BuildDef
	local price = Plot.price(list, id, s.fx)
	if not Crew.spend(s, price, def.name) then
		return false
	end
	local b: Plot.Building = { uid = s.data.nextUid, id = id, x = x, z = z, r = r, paid = price, t = os.time() }
	s.data.nextUid += 1
	table.insert(list, b)
	if id == "Garage" then
		s.data.garage = true
	end
	spawnModel(s.player, p, b)
	Crew.stat(s, "built", 1)
	s.dirty = true
	return true
end

RemoteGuard.connect(Remotes.get("BuildIntent"), function(action: any, a: any, b: any, c: any, d: any, e: any)
	if action == "place" then
		return Validate.shortString(a, 24)
			and Plot.def(a) ~= nil
			and Validate.finiteNumber(b, -HALF, HALF)
			and Validate.finiteNumber(c, -HALF, HALF)
			and Validate.integer(d, 0, 3)
			and e == nil
	elseif action == "belt" then
		return Validate.finiteNumber(a, -HALF, HALF)
			and Validate.finiteNumber(b, -HALF, HALF)
			and Validate.finiteNumber(c, -HALF, HALF)
			and Validate.finiteNumber(d, -HALF, HALF)
			and e == nil
	elseif action == "remove" then
		return Validate.integer(a, 1, 1e9) and b == nil
	elseif action == "claim" then
		return Validate.integer(a, 1, #plots) and b == nil
	end
	return false
end, function(player: Player, action: string, a: any, b: any, c: any, d: any)
	local s = Crew.get(player)
	if not s then
		return
	end
	if action == "claim" then
		claim(player, plots[a])
		return
	end
	local p = plotOf[player]
	if not p then
		Crew.feedback(player, "Error", { text = "Claim a Mop Base plot first" })
		return
	end
	if not s.data.buildTool then
		Crew.feedback(player, "Error", { text = "Buy the Build Tool at a supply wall" })
		return
	end
	if not onOwnPlot(player, p) then
		Crew.feedback(player, "Error", { text = "Stand on your plot to build" })
		return
	end
	if action == "place" then
		if place(s, p, a, Plot.snap(b), Plot.snap(c), d) then
			Crew.feedback(player, "Built", { id = a })
			changed(player)
		end
	elseif action == "belt" then
		local laid = 0
		for _, tile in Plot.beltRun(Plot.snap(a), Plot.snap(b), Plot.snap(c), Plot.snap(d)) do
			if Plot.canPlace(s.data.buildings, "Belt", tile.x, tile.z, tile.r) then
				if not place(s, p, "Belt", tile.x, tile.z, tile.r) then
					break
				end
				laid += 1
			end
		end
		if laid > 0 then
			Crew.feedback(player, "Built", { id = "Belt", count = laid })
			changed(player)
		end
	elseif action == "remove" then
		local list = s.data.buildings
		for i, bld in list do
			if bld.uid == a then
				table.remove(list, i)
				local refund = Plot.refund(bld, os.time() - bld.t)
				local m = placed[player] and placed[player][bld.uid]
				if m then
					m:Destroy()
					placed[player][bld.uid] = nil
				end
				local z = ZONES[bld.id]
				if z then
					-- rebuild this kind's zones from what is left
					Zones.removeOwned(z.kind, player.UserId)
					for _, other in list do
						local om = placed[player] and placed[player][other.uid]
						if other.id == bld.id and om then
							Zones.add(z.kind, om:GetPivot().Position, z.radius, player.UserId)
						end
					end
				end
				if bld.id == "Garage" then
					s.data.garage = false
				end
				if refund > 0 then
					Crew.earn(s, refund, "Refund")
				end
				s.dirty = true
				changed(player)
				return
			end
		end
	end
end)

return Base
