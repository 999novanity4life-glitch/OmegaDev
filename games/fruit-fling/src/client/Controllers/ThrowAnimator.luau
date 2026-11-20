--!strict
-- Procedural throw animation (client, cosmetic). Drives four R15 joints from
-- the pure ThrowPose curves:
--   charge(fill) while the meter runs: the arm cocks back as the marker climbs,
--   swing(): wind-up -> whip (release) -> follow-through hold -> settle.
-- Uses Motor6D.C0 offsets on top of each joint's rest C0, like ThrowFX did,
-- so it layers over whatever the Animator plays. R6 falls back to the two
-- shoulders. C0 edits made on the client do not replicate, so other players
-- see the default pose: a server-side or AnimationTrack version is a Studio
-- follow-up (noted in the PR).

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ThrowPose = require(Shared:WaitForChild("ThrowPose"))

type Pose = ThrowPose.Pose

local ThrowAnimator = {}

type Rig = { [string]: { motor: Motor6D, rest: CFrame } }

-- Rest C0 per motor, remembered the first time we touch it so repeated
-- throws never drift.
local rest: { [Motor6D]: CFrame } = setmetatable({}, { __mode = "k" }) :: any

local JOINT_PATHS: { [string]: { { string } } } = {
	waist = { { "UpperTorso", "Waist" } },
	rightShoulder = { { "RightUpperArm", "RightShoulder" }, { "Torso", "Right Shoulder" } },
	rightElbow = { { "RightLowerArm", "RightElbow" } },
	leftShoulder = { { "LeftUpperArm", "LeftShoulder" }, { "Torso", "Left Shoulder" } },
}

local function rig(character: Model?): Rig
	local out: Rig = {}
	if not character then
		return out
	end
	for joint, paths in JOINT_PATHS do
		for _, path in paths do
			local part = character:FindFirstChild(path[1])
			local m = part and part:FindFirstChild(path[2])
			if m and m:IsA("Motor6D") then
				local known: CFrame? = rest[m]
				if not known then
					known = m.C0
					rest[m] = m.C0
				end
				out[joint] = { motor = m, rest = known :: CFrame }
				break
			end
		end
	end
	return out
end

local function apply(r: Rig, pose: Pose)
	for joint, entry in r do
		local e = (pose :: any)[joint] :: { number }?
		if e then
			entry.motor.C0 = entry.rest * CFrame.Angles(e[1], e[2], e[3])
		end
	end
end

local lastCharge: Pose = ThrowPose.REST
local swinging = false

-- Hold the anticipation pose for a meter fill of 0..1.
function ThrowAnimator.charge(character: Model?, fill: number)
	if swinging then
		return
	end
	lastCharge = if GuiService.ReducedMotionEnabled then ThrowPose.REST else ThrowPose.charge(fill, Config.UI)
	apply(rig(character), lastCharge)
end

-- Back to the rest pose (leaving the throw spot, respawn).
function ThrowAnimator.reset(character: Model?)
	lastCharge = ThrowPose.REST
	apply(rig(character), ThrowPose.REST)
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
	local keys = ThrowPose.keys(cfg, lastCharge)
	local total = ThrowPose.totalTime(cfg)
	local releaseAt = ThrowPose.releaseTime(cfg)
	local r = rig(character)
	if GuiService.ReducedMotionEnabled or next(r) == nil then
		-- No animation: release straight away so the throw never stalls.
		task.defer(onRelease, handPosition(character))
		return 0
	end
	swinging = true
	local start = os.clock()
	local released = false
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		apply(r, ThrowPose.sample(keys, t))
		if not released and t >= releaseAt then
			released = true
			onRelease(handPosition(character))
		end
		if t >= total then
			connection:Disconnect()
			apply(r, ThrowPose.REST)
			lastCharge = ThrowPose.REST
			swinging = false
		end
	end)
	return total
end

return ThrowAnimator
