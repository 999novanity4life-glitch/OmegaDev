--!strict
-- Client view of "the match I'm in": the folder the server keeps in
-- ReplicatedStorage.Matches, named by my MatchId attribute. nil in the lobby.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local SlimeCurve = require(Shared:WaitForChild("SlimeCurve"))

local MatchState = {}

local player = Players.LocalPlayer
local matches = ReplicatedStorage:WaitForChild("Matches")

function MatchState.folder(): Folder?
	local id = player:GetAttribute("MatchId")
	if type(id) ~= "string" then
		return nil
	end
	return matches:FindFirstChild(id) :: Folder?
end

function MatchState.number(name: string): number?
	local folder = MatchState.folder()
	local value = folder and folder:GetAttribute(name)
	return if type(value) == "number" then value else nil
end

function MatchState.state(): string?
	local folder = MatchState.folder()
	local value = folder and folder:GetAttribute("State")
	return if type(value) == "string" then value else nil
end

function MatchState.origin(): Vector3?
	local x, y, z = MatchState.number("OriginX"), MatchState.number("OriginY"), MatchState.number("OriginZ")
	if x and y and z then
		return Vector3.new(x, y, z)
	end
	return nil
end

-- Slime surface height right now, or nil before the slime starts / in the lobby.
function MatchState.slimeHeight(): number?
	local start = MatchState.number("SlimeStart")
	local duration = MatchState.number("SlimeDuration")
	local baseY = MatchState.number("SlimeBaseY")
	local topY = MatchState.number("SlimeTopY")
	if not start or not duration or not baseY or not topY then
		return nil
	end
	local clock = SlimeCurve.clock(
		workspace:GetServerTimeNow(),
		MatchState.number("SlimeHeld") or 0,
		MatchState.number("SlimeHoldStart"),
		MatchState.number("SlimeHoldUntil")
	)
	return SlimeCurve.height(clock, start, duration, baseY, topY, Config.Slime.Exponent)
end

function MatchState.inRound(): boolean
	return MatchState.state() == "Round" and MatchState.number("SlimeStart") ~= nil
end

return MatchState
