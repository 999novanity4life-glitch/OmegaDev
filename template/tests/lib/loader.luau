--!nocheck
-- Loads Roblox-style ModuleScripts under Lune. Fakes just enough of `script`
-- (script.Parent.Sibling) and `require(instance)` for pure modules to run.
-- Modules that touch `game` or Roblox services are not unit-testable here; test
-- those in Studio (see docs) and keep game logic in pure modules.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
-- Roblox datatypes (Vector3, Color3, CFrame...) so Config modules load under Lune.
local hasRoblox, roblox = pcall(require, "@lune/roblox")

local cache = {}
local loadModule

local function dirname(path: string): string
	return string.match(path, "^(.*)/[^/]+$") or "."
end

local function makeRef(path: string)
	-- path is a directory or module path without extension
	return setmetatable({ __path = path }, {
		__index = function(self, key)
			if key == "Parent" then
				return makeRef(dirname(rawget(self, "__path")))
			end
			return makeRef(rawget(self, "__path") .. "/" .. key)
		end,
	})
end

local function resolve(path: string): string
	for _, candidate in { path .. ".luau", path .. ".lua", path .. "/init.luau", path .. "/init.lua" } do
		if fs.isFile(candidate) then
			return candidate
		end
	end
	error("module not found: " .. path)
end

function loadModule(path: string)
	local file = resolve(path)
	if cache[file] ~= nil then
		return cache[file]
	end
	local scriptRef = makeRef(string.gsub(file, "%.luau?$", ""))
	if string.match(file, "/init%.luau?$") then
		scriptRef = makeRef(dirname(file))
	end
	local env = setmetatable({
		script = scriptRef,
		require = function(target)
			if type(target) == "table" and rawget(target, "__path") then
				return loadModule(rawget(target, "__path"))
			end
			return require(target)
		end,
	}, {
		__index = function(_, key)
			local value = getfenv()[key]
			if value == nil and hasRoblox then
				return roblox[key]
			end
			return value
		end,
	})
	local chunk = luau.load(fs.readFile(file), { debugName = file, environment = env })
	local result = chunk()
	cache[file] = result
	return result
end

return {
	load = loadModule,
}
