--!strict
-- Procedural full-body throw (client, cosmetic). Drives twelve R15 joints from
-- the pure ThrowPose curves, plus the throw VFX that live on the character:
--   charge(fill): the body winds into the "set" pose as the meter climbs, a
--     glowing fruit grows in the hand and a wind aura swirls round the feet.
--   swing(): stride -> whip (release) -> follow-through hold -> settle, with
--     a ribbon trail off the hand, a dust kick at the foot plant, an energy pop
--     and a field-of-view punch at release.
-- Rigs here use AnimationConstraint joints (the avatar joint upgrade), whose
-- C0 is a read-only alias, so we layer onto Transform during
-- RunService.PreSimulation, after the Animator writes it - the documented way
-- for both AnimationConstraint and Motor6D:
-- https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint
-- Transform edits made on the client do not replicate, so other players see
-- the default pose: a replicated AnimationTrack version is a follow-up.
--
-- Studio only: set workspace attribute ThrowPreviewT (number) from a client
-- to scrub the swing for screenshots (0..total seconds into the swing, or a
-- negative value -fill for the charge pose). The pose eases toward the target
-- at ThrowPreviewRate swing-seconds per second (default 0.1) so the hand trail
-- records a smooth arc. Remove the attribute to stop.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ThrowPose = require(Shared:WaitForChild("ThrowPose"))

type Pose = ThrowPose.Pose

local ThrowAnimator = {}

local ORANGE = Color3.fromRGB(255, 150, 40)
local HOT = Color3.fromRGB(255, 236, 190)
-- Built-in particle textures that ship with the engine (content/textures/particles).
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

-- R15 joint names per pose slot. R6 joints have rotated C0s, so the curves
-- would point limbs the wrong way: an R6 rig just gets no joints (and the
-- throw still releases instantly, see swing()).
local JOINT_NAMES: { [string]: string } = {
	root = "Root",
	waist = "Waist",
	neck = "Neck",
	rightShoulder = "RightShoulder",
	rightElbow = "RightElbow",
	rightWrist = "RightWrist",
	leftShoulder = "LeftShoulder",
	leftElbow = "LeftElbow",
	leftHip = "LeftHip",
	leftKnee = "LeftKnee",
	rightHip = "RightHip",
	rightKnee = "RightKnee",
}

type Rig = { [string]: Instance } -- Motor6D or AnimationConstraint

local function findRig(character: Model?): Rig
	local out: Rig = {}
	if not character then
		return out
	end
	for slot, name in JOINT_NAMES do
		local found = character:FindFirstChild(name, true)
		if found and (found:IsA("Motor6D") or found:IsA("AnimationConstraint")) then
			out[slot] = found
		end
	end
	return out
end

local function animatorOf(character: Model?): Animator?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid:FindFirstChildOfClass("Animator")
end

local function part(character: Model?, name: string): BasePart?
	local p = character and character:FindFirstChild(name)
	return if p and p:IsA("BasePart") then p else nil
end

-- Character VFX ---------------------------------------------------------------

type Fx = {
	character: Model,
	orb: Part?,
	orbEmitter: ParticleEmitter?,
	orbLight: PointLight?,
	trail: Trail?,
	aura: ParticleEmitter?,
	folder: Folder,
}

local fx: Fx? = nil

local function emitter(props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.LightInfluence = 0
	for k, v in props do
		(e :: any)[k] = v -- property bag; keys are checked by the engine at runtime
	end
	return e
end

local function clearFx()
	local f = fx
	if f then
		f.folder:Destroy()
		fx = nil
	end
end

local function fxFor(character: Model): Fx?
	local f = fx
	if f and f.character == character and f.folder.Parent then
		return f
	end
	clearFx()
	local hand = part(character, "RightHand")
	local root = part(character, "HumanoidRootPart")
	if not hand or not root then
		return nil
	end
	local folder = Instance.new("Folder")
	folder.Name = "ThrowFX"
	folder.Parent = character
	local made: Fx = { character = character, folder = folder }

	-- Glowing fruit held in the palm: a hot core inside an orange shell.
	local grip = hand:FindFirstChild("RightGripAttachment")
	local orb = Instance.new("Part")
	orb.Name = "HeldOrb"
	orb.Shape = Enum.PartType.Ball
	orb.Material = Enum.Material.Neon
	orb.Color = ORANGE
	orb.Transparency = 0.35
	orb.CanCollide = false
	orb.CanTouch = false
	orb.CanQuery = false
	orb.CastShadow = false
	orb.Massless = true
	orb.Size = Vector3.one * 0.1
	local weld = Instance.new("Weld")
	weld.Part0 = hand
	weld.Part1 = orb
	weld.C0 = (if grip and grip:IsA("Attachment") then grip.CFrame else CFrame.new(0, -0.6, 0))
		* CFrame.new(0, -0.15, 0)
	weld.Parent = orb
	local core = orb:Clone()
	core.Name = "Core"
	core.Color = HOT
	core.Transparency = 0
	local coreWeld = core:FindFirstChildOfClass("Weld")
	if coreWeld then
		coreWeld.Part1 = core
	end
	core.Parent = orb
	orb.Parent = folder
	made.orb = orb
	local light = Instance.new("PointLight")
	made.orbLight = light
	light.Color = ORANGE
	light.Range = 8
	light.Brightness = 0
	light.Parent = orb
	local sparkles = emitter({
		Texture = SPARKLE,
		Color = ColorSequence.new(HOT, ORANGE),
		LightEmission = 1,
		Lifetime = NumberRange.new(0.3, 0.6),
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(180, 180),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new(0.1, 1),
		RotSpeed = NumberRange.new(-200, 200),
		Rate = 0,
	})
	sparkles.Parent = orb
	made.orbEmitter = sparkles

	-- Ribbon trail off the hand: the attachments span the forearm axis so
	-- the overhand arc sweeps a sheet, the way a slash trail reads.
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailTop"
	a0.Position = Vector3.new(0, 0.35, 0)
	a0.Parent = hand
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailTip"
	a1.Position = Vector3.new(0, -1.1, 0)
	a1.Parent = hand
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, HOT),
		ColorSequenceKeypoint.new(0.4, ORANGE),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 70, 20)),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.6, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.MinLength = 0.05
	trail.Lifetime = Config.UI.TrailSeconds
	trail.Enabled = false
	trail.Parent = folder
	made.trail = trail
	-- tidy the hand attachments with the rest
	folder.Destroying:Connect(function()
		a0:Destroy()
		a1:Destroy()
	end)

	-- Wind aura swirling up round the feet while charging.
	local feet = Instance.new("Attachment")
	feet.Name = "AuraFeet"
	feet.Position = Vector3.new(0, -2.9, 0)
	feet.Parent = root
	folder.Destroying:Connect(function()
		feet:Destroy()
	end)
	local aura = emitter({
		Texture = SMOKE,
		Color = ColorSequence.new(HOT, ORANGE),
		LightEmission = 0.6,
		Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(4, 9),
		SpreadAngle = Vector2.new(70, 70),
		Acceleration = Vector3.new(0, 6, 0),
		Drag = 3,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1.8) }),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		}),
		RotSpeed = NumberRange.new(-90, 90),
		Rate = 0,
	})
	aura.Parent = feet
	made.aura = aura

	fx = made
	return made
end

-- One-shot burst at a world position (dust kick, energy pop).
local function burst(at: Vector3, color: Color3, texture: string, count: number, speed: number, size: number)
	if GuiService.ReducedMotionEnabled then
		count = math.ceil(count / 4)
	end
	local anchor = Instance.new("Attachment")
	anchor.WorldPosition = at
	anchor.Parent = workspace.Terrain
	local e = emitter({
		Texture = texture,
		Color = ColorSequence.new(color),
		LightEmission = if texture == SPARKLE then 1 else 0.2,
		Lifetime = NumberRange.new(0.35, 0.7),
		Speed = NumberRange.new(speed * 0.5, speed),
		SpreadAngle = Vector2.new(180, 30),
		Drag = 4,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 2.2) }),
		Transparency = NumberSequence.new(0.2, 1),
		Enabled = false,
	})
	e.Parent = anchor
	e:Emit(count)
	task.delay(1, function()
		anchor:Destroy()
	end)
end

local function fovKick()
	local cam = workspace.CurrentCamera
	if not cam or GuiService.ReducedMotionEnabled then
		return
	end
	local base = cam.FieldOfView
	local kick = TweenService:Create(cam, TweenInfo.new(0.05, Enum.EasingStyle.Quad), {
		FieldOfView = base + Config.UI.ReleaseFovKick,
	})
	kick.Completed:Once(function()
		TweenService:Create(cam, TweenInfo.new(0.4, Enum.EasingStyle.Back), { FieldOfView = base }):Play()
	end)
	kick:Play()
end

-- Drive the character VFX for this frame. `fill` 0..1 is the charge, `t` the
-- swing time (nil while charging), `prevT` last frame's swing time.
local function driveFx(character: Model, fill: number, t: number?, prevT: number?, trailLife: number, live: boolean)
	local f = fxFor(character)
	if not f then
		return
	end
	local cfg = Config.Throw
	local releaseAt = ThrowPose.releaseTime(cfg)
	local holding = t == nil or t < releaseAt
	local orb, light, sparkles = f.orb, f.orbLight, f.orbEmitter
	if orb and light and sparkles then
		local s = if holding then Config.UI.HeldOrbSize * (0.45 + 0.55 * fill) else 0.05
		orb.Size = Vector3.one * s
		local core = orb:FindFirstChild("Core")
		if core and core:IsA("BasePart") then
			core.Size = Vector3.one * s * 0.55
			core.Transparency = if holding then 0 else 1
		end
		orb.Transparency = if holding then 0.35 else 1
		light.Brightness = if holding then 1 + 3 * fill else 0
		sparkles.Rate = if holding then 8 + 40 * fill else 0
	end
	local aura = f.aura
	if aura then
		aura.Rate = if t == nil and not GuiService.ReducedMotionEnabled then Config.UI.ChargeAuraRate * fill else 0
	end
	local trail = f.trail
	if trail then
		trail.Lifetime = trailLife
		trail.Enabled = t ~= nil and t < cfg.SwingWindup + cfg.SwingFollow * 0.6
	end
	if t and prevT then
		-- foot plant: dust kicks out from the front foot
		if prevT < cfg.SwingWindup and t >= cfg.SwingWindup then
			local foot = part(character, "LeftFoot")
			if foot then
				burst(foot.Position - Vector3.new(0, 0.3, 0), Color3.fromRGB(205, 190, 160), SMOKE, 14, 9, 0.8)
			end
		end
		-- release: the held energy pops
		if prevT < releaseAt and t >= releaseAt then
			local hand = part(character, "RightHand")
			if hand then
				burst(hand.Position, HOT, SPARKLE, 26, 16, 0.5)
			end
			if live then
				fovKick()
			end
		end
	end
end

-- Pose state ------------------------------------------------------------------

local active: { character: Model, rig: Rig, pose: Pose }? = nil
-- How much the throw pose overrides the playing animation (0..1).
local weight = 0
local BLEND_IN_SECONDS = 0.18
local swingStart: number? = nil
local swingKeys: { ThrowPose.Key }? = nil
local lastFill = 0
local lastCharge: Pose = ThrowPose.REST
local prevSwingT: number? = nil
-- Studio preview scrub
local previewT: number? = nil

-- What we wrote to each joint last frame, and the animated base under it.
-- Studio check (2026-11-20): on these rigs the Animator does not rewrite
-- every joint's Transform every frame (joints no playing track keys keep the
-- last value), so blindly multiplying compounds the offset frame after frame.
-- If Transform still holds what we wrote, the base is the one we saved.
local layered: { [Instance]: { written: CFrame, base: CFrame } } = {}

local function unlayer()
	for joint, st in layered do
		if joint:IsA("AnimationConstraint") then
			if joint.Transform:FuzzyEq(st.written, 1e-4) then
				joint.Transform = st.base
			end
		elseif joint:IsA("Motor6D") then
			if joint.Transform:FuzzyEq(st.written, 1e-4) then
				joint.Transform = st.base
			end
		end
	end
	table.clear(layered)
end

local function setActive(a: { character: Model, rig: Rig, pose: Pose }?)
	if a == nil or (active and active.character ~= a.character) then
		unlayer()
		weight = 0
	end
	active = a
end

local function hold(character: Model?, pose: Pose)
	if not character then
		setActive(nil)
		return
	end
	local a = active
	if a and a.character == character then
		a.pose = pose
	else
		setActive({ character = character, rig = findRig(character), pose = pose })
	end
end

-- The throw overrides the playing animation (avatar idles can be heavily
-- posed: a hunched idle measured Waist -0.59 rad, LeftHip 1.08 rad), blended
-- by `weight` 0..1 so it eases in and back out to the idle.
local function layer(joint: Instance, rot: CFrame, weight: number)
	local st = layered[joint]
	local function base(cur: CFrame): CFrame
		return if st and cur:FuzzyEq(st.written, 1e-4) then st.base else cur
	end
	if joint:IsA("AnimationConstraint") then
		local b = base(joint.Transform)
		joint.Transform = b:Lerp(rot, weight)
		layered[joint] = { written = joint.Transform, base = b }
	elseif joint:IsA("Motor6D") then
		local b = base(joint.Transform)
		joint.Transform = b:Lerp(rot, weight)
		layered[joint] = { written = joint.Transform, base = b }
	end
end

local function applyPose(a: { character: Model, rig: Rig, pose: Pose }, w: number)
	local animator = animatorOf(a.character)
	-- Skip throttled frames as the docs advise.
	if animator and animator.EvaluationThrottled then
		return
	end
	for slot, joint in a.rig do
		local e = a.pose[slot]
		if e then
			layer(joint, CFrame.new(0, e[4] or 0, 0) * CFrame.Angles(e[1], e[2], e[3]), w)
		end
	end
end

-- Fade back to the playing animation over the settle at the end of the swing.
local function settleWeight(t: number): number
	local cfg = Config.Throw
	local from = cfg.SwingWindup + cfg.SwingFollow
	return 1 - math.clamp((t - from) / ThrowPose.SETTLE_SECONDS, 0, 1)
end

local function preview(dt: number): boolean
	if not RunService:IsStudio() then
		return false
	end
	local target = workspace:GetAttribute("ThrowPreviewT")
	local character = Players.LocalPlayer and Players.LocalPlayer.Character
	if type(target) ~= "number" or not character then
		if previewT then
			previewT = nil
			setActive(nil)
			clearFx()
		end
		return false
	end
	local rate = workspace:GetAttribute("ThrowPreviewRate")
	local speed = if type(rate) == "number" and rate > 0 then rate else 0.1
	local cfg = Config.Throw
	local full = ThrowPose.charge(1, Config.UI)
	local before = previewT
	local now = before or target
	if target < 0 then
		now = target
	elseif now < 0 then
		now = 0
	else
		local step = speed * dt
		now = if math.abs(target - now) <= step then target else now + math.sign(target - now) * step
	end
	previewT = now
	local pose = if now < 0 then ThrowPose.charge(-now, Config.UI) else ThrowPose.sample(ThrowPose.keys(cfg, full), now)
	hold(character, pose)
	local a = active
	if a then
		weight = math.min(1, weight + dt / BLEND_IN_SECONDS)
		applyPose(a, weight * settleWeight(math.max(now, 0)))
	end
	driveFx(
		character,
		if now < 0 then -now else 1,
		if now < 0 then nil else now,
		if before and before >= 0 then before else nil,
		Config.UI.TrailSeconds / speed,
		false
	)
	return true
end

RunService.PreSimulation:Connect(function(dt: number)
	if preview(dt) then
		return
	end
	local a = active
	if not a then
		return
	end
	local keys = swingKeys
	local started = swingStart
	local t: number? = nil
	if keys and started then
		t = os.clock() - started
		a.pose = ThrowPose.sample(keys, t :: number)
	end
	weight = math.min(1, weight + dt / BLEND_IN_SECONDS)
	applyPose(a, weight * settleWeight(t or 0))
	driveFx(a.character, lastFill, t, prevSwingT, Config.UI.TrailSeconds, true)
	prevSwingT = t
end)

-- Hold the anticipation pose for a meter fill of 0..1.
function ThrowAnimator.charge(character: Model?, fill: number)
	if swingStart then
		return
	end
	lastFill = math.clamp(fill, 0, 1)
	lastCharge = if GuiService.ReducedMotionEnabled then ThrowPose.REST else ThrowPose.charge(fill, Config.UI)
	hold(character, lastCharge)
end

-- Back to the plain animation (leaving the throw spot, respawn).
function ThrowAnimator.reset(_character: Model?)
	lastCharge = ThrowPose.REST
	lastFill = 0
	swingStart = nil
	swingKeys = nil
	prevSwingT = nil
	setActive(nil)
	clearFx()
end

local function handPosition(character: Model?): Vector3
	local hand = part(character, "RightHand") or part(character, "Right Arm")
	if hand then
		return hand.Position
	end
	local root = part(character, "HumanoidRootPart")
	if root then
		return root.Position + Vector3.new(0, 1.5, 0)
	end
	return Vector3.new(0, 10, 0)
end

-- Same contract as ThrowFX.swing: `onRelease(handPosition)` fires once on the
-- release frame; returns the total length in seconds.
function ThrowAnimator.swing(character: Model?, onRelease: (Vector3) -> ()): number
	local cfg = Config.Throw
	local total = ThrowPose.totalTime(cfg)
	local releaseAt = ThrowPose.releaseTime(cfg)
	local rig = findRig(character)
	if GuiService.ReducedMotionEnabled or next(rig) == nil then
		-- No animation: release straight away so the throw never stalls.
		clearFx()
		task.defer(onRelease, handPosition(character))
		return 0
	end
	swingKeys = ThrowPose.keys(cfg, lastCharge)
	local start = os.clock()
	swingStart = start
	prevSwingT = 0
	hold(character, lastCharge)
	task.delay(releaseAt, function()
		onRelease(handPosition(character))
	end)
	task.delay(total, function()
		if swingStart == start then
			swingStart = nil
			swingKeys = nil
			prevSwingT = nil
			lastCharge = ThrowPose.REST
			lastFill = 0
			setActive(nil)
			clearFx()
		end
	end)
	return total
end

return ThrowAnimator
