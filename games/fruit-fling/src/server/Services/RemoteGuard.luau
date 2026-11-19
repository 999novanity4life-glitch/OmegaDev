--!strict
-- Wraps RemoteEvent handlers: rate limits per player and rejects bad payloads
-- before game code sees them. Never trust anything the client sends.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local RateLimiter = require(Shared:WaitForChild("RateLimiter"))

export type Validator = (...any) -> boolean

local RemoteGuard = {}

function RemoteGuard.connect(
	remote: RemoteEvent,
	validate: Validator,
	handler: (player: Player, ...any) -> ()
): RBXScriptConnection
	local limiter = RateLimiter.new(Config.RateLimits.DefaultPerSecond, Config.RateLimits.Burst)
	Players.PlayerRemoving:Connect(function(player)
		limiter:forget(player)
	end)
	return remote.OnServerEvent:Connect(function(player: Player, ...: any)
		if not limiter:allow(player, os.clock()) then
			return
		end
		local ok, valid = pcall(validate, ...)
		if not ok or not valid then
			warn(string.format("[RemoteGuard] rejected %s from %s", remote.Name, player.Name))
			return
		end
		handler(player, ...)
	end)
end

return RemoteGuard
