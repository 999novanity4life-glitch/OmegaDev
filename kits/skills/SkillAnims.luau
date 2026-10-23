-- SkillAnims: builds R15 KeyframeSequences in code (poses + markers).
-- In Studio, KeyframeSequenceProvider:RegisterKeyframeSequence gives a temporary id for testing.
-- For a published game: open each sequence in the Animation Editor, Publish to Roblox under the
-- game's owner (user or group), and put the asset ids in ANIM_IDS so they load for everyone.
-- Lives at ReplicatedStorage.Skills.SkillAnims.
local SkillAnims = {}

SkillAnims.ANIM_IDS = {
	-- Bolt = "rbxassetid://000", Slam = "rbxassetid://000", Dash = "rbxassetid://000",
}

-- Sign convention (checked on a rig 2026-10-23): +X pitch on UpperTorso/Head leans BACK;
-- +X on an UpperArm/UpperLeg swings it FORWARD/UP; -X on a LowerLeg bends the knee.
local rad = math.rad
local function A(x, y, z) return CFrame.Angles(rad(x or 0), rad(y or 0), rad(z or 0)) end

local function pose(name: string, cf: CFrame?, parent: Instance)
	local p = Instance.new("Pose")
	p.Name = name
	p.CFrame = cf or CFrame.identity
	p.EasingStyle = Enum.PoseEasingStyle.Cubic
	p.EasingDirection = Enum.PoseEasingDirection.Out
	p.Weight = 1
	p.Parent = parent
	return p
end

-- f = { t = time, LowerTorso = cf, UpperTorso = cf, ... } ; markers = { { t = time, name = "Hit" } }
local function build(frames, markers)
	local ks = Instance.new("KeyframeSequence")
	ks.Loop = false
	ks.Priority = Enum.AnimationPriority.Action
	for _, f in frames do
		local kf = Instance.new("Keyframe")
		kf.Time = f.t
		local root = pose("HumanoidRootPart", nil, kf)
		root.Weight = 0
		local lt = pose("LowerTorso", f.LowerTorso, root)
		local ut = pose("UpperTorso", f.UpperTorso, lt)
		pose("Head", f.Head, ut)
		local rua = pose("RightUpperArm", f.RightUpperArm, ut)
		pose("RightLowerArm", f.RightLowerArm, rua)
		local lua_ = pose("LeftUpperArm", f.LeftUpperArm, ut)
		pose("LeftLowerArm", f.LeftLowerArm, lua_)
		local rul = pose("RightUpperLeg", f.RightUpperLeg, lt)
		pose("RightLowerLeg", f.RightLowerLeg, rul)
		local lul = pose("LeftUpperLeg", f.LeftUpperLeg, lt)
		pose("LeftLowerLeg", f.LeftLowerLeg, lul)
		for _, m in markers or {} do
			if math.abs(m.t - f.t) < 1e-3 then
				local km = Instance.new("KeyframeMarker")
				km.Name = m.name
				km.Value = m.value or ""
				km.Parent = kf
			end
		end
		kf.Parent = ks
	end
	return ks
end

local N = {} -- neutral pose
function SkillAnims.sequences()
	return {
		-- Projectile cast: wind back, thrust forward on "Fire".
		Bolt = build({
			{ t = 0 },
			{ t = 0.16, UpperTorso = A(0, 35, 0), RightUpperArm = A(-40, 0, 30), RightLowerArm = A(60, 0, 0), LeftUpperArm = A(30, 0, -20) },
			{ t = 0.3, UpperTorso = A(-5, -25, 0), RightUpperArm = A(95, 0, 10), RightLowerArm = A(5, 0, 0), LeftUpperArm = A(-20, 0, -15),
				RightUpperLeg = A(-20, 0, 0), LeftUpperLeg = A(15, 0, 0) },
			{ t = 0.6 },
		}, { { t = 0.3, name = "Fire" } }),

		-- Ground slam: hop up, arms overhead, smash down on "Hit".
		Slam = build({
			{ t = 0 },
			{ t = 0.22, LowerTorso = CFrame.new(0, 0.6, 0), UpperTorso = A(-15, 0, 0), RightUpperArm = A(165, 0, 15), LeftUpperArm = A(165, 0, -15),
				RightLowerArm = A(20, 0, 0), LeftLowerArm = A(20, 0, 0), RightUpperLeg = A(30, 0, 0), RightLowerLeg = A(-50, 0, 0), LeftUpperLeg = A(30, 0, 0), LeftLowerLeg = A(-50, 0, 0) },
			{ t = 0.42, LowerTorso = CFrame.new(0, -1.1, 0), UpperTorso = A(-35, 0, 0), Head = A(20, 0, 0), RightUpperArm = A(25, 0, 20), LeftUpperArm = A(25, 0, -20),
				RightUpperLeg = A(70, 0, 0), RightLowerLeg = A(-95, 0, 0), LeftUpperLeg = A(70, 0, 0), LeftLowerLeg = A(-95, 0, 0) },
			{ t = 0.62, LowerTorso = CFrame.new(0, -0.9, 0), UpperTorso = A(-30, 0, 0), Head = A(15, 0, 0), RightUpperArm = A(20, 0, 20), LeftUpperArm = A(20, 0, -20),
				RightUpperLeg = A(60, 0, 0), RightLowerLeg = A(-80, 0, 0), LeftUpperLeg = A(60, 0, 0), LeftLowerLeg = A(-80, 0, 0) },
			{ t = 0.95 },
		}, { { t = 0.42, name = "Hit" } }),

		-- Dash: hard forward lean, arms swept back.
		Dash = build({
			{ t = 0 },
			{ t = 0.06, LowerTorso = CFrame.new(0, -0.3, 0), UpperTorso = A(-40, 0, 0), Head = A(25, 0, 0), RightUpperArm = A(-55, 0, 15), LeftUpperArm = A(-55, 0, -15),
				RightUpperLeg = A(-35, 0, 0), LeftUpperLeg = A(45, 0, 0), LeftLowerLeg = A(-60, 0, 0) },
			{ t = 0.28, LowerTorso = CFrame.new(0, -0.3, 0), UpperTorso = A(-40, 0, 0), Head = A(25, 0, 0), RightUpperArm = A(-55, 0, 15), LeftUpperArm = A(-55, 0, -15),
				RightUpperLeg = A(-35, 0, 0), LeftUpperLeg = A(45, 0, 0), LeftLowerLeg = A(-60, 0, 0) },
			{ t = 0.45 },
		}, { { t = 0.06, name = "Go" } }),
	}
end

-- Loads tracks on an Animator. Uses published ids when present, else temporary Studio ids.
function SkillAnims.load(animator: Animator): { [string]: AnimationTrack }
	local tracks = {}
	local KSP = game:GetService("KeyframeSequenceProvider")
	for name, ks in SkillAnims.sequences() do
		local id = SkillAnims.ANIM_IDS[name]
		if not id then
			local ok, res = pcall(function() return KSP:RegisterKeyframeSequence(ks) end)
			id = ok and res or nil
		end
		if id then
			local anim = Instance.new("Animation")
			anim.AnimationId = id
			local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
			if ok and track then
				track.Priority = Enum.AnimationPriority.Action
				tracks[name] = track
			end
		end
	end
	return tracks
end

return SkillAnims
