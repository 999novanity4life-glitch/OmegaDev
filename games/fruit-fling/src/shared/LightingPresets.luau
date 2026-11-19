--!strict
-- Look presets as plain data: Lighting, Atmosphere and post-effect values.
-- Pure module (no services), so presets can be validated and blended in Lune
-- tests. LookController (client) applies them to the real instances.
--
-- Tags on each preset's `source`:
--   [DOC]      numbers copied from a Roblox Creator Hub course or page (URL given)
--   [INFERRED] our own starting point, reasoned from the docs; tune in Studio
-- A field left out means "leave whatever the place has". Colors are 0-255 RGB.

export type RGB = { number }

export type LightingProps = {
	ClockTime: number?,
	Brightness: number?,
	ExposureCompensation: number?,
	Ambient: RGB?,
	OutdoorAmbient: RGB?,
	ColorShift_Top: RGB?,
	EnvironmentDiffuseScale: number?,
	EnvironmentSpecularScale: number?,
	ShadowSoftness: number?,
	GeographicLatitude: number?,
}

export type AtmosphereProps = {
	Density: number?,
	Offset: number?,
	Color: RGB?,
	Decay: RGB?,
	Glare: number?,
	Haze: number?,
}

export type BloomProps = { Intensity: number?, Size: number?, Threshold: number? }
export type SunRaysProps = { Intensity: number?, Spread: number? }
export type ColorCorrectionProps = {
	Brightness: number?,
	Contrast: number?,
	Saturation: number?,
	TintColor: RGB?,
}

export type Preset = {
	name: string,
	source: string,
	-- "Realistic" or "Soft". A place setting: set it in default.project.json too,
	-- because scripts may not be allowed to write it (see LookController).
	lightingStyle: string?,
	lighting: LightingProps,
	atmosphere: AtmosphereProps?,
	bloom: BloomProps?,
	sunRays: SunRaysProps?,
	colorCorrection: ColorCorrectionProps?,
}

local LightingPresets = {}

local PRESETS: { [string]: Preset } = {
	-- [DOC] Creator Hub "Enhance outdoor environments" (sunset tutorial):
	-- https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-outdoor-environments
	RobloxOutdoorSunset = {
		name = "RobloxOutdoorSunset",
		source = "[DOC] create.roblox.com tutorials/use-case-tutorials/lighting/enhance-outdoor-environments",
		lightingStyle = "Realistic",
		lighting = {
			ClockTime = 17,
			Ambient = { 156, 136, 176 },
			OutdoorAmbient = { 156, 136, 176 },
			EnvironmentDiffuseScale = 1,
			EnvironmentSpecularScale = 1,
		},
		atmosphere = {
			Density = 0.272,
			Haze = 1,
			Color = { 85, 78, 54 },
		},
	},
	-- [DOC] Creator Hub "Enhance indoor environments" (warm afternoon room):
	-- https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-indoor-environments
	RobloxIndoorWarm = {
		name = "RobloxIndoorWarm",
		source = "[DOC] create.roblox.com tutorials/use-case-tutorials/lighting/enhance-indoor-environments",
		lightingStyle = "Realistic",
		lighting = {
			ClockTime = 15.6,
			Ambient = { 83, 70, 57 },
			EnvironmentDiffuseScale = 1,
			EnvironmentSpecularScale = 1,
			ExposureCompensation = 0.5,
		},
		atmosphere = { Density = 0.5 },
		sunRays = { Intensity = 0.023, Spread = 0.266 },
		colorCorrection = { Contrast = 0.05, Saturation = 0.1 },
	},
	-- [DOC] Creator Hub environmental art course, sci-fi laser tag arena:
	-- https://create.roblox.com/docs/tutorials/curriculums/environmental-art
	RobloxSciFiArena = {
		name = "RobloxSciFiArena",
		source = "[DOC] create.roblox.com tutorials/curriculums/environmental-art",
		lightingStyle = "Realistic",
		lighting = {
			Ambient = { 26, 34, 36 },
			OutdoorAmbient = { 26, 34, 36 },
			ShadowSoftness = 0.15,
			GeographicLatitude = -18,
		},
		atmosphere = {
			Density = 0.285,
			Offset = 0.65,
			Decay = { 254, 254, 254 },
			Glare = 0.3,
			Haze = 2,
		},
		bloom = { Intensity = 1.5, Size = 56 },
	},
	-- [INFERRED] No air: no haze or atmosphere scattering, hard black-ish
	-- shadows, harsh sun. Warm light/cool shadow rule from the DatBoiEle
	-- lighting video (docs/research/videos-2026-10-28/26). Tune in Studio.
	AirlessMoon = {
		name = "AirlessMoon",
		source = "[INFERRED] see docs/research/videos-2026-10-28/26-advanced-lighting-tutorial.md",
		lightingStyle = "Realistic",
		lighting = {
			ClockTime = 9,
			Ambient = { 8, 9, 14 },
			OutdoorAmbient = { 18, 20, 30 },
			ColorShift_Top = { 255, 244, 225 },
			EnvironmentDiffuseScale = 0.2,
			EnvironmentSpecularScale = 1,
			ShadowSoftness = 0,
			ExposureCompensation = 0.3,
		},
		atmosphere = { Density = 0, Haze = 0, Glare = 0 },
		bloom = { Intensity = 0.4, Size = 40, Threshold = 1.5 },
		colorCorrection = { Contrast = 0.1, Saturation = -0.2 },
	},
}

for _, preset in PRESETS do
	table.freeze(preset)
end

function LightingPresets.get(name: string): Preset?
	return PRESETS[name]
end

function LightingPresets.names(): { string }
	local list = {}
	for name in PRESETS do
		table.insert(list, name)
	end
	table.sort(list)
	return list
end

-- Ranges we have verified in the engine API reference. Anything not listed is
-- only checked for being a finite number.
local RANGES: { [string]: { number } } = {
	["lighting.ClockTime"] = { 0, 24 },
	["lighting.ExposureCompensation"] = { -5, 5 },
	["lighting.ShadowSoftness"] = { 0, 1 },
	["lighting.EnvironmentDiffuseScale"] = { 0, 1 },
	["lighting.EnvironmentSpecularScale"] = { 0, 1 },
	["atmosphere.Density"] = { 0, 1 },
	["atmosphere.Offset"] = { 0, 1 },
	["atmosphere.Glare"] = { 0, 10 },
	["atmosphere.Haze"] = { 0, 10 },
}

local SECTIONS = { "lighting", "atmosphere", "bloom", "sunRays", "colorCorrection" }

local function isFinite(n: number): boolean
	return n == n and n ~= math.huge and n ~= -math.huge
end

local function isRGB(value: any): boolean
	if type(value) ~= "table" or #value ~= 3 then
		return false
	end
	for _, c in value do
		if type(c) ~= "number" or not isFinite(c) or c < 0 or c > 255 then
			return false
		end
	end
	return true
end

-- Returns a list of problems; an empty list means the preset is usable.
function LightingPresets.validate(preset: Preset): { string }
	local problems = {}
	if preset.lightingStyle ~= nil and preset.lightingStyle ~= "Realistic" and preset.lightingStyle ~= "Soft" then
		table.insert(problems, "lightingStyle must be Realistic or Soft")
	end
	for _, section in SECTIONS do
		-- any: look a section up by name; each section is a record of numbers or RGB.
		local props = (preset :: any)[section]
		if props == nil then
			continue
		end
		for key, value in props do
			local path = section .. "." .. key
			if type(value) == "table" then
				if not isRGB(value) then
					table.insert(problems, path .. " must be three 0-255 numbers")
				end
			elseif type(value) ~= "number" or not isFinite(value) then
				table.insert(problems, path .. " must be a finite number")
			else
				local range = RANGES[path]
				if range and (value < range[1] or value > range[2]) then
					table.insert(problems, string.format("%s=%g outside %g..%g", path, value, range[1], range[2]))
				end
			end
		end
	end
	-- Glare and Decay only show when Haze > 0 (Atmosphere API reference).
	local atmo = preset.atmosphere
	if atmo and (atmo.Glare or 0) > 0 and (atmo.Haze or 0) <= 0 then
		table.insert(problems, "atmosphere.Glare has no effect while Haze is 0")
	end
	return problems
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Sections are typed records; blending walks them generically by key, so the
-- casts to `any` below are deliberate (the output keeps the same keys).
local function blendSection(a: { [string]: any }?, b: { [string]: any }?, t: number): { [string]: any }?
	if a == nil and b == nil then
		return nil
	end
	local out: { [string]: any } = table.clone(a or {})
	local to: { [string]: any } = b or {}
	for key, bValue in to do
		local aValue = out[key]
		if aValue == nil then
			out[key] = bValue
		elseif type(bValue) == "table" then
			out[key] = { lerp(aValue[1], bValue[1], t), lerp(aValue[2], bValue[2], t), lerp(aValue[3], bValue[3], t) }
		else
			out[key] = lerp(aValue, bValue, t)
		end
	end
	return out
end

-- Mix two presets for zone transitions (t = 0 gives a, t = 1 gives b).
-- A field present in only one preset is held at that value.
function LightingPresets.blend(a: Preset, b: Preset, t: number): Preset
	t = math.clamp(if t == t then t else 0, 0, 1)
	return {
		name = if t < 0.5 then a.name else b.name,
		source = "blend",
		lightingStyle = if t < 0.5 then a.lightingStyle else b.lightingStyle,
		lighting = blendSection(a.lighting :: any, b.lighting :: any, t) :: any,
		atmosphere = blendSection(a.atmosphere :: any, b.atmosphere :: any, t) :: any,
		bloom = blendSection(a.bloom :: any, b.bloom :: any, t) :: any,
		sunRays = blendSection(a.sunRays :: any, b.sunRays :: any, t) :: any,
		colorCorrection = blendSection(a.colorCorrection :: any, b.colorCorrection :: any, t) :: any,
	}
end

return table.freeze(LightingPresets)
