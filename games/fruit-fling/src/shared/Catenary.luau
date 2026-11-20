--!strict
-- Sagging rope / cable / bunting curves (map rulebook M40: curves and sags
-- break CG straightness). Pure math, no Roblox services, so it runs under Lune.
--
-- A rope hanging between two points is a catenary; for the small sags we use
-- (sag under ~25% of span) a parabola is visually identical and needs no
-- solver, so we use the parabola: y(t) = lerp(a, b, t) - 4 * sag * t * (1 - t).

export type Point = { x: number, y: number, z: number }

local Catenary = {}

-- Returns `segments + 1` points from a to b (inclusive) sagging `sag` studs
-- below the straight line at the midpoint.
function Catenary.points(a: Point, b: Point, sag: number, segments: number): { Point }
	assert(segments >= 1, "segments must be >= 1")
	assert(sag == sag and sag >= 0, "sag must be a non-negative number")
	local out: { Point } = table.create(segments + 1)
	for i = 0, segments do
		local t = i / segments
		out[i + 1] = {
			x = a.x + (b.x - a.x) * t,
			y = a.y + (b.y - a.y) * t - 4 * sag * t * (1 - t),
			z = a.z + (b.z - a.z) * t,
		}
	end
	return out
end

-- Sag for a span so long and short ropes look equally slack.
function Catenary.sagFor(span: number, slack: number): number
	return math.max(0, span * slack)
end

-- Length of the polyline (used to size rope segments).
function Catenary.length(points: { Point }): number
	local total = 0
	for i = 2, #points do
		local p, q = points[i - 1], points[i]
		total += math.sqrt((q.x - p.x) ^ 2 + (q.y - p.y) ^ 2 + (q.z - p.z) ^ 2)
	end
	return total
end

return table.freeze(Catenary)
