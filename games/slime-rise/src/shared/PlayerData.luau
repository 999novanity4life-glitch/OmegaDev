--!strict
-- Pure saved-data rules: the template, cleaning before save, and updates.
-- DataService owns the ProfileStore session; this module only does math.

local PlayerData = {}

export type Data = {
	Version: number,
	Crowns: number,
	Escapes: number,
	BestTime: number, -- seconds, 0 = never escaped (any map)
	BestTimes: { [string]: number }, -- per map id
	SeenIntros: { [string]: boolean }, -- map ids whose intro this player has watched
}

PlayerData.VERSION = 1

function PlayerData.template(): Data
	return { Version = PlayerData.VERSION, Crowns = 0, Escapes = 0, BestTime = 0, BestTimes = {}, SeenIntros = {} }
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
	local times: { [string]: number } = {}
	if type(data.BestTimes) == "table" then
		for id, t in data.BestTimes :: any do
			if type(id) == "string" and #id <= 20 then
				local clean = cleanTime(t)
				if clean > 0 then
					times[id] = clean
				end
			end
		end
	end
	data.BestTimes = times
	local seen: { [string]: boolean } = {}
	if type(data.SeenIntros) == "table" then
		for id, flag in data.SeenIntros :: any do
			if type(id) == "string" and #id <= 20 and flag == true then
				seen[id] = true
			end
		end
	end
	data.SeenIntros = seen
	return data
end

function PlayerData.addCrowns(data: Data, amount: number): number
	data.Crowns = cleanCount(data.Crowns + cleanCount(amount))
	return data.Crowns
end

-- The first intro on a map plays in full; from the second time on it can be
-- skipped. Marks the map seen and returns true if it had been seen before.
function PlayerData.markIntroSeen(data: Data, mapId: string): boolean
	local seenBefore = data.SeenIntros[mapId] == true
	data.SeenIntros[mapId] = true
	return seenBefore
end

-- Records an escape; returns true when it is a new best time on that map.
function PlayerData.recordEscape(data: Data, seconds: number, mapId: string?): boolean
	data.Escapes = cleanCount(data.Escapes + 1)
	local t = cleanTime(seconds)
	if t <= 0 then
		return false
	end
	if data.BestTime == 0 or t < data.BestTime then
		data.BestTime = t
	end
	local id = mapId or "Shaft"
	local prev = data.BestTimes[id]
	if prev == nil or t < prev then
		data.BestTimes[id] = t
		return true
	end
	return false
end

return PlayerData
