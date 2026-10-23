// OmegaDev control room: a local dashboard over the .omegadev/ state.
// No dependencies. Binds to 127.0.0.1 only; it can approve work and queue
// instructions, so never expose it to a network.
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import { PITCH_DIRS, ROOT, STATE, readState } from "../scripts/state.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));

// Library: the studio's knowledge, shown read-only in the control room.
// Order here is the order of the groups on the page.
const LIBRARY = [
	{ dir: "vault", group: "Studio playbook" },
	{ dir: "docs/rulebooks", group: "Rulebooks" },
	{ dir: "docs/research", group: "Research" },
	{ dir: "docs", group: "Studio docs" },
	{ dir: "kits", group: "Code kits", readmes: true },
];

// Last commit time for a file (falls back to the file's mtime outside git or for new files).
const lastChanged = (file) => {
	try {
		const iso = execFileSync("git", ["log", "-1", "--format=%cI", "--", file], { cwd: ROOT, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
		if (iso) return new Date(iso).toISOString();
	} catch {}
	return fs.statSync(file).mtime.toISOString();
};

export function listLibrary() {
	const out = [];
	for (const { dir, group, readmes } of LIBRARY) {
		const full = path.join(ROOT, dir);
		if (!fs.existsSync(full)) continue;
		const files = readmes
			? fs.readdirSync(full, { withFileTypes: true }).filter((d) => d.isDirectory()).map((d) => path.join(d.name, "README.md"))
			: fs.readdirSync(full).filter((f) => f.endsWith(".md"));
		for (const rel of files.sort()) {
			const file = path.join(full, rel);
			if (!fs.existsSync(file) || !fs.statSync(file).isFile()) continue;
			const text = fs.readFileSync(file, "utf8");
			const title = (text.match(/^#\s+(.+)$/m) || [])[1] || path.basename(rel, ".md");
			out.push({ path: `${dir}/${rel.split(path.sep).join("/")}`, group, title: title.trim(), updated: lastChanged(file), text });
		}
	}
	return out;
}
const MEDIA_TYPES = { ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".webp": "image/webp", ".gif": "image/gif", ".mp4": "video/mp4", ".webm": "video/webm" };

const send = (res, code, body, type = "application/json") => {
	res.writeHead(code, { "Content-Type": type, "Cache-Control": "no-store" });
	res.end(typeof body === "string" || Buffer.isBuffer(body) ? body : JSON.stringify(body));
};

const readBody = (req) =>
	new Promise((resolve, reject) => {
		let data = "";
		req.on("data", (c) => {
			data += c;
			if (data.length > 64 * 1024) reject(new Error("body too large"));
		});
		req.on("end", () => {
			try {
				resolve(data ? JSON.parse(data) : {});
			} catch (e) {
				reject(e);
			}
		});
	});

const writeJson = (file, value) => {
	fs.mkdirSync(path.dirname(file), { recursive: true });
	fs.writeFileSync(file, JSON.stringify(value, null, 2) + "\n");
};

// Only plain ids (no path separators) may name files.
const safeId = (id) => (typeof id === "string" && /^[a-z]-[a-z0-9]+$/.test(id) ? id : null);

async function handle(req, res) {
	const url = new URL(req.url, "http://localhost");
	if (req.method === "GET" && url.pathname === "/") {
		return send(res, 200, fs.readFileSync(path.join(HERE, "index.html")), "text/html; charset=utf-8");
	}
	if (req.method === "GET" && url.pathname === "/api/state") return send(res, 200, readState());
	// Read-only list of whitelisted Markdown files (no path from the client is ever opened).
	if (req.method === "GET" && url.pathname === "/api/library") return send(res, 200, listLibrary());
	if (req.method === "GET" && url.pathname.startsWith("/media/")) {
		const name = path.basename(url.pathname);
		const file = path.join(STATE, "review", "media", name);
		const type = MEDIA_TYPES[path.extname(name).toLowerCase()];
		if (!type || !fs.existsSync(file)) return send(res, 404, { error: "not found" });
		return send(res, 200, fs.readFileSync(file), type);
	}
	if (req.method === "GET" && url.pathname.startsWith("/pitch/")) {
		const name = path.basename(url.pathname);
		const file = PITCH_DIRS.map((d) => path.join(d, name)).find((f) => fs.existsSync(f));
		if (!name.endsWith(".md") || !file) return send(res, 404, { error: "not found" });
		return send(res, 200, fs.readFileSync(file, "utf8"), "text/plain; charset=utf-8");
	}
	if (req.method !== "POST") return send(res, 404, { error: "not found" });

	// Reject cross-site form posts: the page always sends JSON.
	if (!String(req.headers["content-type"] || "").startsWith("application/json"))
		return send(res, 415, { error: "json only" });
	const body = await readBody(req);

	if (url.pathname === "/api/verdict") {
		const id = safeId(body.id);
		const file = id && path.join(STATE, "review", `${id}.json`);
		if (!file || !fs.existsSync(file)) return send(res, 404, { error: "no such item" });
		if (!["approved", "changes", "rejected"].includes(body.verdict)) return send(res, 400, { error: "bad verdict" });
		const item = JSON.parse(fs.readFileSync(file, "utf8"));
		Object.assign(item, { verdict: body.verdict, comment: String(body.comment || ""), pickedUp: false, updated: new Date().toISOString() });
		writeJson(file, item);
		return send(res, 200, item);
	}
	if (url.pathname === "/api/ask") {
		const text = String(body.text || "").trim();
		if (!text) return send(res, 400, { error: "empty" });
		fs.mkdirSync(STATE, { recursive: true });
		fs.appendFileSync(path.join(STATE, "inbox.jsonl"), JSON.stringify({ ts: new Date().toISOString(), text }) + "\n");
		return send(res, 200, { ok: true });
	}
	if (url.pathname === "/api/tryit") {
		const id = safeId(body.id);
		const file = id && path.join(STATE, "tryit", `${id}.json`);
		if (!file || !fs.existsSync(file)) return send(res, 404, { error: "no such card" });
		const card = JSON.parse(fs.readFileSync(file, "utf8"));
		card.status = "done";
		card.reply = String(body.reply || "");
		writeJson(file, card);
		return send(res, 200, card);
	}
	if (url.pathname === "/api/pause") {
		fs.mkdirSync(STATE, { recursive: true });
		if (body.paused) fs.writeFileSync(path.join(STATE, "paused"), new Date().toISOString());
		else fs.rmSync(path.join(STATE, "paused"), { force: true });
		return send(res, 200, { paused: !!body.paused });
	}
	return send(res, 404, { error: "not found" });
}

export function startRoom(port) {
	const server = http.createServer((req, res) =>
		handle(req, res).catch((e) => send(res, 500, { error: String(e.message || e) })),
	);
	server.listen(port, "127.0.0.1", () => console.log(`OmegaDev control room: http://localhost:${server.address().port}`));
	return server;
}
