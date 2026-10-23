// Shared paths and the read-only view of .omegadev/ state. Kept separate from
// omega.mjs so the control room can import it without importing the CLI.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
export const STATE = process.env.OMEGADEV_STATE ? path.resolve(process.env.OMEGADEV_STATE) : path.join(ROOT, ".omegadev");
export const GAMES = path.join(ROOT, "games");

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
	const pitches = fs.existsSync(path.join(STATE, "pitches"))
		? fs.readdirSync(path.join(STATE, "pitches")).filter((f) => f.endsWith(".md"))
		: [];
	return {
		paused: fs.existsSync(path.join(STATE, "paused")),
		studioLock: readJson(path.join(STATE, "locks", "studio.json"), null),
		tasks: readJson(path.join(STATE, "tasks.json"), []),
		agents,
		games,
		review: list("review"),
		tryit: list("tryit"),
		pitches,
	};
}
