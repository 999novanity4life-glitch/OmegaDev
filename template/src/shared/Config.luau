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

-- Combat feel per hit tier (CombatFeel + ImpactFX, see vault/17). Seconds,
-- studs and degrees. Starting points: tune by watching captures, not by guess.
Config.Feel = {
	Fps = 60, -- frame rate move timings are authored in
	MaxHitStop = 0.12,
	ComboPitchStep = 0.04,
	ComboPitchMax = 0.3,
	ComboShakeStep = 0.15,
	ComboShakeMax = 1,
	Tiers = {
		Light = {
			hitStop = 0.03,
			shake = 0.15,
			fovKick = 0,
			impactFrames = 0,
			slowMo = 0,
			slowMoScale = 1,
			particles = 1,
			pitch = 1,
		},
		Heavy = {
			hitStop = 0.07,
			shake = 0.35,
			fovKick = 3,
			impactFrames = 0,
			slowMo = 0,
			slowMoScale = 1,
			particles = 1.5,
			pitch = 0.9,
		},
		Finisher = {
			hitStop = 0.1,
			shake = 0.6,
			fovKick = 6,
			impactFrames = 2,
			slowMo = 0.35,
			slowMoScale = 0.3,
			particles = 2,
			pitch = 0.8,
		},
		Ultimate = {
			hitStop = 0.12,
			shake = 0.9,
			fovKick = 10,
			impactFrames = 4,
			slowMo = 0.8,
			slowMoScale = 0.2,
			particles = 3,
			pitch = 0.7,
		},
	},
}

-- Cutscenes and ability cams (CinematicCamera, see vault/18).
Config.Cinematic = {
	LetterboxScale = 0.11, -- each bar's height as a fraction of the screen
	LetterboxTime = 0.25,
	SkipAppearsAfter = 1, -- seconds before the Skip button shows
	BlendBackTime = 0.35, -- seconds to ease from the last shot back to gameplay
	AbilityCamMaxSeconds = 3, -- in-combat cams longer than this steal control
}

return table.freeze(Config)
