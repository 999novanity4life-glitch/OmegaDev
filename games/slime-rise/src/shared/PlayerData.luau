--!strict
-- Pure saved-data rules: the template, cleaning before save, and updates.
-- DataService owns the ProfileStore session; this module only does math.

local PlayerData = {}

export type Data = {
	Version: number,
	Crowns: number,
	Escapes: number,
	BestTime: number, -- seconds, 0 = never escaped
}

PlayerData.VERSION = 1

function PlayerData.template(): Data
	return { Version = PlayerData.VERSION, Crowns = 0, Escapes = 0, BestTime = 0 }
end

local function cleanCount(value: any): number
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return 0
	end
	return math.max(0, math.floor(value))
end

local function cleanTime(value: any): number
	if type(value) ~= "number" or value ~= value or value == math.huge or value < 0 then
		return 0
	end
	return math.floor(value * 100 + 0.5) / 100
end

-- Fix any bad values in place (NaN, infinity, negatives, wrong types). One bad
-- value would fail the whole save, so this runs on load and before changes.
function PlayerData.sanitize(data: Data): Data
	data.Version = PlayerData.VERSION
	data.Crowns = cleanCount(data.Crowns)
	data.Escapes = cleanCount(data.Escapes)
	data.BestTime = cleanTime(data.BestTime)
	return data
end

function PlayerData.addCrowns(data: Data, amount: number): number
	data.Crowns = cleanCount(data.Crowns + cleanCount(amount))
	return data.Crowns
end

-- Records an escape; returns true when it is a new best time.
function PlayerData.recordEscape(data: Data, seconds: number): boolean
	data.Escapes = cleanCount(data.Escapes + 1)
	local t = cleanTime(seconds)
	if t > 0 and (data.BestTime == 0 or t < data.BestTime) then
		data.BestTime = t
		return true
	end
	return false
end

return PlayerData
