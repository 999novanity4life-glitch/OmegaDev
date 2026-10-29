--!strict
-- The Moon's collectables: 195 tangled company flags (hold to untangle, $100) and 26 lost
-- probes buried at crater sites (sweep the site's hex clean, then survey the probe, $250).
-- Every player has their own list in the save; the world objects are shared, and each client
-- hides the prompts it has already done.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Places = require(Shared:WaitForChild("Places"))

local Crew = require(script.Parent.Crew)
local Moon = require(script.Parent.Moon)
local Stations = require(script.Parent.Stations)

local Finds = {}

local folder = Instance.new("Folder")
folder.Name = "Finds"
folder.Parent = Workspace

local ORANGE = Color3.fromRGB(255, 132, 28)
local WHITE = Color3.fromRGB(236, 238, 242)
local STEEL = Color3.fromRGB(150, 156, 168)

local function part(model: Model, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function prompt(parent: BasePart, action: string, object: string, hold: number): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p.Style = Enum.ProximityPromptStyle.Custom
	p.Parent = parent
	return p
end

-- A bent pole with the flag cloth wrapped round it. The client straightens it once untangled.
local function buildFlag(index: number, dir: Vector3): Model
	local ground = Stations.groundAt(dir)
	local base = Places.frameAt(ground, (index * 2.399) % (2 * math.pi))
	local model = Instance.new("Model")
	model.Name = "Flag" .. index
	local foot = part(model, Vector3.new(1.4, 0.6, 1.4), base * CFrame.new(0, 0.1, 0), STEEL, Enum.Material.Metal)
	model.PrimaryPart = foot
	local tilt = base * CFrame.Angles(0, 0, math.rad(24)) * CFrame.new(0, 3.2, 0)
	local pole = part(model, Vector3.new(0.3, 6.4, 0.3), tilt, STEEL, Enum.Material.Metal)
	pole.Name = "Pole"
	-- crumpled cloth: three twisted strips in the company colours
	for k = 0, 2 do
		local strip = part(
			model,
			Vector3.new(1.2, 1.1, 0.12),
			tilt * CFrame.new(0, 1.6 - k * 0.9, 0) * CFrame.Angles(0, k * 2.1, math.rad(18 - k * 15)),
			if k == 1 then WHITE else ORANGE,
			Enum.Material.Fabric
		)
		strip.Name = "Tangle"
	end
	-- the straight flag, hidden until untangled (client side)
	local up = base * CFrame.new(0, 3.4, 0)
	local straight = part(model, Vector3.new(0.3, 6.8, 0.3), up, STEEL, Enum.Material.Metal)
	straight.Name = "Straight"
	straight.Transparency = 1
	local cloth = part(model, Vector3.new(3, 1.9, 0.1), up * CFrame.new(1.65, 2.3, 0), ORANGE, Enum.Material.Fabric)
	cloth.Name = "Cloth"
	cloth.Transparency = 1
	local stripe = part(model, Vector3.new(3, 0.5, 0.12), up * CFrame.new(1.65, 2.3, 0), WHITE, Enum.Material.Fabric)
	stripe.Name = "Cloth"
	stripe.Transparency = 1
	local p = prompt(foot, "Untangle", "Company Flag", Config.Flags.HoldSeconds)
	p:SetAttribute("Find", "flag")
	p:SetAttribute("Index", index)
	model:SetAttribute("Find", "flag")
	model:SetAttribute("Index", index)
	model.Parent = folder
	return model
end

-- A probe half buried in a crater, covered in dust until its hex is swept.
local probeSector: { [number]: number } = {}
local probePrompt: { [number]: ProximityPrompt } = {}

local function buildProbe(index: number, dir: Vector3): Model
	local ground = Stations.groundAt(dir)
	local base = Places.frameAt(ground, index * 1.3)
	local model = Instance.new("Model")
	model.Name = "Probe" .. index
	local body = part(
		model,
		Vector3.new(4, 2.2, 3),
		base * CFrame.new(0, 0.2, 0) * CFrame.Angles(math.rad(14), 0, math.rad(-9)),
		Color3.fromRGB(196, 170, 96),
		Enum.Material.Foil
	)
	body.Name = "Body"
	model.PrimaryPart = body
	local panel = part(
		model,
		Vector3.new(6, 0.15, 2.6),
		body.CFrame * CFrame.new(4.6, 0.3, 0) * CFrame.Angles(0, 0, math.rad(-12)),
		Color3.fromRGB(38, 58, 120),
		Enum.Material.Glass
	)
	panel.Name = "Panel"
	local dish = part(model, Vector3.new(0.4, 2.6, 2.6), body.CFrame * CFrame.new(-1.2, 1.9, 0), WHITE)
	dish.Shape = Enum.PartType.Cylinder
	dish.Name = "Dish"
	local light =
		part(model, Vector3.new(0.5, 0.5, 0.5), body.CFrame * CFrame.new(0.8, 1.25, 0.8), ORANGE, Enum.Material.Neon)
	light.Shape = Enum.PartType.Ball
	light.Name = "Beacon"
	local p = prompt(body, "Survey", "Lost Probe", Config.Probes.HoldSeconds)
	p:SetAttribute("Find", "probe")
	p:SetAttribute("Index", index)
	model:SetAttribute("Find", "probe")
	model:SetAttribute("Index", index)
	local s = Moon.sector:locate(dir)
	probeSector[s] = index
	local open = Moon.isSectorDone(s)
	p.Enabled = open
	model:SetAttribute("Uncovered", open)
	probePrompt[index] = p
	model.Parent = folder
	return model
end

local function onFlag(player: Player, index: number)
	local s = Crew.get(player)
	local key = tostring(index)
	if not s or s.data.flags[key] then
		return
	end
	s.data.flags[key] = true
	Crew.stat(s, "flagsFixed", 1)
	local count = 0
	for _ in s.data.flags do
		count += 1
	end
	Crew.earn(s, Economy.flagReward(s.fx), "Flag untangled")
	Crew.feedback(player, "Find", { kind = "flag", index = index, count = count, total = #Places.flags })
	Crew.checkAchievements(s)
end

local function onProbe(player: Player, index: number)
	local s = Crew.get(player)
	local key = tostring(index)
	if not s or s.data.probes[key] then
		return
	end
	local p = probePrompt[index]
	if not p or not p.Enabled then
		return
	end
	s.data.probes[key] = true
	local count = 0
	for _ in s.data.probes do
		count += 1
	end
	Crew.earn(s, Economy.probeReward(s.fx), "Probe surveyed")
	Crew.feedback(player, "Find", { kind = "probe", index = index, count = count, total = #Places.probes })
	Crew.checkAchievements(s)
end

for i, dir in Places.flags do
	local m = buildFlag(i, dir)
	local p = (m.PrimaryPart :: BasePart):FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt
	p.Triggered:Connect(function(player)
		onFlag(player, i)
	end)
	if i % 40 == 0 then
		task.wait()
	end
end

for i, dir in Places.probes do
	buildProbe(i, dir)
	probePrompt[i].Triggered:Connect(function(player)
		onProbe(player, i)
	end)
end

Moon.onSectorDone(function(sectorId)
	local index = probeSector[sectorId]
	if index then
		probePrompt[index].Enabled = true
		local model = folder:FindFirstChild("Probe" .. index)
		if model then
			model:SetAttribute("Uncovered", true)
		end
	end
end)

function Finds.flagCount(): number
	return #Places.flags
end

return Finds
