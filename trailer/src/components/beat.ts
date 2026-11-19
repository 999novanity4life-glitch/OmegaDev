// 1 on the beat, decaying to 0 before the next one (for beat-synced pulses).
export const beatPulse = (frame: number, fps: number, bpm: number, offset = 0): number => {
  const beatFrames = (60 / bpm) * fps;
  const t = frame - offset * fps;
  if (t < 0) return 0;
  const phase = (t % beatFrames) / beatFrames;
  return Math.exp(-phase * 6);
};
