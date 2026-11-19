import { loadFont } from "@remotion/fonts";
import { staticFile } from "remotion";

// Anton (SIL OFL 1.1, public/fonts/OFL-Anton.txt), bundled so renders work
// offline and on any machine. Swap per game's style bible.
export const fontFamily = "Anton";
loadFont({ family: fontFamily, url: staticFile("fonts/Anton-Regular.ttf"), weight: "400" });
