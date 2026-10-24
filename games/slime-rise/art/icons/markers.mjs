// Slime Rise puzzle markers: floating world icons that point players at the
// floor's puzzle, in the HUD icon style (thick plum outline drawn behind the
// fills so overlapping shapes share one outline, gradient fills, shade side,
// gloss, sparkles). Three candidates + the glow ring and off-screen arrow.
// Run from a folder with @resvg/resvg-js installed: node markers.mjs
import { Resvg } from "@resvg/resvg-js";
import { writeFileSync, mkdirSync } from "node:fs";

const OUT = "#1A1230";
const SW = 8;
const GREEN = "#6BFF3D";
const GREEN_D = "#24A818";
const TEAL = "#3DE8FF";
const TEAL_D = "#1290B0";
const CREAM = "#FFF8E6";

const lin = (id, stops, x2 = 0, y2 = 1) =>
	`<linearGradient id="${id}" x1="0" y1="0" x2="${x2}" y2="${y2}">${stops
		.map(([o, c, a = 1]) => `<stop offset="${o}" stop-color="${c}" stop-opacity="${a}"/>`)
		.join("")}</linearGradient>`;
const rad = (id, stops, cx = 0.5, cy = 0.5, r = 0.5) =>
	`<radialGradient id="${id}" cx="${cx}" cy="${cy}" r="${r}">${stops
		.map(([o, c, a = 1]) => `<stop offset="${o}" stop-color="${c}" stop-opacity="${a}"/>`)
		.join("")}</radialGradient>`;
const svg = (defs, body) =>
	`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="512" height="512"><defs>${defs}</defs>${body}</svg>`;

// Shapes are given as path strings. outline() draws all of them as one fat
// plum silhouette; fills go on top, so touching shapes read as one object.
const outline = (paths, w = SW) =>
	paths
		.map((d) => `<path d="${d}" fill="${OUT}" stroke="${OUT}" stroke-width="${w * 2}" stroke-linejoin="round"/>`)
		.join("");
const fill = (d, f, op = 1) => `<path d="${d}" fill="${f}" opacity="${op}"/>`;
const clipped = (id, d, inner) => `<clipPath id="${id}"><path d="${d}"/></clipPath><g clip-path="url(#${id})">${inner}</g>`;
const star = (x, y, r, o = 1) =>
	`<path d="M${x} ${y - r} Q${x} ${y} ${x + r} ${y} Q${x} ${y} ${x} ${y + r} Q${x} ${y} ${x - r} ${y} Q${x} ${y} ${x} ${y - r} Z" fill="#FFFFFF" opacity="${o}"/>`;
const circle = (cx, cy, r) => `M${cx - r} ${cy} A${r} ${r} 0 1 0 ${cx + r} ${cy} A${r} ${r} 0 1 0 ${cx - r} ${cy} Z`;
const glow = (id, color) =>
	rad(id, [
		[0, color, 0.55],
		[1, color, 0],
	]);

// A gear centred at (cx, cy): body radius r, `teeth` square teeth.
function gear(cx, cy, r, teeth, depth) {
	let d = "";
	const n = teeth * 2;
	for (let i = 0; i < n * 2; i++) {
		const a = (i / (n * 2)) * Math.PI * 2 - Math.PI / 2;
		const tooth = Math.floor(i / 2) % 2 === 0;
		const rr = tooth ? r + depth : r;
		d += `${i === 0 ? "M" : "L"}${(cx + Math.cos(a) * rr).toFixed(2)} ${(cy + Math.sin(a) * rr).toFixed(2)} `;
	}
	return d + "Z";
}

const drop = (x, y, s) =>
	`M${x} ${y} C${x} ${y} ${x + 12 * s} ${y + 14 * s} ${x + 12 * s} ${y + 22 * s} A${12 * s} ${12 * s} 0 0 1 ${x - 12 * s} ${y + 22 * s} C${x - 12 * s} ${y + 14 * s} ${x} ${y} ${x} ${y} Z`;

const out = {};

// A: repair badge. Green hex with a point at the bottom, a cream wrench and
// a slime drop: "fix it here".
{
	const hex = "M64 12 L104 35 L104 81 L76 97 L64 118 L52 97 L24 81 L24 35 Z";
	const inner = "M64 24 L94 41 L94 76 L64 93 L34 76 L34 41 Z";
	const head = circle(56, 46, 13);
	const handle = "M50 54 L62 50 L80 84 Q82 90 76 92 Q71 93 68 88 Z";
	const jaw = "M50 36 L58 32 L62 44 L54 48 Z";
	const dr = drop(84, 46, 0.85);
	out.markerA = svg(
		glow("gA", GREEN) +
			lin("hexA", [[0, "#B6FF8F"], [0.5, GREEN], [1, GREEN_D]]) +
			lin("innA", [[0, "#2D6B3A"], [1, "#163A22"]]) +
			lin("wrA", [[0, "#FFFFFF"], [1, "#CFC6E6"]]) +
			lin("drA", [[0, "#D6FFB8"], [1, GREEN_D]]),
		`<circle cx="64" cy="60" r="62" fill="url(#gA)"/>` +
			outline([hex]) +
			fill(hex, "url(#hexA)") +
			clipped("cA", hex, fill("M64 12 L104 35 L104 81 L76 97 L64 118 Z", GREEN_D, 0.35) + fill("M24 35 L64 12 L74 18 L30 44 Z", "#FFFFFF", 0.45)) +
			fill(inner, "url(#innA)") +
			outline([head, handle], 4) +
			fill(head, "url(#wrA)") +
			fill(handle, "url(#wrA)") +
			fill(jaw, "#163A22") +
			fill("M69 72 L78 86", "none") +
			`<path d="M60 58 L74 84" stroke="#A89CC8" stroke-width="3" stroke-linecap="round" opacity="0.7"/>` +
			outline([dr], 4) +
			fill(dr, "url(#drA)") +
			`<ellipse cx="80" cy="62" rx="3" ry="5" fill="#FFFFFF" opacity="0.8"/>` +
			star(100, 22, 6) +
			star(28, 100, 4, 0.85),
	);
}

// B: slime pin. A map-pin drop in slime green with a cream window and a teal
// gear inside, a drip running off its side: "objective here".
{
	const pin = "M64 118 C64 118 20 76 20 50 A44 44 0 0 1 108 50 C108 76 64 118 64 118 Z";
	const win = circle(64, 50, 25);
	const g = gear(64, 50, 12, 8, 4.5);
	const drip = "M100 64 Q104 74 102 82 A5 5 0 0 1 92 82 Q92 74 96 68 Z";
	out.markerB = svg(
		glow("gB", GREEN) +
			lin("pinB", [[0, "#C8FF9E"], [0.45, GREEN], [1, GREEN_D]]) +
			lin("winB", [[0, "#FFFFFF"], [1, "#E8E0F6"]]) +
			lin("gearB", [[0, "#9FF6FF"], [1, TEAL_D]]),
		`<circle cx="64" cy="58" r="62" fill="url(#gB)"/>` +
			`<ellipse cx="64" cy="122" rx="20" ry="4" fill="#000" opacity="0.3"/>` +
			outline([pin, drip]) +
			fill(pin, "url(#pinB)") +
			fill(drip, "url(#pinB)") +
			clipped(
				"cB",
				pin,
				fill("M64 6 A44 44 0 0 1 108 50 C108 76 64 118 64 118 Z", GREEN_D, 0.35) +
					fill("M30 30 Q40 12 62 10 Q48 20 40 40 Z", "#FFFFFF", 0.55),
			) +
			outline([win], 4) +
			fill(win, "url(#winB)") +
			outline([g], 3.5) +
			fill(g, "url(#gearB)") +
			`<circle cx="64" cy="50" r="5" fill="${OUT}"/>` +
			`<circle cx="62" cy="48" r="1.6" fill="#FFFFFF"/>` +
			fill("M48 40 Q52 32 60 30 Q54 36 52 42 Z", "#FFFFFF", 0.8) +
			star(104, 18, 6) +
			star(22, 86, 4, 0.85),
	);
}

// C: alert badge. A round badge with a hazard-striped rim and a green slime
// "!" dripping inside: "puzzle needed".
{
	const rim = circle(64, 58, 46);
	const face = circle(64, 58, 33);
	const tail = "M54 100 L64 120 L74 100 Z";
	const bang = "M57 34 Q64 30 71 34 L68 66 Q64 70 60 66 Z";
	const dot = circle(64, 79, 6.5);
	let stripes = "";
	for (let i = -8; i < 8; i++) {
		const x = 64 + i * 14;
		stripes += `<path d="M${x} 0 L${x + 7} 0 L${x - 50} 128 L${x - 57} 128 Z" fill="${OUT}"/>`;
	}
	out.markerC = svg(
		glow("gC", "#FFC93C") +
			lin("rimC", [[0, "#FFF1A8"], [1, "#FFB020"]]) +
			lin("faceC", [[0, "#3A2B5E"], [1, "#1E1636"]]) +
			lin("bangC", [[0, "#D6FFB8"], [0.5, GREEN], [1, GREEN_D]]),
		`<circle cx="64" cy="60" r="62" fill="url(#gC)"/>` +
			outline([rim, tail]) +
			fill(rim, "url(#rimC)") +
			fill(tail, "url(#rimC)") +
			clipped("cC", rim, stripes + fill("M18 58 A46 46 0 0 1 64 12 L64 20 A38 38 0 0 0 26 58 Z", "#FFFFFF", 0.35)) +
			outline([face], 3) +
			fill(face, "url(#faceC)") +
			outline([bang, dot], 3.5) +
			fill(bang, "url(#bangC)") +
			fill(dot, "url(#bangC)") +
			fill("M60 38 Q63 36 66 37 L64 52 Z", "#FFFFFF", 0.7) +
			fill("M70 66 Q73 74 71 80 A3 3 0 0 1 66 79 Q66 72 68 68 Z", "url(#bangC)") +
			star(104, 20, 6) +
			star(24, 92, 4, 0.85),
	);
}

// Soft glow ring (white, tinted in game) and the off-screen arrow.
out.ring = svg(
	rad("ringG", [
		[0.62, "#FFFFFF", 0],
		[0.78, "#FFFFFF", 0.9],
		[0.86, "#FFFFFF", 0.35],
		[1, "#FFFFFF", 0],
	]),
	`<circle cx="64" cy="64" r="64" fill="url(#ringG)"/>`,
);
{
	const arrow = "M30 44 L74 44 L74 26 L108 64 L74 102 L74 84 L30 84 Q22 84 22 76 L22 52 Q22 44 30 44 Z";
	out.arrow = svg(
		lin("arG", [[0, "#C8FF9E"], [0.5, GREEN], [1, GREEN_D]]),
		outline([arrow]) +
			fill(arrow, "url(#arG)") +
			fill("M30 48 L76 48 L76 34 L100 62 L30 62 Q26 62 26 58 L26 52 Q26 48 30 48 Z", "#FFFFFF", 0.4),
	);
}

mkdirSync("markers", { recursive: true });
for (const [name, s] of Object.entries(out)) {
	writeFileSync(`markers/${name}.png`, new Resvg(s, { background: "rgba(0,0,0,0)" }).render().asPng());
	writeFileSync(`markers/${name}.svg`, s);
}
// Contact sheet on light and dark backgrounds.
const names = ["markerA", "markerB", "markerC", "arrow"];
const cell = 220;
let sheet = `<svg xmlns="http://www.w3.org/2000/svg" width="${cell * 4}" height="${cell * 2}">`;
sheet += `<rect width="${cell * 4}" height="${cell}" fill="#241C3C"/><rect y="${cell}" width="${cell * 4}" height="${cell}" fill="#C9D6E8"/>`;
names.forEach((n, i) => {
	for (const row of [0, 1]) {
		sheet += `<image href="data:image/svg+xml;base64,${Buffer.from(out[n]).toString("base64")}" x="${i * cell + 10}" y="${row * cell + 10}" width="${cell - 20}" height="${cell - 20}"/>`;
	}
});
sheet += "</svg>";
writeFileSync("markers/sheet.png", new Resvg(sheet).render().asPng());
console.log("rendered", Object.keys(out).join(", "));
