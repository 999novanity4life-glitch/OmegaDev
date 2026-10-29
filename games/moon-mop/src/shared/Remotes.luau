--!strict
-- Single source of truth for remote names. The server creates them; the client waits.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	-- client -> server: intent only, always validated server-side
	"ToolIntent", -- ("on" | "off" | "equip", slot?)
	"Pack", -- press Q: pack the Dust Pack into a pod
	"Buy", -- (kind, id, extra?)
	"Teleport", -- (stationIndex)
	"Waypoint", -- ("add", dir) | ("clear", index)
	"VehicleIntent", -- ("spawn" | "store" | "enter" | "exit" | "dial" | "lights", arg?)
	"VehicleReport", -- driver's stunt report (flips, spins, airTime), checked against physics
	"BuildIntent", -- ("place" | "remove" | "belt", ...)
	"Customize", -- (visorStyle, suitColour)
	"Gear", -- ("jetpack" | "boots" | "nightvision", on)
	"Story", -- ("hired") when the hiring cutscene finishes
	-- server -> client
	"State", -- the player's authoritative state (money, pack, tools...)
	"Feedback", -- (kind, data): rewards, toasts, errors, unlocks
	"MoonSnapshot", -- (completedSectors: buffer, partialPatches: buffer) on join
	"MoonDelta", -- (patches: buffer, sectorsDone: buffer, sectorsRedusted: buffer)
	"WorldEvent", -- (kind, data): meteor warnings, launches, region completes
}

local FOLDER_NAME = "Remotes"

local Remotes = {}

function Remotes.get(name: string): RemoteEvent
	assert(table.find(NAMES, name), "unknown remote: " .. name)
	local folder: Instance
	if RunService:IsServer() then
		folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME) or Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		local existing = folder:FindFirstChild(name)
		if existing then
			return existing :: RemoteEvent
		end
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		return remote
	end
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	return folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
