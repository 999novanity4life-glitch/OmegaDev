// Slime Rise HUD icons v2: same chunky cartoon style (thick plum outline,
// bright fills) with more detail: shade side, rim light, facets, gloss,
// sparkles and small props. Renders 512px PNGs + a contact sheet.
import { Resvg } from "@resvg/resvg-js";
import { writeFileSync, mkdirSync } from "node:fs";

const OUT = "#1A1230";
const SW = 8;
const GREEN = "#6BFF3D";
const GREEN_D = "#24A818";
const GOLD_D = "#D9790F";
const TEAL = "#3DE8FF";
const PURPLE = "#A66BFF";

const lin = (id, stops, x2 = 0, y2 = 1) =>
	`<linearGradient id="${id}" x1="0" y1="0" x2="${x2}" y2="${y2}">${stops
		.map(([o, c, a = 1]) => `<stop offset="${o}" stop-color="${c}" stop-opacity="${a}"/>`)
		.join("")}</linearGradient>`;
const rad = (id, stops, cx = 0.4, cy = 0.35, r = 0.75) =>
	`<radialGradient id="${id}" cx="${cx}" cy="${cy}" r="${r}">${stops
		.map(([o, c, a = 1]) => `<stop offset="${o}" stop-color="${c}" stop-opacity="${a}"/>`)
		.join("")}</radialGradient>`;
const BLUR = `<filter id="blur" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="5"/></filter>`;

// A filled shape with clipped inner details and the outline drawn last on top.
let clipN = 0;
function layer(d, fill, details = "", sw = SW) {
	const id = `clip${clipN++}`;
	return (
		`<clipPath id="${id}"><path d="${d}"/></clipPath>` +
		`<path d="${d}" fill="${fill}"/>` +
		`<g clip-path="url(#${id})">${details}</g>` +
		`<path d="${d}" fill="none" stroke="${OUT}" stroke-width="${sw}" stroke-linejoin="round" stroke-linecap="round"/>`
	);
}
const circleD = (cx, cy, r) => `M${cx - r} ${cy} A${r} ${r} 0 1 0 ${cx + r} ${cy} A${r} ${r} 0 1 0 ${cx - r} ${cy} Z`;
const star = (x, y, r, o = 1) =>
	`<path d="M${x} ${y - r} Q${x} ${y} ${x + r} ${y} Q${x} ${y} ${x} ${y + r} Q${x} ${y} ${x - r} ${y} Q${x} ${y} ${x} ${y - r} Z" fill="#FFFFFF" opacity="${o}"/>`;
const shadow = (cy = 120, rx = 38) => `<ellipse cx="64" cy="${cy}" rx="${rx}" ry="5" fill="#000" opacity="0.28"/>`;
const p = (d, fill, op = 1, extra = "") => `<path d="${d}" fill="${fill}" opacity="${op}" ${extra}/>`;
const line = (d, color, w, op = 1) =>
	`<path d="${d}" fill="none" stroke="${color}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round" opacity="${op}"/>`;
const svg = (name, defs, body) =>
	`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="512" height="512"><defs>${BLUR}${defs}</defs>${body}</svg>`;

const icons = {};

// Crown: ball tips, engraved line, faceted gems, shaded right side.
{
	const pts = "M18 90 L22 42 L44 64 L64 24 L84 64 L106 42 L110 90 Z";
	const band = "M14 86 H114 V106 Q114 112 108 112 H20 Q14 112 14 106 Z";
	const gem = "M64 88 L75 99 L64 110 L53 99 Z";
	icons.crown = svg(
		"crown",
		lin("cg", [[0, "#FFF1A8"], [0.45, "#FFC93C"], [1, GOLD_D]]) +
			lin("cgem", [[0, "#D6FFB8"], [1, GREEN_D]]) +
			rad("cglow", [[0, "#FFE27A", 0.7], [1, "#FFE27A", 0]], 0.5, 0.5, 0.5),
		`<circle cx="64" cy="66" r="58" fill="url(#cglow)"/>` +
			shadow(121, 46) +
			layer(
				pts,
				"url(#cg)",
				p("M64 24 L84 64 L106 42 L110 90 H64 Z", GOLD_D, 0.38) +
					line("M27 84 L30 56 L44 72 L64 38 L84 72 L98 56 L101 84", "#9C5208", 2.5, 0.55) +
					p("M23 50 L40 68 L35 84 L25 84 Z", "#FFFFFF", 0.55) +
					p("M60 36 L64 28 L70 42 L62 50 Z", "#FFFFFF", 0.6),
			) +
			[
				[22, 42],
				[64, 24],
				[106, 42],
			]
				.map(
					([x, y]) =>
						layer(circleD(x, y, 6.5), "url(#cg)", `<circle cx="${x - 2}" cy="${y - 2.5}" r="2.2" fill="#FFF"/>`, 5),
				)
				.join("") +
			layer(
				band,
				"url(#cg)",
				p("M14 101 H114 V114 H14 Z", GOLD_D, 0.55) +
					line("M20 91 H108", "#FFFFFF", 3, 0.6) +
					[24, 104].map((x) => `<circle cx="${x}" cy="99" r="2.6" fill="#9C5208" opacity="0.8"/>`).join(""),
			) +
			layer(
				gem,
				"url(#cgem)",
				p("M64 88 L75 99 L64 99 Z", "#FFFFFF", 0.55) + p("M64 99 L75 99 L64 110 Z", GREEN_D, 0.5),
				4,
			) +
			layer(circleD(39, 99, 5.5), TEAL, `<circle cx="37.5" cy="97" r="2" fill="#FFF"/>` + p("M33 101 H46 V106 H33Z", "#1F8FCF", 0.5), 3.5) +
			layer(circleD(89, 99, 5.5), PURPLE, `<circle cx="87.5" cy="97" r="2" fill="#FFF"/>` + p("M83 101 H96 V106 H83Z", "#6A2FC0", 0.5), 3.5) +
			star(104, 16, 8) +
			star(18, 22, 4.5, 0.9) +
			star(114, 72, 3.5, 0.8),
	);
}

// Dash: faceted bolt with glow, gradient speed streaks and sparks.
{
	const bolt = "M78 6 L34 70 H60 L48 122 L106 50 H74 L92 6 Z";
	const streak = (y, x1, x2) =>
		line(`M${x1} ${y} H${x2}`, "url(#dstreak)", 8) + line(`M${x1 + 6} ${y} H${x2 - 2}`, "#FFFFFF", 2.2, 0.8);
	icons.dash = svg(
		"dash",
		lin("dg", [[0, "#E4FFC9"], [0.5, GREEN], [1, GREEN_D]]) +
			`<linearGradient id="dstreak" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="34" y2="0"><stop offset="0" stop-color="${GREEN}" stop-opacity="0.15"/><stop offset="1" stop-color="#E4FFC9"/></linearGradient>`,
		`<path d="${bolt}" fill="${GREEN}" opacity="0.55" filter="url(#blur)"/>` +
			shadow(122, 30) +
			streak(46, 6, 30) +
			streak(66, 2, 26) +
			streak(86, 10, 30) +
			layer(
				bolt,
				"url(#dg)",
				p("M88 0 L128 0 L128 128 L46 128 L64 64 Z", GREEN_D, 0.42) +
					line("M77 13 L43 64", "#FFFFFF", 3.5, 0.75) +
					line("M58 76 L54 96", "#FFFFFF", 2.5, 0.5) +
					p("M80 12 L88 12 L74 40 L66 40 Z", "#FFFFFF", 0.45),
			) +
			star(112, 20, 7) +
			star(108, 98, 4.5, 0.9) +
			`<circle cx="98" cy="30" r="2.4" fill="#E4FFC9"/><circle cx="26" cy="104" r="2" fill="#E4FFC9"/>`,
	);
}

// Bubble Shield: iridescent bubble around a little green shield emblem.
{
	const bubble = circleD(64, 62, 50);
	const emblem = "M64 36 L88 45 V64 Q88 84 64 96 Q40 84 40 64 V45 Z";
	icons.shield = svg(
		"shield",
		rad("sg", [[0, "#F2FFFF"], [0.45, "#8FF2FF"], [1, "#2A9FD8"]]) +
			lin("sirid", [[0, "#FF9BE0"], [0.35, "#FFF27A"], [0.7, "#7AFFD9"], [1, "#9B8CFF"]], 1, 1) +
			lin("sem", [[0, "#D6FFB8"], [1, GREEN_D]]),
		shadow(120, 34) +
			layer(
				bubble,
				"url(#sg)",
				`<circle cx="64" cy="62" r="44" fill="none" stroke="url(#sirid)" stroke-width="4" opacity="0.6"/>` +
					p("M10 74 A54 54 0 0 0 118 74 A54 38 0 0 1 10 74 Z", "#1E6FB0", 0.35) +
					layer(
						emblem,
						"url(#sem)",
						p("M64 36 L88 45 V64 Q88 84 64 96 Z", GREEN_D, 0.4) +
							line("M64 44 V88", "#FFFFFF", 2.5, 0.45) +
							p("M46 50 L58 45 L56 60 L46 64 Z", "#FFFFFF", 0.55),
						5,
					) +
					p("M28 44 Q34 22 58 16 Q44 30 40 50 Z", "#FFFFFF", 0.7) +
					`<circle cx="90" cy="88" r="5" fill="#FFFFFF" opacity="0.55"/><circle cx="98" cy="78" r="2.4" fill="#FFFFFF" opacity="0.5"/>`,
			) +
			layer(circleD(110, 22, 7), "url(#sg)", `<circle cx="108" cy="20" r="2.2" fill="#FFF"/>`, 3.5) +
			layer(circleD(118, 40, 4), "url(#sg)", "", 3) +
			star(16, 18, 6),
	);
}

// Goo Hook: thick dripping goo rope, shaded metal hook with rivet eye.
{
	const goo =
		"M54 2 H74 V26 Q80 32 76 40 Q74 48 69 45 Q67 54 61 49 Q53 46 54 38 Q48 30 54 24 Z";
	const prongs = "M64 50 V94 M64 94 Q30 96 26 66 M64 94 Q98 96 102 66";
	icons.hook = svg(
		"hook",
		lin("hm", [[0, "#FFFFFF"], [0.5, "#C9CEDC"], [1, "#6E7690"]], 1, 0) +
			lin("hgoo", [[0, "#D6FFB8"], [0.5, GREEN], [1, GREEN_D]], 1, 0),
		shadow(122, 34) +
			line(prongs, OUT, 22) +
			line(prongs, "url(#hm)", 12) +
			line("M60 54 V90 M60 92 Q34 92 30 70", "#FFFFFF", 3, 0.75) +
			line("M68 96 Q92 96 99 74", "#4A5068", 3, 0.6) +
			layer("M18 64 L27 46 L37 64 Z", "url(#hm)", p("M27 46 L37 64 H27 Z", "#6E7690", 0.5), 5) +
			layer("M110 64 L101 46 L91 64 Z", "url(#hm)", p("M101 46 L110 64 H101 Z", "#6E7690", 0.5), 5) +
			layer(circleD(64, 50, 10), "url(#hm)", `<circle cx="64" cy="50" r="4" fill="${OUT}"/>` + `<circle cx="60" cy="46" r="2.4" fill="#FFF"/>`, 5) +
			layer(
				goo,
				"url(#hgoo)",
				line("M60 4 V34", "#FFFFFF", 3.5, 0.65) +
					`<circle cx="68" cy="16" r="3" fill="#FFFFFF" opacity="0.4"/><circle cx="66" cy="30" r="2" fill="#FFFFFF" opacity="0.35"/>` +
					p("M70 0 H80 V50 H70 Z", GREEN_D, 0.35),
				6,
			) +
			layer("M58 100 Q64 96 70 100 Q72 110 66 113 Q64 120 61 113 Q56 110 58 100 Z", "url(#hgoo)", `<circle cx="62" cy="103" r="1.8" fill="#FFF"/>`, 5) +
			layer(circleD(75, 59, 3.5), GREEN, "", 3) +
			star(108, 16, 6) +
			star(20, 30, 4, 0.85),
	);
}

// Double Jump: faceted chevrons with dust puffs and motion ticks.
{
	const c1 = "M24 58 L64 20 L104 58 L88 72 L64 50 L40 72 Z";
	const c2 = "M24 90 L64 52 L104 90 L88 104 L64 82 L40 104 Z";
	const facet = (d, y) =>
		layer(d, "url(#jg)", p(`M0 ${y} H128 V128 H0 Z`, "#5A22B8", 0.38) + p(`M30 ${y - 2} L64 ${y - 34} L70 ${y - 28} L38 ${y + 2} Z`, "#FFFFFF", 0.5));
	icons.jump = svg(
		"jump",
		lin("jg", [[0, "#F0E2FF"], [0.5, "#B98CFF"], [1, "#6A2FD0"]]),
		`<path d="${c1} ${c2}" fill="${PURPLE}" opacity="0.4" filter="url(#blur)"/>` +
			facet(c1, 52) +
			facet(c2, 84) +
			[
				[44, 115, 7],
				[57, 118, 8.5],
				[72, 117, 7.5],
				[85, 114, 6],
			]
				.map(([x, y, r]) => layer(circleD(x, y, r), "#F1EBFF", `<circle cx="${x - r * 0.3}" cy="${y - r * 0.35}" r="${r * 0.3}" fill="#FFF"/>`, 3.5))
				.join("") +
			line("M14 40 L8 34 M114 40 L120 34 M12 62 H4 M116 62 H124", "#FFFFFF", 3.5, 0.85) +
			star(110, 14, 6),
	);
}

// Slime mascot: squat jelly blob with inner bubbles, shade and shine.
{
	const blob =
		"M22 92 C14 72 24 44 50 36 C54 26 62 20 68 24 C64 28 64 33 70 36 C98 40 116 66 106 92 " +
		"C110 100 106 108 98 106 C96 114 86 116 82 108 C72 114 58 114 50 108 C44 116 32 114 32 106 C22 108 16 100 22 92 Z";
	icons.slime = svg(
		"slime",
		lin("bg", [[0, "#E0FFC2"], [0.45, GREEN], [1, GREEN_D]]),
		shadow(121, 44) +
			layer(
				blob,
				"url(#bg)",
				`<ellipse cx="66" cy="114" rx="62" ry="22" fill="${GREEN_D}" opacity="0.55"/>` +
					`<ellipse cx="100" cy="74" rx="14" ry="30" fill="${GREEN_D}" opacity="0.3"/>` +
					[
						[30, 96, 4],
						[86, 98, 3],
						[96, 62, 2.5],
						[40, 52, 2],
					]
						.map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="none" stroke="#FFFFFF" stroke-width="1.6" opacity="0.55"/>`)
						.join("") +
					p("M32 66 Q36 46 54 40 Q46 52 42 68 Z", "#FFFFFF", 0.65) +
					p("M62 28 Q64 24 67 25 Q64 30 65 34 Z", "#FFFFFF", 0.6) +
					line("M40 110 Q44 112 48 108", "#FFFFFF", 2, 0.4),
			) +
			`<ellipse cx="50" cy="74" rx="8.5" ry="10.5" fill="${OUT}"/><ellipse cx="80" cy="74" rx="8.5" ry="10.5" fill="${OUT}"/>` +
			`<circle cx="53" cy="70" r="3.4" fill="#FFF"/><circle cx="83" cy="70" r="3.4" fill="#FFF"/>` +
			`<circle cx="47.5" cy="78.5" r="1.6" fill="#FFF"/><circle cx="77.5" cy="78.5" r="1.6" fill="#FFF"/>` +
			`<ellipse cx="37" cy="87" rx="6.5" ry="3.8" fill="#FF6FA8" opacity="0.65"/><ellipse cx="93" cy="87" rx="6.5" ry="3.8" fill="#FF6FA8" opacity="0.65"/>` +
			line("M57 88 Q65 96 73 88", OUT, 4.5) +
			`<path d="M62 92.5 Q65 96 68 92.5 Q65 99 62 92.5 Z" fill="#FF6FA8"/>` +
			star(108, 30, 6) +
			star(16, 50, 3.5, 0.85),
	);
}

// Timer: stopwatch with ticks, three hands, crown button and glass glare.
{
	const ticks = Array.from({ length: 12 }, (_, i) => {
		const a = (i / 12) * Math.PI * 2;
		const r1 = i % 3 === 0 ? 24 : 28;
		const x1 = 64 + Math.sin(a) * r1,
			y1 = 74 - Math.cos(a) * r1;
		const x2 = 64 + Math.sin(a) * 31,
			y2 = 74 - Math.cos(a) * 31;
		return line(`M${x1.toFixed(1)} ${y1.toFixed(1)} L${x2.toFixed(1)} ${y2.toFixed(1)}`, OUT, i % 3 === 0 ? 4 : 2.2);
	}).join("");
	icons.timer = svg(
		"timer",
		lin("tg", [[0, "#D6FFB8"], [0.5, GREEN], [1, GREEN_D]]) +
			lin("tm", [[0, "#FFFFFF"], [1, "#8C93A8"]]) +
			rad("tface", [[0, "#FFFFFF"], [0.8, "#F1F3F8"], [1, "#C9CEDC"]], 0.45, 0.4, 0.7),
		shadow(122, 36) +
			layer("M55 6 H73 V20 H55 Z", "url(#tm)", line("M59 8 V18 M64 8 V18 M69 8 V18", "#6E7690", 1.6, 0.8), 5) +
			`<g transform="rotate(42 98 36)">${layer("M93 26 H103 V38 H93 Z", "url(#tm)", "", 4.5)}</g>` +
			layer(circleD(64, 74, 46), "url(#tg)", p("M64 28 A46 46 0 0 1 64 120 Z", GREEN_D, 0.3) + line("M30 52 A40 40 0 0 1 56 32", "#FFFFFF", 3.5, 0.6)) +
			layer(
				circleD(64, 74, 34),
				"url(#tface)",
				ticks +
					line("M64 74 L64 50", OUT, 5.5) +
					line("M64 74 L80 84", OUT, 5.5) +
					line("M64 80 L74 50", "#FF4D6A", 2.2) +
					`<circle cx="64" cy="74" r="4.5" fill="${OUT}"/><circle cx="64" cy="74" r="1.8" fill="#FF4D6A"/>` +
					p("M34 66 A31 31 0 0 1 72 42 Q52 46 40 72 Z", "#FFFFFF", 0.7),
				4,
			) +
			star(108, 14, 6) +
			star(18, 34, 4, 0.85),
	);
}

// Exit flag: waving checkered flag on a gold pole with ball top.
{
	const flag = "M36 18 Q60 8 80 20 Q98 30 116 20 V72 Q98 82 80 72 Q60 60 36 70 Z";
	icons.exit = svg(
		"exit",
		lin("eg", [[0, "#FFF1A8"], [1, GOLD_D]], 1, 0) +
			`<pattern id="echeck" width="12" height="12" patternUnits="userSpaceOnUse" patternTransform="skewY(-8)"><rect width="12" height="12" fill="#FFFFFF"/><rect width="6" height="6" fill="#2A2040"/><rect x="6" y="6" width="6" height="6" fill="#2A2040"/></pattern>`,
		shadow(122, 22) +
			line("M30 18 V118", OUT, 15) +
			line("M30 18 V118", "url(#eg)", 7) +
			line("M28 24 V114", "#FFFFFF", 2, 0.7) +
			layer(circleD(30, 14, 7), "url(#eg)", `<circle cx="28" cy="12" r="2.4" fill="#FFF"/>`, 5) +
			layer(
				flag,
				"url(#echeck)",
				p("M70 0 Q80 40 70 128 H96 Q88 40 96 0 Z", "#1A1230", 0.22) +
					p("M44 0 Q50 40 44 128 H56 Q52 40 56 0 Z", "#FFFFFF", 0.25) +
					p("M100 0 H128 V128 H100 Z", "#FFFFFF", 0.15) +
					line("M40 66 Q60 56 80 68 Q98 78 112 70", GREEN, 4, 0.9),
			) +
			star(110, 92, 7) +
			star(98, 8, 4, 0.85) +
			star(18, 50, 3.5, 0.8),
	);
}

// Lock: shaded shackle, riveted body, gold keyhole plate.
{
	const body = "M22 56 H106 V106 Q106 116 96 116 H32 Q22 116 22 106 Z";
	icons.lock = svg(
		"lock",
		lin("lb", [[0, "#9C92BC"], [0.5, "#6A5F8C"], [1, "#3C3258"]]) +
			lin("ls", [[0, "#FFFFFF"], [1, "#7E86A0"]], 1, 0) +
			lin("lk", [[0, "#FFF1A8"], [1, GOLD_D]]),
		shadow(122, 40) +
			line("M40 58 V42 Q40 16 64 16 Q88 16 88 42 V58", OUT, 22) +
			line("M40 58 V42 Q40 16 64 16 Q88 16 88 42 V58", "url(#ls)", 11) +
			line("M37 50 V42 Q37 22 56 19", "#FFFFFF", 2.5, 0.75) +
			layer(
				body,
				"url(#lb)",
				p("M0 56 H128 V64 H0 Z", "#FFFFFF", 0.3) +
					p("M0 104 H128 V128 H0 Z", "#2A2040", 0.35) +
					[
						[31, 65],
						[97, 65],
						[31, 107],
						[97, 107],
					]
						.map(([x, y]) => `<circle cx="${x}" cy="${y}" r="3.2" fill="#C9C2E0"/><circle cx="${x - 0.8}" cy="${y - 0.8}" r="1.1" fill="#FFF"/>`)
						.join("") +
					line("M84 76 L96 70 M86 84 L92 81", "#FFFFFF", 1.6, 0.35),
			) +
			layer("M52 70 H76 Q80 70 80 74 V98 Q80 102 76 102 H52 Q48 102 48 98 V74 Q48 70 52 70 Z", "url(#lk)", p("M48 90 H80 V102 H48 Z", GOLD_D, 0.45), 4) +
			`<circle cx="64" cy="82" r="5.5" fill="${OUT}"/><path d="M61 84 L67 84 L68.5 96 H59.5 Z" fill="${OUT}"/>` +
			star(110, 26, 5.5, 0.9),
	);
}

mkdirSync("png2", { recursive: true });
const names = Object.keys(icons);
for (const name of names) {
	writeFileSync(`svg2_${name}.svg`, icons[name]);
	writeFileSync(`png2/${name}.png`, new Resvg(icons[name]).render().asPng());
}
const cell = 200;
let sheet = `<svg xmlns="http://www.w3.org/2000/svg" width="${cell * names.length}" height="${cell * 2}">`;
sheet += `<rect width="100%" height="${cell}" fill="#241A3A"/><rect y="${cell}" width="100%" height="${cell}" fill="#BFE8FF"/>`;
names.forEach((n, i) => {
	const inner = icons[n].replace(/^<svg[^>]*>/, "").replace(/<\/svg>$/, "");
	for (const row of [0, 1])
		sheet += `<svg x="${i * cell + 8}" y="${row * cell + 8}" width="184" height="184" viewBox="0 0 128 128">${inner}</svg>`;
});
sheet += "</svg>";
writeFileSync("sheet2.png", new Resvg(sheet).render().asPng());
console.log("rendered", names.join(", "));
