--!strict
-- Pure pose curves for the full-body overhand throw (2026-11-20 animation pass 2).
-- A real pitching/throwing chain, not a windmill:
--   set (meter):  front leg lifts, torso coils away, throwing arm up in an "L"
--                 with the fruit by the ear, glove arm points down the lane.
--   stride:       front leg strides out and the body drops, the forearm lays
--                 back behind the head (max external rotation).
--   release:      hips and chest fire round, the upper arm internally rotates
--                 (the whip), the elbow snaps straight, wrist flicks.
--   follow:       the arm wraps down across the body, the back foot kicks up,
--                 the chest bends over the front leg. Hold, then settle.
-- The head counter-rotates so the eyes stay on the target throughout.
--
-- Each joint is an {x, y, z} rotation (CFrame.Angles order, applied in the
-- joint's parent frame on top of the animated Transform). `root` carries a
-- 4th value: a vertical drop in studs (the body sinks into the stride).
-- Throwing shoulder: z abducts (raises the arm sideways), y swings it
-- horizontally (+ forward), x turns the arm about its own axis (+ lays the
-- bent forearm up/back, - turns it forward and down); ThrowAnimator composes
-- it as swing * abduct * twist. Glove shoulder: plain Euler, +x raises forward.
-- Hips/knees/elbows/wrists: +x swings the limb forward, -x back.
-- No `game` access; tests/ThrowPose.spec.luau covers it under Lune.

export type Euler = { number }
export type Pose = { [string]: Euler }
export type Ease = "smooth" | "in" | "out"
export type Key = { time: number, pose: Pose, ease: Ease }

export type SwingConfig = { SwingWindup: number, SwingFollow: number }
export type ChargeConfig = { ChargeLayback: number, ChargeWaistTwist: number, ChargeLegLift: number }

local ThrowPose = {}

ThrowPose.JOINTS = {
	"root",
	"waist",
	"neck",
	"rightShoulder",
	"rightElbow",
	"rightWrist",
	"leftShoulder",
	"leftElbow",
	"leftHip",
	"leftKnee",
	"rightHip",
	"rightKnee",
}

-- How long the whip from max layback to release lasts.
ThrowPose.WHIP_SECONDS = 0.06
-- Settle from the follow-through hold back to the plain animation.
ThrowPose.SETTLE_SECONDS = 0.3

local function zero(): Euler
	return { 0, 0, 0 }
end

-- Builds a full pose; any joint left out is at rest. The neck is derived so
-- the eyes stay on the lane: it undoes the waist turn and most of its pitch.
local function pose(p: Pose): Pose
	local out: Pose = {}
	for _, j in ThrowPose.JOINTS do
		out[j] = p[j] or zero()
	end
	out.root = { out.root[1], out.root[2], out.root[3], out.root[4] or 0 }
	if not p.neck then
		local w = out.waist
		out.neck = { -0.6 * w[1], -0.85 * w[2], -0.5 * w[3] }
	end
	return out
end

ThrowPose.REST = pose({})

-- The "set" pose at a full meter (fill 1). Coil amounts come from Config.UI.
local function setPose(cfg: ChargeConfig): Pose
	return pose({
		root = { 0, 0, 0, -0.12 },
		waist = { 0.08, -cfg.ChargeWaistTwist, -0.06 }, -- lean back a touch, coil right
		rightShoulder = { cfg.ChargeLayback, -0.35, 2.0 }, -- elbow at shoulder height, forearm up
		rightElbow = { 1.55, 0, 0 },
		rightWrist = { -0.35, 0, 0 },
		leftShoulder = { 1.45, 0, -0.15 }, -- glove arm points down the lane
		leftElbow = { 0.25, 0, 0 },
		leftHip = { cfg.ChargeLegLift, 0, 0.05 }, -- knee up
		leftKnee = { -1.75, 0, 0 },
		rightHip = { 0.15, 0, 0 }, -- weight sits on the back leg
		rightKnee = { -0.3, 0, 0 },
	})
end

local function easeInOut(k: number): number
	return k * k * (3 - 2 * k)
end

local function mix(a: Euler, b: Euler, k: number): Euler
	local out = {}
	for i = 1, math.max(#a, #b) do
		local x, y = a[i] or 0, b[i] or 0
		out[i] = x + (y - x) * k
	end
	return out
end

function ThrowPose.blend(a: Pose, b: Pose, k: number): Pose
	local out: Pose = {}
	for _, j in ThrowPose.JOINTS do
		out[j] = mix(a[j] or zero(), b[j] or zero(), k)
	end
	return out
end

-- Meter anticipation: the body winds into the set pose as the marker climbs (0..1).
function ThrowPose.charge(fill: number, cfg: ChargeConfig): Pose
	local k = easeInOut(math.clamp(fill, 0, 1))
	return ThrowPose.blend(ThrowPose.REST, setPose(cfg), k)
end

function ThrowPose.releaseTime(cfg: SwingConfig): number
	return cfg.SwingWindup + ThrowPose.WHIP_SECONDS
end

function ThrowPose.totalTime(cfg: SwingConfig): number
	return cfg.SwingWindup + cfg.SwingFollow + ThrowPose.SETTLE_SECONDS
end

-- Keyframes. `from` is the pose the swing starts in (the locked charge pose),
-- so there is no pop between the meter and the swing.
function ThrowPose.keys(cfg: SwingConfig, from: Pose?): { Key }
	local w, f = cfg.SwingWindup, cfg.SwingFollow
	local release = w + ThrowPose.WHIP_SECONDS
	return {
		{ time = 0, pose = from or ThrowPose.REST, ease = "smooth" },
		-- stride: front foot reaches out, body sinks, forearm starts laying back
		{
			time = w * 0.55,
			pose = pose({
				root = { 0, 0, 0, -0.4 },
				waist = { 0.05, -0.6, -0.08 },
				rightShoulder = { 2.3, -0.45, 2.05 },
				rightElbow = { 1.6, 0, 0 },
				rightWrist = { -0.5, 0, 0 },
				leftShoulder = { 1.5, 0, -0.25 },
				leftElbow = { 0.3, 0, 0 },
				leftHip = { 0.8, 0, 0.08 },
				leftKnee = { -0.45, 0, 0 },
				rightHip = { -0.25, 0, 0 },
				rightKnee = { -0.45, 0, 0 },
			}),
			ease = "out",
		},
		-- foot plant, max layback: hips fire first, the arm lags behind (the coil)
		{
			time = w,
			pose = pose({
				root = { 0, 0, 0, -0.5 },
				waist = { -0.05, -0.15, -0.1 },
				rightShoulder = { 2.6, -0.55, 2.1 },
				rightElbow = { 1.6, 0, 0 },
				rightWrist = { -0.7, 0, 0 },
				leftShoulder = { 0.9, 0, -0.5 },
				leftElbow = { 1.2, 0, 0 },
				leftHip = { 0.7, 0, 0.08 },
				leftKnee = { -0.25, 0, 0 },
				rightHip = { -0.5, 0, 0 },
				rightKnee = { -0.7, 0, 0 },
			}),
			ease = "smooth",
		},
		-- release: chest whips round, arm fires forward over the top, elbow snaps
		{
			time = release,
			pose = pose({
				root = { 0, 0, 0, -0.55 },
				waist = { -0.35, 0.5, 0.05 },
				rightShoulder = { 0.1, 0.85, 2.25 },
				rightElbow = { 0.2, 0, 0 },
				rightWrist = { 0.55, 0, 0 },
				leftShoulder = { 0.35, 0, -0.6 }, -- glove tucked to the chest
				leftElbow = { 1.9, 0, 0 },
				leftHip = { 0.6, 0, 0.08 },
				leftKnee = { -0.2, 0, 0 },
				rightHip = { -0.6, 0, 0 },
				rightKnee = { -0.9, 0, 0 },
			}),
			ease = "in",
		},
		-- follow-through: arm wraps across to the left hip, back foot kicks up
		{
			time = w + f * 0.6,
			pose = pose({
				root = { 0, 0, 0, -0.55 },
				waist = { -0.6, 0.65, 0.1 },
				rightShoulder = { -0.45, 1.3, 0.7 },
				rightElbow = { 0.55, 0, 0 },
				rightWrist = { 0.4, 0, 0 },
				leftShoulder = { 0.15, 0, -0.45 },
				leftElbow = { 1.6, 0, 0 },
				leftHip = { 0.65, 0, 0.05 },
				leftKnee = { -0.35, 0, 0 },
				rightHip = { -0.9, 0, 0 },
				rightKnee = { -1.5, 0, 0 },
			}),
			ease = "out",
		},
		-- held finish (readable silhouette)
		{
			time = w + f,
			pose = pose({
				root = { 0, 0, 0, -0.5 },
				waist = { -0.55, 0.6, 0.1 },
				rightShoulder = { -0.4, 1.25, 0.65 },
				rightElbow = { 0.6, 0, 0 },
				rightWrist = { 0.35, 0, 0 },
				leftShoulder = { 0.15, 0, -0.4 },
				leftElbow = { 1.5, 0, 0 },
				leftHip = { 0.6, 0, 0.05 },
				leftKnee = { -0.35, 0, 0 },
				rightHip = { -0.8, 0, 0 },
				rightKnee = { -1.4, 0, 0 },
			}),
			ease = "smooth",
		},
		{ time = w + f + ThrowPose.SETTLE_SECONDS, pose = ThrowPose.REST, ease = "smooth" },
	}
end

local function eased(t: number, ease: Ease): number
	if ease == "in" then
		return t * t
	elseif ease == "out" then
		return 1 - (1 - t) * (1 - t)
	end
	return easeInOut(t)
end

-- Pose at `t` seconds into the swing. Clamps outside the key range.
function ThrowPose.sample(keys: { Key }, t: number): Pose
	if t <= keys[1].time then
		return keys[1].pose
	end
	for i = 2, #keys do
		local a, b = keys[i - 1], keys[i]
		if t <= b.time then
			local span = b.time - a.time
			local k = if span > 0 then (t - a.time) / span else 1
			return ThrowPose.blend(a.pose, b.pose, eased(k, b.ease))
		end
	end
	return keys[#keys].pose
end

return ThrowPose
