--!strict
-- Throw visuals (client only, cosmetic): the overhand swing on the character,
-- the release burst, the fruit in flight and the splash. Modeled on Throw Food
-- For Animals (TFFA: ~0.2 s wind-up, release on the 3rd frame with a white
-- starburst at the hand, streak trail, ~0.3 s follow-through), with more VFX:
-- a shockwave ring, sparks, speed streaks and a rarity-coloured trail.
-- Everything respects GuiService.ReducedMotionEnabled (fewer particles, no
-- screen flash). No asset IDs: parts, Neon, Trails and ParticleEmitters only.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local SplashShape = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SplashShape"))
local FruitMesh = require(script.Parent.FruitMesh)
local Juice = require(script.Parent.Juice)

local ThrowFX = {}

local function reduced(): boolean
	return GuiService.ReducedMotionEnabled
end

local function fxPart(name: string, shape: Enum.PartType, color: Color3, size: Vector3, cframe: CFrame): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = size
	p.CFrame = cframe
	p.Parent = workspace
	return p
end

local function fadeOut(part: BasePart, seconds: number, goal: { [string]: any })
	goal.Transparency = 1
	local tween =
		TweenService:Create(part, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	tween.Completed:Once(function()
		part:Destroy()
	end)
	tween:Play()
end

-- One-shot spark burst from an invisible anchor. ParticleEmitter:Emit is on
-- the ParticleEmitter engine reference page.
local function sparks(at: Vector3, color: Color3, count: number, speed: number)
	local anchor = fxPart("Sparks", Enum.PartType.Ball, color, Vector3.new(0.2, 0.2, 0.2), CFrame.new(at))
	anchor.Transparency = 1
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Lifetime = NumberRange.new(0.25, 0.5)
	emitter.Speed = NumberRange.new(speed * 0.5, speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = 6
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new(0, 1)
	emitter.Parent = anchor
	emitter:Emit(if reduced() then math.ceil(count / 3) else count)
	task.delay(0.8, function()
		anchor:Destroy()
	end)
end

-- Joints. Classic R15 rigs use Motor6D; rigs with the avatar joint upgrade
-- use AnimationConstraint (RightUpperArm.RightShoulder, UpperTorso.Waist). Both
-- expose Transform, which the Animator rewrites every frame, so the swing
-- writes it in RunService.PreSimulation (after animations, before physics).
-- Verified in Studio 2026-11-20: writing C0 or the rig attachment had no
-- effect on an AnimationConstraint rig; Transform in PreSimulation did.
type Joint = (CFrame) -> ()

local function jointSetter(joint: Instance?): Joint?
	if joint and joint:IsA("Motor6D") then
		return function(cf: CFrame)
			joint.Transform = cf
		end
	elseif joint and joint:IsA("AnimationConstraint") then
		return function(cf: CFrame)
			joint.Transform = cf
		end
	end
	return nil
end

local function findJoints(character: Model): (Joint?, Joint?)
	local upperArm = character:FindFirstChild("RightUpperArm")
	local arm = jointSetter(upperArm and upperArm:FindFirstChild("RightShoulder"))
	if not arm then
		local torso = character:FindFirstChild("Torso") -- R6
		arm = jointSetter(torso and torso:FindFirstChild("Right Shoulder"))
	end
	local upperTorso = character:FindFirstChild("UpperTorso")
	local waist = jointSetter(upperTorso and upperTorso:FindFirstChild("Waist"))
	return arm, waist
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Swing keyframes: { time, arm pitch (rad), waist twist (rad) }.
-- Pitch rotates the arm about its shoulder X axis: + raises it forward/up.
local function swingKeys(cfg: typeof(Config.Throw)): { { number } }
	local w = cfg.SwingWindup
	local f = cfg.SwingFollow
	return {
		{ 0, 0, 0 },
		{ w * 0.6, 3.3, 0.55 }, -- arm cocked up and back, torso turned away
		{ w, 3.6, 0.6 }, -- top of the wind-up
		{ w + 0.06, 1.6, -0.35 }, -- whip over the top: release
		{ w + f * 0.6, 0.4, -0.5 }, -- follow-through across the body
		{ w + f + 0.15, 0, 0 }, -- settle
	}
end

-- Plays the overhand swing. `onRelease(handPosition)` fires on the release
-- frame. Returns the total swing length in seconds.
function ThrowFX.swing(character: Model?, onRelease: (Vector3) -> ()): number
	local cfg = Config.Throw
	local keys = swingKeys(cfg)
	local total = keys[#keys][1]
	local releaseAt = keys[4][1]
	local arm, waist
	if character then
		arm, waist = findJoints(character)
	end
	local start = os.clock()
	local released = false
	local connection: RBXScriptConnection
	connection = RunService.PreSimulation:Connect(function()
		local t = os.clock() - start
		local pitch, twist = 0, 0
		for i = 2, #keys do
			local a, b = keys[i - 1], keys[i]
			if t <= b[1] then
				local k = (t - a[1]) / math.max(b[1] - a[1], 1e-3)
				-- ease in-out for the body, sharp for the whip
				k = if i == 4 then k * k else k * k * (3 - 2 * k)
				pitch = lerp(a[2], b[2], k)
				twist = lerp(a[3], b[3], k)
				break
			end
		end
		if arm then
			arm(CFrame.Angles(pitch, 0, 0))
		end
		if waist then
			waist(CFrame.Angles(0, twist, 0))
		end
		if not released and t >= releaseAt then
			released = true
			local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local pos = if hand and hand:IsA("BasePart")
				then hand.Position
				elseif root and root:IsA("BasePart") then root.Position + Vector3.new(0, 2, -1)
				else Vector3.zero
			task.spawn(onRelease, pos)
		end
		if t >= total then
			connection:Disconnect()
		end
	end)
	return total
end

-- A painted VFX texture from Config.UI.Vfx, or nil while it is not there.
-- Config.UI ships on the stacked UI branch (PR #31); read it loosely so this
-- file works with or without it. `any`: the field is absent on this branch.
local function vfxTexture(name: string): string?
	local ui = (Config :: any).UI
	local id = ui and ui.Vfx and ui.Vfx[name]
	return if type(id) == "string" and id ~= "" then id else nil
end

-- Runs `step(t)` every frame until it returns false; t = seconds since start.
local function animate(step: (number) -> boolean)
	local start = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function()
		if not step(os.clock() - start) then
			connection:Disconnect()
		end
	end)
end

local function easeOut(k: number): number
	local c = math.clamp(k, 0, 1)
	return 1 - (1 - c) * (1 - c)
end

-- The release burst: white starburst (TFFA) + rarity shockwave ring + sparks.
function ThrowFX.releaseBurst(at: Vector3, rarityColor: Color3, forward: Vector3, power: number)
	local big = 0.6 + power -- power in 0..1
	local star = fxPart("Starburst", Enum.PartType.Ball, Color3.new(1, 1, 1), Vector3.new(1, 1, 1), CFrame.new(at))
	local light = Instance.new("PointLight")
	light.Color = Color3.new(1, 1, 1)
	light.Brightness = 4
	light.Range = 14
	light.Parent = star
	fadeOut(star, 0.2, { Size = Vector3.new(2, 2, 2) * big })
	-- shockwave: a flat cylinder facing along the throw (cylinder axis = X)
	local ring = fxPart(
		"Shockwave",
		Enum.PartType.Cylinder,
		rarityColor,
		Vector3.new(0.15, 1.5, 1.5),
		CFrame.lookAt(at + forward * 2, at + forward * 3) * CFrame.Angles(0, math.rad(90), 0)
	)
	ring.Transparency = 0.35
	fadeOut(ring, 0.3, { Size = Vector3.new(0.05, 5, 5) * big })
	sparks(at, rarityColor, math.floor(24 * big), 30)
	-- anime impact rays: thin spikes bursting out around the hand, in the
	-- plane facing the throw, the longest at full power
	local face = CFrame.lookAt(at, at + forward)
	local rays = if reduced() then 4 else 10
	for i = 1, rays do
		local a = (i - 1) / rays * 2 * math.pi + math.random() * 0.3
		local dir = (face.RightVector * math.cos(a) + face.UpVector * math.sin(a)).Unit
		local length = (1.5 + math.random() * 1.5) * big
		local spike = fxPart(
			"ReleaseRay",
			Enum.PartType.Block,
			if i % 2 == 0 then Color3.new(1, 1, 1) else rarityColor,
			Vector3.new(0.12, 0.12, 0.1),
			CFrame.new(at)
		)
		spike.Transparency = 0.05
		animate(function(t: number): boolean
			local k = t / 0.18
			if k >= 1 then
				spike:Destroy()
				return false
			end
			local len = length * easeOut(k)
			local mid = at + dir * (0.6 + len / 2)
			spike.Size = Vector3.new(0.12 * (1 - k * 0.7), 0.12 * (1 - k * 0.7), math.max(len, 0.1))
			spike.CFrame = CFrame.lookAt(mid, mid + dir)
			spike.Transparency = 0.05 + 0.95 * k * k
			return true
		end)
	end
	-- speed streaks shooting forward
	if not reduced() then
		for _ = 1, 6 do
			local side = Vector3.new(math.random() - 0.5, math.random() - 0.3, 0) * 3
			local from = at + side
			local streak = fxPart(
				"Streak",
				Enum.PartType.Block,
				Color3.new(1, 1, 1),
				Vector3.new(0.12, 0.12, 4),
				CFrame.lookAt(from, from + forward)
			)
			streak.Transparency = 0.3
			fadeOut(streak, 0.25, { CFrame = CFrame.lookAt(from + forward * 14, from + forward * 15) })
		end
	end
end

-- The thrown fruit: the real fruit model (FruitMesh, built on this client),
-- else a glowing stand-in ball. Ref P3 (Genshin wish meteor): the trail is a
-- meteor in the rarity colour, wider and longer the rarer the fruit, so the
-- whole server can tell a Mythical from far away.
local FLIGHT_SIZE = 2.6 -- studs across the fruit in flight

function ThrowFX.makeFruit(key: string, glow: Color3, rarityColor: Color3, rank: number?): BasePart
	local tier = rank or 1
	local part: BasePart
	local model = FruitMesh.get(key)
	local body = model and model.PrimaryPart
	if model and body then
		local e = model:GetExtentsSize()
		local widest = math.max(e.X, e.Y, e.Z)
		if widest > 0 then
			model:ScaleTo(model:GetScale() * FLIGHT_SIZE / widest)
		end
		-- keep only the body; the glow shell rides on its weld
		for _, child in model:GetChildren() do
			if child ~= body and child:IsA("BasePart") then
				child.Parent = body
			end
		end
		body.Parent = nil
		model:Destroy()
		part = body
	else
		local ball = Instance.new("Part")
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(2.4, 2.4, 2.4)
		ball.Material = Enum.Material.SmoothPlastic
		ball.Color = glow:Lerp(Color3.new(0, 0, 0), 0.25)
		local shell = Instance.new("Part")
		shell.Name = "GlowShell"
		shell.Shape = Enum.PartType.Ball
		shell.Size = Vector3.new(2.9, 2.9, 2.9)
		shell.Material = Enum.Material.Neon
		shell.Color = glow
		shell.Transparency = 0.65
		shell.CanCollide = false
		shell.CanQuery = false
		shell.CanTouch = false
		shell.Massless = true
		shell.CFrame = ball.CFrame
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = ball
		weld.Part1 = shell
		weld.Parent = shell
		shell.Parent = ball
		part = ball
	end
	part.Name = "ThrownFruit"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	-- Meteor: a wide rarity trail plus a white-hot core trail inside it.
	local width = 0.9 + 0.35 * tier
	local function trail(half: number, life: number, color: ColorSequence, alpha: NumberSequence)
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, half, 0)
		a0.Parent = part
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -half, 0)
		a1.Parent = part
		local t = Instance.new("Trail")
		t.Attachment0 = a0
		t.Attachment1 = a1
		t.Lifetime = life
		t.LightEmission = 1
		t.LightInfluence = 0
		t.FaceCamera = true
		t.WidthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.7),
			NumberSequenceKeypoint.new(1, 0),
		})
		t.Color = color
		t.Transparency = alpha
		t.Parent = part
	end
	trail(
		width,
		0.35 + 0.15 * tier,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, rarityColor:Lerp(Color3.new(1, 1, 1), 0.5)),
			ColorSequenceKeypoint.new(0.25, rarityColor),
			ColorSequenceKeypoint.new(1, rarityColor:Lerp(Color3.new(0, 0, 0), 0.3)),
		}),
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1) })
	)
	trail(width * 0.35, 0.22, ColorSequence.new(Color3.new(1, 1, 1)), NumberSequence.new(0, 1))
	local light = Instance.new("PointLight")
	light.Color = rarityColor
	light.Range = 14 + 3 * tier
	light.Brightness = 3
	light.Parent = part
	local aura = Instance.new("ParticleEmitter")
	aura.Color = ColorSequence.new(Color3.new(1, 1, 1), rarityColor)
	aura.LightEmission = 1
	aura.LightInfluence = 0
	aura.Rate = (if reduced() then 10 else 40) * tier
	aura.Lifetime = NumberRange.new(0.25, 0.6)
	aura.Speed = NumberRange.new(0.5, 2.5)
	aura.SpreadAngle = Vector2.new(180, 180)
	aura.Size = NumberSequence.new(0.35 + 0.1 * tier, 0)
	aura.Transparency = NumberSequence.new(0, 1)
	aura.Parent = part
	part.Parent = workspace
	return part
end

-- Landing splash: water ring, spray sparks, and a rarity pillar for rare finds.
-- A ring on the water made of short Neon dashes (Roblox has no torus part).
-- Grows from 0 to `radius` over `seconds`, fading out. Starts after `delay`.
local function dashRing(at: Vector3, color: Color3, radius: number, seconds: number, delay: number, thick: number)
	local dashes = if reduced() then 12 else 28
	local parts: { Part } = {}
	for i = 1, dashes do
		local d = fxPart("RippleDash", Enum.PartType.Block, color, Vector3.new(thick, 0.12, 1), CFrame.new(at))
		d.Transparency = 1
		parts[i] = d
	end
	animate(function(t: number): boolean
		local k = (t - delay) / seconds
		if k < 0 then
			return true
		end
		if k >= 1 then
			for _, d in parts do
				d:Destroy()
			end
			return false
		end
		local r = math.max(0.5, radius * easeOut(k))
		local len = 2 * math.pi * r / dashes * 0.6
		for i, d in parts do
			local a = (i - 1) / dashes * 2 * math.pi
			local pos = at + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			d.Size = Vector3.new(thick * (1 - k * 0.6), 0.12, len)
			-- dash runs along the tangent of the circle
			d.CFrame = CFrame.lookAt(pos, pos + Vector3.new(-math.sin(a), 0, math.cos(a)))
			d.Transparency = 0.15 + 0.85 * k
		end
		return true
	end)
end

-- Landing impact, bigger for rarer fruits (Config.Splash.Tiers, one row per
-- rarity rank 1..4). Rare: water column, crown of droplets, ripples, foam,
-- mist. Epic adds a rarity shockwave and light rays across the water.
-- Legendary and Mythical add a rarity light pillar with rising motes and a
-- camera shake. Masterwork turns the shockwave gold and scales it all up.
function ThrowFX.splash(at: Vector3, rarityColor: Color3, rarityRank: number, masterwork: boolean)
	local cfg = Config.Splash
	local tier = SplashShape.tier(rarityRank, cfg.Tiers, masterwork, cfg.MasterworkScale)
	local calm = reduced()
	local water = Color3.fromRGB(200, 240, 255)
	local accent = if masterwork then Color3.fromRGB(255, 214, 64) else rarityColor

	-- flash
	local anchor = fxPart("SplashLight", Enum.PartType.Ball, water, Vector3.new(0.2, 0.2, 0.2), CFrame.new(at))
	anchor.Transparency = 1
	local light = Instance.new("PointLight")
	light.Color = accent:Lerp(Color3.new(1, 1, 1), 0.4)
	light.Range = math.min(60, tier.reach)
	light.Brightness = tier.light
	light.Parent = anchor
	TweenService:Create(light, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { Brightness = 0 }):Play()
	task.delay(0.7, function()
		anchor:Destroy()
	end)

	-- water column: a spray of soft particles shot straight up under gravity,
	-- around a thin white-hot core that spikes up and collapses
	local upSpeed = math.sqrt(2 * cfg.Gravity * tier.column)
	local life = SplashShape.airTime(upSpeed, cfg.Gravity) -- until it falls back
	local sprayAnchor = fxPart("SplashSpray", Enum.PartType.Ball, water, Vector3.new(0.2, 0.2, 0.2), CFrame.new(at))
	sprayAnchor.Transparency = 1
	local function spray(spread: number, count: number, speedLo: number, sizeFrom: number, sizeTo: number)
		local e = Instance.new("ParticleEmitter")
		e.Enabled = false
		local tex = vfxTexture("Wisp") or vfxTexture("Glow")
		if tex then
			e.Texture = tex
		end
		e.Color = ColorSequence.new(Color3.new(1, 1, 1), water)
		e.LightEmission = 0
		e.LightInfluence = 1
		e.Lifetime = NumberRange.new(life * 0.8, life)
		e.Speed = NumberRange.new(upSpeed * speedLo, upSpeed)
		e.Acceleration = Vector3.new(0, -cfg.Gravity, 0)
		e.SpreadAngle = Vector2.new(spread, spread)
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-90, 90)
		e.Size = NumberSequence.new(sizeFrom, sizeTo)
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.25),
			NumberSequenceKeypoint.new(0.7, 0.45),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Parent = sprayAnchor
		e:Emit(if calm then math.ceil(count / 3) else count)
	end
	spray(5, 30 + 12 * rarityRank, 0.55, 0.8, 1.6 + tier.column / 12) -- the column
	spray(30, 18 + 8 * rarityRank, 0.3, 0.6, 1.4) -- the sheet flaring out
	task.delay(1.4, function()
		sprayAnchor:Destroy()
	end)
	local width = 0.8 + tier.column * 0.06
	local core = fxPart(
		"SplashCore",
		Enum.PartType.Cylinder,
		Color3.new(1, 1, 1),
		Vector3.new(0.1, width, width),
		CFrame.new(at)
	)
	core.Transparency = 0.1
	local upright = CFrame.Angles(0, 0, math.rad(90))
	animate(function(t: number): boolean
		local h: number, fade: number
		if t < cfg.ColumnRise then
			h = tier.column * 0.8 * easeOut(t / cfg.ColumnRise)
			fade = 0
		else
			local k = (t - cfg.ColumnRise) / cfg.ColumnFall
			if k >= 1 then
				core:Destroy()
				return false
			end
			h = tier.column * 0.8 * (1 - k * k)
			fade = k
		end
		h = math.max(h, 0.1)
		core.Size = Vector3.new(h, width * (1 - fade * 0.7), width * (1 - fade * 0.7))
		core.CFrame = CFrame.new(at + Vector3.new(0, h / 2, 0)) * upright
		core.Transparency = 0.1 + 0.9 * fade
		return true
	end)

	-- crown of droplets on ballistic arcs
	local n = if calm then math.ceil(tier.crown / 3) else tier.crown
	for i = 1, n do
		local vx, vy, vz = SplashShape.crownVelocity(i, n, tier.column, cfg.Gravity, cfg.CrownUp, cfg.CrownOut)
		local size = if i % 2 == 0 then 1.4 else 1
		local drop = fxPart(
			"Droplet",
			Enum.PartType.Ball,
			if i % 3 == 0 then Color3.new(1, 1, 1) else water,
			Vector3.one * size,
			CFrame.new(at)
		)
		drop.Material = if i % 3 == 0 then Enum.Material.Neon else Enum.Material.Glass
		drop.Transparency = 0.1
		local airTime = SplashShape.airTime(vy, cfg.Gravity)
		animate(function(t: number): boolean
			if t >= airTime then
				drop:Destroy()
				return false
			end
			local x, y, z = SplashShape.ballistic(t, vx, vy, vz, cfg.Gravity)
			drop.CFrame = CFrame.new(at + Vector3.new(x, y, z))
			-- droplets stretch along their fall
			local stretch = 1 + math.abs(vy - cfg.Gravity * t) / 40
			drop.Size = Vector3.new(size, size * stretch, size)
			return true
		end)
	end

	-- foam disc and ripples
	local foam =
		fxPart("Foam", Enum.PartType.Cylinder, Color3.new(1, 1, 1), Vector3.new(0.15, 2, 2), CFrame.new(at) * upright)
	foam.Material = Enum.Material.SmoothPlastic
	foam.Transparency = 0.25
	fadeOut(foam, 1.1, { Size = Vector3.new(0.15, tier.reach * 0.45, tier.reach * 0.45) })
	for k = 1, tier.ripples do
		dashRing(at, water, tier.reach * k / tier.ripples, cfg.RippleSeconds, (k - 1) * cfg.RippleGap, 0.5)
	end
	sparks(at + Vector3.new(0, 1, 0), water, 20 + 6 * tier.ripples, 10 + tier.column)

	-- Epic and up: rarity shockwave + light rays across the water
	if tier.rays > 0 then
		dashRing(at + Vector3.new(0, 0.1, 0), accent, tier.reach * 1.1, 0.45, 0, 1.2)
		if not calm then
			for i = 1, tier.rays do
				local a = (i - 1) / tier.rays * 2 * math.pi + math.random() * 0.2
				local dir = Vector3.new(math.cos(a), 0, math.sin(a))
				local ray = fxPart("ImpactRay", Enum.PartType.Block, accent, Vector3.new(0.35, 0.1, 1), CFrame.new(at))
				ray.Transparency = 0.1
				local length = tier.reach * (0.6 + math.random() * 0.3)
				animate(function(t: number): boolean
					local k = t / 0.5
					if k >= 1 then
						ray:Destroy()
						return false
					end
					local len = length * easeOut(k)
					local mid = at + dir * (len / 2 + 1) + Vector3.new(0, 0.15, 0)
					ray.Size = Vector3.new(0.35 * (1 - k), 0.1, math.max(len, 0.1))
					ray.CFrame = CFrame.lookAt(mid, mid + dir)
					ray.Transparency = 0.1 + 0.9 * k
					return true
				end)
			end
		end
	end

	-- Legendary and up: a rarity light pillar with motes rising inside it
	if tier.pillar > 0 then
		local thick = 3 + tier.column * 0.12
		local pillar = fxPart(
			"RarityPillar",
			Enum.PartType.Cylinder,
			accent,
			Vector3.new(0.1, thick, thick),
			CFrame.new(at) * upright
		)
		pillar.Transparency = 0.3
		local inner = fxPart(
			"PillarCore",
			Enum.PartType.Cylinder,
			Color3.new(1, 1, 1),
			Vector3.new(0.1, thick * 0.35, thick * 0.35),
			CFrame.new(at) * upright
		)
		inner.Transparency = 0.1
		local motes = Instance.new("ParticleEmitter")
		motes.Color = ColorSequence.new(Color3.new(1, 1, 1), accent)
		motes.LightEmission = 1
		motes.LightInfluence = 0
		motes.Rate = if calm then 15 else 60
		motes.Lifetime = NumberRange.new(0.8, 1.4)
		motes.Speed = NumberRange.new(25, 45)
		motes.SpreadAngle = Vector2.new(8, 8)
		motes.Acceleration = Vector3.zero
		motes.Size = NumberSequence.new(0.6, 0)
		motes.Transparency = NumberSequence.new(0, 1)
		motes.EmissionDirection = Enum.NormalId.Right -- the cylinder's X axis points up
		motes.Parent = inner
		local rise, hold, shrink = 0.25, 0.6, 0.7
		animate(function(t: number): boolean
			local h: number, w: number, fade: number
			if t < rise then
				h, w, fade = tier.pillar * easeOut(t / rise), 1, 0
			elseif t < rise + hold then
				h, w, fade = tier.pillar, 1 + 0.08 * math.sin((t - rise) * 25), 0
			else
				local k = (t - rise - hold) / shrink
				if k >= 1 then
					pillar:Destroy()
					inner:Destroy()
					return false
				end
				h, w, fade = tier.pillar, 1 - k, k
				motes.Enabled = false
			end
			h = math.max(h, 0.1)
			local mid = CFrame.new(at + Vector3.new(0, h / 2, 0)) * upright
			pillar.Size = Vector3.new(h, thick * w, thick * w)
			pillar.CFrame = mid
			pillar.Transparency = 0.3 + 0.7 * fade
			inner.Size = Vector3.new(h, thick * 0.35 * w, thick * 0.35 * w)
			inner.CFrame = mid
			inner.Transparency = 0.1 + 0.9 * fade
			return true
		end)
		sparks(at + Vector3.new(0, 3, 0), accent, 30 + 10 * rarityRank, 40)
	end

	if tier.shake > 0 then
		Juice.shakeCamera(tier.shake)
	end
end

return ThrowFX
