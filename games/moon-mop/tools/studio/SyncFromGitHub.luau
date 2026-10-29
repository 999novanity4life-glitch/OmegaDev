--!nocheck
-- Pull this game's code from a pushed GitHub commit straight into the open Studio place, for when
-- Rojo can't reach the machine running Studio. Run it through the Studio MCP `execute_luau` tool
-- (Edit datamodel) with SHA set. It maps files like default.project.json does:
--   src/shared -> ReplicatedStorage.Shared, src/server -> ServerScriptService.Server,
--   src/client -> StarterPlayer.StarterPlayerScripts.Client, vendor/ProfileStore.luau ->
--   ServerStorage.Vendor.ProfileStore. init.server/init.client files become the folder's script.
-- HttpService is switched on only for the fetch and put back as it was.

local SHA = "__SHA__"
local REPO = "999novanity4life-glitch/OmegaDev"
local GAME = "games/moon-mop/"

local Http = game:GetService("HttpService")
local ROOTS = {
	{ prefix = GAME .. "src/shared/", parent = game.ReplicatedStorage, name = "Shared" },
	{ prefix = GAME .. "src/server/", parent = game.ServerScriptService, name = "Server" },
	{ prefix = GAME .. "src/client/", parent = game.StarterPlayer.StarterPlayerScripts, name = "Client" },
}

local was = Http.HttpEnabled
Http.HttpEnabled = true
local files = {}
local ok, err = pcall(function()
	local tree = Http:JSONDecode(
		Http:GetAsync(string.format("https://api.github.com/repos/%s/git/trees/%s?recursive=1", REPO, SHA), true)
	)
	for _, node in tree.tree do
		if node.type == "blob" and string.sub(node.path, -5) == ".luau" then
			for _, r in ROOTS do
				if string.sub(node.path, 1, #r.prefix) == r.prefix then
					table.insert(files, { root = r, rel = string.sub(node.path, #r.prefix + 1), path = node.path })
				end
			end
			if node.path == GAME .. "vendor/ProfileStore.luau" then
				table.insert(files, { vendor = true, path = node.path })
			end
		end
	end
	for _, f in files do
		f.source = Http:GetAsync(string.format("https://raw.githubusercontent.com/%s/%s/%s", REPO, SHA, f.path), true)
	end
end)
Http.HttpEnabled = was
if not ok then
	error("fetch failed: " .. tostring(err))
end

local function classOf(name)
	if string.match(name, "%.server%.luau$") then
		return "Script", string.gsub(name, "%.server%.luau$", "")
	elseif string.match(name, "%.client%.luau$") then
		return "LocalScript", string.gsub(name, "%.client%.luau$", "")
	end
	return "ModuleScript", (string.gsub(name, "%.luau$", ""))
end

-- wipe and rebuild each root
local made = 0
for _, r in ROOTS do
	local old = r.parent:FindFirstChild(r.name)
	if old then
		old:Destroy()
	end
	-- the root itself: a script if it has an init file, else a folder
	local rootClass = "Folder"
	local rootSource = nil
	for _, f in files do
		if f.root == r and string.match(f.rel, "^init%.[%a]+%.luau$") then
			rootClass = classOf(f.rel)
			rootSource = f.source
		end
	end
	local root = Instance.new(rootClass)
	root.Name = r.name
	if rootSource then
		root.Source = rootSource
	end
	root.Parent = r.parent
	for _, f in files do
		if f.root == r and not string.match(f.rel, "^init%.[%a]+%.luau$") then
			local parts = string.split(f.rel, "/")
			local cur = root
			for i = 1, #parts - 1 do
				local nxt = cur:FindFirstChild(parts[i])
				if not nxt then
					nxt = Instance.new("Folder")
					nxt.Name = parts[i]
					nxt.Parent = cur
				end
				cur = nxt
			end
			local class, name = classOf(parts[#parts])
			local inst = Instance.new(class)
			inst.Name = name
			inst.Source = f.source
			inst.Parent = cur
			made += 1
		end
	end
end
local vendor = game.ServerStorage:FindFirstChild("Vendor") or Instance.new("Folder")
vendor.Name = "Vendor"
vendor.Parent = game.ServerStorage
for _, f in files do
	if f.vendor then
		local old = vendor:FindFirstChild("ProfileStore")
		if old then
			old:Destroy()
		end
		local m = Instance.new("ModuleScript")
		m.Name = "ProfileStore"
		m.Source = f.source
		m.Parent = vendor
		made += 1
	end
end
return string.format("synced %d scripts from %s", made, string.sub(SHA, 1, 7))
