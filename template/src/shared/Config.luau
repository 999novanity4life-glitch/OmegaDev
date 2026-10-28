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

return table.freeze(Config)
