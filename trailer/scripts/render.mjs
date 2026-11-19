#!/usr/bin/env node
// Lint an edit list, then render it.
//   node scripts/render.mjs edits/<name>.json [out.mp4] [extra remotion flags]
// Store edits that break Roblox's video rules stop here instead of wasting one
// of the 3 monthly uploads.
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { lint } from "../src/edl.ts";

const [file, outArg, ...rest] = process.argv.slice(2);
if (!file) {
  console.error("usage: render.mjs edits/<name>.json [out.mp4]");
  process.exit(1);
}
const edl = JSON.parse(fs.readFileSync(file, "utf8"));
const issues = lint(edl);
for (const i of issues) console.log(`${i.level.toUpperCase()}  ${i.message}`);
if (issues.some((i) => i.level === "error")) process.exit(1);
const out = outArg ?? path.join("out", path.basename(file, ".json") + ".mp4");
const id = edl.format === "vertical" ? "TrailerVertical" : "Trailer";
const props = path.join("out", `.props-${path.basename(file)}`);
fs.mkdirSync("out", { recursive: true });
fs.writeFileSync(props, JSON.stringify({ edl }));
const args = ["remotion", "render", id, out, `--props=${props}`, "--codec=h264", "--crf=18", ...rest];
if (process.env.REMOTION_BROWSER) args.push(`--browser-executable=${process.env.REMOTION_BROWSER}`);
const r = spawnSync("npx", args, { stdio: "inherit" });
process.exit(r.status ?? 1);
