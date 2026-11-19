import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import type { Transition } from "../edl";

// Overlays drawn on the first frames of the incoming shot.
// flash: 4-frame white pop. impact: 2 inverted high-contrast frames, the
// anime impact-frame look. whip: directional streak + blur. fade: from black.
export const TransitionIn: React.FC<{ kind: Transition; accent: string }> = ({ kind, accent }) => {
  const frame = useCurrentFrame();
  if (kind === "flash") {
    return (
      <AbsoluteFill
        style={{
          backgroundColor: "white",
          opacity: interpolate(frame, [0, 4], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }),
        }}
      />
    );
  }
  if (kind === "impact" && frame < 3) {
    return (
      <AbsoluteFill
        style={{
          backdropFilter: frame < 2 ? "invert(1) grayscale(1) contrast(4)" : "grayscale(1) contrast(3)",
          backgroundColor: frame === 0 ? "rgba(0,0,0,0.15)" : "transparent",
        }}
      />
    );
  }
  if (kind === "whip" && frame < 6) {
    return (
      <AbsoluteFill
        style={{
          backdropFilter: `blur(${interpolate(frame, [0, 6], [18, 0])}px)`,
          background: `linear-gradient(90deg, transparent, ${accent}55 45%, white 50%, ${accent}55 55%, transparent)`,
          translate: `${interpolate(frame, [0, 6], [-40, 120])}% 0`,
        }}
      />
    );
  }
  if (kind === "fade") {
    return (
      <AbsoluteFill
        style={{
          backgroundColor: "black",
          opacity: interpolate(frame, [0, 10], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }),
        }}
      />
    );
  }
  return null;
};
