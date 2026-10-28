--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local _Juice = require(script.Controllers.Juice)
local LookController = require(script.Controllers.LookController)

-- Lighting, Atmosphere and post effects from Config.Look (see vault/15).
LookController.start()

local stateChanged = Remotes.get("StateChanged")

stateChanged.OnClientEvent:Connect(function(action: string, result: string)
	-- Server confirmed. Play the confirmation feedback here.
	print(action, result)
end)
