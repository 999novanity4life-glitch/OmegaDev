--!strict
-- Run in Studio through the MCP `execute_luau` tool (edit mode is fine).
-- Paste candidate IDs below; prints PASS/FAIL per ID. PASS = an audio asset
-- (AssetTypeId 3) created by the Roblox account. Uses
-- MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset)
-- (https://create.roblox.com/docs/reference/engine/classes/MarketplaceService#GetProductInfo).

local MarketplaceService = game:GetService("MarketplaceService")

local CANDIDATES: { [string]: number } = {
	-- release_whoosh = 0,
}

for cue, id in CANDIDATES do
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset)
	end)
	if not ok or type(info) ~= "table" then
		print(`FAIL {cue} {id}: lookup failed ({info})`)
		continue
	end
	local creator = info.Creator and info.Creator.Name or "?"
	local isAudio = info.AssetTypeId == 3
	local byRoblox = creator == "Roblox"
	print(
		`{if isAudio and byRoblox then "PASS" else "FAIL"} {cue} {id} "{info.Name}" by {creator} type {info.AssetTypeId}`
	)
end
