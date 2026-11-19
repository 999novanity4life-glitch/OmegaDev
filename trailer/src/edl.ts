// Edit decision list (EDL): a whole trailer as data. Agents write these JSON
// files; Remotion renders them. Pure TypeScript, no imports, so `node --test`
// can run it directly (see scripts/edl.test.ts).
//
// Timing is in MUSIC BEATS by default: "audio first" is the most repeated rule
// from professional trailer editors (Derek Lieu in PC Gamer,
// https://www.pcgamer.com/the-art-of-making-effective-game-trailers), and
// counting in beats keeps every cut on the music without frame math.

export type Profile = "store" | "social";
export type Format = "landscape" | "vertical";
export type Transition = "cut" | "flash" | "impact" | "whip" | "fade";

export type ClipEvent = {
  type: "clip";
  src: string; // path under public/
  in: number; // seconds into the source
  beats?: number; // length on the timeline, in beats...
  seconds?: number; // ...or in seconds
  speed?: number; // playback rate (0.25 = slow-mo); store videos: keep real time where it matters
  zoom?: number; // punch-in at the cut, eased back to 1 (e.g. 1.12)
  transition?: Transition; // how this clip comes in
  shake?: number; // px of beat-synced shake (0 = none)
  label?: string; // what this shot proves (for review only, not rendered)
};

export type TitleEvent = {
  type: "title";
  text: string;
  sub?: string;
  beats?: number;
  seconds?: number;
  transition?: Transition;
};

export type LogoEvent = {
  type: "logo";
  name: string;
  tagline?: string; // social only; store videos may show logo/branding but no promotion
  beats?: number;
  seconds?: number;
  transition?: Transition;
};

export type EdlEvent = ClipEvent | TitleEvent | LogoEvent;

export type Edl = {
  title: string;
  profile: Profile;
  format: Format;
  fps: number;
  music?: {
    src: string;
    bpm: number;
    offset?: number; // seconds before the first downbeat
    volume?: number;
    source: "roblox-catalog" | "licensed" | "original"; // store videos: roblox-catalog only
    hasLyrics?: boolean;
  };
  theme?: { accent?: string; glow?: string };
  letterbox?: boolean;
  events: EdlEvent[];
};

export type Placed = { start: number; duration: number; event: EdlEvent; index: number };

export const SIZES: Record<Format, { width: number; height: number }> = {
  landscape: { width: 1920, height: 1080 },
  vertical: { width: 1080, height: 1920 },
};

export const secondsPerBeat = (bpm: number): number => 60 / bpm;

// Frames for an event, from beats (needs music) or seconds.
export const eventFrames = (edl: Edl, e: EdlEvent): number => {
  if (e.seconds !== undefined) return Math.max(1, Math.round(e.seconds * edl.fps));
  if (e.beats !== undefined) {
    if (!edl.music) throw new Error(`event uses beats but the EDL has no music: ${JSON.stringify(e)}`);
    return Math.max(1, Math.round(e.beats * secondsPerBeat(edl.music.bpm) * edl.fps));
  }
  throw new Error(`event needs beats or seconds: ${JSON.stringify(e)}`);
};

// Lay events end to end after the music offset. Beat positions are computed
// from the running beat count, not by summing rounded frames, so cuts never
// drift off the beat over a long trailer.
export const layout = (edl: Edl): { placed: Placed[]; totalFrames: number } => {
  const placed: Placed[] = [];
  const offsetFrames = Math.round((edl.music?.offset ?? 0) * edl.fps);
  let seconds = 0;
  let cursor = offsetFrames;
  edl.events.forEach((event, index) => {
    let start: number;
    let end: number;
    if (event.seconds === undefined && event.beats !== undefined && edl.music) {
      const spb = secondsPerBeat(edl.music.bpm);
      start = Math.round(((edl.music.offset ?? 0) + seconds) * edl.fps);
      seconds += event.beats * spb;
      end = Math.round(((edl.music.offset ?? 0) + seconds) * edl.fps);
    } else {
      const f = eventFrames(edl, event);
      start = cursor;
      end = cursor + f;
      seconds += f / edl.fps;
    }
    start = Math.max(start, cursor);
    placed.push({ start, duration: Math.max(1, end - start), event, index });
    cursor = start + Math.max(1, end - start);
  });
  return { placed, totalFrames: Math.max(1, cursor) };
};

// Words that turn a gameplay video into an advertisement or a subjective claim.
// Roblox rejects these in store (thumbnail) videos:
// https://create.roblox.com/docs/production/publishing/thumbnails ("Text, Claims, and Advertisements").
const CLAIM_WORDS = [
  "free", "% off", "off!", "sale", "best", "#1", "number one", "ugc", "robux", "giveaway",
  "epic", "amazing", "incredible", "insane", "must play", "play now", "join now", "limited time",
];

export type Issue = { level: "error" | "warn"; message: string };

// Rules for each profile. Store rules come from the Roblox doc above; social
// rules are studio taste (Lieu: gameplay first, logo last, no superlatives).
export const lint = (edl: Edl): Issue[] => {
  const issues: Issue[] = [];
  const err = (message: string) => issues.push({ level: "error", message });
  const warn = (message: string) => issues.push({ level: "warn", message });
  if (!(edl.fps > 0 && edl.fps <= 60)) err("fps must be 1-60");
  if (edl.events.length === 0) err("no events");
  if (edl.music && !(edl.music.bpm >= 40 && edl.music.bpm <= 240)) err("music bpm must be 40-240");
  let total = 0;
  try {
    total = layout(edl).totalFrames / edl.fps;
  } catch (e) {
    err(String((e as Error).message));
  }
  const first = edl.events[0];
  if (first && first.type !== "clip") warn("open on gameplay, not a title or logo (attention drops within seconds)");
  const logoIndex = edl.events.findIndex((e) => e.type === "logo");
  if (logoIndex >= 0 && logoIndex < edl.events.length - 1) warn("put the logo at the end");
  for (const e of edl.events) {
    if (e.type === "clip" && e.speed !== undefined && !(e.speed > 0 && e.speed <= 4)) err(`clip ${e.src}: speed must be in (0, 4]`);
    if (e.type === "clip" && e.in < 0) err(`clip ${e.src}: in must be >= 0`);
    if (e.type === "title" && e.text.split(/\s+/).length > 6) warn(`title "${e.text}" is long; keep cards to a few words`);
  }
  if (edl.profile === "store") {
    if (edl.format !== "landscape") err("store videos are landscape (16:9)");
    if (total > 0 && (total < 6 || total > 60)) err(`store video is ${total.toFixed(1)} s; keep it 6-60 s (Roblox video pilot spec, confirm in Creator Dashboard)`);
    if (edl.music && edl.music.source !== "roblox-catalog") err("store videos may only use music from the Roblox audio catalog");
    if (edl.music?.hasLyrics) err("store videos may not use music with lyrics");
    if (edl.letterbox) warn("letterbox bars hide real gameplay; avoid in store videos");
    for (const e of edl.events) {
      const text = e.type === "title" ? `${e.text} ${e.sub ?? ""}` : e.type === "logo" ? `${e.tagline ?? ""}` : "";
      const lower = text.toLowerCase();
      for (const w of CLAIM_WORDS) if (lower.includes(w)) err(`store video text "${text.trim()}" reads as a claim or ad ("${w}")`);
      if (e.type === "logo" && e.tagline) err("store videos: logo only, no tagline or call to action");
    }
    const titles = edl.events.filter((e) => e.type === "title").length;
    if (titles > 3) warn("store videos: use overlay text sparingly");
  }
  return issues;
};
