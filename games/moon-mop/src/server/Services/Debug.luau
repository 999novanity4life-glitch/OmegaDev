--!strict
-- Studio-only test hooks for playtests driven from outside (the Studio MCP). Code run from the
-- command bar gets its own copies of modules, so it can't touch the live services directly;
-- this BindableFunction runs inside them. Never created in a live server.

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Crew = require(script.Parent.Crew)

local Debug = {}

if RunService:IsStudio() then
	local fn = Instance.new("BindableFunction")
	fn.Name = "MoonMopDebug"
	fn.OnInvoke = function(cmd: string, arg: any): any
		local player = Players:GetPlayers()[1]
		local s = player and Crew.get(player)
		if not s then
			return "no session"
		end
		local d = s.data
		if cmd == "grant" then
			d.hired = true
			d.money = (arg :: number?) or 100000
			d.buildTool = true
			for _, t in Config.Tools do
				d.tools[t.id] = true
			end
			for _, v in Config.Vehicles do
				d.vehicles[v.id] = d.vehicles[v.id] or {}
			end
			s.dirty = true
			return "granted"
		elseif cmd == "money" then
			d.money = arg :: number
			s.dirty = true
			return d.money
		elseif cmd == "stats" then
			return game:GetService("HttpService"):JSONEncode(d.stats)
		elseif cmd == "tank" then
			s.tankKg = arg :: number
			return s.tankKg
		elseif cmd == "pack" then
			s.packKg = arg :: number
			s.dirty = true
			return s.packKg
		elseif cmd == "state" then
			return string.format(
				"money %.2f plot %d buildings %d vehicle %s tank %.2f pack %.2f pods %d",
				d.money,
				d.plot,
				#d.buildings,
				tostring(s.vehicleId),
				s.tankKg,
				s.packKg,
				#s.pods
			)
		end
		return "unknown command"
	end
	fn.Parent = ServerStorage
end

return Debug
