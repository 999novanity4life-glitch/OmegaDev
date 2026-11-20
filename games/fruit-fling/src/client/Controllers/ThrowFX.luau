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

-- The release burst: white starburst (TFFA) + rarity shockwave ring + sparks.
function ThrowFX.releaseBurst(at: Vector3, rarityColor: Color3, forward: Vector3, power: number)
	local big = 0.6 + power -- power in 0..1
	local star = fxPart("Starburst", Enum.PartType.Ball, Color3.new(1, 1, 1), Vector3.new(1, 1, 1), CFrame.new(at))
	local light = Instance.new("PointLight")
	light.Color = Color3.new(1, 1, 1)
	light.Brightness = 6
	light.Range = 14
	light.Parent = star
	fadeOut(star, 0.22, { Size = Vector3.new(5, 5, 5) * big })
	-- shockwave: a flat cylinder facing along the throw (cylinder axis = X)
	local ring = fxPart(
		"Shockwave",
		Enum.PartType.Cylinder,
		rarityColor,
		Vector3.new(0.15, 1.5, 1.5),
		CFrame.lookAt(at, at + forward) * CFrame.Angles(0, math.rad(90), 0)
	)
	ring.Transparency = 0.2
	fadeOut(ring, 0.35, { Size = Vector3.new(0.05, 11, 11) * big })
	sparks(at, rarityColor, math.floor(24 * big), 30)
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

-- The thrown fruit: a clone of ReplicatedStorage.FruitModels/<key> when it
-- exists (Studio import of assets/fruits), else a glowing stand-in ball.
-- Always gets a rarity trail, a glow light and a white core streak (TFFA).
function ThrowFX.makeFruit(key: string, glow: Color3, rarityColor: Color3): BasePart
	local models = ReplicatedStorage:FindFirstChild("FruitModels")
	local template = models and models:FindFirstChild(key)
	local part: BasePart
	-- Only meshes with an uploaded MeshId: a MeshPart built from an
	-- EditableMesh in Studio does not replicate its geometry to clients.
	if template and template:IsA("MeshPart") and template.MeshId ~= "" then
		part = template:Clone()
		-- child parts (the glow shell) ride along on welds; the body is moved
		-- by CFrame each frame
		for _, child in part:GetDescendants() do
			if child:IsA("BasePart") then
				child.Anchored = false
				child.CanCollide = false
				child.CanQuery = false
				child.CanTouch = false
				child.Massless = true
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = part
				weld.Part1 = child
				weld.Parent = child
			end
		end
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
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.9, 0)
	a0.Parent = part
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.9, 0)
	a1.Parent = part
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.45
	trail.LightEmission = 1
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Color = ColorSequence.new(Color3.new(1, 1, 1), rarityColor)
	trail.Transparency = NumberSequence.new(0, 1)
	trail.Parent = part
	local light = Instance.new("PointLight")
	light.Color = glow
	light.Range = 14
	light.Brightness = 2.5
	light.Parent = part
	local aura = Instance.new("ParticleEmitter")
	aura.Color = ColorSequence.new(rarityColor)
	aura.LightEmission = 1
	aura.Rate = if reduced() then 10 else 40
	aura.Lifetime = NumberRange.new(0.2, 0.4)
	aura.Speed = NumberRange.new(0, 1)
	aura.Size = NumberSequence.new(0.5, 0)
	aura.Transparency = NumberSequence.new(0.2, 1)
	aura.Parent = part
	part.Parent = workspace
	return part
end

-- Landing splash: water ring, spray sparks, and a rarity pillar for rare finds.
function ThrowFX.splash(at: Vector3, rarityColor: Color3, rarityRank: number, masterwork: boolean)
	local ring = fxPart(
		"Splash",
		Enum.PartType.Cylinder,
		if masterwork then Color3.fromRGB(255, 214, 64) else Color3.fromRGB(210, 245, 255),
		Vector3.new(0.4, 2, 2),
		CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	)
	local grow = if masterwork then 42 else 24
	fadeOut(ring, 0.7, { Size = Vector3.new(0.4, grow, grow) })
	sparks(at + Vector3.new(0, 1, 0), Color3.fromRGB(220, 250, 255), 30, 24)
	if rarityRank >= 3 then
		-- Legendary and Mythical: a light pillar in the rarity colour
		local pillar = fxPart(
			"RarityPillar",
			Enum.PartType.Cylinder,
			rarityColor,
			Vector3.new(60, 3, 3),
			CFrame.new(at + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90))
		)
		pillar.Transparency = 0.35
		fadeOut(pillar, 1.6, { Size = Vector3.new(60, 0.2, 0.2) })
		sparks(at + Vector3.new(0, 3, 0), rarityColor, 40, 40)
	end
end

return ThrowFX
