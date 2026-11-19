import { fontFamily } from "./font";
import { AbsoluteFill, Easing, interpolate, useCurrentFrame, useVideoConfig } from "remotion";

// Kinetic title card: slams in from big to size, chrome gradient fill with an
// accent glow, a light sweep across the letters, then a quick exit.
export const Title: React.FC<{ text: string; sub?: string; accent: string; glow: string; durationInFrames: number; vertical: boolean }> = ({
  text,
  sub,
  accent,
  glow,
  durationInFrames,
  vertical,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const out = Math.max(1, durationInFrames - 5);
  return (
    <AbsoluteFill
      style={{
        backgroundColor: "#0b0c0e",
        backgroundImage: `radial-gradient(ellipse at 50% 55%, ${glow}33 0%, transparent 60%), repeating-linear-gradient(45deg, #15171b 0 6px, #0e0f12 6px 12px)`,
        justifyContent: "center",
        alignItems: "center",
        flexDirection: "column",
      }}
    >
      <div
        style={{
          fontFamily,
          fontSize: vertical ? 150 : 170,
          lineHeight: 1,
          letterSpacing: interpolate(frame, [0, 0.4 * fps], [24, 4], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }),
          textAlign: "center",
          padding: "0 60px",
          textTransform: "uppercase",
          backgroundImage: `linear-gradient(180deg, #ffffff 0%, #c9ced6 45%, #6b717c 52%, #e9edf2 70%, #9aa1ab 100%)`,
          WebkitBackgroundClip: "text",
          color: "transparent",
          filter: `drop-shadow(0 0 18px ${accent}) drop-shadow(0 6px 0 #000)`,
          scale: interpolate(frame, [0, 0.18 * fps, out, durationInFrames], [2.2, 1, 1, 0.9], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: Easing.bezier(0.16, 1, 0.3, 1),
            output: "perceptual-scale",
          }),
          opacity: interpolate(frame, [0, 2, out, durationInFrames], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }),
        }}
      >
        {text}
      </div>
      {sub ? (
        <div
          style={{
            fontFamily,
            fontSize: vertical ? 56 : 52,
            color: accent,
            marginTop: 28,
            letterSpacing: 6,
            textTransform: "uppercase",
            opacity: interpolate(frame, [0.25 * fps, 0.45 * fps, out, durationInFrames], [0, 1, 1, 0], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
            translate: `0 ${interpolate(frame, [0.25 * fps, 0.45 * fps], [20, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })}px`,
          }}
        >
          {sub}
        </div>
      ) : null}
      <AbsoluteFill
        style={{
          background: "linear-gradient(100deg, transparent 40%, rgba(255,255,255,0.35) 50%, transparent 60%)",
          translate: `${interpolate(frame, [0.15 * fps, 0.7 * fps], [-100, 100], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })}% 0`,
          mixBlendMode: "overlay",
        }}
      />
    </AbsoluteFill>
  );
};
