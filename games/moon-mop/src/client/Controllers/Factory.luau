--!strict
-- Draws every base's belts at work: the pods the server reports glide between updates, coloured
-- by what they carry. Also hangs little readouts over your own Dot Bot docks (what the bot is
-- doing) and batteries and solar (power in, stored, in use).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Theme = require(script.Parent.Theme)

local Factory = {}

local player = Players.LocalPlayer
local GLIDE = 0.25 -- matches the server's view rate

local LOOK: { [string]: { color: Color3, material: Enum.Material } } = {
	Dust = { color = Color3.fromRGB(205, 205, 212), material = Enum.Material.SmoothPlastic },
	Stardust = { color = Color3.fromRGB(170, 120, 255), material = Enum.Material.Neon },
	Glass = { color = Color3.fromRGB(120, 230, 255), material = Enum.Material.Glass },
	Gem = { color = Color3.fromRGB(255, 80, 190), material = Enum.Material.Neon },
}

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { Workspace.Terrain }

local groundCache: { [string]: CFrame } = {}

-- A plot-space spot on the ground, up = the Moon's up there.
local function spot(plot: Model, index: string, x: number, z: number): CFrame?
	local key = string.format("%s:%d:%d", index, math.floor(x * 2), math.floor(z * 2))
	local cached = groundCache[key]
	if cached then
		return cached
	end
	local frame = plot:GetPivot()
	local flat = frame:PointToWorldSpace(Vector3.new(x, 0, z))
	local up = frame.UpVector
	local hit = Workspace:Raycast(flat + up * 30, -up * 60, terrainOnly)
	local cf = CFrame.fromMatrix(if hit then hit.Position else flat, frame.RightVector, up)
	groundCache[key] = cf
	return cf
end

local function podPart(kind: string): Part
	local look = LOOK[kind] or LOOK.Dust
	local p = Instance.new("Part")
	p.Name = "Pod"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(1.6, 1.6, 1.6)
	p.Color = look.color
	p.Material = look.material
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	local band = Instance.new("Part")
	band.Name = "Band"
	band.Shape = Enum.PartType.Cylinder
	band.Size = Vector3.new(0.35, 1.7, 1.7)
	band.Color = Theme.ORANGE
	band.Material = Enum.Material.SmoothPlastic
	band.Anchored = true
	band.CanCollide = false
	band.CanQuery = false
	band.CanTouch = false
	band.Parent = p
	return p
end

local readouts: { [Instance]: BillboardGui } = {}

-- A small label floating over a building part. Kept in PlayerGui with an Adornee (billboards
-- under PlayerGui are what the HUD uses elsewhere) and dropped when the part goes away.
local function readout(parent: BasePart, name: string): TextLabel
	local existing = readouts[parent]
	if existing and existing.Name == name then
		return existing:FindFirstChildOfClass("TextLabel") :: TextLabel
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = name
	bb.Adornee = parent
	bb.Size = UDim2.fromOffset(170, 34)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	bb.MaxDistance = 90
	bb.AlwaysOnTop = true
	bb.ResetOnSpawn = false
	local label = Theme.text("", UDim2.fromScale(1, 1), Theme.WHITE, Enum.Font.GothamBold, 16)
	label.BackgroundTransparency = 0.25
	label.BackgroundColor3 = Theme.SLATE
	label.TextXAlignment = Enum.TextXAlignment.Center
	Theme.corner(label, 6)
	label.Parent = bb
	bb.Parent = player:WaitForChild("PlayerGui")
	readouts[parent] = bb
	parent.Destroying:Once(function()
		bb:Destroy()
		readouts[parent] = nil
	end)
	return label
end

local function myPlot(): Model?
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then
		return nil
	end
	for _, p in plots:GetChildren() do
		local buildings = p:FindFirstChild("Buildings")
		local first = buildings and buildings:FindFirstChildWhichIsA("Model")
		if first and first:GetAttribute("Owner") == player.UserId then
			return p :: Model
		end
	end
	return nil
end

local function updateReadouts()
	local plot = myPlot()
	if not plot then
		return
	end
	local buildings = plot:FindFirstChild("Buildings")
	if not buildings then
		return
	end
	local stored = plot:GetAttribute("Battery") :: number? or 0
	local storeMax = plot:GetAttribute("BatteryMax") :: number? or 0
	local powerIn = plot:GetAttribute("PowerIn") :: number? or 0
	local powerUse = plot:GetAttribute("PowerUse") :: number? or 0
	for _, m in buildings:GetChildren() do
		if not m:IsA("Model") or m:GetAttribute("Owner") ~= player.UserId then
			continue
		end
		local id = m:GetAttribute("Building")
		local anchor = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
		if not anchor then
			continue
		end
		if id == "DotBotMk1" or id == "DotBotMk2" or id == "CosmicOcto" then
			local label = readout(anchor, "BotStatus")
			local status = m:GetAttribute("Status") :: string? or "Starting up"
			label.Text = status
			label.TextColor3 = if status == "Cleaning" or status == "Flying out" then Theme.TEAL else Theme.AMBER
		elseif id == "Battery" then
			local label = readout(anchor, "Charge")
			label.Text = string.format("%.1f / %.0f kWh", stored, storeMax)
			label.TextColor3 = if stored > 0.05 then Theme.GREEN else Theme.MUTED
			local fill = math.clamp(if storeMax > 0 then stored / storeMax else 0, 0, 1)
			for _, part in m:GetChildren() do
				local level = part:GetAttribute("Level")
				if part:IsA("BasePart") and typeof(level) == "number" then
					part.Transparency = if level <= fill * 4 + 0.01 then 0 else 0.85
				end
			end
		elseif id == "SolarPost" or id == "TwinSolar" then
			local label = readout(anchor, "Solar")
			label.Text = string.format("%.1f kW in · %.1f kW used", powerIn, powerUse)
			label.TextColor3 = if powerIn >= powerUse then Theme.YELLOW else Theme.RED
		end
	end
end

-- A Cosmic Octo firing a pod home: it arcs over the Moon to the Pod Catcher.
local function octoPod(from: Vector3, to: Vector3, seconds: number, folder: Instance)
	local pod = podPart("Dust")
	pod.Size = Vector3.new(2.4, 2.4, 2.4)
	pod.Color = Color3.fromRGB(190, 160, 255)
	pod.Material = Enum.Material.Neon
	pod.Parent = folder
	local band = pod:FindFirstChild("Band") :: BasePart
	local mid = (from + to) / 2
	local up = (mid - Config.Moon.Centre).Unit
	local peak = mid + up * math.max(20, (to - from).Magnitude * 0.35)
	local t = 0
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function(dt: number)
		t = math.min(1, t + dt / seconds)
		local a = from:Lerp(peak, t)
		local b = peak:Lerp(to, t)
		local cf = CFrame.new(a:Lerp(b, t))
		pod.CFrame = cf
		band.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
		if t >= 1 then
			conn:Disconnect()
			pod:Destroy()
		end
	end)
end

function Factory.start()
	local folder = Instance.new("Folder")
	folder.Name = "BeltPods"
	folder.Parent = Workspace
	local pods: { [number]: Part } = {}
	Remotes.get("Factory").OnClientEvent:Connect(function(view: any)
		if typeof(view) ~= "table" then
			return
		end
		local seen: { [number]: boolean } = {}
		local plots = Workspace:FindFirstChild("Plots")
		for index, flat in view do
			local plot = plots and plots:FindFirstChild("Plot" .. tostring(index))
			if not plot or not plot:IsA("Model") or typeof(flat) ~= "table" then
				continue
			end
			for i = 1, #flat - 4, 5 do
				local id, x, z, h, kind = flat[i], flat[i + 1], flat[i + 2], flat[i + 3], flat[i + 4]
				if
					typeof(id) ~= "number"
					or typeof(x) ~= "number"
					or typeof(z) ~= "number"
					or typeof(h) ~= "number"
				then
					continue
				end
				local base = spot(plot, tostring(index), x, z)
				if not base then
					continue
				end
				local cf = base * CFrame.new(0, 1.6 + h, 0)
				seen[id] = true
				local part = pods[id]
				if not part then
					local fresh = podPart(if typeof(kind) == "string" then kind else "Dust")
					fresh.CFrame = cf
					local band = fresh:FindFirstChild("Band") :: BasePart
					band.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
					fresh.Parent = folder
					pods[id] = fresh
				else
					TweenService:Create(part, TweenInfo.new(GLIDE, Enum.EasingStyle.Linear), { CFrame = cf }):Play()
					local band = part:FindFirstChild("Band") :: BasePart
					TweenService:Create(band, TweenInfo.new(GLIDE, Enum.EasingStyle.Linear), {
						CFrame = cf * CFrame.Angles(0, 0, math.pi / 2),
					}):Play()
				end
			end
		end
		for id, part in pods do
			if not seen[id] then
				part:Destroy()
				pods[id] = nil
			end
		end
	end)
	Remotes.get("WorldEvent").OnClientEvent:Connect(function(kind: any, data: any)
		if
			kind == "OctoPod"
			and typeof(data) == "table"
			and typeof(data.from) == "Vector3"
			and typeof(data.to) == "Vector3"
		then
			octoPod(data.from, data.to, if typeof(data.t) == "number" then math.clamp(data.t, 0.5, 6) else 2, folder)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			updateReadouts()
		end
	end)
end

return Factory
