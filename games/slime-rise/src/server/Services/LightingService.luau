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

function LightingService.start()
	local cfg = Config.Lighting
	Lighting.Ambient = cfg.Ambient
	Lighting.OutdoorAmbient = cfg.OutdoorAmbient
	Lighting.Brightness = cfg.Brightness
	Lighting.ClockTime = cfg.ClockTime
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.EnvironmentSpecularScale = 0.8
	Lighting.GlobalShadows = true
	local sky = ensure("Sky", "LabSky") :: Sky
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
	bloom.Size = 30
	bloom.Threshold = 1.4
	local grade = ensure("ColorCorrectionEffect", "LabGrade") :: ColorCorrectionEffect
	grade.Contrast = 0.12
	grade.Saturation = 0.15
	grade.TintColor = Color3.fromRGB(235, 255, 240)
end

return LightingService
