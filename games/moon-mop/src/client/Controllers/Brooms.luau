--!strict
-- What every player's tool looks like, built from Parts on each client (cosmetic only: width,
-- pack and speed come from the server). The ladder follows Sharman's direction: three junk tools
-- that look weak, then planet brooms that get more detail and glow every tier, ending in the
-- Cosmic Broom with all eight planets orbiting and a black-hole pommel.
-- Look tiers (design doc): Junk = no glow; Planet = one light and one particle effect;
-- Giant = neon trim, orbiting moons or rings, a trail; Cosmic = glass/neon/forcefield, beams.
-- Each tool stays under ~30 parts and 3 emitters so 16 players still run on phones.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Loadout = require(Shared:WaitForChild("Loadout"))

local Brooms = {}

local CENTRE = Config.Moon.Centre

type Orbiter = {
	part: Part,
	radius: number,
	speed: number,
	phase: number,
	tilt: number,
	around: string,
	height: number,
}
type Built = {
	model: Model,
	head: BasePart,
	orbiters: { Orbiter },
	dust: ParticleEmitter?,
	trail: Trail?,
	id: string,
	spin: BasePart?,
}

local function p(
	model: Model,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	mat: Enum.Material?,
	shape: Enum.PartType?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = mat or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	if shape then
		part.Shape = shape
	end
	part.Parent = model
	return part
end

local function ball(model: Model, name: string, d: number, color: Color3, mat: Enum.Material?): Part
	return p(model, name, Vector3.new(d, d, d), CFrame.identity, color, mat, Enum.PartType.Ball)
end

local PLANETS: { [string]: { color: Color3, size: number, mat: Enum.Material? } } = {
	Mercury = { color = Color3.fromRGB(150, 146, 140), size = 0.9 },
	Venus = { color = Color3.fromRGB(232, 200, 120), size = 1.0 },
	Earth = { color = Color3.fromRGB(60, 130, 225), size = 1.1 },
	Mars = { color = Color3.fromRGB(205, 85, 50), size = 1.1 },
	Jupiter = { color = Color3.fromRGB(214, 172, 128), size = 1.5 },
	Saturn = { color = Color3.fromRGB(226, 204, 150), size = 1.3 },
	Uranus = { color = Color3.fromRGB(150, 222, 232), size = 1.2, mat = Enum.Material.Glass },
	Neptune = { color = Color3.fromRGB(50, 90, 230), size = 1.2 },
	Sun = { color = Color3.fromRGB(255, 190, 60), size = 1.6, mat = Enum.Material.Neon },
}
local EIGHT = { "Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune" }

local function emitter(parent: BasePart, color: Color3, rate: number, light: boolean?): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.LightEmission = if light then 0.8 else 0
	-- plain dust is a soft puff; magic brooms keep the default sparkle
	if not light then
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	end
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1.6) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.5, 1.2)
	e.Speed = NumberRange.new(2, 5)
	e.SpreadAngle = Vector2.new(60, 60)
	e.Acceleration = Vector3.zero
	e.Drag = 2
	e.Rate = rate
	e.Enabled = false
	e.Parent = parent
	return e
end

local function addLight(parent: BasePart, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = parent
end

-- Build a tool in local space: head centre at the origin, handle along +Y.
local function build(id: string): Built
	local def = Loadout.tool(id) or Config.Tools[1]
	local model = Instance.new("Model")
	model.Name = "Broom_" .. def.id
	local orbiters: { Orbiter } = {}
	local headW = math.clamp(def.width * 0.42, 0.9, 6.5)
	local handleLen = if def.look == "Junk" then 3.6 else 5.6
	local look = def.look
	local head: BasePart
	local dustColor = Color3.fromRGB(70, 66, 74) -- dark grit sprays off the brush (p1_140)
	local trailColor: Color3? = nil
	local spin: BasePart? = nil

	if def.id == "Toothbrush" then
		p(
			model,
			"Handle",
			Vector3.new(0.32, handleLen, 0.22),
			CFrame.new(0, handleLen / 2, 0.3),
			Color3.fromRGB(130, 200, 225)
		)
		p(
			model,
			"Chew",
			Vector3.new(0.36, 0.5, 0.26),
			CFrame.new(0, handleLen - 0.2, 0.3) * CFrame.Angles(0, 0, 0.3),
			Color3.fromRGB(110, 175, 200)
		)
		head = p(
			model,
			"Head",
			Vector3.new(headW * 0.5, 0.2, 0.6),
			CFrame.new(0, 0.35, 0.15),
			Color3.fromRGB(130, 200, 225)
		)
		p(
			model,
			"Bristles",
			Vector3.new(headW * 0.5, 0.35, 0.5),
			CFrame.new(0, 0.12, 0) * CFrame.Angles(0.35, 0, 0),
			Color3.fromRGB(235, 232, 220)
		)
	elseif def.id == "ScrubBrush" then
		p(
			model,
			"Handle",
			Vector3.new(0.4, handleLen, 0.4),
			CFrame.new(0, handleLen / 2, 0.3),
			Color3.fromRGB(140, 100, 62),
			Enum.Material.Wood
		)
		p(
			model,
			"Tape",
			Vector3.new(0.5, 0.7, 0.5),
			CFrame.new(0, handleLen * 0.7, 0.3),
			Color3.fromRGB(150, 154, 160),
			Enum.Material.Fabric
		)
		head = p(
			model,
			"Head",
			Vector3.new(headW * 0.6, 0.45, 0.9),
			CFrame.new(0, 0.5, 0.1),
			Color3.fromRGB(150, 108, 66),
			Enum.Material.Wood
		)
		p(
			model,
			"Bristles",
			Vector3.new(headW * 0.55, 0.35, 0.8),
			CFrame.new(0, 0.15, 0.1),
			Color3.fromRGB(190, 160, 110),
			Enum.Material.Fabric
		)
	elseif def.id == "DustpanBrush" then
		p(
			model,
			"Handle",
			Vector3.new(0.4, handleLen, 0.3),
			CFrame.new(0, handleLen / 2, 0.3),
			Color3.fromRGB(128, 132, 140)
		)
		head = p(
			model,
			"Head",
			Vector3.new(headW * 0.65, 0.4, 0.8),
			CFrame.new(0, 0.5, 0.1),
			Color3.fromRGB(128, 132, 140)
		)
		p(
			model,
			"Crack",
			Vector3.new(0.06, 0.42, 0.82),
			CFrame.new(headW * 0.1, 0.5, 0.1) * CFrame.Angles(0, 0.3, 0),
			Color3.fromRGB(60, 62, 70)
		)
		p(
			model,
			"TapeFix",
			Vector3.new(0.3, 0.44, 0.84),
			CFrame.new(headW * 0.1, 0.5, 0.1),
			Color3.fromRGB(170, 170, 176),
			Enum.Material.Fabric
		)
		p(
			model,
			"Bristles",
			Vector3.new(headW * 0.6, 0.3, 0.7),
			CFrame.new(0, 0.15, 0.1),
			Color3.fromRGB(70, 72, 78),
			Enum.Material.Fabric
		)
	else
		-- real brooms: metal handle, a ferrule, a wide head with bristles
		local planet = PLANETS[def.planet or ""] or PLANETS.Mercury
		local handleColor = if look == "Planet"
			then Color3.fromRGB(176, 180, 190)
			elseif look == "Giant" then Color3.fromRGB(205, 210, 220)
			else Color3.fromRGB(30, 30, 44)
		local handleMat = if look == "Planet"
			then Enum.Material.Metal
			elseif look == "Giant" then Enum.Material.Metal
			else Enum.Material.Glass
		if def.id == "VenusBroom" then
			handleColor = Color3.fromRGB(214, 176, 80)
		elseif def.id == "MarsBroom" then
			handleColor = Color3.fromRGB(150, 70, 45)
			handleMat = Enum.Material.CorrodedMetal
		end
		p(
			model,
			"Handle",
			Vector3.new(0.42, handleLen, 0.42),
			CFrame.new(0, handleLen / 2 + 0.6, 0.25),
			handleColor,
			handleMat
		)
		p(
			model,
			"Grip",
			Vector3.new(0.5, 1.1, 0.5),
			CFrame.new(0, handleLen - 0.2, 0.25),
			Color3.fromRGB(34, 36, 42),
			Enum.Material.Fabric
		)
		p(
			model,
			"Ferrule",
			Vector3.new(0.7, 0.5, 0.7),
			CFrame.new(0, 1.05, 0.2),
			planet.color,
			if look == "Planet" then Enum.Material.Metal else Enum.Material.Neon
		)
		head = p(model, "Head", Vector3.new(headW, 0.55, 0.9), CFrame.new(0, 0.75, 0.1), handleColor, handleMat)
		local bristleColor = if look == "Planet"
			then Color3.fromRGB(210, 196, 160)
			elseif look == "Giant" then planet.color
			else Color3.fromRGB(120, 90, 255)
		local bristleMat = if look == "Cosmic" then Enum.Material.Neon else Enum.Material.Fabric
		if def.id == "UranusBroom" then
			bristleColor, bristleMat = Color3.fromRGB(170, 236, 246), Enum.Material.Glass
		elseif def.id == "NeptuneBroom" then
			bristleColor = Color3.fromRGB(60, 110, 255)
		elseif def.id == "SolarBroom" then
			bristleColor = Color3.fromRGB(255, 160, 40)
		end
		p(model, "Bristles", Vector3.new(headW * 0.96, 0.55, 0.75), CFrame.new(0, 0.25, 0.1), bristleColor, bristleMat)
		if look ~= "Planet" then
			p(
				model,
				"Trim",
				Vector3.new(headW + 0.1, 0.12, 0.95),
				CFrame.new(0, 1.05, 0.1),
				planet.color,
				Enum.Material.Neon
			)
		end

		if def.id == "CosmicBroom" then
			-- eight planets round the handle, a black-hole pommel, a star trail
			for i, name in EIGHT do
				local spec = PLANETS[name]
				local b = ball(model, name, spec.size * 0.55, spec.color, spec.mat)
				table.insert(orbiters, {
					part = b,
					radius = 1.2 + i * 0.32,
					speed = 1.6 - i * 0.12,
					phase = i * 0.8,
					tilt = 0.25,
					around = "handle",
					height = 2 + i * 0.45,
				})
			end
			local hole = ball(model, "BlackHole", 1, Color3.fromRGB(4, 4, 8))
			hole.CFrame = CFrame.new(0, handleLen + 1.1, 0.25)
			local disk = p(
				model,
				"Accretion",
				Vector3.new(0.12, 1.8, 1.8),
				CFrame.new(0, handleLen + 1.1, 0.25) * CFrame.Angles(0, 0, math.rad(80)),
				Color3.fromRGB(255, 150, 60),
				Enum.Material.Neon,
				Enum.PartType.Cylinder
			)
			disk.Transparency = 0.2
			spin = disk
			addLight(head, Color3.fromRGB(140, 110, 255), 18, 2.4)
			trailColor = Color3.fromRGB(190, 170, 255)
			dustColor = Color3.fromRGB(180, 160, 255)
		elseif def.id == "SolarBroom" then
			local sun = ball(model, "Sun", 1.8, planet.color, Enum.Material.Neon)
			table.insert(
				orbiters,
				{ part = sun, radius = 0.01, speed = 0, phase = 0, tilt = 0, around = "head", height = 1.9 }
			)
			local flare = ball(model, "Flare", 2.6, Color3.fromRGB(255, 120, 30), Enum.Material.ForceField)
			table.insert(
				orbiters,
				{ part = flare, radius = 0.01, speed = 0, phase = 0, tilt = 0, around = "head", height = 1.9 }
			)
			addLight(head, Color3.fromRGB(255, 180, 90), 20, 3)
			trailColor = Color3.fromRGB(255, 170, 60)
			dustColor = Color3.fromRGB(255, 140, 40)
		else
			local planetBall = ball(model, "Planet", planet.size, planet.color, planet.mat)
			local around = if look == "Planet" then "handle" else "head"
			table.insert(orbiters, {
				part = planetBall,
				radius = if look == "Planet" then 0.9 else 0.01,
				speed = 0.9,
				phase = 0,
				tilt = if def.id == "UranusBroom" then 1.4 else 0.2,
				around = around,
				height = if look == "Planet" then handleLen * 0.75 else 2.3,
			})
			if def.id == "EarthBroom" then
				local moon = ball(model, "Moon", 0.35, Color3.fromRGB(210, 210, 214))
				table.insert(orbiters, {
					part = moon,
					radius = 1.1,
					speed = 2.4,
					phase = 0,
					tilt = 0.4,
					around = "handle",
					height = handleLen * 0.75,
				})
				local land = ball(model, "Land", planet.size * 0.7, Color3.fromRGB(80, 170, 90))
				land.Transparency = 0.15
				table.insert(orbiters, {
					part = land,
					radius = 0.9,
					speed = 0.9,
					phase = 0.15,
					tilt = 0.2,
					around = "handle",
					height = handleLen * 0.75,
				})
			elseif def.id == "MarsBroom" then
				for k = 1, 2 do
					local m = ball(model, "Moon" .. k, 0.3, Color3.fromRGB(170, 150, 130))
					table.insert(orbiters, {
						part = m,
						radius = 1.5 + k * 0.4,
						speed = 2.6 - k * 0.6,
						phase = k * 2,
						tilt = 0.5,
						around = "head",
						height = 2.3,
					})
				end
			elseif def.id == "SaturnBroom" then
				local ring = p(
					model,
					"Rings",
					Vector3.new(0.1, headW + 1.6, headW + 1.6),
					CFrame.identity,
					Color3.fromRGB(240, 222, 170),
					Enum.Material.Neon,
					Enum.PartType.Cylinder
				)
				ring.Transparency = 0.35
				spin = ring
			elseif def.id == "JupiterBroom" then
				local spot = ball(model, "Storm", planet.size * 0.35, Color3.fromRGB(200, 90, 60))
				table.insert(orbiters, {
					part = spot,
					radius = planet.size * 0.45,
					speed = 1.8,
					phase = 0,
					tilt = 0,
					around = "head",
					height = 2.3,
				})
			elseif def.id == "NeptuneBroom" then
				local vortex = p(
					model,
					"Vortex",
					Vector3.new(0.1, headW + 0.8, headW + 0.8),
					CFrame.identity,
					Color3.fromRGB(80, 140, 255),
					Enum.Material.ForceField,
					Enum.PartType.Cylinder
				)
				spin = vortex
			end
			if look ~= "Junk" then
				addLight(head, planet.color, if look == "Planet" then 8 else 12, if look == "Planet" then 0.8 else 1.6)
			end
			if look ~= "Planet" then
				trailColor = planet.color
			end
			if look ~= "Junk" then
				dustColor = planet.color:Lerp(Color3.fromRGB(70, 66, 74), 0.5)
			end
		end
	end

	local dust = emitter(head, dustColor, if look == "Junk" then 18 else 30, look == "Cosmic" or look == "Giant")
	local trail: Trail? = nil
	if trailColor then
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(-head.Size.X / 2, 0, 0)
		a0.Parent = head
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(head.Size.X / 2, 0, 0)
		a1.Parent = head
		local t = Instance.new("Trail")
		t.Attachment0 = a0
		t.Attachment1 = a1
		t.Color = ColorSequence.new(trailColor)
		t.LightEmission = 0.8
		t.Lifetime = 0.35
		t.Transparency = NumberSequence.new(0.3, 1)
		t.Enabled = false
		t.Parent = head
		trail = t
	end
	model.PrimaryPart = head
	return { model = model, head = head, orbiters = orbiters, dust = dust, trail = trail, id = def.id, spin = spin }
end
Brooms.build = build

-- Local-space rest pose of every part (so we can re-place the whole tool each frame).
local restPose: { [Model]: { [BasePart]: CFrame } } = {}

local built: { [Model]: Built } = {}
local folder = Instance.new("Folder")
folder.Name = "Brooms"
folder.Parent = Workspace

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { Workspace.Terrain }

local function ensure(char: Model): Built?
	local id = char:GetAttribute("Tool") :: string?
	if not id or char:GetAttribute("Driving") then
		local old = built[char]
		if old then
			old.model:Destroy()
			built[char] = nil
		end
		return nil
	end
	local b = built[char]
	if b and b.id == id then
		return b
	end
	if b then
		b.model:Destroy()
	end
	local nb = build(id)
	local pose = {}
	for _, d in nb.model:GetDescendants() do
		if d:IsA("BasePart") then
			pose[d] = d.CFrame
		end
	end
	restPose[nb.model] = pose
	nb.model.Parent = folder
	built[char] = nb
	return nb
end

local t0 = os.clock()
local function update()
	local now = os.clock() - t0
	local reduced = GuiService.ReducedMotionEnabled
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not char or not root then
			continue
		end
		local b = ensure(char)
		if not b then
			continue
		end
		local up = (root.Position - CENTRE).Unit
		local fwd = root.CFrame.LookVector
		fwd -= up * fwd:Dot(up)
		if fwd.Magnitude < 1e-3 then
			continue
		end
		fwd = fwd.Unit
		local right = fwd:Cross(up)
		local brushing = char:GetAttribute("Brushing") == true
		local reach = (char:GetAttribute("ToolReach") :: number?) or 2
		local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
		local handPos = if hand and hand:IsA("BasePart") then hand.Position else root.Position + right * 1 + up * 0.5
		-- your own tool in first person: held from the lower right of the view (P1 f_006, f_328),
		-- far enough out that a full-size tool reads as a hand-held one (playtested at FOV 80)
		local cam = Workspace.CurrentCamera
		local eye = root.Position + up * 1.55
		local mine = plr == Players.LocalPlayer and (cam.CFrame.Position - eye).Magnitude < 0.6
		if mine then
			handPos = (cam.CFrame * CFrame.new(1.6, -1.9, -3.4)).Position
		end
		local headPos: Vector3
		if mine and not brushing then
			headPos = (cam.CFrame * CFrame.new(1.5, -1.3, -6.6)).Position
		elseif brushing then
			-- sweep side to side in front of you, head on the ground
			local sway = if reduced then 0 else math.sin(now * 7) * 0.9
			local probe = root.Position + fwd * reach + right * sway
			local hit = Workspace:Raycast(probe + up * 2, -up * 9, terrainOnly)
			headPos = if hit then hit.Position else probe - up * 2.6
		else
			-- carried over the shoulder
			headPos = root.Position + up * 3.4 - fwd * 1.2 + right * 1.2
		end
		local axis = (handPos - headPos)
		if axis.Magnitude < 0.5 then
			axis = up
		end
		local y = axis.Unit
		local x = y:Cross(fwd)
		if x.Magnitude < 1e-3 then
			x = right
		end
		x = x.Unit
		local base = CFrame.fromMatrix(headPos, x, y)
		local pose = restPose[b.model]
		for part, rest in pose do
			part.CFrame = base * rest
		end
		-- orbiters
		for _, o in b.orbiters do
			local centre = if o.around == "head"
				then base * CFrame.new(0, o.height, 0.1)
				else base * CFrame.new(0, o.height, 0.25)
			if reduced then
				o.part.CFrame = centre * CFrame.new(o.radius, 0, 0)
			else
				local a = now * o.speed + o.phase
				o.part.CFrame = centre
					* CFrame.Angles(o.tilt, 0, 0)
					* CFrame.new(math.cos(a) * o.radius, 0, math.sin(a) * o.radius)
					* CFrame.Angles(0, a * 2, 0)
			end
		end
		if b.spin then
			local a = if reduced then 0 else now * 2
			if b.id == "CosmicBroom" then
				b.spin.CFrame = base * CFrame.new(0, 6.7, 0.25) * CFrame.Angles(0, a, math.rad(80))
			else
				b.spin.CFrame = base * CFrame.new(0, 0.7, 0.1) * CFrame.Angles(0, a, math.rad(90))
			end
		end
		local moving = root.AssemblyLinearVelocity.Magnitude > 2
		if b.dust then
			b.dust.Enabled = brushing and moving
			b.dust.Acceleration = up * 1.5
		end
		if b.trail then
			b.trail.Enabled = brushing and moving
		end
	end
	for char, b in built do
		if not char.Parent then
			b.model:Destroy()
			built[char] = nil
		end
	end
end

-- A fresh model of a tool, for 3D icons in menus and on the belt slots. Cached per id.
local iconCache: { [string]: Model } = {}
function Brooms.model(id: string): Model
	local m = iconCache[id]
	if not m then
		m = build(id).model
		iconCache[id] = m
	end
	return m
end

function Brooms.start()
	RunService.RenderStepped:Connect(update)
end

return Brooms
