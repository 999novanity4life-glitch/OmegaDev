import { test } from "node:test";
import assert from "node:assert/strict";
import { layout, lint, eventFrames, type Edl } from "../src/edl.ts";

const base = (): Edl => ({
  title: "t",
  profile: "social",
  format: "landscape",
  fps: 30,
  music: { src: "m.wav", bpm: 120, source: "original" },
  events: [
    { type: "clip", src: "a.mp4", in: 0, beats: 2 },
    { type: "clip", src: "b.mp4", in: 1, beats: 1 },
    { type: "logo", name: "GAME", seconds: 2 },
  ],
});

test("beats convert to frames at the music tempo", () => {
  const edl = base();
  assert.equal(eventFrames(edl, edl.events[0]), 30); // 2 beats at 120 bpm = 1 s
});

test("layout places events end to end", () => {
  const { placed, totalFrames } = layout(base());
  assert.deepEqual(placed.map((p) => [p.start, p.duration]), [[0, 30], [30, 15], [45, 60]]);
  assert.equal(totalFrames, 105);
});

test("beat cuts do not drift over many odd-tempo beats", () => {
  const edl = base();
  edl.music!.bpm = 127; // 0.4724 s per beat, not a whole number of frames
  edl.events = Array.from({ length: 64 }, () => ({ type: "clip" as const, src: "a.mp4", in: 0, beats: 1 }));
  const { placed } = layout(edl);
  const last = placed[placed.length - 1];
  const exact = (63 * 60 / 127) * 30;
  assert.ok(Math.abs(last.start - exact) <= 0.5, `start ${last.start} vs ${exact}`);
});

test("beats without music is an error", () => {
  const edl = base();
  delete edl.music;
  assert.throws(() => layout(edl));
});

test("music offset delays the first cut", () => {
  const edl = base();
  edl.music!.offset = 0.5;
  assert.equal(layout(edl).placed[0].start, 15);
});

test("social lint: logo first and long titles warn", () => {
  const edl = base();
  edl.events.unshift({ type: "logo", name: "GAME", seconds: 1 });
  edl.events.push({ type: "title", text: "one two three four five six seven", seconds: 1 });
  const msgs = lint(edl).map((i) => i.message).join("\n");
  assert.match(msgs, /open on gameplay/);
  assert.match(msgs, /logo at the end/);
  assert.match(msgs, /keep cards to a few words/);
});

test("store lint enforces Roblox video rules", () => {
  const edl = base();
  edl.profile = "store";
  edl.events = [
    { type: "clip", src: "a.mp4", in: 0, seconds: 8 },
    { type: "title", text: "FREE UGC every round", seconds: 2 },
    { type: "logo", name: "GAME", tagline: "Play now!", seconds: 2 },
  ];
  const errors = lint(edl).filter((i) => i.level === "error").map((i) => i.message).join("\n");
  assert.match(errors, /Roblox audio catalog/);
  assert.match(errors, /claim or ad/);
  assert.match(errors, /logo only/);
});

test("a clean store edit passes", () => {
  const edl = base();
  edl.profile = "store";
  edl.music = { src: "m.wav", bpm: 120, source: "roblox-catalog" };
  edl.events = [
    { type: "clip", src: "a.mp4", in: 0, beats: 8 },
    { type: "title", text: "Chain combos", beats: 2 },
    { type: "clip", src: "b.mp4", in: 0, beats: 8 },
    { type: "logo", name: "GAME", beats: 4 },
  ];
  assert.deepEqual(lint(edl).filter((i) => i.level === "error"), []);
});

test("store videos outside 6-60 s fail", () => {
  const edl = base();
  edl.profile = "store";
  edl.music = { src: "m.wav", bpm: 120, source: "roblox-catalog" };
  edl.events = [{ type: "clip", src: "a.mp4", in: 0, seconds: 3 }];
  assert.ok(lint(edl).some((i) => /6-60 s/.test(i.message)));
});
