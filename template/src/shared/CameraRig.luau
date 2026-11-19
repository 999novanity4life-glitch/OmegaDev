--!strict
-- Pure camera math for cutscenes, ability cams and trailer shots. No services,
-- so every rule is unit-tested under Lune. CinematicCamera (client) turns the
-- numbers into Camera.CFrame / FieldOfView each frame.
--
-- A shot is described RELATIVE TO A SUBJECT (a character's root, a boss, a
-- landmark): offsets are { right, up, back } in the subject's own frame, so the
-- same shot works wherever the fight happens. This is the "relative to
-- HumanoidRootPart" pattern battleground games use for ability cams
-- (DevForum: https://devforum.roblox.com/t/camera-animations-for-cutscenes-and-gameplay/1181691).
--
-- Engine facts used here:
--   [DOC] Camera.FieldOfView is clamped to 1-120 degrees, default 70
--         (https://create.roblox.com/docs/reference/engine/classes/Camera).
-- Shot vocabulary (dolly, push-in, orbit, whip pan, crane) is standard film
-- grammar; the easing set mirrors Enum.EasingStyle names [INFERRED].

export type Vec = { number } -- { right, up, back } in subject space, or { x, y, z } in world space
export type Ease = "Linear" | "SineInOut" | "QuadOut" | "CubicInOut" | "ExpoOut" | "ExpoIn" | "BackOut"
export type Pose = {
	offset: Vec, -- camera position in subject space
	look: Vec, -- point the camera looks at, in subject space
	fov: number,
	roll: number?, -- degrees; keep 0 for gameplay (motion sickness, vault/07)
}
export type Shot = {
	name: string,
	duration: number, -- seconds
	from: Pose,
	to: Pose,
	ease: Ease?,
	orbit: number?, -- extra degrees swept around the subject's up axis over the shot
	shake: number?, -- studs of handheld shake (0 = locked off)
	timeScale: number?, -- slow-mo hint for animations and particles during this shot (1 = normal)
	cut: boolean?, -- true = hard cut into this shot (default), false = blend from previous camera
}

local CameraRig = {}

CameraRig.MIN_FOV = 1
CameraRig.MAX_FOV = 120

local function isFinite(n: number): boolean
	return n == n and n ~= math.huge and n ~= -math.huge
end

-- Easing curves on t in [0, 1] (Robert Penner's equations, the same family
-- TweenService uses).
function CameraRig.ease(name: Ease?, t: number): number
	local x = math.clamp(t, 0, 1)
	if name == nil or name == "SineInOut" then
		return -(math.cos(math.pi * x) - 1) / 2
	elseif name == "Linear" then
		return x
	elseif name == "QuadOut" then
		return 1 - (1 - x) * (1 - x)
	elseif name == "CubicInOut" then
		return if x < 0.5 then 4 * x * x * x else 1 - ((-2 * x + 2) ^ 3) / 2
	elseif name == "ExpoOut" then
		return if x >= 1 then 1 else 1 - 2 ^ (-10 * x)
	elseif name == "ExpoIn" then
		return if x <= 0 then 0 else 2 ^ (10 * x - 10)
	elseif name == "BackOut" then
		local c1 = 1.70158
		local c3 = c1 + 1
		return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
	end
	error("unknown ease " .. tostring(name))
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function lerpVec(a: Vec, b: Vec, t: number): Vec
	return { lerp(a[1], b[1], t), lerp(a[2], b[2], t), lerp(a[3], b[3], t) }
end

-- Rotate a subject-space vector about the up axis by `degrees`.
function CameraRig.yawVec(v: Vec, degrees: number): Vec
	local r = math.rad(degrees)
	local c, s = math.cos(r), math.sin(r)
	return { v[1] * c + v[3] * s, v[2], -v[1] * s + v[3] * c }
end

-- Pose of a shot at local alpha (0..1).
function CameraRig.sample(shot: Shot, alpha: number): Pose
	local e = CameraRig.ease(shot.ease, alpha)
	local offset = lerpVec(shot.from.offset, shot.to.offset, e)
	if shot.orbit and shot.orbit ~= 0 then
		offset = CameraRig.yawVec(offset, shot.orbit * e)
	end
	return {
		offset = offset,
		look = lerpVec(shot.from.look, shot.to.look, e),
		fov = math.clamp(lerp(shot.from.fov, shot.to.fov, e), CameraRig.MIN_FOV, CameraRig.MAX_FOV),
		roll = lerp(shot.from.roll or 0, shot.to.roll or 0, e),
	}
end

-- Subject space -> world space. `yaw` is the subject's facing in radians
-- (0 = looking down -Z, Roblox's forward). right = +X, up = +Y, back = +Z.
function CameraRig.toWorld(origin: Vec, yaw: number, v: Vec): Vec
	local c, s = math.cos(yaw), math.sin(yaw)
	return {
		origin[1] + v[1] * c + v[3] * s,
		origin[2] + v[2],
		origin[3] - v[1] * s + v[3] * c,
	}
end

-- Cubic Bezier through four points (for hand-placed flythrough paths).
function CameraRig.bezier(p0: Vec, p1: Vec, p2: Vec, p3: Vec, t: number): Vec
	local u = 1 - t
	local a, b, c, d = u * u * u, 3 * u * u * t, 3 * u * t * t, t * t * t
	return {
		a * p0[1] + b * p1[1] + c * p2[1] + d * p3[1],
		a * p0[2] + b * p1[2] + c * p2[2] + d * p3[2],
		a * p0[3] + b * p1[3] + c * p2[3] + d * p3[3],
	}
end

-- Smooth, deterministic handheld shake: sum of incommensurate sines, so it
-- never repeats visibly and needs no random state. Returns a world offset in
-- studs with magnitude <= amplitude.
function CameraRig.shake(t: number, amplitude: number, seed: number?): Vec
	if amplitude <= 0 then
		return { 0, 0, 0 }
	end
	local k = (seed or 0) * 1.618
	local function n(f1: number, f2: number, p: number): number
		return (math.sin(t * f1 + p + k) * 0.6 + math.sin(t * f2 + p * 2.3 + k) * 0.4)
	end
	-- each axis lies in [-1, 1]; scale by 1/sqrt(3) so the vector length stays <= amplitude
	local s = amplitude / math.sqrt(3)
	return { n(7.1, 13.3, 0.0) * s, n(6.3, 11.7, 1.7) * s, n(5.9, 12.9, 3.1) * s }
end

-- Total running time of a shot list.
function CameraRig.total(shots: { Shot }): number
	local sum = 0
	for _, shot in shots do
		sum += shot.duration
	end
	return sum
end

-- Which shot plays at `time`, and how far through it (0..1). Past the end
-- returns the last shot at alpha 1. Returns nil for an empty list.
function CameraRig.locate(shots: { Shot }, time: number): (number?, number)
	local t = math.max(0, time)
	for i, shot in shots do
		if t < shot.duration or i == #shots then
			return i, math.clamp(t / shot.duration, 0, 1)
		end
		t -= shot.duration
	end
	return nil, 0
end

-- Rejects shot lists that would leave the camera somewhere bad. Run it in
-- tests for every cutscene a game ships.
function CameraRig.validate(shots: { Shot }): (boolean, string?)
	if #shots == 0 then
		return false, "no shots"
	end
	for i, shot in shots do
		local where = string.format("shot %d (%s)", i, shot.name)
		if not (isFinite(shot.duration) and shot.duration > 0) then
			return false, where .. ": duration must be > 0"
		end
		for _, pose in { shot.from, shot.to } do
			for _, v in { pose.offset, pose.look } do
				if #v ~= 3 then
					return false, where .. ": vectors need 3 numbers"
				end
				for _, n in v do
					if not isFinite(n) then
						return false, where .. ": non-finite number"
					end
				end
			end
			if pose.fov < CameraRig.MIN_FOV or pose.fov > CameraRig.MAX_FOV then
				return false, where .. ": fov out of 1-120"
			end
			local ox, oy, oz =
				pose.offset[1] - pose.look[1], pose.offset[2] - pose.look[2], pose.offset[3] - pose.look[3]
			if ox * ox + oy * oy + oz * oz < 1e-6 then
				return false, where .. ": camera sits on its look point"
			end
		end
		CameraRig.ease(shot.ease, 0.5) -- errors on an unknown ease
		if shot.timeScale and (shot.timeScale <= 0 or shot.timeScale > 1) then
			return false, where .. ": timeScale must be in (0, 1]"
		end
	end
	return true, nil
end

-- Ready-made shot builders. Distances in studs, tuned for a 5-stud R15 rig.
-- Numbers are studio starting points [INFERRED], tune per game in Config.
local Shots = {}

-- Slow push-in on the face: the "power-up" beat before an ultimate.
function Shots.pushIn(duration: number, fromDist: number?, toDist: number?): Shot
	return {
		name = "PushIn",
		duration = duration,
		from = { offset = { 1.5, 2, fromDist or 10 }, look = { 0, 1.5, 0 }, fov = 60 },
		to = { offset = { 0.8, 1.8, toDist or 5 }, look = { 0, 1.6, 0 }, fov = 45 },
		ease = "SineInOut",
	}
end

-- Low hero angle orbiting the subject: transformations and reveals.
function Shots.heroOrbit(duration: number, degrees: number?): Shot
	return {
		name = "HeroOrbit",
		duration = duration,
		from = { offset = { 0, 0.5, 9 }, look = { 0, 2.5, 0 }, fov = 55 },
		to = { offset = { 0, 0.8, 8 }, look = { 0, 2.8, 0 }, fov = 50 },
		orbit = degrees or 120,
		ease = "CubicInOut",
	}
end

-- Over-the-shoulder toward a target in front of the subject: wind-ups and beams.
function Shots.overShoulder(duration: number, targetDist: number?): Shot
	local d = targetDist or 20
	return {
		name = "OverShoulder",
		duration = duration,
		from = { offset = { 2.5, 2.2, 6 }, look = { 0, 2, -d }, fov = 62 },
		to = { offset = { 2.2, 2.0, 4.5 }, look = { 0, 2, -d }, fov = 55 },
		ease = "QuadOut",
	}
end

-- Fast whip around to the front with an FOV punch: the hit lands here.
function Shots.whipToFront(duration: number): Shot
	return {
		name = "WhipToFront",
		duration = duration,
		from = { offset = { 6, 2, 3 }, look = { 0, 2, 0 }, fov = 70 },
		to = { offset = { 0, 1.8, -7 }, look = { 0, 2, 0 }, fov = 40 },
		ease = "ExpoOut",
		shake = 0.15,
	}
end

-- Crane up and away to show the aftermath (crater, knocked-back enemies).
function Shots.craneOut(duration: number): Shot
	return {
		name = "CraneOut",
		duration = duration,
		from = { offset = { 0, 4, 10 }, look = { 0, 1, 0 }, fov = 60 },
		to = { offset = { 0, 22, 26 }, look = { 0, 0, -4 }, fov = 65 },
		ease = "CubicInOut",
	}
end

-- Locked-off wide for trailers: let the action play inside a still frame.
function Shots.lockedWide(duration: number): Shot
	return {
		name = "LockedWide",
		duration = duration,
		from = { offset = { 14, 6, 18 }, look = { 0, 2, 0 }, fov = 50 },
		to = { offset = { 14, 6, 18 }, look = { 0, 2, 0 }, fov = 50 },
		ease = "Linear",
	}
end

CameraRig.Shots = Shots

return CameraRig
