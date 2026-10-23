--!strict
-- Token bucket per key. Pure: the caller passes the clock, so tests are deterministic.

export type RateLimiter = {
	allow: (self: RateLimiter, key: any, now: number) -> boolean,
	forget: (self: RateLimiter, key: any) -> (),
}

type Bucket = { tokens: number, updated: number }

local RateLimiter = {}

function RateLimiter.new(perSecond: number, burst: number): RateLimiter
	local buckets: { [any]: Bucket } = {}
	local limiter = {}

	function limiter.allow(_self: RateLimiter, key: any, now: number): boolean
		local bucket = buckets[key]
		if not bucket then
			bucket = { tokens = burst, updated = now }
			buckets[key] = bucket
		end
		bucket.tokens = math.min(burst, bucket.tokens + (now - bucket.updated) * perSecond)
		bucket.updated = now
		if bucket.tokens < 1 then
			return false
		end
		bucket.tokens -= 1
		return true
	end

	function limiter.forget(_self: RateLimiter, key: any)
		buckets[key] = nil
	end

	return limiter :: RateLimiter
end

return RateLimiter
