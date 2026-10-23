--!nocheck
-- Run from the project root: `lune run tests/run`
local fs = require("@lune/fs")
local process = require("@lune/process")
local t = require("./lib/expect")
local loader = require("./lib/loader")

for _, name in fs.readDir("tests") do
	if string.match(name, "%.spec%.luau$") then
		print(name)
		local spec = require("./" .. string.gsub(name, "%.luau$", ""))
		spec(t, loader.load)
	end
end

print(string.format("\n%d passed, %d failed", t.results.passed, t.results.failed))
for _, failure in t.results.failures do
	print("FAIL " .. failure)
end
process.exit(if t.results.failed == 0 then 0 else 1)
