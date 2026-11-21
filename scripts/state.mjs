// Shared paths and the read-only view of .omegadev/ state. Kept separate from
// omega.mjs so the control room can import it without importing the CLI.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
export const STATE = process.env.OMEGADEV_STATE ? path.resolve(process.env.OMEGADEV_STATE) : path.join(ROOT, ".omegadev");
export const GAMES = path.join(ROOT, "games");
// Pitches are committed so ones written in the cloud reach every machine.
// .omegadev/pitches is still read for older local pitches.
export const PITCH_DIRS = [path.join(ROOT, "pitches"), path.join(STATE, "pitches")];

export const AGENTS = [
	"lead", "pulse", "architect", "builder", "scenic", "frame", "librarian",
	"balance", "splash", "playtest", "kid-tester", "producer", "liveops", "code-reviewer",
];

export const readJson = (file, fallback) => {
	try {
		return JSON.parse(fs.readFileSync(file, "utf8"));
	} catch {
		return fallback;
	}
};

// Last lines of a .jsonl file in the state dir (bad lines are skipped).
const tailJsonl = (name, n) => {
	const file = path.join(STATE, name);
	if (!fs.existsSync(file)) return [];
	return fs
		.readFileSync(file, "utf8")
		.trim()
		.split("\n")
		.slice(-n)
		.map((l) => {
			try {
				return JSON.parse(l);
			} catch {
				return null;
			}
		})
		.filter(Boolean);
};

// What the Lead cycles used, from each run's own report (`omega lead` writes usage.jsonl).
// costUsd is the API-equivalent price Claude Code reports; on a subscription plan it
// counts toward plan limits instead of being billed.
export function usageSummary() {
	const rows = tailJsonl("usage.jsonl", 5000);
	const since = (ms) => rows.filter((r) => Date.now() - Date.parse(r.ts) < ms);
	const sum = (list) => ({
		cycles: list.length,
		tokens: list.reduce((a, r) => a + (r.tokens || 0), 0),
		costUsd: list.reduce((a, r) => a + (r.costUsd || 0), 0),
	});
	const midnight = new Date();
	midnight.setHours(0, 0, 0, 0);
	return {
		today: sum(since(Date.now() - midnight.getTime())),
		week: sum(since(7 * 86400000)),
		last: rows.at(-1) || null,
	};
}

export function readState() {
	const list = (dir) => {
		const full = path.join(STATE, dir);
		if (!fs.existsSync(full)) return [];
		return fs
			.readdirSync(full)
			.filter((f) => f.endsWith(".json"))
			.map((f) => readJson(path.join(full, f), null))
			.filter(Boolean);
	};
	const games = fs.existsSync(GAMES)
		? fs
				.readdirSync(GAMES, { withFileTypes: true })
				.filter((d) => d.isDirectory())
				.map((d) => ({ slug: d.name, ...readJson(path.join(GAMES, d.name, "game.json"), {}) }))
		: [];
	const agents = Object.fromEntries(
		AGENTS.map((name) => [name, readJson(path.join(STATE, "agents", `${name}.json`), { status: "idle", line: "" })]),
	);
	const pitches = [
		...new Set(
			PITCH_DIRS.filter((d) => fs.existsSync(d)).flatMap((d) => fs.readdirSync(d).filter((f) => f.endsWith(".md"))),
		),
	].sort();
	return {
		paused: fs.existsSync(path.join(STATE, "paused")),
		studioLock: readJson(path.join(STATE, "locks", "studio.json"), null),
		tasks: readJson(path.join(STATE, "tasks.json"), []),
		agents,
		games,
		review: list("review"),
		tryit: list("tryit"),
		pitches,
		feed: tailJsonl("feed.jsonl", 40).reverse(),
		usage: usageSummary(),
	};
}
