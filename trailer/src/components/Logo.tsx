import { fontFamily } from "./font";
import { AbsoluteFill, Easing, interpolate, useCurrentFrame, useVideoConfig } from "remotion";

// End card: logo lockup grows out of a light burst; tagline (social only) under it.
export const Logo: React.FC<{ name: string; tagline?: string; accent: string; vertical: boolean }> = ({ name, tagline, accent, vertical }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  return (
    <AbsoluteFill style={{ backgroundColor: "#07080a", justifyContent: "center", alignItems: "center", flexDirection: "column" }}>
      <AbsoluteFill
        style={{
          background: `radial-gradient(circle at 50% 50%, ${accent} 0%, ${accent}55 18%, transparent 55%)`,
          opacity: interpolate(frame, [0, 4, 0.8 * fps], [0, 1, 0.35], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }),
          scale: interpolate(frame, [0, 0.8 * fps], [0.3, 1.4], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: Easing.bezier(0.16, 1, 0.3, 1),
          }),
        }}
      />
      <div
        style={{
          fontFamily,
          fontSize: vertical ? 160 : 200,
          lineHeight: 1,
          textTransform: "uppercase",
          letterSpacing: 6,
          backgroundImage: "linear-gradient(180deg, #fff 0%, #d4d8de 46%, #5d636d 52%, #f1f3f6 72%, #a4aab3 100%)",
          WebkitBackgroundClip: "text",
          color: "transparent",
          filter: `drop-shadow(0 0 26px ${accent}) drop-shadow(0 8px 0 #000)`,
          scale: interpolate(frame, [0, 0.35 * fps], [0.6, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: Easing.spring({ damping: 12 }),
            output: "perceptual-scale",
          }),
        }}
      >
        {name}
      </div>
      {tagline ? (
        <div
          style={{
            fontFamily,
            fontSize: 54,
            marginTop: 30,
            color: "white",
            letterSpacing: 8,
            textTransform: "uppercase",
            opacity: interpolate(frame, [0.4 * fps, 0.6 * fps], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }),
          }}
        >
          {tagline}
        </div>
      ) : null}
    </AbsoluteFill>
  );
};
