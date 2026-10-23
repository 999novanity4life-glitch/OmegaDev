--!strict
-- Pure puzzle numbers: how big each puzzle is for a party size, and the
-- color code. PuzzleService builds the parts; this decides the rules.

local PuzzleRules = {}

local function clampPlayers(n: number): number
	return math.clamp(math.floor(n), 1, 8)
end

-- One valve per player (up to 3) plus one, so even a solo run has 2.
function PuzzleRules.valveCount(players: number): number
	return math.min(clampPlayers(players), 3) + 1
end

-- Plates must all be held at once. Teams get one plate per player (up to 3);
-- solo gets 2 plates plus a ballast canister to weigh one down.
function PuzzleRules.plateCount(players: number): number
	local n = clampPlayers(players)
	return if n < 2 then 2 else math.min(n, 3)
end

-- Ballast canisters handed out so every plate can be held at once.
function PuzzleRules.plateWeights(players: number): number
	return math.max(0, PuzzleRules.plateCount(players) - clampPlayers(players))
end

function PuzzleRules.fuseCount(players: number): number
	return math.min(1 + (clampPlayers(players) - 1) // 3, 3)
end

-- A code of `length` color indexes in 1..colors from a seed (deterministic).
function PuzzleRules.colorCode(seed: number, length: number, colors: number): { number }
	local state = math.abs(math.floor(seed)) % 2147483647
	if state == 0 then
		state = 7
	end
	local code = {}
	for i = 1, length do
		state = (state * 48271) % 2147483647
		code[i] = state % colors + 1
	end
	return code
end

function PuzzleRules.codeMatches(current: { number }, code: { number }): boolean
	if #current ~= #code then
		return false
	end
	for i, v in code do
		if current[i] ~= v then
			return false
		end
	end
	return true
end

return PuzzleRules
