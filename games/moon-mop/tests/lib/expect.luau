--!nocheck
-- Tiny test harness: describe/it/expect, zero dependencies.

local results = { passed = 0, failed = 0, failures = {} }
local prefix = {}

local function describe(name: string, fn: () -> ())
	table.insert(prefix, name)
	fn()
	table.remove(prefix)
end

local function it(name: string, fn: () -> ())
	local full = table.concat(prefix, " > ") .. " > " .. name
	local ok, err = pcall(fn)
	if ok then
		results.passed += 1
		print("  PASS  " .. full)
	else
		results.failed += 1
		table.insert(results.failures, full .. "\n        " .. tostring(err))
		print("  FAIL  " .. full)
	end
end

local function expect(actual: any)
	local m = {}
	function m.toBe(expected: any)
		if actual ~= expected then
			error(string.format("expected %s, got %s", tostring(expected), tostring(actual)), 2)
		end
	end
	function m.toBeNear(expected: number, eps: number?)
		if math.abs(actual - expected) > (eps or 1e-6) then
			error(string.format("expected ~%s, got %s", tostring(expected), tostring(actual)), 2)
		end
	end
	function m.toBeTruthy()
		if not actual then
			error("expected truthy, got " .. tostring(actual), 2)
		end
	end
	function m.toBeFalsy()
		if actual then
			error("expected falsy, got " .. tostring(actual), 2)
		end
	end
	return m
end

return { describe = describe, it = it, expect = expect, results = results }
