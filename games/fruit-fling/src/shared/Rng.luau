--!strict
-- Small deterministic RNG (Park-Miller minimal standard) so pure layout
-- modules give the same map for the same seed in Studio and under Lune,
-- without depending on Roblox's Random.

export type Rng = {
	next: (self: Rng) -> number, -- [0, 1)
	range: (self: Rng, lo: number, hi: number) -> number,
	int: (self: Rng, lo: number, hi: number) -> number, -- inclusive
	pick: <T>(self: Rng, list: { T }) -> T,
	state: number,
}

local MOD = 2147483647
local MUL = 48271

local Rng = {}
Rng.__index = Rng

function Rng.new(seed: number): Rng
	local s = math.floor(math.abs(seed)) % MOD
	if s == 0 then
		s = 1
	end
	return (setmetatable({ state = s }, Rng) :: any) :: Rng -- any: metatable cast to the exported type
end

function Rng.next(self: Rng): number
	self.state = (self.state * MUL) % MOD
	return (self.state - 1) / (MOD - 1)
end

function Rng.range(self: Rng, lo: number, hi: number): number
	return lo + (hi - lo) * self:next()
end

function Rng.int(self: Rng, lo: number, hi: number): number
	return math.min(hi, lo + math.floor(self:next() * (hi - lo + 1)))
end

function Rng.pick<T>(self: Rng, list: { T }): T
	return list[self:int(1, #list)]
end

return Rng
