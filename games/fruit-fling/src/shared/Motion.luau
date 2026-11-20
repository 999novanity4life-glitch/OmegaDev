--!strict
-- Pure motion math for the premium HUD (2026-11-20 UI pass): springs, the
-- rolling distance digits, the Mythical rainbow and extruded-text offsets.
-- No `game` access; tests/Motion.spec.luau covers it under Lune.
-- Numbers come from Config.UI.

local Motion = {}

-- One semi-implicit Euler step of a damped spring toward `target`.
-- `freq` is the natural frequency in Hz, `damping` 1 = critical, < 1 = bouncy.
-- Returns the new position and velocity.
function Motion.spring(
	x: number,
	v: number,
	target: number,
	freq: number,
	damping: number,
	dt: number
): (number, number)
	local w = 2 * math.pi * freq
	local accel = -2 * damping * w * v - w * w * (x - target)
	local nv = v + accel * dt
	return x + nv * dt, nv
end

-- Roll a shown number toward the real one: exponential approach at `rate`
-- per second, never slower than `minStep` per second, never past the target.
function Motion.roll(shown: number, target: number, dt: number, rate: number, minStep: number): number
	local gap = target - shown
	if gap == 0 then
		return target
	end
	local step = gap * (1 - math.exp(-rate * dt))
	local floor = minStep * dt
	if math.abs(step) < floor then
		step = if gap > 0 then floor else -floor
	end
	if math.abs(step) >= math.abs(gap) then
		return target
	end
	return shown + step
end

-- Split metres into the big whole part and the small tenths part, e.g.
-- 142.63 -> "142", ".6". Negative or NaN input shows 0.
function Motion.splitDistance(metres: number): (string, string)
	if metres ~= metres or metres < 0 then
		metres = 0
	end
	local tenths = math.floor(metres * 10 + 0.5)
	return tostring(tenths // 10), "." .. tostring(tenths % 10)
end

-- HSV (all 0..1) to 0-255 RGB.
function Motion.hsv(h: number, s: number, v: number): { number }
	h = h % 1
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	local r, g, b
	if i == 0 then
		r, g, b = v, t, p
	elseif i == 1 then
		r, g, b = q, v, p
	elseif i == 2 then
		r, g, b = p, v, t
	elseif i == 3 then
		r, g, b = p, q, v
	elseif i == 4 then
		r, g, b = t, p, v
	else
		r, g, b = v, p, q
	end
	return { math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5) }
end

-- The Mythical rainbow colour at time `t` (seconds), `offset` shifts the hue
-- so neighbouring gradient keypoints differ.
function Motion.rainbow(t: number, speed: number, offset: number?): { number }
	return Motion.hsv(t * speed + (offset or 0), 0.75, 1)
end

-- Stacked-label extrusion: pixel Y offsets for each layer behind the face,
-- deepest first, and how dark each layer is (0 = black .. 1 = face colour).
function Motion.extrude(layers: number, stepPx: number): { { offset: number, shade: number } }
	local out = {}
	for i = layers, 1, -1 do
		table.insert(out, { offset = i * stepPx, shade = 0.15 + 0.5 * (1 - i / layers) })
	end
	return out
end

-- RGB split width over time: full at 0, closes with an ease-out to 0 at `seconds`.
function Motion.splitWidth(t: number, px: number, seconds: number): number
	if seconds <= 0 or t >= seconds then
		return 0
	end
	local k = 1 - math.max(0, t) / seconds
	return px * k * k
end

-- Back ease-out (overshoot then settle), the pop-in curve. 0..1 -> 0..1.
function Motion.backOut(t: number, overshoot: number?): number
	local s = overshoot or 1.70158
	local u = math.clamp(t, 0, 1) - 1
	return 1 + u * u * ((s + 1) * u + s)
end

-- Name of the zone a distance falls in (zones sorted by `from`), or nil
-- before the first one.
function Motion.zoneAt(distance: number, zones: { { from: number, name: string } }): string?
	local found: string? = nil
	for _, z in zones do
		if distance >= z.from then
			found = z.name
		end
	end
	return found
end

return Motion
