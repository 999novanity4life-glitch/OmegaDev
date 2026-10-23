-- SkillService: the server owns cooldowns, hit detection, damage and knockback.
-- The client only asks ("use Bolt toward this direction") and plays visuals.
-- Follows ROBLOX_ENGINEERING_RULES remote rules: type + finiteness checks, server origin,
-- server cooldowns, server hit tests. Lives at ServerScriptService.SkillService.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Skills = ReplicatedStorage:WaitForChild("Skills")
local Data = require(Skills:WaitForChild("SkillData"))

local remotes = Instance.new("Folder")
remotes.Name = "SkillRemotes"
local UseSkill = Instance.new("RemoteEvent"); UseSkill.Name = "UseSkill"; UseSkill.Parent = remotes
local SkillFx = Instance.new("RemoteEvent"); SkillFx.Name = "SkillFx"; SkillFx.Parent = remotes
local SetTheme = Instance.new("RemoteEvent"); SetTheme.Name = "SetTheme"; SetTheme.Parent = remotes
remotes.Parent = Skills

local cooldowns: { [Player]: { [string]: number } } = {}

local function finiteVec(v: any): boolean
	return typeof(v) == "Vector3" and v.X == v.X and v.Y == v.Y and v.Z == v.Z and v.Magnitude < 1e4
end

local function alive(p: Player)
	local c = p.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	local r = c and c:FindFirstChild("HumanoidRootPart")
	if h and r and h.Health > 0 then
		return c, h, r :: BasePart
	end
	return nil
end

local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Exclude

local function targetsInRadius(pos: Vector3, radius: number, exclude: Model)
	overlap.FilterDescendantsInstances = { exclude, Workspace:FindFirstChild("SkillFX") }
	local found, out = {}, {}
	for _, part in Workspace:GetPartBoundsInRadius(pos, radius, overlap) do
		local model = part:FindFirstAncestorOfClass("Model")
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		local root = model and model:FindFirstChild("HumanoidRootPart")
		if hum and root and hum.Health > 0 and not found[model] then
			found[model] = true
			table.insert(out, { hum = hum, root = root })
		end
	end
	return out
end

local function hit(caster: Player, theme: string, t, fromPos: Vector3, def, lift: number)
	t.hum:TakeDamage(def.damage)
	local dir = (t.root.Position - fromPos) * Vector3.new(1, 0, 1)
	dir = dir.Magnitude > 0.01 and dir.Unit or Vector3.new(0, 0, -1)
	t.root:ApplyImpulse((dir * def.knock + Vector3.new(0, lift, 0)) * t.root.AssemblyMass)
	SkillFx:FireAllClients(caster.UserId, "Damage", theme, { pos = t.root.Position, amount = def.damage })
end

UseSkill.OnServerEvent:Connect(function(p: Player, id: any, aim: any)
	if typeof(id) ~= "string" then return end
	local def = Data.Skills[id]
	if not def or not finiteVec(aim) or aim.Magnitude < 0.5 or aim.Magnitude > 1.5 then return end
	local c, h, r = alive(p)
	if not c then return end
	local cd = cooldowns[p] or {}
	cooldowns[p] = cd
	local now = os.clock()
	if (cd[id] or 0) > now - 0.05 then return end -- 50 ms grace for latency
	cd[id] = now + def.cooldown
	local theme = p:GetAttribute("SkillTheme") or "Amber"
	local flat = aim * Vector3.new(1, 0, 1)
	flat = flat.Magnitude > 0.1 and flat.Unit or (r.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit

	SkillFx:FireAllClients(p.UserId, "Cast", theme, { skill = id })

	if def.shape == "Projectile" then
		task.delay(def.castTime, function()
			local c2, _, r2 = alive(p)
			if not c2 then return end
			local origin = r2.Position + Vector3.new(0, 1.2, 0) + flat * 2
			-- Clamp pitch to +-15 deg so mouse aim at the floor does not bury the shot (playtest 2026-10-23).
			local pitch = math.clamp(math.asin(math.clamp(aim.Unit.Y, -1, 1)), -math.rad(15), math.rad(15))
			local dir = (flat * math.cos(pitch) + Vector3.new(0, math.sin(pitch), 0)).Unit
			local rp = RaycastParams.new()
			rp.FilterType = Enum.RaycastFilterType.Exclude
			rp.FilterDescendantsInstances = { c2, Workspace:FindFirstChild("SkillFX") }
			local res = Workspace:Spherecast(origin, 0.6, dir * def.range, rp) -- thin sweep; def.radius widens the damage zone
			local hitPos = res and res.Position or origin + dir * def.range
			local travel = (hitPos - origin).Magnitude / def.speed
			SkillFx:FireAllClients(p.UserId, id, theme, { origin = origin, hit = hitPos, travel = travel })
			task.delay(travel, function()
				for _, t in targetsInRadius(hitPos, def.radius + 2.5, c2) do hit(p, theme, t, origin, def, 12) end
			end)
		end)
	elseif def.shape == "Ground" then
		task.delay(def.castTime, function()
			local c2, h2, r2 = alive(p)
			if not c2 then return end
			local ground = r2.Position - Vector3.new(0, h2.HipHeight + r2.Size.Y / 2, 0)
			SkillFx:FireAllClients(p.UserId, id, theme, { pos = ground })
			for _, t in targetsInRadius(ground, def.radius, c2) do hit(p, theme, t, ground, def, def.lift) end
		end)
	elseif def.shape == "Dash" then
		-- The caster's client moves its own character (it owns the physics); the server checks the result.
		local start = r.Position
		SkillFx:FireAllClients(p.UserId, id, theme, { dir = flat })
		task.delay(def.duration + 0.05, function()
			local c2, _, r2 = alive(p)
			if not c2 then return end
			local moved = (r2.Position - start).Magnitude
			if moved > def.distance * 1.6 + 6 then return end -- moved too far: ignore the hit
			local mid = (start + r2.Position) / 2
			for _, t in targetsInRadius(mid, math.max(def.radius, moved / 2 + 2), c2) do hit(p, theme, t, start, def, 8) end
		end)
	end
end)

SetTheme.OnServerEvent:Connect(function(p: Player, name: any)
	if typeof(name) == "string" and Data.Themes[name] then
		p:SetAttribute("SkillTheme", name)
	end
end)

local function init(p: Player) p:SetAttribute("SkillTheme", "Amber") end
Players.PlayerAdded:Connect(init)
for _, p in Players:GetPlayers() do init(p) end
Players.PlayerRemoving:Connect(function(p) cooldowns[p] = nil end)

-- Test dummies (studio test only): three simple rigs in front of spawn that respawn.
local function makeDummy(pos: Vector3)
	local m = Instance.new("Model")
	m.Name = "SkillDummy"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"; root.Size = Vector3.new(2, 2, 1); root.Transparency = 1; root.CFrame = CFrame.new(pos); root.Parent = m
	local torso = Instance.new("Part")
	torso.Name = "Torso"; torso.Size = Vector3.new(2, 2, 1); torso.Color = Color3.fromHex("#4A7D8C"); torso.CFrame = root.CFrame; torso.Parent = m
	local head = Instance.new("Part")
	head.Name = "Head"; head.Size = Vector3.new(1.2, 1.2, 1.2); head.Color = Color3.fromHex("#F2C98A"); head.CFrame = root.CFrame * CFrame.new(0, 1.6, 0); head.Parent = m
	local legs = Instance.new("Part")
	legs.Name = "Legs"; legs.Size = Vector3.new(2, 2, 1); legs.Color = Color3.fromHex("#2B5A6B"); legs.CFrame = root.CFrame * CFrame.new(0, -2, 0); legs.Parent = m
	for _, part in { torso, head, legs } do
		local w = Instance.new("WeldConstraint"); w.Part0 = root; w.Part1 = part; w.Parent = part
	end
	local hum = Instance.new("Humanoid")
	hum.HipHeight = 2
	hum.MaxHealth = 100
	hum.Health = 100
	hum.Parent = m
	m.PrimaryPart = root
	m.Parent = Workspace
	root:SetNetworkOwner(nil)
	hum.Died:Connect(function()
		task.wait(2)
		m:Destroy()
		makeDummy(pos)
	end)
end
local spawnLoc = Workspace:FindFirstChildOfClass("SpawnLocation")
local base = spawnLoc and spawnLoc.Position or Vector3.new(0, 3, 0)
for i = -1, 1 do
	makeDummy(base + Vector3.new(i * 8, 4, -22))
end
