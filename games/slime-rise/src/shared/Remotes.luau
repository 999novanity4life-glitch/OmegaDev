--!strict
-- Single source of truth for remote names. The server creates them; the client waits.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"UsePower", -- client -> server: power id (+ grapple target), validated server-side
	"PowerFx", -- server -> all clients: someone used a power, play its effect
	"Notify", -- server -> client: escaped, slimed, results, cutscenes, puzzle events
	"PartyAction", -- client -> server: elevator host picks mode / max size / go
	"MiniGame", -- client -> server: puzzle move (rotate pipe, connect wire, press pad)
	"SkipIntro", -- client -> server: done watching a repeat intro (no payload)
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
