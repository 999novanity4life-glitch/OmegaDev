--!strict
-- Procedural throw animation (client, cosmetic). Drives four rig joints from
-- the pure ThrowPose curves:
--   charge(fill) while the meter runs: the arm swings back as the marker climbs,
--   swing(): wind-up -> whip (release) -> follow-through hold -> settle.
-- Rigs here use AnimationConstraint joints (the avatar joint upgrade), whose
-- C0 is a read-only alias, so we layer onto Transform during
-- RunService.PreSimulation, after the Animator writes it - the documented way
-- for both AnimationConstraint and Motor6D:
-- https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint
-- Transform edits made on the client do not replicate, so other players see
-- the default pose: a replicated AnimationTrack version is a follow-up.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ThrowPose = require(Shared:WaitForChild("ThrowPose"))

type Pose = ThrowPose.Pose

local ThrowAnimator = {}

-- Joint names per pose slot: R15 first, then the R6 fallback.
local JOINT_NAMES: { [string]: { string } } = {
	waist = { "Waist" },
	rightShoulder = { "RightShoulder", "Right Shoulder" },
	rightElbow = { "RightElbow" },
	leftShoulder = { "LeftShoulder", "Left Shoulder" },
}

type Rig = { [string]: Instance } -- Motor6D or AnimationConstraint

local function findRig(character: Model?): Rig
	local out: Rig = {}
	if not character then
		return out
	end
	for slot, names in JOINT_NAMES do
		for _, name in names do
			local found = character:FindFirstChild(name, true)
			if found and (found:IsA("Motor6D") or found:IsA("AnimationConstraint")) then
				out[slot] = found
				break
			end
		end
	end
	return out
end

local function animatorOf(character: Model?): Animator?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid:FindFirstChildOfClass("Animator")
end

-- What PreSimulation layers on, if anything.
local active: { character: Model, rig: Rig, pose: Pose }? = nil
local swingStart: number? = nil
local swingKeys: { ThrowPose.Key }? = nil
local lastCharge: Pose = ThrowPose.REST

RunService.PreSimulation:Connect(function()
	local a = active
	if not a then
		return
	end
	local keys = swingKeys
	local started = swingStart
	if keys and started then
		a.pose = ThrowPose.sample(keys, os.clock() - started)
	end
	local animator = animatorOf(a.character)
	-- Skip throttled frames as the docs advise (the Animator didn't write
	-- Transform, so layering again would compound the offset).
	if animator and animator.EvaluationThrottled then
		return
	end
	for slot, joint in a.rig do
		local e = (a.pose :: any)[slot] :: { number }? -- Pose fields indexed by slot name
		if e then
			local rot = CFrame.Angles(e[1], e[2], e[3])
			if joint:IsA("AnimationConstraint") then
				joint.Transform = rot * joint.Transform
			elseif joint:IsA("Motor6D") then
				joint.Transform = rot * joint.Transform
			end
		end
	end
end)

local function hold(character: Model?, pose: Pose)
	if not character then
		active = nil
		return
	end
	local a = active
	if a and a.character == character then
		a.pose = pose
	else
		active = { character = character, rig = findRig(character), pose = pose }
	end
end

-- Hold the anticipation pose for a meter fill of 0..1.
function ThrowAnimator.charge(character: Model?, fill: number)
	if swingStart then
		return
	end
	lastCharge = if GuiService.ReducedMotionEnabled then ThrowPose.REST else ThrowPose.charge(fill, Config.UI)
	hold(character, lastCharge)
end

-- Back to the plain animation (leaving the throw spot, respawn).
function ThrowAnimator.reset(_character: Model?)
	lastCharge = ThrowPose.REST
	swingStart = nil
	swingKeys = nil
	active = nil
end

local function handPosition(character: Model?): Vector3
	if character then
		local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
		if hand and hand:IsA("BasePart") then
			return hand.Position
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return root.Position + Vector3.new(0, 1.5, 0)
		end
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
		task.defer(onRelease, handPosition(character))
		return 0
	end
	swingKeys = ThrowPose.keys(cfg, lastCharge)
	local start = os.clock()
	swingStart = start
	hold(character, lastCharge)
	task.delay(releaseAt, function()
		onRelease(handPosition(character))
	end)
	task.delay(total, function()
		if swingStart == start then
			swingStart = nil
			swingKeys = nil
			lastCharge = ThrowPose.REST
			active = nil
		end
	end)
	return total
end

return ThrowAnimator
