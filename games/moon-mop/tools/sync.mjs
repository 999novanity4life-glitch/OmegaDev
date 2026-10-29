// Turns this game's Rojo tree into Luau chunks that rebuild the scripts inside a running Studio
// (sent one by one through the Studio MCP `execute_luau` tool), for when Rojo serve can't reach
// the machine running Studio. Only the code roots are replaced: Shared, Server, Client, Vendor.
//
//   node tools/sync.mjs <outDir>      -> writes <outDir>/sync-01.luau, sync-02.luau, ...
// and <outDir>/manifest.json (the same tree as JSON, for Studio to fetch from a local server).
import fs from "node:fs";
import path from "node:path";

const GAME = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..");
const out = path.resolve(process.argv[2] ?? path.join(GAME, ".sync"));
const LIMIT = 120_000;

const ROOTS = [
	{ parent: "ReplicatedStorage", name: "Shared", dir: "src/shared" },
	{ parent: "ServerScriptService", name: "Server", dir: "src/server" },
	{ parent: "StarterPlayer/StarterPlayerScripts", name: "Client", dir: "src/client" },
];

const nodes = []; // { parent, name, className, source? }

function scriptClass(file) {
	if (file.endsWith(".server.luau")) return "Script";
	if (file.endsWith(".client.luau")) return "LocalScript";
	return "ModuleScript";
}

function baseName(file) {
	return file.replace(/\.(server|client)\.luau$/, "").replace(/\.luau$/, "");
}

function walk(dir, parent, name) {
	const entries = fs.readdirSync(dir).sort();
	const init = entries.find((e) => /^init(\.server|\.client)?\.luau$/.test(e));
	const me = `${parent}/${name}`;
	if (init) {
		nodes.push({ parent, name, className: scriptClass(init), file: path.relative(GAME, path.join(dir, init)), source: fs.readFileSync(path.join(dir, init), "utf8") });
	} else {
		nodes.push({ parent, name, className: "Folder" });
	}
	for (const e of entries) {
		if (e === init) continue;
		const full = path.join(dir, e);
		if (fs.statSync(full).isDirectory()) {
			walk(full, me, e);
		} else if (e.endsWith(".luau")) {
			nodes.push({ parent: me, name: baseName(e), className: scriptClass(e), file: path.relative(GAME, full), source: fs.readFileSync(full, "utf8") });
		}
	}
}

for (const r of ROOTS) walk(path.join(GAME, r.dir), r.parent, r.name);
nodes.push({ parent: "ServerStorage", name: "Vendor", className: "Folder" });
nodes.push({
	parent: "ServerStorage/Vendor",
	name: "ProfileStore",
	className: "ModuleScript",
	file: "vendor/ProfileStore.luau",
	source: fs.readFileSync(path.join(GAME, "vendor/ProfileStore.luau"), "utf8"),
});

function longString(s) {
	let eq = "";
	while (s.includes(`]${eq}]`)) eq += "=";
	// a leading newline inside a long string is dropped by Luau, so add one to keep line 1 intact
	return `[${eq}[\n${s}]${eq}]`;
}

const HEADER = `local function at(path: string): Instance
	local cur: Instance = game
	for part in string.gmatch(path, "[^/]+") do
		local nxt = cur:FindFirstChild(part)
		if not nxt then
			if cur == game then
				nxt = game:GetService(part)
			else
				error("missing " .. path)
			end
		end
		cur = nxt :: Instance
	end
	return cur
end
local function put(parent: string, name: string, className: string, source: string?)
	local p = at(parent)
	local old = p:FindFirstChild(name)
	if old and old.ClassName ~= className then
		old:Destroy()
		old = nil
	end
	local inst = old or Instance.new(className)
	inst.Name = name
	if source then
		(inst :: any).Source = source
	end
	inst.Parent = p
end
`;

fs.rmSync(out, { recursive: true, force: true });
fs.mkdirSync(out, { recursive: true });

const chunks = [];
let cur = HEADER;
// first chunk wipes the code roots so deleted files don't linger
cur += `for _, p in { "ReplicatedStorage/Shared", "ServerScriptService/Server", "StarterPlayer/StarterPlayerScripts/Client", "ServerStorage/Vendor" } do
	local ok, inst = pcall(at, p)
	if ok then inst:Destroy() end
end
`;
for (const n of nodes) {
	const line = `put(${JSON.stringify(n.parent)}, ${JSON.stringify(n.name)}, ${JSON.stringify(n.className)}${
		n.source !== undefined ? ", " + longString(n.source) : ""
	})\n`;
	if (cur.length + line.length > LIMIT && cur !== HEADER) {
		chunks.push(cur);
		cur = HEADER;
	}
	cur += line;
}
chunks.push(cur + `return "synced"\n`);
chunks.forEach((c, i) => {
	if (i < chunks.length - 1) c += `return "chunk ${i + 1} ok"\n`;
	fs.writeFileSync(path.join(out, `sync-${String(i + 1).padStart(2, "0")}.luau`), c);
});
fs.writeFileSync(path.join(out, "manifest.json"), JSON.stringify(nodes));

// remote.luau: a small chunk that fetches every file from a pushed commit on GitHub instead of
// carrying the sources (BASE is replaced with the raw URL of games/<slug>/ at that commit).
const list = nodes
	.map((n) => `\t{ ${JSON.stringify(n.parent)}, ${JSON.stringify(n.name)}, ${JSON.stringify(n.className)}, ${n.file ? JSON.stringify(n.file) : "nil"} },`)
	.join("\n");
fs.writeFileSync(
	path.join(out, "remote.luau"),
	`${HEADER}local BASE = "__BASE__"
local Http = game:GetService("HttpService")
local was = Http.HttpEnabled
Http.HttpEnabled = true
local entries = {
${list}
}
local sources = {}
local ok, err = pcall(function()
	for i, e in entries do
		if e[4] then
			sources[i] = Http:GetAsync(BASE .. e[4], true)
		end
	end
end)
Http.HttpEnabled = was
if not ok then
	error("fetch failed: " .. tostring(err))
end
for _, p in { "ReplicatedStorage/Shared", "ServerScriptService/Server", "StarterPlayer/StarterPlayerScripts/Client", "ServerStorage/Vendor" } do
	local found, inst = pcall(at, p)
	if found then inst:Destroy() end
end
for i, e in entries do
	put(e[1], e[2], e[3], sources[i])
end
return string.format("synced %d instances", #entries)
`
);
console.log(`${nodes.length} instances in ${chunks.length} chunks -> ${out}`);
