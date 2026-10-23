--!strict
-- Pure camera path for the map intro: opens on the leak, then glides up the
-- shaft one tier at a time on an inner orbit (looking out at the course and
-- the puzzle), rises through each hatch while its doors slide open, and ends
-- framing the roof exit. Numbers only, relative to the match origin, so tests
-- can prove the camera never passes through a floor. Angles are in degrees.

local Config = require(script.Parent.Config)
local ShaftLayout = require(script.Parent.ShaftLayout)

local IntroPath = {}

export type Point = { number } -- { x, y, z }
export type Key = { t: number, pos: Point, look: Point }
export type Hatch = { t: number, tier: number } -- when the camera crosses that tier's ceiling
export type Caption = { t: number, main: string, sub: string }
export type Path = { keys: { Key }, hatches: { Hatch }, captions: { Caption }, seconds: number }

local function at(angle: number, radius: number, y: number): Point
	local x, z = ShaftLayout.polar(angle, radius)
	return { x, y, z }
end

local function dist(a: Point, b: Point): number
	local dx, dy, dz = a[1] - b[1], a[2] - b[2], a[3] - b[3]
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Signed shortest turn from angle a to angle b, in (-180, 180].
local function turn(a: number, b: number): number
	local d = (b - a) % 360
	return if d > 180 then d - 360 else d
end

function IntroPath.build(layout: ShaftLayout.Layout, labels: { string }, title: string): Path
	local cfg = Config.Intro
	local shaft = Config.Shaft
	-- `dur` fixes the time from the previous waypoint (holds); otherwise it
	-- comes from distance at the glide speed.
	local waypoints: { { pos: Point, look: Point, dur: number? } } = {}
	local hatchAt: { { index: number, tier: number } } = {}
	local captionAt: { { index: number, main: string, sub: string } } = {}
	local function add(pos: Point, look: Point, dur: number?)
		-- Never aim near straight up or down (the shot would spin): keep the
		-- look within ~60 degrees of level.
		local dx, dz = look[1] - pos[1], look[3] - pos[3]
		local flat = math.max(math.sqrt(dx * dx + dz * dz), 3)
		local dy = math.clamp(look[2] - pos[2], -flat * 1.7, flat * 1.7)
		table.insert(waypoints, { pos = pos, look = { look[1], pos[2] + dy, look[3] }, dur = dur })
	end
	-- A hold drifts a little instead of freezing.
	local function hold(seconds: number)
		local w = waypoints[#waypoints]
		add({ w.pos[1] * 0.97, w.pos[2] + 0.5, w.pos[3] * 0.97 }, w.look, seconds)
	end
	local function caption(main: string, sub: string)
		table.insert(captionAt, { index = #waypoints, main = main, sub = sub })
	end
	-- Inner orbit: camera near the core, tracking from one subject on the
	-- wall to another (few pans, mostly parallax, so it reads as calm).
	-- Subjects blend around the wall (polar), never on a chord through the middle.
	local function orbit(a0: number, a1: number, y0: number, y1: number, from: ShaftLayout.Pad, to: ShaftLayout.Pad)
		local sweep = turn(a0, a1)
		local lookTurn = turn(from.angle, to.angle)
		local steps = math.max(2, math.ceil(math.abs(sweep) / 30))
		for i = 1, steps do
			local f = i / steps
			local e = f * f * (3 - 2 * f)
			local look =
				at(from.angle + lookTurn * e, from.radius + (to.radius - from.radius) * e, from.y + (to.y - from.y) * e)
			add(at(a0 + sweep * f, cfg.OrbitRadius, y0 + (y1 - y0) * f), look)
		end
	end

	-- 1. The leak: slow push-in with the title card.
	local leakAngle = layout.tiers[1].hatchAngle + 180
	local leak = at(leakAngle, shaft.Radius - 3, 4)
	add(at(leakAngle + 30, cfg.OrbitRadius + 3, 5), leak)
	caption(title, "The lab is flooding. Fix the leak. Climb out!")
	add(at(leakAngle + 20, cfg.OrbitRadius + 6, 6), leak, cfg.LeakSeconds)

	local fromAngle, fromY = leakAngle + 20, 6
	for i, tier in layout.tiers do
		caption(`TIER {i}`, labels[i] or "")
		-- 2. Orbit to just short of this tier's hatch, rising as we go.
		local dir = if turn(fromAngle, tier.hatchAngle) >= 0 then 1 else -1
		local top = tier.ceilingY - cfg.CeilingClearance
		local mid = tier.pads[math.max(1, math.ceil(#tier.pads / 2))]
		orbit(fromAngle, tier.hatchAngle - dir * cfg.HatchApproach, fromY, top, mid, tier.landing)
		-- 3. Rise straight up through the hatch (its doors slide open) with the
		-- camera near level, so the floor wipes down through the frame.
		local hatchY = tier.ceilingY
		waypoints[#waypoints].look = at(tier.hatchAngle + dir * 45, shaft.PadRadius, hatchY - 5)
		local nextTier = layout.tiers[i + 1]
		local onward = if nextTier
			then at(tier.hatchAngle + turn(tier.hatchAngle, nextTier.hatchAngle) / 2, shaft.PadRadius, hatchY + 8)
			else at(layout.exitAngle, layout.exitRadius, layout.exitY)
		add(
			at(tier.hatchAngle, tier.hatchRadius, top + 0.5),
			at(tier.hatchAngle + dir * 60, shaft.PadRadius, hatchY - 1)
		)
		add(at(tier.hatchAngle, tier.hatchRadius, hatchY + cfg.RiseAbove), onward)
		table.insert(hatchAt, { index = #waypoints, tier = i })
		fromAngle, fromY = tier.hatchAngle, hatchY + cfg.RiseAbove
	end

	-- 4. The roof: swing round high to frame the exit beacon, then hold on it.
	local exit = at(layout.exitAngle, layout.exitRadius, layout.exitY)
	local last = layout.tiers[#layout.tiers]
	local side = if turn(last.hatchAngle, layout.exitAngle) >= 0 then -1 else 1
	add(at(layout.exitAngle + side * 70, 26, layout.topY + 18), exit)
	caption("THE EXIT", "Get everyone out before the slime does!")
	add(at(layout.exitAngle + side * 40, 28, layout.topY + 15), exit)
	hold(cfg.ExitSeconds)

	-- Steady glide speed; if the moving part runs past the cap it is sped up
	-- (holds keep their length so the title and exit still get their time).
	local moving, holds = 0, 0
	for i = 2, #waypoints do
		local w = waypoints[i]
		if w.dur then
			holds += w.dur
		else
			moving += math.max(dist(waypoints[i - 1].pos, w.pos) / cfg.Speed, cfg.MinStep)
		end
	end
	local scale = math.min(1, (cfg.MaxSeconds - holds) / moving)
	local keys: { Key } = { { t = 0, pos = waypoints[1].pos, look = waypoints[1].look } }
	for i = 2, #waypoints do
		local w = waypoints[i]
		local step = w.dur or math.max(dist(waypoints[i - 1].pos, w.pos) / cfg.Speed, cfg.MinStep) * scale
		table.insert(keys, { t = keys[i - 1].t + step, pos = w.pos, look = w.look })
	end
	local hatches: { Hatch } = {}
	for _, h in hatchAt do
		-- Midway between "below" and "above" is when the camera is in the slab.
		table.insert(hatches, { t = (keys[h.index - 1].t + keys[h.index].t) / 2, tier = h.tier })
	end
	local captions: { Caption } = {}
	for _, c in captionAt do
		table.insert(captions, { t = keys[c.index].t, main = c.main, sub = c.sub })
	end
	return { keys = keys, hatches = hatches, captions = captions, seconds = keys[#keys].t }
end

-- Smooth position on the path at time t (cubic Hermite with tangents from the
-- neighbouring keys, zero speed at both ends so it eases in and out).
local function hermite(keys: { Key }, t: number, field: "pos" | "look"): Point
	local n = #keys
	if t <= keys[1].t then
		return keys[1][field]
	elseif t >= keys[n].t then
		return keys[n][field]
	end
	local i = 1
	while i < n - 1 and keys[i + 1].t < t do
		i += 1
	end
	local function tangent(j: number): Point
		if j <= 1 or j >= n then
			return { 0, 0, 0 }
		end
		local a, b = keys[j - 1], keys[j + 1]
		local span = b.t - a.t
		if span <= 0 then
			return { 0, 0, 0 }
		end
		return {
			(b[field][1] - a[field][1]) / span,
			(b[field][2] - a[field][2]) / span,
			(b[field][3] - a[field][3]) / span,
		}
	end
	local k0, k1 = keys[i], keys[i + 1]
	local dt = k1.t - k0.t
	if dt <= 0 then
		return k1[field]
	end
	local s = (t - k0.t) / dt
	local s2, s3 = s * s, s * s * s
	local h00, h10, h01, h11 = 2 * s3 - 3 * s2 + 1, s3 - 2 * s2 + s, -2 * s3 + 3 * s2, s3 - s2
	local m0, m1 = tangent(i), tangent(i + 1)
	local out = {}
	for c = 1, 3 do
		out[c] = h00 * k0[field][c] + h10 * dt * m0[c] + h01 * k1[field][c] + h11 * dt * m1[c]
	end
	return out
end

function IntroPath.sample(keys: { Key }, t: number): (Point, Point)
	return hermite(keys, t, "pos"), hermite(keys, t, "look")
end

return IntroPath
