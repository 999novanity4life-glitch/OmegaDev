--!strict
-- Pure timeline for the in-world fruit showcase (2026-11-20, Sharman: "show
-- the actual model", rarities "cool and exaggerated with many effects, not a
-- card"). The fruit bursts out of the water, then the aura climbs tier by
-- tier (Rare -> ... -> the rolled tier) with a burst on every step, then a
-- final slam, then a hold. Each tier adds layers on top of the ones below.
-- No `game` access; tests/ShowcaseBeats.spec.luau covers it under Lune.

export type ShowcaseConfig = {
	RiseSeconds: number,
	StepSeconds: number,
	SlamSeconds: number,
	Hold: { [string]: number },
	Flare: { [string]: number }, -- star-flare build-up before the climb (ref M4)
	ZoomSeconds: number, -- Mythical lunge at the camera on the slam (ref M6)
}

export type Layers = {
	aura: boolean, -- glow puffs + light + rays (every tier)
	rings: boolean, -- shockwave rings on each step (every tier)
	lightning: boolean, -- arcs crackling round the fruit (Epic+)
	pillar: boolean, -- light pillar through the fruit, embers (Legendary+)
	halos: boolean, -- tilted halo rings spinning round the fruit (Legendary+)
	orbit: boolean, -- orbiting comets + rainbow cycle (Mythical)
	flash: boolean, -- white-out on the slam (Legendary+)
	zoom: boolean, -- fruit lunges at the camera to fill the screen (Mythical, ref M6)
}

export type Step = { tier: string, time: number }

export type Plan = {
	flare: number, -- seconds of star flare after the rise (0 = none)
	zoom: number, -- seconds of the camera lunge on the slam (0 = none)
	steps: { Step }, -- tier climb, ending on the rolled tier
	slam: number, -- when the final tier slams in
	total: number, -- when the showcase ends
	rank: number, -- 1 = most common
	rays: number, -- god rays behind the fruit
	burst: number, -- sparks per step burst (before reduced-motion scaling)
}

local ShowcaseBeats = {}

function ShowcaseBeats.rank(rarity: string, order: { string }): number
	return table.find(order, rarity) or 0
end

-- Which effect layers a tier gets. Higher tiers keep every lower layer.
function ShowcaseBeats.layers(rank: number): Layers
	return {
		aura = rank >= 1,
		rings = rank >= 1,
		lightning = rank >= 2,
		pillar = rank >= 3,
		halos = rank >= 3,
		orbit = rank >= 4,
		flash = rank >= 3,
		zoom = rank >= 4,
	}
end

function ShowcaseBeats.plan(rarity: string, order: { string }, cfg: ShowcaseConfig): Plan
	local rank = math.max(1, ShowcaseBeats.rank(rarity, order))
	local tier = order[rank]
	local flare = math.max(0, cfg.Flare[tier] or 0)
	local zoom = if ShowcaseBeats.layers(rank).zoom then cfg.ZoomSeconds else 0
	local steps: { Step } = {}
	for i = 1, rank do
		table.insert(steps, { tier = order[i], time = cfg.RiseSeconds + flare + (i - 1) * cfg.StepSeconds })
	end
	local slam = steps[#steps].time
	local hold = cfg.Hold[tier] or 1.5
	return {
		flare = flare,
		zoom = zoom,
		steps = steps,
		slam = slam,
		total = slam + zoom + cfg.SlamSeconds + hold,
		rank = rank,
		rays = 8 + 4 * rank,
		burst = 20 * rank,
	}
end

-- Radius of an expanding shockwave ring at `t` seconds (ease-out), from r0 to r1.
function ShowcaseBeats.ring(t: number, seconds: number, r0: number, r1: number): number
	local k = if seconds > 0 then math.clamp(t / seconds, 0, 1) else 1
	k = 1 - (1 - k) * (1 - k) * (1 - k)
	return r0 + (r1 - r0) * k
end

-- Zigzag lightning bolt from a to b as `n` points (ends fixed). `rand` gives
-- 0..1 so the caller owns the randomness (tests pass a fixed sequence).
function ShowcaseBeats.bolt(a: { number }, b: { number }, n: number, jitter: number, rand: () -> number): { { number } }
	local pts = { { a[1], a[2], a[3] } }
	for i = 1, n - 2 do
		local k = i / (n - 1)
		local p = {}
		for c = 1, 3 do
			p[c] = a[c] + (b[c] - a[c]) * k + (rand() * 2 - 1) * jitter
		end
		table.insert(pts, p)
	end
	table.insert(pts, { b[1], b[2], b[3] })
	return pts
end

return ShowcaseBeats
