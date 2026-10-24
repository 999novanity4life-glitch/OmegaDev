--!strict
-- Pure parkour route for one tier, built from lab equipment and checked with
-- JumpMath. Each element is a standing surface (top height, half-length along
-- the route) placed around the shaft wall. Assisted moves (bounce pad, fan
-- updraft, arm lift) carry the player up more than a jump can.
-- Angles in degrees, heights relative to the tier floor. Angle/radius are
-- authored for the round reference shaft; x/z are where the element really
-- stands in this map's room (Footprint.polar), and jumps are measured there.

local JumpMath = require(script.Parent.JumpMath)
local Footprint = require(script.Parent.Footprint)

local CourseLayout = {}

export type Element = {
	kind: string, -- Crate | Tank | Shelf | PipeBeam | Conveyor | Centrifuge | Bounce | Fan | Arm | Catwalk
	angle: number,
	radius: number,
	y: number, -- standing height (top surface)
	half: number, -- half-length along the route
	base: number, -- height the element stands on (floor or below)
	rise: number?, -- for Arm: lift distance; for Bounce/Fan: height gained
	assisted: boolean,
	x: number?, -- real position in the room (set by build)
	z: number?,
}

export type Options = { footprint: Footprint.Footprint?, gaps: { number }?, theme: string? }

local RADIUS = 26
-- Edge-to-edge gap per tier (from the jump table: 40% / 55% / 70% / 85% of
-- the 8.67-stud flat travel, rounded to kid-friendly values).
local GAPS = { 3.5, 4.5, 5.5, 6.5 }

type Step = { kind: string, y: number, half: number, rise: number? }

-- Hand-tuned sequences per tier (heights are tops above the tier floor).
-- Nintendo pattern: introduce, develop, twist.
local SEQUENCES: { { Step } } = {
	{ -- Tier 1: learn to hop on lab gear
		{ kind = "Crate", y = 4, half = 2 },
		{ kind = "Crate", y = 8, half = 2 },
		{ kind = "Crate", y = 12, half = 2 },
		{ kind = "Tank", y = 14, half = 2.6 },
		{ kind = "Tank", y = 17, half = 2.6 },
		{ kind = "Shelf", y = 20, half = 3 },
		{ kind = "Catwalk", y = 23.5, half = 4 },
		{ kind = "Catwalk", y = 27, half = 4 },
	},
	{ -- Tier 2: beams, a pushing conveyor, an updraft
		{ kind = "Crate", y = 4, half = 2 },
		{ kind = "Crate", y = 8, half = 2 },
		{ kind = "Tank", y = 11, half = 2.6 },
		{ kind = "PipeBeam", y = 14, half = 6 },
		{ kind = "Conveyor", y = 17, half = 7 },
		{ kind = "Fan", y = 17.5, half = 3.5, rise = 10 },
		{ kind = "Catwalk", y = 27, half = 4 },
	},
	{ -- Tier 3: bounce, spin, lift
		{ kind = "Crate", y = 4, half = 2 },
		{ kind = "Bounce", y = 4.6, half = 2.5, rise = 11 },
		{ kind = "Catwalk", y = 16, half = 4 },
		{ kind = "Centrifuge", y = 19, half = 5 },
		{ kind = "PipeBeam", y = 22, half = 6 },
		{ kind = "Arm", y = 22.6, half = 3, rise = 6 },
		{ kind = "Catwalk", y = 28, half = 4 },
	},
	{ -- Tier 4: everything, wider gaps
		{ kind = "Crate", y = 4, half = 2 },
		{ kind = "Crate", y = 8, half = 2 },
		{ kind = "Conveyor", y = 11, half = 7 },
		{ kind = "Centrifuge", y = 14, half = 5 },
		{ kind = "Tank", y = 17, half = 2.6 },
		{ kind = "Bounce", y = 17.6, half = 2.5, rise = 9 },
		{ kind = "Catwalk", y = 26.5, half = 4 },
	},
}

-- Cryo Vault (Medium): smaller rises so the wider gaps stay makeable, with
-- slippery ice ledges and frost panels that fade when stood on.
local CRYO: { { Step } } = {
	{ -- Tier 1: ice introduced on wide ledges
		{ kind = "Crate", y = 4, half = 2 },
		{ kind = "Crate", y = 8, half = 2 },
		{ kind = "IceLedge", y = 11, half = 3 },
		{ kind = "Tank", y = 14, half = 2.6 },
		{ kind = "Shelf", y = 17, half = 3 },
		{ kind = "Catwalk", y = 20, half = 4 },
		{ kind = "IceLedge", y = 23, half = 3 },
		{ kind = "Catwalk", y = 26.5, half = 4 },
	},
	{ -- Tier 2: frost panels and a freezer conveyor
		{ kind = "Crate", y = 4, half = 2 },
		{ kind = "FrostPanel", y = 7, half = 2.5 },
		{ kind = "FrostPanel", y = 10, half = 2.5 },
		{ kind = "Tank", y = 13, half = 2.6 },
		{ kind = "PipeBeam", y = 16, half = 6 },
		{ kind = "Conveyor", y = 19, half = 7 },
		{ kind = "Catwalk", y = 22.5, half = 4 },
		{ kind = "FrostPanel", y = 25.5, half = 2.5 },
		{ kind = "Catwalk", y = 27.5, half = 4 },
	},
	{ -- Tier 3: bounce into ice
		{ kind = "Crate", y = 4, half = 2 },
		{ kind = "Bounce", y = 4.6, half = 2.5, rise = 11 },
		{ kind = "IceLedge", y = 16, half = 3 },
		{ kind = "FrostPanel", y = 19, half = 2.5 },
		{ kind = "PipeBeam", y = 22, half = 6 },
		{ kind = "Catwalk", y = 25, half = 4 },
		{ kind = "IceLedge", y = 27.5, half = 3 },
	},
	{ -- Tier 4: updraft, then a frost-panel chain
		{ kind = "Crate", y = 4, half = 2 },
		{ kind = "Crate", y = 8, half = 2 },
		{ kind = "Fan", y = 8.5, half = 3.5, rise = 10 },
		{ kind = "Catwalk", y = 19, half = 4 },
		{ kind = "FrostPanel", y = 22, half = 2.5 },
		{ kind = "FrostPanel", y = 25, half = 2.5 },
		{ kind = "Catwalk", y = 27.5, half = 4 },
	},
	{ -- Tier 5: everything, widest gaps
		{ kind = "Crate", y = 4, half = 2 },
		{ kind = "IceLedge", y = 7, half = 3 },
		{ kind = "FrostPanel", y = 10, half = 2.5 },
		{ kind = "IceLedge", y = 13, half = 3 },
		{ kind = "Conveyor", y = 16, half = 7 },
		{ kind = "FrostPanel", y = 19, half = 2.5 },
		{ kind = "Centrifuge", y = 22, half = 5 },
		{ kind = "Catwalk", y = 25, half = 4 },
		{ kind = "IceLedge", y = 27.5, half = 3 },
	},
}

local THEMES: { [string]: { { Step } } } = { Lab = SEQUENCES, Cryo = CRYO }

local ASSISTED = { Bounce = true, Fan = true, Arm = true }
local REFERENCE = Footprint.new({ shape = "circle", radius = Footprint.REF })

-- Builds the route for tier `index` ending before the landing at `endAngle`.
function CourseLayout.build(index: number, endAngle: number, jitter: (() -> number)?, opts: Options?): { Element }
	local fp = (opts and opts.footprint) or REFERENCE
	local sequences = THEMES[(opts and opts.theme) or "Lab"] or SEQUENCES
	local seq = sequences[((index - 1) % #sequences) + 1]
	local gaps = (opts and opts.gaps) or GAPS
	local gap = gaps[math.min(index, #gaps)]
	local roll = jitter or function()
		return 0.5
	end
	-- Lay the route backwards from the landing so it always ends there. Each
	-- element is placed by walking back around the wall until the real edge
	-- gap to the next one (landing at radius 20 included) is the tier's gap.
	local elements: { Element } = {}
	local nextAngle, nextRadius, nextHalf = endAngle, 20, 7
	for i = #seq, 1, -1 do
		local s = seq[i]
		local thisGap = gap + (roll() - 0.5) * 0.8
		local radius = RADIUS + (roll() - 0.5) * 1.5
		local want = s.half + thisGap + nextHalf
		local nx, nz = Footprint.polar(fp, nextAngle, nextRadius)
		local angle = nextAngle
		local x, z = nx, nz
		-- Fine steps: near a rounded corner one step can move the spot a lot.
		for _ = 1, 3600 do
			angle -= 0.1
			x, z = Footprint.polar(fp, angle, radius)
			if math.sqrt((x - nx) ^ 2 + (z - nz) ^ 2) >= want then
				break
			end
		end
		table.insert(elements, 1, {
			kind = s.kind,
			angle = angle,
			radius = radius,
			y = s.y,
			half = s.half,
			base = 0,
			rise = s.rise,
			assisted = ASSISTED[s.kind] == true,
			x = x,
			z = z,
		})
		nextAngle, nextRadius, nextHalf = angle, radius, s.half
	end
	return elements
end

local function where(e: Element, fp: Footprint.Footprint): (number, number)
	if e.x and e.z then
		return e.x, e.z
	end
	return Footprint.polar(fp, e.angle, e.radius)
end

-- Edge gap and height change between two route elements.
function CourseLayout.jump(a: Element, b: Element, fp: Footprint.Footprint?): (number, number)
	local ax, az = where(a, fp or REFERENCE)
	local bx, bz = where(b, fp or REFERENCE)
	local centre = math.sqrt((ax - bx) ^ 2 + (az - bz) ^ 2)
	local fromY = a.y + (if a.assisted and a.rise then a.rise else 0)
	return centre - a.half - b.half, b.y - fromY
end

-- True when every jump on the route can be made (assisted moves count their lift).
function CourseLayout.valid(elements: { Element }, floorStart: boolean?, fp: Footprint.Footprint?): boolean
	if floorStart ~= false and elements[1].y > 4.5 then
		return false
	end
	for i = 2, #elements do
		local gap, dh = CourseLayout.jump(elements[i - 1], elements[i], fp)
		if dh > 5 or gap > JumpMath.maxGap(dh) - 1.5 then
			return false
		end
	end
	return true
end

return CourseLayout
