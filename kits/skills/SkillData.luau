-- SkillData: every skill is data. Gameplay numbers live here; looks live in Themes.
-- Swapping a theme reskins every skill (colours, labels) without touching code.
-- Lives at ReplicatedStorage.Skills.SkillData.
local SkillData = {}

-- Standard skill shapes seen across the top BuiltByBit packs: Projectile, Ground/AoE, Dash.
SkillData.Order = { "Bolt", "Slam", "Dash" }
SkillData.Skills = {
	Bolt = { shape = "Projectile", key = Enum.KeyCode.Q, cooldown = 1.2, castTime = 0.3, speed = 70, range = 60, radius = 1.5, damage = 15, knock = 40 },
	Slam = { shape = "Ground", key = Enum.KeyCode.E, cooldown = 4, castTime = 0.42, radius = 14, damage = 25, knock = 55, lift = 35 },
	Dash = { shape = "Dash", key = Enum.KeyCode.R, cooldown = 2.5, castTime = 0.05, distance = 24, duration = 0.22, radius = 4, damage = 10, knock = 30 },
}

SkillData.Themes = {
	Amber = {
		game = "Dig a Dino",
		primary = Color3.fromHex("#FFB23F"), -- amber
		secondary = Color3.fromHex("#3DFFB5"), -- relic jade
		dust = Color3.fromHex("#C99A6B"), -- sandstone
		shard = Color3.fromHex("#8C5A3C"),
		labels = { Bolt = "Amber Bolt", Slam = "Fossil Slam", Dash = "Raptor Dash" },
	},
	Dream = {
		game = "Steal a Dream",
		primary = Color3.fromHex("#9F96FF"),
		secondary = Color3.fromHex("#7CF5FF"),
		dust = Color3.fromHex("#D6CCF5"),
		shard = Color3.fromHex("#FFE066"),
		labels = { Bolt = "Dream Bolt", Slam = "Pillow Quake", Dash = "Sleepwalk Dash" },
	},
}
SkillData.ThemeOrder = { "Amber", "Dream" }

return SkillData
