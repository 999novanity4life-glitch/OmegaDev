--!strict
-- The core loop on the server: brushing, the Dust Pack, packing pods (Q), dropped pods, and
-- deposits that launch pods for money. Sector and region rewards are paid here too.
-- The client only says "tool on/off" and "pack"; the server samples where the tool really is.

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

local Crew = require(script.Parent.Crew)
local Moon = require(script.Parent.Moon)
local RemoteGuard = require(script.Parent.RemoteGuard)

local Dust = {}

local CENTRE = Config.Moon.Centre
local worldEvent = Remotes.get("WorldEvent")

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include
groundParams.FilterDescendantsInstances = { Workspace.Terrain }

-- Sweep a strip and put the dust in a container with `room` kg left. Returns kg and Stardust kg.
function Dust.sweep(
	by: Player,
	from: Vector3,
	to: Vector3,
	up: Vector3,
	width: number,
	clean: number,
	allowSteep: boolean,
	room: number
): (number, number)
	local kg, star = 0, 0
	if room <= 0 then
		return 0, 0
	end
	for _, sample in Sweep.samples(from, to, up, width) do
		local k, st = Moon.scrubDir((sample.point - CENTRE).Unit, sample.area, clean, by, allowSteep)
		kg += k
		star += st
		if kg >= room then
			break
		end
	end
	if kg > room then
		star *= room / kg
		kg = room
	end
	return kg, star
end

-- Where the tool head touches the ground, or nil in the air.
local function toolHead(char: Model, reach: number): (Vector3?, Vector3?)
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then
		return nil, nil
	end
	local up = Places.up(root.Position)
	local fwd = root.CFrame.LookVector
	fwd -= up * fwd:Dot(up)
	if fwd.Magnitude < 1e-3 then
		return nil, nil
	end
	local probe = root.Position + fwd.Unit * reach
	local hit = Workspace:Raycast(probe + up * 2, -up * (hum.HipHeight + root.Size.Y / 2 + 6), groundParams)
	if not hit then
		return nil, nil
	end
	return hit.Position, up
end

-- Drop a pod at a position (Auto Packer with full hands, or a vehicle unloading).
local podFolder = Instance.new("Folder")
podFolder.Name = "DroppedPods"
podFolder.Parent = Workspace

local function dropPod(s: Crew.Session, pod: Crew.Pod, at: Vector3)
	local up = Places.up(at)
	local part = Instance.new("Part")
	part.Name = "Pod"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(3.2, 2.2, 2.2)
	-- cylinders run along X, so stand the pod up by pointing X along the local up
	part.CFrame = CFrame.fromMatrix(at + up * 1.6, up, Places.frameAt(at).LookVector)
	part.Anchored = true
	part.CanCollide = false
	part.Color = Color3.fromRGB(236, 238, 243)
	part.Material = Enum.Material.SmoothPlastic
	part:SetAttribute("Owner", s.player.UserId)
	part:SetAttribute("Kg", pod.kg)
	part:SetAttribute("Star", pod.stardust)
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(110, 230, 255)
	glow.Range = 6
	glow.Brightness = 1.4
	glow.Parent = part
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up"
	prompt.ObjectText = string.format("Dust Pod %.1f kg", pod.kg)
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player)
		local who = Crew.get(player)
		if not who or player.UserId ~= part:GetAttribute("Owner") then
			return
		end
		if #who.pods >= Crew.carryLimit(who) then
			Crew.feedback(player, "Error", { text = "Your hands are full. Deposit pods first." })
			return
		end
		table.insert(
			who.pods,
			{ kg = part:GetAttribute("Kg") :: number, stardust = part:GetAttribute("Star") :: number }
		)
		part:Destroy()
		who.dirty = true
		Crew.feedback(player, "PodPicked", nil)
	end)
	part.Parent = podFolder
end
Dust.dropPod = dropPod

-- Turn the pack into a pod. Into your hands if there is room, else at your feet.
function Dust.pack(s: Crew.Session, auto: boolean?): boolean
	if s.packKg < 0.01 then
		if not auto then
			Crew.feedback(s.player, "Error", { text = "Your Dust Pack is empty" })
		end
		return false
	end
	local now = os.clock()
	if now < s.packBusyUntil then
		return false
	end
	s.packBusyUntil = now + Loadout.packSeconds(s.fx) * (if auto then 0.25 else 1)
	local pod = { kg = s.packKg, stardust = s.packStar }
	s.packKg, s.packStar = 0, 0
	if #s.pods < Crew.carryLimit(s) then
		table.insert(s.pods, pod)
	else
		local char = s.player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			dropPod(s, pod, root.Position - Places.up(root.Position) * 2.5)
		end
	end
	s.dirty = true
	Crew.feedback(s.player, "Packed", { kg = pod.kg, auto = auto == true })
	return true
end

-- Sell every carried pod. `fee` for the Pocket Drop Pad; `cannon` is where the launch is shown.
function Dust.deposit(s: Crew.Session, cannon: Vector3?, fee: number?): number
	if #s.pods == 0 then
		if s.packKg > 0.01 then
			Crew.feedback(s.player, "Error", { text = "Press Q to pack your dust into a pod first" })
		else
			Crew.feedback(s.player, "Error", { text = "No pods to deposit" })
		end
		return 0
	end
	local pods = s.pods
	s.pods = {}
	local kg = 0
	for _, p in pods do
		kg += p.kg
	end
	local amount = Economy.depositPayout(pods, s.fx, fee)
	Crew.stat(s, "kg", kg)
	Crew.stat(s, "deposits", 1)
	Crew.earn(s, amount, "Launch", cannon)
	if cannon then
		worldEvent:FireAllClients("Launch", { at = cannon, pods = #pods, by = s.player.UserId })
	end
	if (s.data.stats.deposits or 0) <= 1 then
		Crew.feedback(s.player, "Cutscene", { name = "PodCannon", at = cannon })
	end
	return amount
end

-- Sector and region rewards.
Moon.onSectorDone(function(sectorId, by)
	if not by then
		return
	end
	local s = Crew.get(by)
	if not s then
		return
	end
	local dir = Moon.sector:position(sectorId)
	local reward = Economy.sectorReward(Sweep.angleFromNorth(dir), s.fx)
	Crew.stat(s, "sectors", 1)
	Crew.earn(s, reward, "Sector", CENTRE + dir * Config.Moon.Radius)
	Crew.feedback(by, "SectorDone", { sector = sectorId, amount = reward })
	-- Crew Share: nearby crewmates get a cut
	for _, other in Crew.all() do
		if other ~= s and other.fx.crewPct then
			local char = other.player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and Places.arc(Places.dirOf(root.Position), dir) < 150 then
				Crew.earn(other, reward * other.fx.crewPct / 100, "Crew share", nil)
			end
		end
	end
end)

Moon.onRegionDone(function(regionId, by)
	if not by then
		return
	end
	local s = Crew.get(by)
	if not s then
		return
	end
	local reward = Economy.regionReward(s.fx)
	Crew.stat(s, "regions", 1)
	Crew.earn(s, reward, "Region", nil)
	worldEvent:FireAllClients("RegionDone", { region = regionId, by = by.UserId, amount = reward })
end)

-- Remotes.
RemoteGuard.connect(Remotes.get("ToolIntent"), function(action: any, slot: any)
	if action == "on" or action == "off" then
		return slot == nil
	end
	return action == "equip" and Validate.integer(slot, 1, 6)
end, function(player: Player, action: string, slot: number?)
	local s = Crew.get(player)
	if not s then
		return
	end
	if action == "equip" then
		if slot and s.data.belt[slot] then
			s.data.equipped = slot
			s.dirty = true
		end
		return
	end
	s.toolOn = action == "on"
	s.lastHead = nil
	s.dirty = true
	Crew.syncCharacter(s)
end)

RemoteGuard.connect(Remotes.get("Pack"), function(...: any)
	return select("#", ...) == 0
end, function(player: Player)
	local s = Crew.get(player)
	if s then
		Dust.pack(s, false)
	end
end)

-- Brushing tick.
local fullWarned: { [Player]: number } = {}
task.spawn(function()
	local dtTarget = Config.Dust.ServerTick
	while true do
		task.wait(dtTarget)
		local now = os.clock()
		for player, s in Crew.all() do
			local char = player.Character
			if not char or not s.toolOn or s.vehicle then
				s.lastHead = nil
				continue
			end
			local _, stats = Crew.equippedTool(s)
			local head, up = toolHead(char, stats.reach)
			if not head or not up then
				s.lastHead = nil
				continue
			end
			local last = s.lastHead
			local dt = now - s.lastT
			s.lastHead, s.lastT = head, now
			if not last then
				continue
			end
			local maxSpeed = Loadout.walkSpeed(s.fx, true) * 1.6 -- jetpack and slopes
			if not Sweep.plausible((head - last).Magnitude, dt, maxSpeed) then
				continue
			end
			local room = stats.pack - s.packKg
			if room <= 1e-4 then
				if s.fx.autoPack and Dust.pack(s, true) then
					room = stats.pack
				else
					if now - (fullWarned[player] or 0) > 4 then
						fullWarned[player] = now
						Crew.feedback(player, "PackFull", nil)
					end
					continue
				end
			end
			local kg, star = Dust.sweep(player, last, head, up, stats.width, stats.clean, true, room)
			if kg > 0 then
				s.packKg += kg
				s.packStar += star
				s.dirty = true
			end
		end
	end
end)

-- Magnet Pods: your dropped pods drift to you.
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, pod in podFolder:GetChildren() do
			if not pod:IsA("BasePart") then
				continue
			end
			local owner = game:GetService("Players"):GetPlayerByUserId(pod:GetAttribute("Owner") :: number)
			local s = owner and Crew.get(owner)
			local char = owner and owner.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if s and root and s.fx.magnetPods and #s.pods < Crew.carryLimit(s) then
				if (root.Position - pod.Position).Magnitude < 24 then
					table.insert(
						s.pods,
						{ kg = pod:GetAttribute("Kg") :: number, stardust = pod:GetAttribute("Star") :: number }
					)
					s.dirty = true
					pod:Destroy()
				end
			end
		end
	end
end)

return Dust
