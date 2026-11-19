#!/usr/bin/env node
// Split one long screen recording into takes at TrailerMode's black slates.
//   node scripts/split-takes.mjs <recording.mov> [console-log.txt]
// Writes public/takes/<name>.mp4 (names from the log, else take-01, ...).
import { execFileSync, spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { parseBlackdetect, takesFromRuns, takeNamesFromLog } from "./lib/blackdetect.mjs";

const [input, logFile] = process.argv.slice(2);
if (!input) {
  console.error("usage: split-takes.mjs <recording> [console-log]");
  process.exit(1);
}
const probe = execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", input]).toString();
const duration = parseFloat(probe);
const det = spawnSync("ffmpeg", ["-hide_banner", "-i", input, "-vf", "blackdetect=d=0.3:pix_th=0.05", "-an", "-f", "null", "-"], {
  encoding: "utf8",
});
const takes = takesFromRuns(parseBlackdetect(det.stderr), duration);
const names = logFile ? takeNamesFromLog(fs.readFileSync(logFile, "utf8")) : [];
const outDir = path.join(path.dirname(new URL(import.meta.url).pathname), "..", "public", "takes");
fs.mkdirSync(outDir, { recursive: true });
takes.forEach((t, i) => {
  const name = names[i] ?? `take-${String(i + 1).padStart(2, "0")}`;
  const out = path.join(outDir, `${name}.mp4`);
  // Re-encode (not stream copy) so cuts are frame-accurate; CRF 16 keeps detail for the edit.
  execFileSync("ffmpeg", ["-loglevel", "error", "-y", "-ss", String(t.start), "-i", input, "-t", String(t.duration),
    "-c:v", "libx264", "-crf", "16", "-preset", "medium", "-pix_fmt", "yuv420p", "-an", out]);
  console.log(`${name}\t${t.start.toFixed(2)}s\t${t.duration}s\t${out}`);
});
if (takes.length === 0) console.log("no slates found; did the recording include TrailerMode.take()?");
