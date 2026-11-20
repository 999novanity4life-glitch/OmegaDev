--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local DockBuilder = require(script.Services.DockBuilder)
local Lane = require(script.Services.Lane)
local ThrowService = require(script.Services.ThrowService)

if Config.Dock.Enabled then
	DockBuilder.build()
else
	Lane.build()
end
ThrowService.start()
