--!strict
-- Meteor showers: every so often a warning goes out, then a handful of meteors hit cleaned
-- ground away from the stations and bases and put dust back on the sectors round each crater,
-- so there is always more Moon to sweep. Clients draw the warning, the streaks and the impacts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Places = require(Shared:WaitForChild("Places"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Moon = require(script.Parent.Moon)
local Stations = require(script.Parent.Stations)

local Meteors = {}

local M = Config.Meteor
local worldEvent = Remotes.get("WorldEvent")
local rng = Random.new()

local function clearOfPads(dir: Vector3): boolean
	for _, pad in Places.pads() do
		if Places.arc(dir, pad.dir) < pad.radius + 60 then
			return false
		end
	end
	return true
end

-- Impact sites: cleaned sectors if there are enough, else anywhere away from the pads.
local function pickSites(count: number): { number }
	local sites: { number } = {}
	local fallback: { number } = {}
	for _ = 1, 4000 do
		if #sites >= count then
			break
		end
		local sid = rng:NextInteger(0, Moon.sector.count - 1)
		local dir = Moon.sector:position(sid)
		if clearOfPads(dir) then
			if Moon.isSectorDone(sid) then
				table.insert(sites, sid)
			elseif #fallback < count then
				table.insert(fallback, sid)
			end
		end
	end
	for _, sid in fallback do
		if #sites >= count then
			break
		end
		table.insert(sites, sid)
	end
	return sites
end

-- Run one shower now: warn, wait, then strike.
function Meteors.shower(warningSeconds: number?)
	local sites = pickSites(M.Impacts)
	local points: { Vector3 } = {}
	for _, sid in sites do
		table.insert(points, Stations.groundAt(Moon.sector:position(sid)))
	end
	local warn = warningSeconds or M.WarningSeconds
	worldEvent:FireAllClients("MeteorWarning", { seconds = warn, at = points })
	task.wait(warn)
	for i, sid in sites do
		worldEvent:FireAllClients("Meteor", { at = points[i], fall = 1.6 })
		task.delay(1.6, function()
			for _, s in Moon.ring(sid, M.RedustRings) do
				if clearOfPads(Moon.sector:position(s)) then
					Moon.redustSector(s)
				end
			end
		end)
		task.wait(rng:NextNumber(0.4, 1.2))
	end
end

task.spawn(function()
	while true do
		task.wait(M.EverySeconds)
		Meteors.shower()
	end
end)

return Meteors
