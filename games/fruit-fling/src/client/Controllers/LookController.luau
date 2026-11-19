--!strict
-- Applies LightingPresets to Lighting on this client and blends between them
-- when the player changes zone. Lighting changes made on the client are local,
-- so each player can stand in a different zone's look.
-- Not yet run in Studio: verify with docs/VISUAL_QA.md before relying on it.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LightingPresets = require(Shared:WaitForChild("LightingPresets"))

type Preset = LightingPresets.Preset
type RGB = LightingPresets.RGB

local LookController = {}

local PREFIX = "OmegaLook"
local current: Preset? = nil
local blendConnection: RBXScriptConnection? = nil

local function toColor(c: RGB): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function ensure(className: string, suffix: string): Instance
	local name = PREFIX .. suffix
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

-- Write each field onto the instance. Values are numbers or RGB triples from
-- the preset; keys were checked by LightingPresets.validate.
local function write(inst: Instance, props: { [string]: number | RGB })
	for key, value in props do
		-- any: property names come from the typed preset, not the network.
		(inst :: any)[key] = if type(value) == "table" then toColor(value) else value
	end
end

-- Studio's starter places ship Bloom, SunRays, DepthOfField, a Sky and an
-- Atmosphere. Stacked on a preset they wash the scene out, so switch effects
-- off and park extra Atmospheres in a folder (same pattern as slime-rise).
function LookController.retireStarterEffects()
	local parked = Lighting:FindFirstChild("UnusedStarterEffects") or Instance.new("Folder")
	parked.Name = "UnusedStarterEffects"
	parked.Parent = Lighting
	for _, inst in Lighting:GetChildren() do
		if string.sub(inst.Name, 1, #PREFIX) == PREFIX then
			continue
		end
		if inst:IsA("PostEffect") then
			inst.Enabled = false
		elseif inst:IsA("Atmosphere") then
			inst.Parent = parked
		end
	end
end

function LookController.apply(preset: Preset)
	current = preset
	if preset.lightingStyle and preset.source ~= "blend" then
		-- LightingStyle is also set in default.project.json. Writing it from a
		-- script may be refused, so a failure here is expected and harmless.
		pcall(function()
			(Lighting :: any).LightingStyle = (Enum :: any).LightingStyle[preset.lightingStyle]
		end)
	end
	write(Lighting, preset.lighting :: any)
	if preset.atmosphere then
		write(ensure("Atmosphere", "Atmosphere"), preset.atmosphere :: any)
	end
	local sections: { { string } } = {
		{ "bloom", "BloomEffect", "Bloom" },
		{ "sunRays", "SunRaysEffect", "SunRays" },
		{ "colorCorrection", "ColorCorrectionEffect", "ColorCorrection" },
	}
	for _, s in sections do
		-- any: index the preset by section name (see LightingPresets.blend).
		local props = (preset :: any)[s[1]]
		local existing = Lighting:FindFirstChild(PREFIX .. s[3])
		if props then
			local effect = ensure(s[2], s[3]) :: PostEffect
			effect.Enabled = true
			write(effect, props)
		elseif existing and existing:IsA("PostEffect") then
			existing.Enabled = false
		end
	end
end

function LookController.applyByName(name: string)
	local preset = LightingPresets.get(name)
	if preset then
		LookController.apply(preset)
	else
		warn("LookController: unknown preset " .. name)
	end
end

-- Blend from the current look to another preset over `seconds`. Reduced
-- Motion players get the new look at once.
function LookController.blendTo(name: string, seconds: number?)
	local target = LightingPresets.get(name)
	if not target then
		warn("LookController: unknown preset " .. name)
		return
	end
	if blendConnection then
		blendConnection:Disconnect()
		blendConnection = nil
	end
	local from = current
	local duration = seconds or Config.Look.ZoneBlendSeconds
	if from == nil or duration <= 0 or GuiService.ReducedMotionEnabled then
		LookController.apply(target)
		return
	end
	local elapsed = 0
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(dt: number)
		elapsed += dt
		local t = math.min(1, elapsed / duration)
		-- smoothstep so the change eases in and out
		LookController.apply(LightingPresets.blend(from, target, t * t * (3 - 2 * t)))
		if t >= 1 then
			connection:Disconnect()
			blendConnection = nil
			current = target
		end
	end)
	blendConnection = connection
end

function LookController.start()
	LookController.retireStarterEffects()
	LookController.applyByName(Config.Look.Preset)
end

return LookController
