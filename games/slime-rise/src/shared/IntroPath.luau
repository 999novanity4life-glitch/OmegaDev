--!strict
-- Pure camera plan for the map intro, built as shots with quick dips to
-- black between floors (the camera never travels through a floor):
--   per tier: a wide establishing shot that slowly drifts across the floor,
--             then a push-in that settles on that tier's puzzle
--   last:     a high shot of the roof exit
-- Every shot moves on a short, nearly straight line toward a fixed subject,
-- so the view never spins. Numbers only, relative to the match origin, so
-- tests can check every frame. Angles are in degrees.

local Config = require(script.Parent.Config)
local ShaftLayout = require(script.Parent.ShaftLayout)

local IntroPath = {}

export type Point = { number } -- { x, y, z }
export type Key = { t: number, pos: Point, look: Point }
export type Shot = { t: number, tier: number, keys: { Key } } -- tier 0 = roof
export type Caption = { t: number, main: string, sub: string }
export type TierInfo = { title: string, label: string, focus: ShaftLayout.Pad }
export type Path = { shots: { Shot }, cuts: { number }, captions: { Caption }, seconds: number }

local function at(angle: number, radius: number, y: number): Point
	local x, z = ShaftLayout.polar(angle, radius)
	return { x, y, z }
end

-- Signed shortest turn from angle a to angle b, in (-180, 180].
local function turn(a: number, b: number): number
	local d = (b - a) % 360
	return if d > 180 then d - 360 else d
end

local function sign(x: number): number
	return if x < 0 then -1 else 1
end

function IntroPath.build(layout: ShaftLayout.Layout, tiers: { TierInfo }, title: string): Path
	local cfg = Config.Intro
	local shots: { Shot } = {}
	local captions: { Caption } = {}
	local clock = 0
	local function shot(tier: number, seconds: number, keys: { { pos: Point, look: Point } })
		local list: { Key } = {}
		for i, k in keys do
			table.insert(list, { t = clock + seconds * (i - 1) / (#keys - 1), pos = k.pos, look = k.look })
		end
		table.insert(shots, { t = clock, tier = tier, keys = list })
		clock += seconds
	end
	local function caption(offset: number, main: string, sub: string)
		table.insert(captions, { t = clock + offset, main = main, sub = sub })
	end

	for i, tier in layout.tiers do
		local info = tiers[i] or { title = `TIER {i}`, label = "", focus = tier.landing }
		local focus = info.focus
		local f, c = tier.floorY, tier.ceilingY
		local low = f + cfg.FloorClearance
		local high = c - Config.Shaft.BulkheadThickness - cfg.CeilingClearance
		local function y(v: number): number
			return math.clamp(v, low, high)
		end
		-- Wide: from across the shaft, framing the middle of this floor's
		-- parkour route (the climb), with a slow sideways drift.
		local mid = focus.angle + turn(focus.angle, tier.hatchAngle) / 2
		local away = -sign(turn(mid, tier.hatchAngle))
		local route = tier.pads[math.max(1, math.ceil(#tier.pads / 2))]
		local camAngle = route.angle + away * cfg.WideOffset
		local subject = at(route.angle, route.radius, route.y)
		local camY = route.y + cfg.WideRise
		if i == 1 then
			caption(0.4, title, "The lab is flooding. Fix the leak. Climb out!")
		else
			caption(0.3, `TIER {i}`, "Climb the lab gear to the hatch")
		end
		shot(i, if i == 1 then cfg.FirstWideSeconds else cfg.WideSeconds, {
			{ pos = at(camAngle - away * 6, cfg.WideRadius, y(camY)), look = subject },
			{
				pos = at(camAngle + away * 6, cfg.WideRadius, y(camY - 1.5)),
				look = { subject[1], subject[2] - 1, subject[3] },
			},
		})
		-- Push-in: glide toward the puzzle and settle on it. Wall puzzles are
		-- approached from the middle of the shaft, floor puzzles from outside.
		local inward = focus.radius >= 22
		local r0 = if inward then focus.radius - 15 else focus.radius + 12
		local r1 = if inward then focus.radius - 7.5 else focus.radius + 7
		local target = at(focus.angle, focus.radius, focus.y)
		caption(0.35, info.title, `Tier {i}: {info.label}`)
		shot(i, cfg.PuzzleSeconds, {
			{
				pos = at(focus.angle + away * 12, r0, y(focus.y + (if inward then 8 else 10))),
				look = { target[1], target[2] + 1, target[3] },
			},
			{ pos = at(focus.angle + away * 5, r1, y(focus.y + (if inward then 3 else 5.5))), look = target },
		})
	end

	-- Roof: high three-quarter view of the exit beacon, drifting in.
	local exit = at(layout.exitAngle, layout.exitRadius, layout.exitY)
	local last = layout.tiers[#layout.tiers]
	local side = if turn(last.hatchAngle, layout.exitAngle) >= 0 then -1 else 1
	caption(0.3, "THE EXIT", "Get everyone out before the slime does!")
	shot(0, cfg.ExitSeconds, {
		{ pos = at(layout.exitAngle + side * 55, 27, layout.topY + 18), look = exit },
		{ pos = at(layout.exitAngle + side * 40, 26, layout.topY + 14), look = exit },
	})

	local cuts: { number } = {}
	for i = 2, #shots do
		-- Only floor changes get a dip to black; wide -> push-in is one move.
		if shots[i].tier ~= shots[i - 1].tier then
			table.insert(cuts, shots[i].t)
		end
	end
	return { shots = shots, cuts = cuts, captions = captions, seconds = clock }
end

-- Smooth position on a shot at time t (cubic Hermite through its keys with
-- zero speed at both ends, so every move eases in and settles).
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
		return {
			(b[field][1] - a[field][1]) / span,
			(b[field][2] - a[field][2]) / span,
			(b[field][3] - a[field][3]) / span,
		}
	end
	local k0, k1 = keys[i], keys[i + 1]
	local dt = k1.t - k0.t
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

-- Camera position and look target at time t, plus which shot is playing.
function IntroPath.sample(path: Path, t: number): (Point, Point, number)
	local index = 1
	for i, s in path.shots do
		if s.t <= t then
			index = i
		end
	end
	local keys = path.shots[index].keys
	return hermite(keys, t, "pos"), hermite(keys, t, "look"), index
end

return IntroPath
