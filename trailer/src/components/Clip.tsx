import { Video } from "@remotion/media";
import { AbsoluteFill, Easing, interpolate, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import type { ClipEvent } from "../edl";
import { beatPulse } from "./beat";

// One gameplay shot: trimmed source, optional slow-mo, a punch-in zoom at the
// cut that eases out (sells the hit), and optional shake on every beat.
export const Clip: React.FC<{ clip: ClipEvent; bpm?: number; globalStart: number }> = ({ clip, bpm, globalStart }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const zoom = clip.zoom ?? 1;
  const shake = clip.shake ?? 0;
  const pulse = bpm ? beatPulse(frame + globalStart, fps, bpm) : 0;
  const dx = shake ? Math.sin((frame + globalStart) * 2.7) * shake * pulse : 0;
  const dy = shake ? Math.cos((frame + globalStart) * 3.1) * shake * pulse : 0;
  return (
    <AbsoluteFill style={{ backgroundColor: "black", overflow: "hidden" }}>
      <AbsoluteFill
        style={{
          scale: interpolate(frame, [0, 0.35 * fps], [zoom, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: Easing.bezier(0.16, 1, 0.3, 1),
          }),
          translate: `${dx}px ${dy}px`,
        }}
      >
        <Video
          src={staticFile(clip.src)}
          trimBefore={Math.round(clip.in * fps)}
          playbackRate={clip.speed ?? 1}
          muted
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
        />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
