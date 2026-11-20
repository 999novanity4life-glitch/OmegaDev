--!strict
-- Pure math for the landing splash (no services): which tier row to use, the
-- crown droplet velocities and their ballistic arcs. ThrowFX turns these
-- numbers into parts; the spec checks them.

local SplashShape = {}

export type Tier = {
	column: number,
	crown: number,
	ripples: number,
	reach: number,
	rays: number,
	pillar: number,
	light: number,
	shake: number,
}

-- The tier row for a rarity rank (1 = Rare). Out-of-range or NaN ranks clamp.
-- Masterwork scales every size up (counts are rounded).
function SplashShape.tier(rank: number, tiers: { Tier }, masterwork: boolean, masterworkScale: number): Tier
	local i = if rank ~= rank then 1 else math.clamp(math.floor(rank), 1, #tiers)
	local row = tiers[i]
	local s = if masterwork then masterworkScale else 1
	return {
		column = row.column * s,
		crown = math.floor(row.crown * s + 0.5),
		ripples = row.ripples,
		reach = row.reach * s,
		rays = math.floor(row.rays * s + 0.5),
		pillar = row.pillar * s,
		light = row.light * s,
		shake = row.shake,
	}
end

-- Launch velocity of crown droplet i of n: evenly spaced around the circle,
-- with alternating tall/short droplets so the crown looks ragged.
-- Returns vx, vy, vz in studs/s.
function SplashShape.crownVelocity(
	i: number,
	n: number,
	column: number,
	gravity: number,
	upFrac: number,
	outPerStud: number
): (number, number, number)
	local angle = (i - 1) / math.max(n, 1) * 2 * math.pi
	local tall = if i % 2 == 0 then 1 else 0.7
	local up = math.sqrt(2 * gravity * column) * upFrac * tall
	local out = outPerStud * column * (if i % 2 == 0 then 0.8 else 1.2)
	return math.cos(angle) * out, up, math.sin(angle) * out
end

-- Position offset of a droplet t seconds after launch.
function SplashShape.ballistic(t: number, vx: number, vy: number, vz: number, gravity: number): (number, number, number)
	return vx * t, vy * t - 0.5 * gravity * t * t, vz * t
end

-- Seconds until a droplet launched upward at vy falls back to the water.
function SplashShape.airTime(vy: number, gravity: number): number
	if gravity <= 0 then
		return 0
	end
	return math.max(0, 2 * vy / gravity)
end

return SplashShape
