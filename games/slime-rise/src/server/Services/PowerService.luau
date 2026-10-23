--!strict
-- Validates power use. The client moves its own character for instant feel;
-- the server checks unlock, cooldown, round state and range, then tells every
-- client to play the effect. Bubble Shield is server-trusted (MatchService reads it).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Powers = require(Shared:WaitForChild("Powers"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Validate = require(Shared:WaitForChild("Validate"))
local RemoteGuard = require(script.Parent.RemoteGuard)
local MatchService = require(script.Parent.MatchService)

local PowerService = {}

local lastUsed: { [Player]: { [string]: number } } = {}
local ACTIVE: { [string]: boolean } = {}
for _, id in Powers.activeIds() do
	ACTIVE[id] = true
end

local function validVector(value: any): boolean
	return typeof(value) == "Vector3"
		and Validate.finiteNumber(value.X)
		and Validate.finiteNumber(value.Y)
		and Validate.finiteNumber(value.Z)
end

function PowerService.start()
	local usePower = Remotes.get("UsePower")
	local powerFx = Remotes.get("PowerFx")
	Players.PlayerRemoving:Connect(function(player)
		lastUsed[player] = nil
	end)

	RemoteGuard.connect(usePower, function(id: any, target: any)
		return Validate.oneOf(id, ACTIVE) and (target == nil or validVector(target))
	end, function(player: Player, id: string, target: Vector3?)
		if not MatchService.isClimbing(player) then
			return
		end
		local crowns = player:GetAttribute("Crowns")
		if type(crowns) ~= "number" or not Powers.isUnlocked(id, crowns) then
			return
		end
		local def = Powers.def(id) :: Config.PowerDef
		local used = lastUsed[player] or {}
		lastUsed[player] = used
		local t = os.clock()
		-- 0.25 s grace for latency between the client's own cooldown and ours.
		if not Powers.cooldownReady(used[id], def.Cooldown - 0.25, t) then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not character or not root then
			return
		end
		if id == "Grapple" then
			if not target or (target - root.Position).Magnitude > (def.Range or 0) + 6 then
				return
			end
		end
		used[id] = t
		if id == "Shield" then
			character:SetAttribute("ShieldUntil", workspace:GetServerTimeNow() + (def.Duration or 0))
		end
		powerFx:FireAllClients(player.UserId, id, target)
	end)
end

return PowerService
