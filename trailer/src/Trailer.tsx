import { Audio } from "@remotion/media";
import { AbsoluteFill, CalculateMetadataFunction, Interactive, Sequence, staticFile } from "remotion";
import { Clip } from "./components/Clip";
import { Logo } from "./components/Logo";
import { Title } from "./components/Title";
import { TransitionIn } from "./components/Transitions";
import { layout, SIZES, type Edl } from "./edl";

export type TrailerProps = { edl: Edl };

export const calculateTrailerMetadata: CalculateMetadataFunction<TrailerProps> = ({ props }) => {
  const { totalFrames } = layout(props.edl);
  const size = SIZES[props.edl.format];
  return { durationInFrames: totalFrames, fps: props.edl.fps, width: size.width, height: size.height };
};

export const Trailer: React.FC<TrailerProps> = ({ edl }) => {
  const { placed } = layout(edl);
  const accent = edl.theme?.accent ?? "#ff8a1f";
  const glow = edl.theme?.glow ?? "#ffb15c";
  const vertical = edl.format === "vertical";
  return (
    <AbsoluteFill style={{ backgroundColor: "black" }}>
      {placed.map(({ start, duration, event, index }) => (
        <Sequence key={index} name={`${index + 1} ${event.type}`} from={start} durationInFrames={duration} layout="absolute-fill">
          {event.type === "clip" ? <Clip clip={event} bpm={edl.music?.bpm} globalStart={start} /> : null}
          {event.type === "title" ? (
            <Title text={event.text} sub={event.sub} accent={accent} glow={glow} durationInFrames={duration} vertical={vertical} />
          ) : null}
          {event.type === "logo" ? (
            <Logo name={event.name} tagline={edl.profile === "store" ? undefined : event.tagline} accent={accent} vertical={vertical} />
          ) : null}
          <TransitionIn kind={event.transition ?? "cut"} accent={accent} />
        </Sequence>
      ))}
      {edl.letterbox ? (
        <>
          <Interactive.Div name="Letterbox top" style={{ position: "absolute", top: 0, left: 0, right: 0, height: "11%", backgroundColor: "black" }} />
          <Interactive.Div name="Letterbox bottom" style={{ position: "absolute", bottom: 0, left: 0, right: 0, height: "11%", backgroundColor: "black" }} />
        </>
      ) : null}
      {edl.music ? <Audio src={staticFile(edl.music.src)} volume={edl.music.volume ?? 0.9} /> : null}
    </AbsoluteFill>
  );
};
