--!strict
-- Every tunable number lives here so designers (and agents) can balance the
-- game without touching logic. Change values, not code.

export type PowerDef = {
	Cost: number,
	Cooldown: number,
	Passive: boolean,
	Distance: number?,
	Duration: number?,
	Range: number?,
}

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

-- One match = one elevator party, built far from the lobby in this server.
Config.Match = {
	HeadStartSeconds = 4, -- after the flyover, before the slime moves
	Seconds = 150, -- whole match, head start included
	ResultsSeconds = 6,
	RespawnSeconds = 3,
	FirstOrigin = Vector3.new(0, 0, 3000), -- match slot 1; later slots step along X
	Spacing = 1200,
}

Config.Slime = {
	BaseDepth = 15, -- slime starts this far below the shaft floor
	TopMargin = 10, -- slime ends this far above the exit
	Exponent = 1.25, -- above 1 = slow start, fast finish
	SolveHoldSeconds = 6, -- solving a floor's puzzle freezes the slime this long
	DamagePerSecond = 50,
	CheckInterval = 0.2,
	ContactMargin = 0.5, -- studs above the surface that still count as touching
}

-- The containment shaft: tiers stacked between bulkhead floors.
Config.Shaft = {
	Tiers = 4,
	TierHeight = 42, -- floor top to next floor top
	Radius = 36, -- inner wall radius
	WallSegments = 24,
	PadsPerTier = 6, -- wall pads from the floor up to the landing
	PadRise = 4.5,
	PadRadius = 27,
	LandingHeight = 30, -- landing top above the tier floor
	HatchSize = 12, -- square hole in each bulkhead
	BridgePads = 3, -- slide out from the wall after the tier puzzle
	BulkheadThickness = 2,
	ExitRadius = 6,
	CoreRadius = 5, -- glass slime tank in the middle
}

-- Course gear behaviour.
Config.Course = {
	FrostWarnSeconds = 0.7, -- a frost panel holds this long after you land
	FrostGoneSeconds = 2.4, -- then it is gone this long before refreezing
	LeafSolidSeconds = 2.6, -- phantom leaf cycle: solid,
	LeafWarnSeconds = 0.7, -- then flutters (half see-through),
	LeafGoneSeconds = 1.5, -- then gone
	SweeperSpeed = 1.5, -- plant sweeper arm, radians per second
}

-- Map intro camera (IntroPath): per tier a wide shot then a push-in on the
-- puzzle, with a quick dip to black between floors.
Config.Intro = {
	FirstWideSeconds = 3.6, -- tier 1 wide carries the sector title
	WideSeconds = 2.8,
	PuzzleSeconds = 3.2,
	ExitSeconds = 3.2,
	DipOut = 0.25, -- fade to black before a floor change
	DipIn = 0.3, -- fade back in on the next floor
	MaxSeconds = 32, -- bigger maps shorten each floor's shots to stay near this
	WideRadius = 26, -- wide camera distance from the shaft centre
	WideOffset = 130, -- degrees around from the route (keeps the core out of the middle)
	WideRise = 9, -- wide camera height above the middle of the route
	FloorClearance = 2.5, -- camera stays this far above a floor
	CeilingClearance = 2.5, -- and this far below the slab above
}

Config.Party = {
	MaxPlayers = 8,
	DefaultMax = 4,
	AutoStartSeconds = 10, -- public pod starts by itself this long after filling
	RideSeconds = 5.5, -- elevator cutscene
	PodCount = 3,
}

Config.Puzzles = {
	-- Real mini-games first; Plates (team) and Fuses (carry) add physical variety.
	Order = { "Pipes", "Wires", "Memory", "Fuses", "Plates" },
	ValveHoldSeconds = 2,
	PlateHoldSeconds = 1.5,
	ColorLevers = 3,
	ColorNames = { "Green", "Purple", "Teal", "Orange" },
	FuseWalkSpeed = 12,
	PromptDistance = 9,
}

Config.Lobby = {
	Origin = Vector3.new(0, 0, 0),
	Size = Vector3.new(140, 36, 96),
	FallCatchDepth = 25, -- below the lobby floor by this much = put back at the spawn
}

Config.Lighting = {
	Ambient = Color3.fromRGB(100, 96, 136),
	OutdoorAmbient = Color3.fromRGB(70, 82, 100),
	Brightness = 2,
	ClockTime = 0,
	FogColor = Color3.fromRGB(18, 30, 26),
	Haze = 0.8,
	AtmosphereColor = Color3.fromRGB(150, 200, 175),
	Bloom = 0.3,
}

Config.Crowns = {
	Escape = 1,
	Speedy = 1,
	SpeedySeconds = 45,
	PodiumBonus = 1,
	PodiumSize = 3,
	StudioStartingCrowns = 25, -- so every power can be tested in Studio
	TeamBonus = 1, -- to everyone alive when a tier puzzle is solved
}

local powers: { [string]: PowerDef } = {
	Dash = { Cost = 0, Cooldown = 6, Passive = false, Distance = 22, Duration = 0.22 },
	DoubleJump = { Cost = 5, Cooldown = 0, Passive = true },
	Shield = { Cost = 12, Cooldown = 20, Passive = false, Duration = 2.5 },
	Grapple = { Cost = 20, Cooldown = 10, Passive = false, Range = 45, Duration = 0.7 },
}
Config.Powers = powers
Config.PowerOrder = { "Dash", "DoubleJump", "Shield", "Grapple" }

Config.Colors = {
	Slime = Color3.fromRGB(107, 255, 61),
	SlimeDeep = Color3.fromRGB(46, 170, 40),
	Pillar = Color3.fromRGB(58, 40, 82),
	PadA = Color3.fromRGB(56, 182, 196),
	PadB = Color3.fromRGB(140, 92, 214),
	Trim = Color3.fromRGB(150, 255, 90),
	Floor = Color3.fromRGB(34, 30, 52),
	Exit = Color3.fromRGB(255, 214, 64),
}

-- HUD icons v2 (original art; source in art/icons/icons2.mjs). Uploaded to the owner's account.
Config.Icons = {
	Crown = "rbxassetid://74343716052407",
	Dash = "rbxassetid://104624439557842",
	Shield = "rbxassetid://90837665542465",
	Grapple = "rbxassetid://135973213830165",
	DoubleJump = "rbxassetid://114652286962017",
	Slime = "rbxassetid://107291750600359",
	Timer = "rbxassetid://112379933179878",
	Exit = "rbxassetid://89572959893618",
	Lock = "rbxassetid://123936364277261",
	-- Objective marker (art/icons/markers.mjs, option B "slime pin").
	MarkerPin = "rbxassetid://90971413579056",
	MarkerRing = "rbxassetid://81596515399927",
	MarkerArrow = "rbxassetid://107174904033799",
}

-- The floating objective marker (MarkerController).
Config.Marker = {
	Height = 7, -- studs above the puzzle
	FadeNear = 9, -- fully faded this close (the interact button shows instead)
	FadeFar = 16, -- fully visible from here out
	EdgeMargin = 115, -- off-screen arrow keeps this far (px) from the screen edge (clears the HUD)
}

-- Mini-game art (art/puzzle_art.py): pipe tiles off/on and tintable symbols.
Config.PuzzleArt = {
	Pipe = {
		["end"] = { off = "rbxassetid://132553462568565", on = "rbxassetid://114173798067856" },
		straight = { off = "rbxassetid://84307288781424", on = "rbxassetid://127606729718843" },
		elbow = { off = "rbxassetid://80010993571282", on = "rbxassetid://116184627948434" },
		tee = { off = "rbxassetid://83587321495017", on = "rbxassetid://103849791979694" },
		cross = { off = "rbxassetid://108381586353374", on = "rbxassetid://78162542822728" },
	},
	-- Colour + symbol pairs, so the puzzles work for colour-blind players.
	Symbols = {
		{ name = "circle", image = "rbxassetid://130643239446591", color = Color3.fromRGB(107, 255, 61) },
		{ name = "square", image = "rbxassetid://75235242033368", color = Color3.fromRGB(166, 107, 255) },
		{ name = "triangle", image = "rbxassetid://100358450635364", color = Color3.fromRGB(61, 232, 255) },
		{ name = "star", image = "rbxassetid://100095636492190", color = Color3.fromRGB(255, 150, 40) },
		{ name = "diamond", image = "rbxassetid://106431767464518", color = Color3.fromRGB(255, 201, 60) },
		{ name = "heart", image = "rbxassetid://139696653372849", color = Color3.fromRGB(255, 90, 120) },
	},
}

-- Roblox audio library only (ProSoundEffects / APM are licensed for Roblox use).
Config.Sounds = {
	LabHum = "rbxassetid://9114330975",
	LobbyMusic = "rbxassetid://9048216729",
	MatchMusic = "rbxassetid://9040002805",
	Alarm = "rbxassetid://97456442012504",
	SlimeBubbles = "rbxassetid://9120303776",
	ElevatorDing = "rbxassetid://18192219147",
	ElevatorHum = "rbxassetid://1843730431",
	DoorSeal = "rbxassetid://613368945",
	Dash = "rbxassetid://9120718689",
	Shield = "rbxassetid://9120341147",
	Grapple = "rbxassetid://9114520162",
	Slimed = "rbxassetid://9114520600",
	Valve = "rbxassetid://9113969124",
	Hydraulic = "rbxassetid://9113055250",
	Solve = "rbxassetid://9041915227",
	Escape = "rbxassetid://9044820101",
}

return table.freeze(Config)
