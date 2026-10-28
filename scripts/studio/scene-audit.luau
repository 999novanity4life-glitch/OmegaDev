--!strict
-- Scene audit for docs/VISUAL_QA.md. Paste into the Studio MCP `execute_luau`
-- tool (Edit or Server datamodel). Read-only: it changes nothing and returns a
-- plain-text report the visual reviewer reads next to the screenshots.
-- Not yet run in Studio (written 2026-10-28); report any API error it raises.

local Lighting = game:GetService("Lighting")
local MaterialService = game:GetService("MaterialService")

local lines: { string } = {}
local function add(fmt: string, ...: any)
	table.insert(lines, string.format(fmt, ...))
end
local function rgb(c: Color3): string
	return string.format("%d,%d,%d", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
end

add("LIGHTING")
add("  LightingStyle=%s PrioritizeLightingQuality=%s", tostring(Lighting.LightingStyle), tostring(Lighting.PrioritizeLightingQuality))
add("  ClockTime=%.2f Brightness=%.2f ExposureCompensation=%.2f", Lighting.ClockTime, Lighting.Brightness, Lighting.ExposureCompensation)
add("  Ambient=%s OutdoorAmbient=%s", rgb(Lighting.Ambient), rgb(Lighting.OutdoorAmbient))
add("  EnvironmentDiffuseScale=%.2f EnvironmentSpecularScale=%.2f", Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale)
add("  GlobalShadows=%s ShadowSoftness=%.2f", tostring(Lighting.GlobalShadows), Lighting.ShadowSoftness)

local skies, atmospheres = 0, 0
for _, child in Lighting:GetChildren() do
	if child:IsA("Sky") then
		skies += 1
	elseif child:IsA("Atmosphere") then
		atmospheres += 1
		add(
			"  Atmosphere %s: Density=%.3f Offset=%.3f Haze=%.2f Glare=%.2f Color=%s Decay=%s",
			child.Name,
			child.Density,
			child.Offset,
			child.Haze,
			child.Glare,
			rgb(child.Color),
			rgb(child.Decay)
		)
	elseif child:IsA("PostEffect") then
		add("  %s %s Enabled=%s", child.ClassName, child.Name, tostring(child.Enabled))
	end
end
add("  Sky objects=%d Atmosphere objects=%d (more than one of either is a smell)", skies, atmospheres)

local parts, meshParts, transparent, shadowCasters, anchoredOff = 0, 0, 0, 0, 0
local surfaceAppearances, textured = 0, 0
local lights, shadowLights = 0, 0
local materials: { [string]: number } = {}
for _, inst in workspace:GetDescendants() do
	if inst:IsA("BasePart") then
		parts += 1
		if inst:IsA("MeshPart") then
			meshParts += 1
			if inst.TextureID ~= "" then
				textured += 1
			end
		end
		if inst.Transparency > 0 and inst.Transparency < 1 then
			transparent += 1
		end
		if inst.CastShadow then
			shadowCasters += 1
		end
		if not inst.Anchored then
			anchoredOff += 1
		end
		local key = inst.Material.Name .. (if inst.MaterialVariant ~= "" then "/" .. inst.MaterialVariant else "")
		materials[key] = (materials[key] or 0) + 1
	elseif inst:IsA("SurfaceAppearance") then
		surfaceAppearances += 1
	elseif inst:IsA("Light") then
		lights += 1
		if inst.Shadows then
			shadowLights += 1
		end
	end
end

add("WORKSPACE")
add("  BaseParts=%d MeshParts=%d unanchored=%d", parts, meshParts, anchoredOff)
add("  semi-transparent parts=%d (overdraw risk when stacked)", transparent)
add("  CastShadow on=%d of %d", shadowCasters, parts)
add("  SurfaceAppearance=%d MeshParts with TextureID=%d", surfaceAppearances, textured)
add("  Lights=%d with Shadows=%d", lights, shadowLights)

local sorted: { { name: string, n: number } } = {}
for name, n in materials do
	table.insert(sorted, { name = name, n = n })
end
table.sort(sorted, function(a, b)
	return a.n > b.n
end)
add("  Materials in use=%d (top 10):", #sorted)
for i = 1, math.min(10, #sorted) do
	add("    %5d  %s", sorted[i].n, sorted[i].name)
end

local variants = 0
for _, inst in MaterialService:GetDescendants() do
	if inst:IsA("MaterialVariant") then
		variants += 1
	end
end
add("MaterialService MaterialVariants=%d", variants)

local terrain = workspace.Terrain
add("TERRAIN Decoration=%s WaterColor=%s", tostring(terrain.Decoration), rgb(terrain.WaterColor))

return table.concat(lines, "\n")
