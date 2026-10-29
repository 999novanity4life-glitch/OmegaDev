--!strict
-- Moon Mop Co. server. Services start in dependency order; each one wires its own remotes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Meshes the clients need (the cleaned-hex tile) go to ReplicatedStorage.Assets.
do
	local assets = ReplicatedStorage:FindFirstChild("Assets") or Instance.new("Folder")
	assets.Name = "Assets"
	local kit = ServerStorage:FindFirstChild("MoonMopKit")
	local dustHex = kit and kit:FindFirstChild("DustHex")
	local hex = dustHex and dustHex:FindFirstChild("Hex")
	if hex and not assets:FindFirstChild("Hex") then
		local copy = hex:Clone()
		copy.Name = "Hex"
		copy.Parent = assets
	end
	assets.Parent = ReplicatedStorage
end

local Services = script.Services
local Moon = require(Services.Moon)
require(Services.Data)
require(Services.Crew)
require(Services.Sky)
require(Services.Dust)
require(Services.Shop)
require(Services.Stations)
require(Services.Finds)
require(Services.Base)
require(Services.Vehicles)

print(string.format("[MoonMop] Moon ready: %d sectors, %d patches", Moon.sector.count, Moon.patch.count))
