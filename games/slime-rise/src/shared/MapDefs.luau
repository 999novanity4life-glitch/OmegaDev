--!strict
-- The map set, easiest first. Each map is a different room of the lab: its
-- own shape and size (Footprint), floor count, course difficulty, timing and
-- theme (palette + Blender kit). Harder maps are bigger, with more floors and
-- puzzles, wider jumps and less spare time. See docs/MAPS_PROPOSAL.md.

local Footprint = require(script.Parent.Footprint)

local MapDefs = {}

export type MapDef = {
	id: string,
	name: string,
	difficulty: number, -- 1 Easy .. 4 Extreme
	rank: string,
	blurb: string,
	footprint: Footprint.Def,
	tiers: number,
	theme: string, -- "Lab" | "Cryo" | ...
	gaps: { number }, -- edge gap per tier (studs), see CourseLayout
	-- Whole match, head start included. Sized per floor from playtest timing:
	-- an ideal climb is 11-16 s (measured on the layouts), real players take
	-- 2-3x that, plus walking to and solving the puzzle (25-40 s) and the
	-- bridge. Easy gives 75 s a floor, Medium 68, Hard 62, Extreme 56, and
	-- every solve freezes the slime for Config.Slime.SolveHoldSeconds.
	matchSeconds: number,
	playable: boolean, -- false = shown in the picker as coming soon
}

MapDefs.list = {
	{
		id = "Shaft",
		name = "Containment Shaft",
		difficulty = 1,
		rank = "EASY",
		blurb = "Where the leak started. Hop the lab gear up four floors.",
		footprint = { shape = "circle", radius = 36 },
		tiers = 4,
		theme = "Lab",
		gaps = { 3.5, 4.5, 5.5, 6.5 },
		matchSeconds = 300,
		playable = true,
	},
	{
		id = "Cryo",
		name = "Cryo Vault",
		difficulty = 2,
		rank = "MEDIUM",
		blurb = "A frozen storage hall. Icy ledges, frost panels, five floors.",
		footprint = { shape = "rect", width = 92, depth = 64, round = 7 },
		tiers = 5,
		theme = "Cryo",
		gaps = { 5, 5.5, 6, 6.5, 7 },
		matchSeconds = 345,
		playable = true,
	},
	{
		id = "Greenhouse",
		name = "Bio Greenhouse",
		difficulty = 3,
		rank = "HARD",
		blurb = "Overgrown hex domes. Vine climbs, mushroom bounces, sweeping plants.",
		footprint = { shape = "hex", radius = 50 },
		tiers = 6,
		theme = "Greenhouse",
		-- Up to ~95% of the flat max gap: the widest jumps are flat, and the
		-- height comes from vine climbs and mushroom bounces.
		gaps = { 6.5, 7, 7.5, 7.8, 7.9, 8 },
		matchSeconds = 375,
		playable = true,
	},
	{
		id = "Reactor",
		name = "Reactor Core",
		difficulty = 4,
		rank = "EXTREME",
		blurb = "The power plant. Turbines, live rails and slime surges.",
		footprint = { shape = "cross", arm = 18, extent = 52 },
		tiers = 8,
		theme = "Lab",
		gaps = { 7, 7.5, 8, 8.5, 9, 9, 9.5, 9.5 },
		matchSeconds = 450,
		playable = false,
	},
} :: { MapDef }

function MapDefs.get(id: string?): MapDef
	for _, def in MapDefs.list do
		if def.id == id and def.playable then
			return def
		end
	end
	return MapDefs.list[1]
end

function MapDefs.isPlayable(id: any): boolean
	if type(id) ~= "string" then
		return false
	end
	for _, def in MapDefs.list do
		if def.id == id then
			return def.playable
		end
	end
	return false
end

return MapDefs
