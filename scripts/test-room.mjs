// Smoke test for the state CLI and control room, against a throwaway state dir.
import assert from "node:assert/strict";
import { execFileSync, spawn } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const state = fs.mkdtempSync(path.join(os.tmpdir(), "omegadev-"));
process.env.OMEGADEV_STATE = state;
const omega = (...args) => execFileSync("node", [path.join(ROOT, "scripts/omega.mjs"), ...args], { encoding: "utf8", env: process.env }).trim();

const taskId = omega("task", "add", "--game", "demo", "--agent", "builder", "--title", "Core verb works");
omega("task", "set", taskId, "--status", "working");
omega("agent", "builder", "--status", "working", "--game", "demo", "--line", "wiring the roll button");
const png = path.join(state, "shot.png");
fs.writeFileSync(png, Buffer.from("89504e470d0a1a0a", "hex"));
const reviewId = omega("review", "add", "--game", "demo", "--agent", "splash", "--kind", "image", "--title", "Icon A", "--file", png);
const cardId = omega("tryit", "add", "--game", "demo", "--title", "Two-account raid", "--steps", "1. Join on PC 2. Quick join on phone");
assert.throws(() => omega("task", "add", "--game", "demo", "--agent", "nobody", "--title", "x"), /agent must be one of/);
const docReview = omega("review", "add", "--game", "demo", "--agent", "pulse", "--kind", "doc", "--title", "Chapter", "--doc", "vault/00 Start Here.md");
assert.throws(() => omega("review", "add", "--game", "demo", "--agent", "pulse", "--kind", "doc", "--title", "x", "--doc", "../secrets.md"), /doc not found/);

const { startRoom } = await import("../control-room/server.mjs");
const server = startRoom(0);
await new Promise((r) => server.once("listening", r));
const base = `http://127.0.0.1:${server.address().port}`;
const post = (p, body) => fetch(base + p, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });

try {
	const s = await (await fetch(`${base}/api/state`)).json();
	assert.equal(s.tasks[0].status, "working");
	assert.equal(s.agents.builder.status, "working");
	assert.equal(s.review[0].verdict, "pending");
	assert.equal((await fetch(`${base}/${s.review[0].file}`)).status, 200);
	assert.equal((await fetch(`${base}/`)).status, 200);
	const lib = await (await fetch(`${base}/api/library`)).json();
	assert.ok(lib.some((d) => d.group === "Studio playbook" && d.path.startsWith("vault/")), "library lists the vault");
	assert.ok(lib.every((d) => typeof d.title === "string" && typeof d.text === "string" && !d.path.includes("..")), "library entries are well formed");
	assert.equal((await fetch(`${base}/api/library/../../etc/passwd`)).status, 404);

	assert.equal((await post("/api/verdict", { id: reviewId, verdict: "changes", comment: "bigger text" })).status, 200);
	assert.equal((await post("/api/verdict", { id: "../../etc/passwd", verdict: "approved" })).status, 404);
	assert.equal((await post("/api/tryit", { id: cardId, reply: "worked" })).status, 200);
	assert.equal((await post("/api/ask", { text: "make the boss harder" })).status, 200);
	const form = await fetch(`${base}/api/ask`, { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body: "text=x" });
	assert.equal(form.status, 415);

	assert.match(omega("status"), /changes splash demo: Icon A — bigger text/);

	// Polish with Fable: the room accepts it, status lists it, tasks can carry the model.
	assert.equal((await post("/api/verdict", { id: docReview, verdict: "polish", comment: "make it shine" })).status, 200);
	assert.equal((await post("/api/verdict", { id: docReview, verdict: "fable-max" })).status, 400);
	assert.match(omega("status"), /polish pulse demo: Chapter — make it shine/);
	omega("task", "add", "--game", "demo", "--agent", "pulse", "--title", "Polish pass on Chapter", "--model", "fable", "--from", "human");
	assert.match(omega("status"), /Polish pass on Chapter \[fable\]/);
	assert.throws(() => omega("task", "add", "--game", "demo", "--agent", "pulse", "--title", "x", "--model", "gpt"), /model must be one of/);

	// Live feed: status lines with a screenshot land on Today, newest first, and the shot is served.
	omega("agent", "frame", "--status", "working", "--game", "demo", "--line", "Uploading art to Roblox", "--shot", png);
	assert.throws(() => omega("agent", "frame", "--status", "working", "--line", "x", "--shot", path.join(state, "tasks.json")), /--shot must be/);
	const fed = (await (await fetch(`${base}/api/state`)).json()).feed;
	assert.equal(fed[0].line, "Uploading art to Roblox");
	assert.match(fed[0].shot, /^media\/f-[\w]+\.png$/);
	assert.equal((await fetch(`${base}/${fed[0].shot}`)).status, 200);
	assert.ok(fed.some((f) => f.line === "Sent for your review: Icon A"), "review items show in the feed");

	// Usage meter: a Claude Code JSON report becomes one usage row.
	const { parseRunReport } = await import("./omega.mjs");
	const rep = parseRunReport('noise\n{"type":"result","result":"moved 2 tasks","total_cost_usd":1.25,"num_turns":9,"usage":{"input_tokens":100,"output_tokens":50,"cache_read_input_tokens":1000},"modelUsage":{"claude-fable-5-2":{"costUSD":1}}}');
	assert.equal(rep.result, "moved 2 tasks");
	assert.equal(rep.usage.tokens, 1150);
	assert.equal(rep.usage.costUsd, 1.25);
	assert.deepEqual(Object.keys(rep.usage.models), ["claude-fable-5-2"]);
	assert.equal(parseRunReport("not json"), null);
	fs.appendFileSync(path.join(state, "usage.jsonl"), JSON.stringify({ ts: new Date().toISOString(), cycle: 1, ...rep.usage }) + "\n");
	const usage = (await (await fetch(`${base}/api/state`)).json()).usage;
	assert.equal(usage.today.cycles, 1);
	assert.equal(usage.week.tokens, 1150);
	assert.match(omega("usage"), /today\s+1 cycles\s+1150 tokens/);
	assert.match(omega("inbox", "take"), /make the boss harder/);
	omega("pause");
	assert.equal((await (await fetch(`${base}/api/state`)).json()).paused, true);
	// The CLI entry point must start the server too (it once deadlocked on a circular import).
	const cli = spawn("node", [path.join(ROOT, "scripts/omega.mjs"), "room", "--port", "43219"], { env: process.env });
	try {
		let ok = false;
		for (let i = 0; i < 50 && !ok; i++) {
			await new Promise((r) => setTimeout(r, 100));
			ok = await fetch("http://127.0.0.1:43219/api/state").then((r) => r.ok, () => false);
		}
		assert.ok(ok, "`omega room` did not start the control room");
	} finally {
		cli.kill();
	}
	console.log("control room smoke test: PASS");
} finally {
	server.close();
	fs.rmSync(state, { recursive: true, force: true });
}
