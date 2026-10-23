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
	};
}
