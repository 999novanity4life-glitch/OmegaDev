// Parse ffmpeg blackdetect output into takes. TrailerMode (Studio) opens every
// take with a 0.5 s black slate, so each black run of ~0.5 s marks a take
// start; the next slate (or the end of the file) ends it.
export const parseBlackdetect = (stderr) => {
  const runs = [];
  const re = /black_start:([\d.]+)\s+black_end:([\d.]+)\s+black_duration:([\d.]+)/g;
  let m;
  while ((m = re.exec(stderr))) runs.push({ start: +m[1], end: +m[2], duration: +m[3] });
  return runs;
};

export const takesFromRuns = (runs, fileDuration, { minSlate = 0.35, maxSlate = 1.2, minTake = 0.5 } = {}) => {
  const slates = runs.filter((r) => r.duration >= minSlate && r.duration <= maxSlate);
  const takes = [];
  slates.forEach((s, i) => {
    const end = i + 1 < slates.length ? slates[i + 1].start : fileDuration;
    if (end - s.end >= minTake) takes.push({ start: s.end, end, duration: +(end - s.end).toFixed(3) });
  });
  return takes;
};

// "OMEGA_TAKE <name> start" lines from the Studio console, in order.
export const takeNamesFromLog = (log) =>
  [...log.matchAll(/OMEGA_TAKE (\S+) start/g)].map((m) => m[1]);
