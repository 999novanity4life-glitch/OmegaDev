--!strict
-- Design tokens: one place for UI color, shape, spacing, type and motion, so
-- every screen in a game speaks the same visual language. Pure module.
-- Colors are 0-255 RGB; the client converts with Color3.fromRGB.
--
-- Sources:
--   [DOC] Roblox UI design course, "choose an art style" and "wireframe your
--         layouts": https://create.roblox.com/docs/tutorials/curriculums/user-interface-design
--   [DOC] Cross-platform UI: https://create.roblox.com/docs/ui/cross-platform-design
--   [RULE] WCAG 2.x contrast: 4.5:1 for body text, 3:1 for large text and
--          UI shapes. https://www.w3.org/TR/WCAG22/#contrast-minimum
--   [INFERRED] the default palette below (carbon / orange glow / chrome, the
--         studio house theme). Each game replaces it from its style bible.

export type RGB = { number }

local UITokens = {}

UITokens.Color = table.freeze({
	Background = { 18, 19, 22 }, -- carbon
	Surface = { 32, 34, 39 },
	SurfaceRaised = { 46, 49, 56 },
	Stroke = { 92, 98, 110 }, -- chrome edge
	Text = { 240, 242, 245 },
	TextMuted = { 168, 174, 186 },
	Accent = { 255, 138, 31 }, -- orange glow
	AccentText = { 20, 14, 8 }, -- text on Accent
	Positive = { 92, 214, 120 },
	Danger = { 255, 84, 84 },
})

-- Corner radius in pixels (UICorner.CornerRadius offset).
UITokens.Radius = table.freeze({ Small = 6, Medium = 12, Large = 20, Pill = 999 })

-- UIStroke thickness in pixels.
UITokens.Stroke = table.freeze({ Hairline = 1, Regular = 2, Bold = 3 })

-- Spacing scale in pixels for UIPadding and layout gaps (4 px grid).
UITokens.Space = table.freeze({ XS = 4, S = 8, M = 12, L = 16, XL = 24, XXL = 32 })

-- Text sizes in pixels. CLAUDE.md rule 5 sets a hard floor of 9; we keep
-- body text well above it for phones [INFERRED].
UITokens.Text = table.freeze({ Caption = 14, Body = 18, Button = 20, Title = 28, Display = 40 })
UITokens.MIN_TEXT = 9

-- Motion in seconds. One shared set keeps every screen's animation consistent
-- (the Hearthstone "shared motion language" lesson, docs/research/videos-2026-10-28/08).
UITokens.Motion = table.freeze({ Press = 0.06, Quick = 0.12, Pop = 0.18, Panel = 0.25, Scene = 0.4 })

-- Minimum touch target in pixels [INFERRED from common mobile guidance; the
-- Roblox course asks for large, thumb-reachable buttons without a number].
UITokens.MIN_TOUCH = 44

-- WCAG relative luminance of an sRGB color (0-255 per channel).
function UITokens.luminance(c: RGB): number
	local function channel(v: number): number
		local s = v / 255
		return if s <= 0.04045 then s / 12.92 else ((s + 0.055) / 1.055) ^ 2.4
	end
	return 0.2126 * channel(c[1]) + 0.7152 * channel(c[2]) + 0.0722 * channel(c[3])
end

-- Contrast ratio between two colors, from 1 (same) to 21 (black on white).
function UITokens.contrastRatio(a: RGB, b: RGB): number
	local la, lb = UITokens.luminance(a), UITokens.luminance(b)
	local hi, lo = math.max(la, lb), math.min(la, lb)
	return (hi + 0.05) / (lo + 0.05)
end

-- Text/background pairs every game must keep readable. Checked by the spec.
UITokens.TEXT_PAIRS = table.freeze({
	{ "Text", "Background" },
	{ "Text", "Surface" },
	{ "Text", "SurfaceRaised" },
	{ "TextMuted", "Background" },
	{ "TextMuted", "Surface" },
	{ "AccentText", "Accent" },
})

return table.freeze(UITokens)
