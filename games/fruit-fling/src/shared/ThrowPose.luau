--!strict
-- Pure pose curves for the overhand throw (2026-11-20 animation pass).
-- Four joints instead of two (ThrowFX's first swing moved the shoulder and
-- waist only): the right elbow whips straight on release and the left arm
-- points down the lane, then counter-swings - the beats in the M1-M6 motion refs
-- (anticipation, fast release, follow-through hold, settle).
-- Each joint is an {x, y, z} rotation in radians applied on top of the
-- joint's rest C0 (CFrame.Angles order). Sign convention matches ThrowFX:
-- +x on a shoulder raises the arm forward/up.
-- No `game` access; tests/ThrowPose.spec.luau covers it under Lune.

export type Euler = { number }
export type Pose = {
	waist: Euler,
	rightShoulder: Euler,
	rightElbow: Euler,
	leftShoulder: Euler,
}
export type Ease = "smooth" | "in" | "out"
export type Key = { time: number, pose: Pose, ease: Ease }

export type SwingConfig = { SwingWindup: number, SwingFollow: number }
export type ChargeConfig = { ChargeArmPitch: number, ChargeWaistTwist: number }

local ThrowPose = {}

ThrowPose.JOINTS = { "waist", "rightShoulder", "rightElbow", "leftShoulder" }

-- How long the whip from the top of the wind-up to release lasts.
ThrowPose.WHIP_SECONDS = 0.06
-- Extra settle after the follow-through.
ThrowPose.SETTLE_SECONDS = 0.15

local function pose(w: Euler, rs: Euler, re: Euler, ls: Euler): Pose
	return { waist = w, rightShoulder = rs, rightElbow = re, leftShoulder = ls }
end

ThrowPose.REST = pose({ 0, 0, 0 }, { 0, 0, 0 }, { 0, 0, 0 }, { 0, 0, 0 })

-- Meter anticipation: the arm cocks back as the marker climbs (0..1).
function ThrowPose.charge(fill: number, cfg: ChargeConfig): Pose
	local k = math.clamp(fill, 0, 1)
	k = k * k * (3 - 2 * k)
	return pose(
		{ -0.08 * k, cfg.ChargeWaistTwist * k, 0 },
		{ cfg.ChargeArmPitch * k, 0, -0.15 * k },
		{ 0.6 * k, 0, 0 },
		{ 0.5 * k, 0, 0.1 * k }
	)
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
	return {
		{ time = 0, pose = from or ThrowPose.REST, ease = "smooth" },
		-- cock: arm up and back, elbow folded, torso turned away, lead arm points
		{
			time = w * 0.6,
			pose = pose({ -0.15, 0.55, 0 }, { 2.9, 0, -0.3 }, { 1.4, 0, 0 }, { 1.2, 0, 0.15 }),
			ease = "out",
		},
		-- top of the wind-up (small hold = readable anticipation)
		{ time = w, pose = pose({ -0.2, 0.6, 0 }, { 3.4, 0, -0.35 }, { 1.7, 0, 0 }, { 1.4, 0, 0.2 }), ease = "smooth" },
		-- whip: accelerating into release, elbow snaps straight
		{
			time = w + ThrowPose.WHIP_SECONDS,
			pose = pose({ 0.25, -0.35, 0 }, { 1.5, 0, 0.1 }, { 0.15, 0, 0 }, { 0.3, 0, 0 }),
			ease = "in",
		},
		-- follow-through across the body, lead arm swings back (held)
		{
			time = w + f * 0.6,
			pose = pose({ 0.35, -0.55, 0 }, { 0.3, 0, 0.45 }, { 0.4, 0, 0 }, { -0.4, 0, -0.1 }),
			ease = "out",
		},
		{
			time = w + f,
			pose = pose({ 0.3, -0.5, 0 }, { 0.25, 0, 0.4 }, { 0.4, 0, 0 }, { -0.35, 0, -0.1 }),
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
	return t * t * (3 - 2 * t)
end

local function mix(a: Euler, b: Euler, k: number): Euler
	return { a[1] + (b[1] - a[1]) * k, a[2] + (b[2] - a[2]) * k, a[3] + (b[3] - a[3]) * k }
end

function ThrowPose.blend(a: Pose, b: Pose, k: number): Pose
	return {
		waist = mix(a.waist, b.waist, k),
		rightShoulder = mix(a.rightShoulder, b.rightShoulder, k),
		rightElbow = mix(a.rightElbow, b.rightElbow, k),
		leftShoulder = mix(a.leftShoulder, b.leftShoulder, k),
	}
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
