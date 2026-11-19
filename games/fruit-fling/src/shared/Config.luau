--!strict
-- Every tunable number lives here so designers (and agents) can balance the
-- game without touching logic. Change values, not code.

local Config = {}

Config.Progression = {
	-- XP needed for level n is BaseXp * n ^ Exponent (rounded).
	BaseXp = 50,
	Exponent = 1.5,
	MaxLevel = 100,
}

Config.RateLimits = {
	-- Max requests per player per window for each remote.
	DefaultPerSecond = 10,
	Burst = 20,
}

Config.Juice = {
	ButtonPressScale = 0.92,
	ButtonPressTime = 0.06,
	PopInTime = 0.18,
	CameraShakeDecay = 6,
}

-- Look (see docs/VISUAL_QA.md and vault/15). Preset names live in
-- LightingPresets; zones blend between presets over ZoneBlendSeconds.
Config.Look = {
	Preset = "RobloxOutdoorSunset",
	ZoneBlendSeconds = 1.5,
}

-- Procedural terrain (TerrainGen + WorldBuilder). Studs unless noted.
Config.Terrain = {
	Seed = 1,
	Size = 512, -- square area, from the origin
	Depth = 128, -- vertical extent written, from y = 0
	BaseHeight = 40,
	Amplitude = 12,
	Frequency = 1 / 160, -- 1 / studs
	Octaves = 4,
	Persistence = 0.5,
	CraterCount = 0,
	CraterRadius = { 12, 48 },
	ChunkVoxels = 64,
	-- First match wins. Names are Enum.Material names.
	Materials = {
		{ material = "Rock", minSlope = 0.9 },
		{ material = "Ground", minSlope = 0.5 },
		{ material = "Grass" },
	} :: { { material: string, minSlope: number?, maxSlope: number?, minHeight: number?, maxHeight: number? } },
	FallbackMaterial = "Ground",
	PropSpacing = 18,
	MaxProps = 300,
}

-- The 3-beat throw (design doc section 3, Option A). Times in seconds,
-- distances in studs. Starting guesses: tune in Studio by feel.
Config.Throw = {
	-- Beat 1, wind-up: a marker ping-pongs along a bar while the button is held;
	-- release it inside the drifting gold zone. Zone sizes are fractions of the bar.
	MarkerPeriod = 0.9, -- one full up-and-down sweep
	ZoneHalfWidth = 0.11,
	ZoneDriftSpeed = 0.35, -- bar lengths per second
	WindupMaxHold = 3, -- auto-release after this long
	-- Fraction of ZoneHalfWidth from the zone centre for each grade.
	ZoneGrades = { Perfect = 0.35, Great = 0.7, Good = 1 },
	-- Beat 2, release ring: shrinks onto the target over RingSeconds; tap on overlap.
	-- Beat 3, air tap: same ring, shown mid-flight.
	RingSeconds = 0.55,
	AirRingSeconds = 0.45,
	AirRingAt = 0.4, -- fraction of the flight when the air ring starts
	TimingWindows = { Perfect = 0.06, Great = 0.11, Good = 0.17 },
	-- Distance = BaseDistance * windup mult * release mult * (1 + air bonus) * combo * masterwork.
	BaseDistance = 120,
	WindupMult = { Miss = 0.6, Good = 0.85, Great = 1, Perfect = 1.15 },
	ReleaseMult = { Miss = 0.5, Good = 0.8, Great = 1, Perfect = 1.25 },
	AirBonus = { Miss = 0, Good = 0.1, Great = 0.2, Perfect = 0.35 },
	MasterworkMult = 1.25, -- all three beats Perfect
	ComboStep = 0.05, -- per consecutive Perfect release
	ComboMax = 10,
	-- Flight time grows with distance so long throws feel long.
	FlightBase = 0.9,
	FlightPerStud = 1 / 150,
	FlightMin = 1.1,
	FlightMax = 3,
	FlightArcHeight = 0.35, -- arc peak as a fraction of distance
	-- Server-side sanity: the air tap must arrive inside the flight (plus lag).
	LagAllowance = 0.4,
	-- Juice
	HitstopSeconds = 0.06,
	PerfectShake = 0.35,
	MasterworkShake = 0.8,
}

-- Greybox lane (server/Services/Lane). Studs.
Config.Lane = {
	DeckHeight = 8,
	Length = 800,
	MarkerEvery = 25,
}

-- Dock map (DockLayout plan -> DockBuilder). Studs and degrees. Rules cited
-- are docs/rulebooks/MAP_RULEBOOK.md; plan in games/fruit-fling/MAP_PLAN.md.
Config.Dock = {
	Enabled = true, -- false = old greybox lane (Lane.luau)
	Seed = 7,
	DeckHeight = 8, -- M20: nothing at y = 0, lift by a multiple of 4
	WaterY = 4,
	SeabedY = -24,
	PierHalfWidth = 12,
	ThrowEdgeZ = -12, -- throws go along -Z from here
	ShoreZ = 100,
	PilingSpacing = 8, -- M34 rhythm
	PilingDiameter = 1.6,
	PilingAboveDeck = 3.5,
	LanternEvery = 2, -- a lantern on every 2nd piling (M41)
	RopeSlack = 0.08, -- sag as a fraction of span (M40)
	LaneKeepClearHalfWidth = 5, -- props never inside |x| < this on the pier (M10, M38)
	GroupSpacing = 13, -- min distance between story groups
	GroupSize = { 3, 8 }, -- M38
	BuntingEvery = 24,
	BuntingPoleHeight = 13,
	LaneLength = 800,
	BuoyEvery = 50, -- a landmark at least every ~50 studs along the lane
	SeaStackEvery = 160,
	LighthouseHeight = 64,
	LighthouseSpinSeconds = 8,
	CoveRadius = 150,
	CoveTerraces = 3,
	TerraceStep = 22,
}

return table.freeze(Config)
