import { Composition } from "remotion";
import demo from "../edits/demo-social.json";
import demoVertical from "../edits/demo-vertical.json";
import type { Edl } from "./edl";
import { calculateTrailerMetadata, Trailer } from "./Trailer";

// Render any edit list with:  npx remotion render Trailer out/x.mp4 --props='{"edl": <json>}'
// or the helper:              node scripts/render.mjs edits/<name>.json
export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="Trailer"
        component={Trailer}
        durationInFrames={300}
        fps={30}
        width={1920}
        height={1080}
        defaultProps={{ edl: demo as Edl }}
        calculateMetadata={calculateTrailerMetadata}
      />
      <Composition
        id="TrailerVertical"
        component={Trailer}
        durationInFrames={300}
        fps={30}
        width={1080}
        height={1920}
        defaultProps={{ edl: demoVertical as Edl }}
        calculateMetadata={calculateTrailerMetadata}
      />
    </>
  );
};
