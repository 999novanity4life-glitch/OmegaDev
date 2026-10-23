// Slime Rise HUD icons: original chunky cartoon icons (thick plum outline,
// bright fill, white gloss). Renders each to 256px PNG plus a contact sheet.
import { Resvg } from "@resvg/resvg-js";
import { writeFileSync, mkdirSync } from "node:fs";

const OUT = "#1A1230"; // outline
const SW = 9; // outline width at 128 units
const GREEN = "#6BFF3D";
const GREEN_D = "#2FBF1A";
const GOLD = "#FFC93C";
const GOLD_D = "#E8901A";
const TEAL = "#3DE8FF";
const PURPLE = "#A66BFF";

const wrap = (body, defs = "") =>
	`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="256" height="256"><defs>${defs}</defs>${body}</svg>`;
const grad = (id, a, b) =>
	`<linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${a}"/><stop offset="1" stop-color="${b}"/></linearGradient>`;
const outlined = (d, fill, extra = "") =>
	`<path d="${d}" fill="${fill}" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round" stroke-linecap="round" ${extra}/>`;
const gloss = (d) => `<path d="${d}" fill="#FFFFFF" opacity="0.55"/>`;

const icons = {
	crown: wrap(
		outlined("M18 92 L24 38 L46 62 L64 24 L82 62 L104 38 L110 92 Z", "url(#g)") +
			outlined("M16 90 H112 V108 Q112 112 108 112 H20 Q16 112 16 108 Z", "url(#g)") +
			`<circle cx="64" cy="100" r="6" fill="${GREEN}" stroke="${OUT}" stroke-width="4"/>` +
			`<circle cx="38" cy="100" r="4.5" fill="${TEAL}" stroke="${OUT}" stroke-width="3.5"/>` +
			`<circle cx="90" cy="100" r="4.5" fill="${PURPLE}" stroke="${OUT}" stroke-width="3.5"/>` +
			gloss("M30 50 L44 66 L40 80 L28 80 Z") +
			gloss("M60 40 L64 32 L70 46 L62 52 Z"),
		grad("g", "#FFE27A", GOLD_D),
	),
	dash: wrap(
		`<path d="M8 50 H30 M4 70 H26 M12 90 H32" stroke="${OUT}" stroke-width="12" stroke-linecap="round"/>` +
			`<path d="M8 50 H30 M4 70 H26 M12 90 H32" stroke="${GREEN}" stroke-width="5" stroke-linecap="round"/>` +
			outlined("M78 8 L36 70 H62 L50 120 L104 50 H74 L92 8 Z", "url(#g)") +
			gloss("M76 16 L84 16 L70 42 L62 42 Z"),
		grad("g", "#C8FF9A", GREEN_D),
	),
	shield: wrap(
		`<circle cx="64" cy="64" r="50" fill="url(#g)" stroke="${OUT}" stroke-width="${SW}"/>` +
			`<circle cx="64" cy="64" r="34" fill="none" stroke="#FFFFFF" stroke-width="4" opacity="0.35"/>` +
			gloss("M34 46 Q40 28 60 22 Q50 34 46 52 Z") +
			`<circle cx="88" cy="86" r="6" fill="#FFFFFF" opacity="0.5"/>`,
		`<radialGradient id="g" cx="0.4" cy="0.35" r="0.75"><stop offset="0" stop-color="#E8FFF0"/><stop offset="0.5" stop-color="${TEAL}"/><stop offset="1" stop-color="#1F8FCF"/></radialGradient>`,
	),
	hook: wrap(
		// rope
		`<path d="M64 6 V40" stroke="${OUT}" stroke-width="14" stroke-linecap="round"/>` +
			`<path d="M64 6 V40" stroke="${GREEN}" stroke-width="6" stroke-linecap="round"/>` +
			// prongs, drawn as outlined strokes
			`<path d="M64 40 V96 M64 96 Q30 98 26 66 M64 96 Q98 98 102 66" fill="none" stroke="${OUT}" stroke-width="20" stroke-linecap="round"/>` +
			`<path d="M64 40 V96 M64 96 Q30 98 26 66 M64 96 Q98 98 102 66" fill="none" stroke="url(#g)" stroke-width="10" stroke-linecap="round"/>` +
			outlined("M18 62 L26 48 L36 64 Z", "#D9DDE8") +
			outlined("M110 62 L102 48 L92 64 Z", "#D9DDE8") +
			// goo drip off the bottom
			outlined("M54 104 Q64 98 74 104 Q74 116 68 118 Q66 124 62 118 Q54 116 54 104 Z", GREEN),
		grad("g", "#F2F4FA", "#8C93A8"),
	),
	jump: wrap(
		outlined("M24 70 L64 32 L104 70 L88 84 L64 62 L40 84 Z", "url(#g)") +
			outlined("M24 104 L64 66 L104 104 L88 118 L64 96 L40 118 Z", "url(#g)") +
			gloss("M34 68 L64 40 L70 46 L42 72 Z"),
		grad("g", "#E2C8FF", "#7A3DDB"),
	),
	slime: wrap(
		// squat jelly blob: domed top with a little curl, wide wobbly base with drips
		outlined(
			"M22 92 C14 72 24 44 50 36 C54 26 62 20 68 24 C64 28 64 33 70 36 C98 40 116 66 106 92 " +
				"C110 100 106 108 98 106 C96 114 86 116 82 108 C72 114 58 114 50 108 C44 116 32 114 32 106 " +
				"C22 108 16 100 22 92 Z",
			"url(#g)",
		) +
			`<ellipse cx="50" cy="74" rx="8" ry="10" fill="${OUT}"/><ellipse cx="80" cy="74" rx="8" ry="10" fill="${OUT}"/>` +
			`<circle cx="52.5" cy="70.5" r="3.2" fill="#FFF"/><circle cx="82.5" cy="70.5" r="3.2" fill="#FFF"/>` +
			`<ellipse cx="38" cy="86" rx="6" ry="3.5" fill="#FF7FB0" opacity="0.6"/><ellipse cx="92" cy="86" rx="6" ry="3.5" fill="#FF7FB0" opacity="0.6"/>` +
			`<path d="M57 88 Q65 95 73 88" fill="none" stroke="${OUT}" stroke-width="4" stroke-linecap="round"/>` +
			gloss("M34 64 Q38 48 54 42 Q46 52 42 66 Z") +
			`<circle cx="92" cy="52" r="4" fill="#FFFFFF" opacity="0.5"/>`,
		grad("g", "#C8FF9A", GREEN_D),
	),
	timer: wrap(
		outlined("M54 6 H74 V20 H54 Z", "#D9DDE8") +
			`<circle cx="64" cy="72" r="46" fill="url(#g)" stroke="${OUT}" stroke-width="${SW}"/>` +
			`<circle cx="64" cy="72" r="34" fill="#FFFFFF" stroke="${OUT}" stroke-width="4"/>` +
			`<path d="M64 72 V46 M64 72 L82 82" stroke="${OUT}" stroke-width="7" stroke-linecap="round"/>` +
			`<circle cx="64" cy="72" r="5" fill="${OUT}"/>`,
		grad("g", "#C8FF9A", GREEN_D),
	),
	exit: wrap(
		`<path d="M30 16 V118" stroke="${OUT}" stroke-width="16" stroke-linecap="round"/>` +
			`<path d="M30 16 V118" stroke="#D9DDE8" stroke-width="7" stroke-linecap="round"/>` +
			outlined("M36 18 Q62 8 82 20 Q100 30 114 22 V74 Q100 82 82 72 Q62 60 36 70 Z", "url(#g)") +
			gloss("M44 26 Q60 20 72 26 L70 34 Q58 30 46 34 Z"),
		grad("g", "#FFE27A", GOLD_D),
	),
	lock: wrap(
		`<path d="M40 60 V42 Q40 18 64 18 Q88 18 88 42 V60" fill="none" stroke="${OUT}" stroke-width="22" stroke-linecap="round"/>` +
			`<path d="M40 60 V42 Q40 18 64 18 Q88 18 88 42 V60" fill="none" stroke="#B9BFD0" stroke-width="10" stroke-linecap="round"/>` +
			outlined("M24 56 H104 V108 Q104 116 96 116 H32 Q24 116 24 108 Z", "url(#g)") +
			`<circle cx="64" cy="80" r="9" fill="${OUT}"/><path d="M64 84 V100" stroke="${OUT}" stroke-width="8" stroke-linecap="round"/>`,
		grad("g", "#8A7FA8", "#4A3F6B"),
	),
};

mkdirSync("png", { recursive: true });
const names = Object.keys(icons);
for (const name of names) {
	writeFileSync(`svg_${name}.svg`, icons[name]);
	writeFileSync(`png/${name}.png`, new Resvg(icons[name]).render().asPng());
}
// contact sheet on a dark and a light background
const cell = 140;
let sheet = `<svg xmlns="http://www.w3.org/2000/svg" width="${cell * names.length}" height="${cell * 2}">`;
sheet += `<rect width="100%" height="${cell}" fill="#241A3A"/><rect y="${cell}" width="100%" height="${cell}" fill="#BFE8FF"/>`;
names.forEach((n, i) => {
	const inner = icons[n].replace(/^<svg[^>]*>/, "").replace(/<\/svg>$/, "").replaceAll('id="g"', `id="g${i}"`).replaceAll("url(#g)", `url(#g${i})`);
	for (const row of [0, 1]) {
		const inner2 = inner.replaceAll(`id="g${i}"`, `id="g${i}r${row}"`).replaceAll(`url(#g${i})`, `url(#g${i}r${row})`);
		sheet += `<svg x="${i * cell + 6}" y="${row * cell + 6}" width="128" height="128" viewBox="0 0 128 128">${inner2}</svg>`;
	}
});
sheet += "</svg>";
writeFileSync("sheet.png", new Resvg(sheet).render().asPng());
console.log("rendered", names.join(", "));
