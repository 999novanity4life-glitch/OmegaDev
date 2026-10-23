#!/usr/bin/env node
// OmegaDev CLI. Zero dependencies (Node 18+).
// Agents use it to read and write the shared state in .omegadev/ so the
// control room, the Lead and every other agent agree on what is going on.
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { AGENTS, GAMES, ROOT, STATE, readJson, readState } from "./state.mjs";

const TASK_STATUSES = ["queued", "working", "blocked", "needs_you", "done", "later"];
const VERDICTS = ["pending", "approved", "changes", "rejected"];

const now = () => new Date().toISOString();
const ensure = (dir) => fs.mkdirSync(dir, { recursive: true });
const writeJson = (file, value) => {
	ensure(path.dirname(file));
	const tmp = `${file}.${process.pid}.tmp`;
	fs.writeFileSync(tmp, JSON.stringify(value, null, 2) + "\n");
	fs.renameSync(tmp, file);
};
const newId = (prefix) => `${prefix}-${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;
const log = (entry) => {
	ensure(STATE);
	fs.appendFileSync(path.join(STATE, "log.jsonl"), JSON.stringify({ ts: now(), ...entry }) + "\n");
};
const die = (msg) => {
	console.error(`omega: ${msg}`);
	process.exit(1);
};

// --flag value parsing; positional args are kept in order.
function parseArgs(argv) {
	const out = { _: [] };
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a.startsWith("--")) {
			const key = a.slice(2);
			const next = argv[i + 1];
			if (next === undefined || next.startsWith("--")) out[key] = true;
			else out[key] = argv[++i];
		} else out._.push(a);
	}
	return out;
}
const need = (args, key) => (args[key] === undefined || args[key] === true ? die(`missing --${key}`) : args[key]);
const oneOf = (value, allowed, name) =>
	allowed.includes(value) ? value : die(`${name} must be one of: ${allowed.join(", ")} (got "${value}")`);

// ---------- commands ----------
const commands = {
	help() {
		console.log(`omega <command>

Games
  new-game <slug> [--name "Display Name"]   copy template/ into games/<slug>
  check <slug|template>                     format, lint, types, tests, build
  games                                     list games and their stage

State (used by agents)
  status                                    one-screen summary for the Lead
  task add --game g --agent a --title t [--detail d] [--status queued]
  task set <id> [--status s] [--agent a] [--detail d]
  agent <name> --status idle|working [--line "what I'm doing"] [--game g]
  review add --game g --agent a --kind image|video|stage --title t [--file path] [--note n]
  review set <id> --verdict approved|changes|rejected [--comment c]
  tryit add --game g --title t --steps "1. ... 2. ..."
  tryit done <id> [--reply r]
  inbox add <text>        |  inbox take   (Lead reads and clears)
  lock studio <agent>     |  unlock studio
  pause | resume

Running
  room [--port 4321]                        open the control room
  lead [--cycles N] [--sleep 120]           run Lead cycles headless (overnight)`);
	},

	"new-game"(args) {
		const slug = args._[0] || die("usage: omega new-game <slug>");
		if (!/^[a-z0-9-]+$/.test(slug)) die("slug must be lowercase letters, digits and dashes");
		const dest = path.join(GAMES, slug);
		if (fs.existsSync(dest)) die(`games/${slug} already exists`);
		fs.cpSync(path.join(ROOT, "template"), dest, { recursive: true });
		const project = path.join(dest, "default.project.json");
		const pj = readJson(project, {});
		pj.name = slug;
		writeJson(project, pj);
		writeJson(path.join(dest, "game.json"), {
			name: args.name || slug,
			stage: "pitch",
			version: null,
			universeId: null,
			placeId: null,
			created: now(),
		});
		log({ kind: "new-game", slug });
		console.log(`created games/${slug}`);
	},

	games() {
		for (const g of readState().games) console.log(`${g.slug}\t${g.stage || "?"}\t${g.name || ""}`);
	},

	check(args) {
		const target = args._[0] || die("usage: omega check <slug|template>");
		const dir = target === "template" ? path.join(ROOT, "template") : path.join(GAMES, target);
		if (!fs.existsSync(dir)) die(`no such game: ${target}`);
		const rel = path.relative(ROOT, dir);
		const defs = path.join(ROOT, "globalTypes.d.luau");
		const steps = [
			["StyLua", "stylua", ["--check", `${rel}/src`, `${rel}/tests`], ROOT],
			["selene", "selene", [`${rel}/src`], ROOT],
			["sourcemap", "rojo", ["sourcemap", "default.project.json", "--output", "sourcemap.json"], dir],
			[
				"luau-lsp",
				"luau-lsp",
				[
					"analyze",
					"--platform=roblox",
					"--sourcemap=sourcemap.json",
					`--definitions=@roblox=${defs}`,
					`--base-luaurc=${path.join(ROOT, ".luaurc")}`,
					"--ignore=Packages/**",
					"src",
				],
				dir,
			],
			["tests", "lune", ["run", "tests/run"], dir],
			["build", "rojo", ["build", "default.project.json", "--output", "build.rbxl"], dir],
		];
		if (!fs.existsSync(defs)) {
			console.log("luau-lsp needs globalTypes.d.luau in the repo root. Download it with:");
			console.log(
				"  curl -sSfLo globalTypes.d.luau https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau",
			);
		}
		let failed = 0;
		for (const [name, cmd, cmdArgs, cwd] of steps) {
			if (name === "luau-lsp" && !fs.existsSync(defs)) {
				console.log(`SKIP  ${name} (no globalTypes.d.luau)`);
				failed++;
				continue;
			}
			const r = spawnSync(cmd, cmdArgs, { cwd, encoding: "utf8" });
			const ok = r.status === 0;
			console.log(`${ok ? "PASS" : "FAIL"}  ${name}`);
			if (!ok) {
				failed++;
				console.log(((r.stdout || "") + (r.stderr || "") + (r.error ? String(r.error) : "")).trim());
			}
		}
		log({ kind: "check", target, failed });
		process.exit(failed ? 1 : 0);
	},

	status() {
		const s = readState();
		console.log(`paused: ${s.paused}   studio: ${s.studioLock ? `held by ${s.studioLock.agent}` : "free"}`);
		console.log("\nGAMES");
		for (const g of s.games) console.log(`  ${g.slug} [${g.stage}] v${g.version ?? "-"}`);
		console.log("\nTASKS (not done)");
		for (const t of s.tasks.filter((t) => t.status !== "done"))
			console.log(`  ${t.id} ${t.status.padEnd(9)} ${t.agent.padEnd(12)} ${t.game}: ${t.title}`);
		console.log("\nREVIEW VERDICTS WAITING FOR AN AGENT (changes/rejected not yet picked up)");
		for (const r of s.review.filter((r) => ["changes", "rejected"].includes(r.verdict) && !r.pickedUp))
			console.log(`  ${r.id} ${r.verdict} ${r.agent} ${r.game}: ${r.title} — ${r.comment || ""}`);
		console.log(`\nREVIEW PENDING HUMAN: ${s.review.filter((r) => r.verdict === "pending").length}`);
		console.log(`TRY-IT CARDS OPEN: ${s.tryit.filter((t) => t.status === "open").length}`);
		const inbox = path.join(STATE, "inbox.jsonl");
		const n = fs.existsSync(inbox) ? fs.readFileSync(inbox, "utf8").trim().split("\n").filter(Boolean).length : 0;
		console.log(`INBOX MESSAGES: ${n}`);
	},

	task(args) {
		const [sub, id] = args._;
		const file = path.join(STATE, "tasks.json");
		const tasks = readJson(file, []);
		if (sub === "add") {
			const task = {
				id: newId("t"),
				game: need(args, "game"),
				agent: oneOf(need(args, "agent"), AGENTS, "agent"),
				title: need(args, "title"),
				detail: args.detail || "",
				status: oneOf(args.status || "queued", TASK_STATUSES, "status"),
				created: now(),
				updated: now(),
			};
			tasks.push(task);
			writeJson(file, tasks);
			log({ kind: "task-add", id: task.id, agent: task.agent, title: task.title });
			console.log(task.id);
		} else if (sub === "set") {
			const task = tasks.find((t) => t.id === id) || die(`no task ${id}`);
			if (args.status) task.status = oneOf(args.status, TASK_STATUSES, "status");
			if (args.agent) task.agent = oneOf(args.agent, AGENTS, "agent");
			if (args.detail) task.detail = args.detail;
			task.updated = now();
			writeJson(file, tasks);
			log({ kind: "task-set", id, status: task.status });
		} else die("usage: omega task add|set");
	},

	agent(args) {
		const name = oneOf(args._[0], AGENTS, "agent");
		writeJson(path.join(STATE, "agents", `${name}.json`), {
			status: oneOf(need(args, "status"), ["idle", "working"], "status"),
			line: args.line || "",
			game: args.game || null,
			updated: now(),
		});
	},

	review(args) {
		const [sub, id] = args._;
		const dir = path.join(STATE, "review");
		if (sub === "add") {
			const item = {
				id: newId("r"),
				game: need(args, "game"),
				agent: oneOf(need(args, "agent"), AGENTS, "agent"),
				kind: oneOf(need(args, "kind"), ["image", "video", "stage"], "kind"),
				title: need(args, "title"),
				note: args.note || "",
				file: null,
				verdict: "pending",
				comment: "",
				created: now(),
				updated: now(),
			};
			if (args.file) {
				const src = path.resolve(args.file);
				if (!fs.existsSync(src)) die(`file not found: ${args.file}`);
				const media = path.join(dir, "media");
				ensure(media);
				const name = `${item.id}${path.extname(src)}`;
				fs.copyFileSync(src, path.join(media, name));
				item.file = `media/${name}`;
			}
			writeJson(path.join(dir, `${item.id}.json`), item);
			log({ kind: "review-add", id: item.id, title: item.title });
			console.log(item.id);
		} else if (sub === "set") {
			const file = path.join(dir, `${id}.json`);
			const item = readJson(file, null) || die(`no review item ${id}`);
			if (args.verdict) {
				item.verdict = oneOf(args.verdict, VERDICTS, "verdict");
				item.pickedUp = false;
			}
			if (args.comment) item.comment = args.comment;
			if (args["picked-up"]) item.pickedUp = true;
			item.updated = now();
			writeJson(file, item);
			log({ kind: "review-set", id, verdict: item.verdict });
		} else die("usage: omega review add|set");
	},

	tryit(args) {
		const [sub, id] = args._;
		const dir = path.join(STATE, "tryit");
		if (sub === "add") {
			const card = {
				id: newId("y"),
				game: need(args, "game"),
				title: need(args, "title"),
				steps: need(args, "steps"),
				status: "open",
				reply: "",
				created: now(),
			};
			writeJson(path.join(dir, `${card.id}.json`), card);
			console.log(card.id);
		} else if (sub === "done") {
			const file = path.join(dir, `${id}.json`);
			const card = readJson(file, null) || die(`no card ${id}`);
			card.status = "done";
			if (args.reply) card.reply = args.reply;
			writeJson(file, card);
		} else die("usage: omega tryit add|done");
	},

	inbox(args) {
		const file = path.join(STATE, "inbox.jsonl");
		const [sub, ...rest] = args._;
		if (sub === "add") {
			ensure(STATE);
			fs.appendFileSync(file, JSON.stringify({ ts: now(), text: rest.join(" ") }) + "\n");
		} else if (sub === "take") {
			if (!fs.existsSync(file)) return;
			process.stdout.write(fs.readFileSync(file, "utf8"));
			fs.renameSync(file, path.join(STATE, `inbox.read.${Date.now()}.jsonl`));
		} else die("usage: omega inbox add|take");
	},

	lock(args) {
		const agent = oneOf(args._[1], AGENTS, "agent");
		const file = path.join(STATE, "locks", "studio.json");
		const held = readJson(file, null);
		// A lock older than 45 minutes is treated as abandoned (crashed agent).
		if (held && held.agent !== agent && Date.now() - Date.parse(held.since) < 45 * 60 * 1000)
			die(`studio is held by ${held.agent} since ${held.since}`);
		writeJson(file, { agent, since: now() });
		console.log(`studio locked by ${agent}`);
	},

	unlock() {
		fs.rmSync(path.join(STATE, "locks", "studio.json"), { force: true });
	},

	pause() {
		ensure(STATE);
		fs.writeFileSync(path.join(STATE, "paused"), now());
		console.log("paused: agents finish their current step and stop");
	},

	resume() {
		fs.rmSync(path.join(STATE, "paused"), { force: true });
		console.log("resumed");
	},

	async room(args) {
		const { startRoom } = await import("../control-room/server.mjs");
		startRoom(Number(args.port) || 4321);
	},

	async lead(args) {
		const cycles = Number(args.cycles) || 1;
		const sleepSec = Number(args.sleep) || 120;
		for (let i = 1; i <= cycles; i++) {
			if (fs.existsSync(path.join(STATE, "paused"))) {
				console.log("paused; stopping");
				break;
			}
			console.log(`\n=== Lead cycle ${i}/${cycles} ${now()} ===`);
			const r = spawnSync(
				"claude",
				["-p", "--agent", "lead", "Run one Lead cycle now, following your instructions exactly."],
				{ cwd: ROOT, stdio: "inherit" },
			);
			log({ kind: "lead-cycle", i, exit: r.status });
			if (r.error) die(`could not start claude: ${r.error.message}`);
			if (i < cycles) await new Promise((res) => setTimeout(res, sleepSec * 1000));
		}
	},
};

const isMain = process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMain) {
	const [cmd, ...rest] = process.argv.slice(2);
	const fn = commands[cmd || "help"];
	if (!fn) die(`unknown command "${cmd}". Try: omega help`);
	await fn(parseArgs(rest));
}
