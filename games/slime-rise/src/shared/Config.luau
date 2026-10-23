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

Config.Round = {
	MinPlayers = 1, -- prototype value so one player can test; launch with 2 + bots
	IntermissionSeconds = 15,
	RoundSeconds = 75,
	HeadStartSeconds = 3,
	ResultsSeconds = 6,
	RespawnSeconds = 3,
}

Config.Slime = {
	BaseY = -15, -- slime starts below the tower floor (about 8 s before it reaches the floor)
	TopMargin = 10, -- slime ends this far above the Exit Pad
	Exponent = 1.25, -- above 1 = slow start, fast finish
	DamagePerSecond = 50,
	CheckInterval = 0.2,
	ContactMargin = 0.5, -- studs above the surface that still count as touching
}

Config.Tower = {
	Origin = Vector3.new(0, 0, 0),
	Pads = 48, -- spiral pads from the floor to the Exit Pad
	RisePerPad = 4.5,
	DegreesPerPad = 22,
	SpiralRadius = 20,
	PillarRadius = 7,
	FloorRadius = 42,
	ExitRadius = 6, -- distance from the Exit Pad that counts as escaping
	LobbyOffset = Vector3.new(110, 40, 0),
}

Config.Crowns = {
	Escape = 1,
	Speedy = 1,
	SpeedySeconds = 45,
	PodiumBonus = 1,
	PodiumSize = 3,
	StudioStartingCrowns = 25, -- so every power can be tested in Studio
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
}

return table.freeze(Config)
