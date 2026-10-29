--!nocheck
-- Run once in Studio (Edit datamodel, MCP execute_luau). Copies the MoonRegolith terrain look
-- onto Basalt as "MoonBedrock" and makes it Basalt's look, so cleaned ground (MoonView repaints
-- Ground to Basalt) shows the same regolith texture, tinted darker. Game scripts lack the
-- capability to write MaterialVariant.BaseMaterial, so this has to live in the place.
local MaterialService = game:GetService("MaterialService")
local regolith = MaterialService:FindFirstChild("MoonRegolith", true)
assert(regolith and regolith:IsA("MaterialVariant"), "MoonRegolith variant missing")
local old = MaterialService:FindFirstChild("MoonBedrock")
if old then
	old:Destroy()
end
local bedrock = regolith:Clone()
bedrock.Name = "MoonBedrock"
bedrock.BaseMaterial = Enum.Material.Basalt
bedrock.Parent = MaterialService
MaterialService:SetBaseMaterialOverride(Enum.Material.Basalt, "MoonBedrock")
return "MoonBedrock ready"
