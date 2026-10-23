--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Validate = require(Shared:WaitForChild("Validate"))
local RemoteGuard = require(script.Services.RemoteGuard)

local requestAction = Remotes.get("RequestAction")
local stateChanged = Remotes.get("StateChanged")

local VALID_ACTIONS = { Click = true }

RemoteGuard.connect(requestAction, function(action: any)
	return Validate.oneOf(action, VALID_ACTIONS)
end, function(player: Player, action: string)
	-- Replace with real game logic. Server decides the outcome, client only asks.
	stateChanged:FireClient(player, action, "ok")
end)
