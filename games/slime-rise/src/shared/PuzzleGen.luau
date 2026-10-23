--!strict
-- Pure generators and checkers for the mini-game puzzles. The server builds a
-- puzzle from a seed, keeps the answer, and checks every move with these.
-- Every generated puzzle is solvable by construction.

local PuzzleGen = {}

-- Directions as bits: N=1, E=2, S=4, W=8.
local DIRS = {
	{ bit = 1, dx = 0, dy = -1, opp = 4 },
	{ bit = 2, dx = 1, dy = 0, opp = 8 },
	{ bit = 4, dx = 0, dy = 1, opp = 1 },
	{ bit = 8, dx = -1, dy = 0, opp = 2 },
}

local function rng(seed: number): (number) -> number
	local state = math.abs(math.floor(seed)) % 2147483647
	if state == 0 then
		state = 1
	end
	return function(n: number): number
		state = (state * 48271) % 2147483647
		return state % n + 1
	end
end

-- Rotate a connection mask clockwise `times` quarter turns.
function PuzzleGen.rotateMask(mask: number, times: number): number
	local m = mask
	for _ = 1, times % 4 do
		local carry = bit32.band(m, 8) ~= 0
		m = bit32.band(bit32.lshift(m, 1), 15)
		if carry then
			m = bit32.bor(m, 1)
		end
	end
	return m
end

export type Pipes = {
	width: number,
	height: number,
	masks: { number }, -- solved connection masks, row-major
	rotations: { number }, -- current quarter turns applied to each tile
	source: number, -- tile index fed by the slime tank
}

-- Random spanning tree over the grid (randomised DFS), then scramble.
function PuzzleGen.pipes(seed: number, width: number, height: number): Pipes
	local roll = rng(seed)
	local count = width * height
	local masks = table.create(count, 0)
	local visited = table.create(count, false)
	local source = (math.floor(height / 2)) * width + 1 -- left edge, middle row
	local stack = { source }
	visited[source] = true
	while #stack > 0 do
		local cell = stack[#stack]
		local x = (cell - 1) % width
		local y = (cell - 1) // width
		local options = {}
		for _, d in DIRS do
			local nx, ny = x + d.dx, y + d.dy
			if nx >= 0 and nx < width and ny >= 0 and ny < height then
				local n = ny * width + nx + 1
				if not visited[n] then
					table.insert(options, { n = n, d = d })
				end
			end
		end
		if #options == 0 then
			table.remove(stack)
		else
			local pick = options[roll(#options)]
			masks[cell] = bit32.bor(masks[cell], pick.d.bit)
			masks[pick.n] = bit32.bor(masks[pick.n], pick.d.opp)
			visited[pick.n] = true
			table.insert(stack, pick.n)
		end
	end
	local rotations = table.create(count, 0)
	for i = 1, count do
		rotations[i] = roll(4) - 1
	end
	-- Never hand out an already-solved board.
	if
		PuzzleGen.pipesSolved({ width = width, height = height, masks = masks, rotations = rotations, source = source })
	then
		rotations[source] = (rotations[source] + 1) % 4
	end
	return { width = width, height = height, masks = masks, rotations = rotations, source = source }
end

-- The mask a tile shows right now (solved mask turned by its scramble).
function PuzzleGen.shownMask(p: Pipes, index: number): number
	return PuzzleGen.rotateMask(p.masks[index], p.rotations[index])
end

-- Which tiles the slime reaches from the source through matching pipe ends.
function PuzzleGen.pipesFlow(p: Pipes): { [number]: boolean }
	local reached: { [number]: boolean } = { [p.source] = true }
	local queue = { p.source }
	while #queue > 0 do
		local cell = table.remove(queue, 1) :: number
		local mask = PuzzleGen.shownMask(p, cell)
		local x = (cell - 1) % p.width
		local y = (cell - 1) // p.width
		for _, d in DIRS do
			if bit32.band(mask, d.bit) ~= 0 then
				local nx, ny = x + d.dx, y + d.dy
				if nx >= 0 and nx < p.width and ny >= 0 and ny < p.height then
					local n = ny * p.width + nx + 1
					if not reached[n] and bit32.band(PuzzleGen.shownMask(p, n), d.opp) ~= 0 then
						reached[n] = true
						table.insert(queue, n)
					end
				end
			end
		end
	end
	return reached
end

-- Solved when slime reaches every tile (the tree is fully connected).
function PuzzleGen.pipesSolved(p: Pipes): boolean
	local reached = PuzzleGen.pipesFlow(p)
	for i = 1, p.width * p.height do
		if not reached[i] then
			return false
		end
	end
	return true
end

export type Wires = {
	left: { number }, -- colour index of each left socket, top to bottom
	right: { number }, -- colour index of each right socket, top to bottom
	connected: { [number]: number }, -- left slot -> right slot
}

local function shuffled(n: number, roll: (number) -> number): { number }
	local list = table.create(n, 0)
	for i = 1, n do
		list[i] = i
	end
	for i = n, 2, -1 do
		local j = roll(i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

function PuzzleGen.wires(seed: number, count: number): Wires
	local roll = rng(seed)
	local left = shuffled(count, roll)
	local right = shuffled(count, roll)
	-- Make sure at least one wire crosses (never a trivial straight-across board).
	local straight = true
	for i = 1, count do
		if left[i] ~= right[i] then
			straight = false
		end
	end
	if straight and count > 1 then
		right[1], right[2] = right[2], right[1]
	end
	return { left = left, right = right, connected = {} }
end

-- True when left slot `l` and right slot `r` carry the same colour.
function PuzzleGen.wireMatches(w: Wires, l: number, r: number): boolean
	return w.left[l] ~= nil and w.left[l] == w.right[r]
end

function PuzzleGen.wiresSolved(w: Wires): boolean
	for l = 1, #w.left do
		local r = w.connected[l]
		if not r or not PuzzleGen.wireMatches(w, l, r) then
			return false
		end
	end
	return true
end

-- Memory lights: a sequence of pad indexes (1..pads). Kids remember about
-- 5 items, so rounds grow 3 -> 4 -> 5.
function PuzzleGen.memory(seed: number, length: number, pads: number): { number }
	local roll = rng(seed)
	local seq = table.create(length, 0)
	for i = 1, length do
		local pick = roll(pads)
		-- No three of the same pad in a row; that reads as a glitch.
		if i > 2 and seq[i - 1] == pick and seq[i - 2] == pick then
			pick = pick % pads + 1
		end
		seq[i] = pick
	end
	return seq
end

function PuzzleGen.memoryMatches(sequence: { number }, input: { number }): boolean
	if #input ~= #sequence then
		return false
	end
	for i, v in sequence do
		if input[i] ~= v then
			return false
		end
	end
	return true
end

return PuzzleGen
