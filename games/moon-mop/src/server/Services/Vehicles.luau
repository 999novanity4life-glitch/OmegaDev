--!strict
-- Vehicles: take one out of your Garage, drive it (the driver's client moves it; the server
-- owns the rules), clean into its tank as you go, dump the tank at any station drum or your own
-- Drop Pad / Collector Pad, and get paid for stunts. The server samples where the vehicle really
-- is, checks the speed is possible, and does all the cleaning and paying.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Loadout = require(Shared:WaitForChild("Loadout"))
local Places = require(Shared:WaitForChild("Places"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sweep = require(Shared:WaitForChild("Sweep"))
local Validate = require(Shared:WaitForChild("Validate"))

local Automation = require(script.Parent.Automation)
local Base = require(script.Parent.Base)
local Crew = require(script.Parent.Crew)
local Dust = require(script.Parent.Dust)
local RemoteGuard = require(script.Parent.RemoteGuard)
local Zones = require(script.Parent.Zones)
local buildVehicle =
	require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("World"):WaitForChild("Vehicles"))

local Vehicles = {}

local CENTRE = Config.Moon.Centre
local worldEvent = Remotes.get("WorldEvent")

local folder = Instance.new("Folder")
folder.Name = "Vehicles"
folder.Parent = Workspace

local lastSample: { [Player]: { at: Vector3, t: number }? } = {}

local function stats(s: Crew.Session): Loadout.VehicleStats?
	local def = s.vehicleId and Loadout.vehicle(s.vehicleId)
	if not def then
		return nil
	end
	return Loadout.vehicleStats(def, s.data.vehicles[def.id], s.fx, s.dial)
end

local function seatWeld(s: Crew.Session, model: Model): boolean
	local char = s.player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local body = model.PrimaryPart
	if not root or not body then
		return false
	end
	local offset = (model:GetAttribute("SeatOffset") :: Vector3?) or Vector3.new(0, 3, 0)
	root.CFrame = body.CFrame * CFrame.new(offset)
	local weld = Instance.new("Weld")
	weld.Name = "VehicleSeat"
	weld.Part0 = body
	weld.Part1 = root
	weld.C0 = CFrame.new(offset)
	weld.Parent = body
	if char then
		for _, p in char:GetDescendants() do
			if p:IsA("BasePart") then
				p.Massless = true
			end
		end
	end
	body.Anchored = false
	body:SetNetworkOwner(s.player)
	-- with streaming on, the driver must always have their vehicle
	model:AddPersistentPlayer(s.player)
	model:SetAttribute("Driver", s.player.UserId)
	return true
end

local function unseat(s: Crew.Session, model: Model)
	local body = model.PrimaryPart
	if body then
		local weld = body:FindFirstChild("VehicleSeat")
		if weld then
			weld:Destroy()
		end
		body.Anchored = true
		body.AssemblyLinearVelocity = Vector3.zero
	end
	model:SetAttribute("Driver", 0)
	model:RemovePersistentPlayer(s.player)
	local char = s.player.Character
	if char then
		for _, p in char:GetDescendants() do
			if p:IsA("BasePart") then
				p.Massless = false
			end
		end
	end
end

local function setDriving(s: Crew.Session, model: Model?, id: string?)
	s.vehicle = model
	s.vehicleId = id
	s.dirty = true
	local char = s.player.Character
	if char then
		char:SetAttribute("Driving", model ~= nil)
	end
	lastSample[s.player] = nil
end

function Vehicles.store(s: Crew.Session)
	local m = s.vehicle
	if m then
		unseat(s, m)
		m:Destroy()
	end
	for _, other in folder:GetChildren() do
		if other:GetAttribute("Owner") == s.player.UserId then
			other:Destroy()
		end
	end
	setDriving(s, nil, nil)
end

local function spawnVehicle(s: Crew.Session, id: string)
	local def = Loadout.vehicle(id)
	if not def or not s.data.vehicles[id] then
		return
	end
	local near, at = Zones.near(s.player, "garage")
	if not near or not at then
		Crew.feedback(s.player, "Error", { text = "Take vehicles out at your Garage" })
		return
	end
	Vehicles.store(s)
	local model = buildVehicle(id)
	model.Name = string.format("%s_%d", id, s.player.UserId)
	model:SetAttribute("Owner", s.player.UserId)
	-- park it just outside the garage door, on the ground
	local garage: Model? = nil
	local plot = Base.plotOf(s.player)
	if plot then
		for _, m in plot.buildings:GetChildren() do
			if m:GetAttribute("Building") == "Garage" and m:IsA("Model") then
				garage = m
			end
		end
	end
	local gcf = if garage then garage:GetPivot() else Places.frameAt(at)
	local out = gcf * CFrame.new(0, def.size.Y * 0.45 + 0.5, -18 - def.size.Z / 2)
	model:PivotTo(out)
	model.Parent = folder
	if seatWeld(s, model) then
		setDriving(s, model, id)
		Crew.feedback(s.player, "Vehicle", { id = id, action = "spawn" })
	else
		model:Destroy()
	end
end

local function dump(s: Crew.Session)
	if not s.vehicle or s.tankKg < 0.01 then
		Crew.feedback(s.player, "Error", { text = "The tank is empty" })
		return
	end
	-- a Collector Pad wired to belts takes the load as pods for the Pod Cannon
	local uid, padAt = Automation.collectorFor(s.player)
	if uid then
		local dust = s.tankKg - s.tankStar
		Automation.feed(s.player, uid, "Dust", dust)
		Automation.feed(s.player, uid, "Stardust", s.tankStar)
		Crew.stat(s, "dumps", 1)
		s.tankKg, s.tankStar = 0, 0
		s.dirty = true
		Crew.feedback(s.player, "Toast", { text = "Tank emptied onto the belts" })
		worldEvent:FireAllClients("Unload", { at = padAt, by = s.player.UserId })
		return
	end
	local at: Vector3? = nil
	local ok, pos = Zones.near(s.player, "drum")
	if ok then
		at = pos
	else
		ok, pos = Zones.near(s.player, "collector")
		if ok then
			at = pos
		else
			ok, pos = Zones.near(s.player, "droppad")
			if ok then
				at = pos
			end
		end
	end
	if not at then
		Crew.feedback(s.player, "Error", { text = "Dump at a station drum, a Collector Pad or a Drop Pad" })
		return
	end
	local pods = { { kg = s.tankKg, stardust = s.tankStar } }
	local amount = Economy.depositPayout(pods, s.fx)
	Crew.stat(s, "kg", s.tankKg)
	Crew.stat(s, "dumps", 1)
	s.tankKg, s.tankStar = 0, 0
	Crew.earn(s, amount, "Launch", at)
	worldEvent:FireAllClients("Launch", { at = at, pods = 1, by = s.player.UserId })
	s.dirty = true
end

RemoteGuard.connect(Remotes.get("VehicleIntent"), function(action: any, arg: any)
	if action == "spawn" then
		return Validate.shortString(arg, 24) and Loadout.vehicle(arg) ~= nil
	elseif action == "dial" then
		return Validate.integer(arg, 0, 3)
	end
	return (action == "store" or action == "enter" or action == "exit" or action == "dump" or action == "lights")
		and arg == nil
end, function(player: Player, action: string, arg: any)
	local s = Crew.get(player)
	if not s then
		return
	end
	if action == "spawn" then
		spawnVehicle(s, arg)
	elseif action == "store" then
		if s.vehicle and not Zones.near(player, "garage") then
			Crew.feedback(player, "Error", { text = "Park at your Garage to store it" })
			return
		end
		Vehicles.store(s)
	elseif action == "exit" then
		local m = s.vehicle
		if m then
			unseat(s, m)
			setDriving(s, nil, nil)
			m:SetAttribute("Parked", true)
			local body = m.PrimaryPart
			local char = player.Character
			if body and char then
				char:PivotTo(body.CFrame * CFrame.new(-(m:GetExtentsSize().X / 2 + 3), 1, 0))
				Crew.feedback(player, "MoveTo", body.CFrame * CFrame.new(-(m:GetExtentsSize().X / 2 + 3), 1, 0))
			end
		end
	elseif action == "enter" then
		if s.vehicle then
			return
		end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		for _, m in folder:GetChildren() do
			if m:IsA("Model") and m:GetAttribute("Owner") == player.UserId and root and m.PrimaryPart then
				if (m.PrimaryPart.Position - root.Position).Magnitude < m:GetExtentsSize().Magnitude / 2 + 8 then
					if seatWeld(s, m) then
						setDriving(s, m, m:GetAttribute("Vehicle") :: string)
					end
					return
				end
			end
		end
	elseif action == "dial" then
		local ups = s.vehicleId and s.data.vehicles[s.vehicleId]
		s.dial = math.clamp(arg, 0, if ups then ups.SuctionDial or 0 else 0)
		s.dirty = true
	elseif action == "dump" then
		dump(s)
	elseif action == "lights" then
		local m = s.vehicle
		local st = stats(s)
		if m and st and st.lights then
			m:SetAttribute("Lights", not m:GetAttribute("Lights"))
		end
	end
end)

-- Stunts: the client counts them, the server caps them and checks the vehicle was moving.
local lastStunt: { [Player]: number } = {}
RemoteGuard.connect(Remotes.get("VehicleReport"), function(flips: any, spins: any, air: any)
	return Validate.integer(flips, 0, 3) and Validate.integer(spins, 0, 6) and Validate.finiteNumber(air, 0, 8)
end, function(player: Player, flips: number, spins: number, air: number)
	local s = Crew.get(player)
	local now = os.clock()
	if not s or not s.vehicle or now - (lastStunt[player] or 0) < 1.5 then
		return
	end
	lastStunt[player] = now
	if air < Config.Stunts.MinAirTime then
		return
	end
	local reward = flips * Config.Stunts.Flip + spins * Config.Stunts.Spin + air * Config.Stunts.AirPerSecond
	if reward > 0 then
		Crew.stat(s, "flips", flips)
		Crew.stat(s, "airTime", air)
		Crew.earn(s, reward, "Stunt")
		Crew.feedback(player, "Stunt", { flips = flips, spins = spins, air = air, amount = reward })
	end
end)

-- Cleaning: sample each driven vehicle 10 times a second and sweep the strip its roller covered.
task.spawn(function()
	local warned: { [Player]: number } = {}
	while true do
		task.wait(Config.Dust.ServerTick)
		local now = os.clock()
		for player, s in Crew.all() do
			local m = s.vehicle
			local def = s.vehicleId and Loadout.vehicle(s.vehicleId)
			local body = m and m.PrimaryPart
			if not m or not def or not body or not def.cleans then
				continue
			end
			local st = stats(s) :: Loadout.VehicleStats
			local cf = body.CFrame
			local head = cf:PointToWorldSpace(Vector3.new(0, -def.size.Y * 0.45, -def.size.Z / 2))
			local up = (head - CENTRE).Unit
			local prev = lastSample[player]
			lastSample[player] = { at = head, t = now }
			if not prev then
				continue
			end
			local dt = now - prev.t
			if not Sweep.plausible((head - prev.at).Magnitude, dt, st.speed * st.turbo * 1.6) then
				continue
			end
			local room = st.tank - s.tankKg
			if room <= 1e-4 then
				if now - (warned[player] or 0) > 5 then
					warned[player] = now
					Crew.feedback(player, "Error", { text = "Tank full! Dump it at a drum or your Collector Pad" })
				end
				continue
			end
			local kg, star =
				Dust.sweep(player, prev.at, head, up, st.width, 1 + (s.fx.cleanPct or 0) / 100, false, room)
			if kg > 0 then
				s.tankKg += kg
				s.tankStar += star
				s.dirty = true
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	for _, m in folder:GetChildren() do
		if m:GetAttribute("Owner") == player.UserId then
			m:Destroy()
		end
	end
	lastSample[player] = nil
	lastStunt[player] = nil
end)

-- Respawning drops you out of the vehicle (it stays parked where it was).
Crew.onReady(function(s)
	s.player.CharacterAdded:Connect(function()
		if s.vehicle then
			local m = s.vehicle
			setDriving(s, nil, nil)
			if m.Parent then
				m:SetAttribute("Driver", 0)
				local body = m.PrimaryPart
				if body then
					body.Anchored = true
				end
			end
		end
	end)
end)

return Vehicles
