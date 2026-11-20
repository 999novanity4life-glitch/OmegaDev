--!strict
-- Every tunable number lives here so designers (and agents) can balance the
-- game without touching logic. Change values, not code.

export type ShopItem = {
	Kind: "GamePass" | "Product",
	AssetId: number,
	Price: number,
	Name: string,
	Blurb: string,
	Cover: string,
	Order: number,
	Tab: string,
	Berries: number?,
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

-- Look (see docs/VISUAL_QA.md and vault/15). Preset names live in
-- LightingPresets; zones blend between presets over ZoneBlendSeconds.
Config.Look = {
	Preset = "BrightFantasy", -- Sharman's map-style video (2026-11-20)
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

-- The throw (design doc section 3, reworked 2026-11-20 after Throw Food For
-- Animals, frames measured in project files fruit-throw/tffa-ref-2026-11-20).
-- Times in seconds, distances in studs. Tune in Studio by feel.
Config.Throw = {
	-- Beat 1, power meter (TFFA style): a marker bounces up and down a vertical
	-- bar, green at the top. One tap locks it. The value runs 0..MeterMax and
	-- the top is PERFECT. Measured from TFFA: about 1.1 s per sweep, slow at the
	-- bottom, fast at the top (MeterEase > 1), starts at +5.
	MeterMax = 20,
	MeterPeriod = 2.2, -- one full up-and-down cycle
	MeterEase = 1.4,
	MeterStart = 5,
	MeterAppearDelay = 0.4,
	MeterLockHold = 0.5, -- the locked marker stays on screen this long
	MeterGrades = { Perfect = 20, Great = 16, Good = 10 }, -- minimum power for each grade
	-- Power -> distance multiplier: MeterMinMult at 0, MeterMaxMult at MeterMax.
	MeterMinMult = 0.5,
	MeterMaxMult = 1.15,
	-- Beat 2, release ring: shrinks onto the target over RingSeconds; tap on overlap.
	-- Beat 3, air tap: same ring, shown mid-flight. Both are bonus distance.
	RingSeconds = 0.55,
	AirRingSeconds = 0.45,
	AirRingAt = 0.4, -- fraction of the flight when the air ring starts
	TimingWindows = { Perfect = 0.06, Great = 0.11, Good = 0.17 },
	-- Distance = BaseDistance * meter mult * release mult * (1 + air bonus) * combo * masterwork.
	BaseDistance = 120,
	ReleaseMult = { Miss = 0.5, Good = 0.8, Great = 1, Perfect = 1.25 },
	AirBonus = { Miss = 0, Good = 0.1, Great = 0.2, Perfect = 0.35 },
	MasterworkMult = 1.25, -- all three beats Perfect
	ComboStep = 0.05, -- per consecutive Perfect release
	ComboMax = 10,
	-- Flight time grows with distance so long throws feel long. A touch faster
	-- than TFFA (Sharman 2026-11-20); RarityPace below stretches rare fruits.
	FlightBase = 0.8,
	FlightPerStud = 1 / 170,
	FlightMin = 1,
	FlightMax = 2.8,
	FlightArcHeight = 0.35, -- arc peak as a fraction of distance
	-- Server-side sanity: the air tap must arrive inside the flight (plus lag).
	LagAllowance = 0.4,
	-- Swing (TFFA: ~0.2 s wind-up, release, ~0.3 s follow-through).
	SwingWindup = 0.2,
	SwingFollow = 0.3,
	-- Dock edge: walking this close to the throw spot starts the cutscene.
	EdgeTriggerRadius = 9,
	EdgeSpotBack = 3, -- the player stands this far behind ThrowEdgeZ
	CutsceneSeconds = 1.1,
	EdgeRetriggerSeconds = 1.5,
	-- Juice
	HitstopSeconds = 0.06,
	PerfectShake = 0.35,
	MasterworkShake = 0.8,
}

-- Rarity pacing (Sharman 2026-11-20: the rarer the fruit, the slower and more
-- dramatic the follow camera). flight = flight time multiplier, camSpeed =
-- follow-cam catch-up rate (higher is snappier), slowmo = seconds of slow
-- motion right after release, played at slowmoSpeed.
export type Pace = { flight: number, camSpeed: number, slowmo: number, slowmoSpeed: number }
Config.Rarity = {
	Order = { "Rare", "Epic", "Legendary", "Mythical" },
	Weight = { Rare = 50, Epic = 30, Legendary = 15, Mythical = 5 },
	Color = {
		Rare = { 90, 170, 255 },
		Epic = { 190, 90, 255 },
		Legendary = { 255, 190, 50 },
		Mythical = { 255, 60, 90 },
	},
	Pace = {
		Rare = { flight = 0.9, camSpeed = 16, slowmo = 0, slowmoSpeed = 1 },
		Epic = { flight = 1, camSpeed = 12, slowmo = 0, slowmoSpeed = 1 },
		Legendary = { flight = 1.15, camSpeed = 8, slowmo = 0.25, slowmoSpeed = 0.3 },
		Mythical = { flight = 1.35, camSpeed = 5, slowmo = 0.5, slowmoSpeed = 0.25 },
	} :: { [string]: Pace },
}

-- Landing impact, one row per rarity rank (Rare..Mythical): rarer = bigger.
-- column = water column height (studs), crown = droplets in the splash crown,
-- ripples = expanding rings, reach = widest ripple, rays = radial light rays
-- on the water, pillar = rarity light pillar height (0 = none), light =
-- flash brightness, shake = camera shake strength.
export type SplashTier = {
	column: number,
	crown: number,
	ripples: number,
	reach: number,
	rays: number,
	pillar: number,
	light: number,
	shake: number,
}
Config.Splash = {
	Tiers = {
		{ column = 6, crown = 10, ripples = 2, reach = 18, rays = 0, pillar = 0, light = 4, shake = 0 },
		{ column = 10, crown = 14, ripples = 3, reach = 26, rays = 6, pillar = 0, light = 6, shake = 0.2 },
		{ column = 16, crown = 20, ripples = 4, reach = 36, rays = 10, pillar = 70, light = 9, shake = 0.45 },
		{ column = 24, crown = 28, ripples = 5, reach = 50, rays = 16, pillar = 120, light = 14, shake = 0.8 },
	} :: { SplashTier },
	MasterworkScale = 1.35,
	Gravity = 70, -- studs/s^2 for droplets
	CrownUp = 0.9, -- droplet up speed as a fraction of sqrt(2*g*column)
	CrownOut = 0.35, -- droplet sideways speed per stud of column
	RippleGap = 0.12, -- seconds between ripple rings
	RippleSeconds = 0.9,
	ColumnRise = 0.18, -- seconds for the column to reach full height
	ColumnFall = 0.5,
}

-- The fruit roster (models in assets/fruits/<key>). Rarity follows the
-- strength rule in the design doc. Feel test: each throw rolls a fruit by
-- rarity weight until equipping exists.
Config.Fruits = {
	{ key = "magma", name = "Magma Fruit", rarity = "Rare", glow = { 255, 110, 40 } },
	{ key = "quake", name = "Quake Fruit", rarity = "Epic", glow = { 230, 240, 255 } },
	{ key = "darkness", name = "Darkness Fruit", rarity = "Epic", glow = { 150, 80, 220 } },
	{ key = "soul", name = "Soul Fruit", rarity = "Legendary", glow = { 255, 170, 220 } },
	{ key = "azure_dragon", name = "Azure Dragon Fruit", rarity = "Legendary", glow = { 95, 210, 238 } },
	{ key = "black_dragon", name = "Black Dragon Fruit", rarity = "Mythical", glow = { 255, 40, 40 } },
	{ key = "rubber", name = "Rubber Fruit", rarity = "Mythical", glow = { 255, 169, 138 } },
} :: { { key: string, name: string, rarity: string, glow: { number } } }

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
	OverheadLanterns = 3, -- lanterns hung under each overhead rope (ref R3)
	LaneLength = 800,
	BuoyEvery = 50, -- a landmark at least every ~50 studs along the lane
	SeaStackEvery = 160,
	LighthouseHeight = 64,
	LighthouseSpinSeconds = 8,
	CoveRadius = 150,
	CoveTerraces = 3,
	TerraceStep = 22,
}

-- Premium HUD + throw animation (2026-11-20 UI pass; mockups in project files
-- fruit-throw/ui-mockups-2026-11-20). Pure numbers; PremiumHUD, ThrowAnimator,
-- Motion, RarityStyle and ThrowPose read them.
Config.UI = {
	-- 3D buttons: a face over a darker base; pressing sinks the face this
	-- fraction of the button height (Brawl Stars style).
	ButtonDepth = 0.06,
	ButtonPressSeconds = 0.05,
	-- Extruded grade text: stacked copies, each this many px lower, darkest last.
	ExtrudeLayers = 3,
	ExtrudeStepPx = 4,
	RgbSplitPx = 5, -- red/cyan ghost copies on PERFECT and MASTERWORK
	RgbSplitSeconds = 0.25, -- the split closes to 0 over this long
	GradeHoldSeconds = 0.9,
	-- Distance plate: digits roll toward the real value.
	DigitRollRate = 14, -- 1/s exponential approach
	DigitMinStep = 0.4, -- m/s floor so it never crawls at the end
	-- Mythical rainbow: hue cycles per second.
	RainbowSpeed = 0.35,
	-- Fruit reveal after landing: climb the rarity ladder, then the card.
	RevealClimbStep = 0.16, -- seconds per rung
	RevealBloomFrom = "Legendary", -- star flare before the card from this tier up
	RevealBloomSeconds = 0.35,
	RevealHoldSeconds = 1.2,
	-- In-world 3D showcase (replaces the card, Sharman 2026-11-20): the real
	-- fruit model bursts out of the water and the aura climbs tier by tier.
	Showcase = {
		RiseSeconds = 0.6, -- out of the water up to the showcase spot
		StepSeconds = 0.55, -- per tier on the climb
		SlamSeconds = 0.4, -- final tier slam
		Hold = { Rare = 1.6, Epic = 2, Legendary = 2.5, Mythical = 3.2 },
		Flare = { Legendary = 0.7, Mythical = 1.1 }, -- ref M4: longer build = rarer
		ZoomSeconds = 0.55, -- ref M6: Mythical fills the screen, then settles
		Lift = 5, -- studs above the water the fruit hangs
		CameraDistance = 9.5,
		FruitSize = 3.4, -- studs across the model's widest side
		SpinRate = 1.3, -- rad/s
		RayLength = 11,
		DofFar = 0.85, -- DepthOfFieldEffect.FarIntensity: blurs the world, not the fruit (ref T2)
		TextLayers = 6, -- ref P7: 3D tier word, SurfaceGui slices stacked in depth
		TextDepth = 0.07, -- studs between slices
		RgbSplit = 0.18, -- studs the red/cyan ghosts start apart, closing to 0
	},
	-- Flight (ref M2): speed vignette + a zone name as the fruit passes it.
	-- Placeholder names from the dock map's landmarks; the One Piece arc
	-- names come from Sharman later.
	Zones = {
		{ from = 0, name = "THE DOCK" },
		{ from = 50, name = "BUOY LINE" },
		{ from = 160, name = "SEA STACKS" },
		{ from = 320, name = "LIGHTHOUSE" },
		{ from = 500, name = "OPEN SEA" },
	} :: { { from: number, name: string } },
	-- Our own painted VFX textures (assets/vfx, uploaded with Sharman's OK
	-- 2026-11-20). Empty = fall back to Roblox's default particle.
	Vfx = {
		Glow = "rbxassetid://117797148911057",
		Flare = "rbxassetid://113118035223287",
		Twinkle = "rbxassetid://91626104663682",
		Spark = "rbxassetid://72709512847650",
		Ring = "rbxassetid://70796318613160",
		Ray = "rbxassetid://131932157700274",
		Wisp = "rbxassetid://91203479420019",
	} :: { [string]: string },
	VignetteAlpha = 0.35, -- edge darkness at full flight speed (0 = black)
	RevealBlurSize = 18, -- BlurEffect.Size at the peak (world only; UI stays sharp)
	-- Meter anticipation: the body winds into the "set" pose as the marker
	-- climbs (front knee up, torso coiled, fruit by the ear). Radians at a full meter.
	ChargeLayback = 1.9, -- throwing forearm turned up behind the ear
	ChargeWaistTwist = 0.4, -- chest coils away from the lane
	ChargeLegLift = 1.5, -- front thigh raised
	-- Throw VFX on the character (ThrowAnimator).
	HeldOrbSize = 0.9, -- studs, the glowing fruit in the hand while charging
	ChargeAuraRate = 40, -- wind particles per second at a full meter
	TrailSeconds = 0.18, -- hand trail lifetime during the swing
	ReleaseFovKick = 6, -- degrees of field-of-view punch on release
	-- Fruit tumble in flight (radians per second at alpha 0, eases out).
	TumbleSpin = 14,
}

-- Shop + smart offers (2026-11-20, Sharman's "Smart Offer Method" video).
-- AssetId 0 = not created on Roblox yet (the shop shows it but cannot sell it).
-- Creating the passes/products on Roblox needs Sharman's OK first.
-- Prices are Robux and always shown in full before buying (vault/09).
-- Nothing here is random: no paid loot boxes (CLAUDE.md rule 7 stays moot).
Config.Shop = {
	Items = {
		-- Gamepasses: one-time, forever.
		DoubleTraining = {
			Kind = "GamePass",
			AssetId = 0,
			Price = 199,
			Name = "2x Training",
			Blurb = "Every dummy hit trains double Jump Power.",
			Cover = "DoubleTraining",
			Order = 1,
			Tab = "Boosts",
		},
		DoubleBerries = {
			Kind = "GamePass",
			AssetId = 0,
			Price = 149,
			Name = "2x Berries",
			Blurb = "Earn double Berries from every jump.",
			Cover = "DoubleBerries",
			Order = 2,
			Tab = "Boosts",
		},
		AutoTrain = {
			Kind = "GamePass",
			AssetId = 0,
			Price = 249,
			Name = "Auto Train",
			Blurb = "Your fighter keeps hitting the nearest dummy for you.",
			Cover = "AutoTrain",
			Order = 3,
			Tab = "Boosts",
		},
		FruitVault = {
			Kind = "GamePass",
			AssetId = 0,
			Price = 99,
			Name = "Fruit Vault +20",
			Blurb = "20 more slots to keep every fruit you find.",
			Cover = "FruitVault",
			Order = 4,
			Tab = "Boosts",
		},
		VIPCaptain = {
			Kind = "GamePass",
			AssetId = 0,
			Price = 299,
			Name = "VIP Captain",
			Blurb = "Gold captain nameplate, VIP flag on your launch rock, gold chat tag.",
			Cover = "VIPCaptain",
			Order = 5,
			Tab = "Style",
		},
		HakiTrail = {
			Kind = "GamePass",
			AssetId = 0,
			Price = 149,
			Name = "Haki Lightning Trail",
			Blurb = "Black and red lightning follows your dive.",
			Cover = "HakiTrail",
			Order = 6,
			Tab = "Style",
		},
		GoldenSplash = {
			Kind = "GamePass",
			AssetId = 0,
			Price = 99,
			Name = "Golden Splash",
			Blurb = "Your water landing bursts into a gold coin crown.",
			Cover = "GoldenSplash",
			Order = 7,
			Tab = "Style",
		},
		CloudTrail = {
			Kind = "GamePass",
			AssetId = 0,
			Price = 149,
			Name = "Sky Cloud Trail",
			Blurb = "Fluffy white clouds puff behind every jump.",
			Cover = "CloudTrail",
			Order = 8,
			Tab = "Style",
		},
		-- Developer products: repeatable.
		JumpSurge = {
			Kind = "Product",
			AssetId = 0,
			Price = 49,
			Name = "Jump Surge (15 min)",
			Blurb = "+25% jump distance for 15 minutes.",
			Cover = "JumpSurge",
			Order = 9,
			Tab = "Berries",
		},
		BerryPouch = {
			Kind = "Product",
			AssetId = 0,
			Price = 39,
			Name = "Berry Pouch",
			Blurb = "10,000 Berries.",
			Berries = 10000,
			Cover = "BerryPouch",
			Order = 10,
			Tab = "Berries",
		},
		BerryChest = {
			Kind = "Product",
			AssetId = 0,
			Price = 149,
			Name = "Berry Chest",
			Blurb = "60,000 Berries.",
			Berries = 60000,
			Cover = "BerryChest",
			Order = 11,
			Tab = "Berries",
		},
		BerryHoard = {
			Kind = "Product",
			AssetId = 0,
			Price = 499,
			Name = "Treasure Hoard",
			Blurb = "400,000 Berries.",
			Berries = 400000,
			Cover = "BerryHoard",
			Order = 12,
			Tab = "Berries",
		},
	} :: { [string]: ShopItem },
	Tabs = { "Boosts", "Style", "Berries" },
	Offers = {
		GraceSeconds = 180, -- never in the first 3 minutes (never on join)
		CooldownSeconds = 240, -- at most one offer every 4 minutes
		MaxPerSession = 3,
		SnoozeSeconds = 1800, -- "Not now" hides that item for 30 minutes
		DismissLimit = 2, -- two "Not now"s and that item is done for the session
		AfterPurchaseQuietSeconds = 300, -- no offers for 5 minutes after any purchase
		NearMissFraction = 0.15, -- jump within 15% of the next arc
		ShortStreakForTraining = 3,
		LongTrainingSeconds = 600,
		CelebrationItems = { "GoldenSplash", "HakiTrail", "CloudTrail" },
		AutoCloseSeconds = 12, -- the card quietly slides away if ignored (counts as "Not now")
	},
	-- Cover art per item.Cover. Empty = the built-in placeholder cover. Real
	-- covers wait for Sharman's OK on the reference board (standing rule).
	CoverImages = {} :: { [string]: string },
	Sounds = {
		Open = "rbxasset://sounds/electronicpingshort.wav",
		Offer = "rbxasset://sounds/electronicpingshort.wav",
	},
	Motion = {
		PanelOpen = 0.25,
		PanelClose = 0.18,
		OfferSlide = 0.35,
		RaySpinDegPerSec = 25,
		MenuBlur = 18,
	},
}

return table.freeze(Config)
