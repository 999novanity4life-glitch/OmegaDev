--!strict
-- Builds the 12 stations on their pads and runs what happens at them: the deposit drum, the
-- menus (supply wall, Upgrade Board, Moon Map, teleport pad), teleports between stations
-- ($50 each, like the original) and Moon Map waypoints.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Places = require(Shared:WaitForChild("Places"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Validate = require(Shared:WaitForChild("Validate"))

local Crew = require(script.Parent.Crew)
local Dust = require(script.Parent.Dust)
local RemoteGuard = require(script.Parent.RemoteGuard)
local Zones = require(script.Parent.Zones)
local buildStation = require(script.Parent.Parent.World.Station)

local Stations = {}

local R = Config.Moon.Radius
local CENTRE = Config.Moon.Centre

local folder = Instance.new("Folder")
folder.Name = "Stations"
folder.Parent = Workspace

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { Workspace.Terrain }

-- Ground radius under a direction (terrain), or the bare sphere if the ray misses.
function Stations.groundAt(dir: Vector3): Vector3
	local hit = Workspace:Raycast(CENTRE + dir * (R + 400), -dir * 700, terrainOnly)
	return if hit then hit.Position else CENTRE + dir * R
end

local spawns: { CFrame } = {}
Stations.spawns = spawns
local supplyStands: { CFrame } = {}
Stations.supplyStands = supplyStands

local function prompt(parent: BasePart, action: string, object: string, hold: number, menu: string?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p.Style = Enum.ProximityPromptStyle.Custom
	if menu then
		p:SetAttribute("Menu", menu)
	end
	p.Parent = parent
	return p
end

local function anchorPart(name: string, cf: CFrame, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = cf
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Parent = parent
	return p
end

local kit = ServerStorage:FindFirstChild("MoonMopKit")
for _, st in Places.stations do
	local ground = Stations.groundAt(st.dir)
	local up = st.dir
	-- turn every station so its door faces the same way round the local north
	local frame = Places.frameAt(ground - up * 0.6)
	local model, a = buildStation(frame, string.upper(st.name), st.index, kit)
	model:SetAttribute("StationIndex", st.index)
	model.Parent = folder
	spawns[st.index] = a.spawn
	-- where a new hire starts: in front of the supply wall, facing it (P1 f_003)
	local wall = a.supply
	supplyStands[st.index] = CFrame.lookAt((wall * CFrame.new(0, 0, -8)).Position, wall.Position, wall.UpVector)

	local drumPoint = anchorPart("DrumPrompt", a.drum * CFrame.new(0, 4, 0), model)
	local deposit = prompt(drumPoint, "Deposit pods", "Dust Drum", Config.Timings.DepositSeconds)
	deposit.Triggered:Connect(function(player)
		local s = Crew.get(player)
		if s then
			Dust.deposit(s, a.cannon.Position)
		end
	end)
	Zones.add("drum", a.drum.Position, 16)

	prompt(anchorPart("SupplyPrompt", a.supply * CFrame.new(0, 4, -3), model), "Browse", "Supply Wall", 0, "supply")
	Zones.add("supply", a.supply.Position, 24)
	prompt(anchorPart("BoardPrompt", a.board * CFrame.new(0, 4, -3), model), "Open", "Upgrade Board", 0, "board")
	Zones.add("board", a.board.Position, 24)
	prompt(anchorPart("MapPrompt", a.globe * CFrame.new(0, 5, 0), model), "Open", "Moon Map", 0, "map")
	prompt(
		anchorPart("TeleportPrompt", a.teleport * CFrame.new(0, 3, 0), model),
		"Teleport",
		"Station Link",
		0,
		"teleport"
	)
	Zones.add("teleport", a.teleport.Position, 16)
	model:SetAttribute("Cannon", a.cannon.Position)
	model:SetAttribute("Spawn", a.spawn.Position)
	Zones.add("station", a.floor.Position, 60)
end

-- Respawns happen at the North Station, inside by the door.
do
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "NorthSpawn"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = spawns[1] * CFrame.new(0, -0.4, 0)
	spawn.Neutral = true
	spawn.Duration = 0
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	spawn.Parent = folder
end

-- Move a player's character (on foot) to a frame on the surface.
function Stations.moveTo(player: Player, cf: CFrame)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not char or not root then
		return
	end
	char:PivotTo(cf * CFrame.new(0, 3, 0))
	root.AssemblyLinearVelocity = Vector3.zero
	-- the client owns its character's physics and its gravity controller keeps its own frame,
	-- so it is told to move too
	Crew.feedback(player, "MoveTo", cf * CFrame.new(0, 3, 0))
end

RemoteGuard.connect(Remotes.get("Teleport"), function(index: any)
	return Validate.integer(index, 1, #Places.stations)
end, function(player: Player, index: number)
	local s = Crew.get(player)
	if not s or s.vehicle then
		if s then
			Crew.feedback(player, "Error", { text = "Leave your vehicle first" })
		end
		return
	end
	if not (Zones.near(player, "teleport") or s.fx.teleportAnywhere) then
		Crew.feedback(player, "Error", { text = "Use a teleport pad in a station" })
		return
	end
	local price = Economy.teleportPrice(s.fx)
	if not Crew.spend(s, price, "a teleport") then
		return
	end
	Crew.stat(s, "teleports", 1)
	Crew.feedback(player, "Teleport", { station = index })
	task.wait(0.6) -- the client fades out first
	Stations.moveTo(player, spawns[index])
end)

RemoteGuard.connect(Remotes.get("Waypoint"), function(action: any, arg: any)
	if action == "add" then
		return typeof(arg) == "Vector3"
			and Validate.finiteNumber(arg.X, -1.01, 1.01)
			and Validate.finiteNumber(arg.Y, -1.01, 1.01)
			and Validate.finiteNumber(arg.Z, -1.01, 1.01)
			and math.abs(arg.Magnitude - 1) < 0.01
	end
	return action == "clear" and Validate.integer(arg, 1, 12)
end, function(player: Player, action: string, arg: any)
	local s = Crew.get(player)
	if not s then
		return
	end
	local list = s.data.waypoints
	if action == "add" then
		local limit = math.min(12, 4 + (s.fx.waypoints or 0))
		if #list >= limit then
			Crew.feedback(player, "Error", { text = string.format("You can pin %d waypoints", limit) })
			return
		end
		local d = (arg :: Vector3).Unit
		table.insert(list, { d.X, d.Y, d.Z })
	elseif list[arg] then
		table.remove(list, arg)
	end
	s.dirty = true
end)

-- Anything that needs the player standing at a station (and not driving).
function Stations.atStation(player: Player): boolean
	return (Zones.near(player, "station"))
end

-- New players start inside the North Station by the Boss Bot.
Crew.onReady(function(s)
	if not s.player.Character then
		s.player.CharacterAdded:Wait()
	end
	task.wait(0.3)
	Stations.moveTo(s.player, spawns[1])
end)

return Stations
