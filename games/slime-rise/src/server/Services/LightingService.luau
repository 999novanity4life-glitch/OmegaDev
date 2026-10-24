--!strict
-- Lab mood: a dark facility with cold ambient light, green haze and bloom
-- on neon. Runtime-safe Lighting properties only.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local LightingService = {}

local function ensure(className: string, name: string): Instance
	local existing = Lighting:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = Lighting
	return inst
end

-- The place still carries Studio's starter effects (a strong Bloom, SunRays,
-- Depth of Field, a second Sky and Atmosphere). Stacked on the lab look they
-- wash every white surface out. Switch them off without deleting anything:
-- effects get Enabled = false, and the extra Sky/Atmosphere move into a
-- folder, where Roblox ignores them.
local function retireStarterEffects()
	local parked = Lighting:FindFirstChild("UnusedStarterEffects") or Instance.new("Folder")
	parked.Name = "UnusedStarterEffects"
	parked.Parent = Lighting
	for _, inst in Lighting:GetChildren() do
		if string.sub(inst.Name, 1, 3) == "Lab" or inst.Name == "ThemeGrade" then
			continue
		end
		if inst:IsA("PostEffect") then
			inst.Enabled = false
		elseif inst:IsA("Sky") or inst:IsA("Atmosphere") then
			inst.Parent = parked
		end
	end
end

function LightingService.start()
	local cfg = Config.Lighting
	retireStarterEffects()
	-- LightingStyle (Realistic) and PrioritizeLightingQuality are place
	-- settings that game scripts can't write: see default.project.json.
	Lighting.Ambient = cfg.Ambient
	Lighting.OutdoorAmbient = cfg.OutdoorAmbient
	Lighting.Brightness = cfg.Brightness
	Lighting.ClockTime = cfg.ClockTime
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.EnvironmentSpecularScale = 0.8
	Lighting.GlobalShadows = true
	-- Realistic lighting reflects and ambient-lights from the skybox even
	-- indoors. The legacy sky512 default floods the lab with day-blue light;
	-- Roblox's current skybox at midnight keeps the interior calm.
	local sky = ensure("Sky", "LabSky") :: Sky
	sky.SkyboxBk = "rbxassetid://6444884337"
	sky.SkyboxDn = "rbxassetid://6444884785"
	sky.SkyboxFt = "rbxassetid://6444884337"
	sky.SkyboxLf = "rbxassetid://6444884337"
	sky.SkyboxRt = "rbxassetid://6444884337"
	sky.SkyboxUp = "rbxassetid://6412503613"
	sky.StarCount = 0
	sky.CelestialBodiesShown = false
	local atmosphere = ensure("Atmosphere", "LabAtmosphere") :: Atmosphere
	atmosphere.Density = 0.22
	atmosphere.Offset = 0.1
	atmosphere.Color = cfg.AtmosphereColor
	atmosphere.Decay = cfg.FogColor
	atmosphere.Glare = 0
	atmosphere.Haze = cfg.Haze
	local bloom = ensure("BloomEffect", "LabBloom") :: BloomEffect
	bloom.Intensity = cfg.Bloom
	bloom.Size = 20
	bloom.Threshold = 2.1
	local grade = ensure("ColorCorrectionEffect", "LabGrade") :: ColorCorrectionEffect
	grade.Contrast = 0.12
	grade.Saturation = 0.15
	grade.TintColor = Color3.fromRGB(235, 255, 240)
end

return LightingService
