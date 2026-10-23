--!nocheck
-- Loads Roblox-style ModuleScripts under Lune. Fakes just enough of `script`
-- (script.Parent.Sibling) and `require(instance)` for pure modules to run.
-- Modules that touch `game` or Roblox services are not unit-testable here; test
-- those in Studio (see docs) and keep game logic in pure modules.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
-- Roblox datatypes so Config modules load under Lune. Lune's own types when it
-- has them, else tiny stand-ins (enough for config tables, not for math).
local hasRoblox, roblox = pcall(require, "@lune/roblox")
local STUBS = {
	Vector3 = {
		new = function(x, y, z)
			return { X = x or 0, Y = y or 0, Z = z or 0 }
		end,
		zero = { X = 0, Y = 0, Z = 0 },
		one = { X = 1, Y = 1, Z = 1 },
	},
	Color3 = {
		new = function(r, g, b)
			return { R = r or 0, G = g or 0, B = b or 0 }
		end,
		fromRGB = function(r, g, b)
			return { R = (r or 0) / 255, G = (g or 0) / 255, B = (b or 0) / 255 }
		end,
	},
	CFrame = {
		new = function(x, y, z)
			return { X = x or 0, Y = y or 0, Z = z or 0 }
		end,
	},
}

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
			if value == nil and hasRoblox and type(roblox) == "table" then
				value = roblox[key]
			end
			if value == nil then
				value = STUBS[key]
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
