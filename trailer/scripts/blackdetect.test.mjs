import { test } from "node:test";
import assert from "node:assert/strict";
import { parseBlackdetect, takesFromRuns, takeNamesFromLog } from "./lib/blackdetect.mjs";

const sample = `
[blackdetect @ 0x1] black_start:2.0 black_end:2.5 black_duration:0.5
[blackdetect @ 0x1] black_start:9.1 black_end:9.6 black_duration:0.5
[blackdetect @ 0x1] black_start:12 black_end:12.1 black_duration:0.1
[blackdetect @ 0x1] black_start:20.0 black_end:20.52 black_duration:0.52
`;

test("parses blackdetect lines", () => {
  assert.equal(parseBlackdetect(sample).length, 4);
});

test("slates split takes; short dips inside a take are ignored", () => {
  const takes = takesFromRuns(parseBlackdetect(sample), 30);
  assert.deepEqual(takes, [
    { start: 2.5, end: 9.1, duration: 6.6 },
    { start: 9.6, end: 20.0, duration: 10.4 },
    { start: 20.52, end: 30, duration: 9.48 },
  ]);
});

test("reads take names from the Studio console log", () => {
  assert.deepEqual(takeNamesFromLog("x\nOMEGA_TAKE combo start\nOMEGA_TAKE combo shot=1\nOMEGA_TAKE ult start"), ["combo", "ult"]);
});
